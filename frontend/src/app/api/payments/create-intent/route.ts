import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { supabaseAdmin } from '@/lib/supabase';
import { createProviderOrder, SupportedProvider } from '@/lib/payment-gateway';
import { createPaymentIntentRecord } from '@/lib/finance-ledger';

function isInternalRequest(req: NextRequest) {
  const token = req.headers.get('x-internal-token');
  const expected = process.env.PAYMENT_INTERNAL_TOKEN;
  return Boolean(token && expected && token === expected);
}

export async function POST(req: NextRequest) {
  const admin = await authenticateAdmin(req);
  if (!admin && !isInternalRequest(req)) return unauthorized();

  try {
    const body = await req.json();
    const orderId = String(body.order_id || '');
    const provider = (body.provider || process.env.PAYMENT_PROVIDER_DEFAULT || 'cashfree') as SupportedProvider;
    const idempotencyKey = String(body.idempotency_key || `${orderId}:${provider}:intent`);

    if (!orderId) {
      return Response.json({ error: 'order_id is required' }, { status: 400 });
    }

    const { data: existingIntent } = await supabaseAdmin
      .from('payment_intents')
      .select('*')
      .eq('order_id', orderId)
      .eq('idempotency_key', idempotencyKey)
      .maybeSingle();

    if (existingIntent) {
      return Response.json({
        intent: existingIntent,
        reused: true,
      });
    }

    const { data: order, error: orderError } = await supabaseAdmin
      .from('orders')
      .select('id, customer_id, vendor_id, total_amount, gross_amount, payment_status, payment_state')
      .eq('id', orderId)
      .single();

    if (orderError || !order) {
      return Response.json({ error: 'Order not found' }, { status: 404 });
    }

    const amount = Number(order.gross_amount ?? order.total_amount ?? 0);
    if (amount <= 0) {
      return Response.json({ error: 'Order amount is invalid for payment intent' }, { status: 400 });
    }

    const receipt = `ord_${order.id.slice(0, 8)}_${Date.now()}`;
    const providerOrder = await createProviderOrder({
      provider,
      amountInPaise: Math.round(amount * 100),
      receipt,
      notes: {
        order_id: order.id,
      },
    });

    const intent = await createPaymentIntentRecord({
      orderId: order.id,
      customerId: order.customer_id,
      vendorId: order.vendor_id,
      provider,
      providerOrderId: providerOrder.providerOrderId,
      amount,
      checkoutUrl: providerOrder.checkoutUrl || null,
      idempotencyKey,
      metadata: {
        provider_raw: providerOrder.rawResponse || null,
      },
    });

    return Response.json({
      intent,
      checkout_url: intent.checkout_url || providerOrder.checkoutUrl || null,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Failed to create payment intent';
    console.error('[POST /api/payments/create-intent] error', error);
    return Response.json({ error: message }, { status: 500 });
  }
}
