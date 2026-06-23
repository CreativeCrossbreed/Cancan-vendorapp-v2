import { supabaseAdmin } from '@/lib/supabase';

function parseMissingColumn(errorMessage: string): string | null {
  const m = errorMessage.match(/Could not find the '([^']+)' column/);
  return m ? m[1] : null;
}

async function insertWithSchemaFallback(
  table: string,
  payload: Record<string, unknown>,
  attempts = 10,
): Promise<Record<string, unknown>> {
  const working = { ...payload };
  for (let i = 0; i < attempts; i += 1) {
    const { data, error } = await supabaseAdmin.from(table).insert(working).select('*').single();
    if (!error) return data;

    const missing = parseMissingColumn(String(error.message || ''));
    if (missing) {
      delete working[missing];
      continue;
    }
    throw error;
  }
  throw new Error(`Failed to insert into ${table}`);
}

async function updateWithSchemaFallback(
  table: string,
  idColumn: string,
  idValue: string,
  payload: Record<string, unknown>,
  attempts = 10,
): Promise<Record<string, unknown>> {
  const working = { ...payload };
  for (let i = 0; i < attempts; i += 1) {
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
  throw new Error(`Failed to update ${table}`);
}

async function createIssue(runId: string, issue: Record<string, unknown>) {
  await insertWithSchemaFallback('reconciliation_issues', {
    run_id: runId,
    issue_type: issue.issue_type,
    severity: issue.severity || 'warning',
    order_id: issue.order_id || null,
    payment_id: issue.payment_id || null,
    payout_item_id: issue.payout_item_id || null,
    description: issue.description,
    expected_payload: issue.expected_payload || null,
    actual_payload: issue.actual_payload || null,
    status: 'open',
  });
}

export async function runReconciliation(runType: 'payments' | 'payouts' | 'full' = 'full') {
  const run = await insertWithSchemaFallback('reconciliation_runs', {
    run_type: runType,
    status: 'running',
    started_at: new Date().toISOString(),
  });

  let paymentIssues = 0;
  let payoutIssues = 0;

  try {
    if (runType === 'payments' || runType === 'full') {
      const { data: payments } = await supabaseAdmin
        .from('payments')
        .select('id, order_id, amount, status, provider_payment_id')
        .eq('status', 'completed')
        .order('created_at', { ascending: false })
        .limit(1000);

      const orderIds = [...new Set((payments || []).map((p) => p.order_id).filter(Boolean))];
      let ordersById = new Map<string, Record<string, unknown>>();
      if (orderIds.length > 0) {
        const { data: orders } = await supabaseAdmin
          .from('orders')
          .select('id, gross_amount, total_amount, payment_status')
          .in('id', orderIds);
        ordersById = new Map((orders || []).map((o) => [o.id, o]));
      }

      for (const payment of payments || []) {
        const order = ordersById.get(payment.order_id);
        if (!order) {
          paymentIssues += 1;
          await createIssue(String(run.id), {
            issue_type: 'orphan_payment',
            severity: 'critical',
            payment_id: payment.id,
            description: `Payment ${payment.id} has no matching order`,
            actual_payload: payment,
          });
          continue;
        }

        const expected = Number(order.gross_amount || order.total_amount || 0);
        const actual = Number(payment.amount || 0);
        if (Math.abs(expected - actual) > 0.01) {
          paymentIssues += 1;
          await createIssue(String(run.id), {
            issue_type: 'payment_amount_mismatch',
            severity: 'warning',
            order_id: order.id,
            payment_id: payment.id,
            description: `Payment ${payment.id} amount does not match order amount`,
            expected_payload: { expected_amount: expected },
            actual_payload: { actual_amount: actual },
          });
        }
      }
    }

    if (runType === 'payouts' || runType === 'full') {
      const { data: payoutItems } = await supabaseAdmin
        .from('payout_items')
        .select('id, vendor_id, amount, status')
        .eq('status', 'paid')
        .order('created_at', { ascending: false })
        .limit(1000);

      const { data: payoutLedgerRows } = await supabaseAdmin
        .from('vendor_wallet_ledger')
        .select('payout_item_id, amount, entry_type, source_type')
        .eq('source_type', 'payout')
        .eq('entry_type', 'debit');

      const ledgerByPayout = new Map<string, number>();
      for (const row of payoutLedgerRows || []) {
        if (!row.payout_item_id) continue;
        ledgerByPayout.set(
          row.payout_item_id,
          Number((ledgerByPayout.get(row.payout_item_id) || 0) + Number(row.amount || 0)),
        );
      }

      for (const payout of payoutItems || []) {
        const debited = Number(ledgerByPayout.get(payout.id) || 0);
        const expected = Number(payout.amount || 0);
        if (Math.abs(expected - debited) > 0.01) {
          payoutIssues += 1;
          await createIssue(String(run.id), {
            issue_type: 'payout_ledger_mismatch',
            severity: 'warning',
            payout_item_id: payout.id,
            description: `Payout ${payout.id} does not match wallet debit`,
            expected_payload: { expected_debit: expected },
            actual_payload: { actual_debit: debited },
          });
        }
      }
    }

    const summary = {
      payment_issues: paymentIssues,
      payout_issues: payoutIssues,
      total_issues: paymentIssues + payoutIssues,
    };

    const completedRun = await updateWithSchemaFallback('reconciliation_runs', 'id', String(run.id), {
      status: 'completed',
      completed_at: new Date().toISOString(),
      summary,
    });

    return {
      run: completedRun,
      summary,
    };
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Reconciliation failed';
    await updateWithSchemaFallback('reconciliation_runs', 'id', String(run.id), {
      status: 'failed',
      completed_at: new Date().toISOString(),
      error_message: message,
    });
    throw error;
  }
}
