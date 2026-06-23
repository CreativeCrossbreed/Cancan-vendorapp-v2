#!/usr/bin/env node
import {
  createSupabaseAdminClient,
  getTableColumns,
  logJson,
  makePhoneForRun,
  nowIso,
  parseArgs,
  requireArg,
  writeManifest,
} from './lib/common.mjs';

function printHelp() {
  console.log(`
Optional direct seed helper for E2E edge states.

Usage:
  node scripts/e2e/direct-seed.mjs --test-run-id run001 --vendor-id <uuid> --scenario unpaid-orders

Required:
  --test-run-id <id>
  --vendor-id <uuid>

Optional:
  --scenario <name>        unpaid-orders | low-stock (default: unpaid-orders)
  --count <number>         number of records to seed (default: 2)
  --dry-run                print planned inserts only
`);
}

async function ensureBaseProduct(supabase, runId, dryRun = false, suffix = 'base') {
  const productsCols = await getTableColumns(supabase, 'products');
  const payload = {};

  if (productsCols.has('name')) payload.name = `[E2E:${runId}] 20L Can ${suffix}`;
  if (productsCols.has('price')) payload.price = 30;
  if (productsCols.has('description')) payload.description = 'E2E seeded product';
  if (productsCols.has('category')) payload.category = 'water_can';
  if (productsCols.has('is_active')) payload.is_active = true;

  if (dryRun) {
    return { id: `dry-product-${runId}`, payload };
  }

  const { data: existing } = await supabase
    .from('products')
    .select('*')
    .eq('name', payload.name)
    .limit(1)
    .maybeSingle();
  if (existing) return existing;

  const { data, error } = await supabase.from('products').insert(payload).select().single();
  if (error) throw new Error(`Failed to create product: ${error.message}`);
  return data;
}

async function createCustomer(supabase, runId, index, dryRun = false) {
  const phone = makePhoneForRun(runId, index + 100);
  const customerPayload = {
    phone,
    name: `[E2E:${runId}] Seed Customer ${index + 1}`,
    address: `E2E Test Address ${index + 1}`,
    flat_number: `F-${index + 1}`,
    floor: `${index + 1}`,
    building_name: 'E2E Towers',
  };

  if (dryRun) return { id: `dry-customer-${index}`, ...customerPayload };

  const { data, error } = await supabase
    .from('customers')
    .upsert(customerPayload, { onConflict: 'phone' })
    .select()
    .single();
  if (error) throw new Error(`Failed to upsert customer: ${error.message}`);
  return data;
}

function buildOrderPayload(columns, { runId, vendorId, customerId, index, totalAmount }) {
  const today = new Date();
  const deliveryDate = today.toISOString().split('T')[0];
  const orderNumber = `E2E-${runId}-${String(index + 1).padStart(3, '0')}`;
  const payload = {};

  if (columns.has('order_number')) payload.order_number = orderNumber;
  if (columns.has('vendor_id')) payload.vendor_id = vendorId;
  if (columns.has('customer_id')) payload.customer_id = customerId;
  if (columns.has('delivery_date')) payload.delivery_date = deliveryDate;
  if (columns.has('time_slot')) payload.time_slot = 'morning';
  if (columns.has('delivery_time_slot')) payload.delivery_time_slot = 'morning';
  if (columns.has('total_amount')) payload.total_amount = totalAmount;
  if (columns.has('subtotal')) payload.subtotal = totalAmount;
  if (columns.has('status')) payload.status = 'completed';
  if (columns.has('is_delivered')) payload.is_delivered = true;
  if (columns.has('delivered_at')) payload.delivered_at = nowIso();
  if (columns.has('payment_status')) payload.payment_status = 'unpaid';
  if (columns.has('amount_paid')) payload.amount_paid = Math.max(totalAmount - 40, 0);
  if (columns.has('remaining_amount')) payload.remaining_amount = 40;
  if (columns.has('notes')) payload.notes = `[E2E:${runId}] Seeded unpaid order`;
  if (columns.has('source')) payload.source = 'e2e_seed';
  if (columns.has('delivery_address')) payload.delivery_address = 'E2E Seed Address';
  if (columns.has('order_items')) payload.order_items = [{ name: '20L Can', qty: 1 }];

  return payload;
}

