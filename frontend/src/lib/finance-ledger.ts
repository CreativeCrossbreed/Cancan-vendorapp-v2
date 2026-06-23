import { supabaseAdmin } from '@/lib/supabase';

type JsonObject = Record<string, unknown>;

function parseMissingColumn(errorMessage: string): string | null {
  const m = errorMessage.match(/Could not find the '([^']+)' column/);
  return m ? m[1] : null;
}

async function insertWithSchemaFallback(
  table: string,
  payload: JsonObject,
  maxAttempts = 10,
): Promise<Record<string, unknown>> {
  const working = { ...payload };
  for (let i = 0; i < maxAttempts; i += 1) {
    const { data, error } = await supabaseAdmin.from(table).insert(working).select('*').single();
    if (!error) return data;

    const missing = parseMissingColumn(String(error.message || ''));
    if (missing) {
      delete working[missing];
      continue;
    }
    throw error;
  }

  throw new Error(`Insert failed for ${table} after schema fallback attempts`);
}

async function updateWithSchemaFallback(
  table: string,
  matchColumn: string,
  matchValue: string,
  payload: JsonObject,
  maxAttempts = 10,
): Promise<Record<string, unknown>> {
  const working = { ...payload };
  for (let i = 0; i < maxAttempts; i += 1) {
    const { data, error } = await supabaseAdmin
      .from(table)
      .update(working)
      .eq(matchColumn, matchValue)
      .select('*')
      .single();
    if (!error) return data;

    const missing = parseMissingColumn(String(error.message || ''));
    if (missing) {
      delete working[missing];
      continue;
    }
    throw error;
  }

  throw new Error(`Update failed for ${table} after schema fallback attempts`);
}

export async function createPaymentIntentRecord(params: {
  orderId: string;
  customerId?: string | null;
  vendorId?: string | null;
  provider: string;
  providerOrderId: string;
  amount: number;
  checkoutUrl?: string | null;
  idempotencyKey: string;
  metadata?: JsonObject;
}) {
  return insertWithSchemaFallback('payment_intents', {
    order_id: params.orderId,
    customer_id: params.customerId || null,
    vendor_id: params.vendorId || null,
    provider: params.provider,
    provider_order_id: params.providerOrderId,
    amount: params.amount,
    currency: 'INR',
    status: 'created',
    checkout_url: params.checkoutUrl || null,
    idempotency_key: params.idempotencyKey,
    metadata: params.metadata || {},
  });
}

export async function markPaymentIntentStatus(intentId: string, status: string, metadata?: JsonObject) {
  return updateWithSchemaFallback('payment_intents', 'id', intentId, {
    status,
    updated_at: new Date().toISOString(),
    metadata: metadata || {},
  });
}

export async function createPaymentRecord(params: {
  orderId: string;
  paymentIntentId?: string | null;
  vendorId?: string | null;
  customerId?: string | null;
  provider?: string | null;
  providerPaymentId?: string | null;
  collectionMode: 'online' | 'cash_platform' | 'cash_vendor';
  amount: number;
  paymentMethod?: string | null;
  gatewayFee?: number;
  gatewayTax?: number;
  platformCommission?: number;
  vendorPayable?: number;
  status?: string;
  idempotencyKey: string;
  metadata?: JsonObject;
}) {
  return insertWithSchemaFallback('payments', {
    order_id: params.orderId,
    payment_intent_id: params.paymentIntentId || null,
    vendor_id: params.vendorId || null,
    customer_id: params.customerId || null,
    provider: params.provider || null,
    provider_payment_id: params.providerPaymentId || null,
    collection_mode: params.collectionMode,
    payment_method: params.paymentMethod || null,
    payment_method_detail: params.paymentMethod || null,
    amount: params.amount,
    gateway_fee: params.gatewayFee || 0,
    gateway_tax: params.gatewayTax || 0,
    platform_commission: params.platformCommission || 0,
    vendor_payable: params.vendorPayable || params.amount,
    status: params.status || 'completed',
    captured_at: new Date().toISOString(),
    idempotency_key: params.idempotencyKey,
    metadata: params.metadata || {},
  });
}

export async function appendVendorWalletEntry(params: {
  vendorId: string;
  orderId?: string | null;
  paymentId?: string | null;
  payoutItemId?: string | null;
  entryType: 'credit' | 'debit' | 'hold' | 'release' | 'reversal';
  sourceType: 'online_payment' | 'cash_collection' | 'commission' | 'payout' | 'adjustment' | 'refund';
  amount: number;
  status?: 'pending' | 'posted' | 'cancelled';
  notes?: string | null;
  metadata?: JsonObject;
}) {
  const { data: rpcData, error: rpcError } = await supabaseAdmin.rpc('append_vendor_wallet_entry', {
    p_vendor_id: params.vendorId,
    p_order_id: params.orderId || null,
    p_payment_id: params.paymentId || null,
    p_payout_item_id: params.payoutItemId || null,
    p_entry_type: params.entryType,
    p_source_type: params.sourceType,
    p_amount: Number(params.amount),
    p_status: params.status || 'posted',
    p_notes: params.notes || null,
    p_metadata: params.metadata || {},
  });

  if (!rpcError && rpcData) {
    return rpcData as Record<string, unknown>;
  }

  // Fallback for environments where migration has not yet been applied.
  const { data: latest } = await supabaseAdmin
    .from('vendor_wallet_ledger')
    .select('balance_after')
    .eq('vendor_id', params.vendorId)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  const previousBalance = Number(latest?.balance_after || 0);
  const nextBalance =
    params.entryType === 'debit' || params.entryType === 'reversal'
      ? previousBalance - Number(params.amount)
      : previousBalance + Number(params.amount);

  return insertWithSchemaFallback('vendor_wallet_ledger', {
    vendor_id: params.vendorId,
    order_id: params.orderId || null,
    payment_id: params.paymentId || null,
    payout_item_id: params.payoutItemId || null,
    entry_type: params.entryType,
    source_type: params.sourceType,
    amount: Number(params.amount),
    balance_after: Number(nextBalance.toFixed(2)),
    status: params.status || 'posted',
    notes: params.notes || null,
    metadata: params.metadata || {},
  });
}

export async function updateOrderFinancialState(orderId: string, payload: JsonObject) {
  return updateWithSchemaFallback('orders', 'id', orderId, payload);
}
