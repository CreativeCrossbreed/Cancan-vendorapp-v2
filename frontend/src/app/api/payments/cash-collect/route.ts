import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { supabaseAdmin } from '@/lib/supabase';
import {
  appendVendorWalletEntry,
  createPaymentRecord,
  updateOrderFinancialState,
} from '@/lib/finance-ledger';

export async function POST(req: NextRequest) {
  const admin = await authenticateAdmin(req);
  if (!admin) return unauthorized();

  try {
    const body = await req.json();
    const orderId = String(body.order_id || '');
    const amount = Number(body.amount || 0);
    const paymentMethod = String(body.payment_method || 'cash');
    const notes = String(body.notes || 'Cash collected by platform');

    if (!orderId || amount <= 0) {
      return Response.json({ error: 'order_id and positive amount are required' }, { status: 400 });
    }

    const { data: order, error: orderError } = await supabaseAdmin
      .from('orders')
      .select('id, vendor_id, customer_id, total_amount, gross_amount, platform_commission_amount, vendor_net_amount, amount_paid')
      .eq('id', orderId)
      .single();

    if (orderError || !order) {
      return Response.json({ error: 'Order not found' }, { status: 404 });
    }

    const grossAmount = Number(order.gross_amount || order.total_amount || amount);
    const commission = Number(order.platform_commission_amount || 0);
    const vendorNet = Number(order.vendor_net_amount || Math.max(grossAmount - commission, 0));
    const alreadyPaid = Number(order.amount_paid || 0);
    const newAmountPaid = Number((alreadyPaid + amount).toFixed(2));
    const remaining = Number(Math.max(grossAmount - newAmountPaid, 0).toFixed(2));

    const payment = await createPaymentRecord({
      orderId: order.id,
      vendorId: order.vendor_id,
      customerId: order.customer_id,
      provider: 'cash',
      providerPaymentId: `cash_${order.id}_${Date.now()}`,
      collectionMode: 'cash_platform',
      amount,
      paymentMethod,
      platformCommission: commission,
      vendorPayable: Number((amount - (commission > 0 ? (commission * (amount / grossAmount)) : 0)).toFixed(2)),
      status: 'completed',
      idempotencyKey: `cash:${order.id}:${Date.now()}`,
      metadata: {
        notes,
        collected_by: admin.email,
      },
    });

    await updateOrderFinancialState(order.id, {
      payment_state: remaining <= 0 ? 'collected_cash_platform' : 'partially_collected_cash_platform',
      payment_status: remaining <= 0 ? 'paid' : 'unpaid',
      payment_method: paymentMethod,
      payment_reference: payment.id,
      amount_paid: newAmountPaid,
      remaining_amount: remaining,
      payment_marked_at: new Date().toISOString(),
    });

    if (order.vendor_id) {
      const vendorShareForThisCollection = Number(((vendorNet / grossAmount) * amount).toFixed(2));
      const paymentId = (payment.id as string | null | undefined) ?? null;
      const { data: existingLedgerEntry } = paymentId
        ? await supabaseAdmin
            .from('vendor_wallet_ledger')
            .select('id')
            .eq('payment_id', paymentId)
            .eq('vendor_id', order.vendor_id)
            .maybeSingle()
        : { data: null };
      if (!existingLedgerEntry) {
        await appendVendorWalletEntry({
          vendorId: order.vendor_id,
          orderId: order.id,
          paymentId,
          entryType: 'credit',
          sourceType: 'cash_collection',
          amount: vendorShareForThisCollection,
          status: 'posted',
          notes: `Cash collected by CanCan and credited to vendor wallet`,
        });
      }
    }

    return Response.json({
      success: true,
      payment,
      order: {
        id: order.id,
        amount_paid: newAmountPaid,
        remaining_amount: remaining,
        payment_status: remaining <= 0 ? 'paid' : 'unpaid',
      },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Failed to record cash collection';
    console.error('[POST /api/payments/cash-collect] error', error);
    return Response.json({ error: message }, { status: 500 });
  }
}
