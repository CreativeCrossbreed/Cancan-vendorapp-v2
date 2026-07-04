import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { detectProviderFromHeaders, verifyWebhookSignature } from '@/lib/payment-gateway';
import { sendWhatsAppMessage } from '@/lib/whatsapp';
import {
  appendVendorWalletEntry,
  createPaymentRecord,
  markPaymentIntentStatus,
  updateOrderFinancialState,
} from '@/lib/finance-ledger';

type WebhookExtract = {
  providerOrderId: string | null;
  providerPaymentId: string | null;
  amount: number;
  status: 'paid' | 'failed' | 'pending';
  raw: unknown;
};

function parseWebhookPayload(provider: 'razorpay' | 'cashfree', payload: Record<string, unknown>): WebhookExtract {
  if (provider === 'razorpay') {
    const payloadContainer = (payload['payload'] as Record<string, unknown> | undefined) || {};
    const paymentPayload = (payloadContainer['payment'] as Record<string, unknown> | undefined) || {};
    const orderPayload = (payloadContainer['order'] as Record<string, unknown> | undefined) || {};
    const entity =
      (paymentPayload['entity'] as Record<string, unknown> | undefined) ||
      (orderPayload['entity'] as Record<string, unknown> | undefined) ||
      {};
    const status = entity['status'] === 'captured' || payload['event'] === 'payment.captured' ? 'paid' : 'failed';
    return {
      providerOrderId: String(entity['order_id'] || '') || null,
      providerPaymentId: String(entity['id'] || '') || null,
      amount: Number(entity['amount'] || 0) / 100,
      status,
      raw: payload,
    };
  }

  const data = (payload['data'] as Record<string, unknown> | undefined) || payload;
  const orderData = (data['order'] as Record<string, unknown> | undefined) || data;
  const paymentData = (data['payment'] as Record<string, unknown> | undefined) || data;

  // Support BOTH Cashfree APIs:
  //  • Payment Links (what we use): data.cf_link_id + data.link_status
  //  • Orders API: order.order_id + order.order_status
  const linkId = data['cf_link_id'] || data['link_id'];
  const linkStatus = String(data['link_status'] || '').toUpperCase();
  const cfStatus = String(
    orderData['order_status'] || paymentData['payment_status'] || linkStatus || '',
  ).toUpperCase();
  const status = cfStatus === 'PAID' || cfStatus === 'SUCCESS' ? 'paid' : cfStatus === 'FAILED' ? 'failed' : 'pending';

  return {
    providerOrderId:
      String(linkId || orderData['order_id'] || orderData['cf_order_id'] || '') || null,
    providerPaymentId: String(paymentData['cf_payment_id'] || paymentData['payment_id'] || '') || null,
    amount: Number(
      data['link_amount_paid'] || paymentData['payment_amount'] || orderData['order_amount'] || 0,
    ),
    status,
    raw: payload,
  };
}

