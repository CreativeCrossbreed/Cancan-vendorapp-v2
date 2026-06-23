import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { runPayoutBatch } from '@/lib/payout-engine';

export async function POST(req: NextRequest) {
  const admin = await authenticateAdmin(req);
  const internalToken = req.headers.get('x-internal-token');
  const isInternal = Boolean(
    internalToken &&
      process.env.PAYMENT_INTERNAL_TOKEN &&
      internalToken === process.env.PAYMENT_INTERNAL_TOKEN,
  );
  if (!admin && !isInternal) return unauthorized();

  if (admin && admin.role !== 'super_admin') {
    return Response.json({ error: 'Only super admins can trigger payout runs' }, { status: 403 });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const settlementDate = body.settlement_date as string | undefined;
    const result = await runPayoutBatch({
      createdBy: admin?.email || 'system-cron',
      settlementDate,
    });

    return Response.json(result);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Failed to run payout batch';
    console.error('[POST /api/payouts/run] error', error);
    return Response.json({ error: message }, { status: 500 });
  }
}