async function seedUnpaidOrders({ supabase, runId, vendorId, count, dryRun }) {
  const orderColumns = await getTableColumns(supabase, 'orders');
  const itemColumns = await getTableColumns(supabase, 'order_items');
  const product = await ensureBaseProduct(supabase, runId, dryRun, 'orders');
  const seeded = { customers: [], orders: [], order_items: [], products: [product] };

  for (let i = 0; i < count; i += 1) {
    const customer = await createCustomer(supabase, runId, i, dryRun);
    seeded.customers.push(customer);

    const totalAmount = 120 + i * 10;
    const orderPayload = buildOrderPayload(orderColumns, {
      runId,
      vendorId,
      customerId: customer.id,
      index: i,
      totalAmount,
    });

    if (dryRun) {
      const fakeOrder = { id: `dry-order-${i}`, ...orderPayload };
      seeded.orders.push(fakeOrder);
      if (itemColumns.has('order_id')) {
        seeded.order_items.push({
          id: `dry-item-${i}`,
          order_id: fakeOrder.id,
          product_id: product.id,
          quantity: 1,
          unit_price: totalAmount,
          subtotal: totalAmount,
        });
      }
      continue;
    }

    const { data: order, error } = await supabase
      .from('orders')
      .insert(orderPayload)
      .select()
      .single();
    if (error) throw new Error(`Failed to seed order: ${error.message}`);
    seeded.orders.push(order);

    if (itemColumns.has('order_id') && itemColumns.has('product_id')) {
      const itemPayload = {
        order_id: order.id,
        product_id: product.id,
        quantity: 1,
        unit_price: totalAmount,
        subtotal: totalAmount,
      };
      const { data: orderItem, error: itemError } = await supabase
        .from('order_items')
        .insert(itemPayload)
        .select()
        .single();
      if (itemError) throw new Error(`Failed to seed order_item: ${itemError.message}`);
      seeded.order_items.push(orderItem);
    }
  }

  return seeded;
}

async function seedLowStock({ supabase, runId, vendorId, count, dryRun }) {
  const vpColumns = await getTableColumns(supabase, 'vendor_products');
  const rows = [];
  const products = [];

  for (let i = 0; i < count; i += 1) {
    const product = await ensureBaseProduct(supabase, runId, dryRun, `stock-${i + 1}`);
    products.push(product);
    const payload = {};
    if (vpColumns.has('vendor_id')) payload.vendor_id = vendorId;
    if (vpColumns.has('product_id')) payload.product_id = product.id;
    if (vpColumns.has('selling_price')) payload.selling_price = 30 + i;
    if (vpColumns.has('deposit_amount')) payload.deposit_amount = 50;
    if (vpColumns.has('current_stock')) payload.current_stock = i; // 0,1,... low/out
    if (vpColumns.has('low_stock_threshold')) payload.low_stock_threshold = 5;
    if (vpColumns.has('is_active')) payload.is_active = true;

    if (dryRun) {
      rows.push({ id: `dry-vp-${i}`, ...payload });
      continue;
    }

    const { data, error } = await supabase
      .from('vendor_products')
      .upsert(payload, { onConflict: 'vendor_id,product_id' })
      .select()
      .single();
    if (error) throw new Error(`Failed to seed vendor_products: ${error.message}`);
    rows.push(data);
  }

  return { products, vendor_products: rows };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const runId = requireArg(args, 'test-run-id');
  const vendorId = requireArg(args, 'vendor-id');
  const scenario = String(args.scenario || 'unpaid-orders');
  const count = Number(args.count || 2);
  const dryRun = Boolean(args['dry-run']);

  const supabase = dryRun ? null : createSupabaseAdminClient();

  let records;
  if (scenario === 'unpaid-orders') {
    records = await seedUnpaidOrders({ supabase, runId, vendorId, count, dryRun });
  } else if (scenario === 'low-stock') {
    records = await seedLowStock({ supabase, runId, vendorId, count, dryRun });
  } else {
    throw new Error(`Unsupported seed scenario "${scenario}"`);
  }

  const phones = (records.customers || []).map((c) => c.phone).filter(Boolean);
  const manifest = {
    runId,
    scenario: `direct-seed:${scenario}`,
    baseUrl: null,
    vendorId,
    dryRun,
    createdAt: nowIso(),
    tags: {
      phones,
      messageIdPrefix: null,
    },
    messageIds: [],
    records,
  };

  const manifestPath = writeManifest(manifest);
  logJson('Direct seed complete', {
    runId,
    scenario,
    dryRun,
    count,
    manifestPath,
    summary: {
      customers: records.customers?.length || 0,
      orders: records.orders?.length || 0,
      order_items: records.order_items?.length || 0,
      vendor_products: records.vendor_products?.length || 0,
    },
  });
}

main().catch((error) => {
  console.error('[direct-seed] failed:', error.message);
  process.exit(1);
});
