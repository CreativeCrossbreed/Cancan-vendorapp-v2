#!/usr/bin/env node
import { createSupabaseAdminClient, logJson, parseArgs, readManifest, requireArg } from './lib/common.mjs';

function printHelp() {
  console.log(`
Cleanup E2E test data created by simulator/direct-seed.

Usage:
  node scripts/e2e/cleanup.mjs --test-run-id run001 --confirm [--dry-run]

Required:
  --test-run-id <id>
  --confirm              Required safety flag for destructive cleanup

Optional:
  --dry-run              Show what would be deleted, do not delete
`);
}

function uniqueIds(rows) {
  return [...new Set((rows || []).map((row) => row.id).filter(Boolean))];
}

async function deleteByIds(supabase, table, ids, dryRun) {
  if (!ids.length) return 0;
  if (dryRun) return ids.length;
  const { error } = await supabase.from(table).delete().in('id', ids);
  if (error) throw new Error(`Failed deleting ${table}: ${error.message}`);
  return ids.length;
}

async function deleteByCompoundKeys(supabase, table, rows, keyA, keyB, dryRun) {
  if (!rows.length) return 0;
  if (dryRun) return rows.length;
  let deleted = 0;
  for (const row of rows) {
    const a = row[keyA];
    const b = row[keyB];
    if (!a || !b) continue;
    const { error } = await supabase.from(table).delete().eq(keyA, a).eq(keyB, b);
    if (error) throw new Error(`Failed deleting ${table} (${a},${b}): ${error.message}`);
    deleted += 1;
  }
  return deleted;
}

async function cleanupFromManifest({ supabase, manifest, dryRun }) {
  const records = manifest.records || {};
  const runTag = `[E2E:${manifest.runId}]`;
  const taggedPhones = new Set((manifest.tags?.phones || []).map((p) => String(p)));
  const taggedCustomers = (records.customers || []).filter(
    (c) => String(c.name || '').includes(runTag) || taggedPhones.has(String(c.phone || '')),
  );
  const taggedCustomerIds = new Set(taggedCustomers.map((c) => c.id));

  const taggedOrders = (records.orders || []).filter((order) => {
    const orderCustomerId = order.customer_id;
    return (
      (orderCustomerId && taggedCustomerIds.has(orderCustomerId)) ||
      String(order.notes || '').includes(runTag) ||
      String(order.order_number || '').includes(`E2E-${manifest.runId}`) ||
      String(order.source || '') === 'e2e_seed'
    );
  });
  const taggedOrderIds = new Set(taggedOrders.map((order) => order.id));

  const taggedOrderItems = (records.order_items || []).filter((item) =>
    taggedOrderIds.has(item.order_id),
  );
  const taggedCustomerVendors = (records.customer_vendors || []).filter((row) =>
    taggedCustomerIds.has(row.customer_id),
  );

  const taggedMessages = (records.whatsapp_messages || []).filter(
    (row) =>
      String(row.message_id || '').startsWith(manifest.tags?.messageIdPrefix || '') ||
      taggedPhones.has(String(row.customer_phone || '')),
  );
  const taggedSessions = (records.whatsapp_sessions || []).filter((row) =>
    taggedPhones.has(String(row.phone_number || '')),
  );

  const taggedProducts = (records.products || []).filter((p) =>
    String(p.name || '').includes(runTag),
  );
  const taggedProductIds = new Set(taggedProducts.map((p) => p.id));
  const taggedVendorProducts = (records.vendor_products || []).filter(
    (row) =>
      taggedProductIds.has(row.product_id) || String(row.notes || '').includes(runTag),
  );

  const summary = {
    whatsapp_messages: 0,
    whatsapp_sessions: 0,
    order_items: 0,
    orders: 0,
    customer_vendors: 0,
    vendor_products: 0,
    customers: 0,
    products: 0,
  };

  // Child -> parent order
  summary.whatsapp_messages = await deleteByIds(
    supabase,
    'whatsapp_messages',
    uniqueIds(taggedMessages),
    dryRun,
  );
  summary.whatsapp_sessions = await deleteByIds(
    supabase,
    'whatsapp_sessions',
    uniqueIds(taggedSessions),
    dryRun,
  );
  summary.order_items = await deleteByIds(supabase, 'order_items', uniqueIds(taggedOrderItems), dryRun);
  summary.orders = await deleteByIds(supabase, 'orders', uniqueIds(taggedOrders), dryRun);
  summary.customer_vendors = await deleteByCompoundKeys(
    supabase,
    'customer_vendors',
    taggedCustomerVendors,
    'customer_id',
    'vendor_id',
    dryRun,
  );
  summary.vendor_products = await deleteByIds(
    supabase,
    'vendor_products',
    uniqueIds(taggedVendorProducts),
    dryRun,
  );
  summary.customers = await deleteByIds(supabase, 'customers', uniqueIds(taggedCustomers), dryRun);

  // Optional: only remove clearly tagged products
  summary.products = await deleteByIds(supabase, 'products', uniqueIds(taggedProducts), dryRun);

  return summary;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const runId = requireArg(args, 'test-run-id');
  const dryRun = Boolean(args['dry-run']);
  const confirm = Boolean(args.confirm);

  if (!dryRun && !confirm) {
    throw new Error('Refusing cleanup without --confirm flag');
  }

  const manifest = readManifest(runId);
  const supabase = dryRun ? null : createSupabaseAdminClient();
  const deleted = await cleanupFromManifest({ supabase, manifest, dryRun });

  logJson('Cleanup complete', {
    runId,
    dryRun,
    deleted,
  });
}

main().catch((error) => {
  console.error('[cleanup] failed:', error.message);
  process.exit(1);
});
