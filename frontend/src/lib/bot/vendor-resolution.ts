import { supabaseAdmin } from '@/lib/supabase';

// When no vendor is within the geo radius, allow assigning the vendor with the
// most stock as a last resort (so an order is never silently dropped).
const ALLOW_STOCK_BASED_VENDOR_FALLBACK =
  process.env.ALLOW_STOCK_BASED_VENDOR_FALLBACK !== 'false';

function toFiniteNumber(value: unknown): number | null {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function haversineDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

async function resolveNearestVendorFallback(customer: any, radiusKm: number): Promise<string | null> {
  const customerLat = toFiniteNumber(customer?.latitude);
  const customerLon = toFiniteNumber(customer?.longitude);
  if (customerLat === null || customerLon === null) return null;

  const { data: vendors, error: vendorError } = await supabaseAdmin
    .from('vendors')
    .select('id, latitude, longitude, is_active, is_on_vacation')
    .eq('is_active', true)
    .eq('is_on_vacation', false)
    .limit(500);

  if (vendorError || !vendors || vendors.length === 0) {
    console.warn('Nearest-vendor fallback failed while loading vendors:', vendorError?.message || 'No vendors');
    return null;
  }

  const vendorIds = vendors.map((vendor: any) => vendor.id).filter(Boolean);
  if (vendorIds.length === 0) return null;

  const { data: vendorProducts, error: stockError } = await supabaseAdmin
    .from('vendor_products')
    .select('vendor_id, current_stock, is_active')
    .in('vendor_id', vendorIds)
    .eq('is_active', true)
    .gt('current_stock', 0);

  if (stockError) {
    console.warn('Nearest-vendor fallback failed while loading stock:', stockError.message);
    return null;
  }

  const stockedVendorIds = new Set(
    (vendorProducts || []).map((row: any) => String(row.vendor_id)).filter(Boolean),
  );
  if (stockedVendorIds.size === 0) return null;

  let bestVendorId: string | null = null;
  let bestDistance = Number.POSITIVE_INFINITY;
  const stockByVendor = new Map<string, number>();

  for (const row of vendorProducts || []) {
    const vendorId = row?.vendor_id ? String(row.vendor_id) : null;
    if (!vendorId) continue;
    const current = stockByVendor.get(vendorId) || 0;
    stockByVendor.set(vendorId, current + Number(row.current_stock || 0));
  }

  for (const vendor of vendors) {
    const vendorId = vendor?.id ? String(vendor.id) : null;
    if (!vendorId || !stockedVendorIds.has(vendorId)) continue;

    const vendorLat = toFiniteNumber(vendor?.latitude);
    const vendorLon = toFiniteNumber(vendor?.longitude);
    if (vendorLat === null || vendorLon === null) continue;

    const distanceKm = haversineDistanceKm(customerLat, customerLon, vendorLat, vendorLon);
    if (distanceKm <= radiusKm && distanceKm < bestDistance) {
      bestDistance = distanceKm;
      bestVendorId = vendorId;
    }
  }

  if (!bestVendorId && ALLOW_STOCK_BASED_VENDOR_FALLBACK) {
    const fallbackVendorId = Array.from(stockedVendorIds).sort((a, b) => {
      const stockDiff = (stockByVendor.get(b) || 0) - (stockByVendor.get(a) || 0);
      if (stockDiff !== 0) return stockDiff;
      return a.localeCompare(b);
    })[0] || null;

    if (fallbackVendorId) {
      console.warn(
        'Nearest-vendor fallback used stock-based assignment because no geo-qualified vendor was found.',
      );
      return fallbackVendorId;
    }
  }

  return bestVendorId;
}

export async function resolveNearestVendor(customer: any): Promise<string | null> {
  const radiusKm = 2;
  if (!customer?.latitude || !customer?.longitude) return null;

  const { data, error } = await supabaseAdmin.rpc('find_nearest_vendors', {
    p_latitude: Number(customer.latitude),
    p_longitude: Number(customer.longitude),
    p_radius_km: radiusKm,
    p_limit: 1,
  });

  if (error) {
    console.warn('Nearest-vendor RPC lookup failed, trying fallback resolver:', error.message);
    return resolveNearestVendorFallback(customer, radiusKm);
  }

  const nearest = Array.isArray(data) && data.length > 0 ? data[0] : null;
  const nearestVendorId = nearest?.vendor_id ? String(nearest.vendor_id) : null;
  return nearestVendorId;
}

export async function linkCustomerVendor(customerId: string, vendorId: string) {
  await supabaseAdmin.from('customer_vendors').upsert(
    {
      customer_id: customerId,
      vendor_id: vendorId,
    },
    { onConflict: 'customer_id,vendor_id' },
  );
}

/**
 * Model A: a customer is owned by exactly one vendor at a time
 * (customers.vendor_id, RLS-enforced). But that owning vendor can go on
 * vacation or become inactive — when that happens the customer must be
 * reassigned to an available alternative rather than getting stuck unable
 * to order. Moves the customer (updates vendor_id in place) rather than
 * creating a second customer row, since vendor_id is a single-owner column.
 */
export async function resolveOwningVendor(customer: any): Promise<{ vendorId: string | null; reassigned: boolean }> {
  const currentVendorId = customer?.vendor_id ? String(customer.vendor_id) : null;

  if (currentVendorId) {
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id, is_active, is_on_vacation')
      .eq('id', currentVendorId)
      .maybeSingle();

    if (vendor && vendor.is_active && !vendor.is_on_vacation) {
      return { vendorId: currentVendorId, reassigned: false };
    }
    console.warn(`Customer ${customer.id}'s vendor ${currentVendorId} is unavailable (active=${vendor?.is_active}, vacation=${vendor?.is_on_vacation}) — reassigning.`);
  }

  const nearestVendorId = await resolveNearestVendor(customer);
  if (!nearestVendorId) {
    return { vendorId: null, reassigned: false };
  }

  await supabaseAdmin.from('customers').update({ vendor_id: nearestVendorId }).eq('id', customer.id);
  await linkCustomerVendor(customer.id, nearestVendorId);
  customer.vendor_id = nearestVendorId;
  return { vendorId: nearestVendorId, reassigned: currentVendorId !== null };
}
