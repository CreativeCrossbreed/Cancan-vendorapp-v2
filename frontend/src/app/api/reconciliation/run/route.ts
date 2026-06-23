import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { runReconciliation } from '@/lib/reconciliation';

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
    return Response.json({ error: 'Only super admins can run reconciliation' }, { status: 403 });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const runType = (body.run_type || 'full') as 'payments' | 'payouts' | 'full';
    const result = await runReconciliation(runType);
    return Response.json(result);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Failed reconciliation run';
    console.error('[POST /api/reconciliation/run] error', error);
    return Response.json({ error: message }, { status: 500 });
  }
}
