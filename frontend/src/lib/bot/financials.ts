import { supabaseAdmin } from '@/lib/supabase';
import { resolveOwningVendor } from '@/lib/bot/vendor-resolution';
import { DEFAULT_PER_BOTTLE_COMMISSION, DEFAULT_BOTTLE_PRICE } from '@/lib/bot/constants';

export type ResolvedOrderFinancials = {
  vendorId: string | null;
  vendorResolutionSource: 'linked' | 'nearest_2km' | 'none';
  productId: string | null;
  productName: string | null;
  unitPrice: number;
  bottleSubtotal: number;
  commissionPerBottle: number;
  commissionAmount: number;
  grossAmount: number;
  vendorNetAmount: number;
  pricingVersion: string;
  policyId: string | null;
};

// Resolve the owning vendor + pricing/commission for an order, applying the
// vendor's settlement policy and product price (with sane defaults).
export async function resolveOrderFinancials(
  customer: any,
  canCount: number,
  selectedProductId?: string | null,
): Promise<ResolvedOrderFinancials> {
  const { vendorId: resolvedVendorId, reassigned } = await resolveOwningVendor(customer);
  const vendorId = resolvedVendorId;
  const vendorResolutionSource: ResolvedOrderFinancials['vendorResolutionSource'] = !vendorId
    ? 'none'
    : reassigned
      ? 'nearest_2km'
      : 'linked';

  let policyId: string | null = null;
  let commissionPerBottle = DEFAULT_PER_BOTTLE_COMMISSION;
  if (vendorId) {
    const { data: policy } = await supabaseAdmin
      .from('settlement_policy')
      .select('id, per_bottle_commission, commission_type, is_active, is_default')
      .eq('vendor_id', vendorId)
      .eq('is_active', true)
      .order('is_default', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (policy?.id) {
      policyId = policy.id;
      if (policy.commission_type === 'per_bottle' && Number(policy.per_bottle_commission) > 0) {
        commissionPerBottle = Number(policy.per_bottle_commission);
      }
    }
  }

  let unitPrice = DEFAULT_BOTTLE_PRICE;
  let productId: string | null = null;
  let productName: string | null = null;
  if (vendorId) {
    let vendorProductQuery = supabaseAdmin
      .from('vendor_products')
      .select('product_id, selling_price, is_active')
      .eq('vendor_id', vendorId)
      .eq('is_active', true);

    if (selectedProductId) {
      vendorProductQuery = vendorProductQuery.eq('product_id', selectedProductId);
    } else {
      vendorProductQuery = vendorProductQuery.order('updated_at', { ascending: false }).limit(1);
    }

    const { data: vendorProduct } = await vendorProductQuery.maybeSingle();

    if (vendorProduct?.selling_price && Number(vendorProduct.selling_price) > 0) {
      unitPrice = Number(vendorProduct.selling_price);
    }
    if (vendorProduct?.product_id) {
      productId = String(vendorProduct.product_id);
      const { data: product } = await supabaseAdmin
        .from('products')
        .select('name')
        .eq('id', productId)
        .maybeSingle();
      productName = (product?.name as string | undefined) || null;
    }
  }

  const bottleSubtotal = Number((unitPrice * canCount).toFixed(2));
  const commissionAmount = Number((commissionPerBottle * canCount).toFixed(2));
  const grossAmount = Number((bottleSubtotal + commissionAmount).toFixed(2));
  const vendorNetAmount = Number((grossAmount - commissionAmount).toFixed(2));

  return {
    vendorId,
    vendorResolutionSource,
    productId,
    productName,
    unitPrice,
    bottleSubtotal,
    commissionPerBottle,
    commissionAmount,
    grossAmount,
    vendorNetAmount,
    pricingVersion: 'marketplace_v1',
    policyId,
  };
}

// The insert*WithFallback helpers tolerate schema drift between deploys: if the
// live DB is missing an optional column, drop it and retry rather than failing
// the whole order. Required columns (e.g. total_amount) still hard-fail.

export async function insertOrderWithFallback(payload: Record<string, any>) {
  const orderPayload = { ...payload };
  const requiredFinancialColumns = new Set([
    'total_amount',
  ]);

  for (let i = 0; i < 12; i += 1) {
    const { data, error } = await supabaseAdmin
      .from('orders')
      .insert(orderPayload)
      .select('id, delivery_date, time_slot, total_amount, vendor_id, order_number, can_count')
      .single();

    if (!error) {
      return { data, usedPayload: orderPayload };
    }

    // Duplicate idempotency_key (concurrent placeOrder for the same order) —
    // recover the row that won the race instead of throwing a dead-end.
    if ((error as any).code === '23505' && orderPayload.idempotency_key) {
      const { data: winner } = await supabaseAdmin
        .from('orders')
        .select('id, delivery_date, time_slot, total_amount, vendor_id, order_number, can_count')
        .eq('idempotency_key', orderPayload.idempotency_key)
        .maybeSingle();
      if (winner?.id) {
        return { data: winner, usedPayload: orderPayload, deduped: true };
      }
    }

    const errorMessage = String(error.message || '');
    const missingColumnMatch = errorMessage.match(/Could not find the '([^']+)' column/);
    if (missingColumnMatch) {
      const missingColumn = missingColumnMatch[1];
      if (requiredFinancialColumns.has(missingColumn)) {
        throw error;
      }
      delete orderPayload[missingColumn];
      continue;
    }

    throw error;
  }

  throw new Error('Unable to insert order after schema fallback attempts');
}

export async function insertCommissionLedgerWithFallback(payload: Record<string, any>) {
  const ledgerPayload = { ...payload };

  for (let i = 0; i < 10; i += 1) {
    const { error } = await supabaseAdmin.from('commission_ledger').insert(ledgerPayload);
    if (!error) return;

    const errorMessage = String(error.message || '');
    const missingColumnMatch = errorMessage.match(/Could not find the '([^']+)' column/);
    if (missingColumnMatch) {
      delete ledgerPayload[missingColumnMatch[1]];
      continue;
    }
    // If table is absent in older DBs, do not break order flow.
    if (
      errorMessage.includes('relation "commission_ledger" does not exist') ||
      errorMessage.includes('Could not find the table')
    ) {
      return;
    }
    throw error;
  }
}

export async function insertOrderItemWithFallback(payload: Record<string, any>) {
  const itemPayload = { ...payload };

  for (let i = 0; i < 10; i += 1) {
    const { error } = await supabaseAdmin.from('order_items').insert(itemPayload);
    if (!error) return;

    const errorMessage = String(error.message || '');
    const missingColumnMatch = errorMessage.match(/Could not find the '([^']+)' column/);
    if (missingColumnMatch) {
      delete itemPayload[missingColumnMatch[1]];
      continue;
    }
    if (
      errorMessage.includes('relation "order_items" does not exist') ||
      errorMessage.includes('Could not find the table')
    ) {
      return;
    }
    throw error;
  }
}
