#!/usr/bin/env node
import {
  createSupabaseAdminClient,
  getTableColumns,
  logJson,
  makeMessageId,
  makePhoneForRun,
  nowIso,
  parseArgs,
  requireArg,
  writeManifest,
} from './lib/common.mjs';

function printHelp() {
  console.log(`
Dummy WhatsApp webhook simulator for vendor E2E runs.

Usage:
  node scripts/e2e/whatsapp-simulator.mjs --base-url http://localhost:3000 --test-run-id run001 --vendor-id <uuid> [options]

Required:
  --base-url <url>         Next.js base URL where /api/whatsapp/webhook is running
  --test-run-id <id>       Deterministic run id used for tagging and cleanup
  --vendor-id <uuid>       Vendor UUID to link onboarding/order records

Optional:
  --scenario <name>        onboarding-order | repeat-order | multi-customer (default: onboarding-order)
  --brand-product-id <id>  Optional product UUID for brand_<id> selection
  --customers <count>      Used by multi-customer scenario (default: 3)
  --step-delay-ms <ms>     Delay between webhook events (default: 300)
  --dry-run                Print events only, do not send
`);
}

function textMessage(id, body) {
  return { id, type: 'text', text: { body } };
}

function locationMessage(id, latitude, longitude) {
  return { id, type: 'location', location: { latitude, longitude } };
}

function buttonReplyMessage(id, replyId, title = 'Button') {
  return {
    id,
    type: 'interactive',
    interactive: {
      type: 'button_reply',
      button_reply: { id: replyId, title },
    },
  };
}

function listReplyMessage(id, replyId, title = 'Option') {
  return {
    id,
    type: 'interactive',
    interactive: {
      type: 'list_reply',
      list_reply: { id: replyId, title },
    },
  };
}

async function resolveBrandReplyId({ supabase, vendorId, explicitProductId }) {
  if (explicitProductId) {
    return {
      replyId: `brand_${explicitProductId}`,
      title: 'Selected Brand',
    };
  }

  let productRows = [];
  let error;

  ({ data: productRows, error } = await supabase
    .from('vendor_products')
    .select('product_id, current_stock, is_active, products(name)')
    .eq('vendor_id', vendorId)
    .eq('is_active', true)
    .gt('current_stock', 0)
    .order('updated_at', { ascending: false })
    .limit(1));

  if (error) {
    ({ data: productRows, error } = await supabase
      .from('vendor_products')
      .select('product_id, current_stock, products(name)')
      .eq('vendor_id', vendorId)
      .gt('current_stock', 0)
      .order('updated_at', { ascending: false })
      .limit(1));
  }

  if (error || !productRows || productRows.length === 0) {
    throw new Error(
      `Unable to resolve in-stock brand for vendor ${vendorId}. Seed vendor_products before running simulator.`,
    );
  }

  const row = productRows[0];
  const productId = String(row.product_id || '').trim();
  if (!productId) {
    throw new Error(`Resolved vendor product has empty product_id for vendor ${vendorId}`);
  }

  const productName = row.products?.name ? String(row.products.name) : 'Brand';
  return {
    replyId: `brand_${productId}`,
    title: productName.substring(0, 24) || 'Brand',
  };
}

