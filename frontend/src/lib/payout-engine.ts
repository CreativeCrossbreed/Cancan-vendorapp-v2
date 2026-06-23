import { supabaseAdmin } from '@/lib/supabase';
import { appendVendorWalletEntry } from '@/lib/finance-ledger';

type VendorBalance = {
  vendorId: string;
  balance: number;
};

function parseMissingColumn(errorMessage: string): string | null {
  const m = errorMessage.match(/Could not find the '([^']+)' column/);
  return m ? m[1] : null;
}

async function insertWithSchemaFallback(
  table: string,
  payload: Record<string, unknown>,
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
  throw new Error(`Unable to insert into ${table}`);
}

async function updateWithSchemaFallback(
  table: string,
  idColumn: string,
  idValue: string,
  payload: Record<string, unknown>,
  maxAttempts = 10,
): Promise<Record<string, unknown>> {
  const working = { ...payload };
  for (let i = 0; i < maxAttempts; i += 1) {
    const { data, error } = await supabaseAdmin
      .from(table)
      .update(working)
      .eq(idColumn, idValue)
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
  throw new Error(`Unable to update ${table}`);
}

async function calculateVendorBalances(): Promise<VendorBalance[]> {
  const { data: rows, error } = await supabaseAdmin
    .from('vendor_wallet_ledger')
    .select('vendor_id, entry_type, amount, status');

  if (error) throw error;

  const map = new Map<string, number>();
  for (const row of rows || []) {
    if (row.status && row.status !== 'posted') continue;
    const amount = Number(row.amount || 0);
    const sign = row.entry_type === 'debit' || row.entry_type === 'reversal' ? -1 : 1;
    map.set(row.vendor_id, Number((map.get(row.vendor_id) || 0) + sign * amount));
  }

  return [...map.entries()]
    .map(([vendorId, balance]) => ({ vendorId, balance: Number(balance.toFixed(2)) }))
    .filter((item) => item.balance > 0);
}

async function executeProviderPayout(vendorId: string) {
  const provider = process.env.PAYMENT_PROVIDER_DEFAULT || 'razorpay';
  const instantEnabled = process.env.ENABLE_REAL_PAYOUTS === 'true';

  if (!instantEnabled) {
    return {
      provider,
      providerPayoutId: `mock_payout_${vendorId.slice(0, 6)}_${Date.now()}`,
      status: 'paid' as const,
    };
  }

  throw new Error(
    `Real payout API is not implemented for provider=${provider}. Disable ENABLE_REAL_PAYOUTS or implement provider integration first.`,
  );
}

export async function runPayoutBatch(params: { createdBy: string; settlementDate?: string }) {
  const settlementDate = params.settlementDate || new Date().toISOString().split('T')[0];
  const provider = process.env.PAYMENT_PROVIDER_DEFAULT || 'razorpay';

  const { data: existingBatch } = await supabaseAdmin
    .from('payout_batches')
    .select('*')
    .eq('settlement_date', settlementDate)
    .in('status', ['scheduled', 'processing', 'partially_paid', 'paid'])
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (existingBatch) {
    return {
      batch: existingBatch,
      items: [],
      summary: {
        total_vendors: Number(existingBatch.total_vendors || 0),
        processed_amount: Number(existingBatch.processed_amount || 0),
        failed_amount: Number(existingBatch.failed_amount || 0),
        reused: true,
      },
    };
  }

  const balances = await calculateVendorBalances();

  const batch = await insertWithSchemaFallback('payout_batches', {
    provider,
    status: 'processing',
    settlement_date: settlementDate,
    total_vendors: balances.length,
    total_amount: balances.reduce((sum, item) => sum + item.balance, 0),
    processed_amount: 0,
    failed_amount: 0,
    created_by: params.createdBy,
    metadata: {
      source: 'api_payout_run',
    },
  });

  let processedAmount = 0;
  let failedAmount = 0;
  const items = [];

  for (const entry of balances) {
    const payoutItem = await insertWithSchemaFallback('payout_items', {
      batch_id: batch.id,
      vendor_id: entry.vendorId,
      provider,
      amount: entry.balance,
      currency: 'INR',
      status: 'processing',
      initiated_at: new Date().toISOString(),
    });

    try {
      const providerResult = await executeProviderPayout(entry.vendorId);
      const paidItem = await updateWithSchemaFallback('payout_items', 'id', String(payoutItem.id), {
        provider_payout_id: providerResult.providerPayoutId,
        status: providerResult.status,
        paid_at: new Date().toISOString(),
        metadata: {
          provider_response: providerResult,
        },
      });

      await appendVendorWalletEntry({
        vendorId: entry.vendorId,
        payoutItemId: String(paidItem.id),
        entryType: 'debit',
        sourceType: 'payout',
        amount: entry.balance,
        status: 'posted',
        notes: `Automated payout batch ${batch.id}`,
      });

      processedAmount += entry.balance;
      items.push(paidItem);
    } catch (itemError: unknown) {
      const message = itemError instanceof Error ? itemError.message : 'Payout failed';
      failedAmount += entry.balance;
      await updateWithSchemaFallback('payout_items', 'id', String(payoutItem.id), {
        status: 'failed',
        failure_reason: message,
      });
    }
  }

  const finalStatus = failedAmount > 0 ? (processedAmount > 0 ? 'partially_paid' : 'failed') : 'paid';
  const finalBatch = await updateWithSchemaFallback('payout_batches', 'id', String(batch.id), {
    status: finalStatus,
    processed_amount: Number(processedAmount.toFixed(2)),
    failed_amount: Number(failedAmount.toFixed(2)),
    updated_at: new Date().toISOString(),
  });

  return {
    batch: finalBatch,
    items,
    summary: {
      total_vendors: balances.length,
      processed_amount: Number(processedAmount.toFixed(2)),
      failed_amount: Number(failedAmount.toFixed(2)),
    },
  };
}