export async function POST(req: NextRequest) {
  const rawBody = await req.text();
  const provider = detectProviderFromHeaders(req.headers);

  if (!verifyWebhookSignature(provider, rawBody, req.headers)) {
    return Response.json({ error: 'Invalid webhook signature' }, { status: 401 });
  }

  try {
    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    const parsed = parseWebhookPayload(provider, payload);

    if (!parsed.providerOrderId) {
      return Response.json({ error: 'provider order id missing' }, { status: 400 });
    }

    const { data: intent } = await supabaseAdmin
      .from('payment_intents')
      .select('*')
      .eq('provider', provider)
      .eq('provider_order_id', parsed.providerOrderId)
      .maybeSingle();

    if (!intent) {
      return Response.json({
        status: 'ignored',
        reason: 'intent_not_found',
      });
    }

    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('id, vendor_id, customer_id, gross_amount, total_amount, platform_commission_amount, vendor_net_amount')
      .eq('id', intent.order_id)
      .single();

    if (!order) {
      await markPaymentIntentStatus(intent.id, 'failed', {
        webhook_error: 'order_not_found',
        webhook_payload: parsed.raw,
      });
      return Response.json({ error: 'Order missing for intent' }, { status: 404 });
    }

    if (parsed.status === 'paid') {
      const amount = Number(parsed.amount || order.gross_amount || order.total_amount || intent.amount || 0);
      const commission = Number(order.platform_commission_amount || 0);
      const vendorPayable = Number(order.vendor_net_amount || amount - commission);
      const gatewayFee = Number((amount * 0.02).toFixed(2));
      const gatewayTax = Number((gatewayFee * 0.18).toFixed(2));

      const payment = await createPaymentRecord({
        orderId: order.id,
        paymentIntentId: intent.id,
        vendorId: order.vendor_id,
        customerId: order.customer_id,
        provider,
        providerPaymentId: parsed.providerPaymentId,
        collectionMode: 'online',
        amount,
        paymentMethod: provider === 'razorpay' ? 'online_razorpay' : 'online_cashfree',
        gatewayFee,
        gatewayTax,
        platformCommission: commission,
        vendorPayable,
        status: 'completed',
        idempotencyKey: `${provider}:${parsed.providerPaymentId || parsed.providerOrderId}`,
        metadata: {
          provider_order_id: parsed.providerOrderId,
          webhook: parsed.raw,
        },
      });

      await markPaymentIntentStatus(intent.id, 'paid', {
        provider_payment_id: parsed.providerPaymentId,
      });

      await updateOrderFinancialState(order.id, {
        payment_status: 'paid',
        payment_state: 'collected_online',
        payment_method: provider,
        payment_reference: parsed.providerPaymentId || parsed.providerOrderId,
        amount_paid: amount,
        remaining_amount: 0,
        payment_marked_at: new Date().toISOString(),
      });

      if (order.vendor_id) {
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
            sourceType: 'online_payment',
            amount: vendorPayable,
            status: 'posted',
            notes: `Online payment settlement credit (${provider})`,
          });
        }
      }

      // Tell the customer on WhatsApp that their payment landed.
      try {
        const { data: cust } = await supabaseAdmin
          .from('customers')
          .select('phone, name')
          .eq('id', order.customer_id)
          .maybeSingle();
        const { data: ord } = await supabaseAdmin
          .from('orders')
          .select('order_number')
          .eq('id', order.id)
          .maybeSingle();
        if ((cust as any)?.phone) {
          const nm = (cust as any).name ? `, ${(cust as any).name}` : '';
          const ref = (ord as any)?.order_number ? ` (${(ord as any).order_number})` : '';
          await sendWhatsAppMessage(
            (cust as any).phone,
            `✅ *Payment received — thank you${nm}!* 💧\n\n` +
              `We've received your payment of *₹${amount.toFixed(0)}*${ref}.\n` +
              `Your order is now *fully paid and confirmed*. 🎉\n\n` +
              `We'll message you when it's out for delivery. 🚚`,
          );
        }
      } catch (notifyErr) {
        console.error('[payments/webhook] customer payment-confirmation message failed', notifyErr);
      }

      return Response.json({ status: 'ok', payment_id: payment.id });
    }

    if (parsed.status === 'failed') {
      await markPaymentIntentStatus(intent.id, 'failed', {
        provider_payment_id: parsed.providerPaymentId,
        webhook: parsed.raw,
      });
      await updateOrderFinancialState(order.id, {
        payment_status: 'unpaid',
        payment_state: 'failed',
      });
      return Response.json({ status: 'ok', result: 'failed_marked' });
    }

    await markPaymentIntentStatus(intent.id, 'requires_action', {
      provider_payment_id: parsed.providerPaymentId,
      webhook: parsed.raw,
    });
    return Response.json({ status: 'ok', result: 'pending' });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Webhook processing failed';
    console.error('[POST /api/payments/webhook] error', error);
    return Response.json({ error: message }, { status: 500 });
  }
}