async function postWebhook(baseUrl, message, customerPhone, dryRun = false) {
  const payload = {
    object: 'whatsapp_business_account',
    entry: [
      {
        id: 'e2e-entry',
        changes: [
          {
            field: 'messages',
            value: {
              messaging_product: 'whatsapp',
              contacts: [{ wa_id: customerPhone }],
              messages: [message],
            },
          },
        ],
      },
    ],
  };

  if (dryRun) {
    logJson(`[DRY RUN] Would post message ${message.id}`, payload);
    return;
  }

  const url = `${baseUrl.replace(/\/$/, '')}/api/whatsapp/webhook`;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  let response;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Webhook POST failed (${response.status}): ${body}`);
  }
}

async function runOnboardingOrderFlow({
  supabase,
  baseUrl,
  runId,
  vendorId,
  brandProductId,
  customerPhone,
  dryRun,
  stepDelayMs,
  stepOffset = 0,
}) {
  const latitude = 12.9716;
  const longitude = 77.5946;
  const customerName = `[E2E:${runId}] Customer ${customerPhone.slice(-4)}`;
  const brandSelection = await resolveBrandReplyId({
    supabase,
    vendorId,
    explicitProductId: brandProductId,
  });

  const events = [
    textMessage(makeMessageId(runId, customerPhone, stepOffset + 1), `ref-${vendorId}`),
    textMessage(makeMessageId(runId, customerPhone, stepOffset + 2), customerName),
    locationMessage(makeMessageId(runId, customerPhone, stepOffset + 3), latitude, longitude),
    buttonReplyMessage(makeMessageId(runId, customerPhone, stepOffset + 4), 'onboard_addr_yes', 'Yes'),
    textMessage(makeMessageId(runId, customerPhone, stepOffset + 5), 'hi'),
    buttonReplyMessage(makeMessageId(runId, customerPhone, stepOffset + 6), 'menu_order_water', 'Order Water'),
    listReplyMessage(
      makeMessageId(runId, customerPhone, stepOffset + 7),
      brandSelection.replyId,
      brandSelection.title,
    ),
    buttonReplyMessage(makeMessageId(runId, customerPhone, stepOffset + 8), 'qty_2', '2 Cans'),
    buttonReplyMessage(
      makeMessageId(runId, customerPhone, stepOffset + 9),
      `date_${new Date().toISOString().split('T')[0]}`,
      'Today',
    ),
    buttonReplyMessage(makeMessageId(runId, customerPhone, stepOffset + 10), 'slot_morning', 'Morning'),
    buttonReplyMessage(makeMessageId(runId, customerPhone, stepOffset + 11), 'confirm_order', 'Confirm'),
  ];

  for (const event of events) {
    await postWebhook(baseUrl, event, customerPhone, dryRun);
    if (stepDelayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, stepDelayMs));
    }
  }

  return events.map((event) => event.id);
}

async function runRepeatOrderFlow({
  supabase,
  baseUrl,
  runId,
  vendorId,
  brandProductId,
  customerPhone,
  dryRun,
  stepDelayMs,
}) {
  const orderEventIds = await runOnboardingOrderFlow({
    supabase,
    baseUrl,
    runId,
    vendorId,
    brandProductId,
    customerPhone,
    dryRun,
    stepDelayMs,
    stepOffset: 0,
  });

  const repeatEvents = [
    textMessage(makeMessageId(runId, customerPhone, 20), 'hi'),
    buttonReplyMessage(makeMessageId(runId, customerPhone, 21), 'menu_repeat_last', 'Repeat'),
    buttonReplyMessage(makeMessageId(runId, customerPhone, 22), 'repeat_confirm', 'Confirm'),
  ];

  for (const event of repeatEvents) {
    await postWebhook(baseUrl, event, customerPhone, dryRun);
    if (stepDelayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, stepDelayMs));
    }
  }

  return [...orderEventIds, ...repeatEvents.map((event) => event.id)];
}

async function captureImpactedRows({ supabase, runId, phones }) {
  const tables = ['customers', 'customer_vendors', 'orders', 'whatsapp_sessions', 'whatsapp_messages'];
  const snapshot = {};

  for (const table of tables) {
    const columns = await getTableColumns(supabase, table);

    if (table === 'customers' && columns.has('phone')) {
      const { data } = await supabase.from('customers').select('*').in('phone', phones);
      snapshot.customers = data || [];
    }

    if (table === 'whatsapp_sessions' && columns.has('phone_number')) {
      const { data } = await supabase.from('whatsapp_sessions').select('*').in('phone_number', phones);
      snapshot.whatsapp_sessions = data || [];
    }

    if (table === 'whatsapp_messages' && columns.has('message_id')) {
      const { data } = await supabase
        .from('whatsapp_messages')
        .select('*')
        .or(phones.map((p) => `customer_phone.eq.${p}`).join(','));
      snapshot.whatsapp_messages = (data || []).filter(
        (row) => String(row.message_id || '').startsWith(`e2e_${runId}_`),
      );
    }

    if (table === 'orders') {
      let orders = [];
      if (snapshot.customers?.length) {
        const customerIds = snapshot.customers.map((c) => c.id);
        let ordersQuery = supabase.from('orders').select('*').in('customer_id', customerIds);
        if (columns.has('source')) {
          ordersQuery = ordersQuery.eq('source', 'whatsapp');
        }
        const { data } = await ordersQuery;
        orders = data || [];
      }

      if (columns.has('customer_id') && snapshot.customers?.length) {
        const customerIds = new Set(snapshot.customers.map((c) => c.id));
        orders = orders.filter((order) => customerIds.has(order.customer_id));
      }
      snapshot.orders = orders;
    }

    if (table === 'customer_vendors' && snapshot.customers?.length) {
      const customerIds = snapshot.customers.map((c) => c.id);
      const { data } = await supabase
        .from('customer_vendors')
        .select('*')
        .in('customer_id', customerIds);
      snapshot.customer_vendors = data || [];
    }
  }

  return snapshot;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  const baseUrl = requireArg(args, 'base-url');
  const runId = requireArg(args, 'test-run-id');
  const vendorId = requireArg(args, 'vendor-id');
  const scenario = String(args.scenario || 'onboarding-order');
  const brandProductId = args['brand-product-id'] ? String(args['brand-product-id']) : null;
  const dryRun = Boolean(args['dry-run']);
  const customerCount = Number(args.customers || 3);
  const stepDelayMs = Number(args['step-delay-ms'] || 300);
  const supabase = createSupabaseAdminClient();

  const phones = [];
  const allMessageIds = [];

  if (scenario === 'onboarding-order') {
    const phone = makePhoneForRun(runId, 0);
    phones.push(phone);
    allMessageIds.push(
      ...(await runOnboardingOrderFlow({
        supabase,
        baseUrl,
        runId,
        vendorId,
        brandProductId,
        customerPhone: phone,
        dryRun,
        stepDelayMs,
      })),
    );
  } else if (scenario === 'repeat-order') {
    const phone = makePhoneForRun(runId, 0);
    phones.push(phone);
    allMessageIds.push(
      ...(await runRepeatOrderFlow({
        supabase,
        baseUrl,
        runId,
        vendorId,
        brandProductId,
        customerPhone: phone,
        dryRun,
        stepDelayMs,
      })),
    );
  } else if (scenario === 'multi-customer') {
    for (let i = 0; i < customerCount; i += 1) {
      const phone = makePhoneForRun(runId, i);
      phones.push(phone);
      allMessageIds.push(
        ...(await runOnboardingOrderFlow({
          supabase,
          baseUrl,
          runId,
          vendorId,
          brandProductId,
          customerPhone: phone,
          dryRun,
          stepDelayMs,
          stepOffset: i * 100,
        })),
      );
    }
  } else {
    throw new Error(`Unsupported scenario "${scenario}"`);
  }

  const manifest = {
    runId,
    scenario,
    baseUrl,
    vendorId,
    dryRun,
    createdAt: nowIso(),
    tags: {
      phones,
      messageIdPrefix: `e2e_${runId}_`,
    },
    messageIds: allMessageIds,
    records: {},
  };

  if (!dryRun) {
    manifest.records = await captureImpactedRows({ supabase, runId, phones });
  }

  const manifestPath = writeManifest(manifest);
  logJson('E2E simulator run complete', {
    runId,
    scenario,
    dryRun,
    phones,
    messageCount: allMessageIds.length,
    manifestPath,
  });
}

main().catch((error) => {
  console.error('[whatsapp-simulator] failed:', error.message);
  process.exit(1);
});
