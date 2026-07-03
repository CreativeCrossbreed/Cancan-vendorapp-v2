import { NextRequest } from 'next/server';
import crypto from 'node:crypto';
import { supabaseAdmin } from '@/lib/supabase';
import {
  sendWhatsAppMessage,
  sendInteractiveList,
  sendReplyButtons,
  sendLocationRequestMessage,
} from '@/lib/whatsapp';
import { createProviderOrder } from '@/lib/payment-gateway';
import { createPaymentIntentRecord } from '@/lib/finance-ledger';
import { notifyVendorNewOrder } from '@/lib/push-notifications';

const WHATSAPP_WEBHOOK_SECRET = process.env.WHATSAPP_WEBHOOK_SECRET;
const META_APP_SECRET = process.env.META_APP_SECRET || process.env.WHATSAPP_APP_SECRET;
const DEFAULT_PER_BOTTLE_COMMISSION = Number.parseFloat(
  process.env.DEFAULT_PER_BOTTLE_COMMISSION || '1',
);
const DEFAULT_BOTTLE_PRICE = Number.parseFloat(process.env.DEFAULT_BOTTLE_PRICE || '30');
const ALLOW_STOCK_BASED_VENDOR_FALLBACK = process.env.ALLOW_STOCK_BASED_VENDOR_FALLBACK !== 'false';
const ORDER_META_PREFIX = '__ORDER_META__:';

// ─────────────────────────────────────────────────────────────
// SESSION STATES
// ─────────────────────────────────────────────────────────────
// ONBOARDING:
//   awaiting_name → awaiting_location → awaiting_address → done
//
// ORDERING:
//   idle (triggers on "hi") → awaiting_can_count → awaiting_custom_qty
//   → awaiting_date → awaiting_time_slot → awaiting_confirmation → done
//
// UPDATE ADDRESS:
//   update_address_location → update_address_confirm
// ─────────────────────────────────────────────────────────────

// ── GET: Meta verification handshake ──
export async function GET(req: NextRequest) {
  const searchParams = req.nextUrl.searchParams;
  const mode = searchParams.get('hub.mode');
  const token = searchParams.get('hub.verify_token');
  const challenge = searchParams.get('hub.challenge');

  if (mode === 'subscribe' && token === WHATSAPP_WEBHOOK_SECRET) {
    return new Response(challenge, { status: 200 });
  }
  return new Response('Forbidden', { status: 403 });
}

// ── POST: Incoming WhatsApp messages ──
export async function POST(req: NextRequest) {
  try {
    const rawBody = await req.text();
    const signature = req.headers.get('x-hub-signature-256');

    if (process.env.NODE_ENV === 'production' && !META_APP_SECRET) {
      // Signature verification is skipped until META_APP_SECRET is configured.
      // Log loudly but keep serving customers — a hard 500 here silently kills
      // the entire WhatsApp bot, which is worse than unverified webhooks.
      console.error('META_APP_SECRET is missing in production — webhook signatures are NOT being verified. Set it in Vercel env ASAP.');
    }

    if (META_APP_SECRET) {
      if (!signature) {
        console.warn('Webhook signature missing');
        return new Response('Unauthorized', { status: 401 });
      }
      const hmac = crypto.createHmac('sha256', META_APP_SECRET);
      const expectedSignature = `sha256=${hmac.update(rawBody).digest('hex')}`;
      const signatureBuffer = Buffer.from(signature);
      const expectedBuffer = Buffer.from(expectedSignature);
      const isValidSignature =
        signatureBuffer.length === expectedBuffer.length &&
        crypto.timingSafeEqual(signatureBuffer, expectedBuffer);
      if (!isValidSignature) {
        console.warn('Webhook signature mismatch');
        return new Response('Unauthorized', { status: 401 });
      }
    }

    const payload = JSON.parse(rawBody);

    if (payload.object === 'whatsapp_business_account') {
      const entry = payload.entry?.[0];
      const changes = entry?.changes?.[0];
      const value = changes?.value;

      if (value?.messages && value.messages.length > 0) {
        for (const message of value.messages) {
          await processMessage(message, value.contacts?.[0]?.wa_id);
        }
      }
    }

    return new Response('EVENT_RECEIVED', { status: 200 });
  } catch (error) {
    console.error('Webhook error:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
}

// ─────────────────────────────────────────────────────────────
// TOP-LEVEL MESSAGE ROUTER
// ─────────────────────────────────────────────────────────────

async function processMessage(message: any, customerPhone: string) {
  if (!customerPhone) return;

  // DEDUPLICATION — rely on the DB unique constraint (idx_whatsapp_messages_dedup
  // on message_id) as the source of truth, not a separate SELECT-then-INSERT,
  // which is a TOCTOU race under Meta's near-simultaneous webhook retries.
  const messageId = message.id;
  if (messageId) {
    const { error: insertError } = await supabaseAdmin.from('whatsapp_messages').insert([{
      message_id: messageId,
      customer_phone: customerPhone,
      message_type: message.type,
      message_content: message.text?.body || JSON.stringify(message),
      direction: 'inbound',
      status: 'received',
    }]);

    if (insertError) {
      // Unique violation (Postgres code 23505) means this message_id was
      // already processed by another concurrent/retried delivery — stop here.
      if ((insertError as any).code === '23505') return;
      console.error('Failed to log inbound WhatsApp message:', insertError);
    }
  }

  // RATE LIMIT
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count: recentCount } = await supabaseAdmin
    .from('whatsapp_messages')
    .select('*', { count: 'exact', head: true })
    .eq('customer_phone', customerPhone)
    .eq('direction', 'inbound')
    .gte('created_at', oneHourAgo);
  if ((recentCount ?? 0) > 100) return;

  // Check for vendor ref code in the message
  let vendorId: string | null = null;
  if (message.type === 'text') {
    const refMatch = message.text.body.trim().match(/^ref-([a-f0-9-]+)$/i);
    if (refMatch) vendorId = refMatch[1];
  }

  // Look up customer
  const { data: customer } = await supabaseAdmin
    .from('customers')
    .select('id, name, address, latitude, longitude, vendor_id')
    .eq('phone', customerPhone)
    .single();

  // ── NEW CUSTOMER: hand off to onboarding ──
  if (!customer) {
    await handleOnboarding(message, customerPhone, vendorId);
    return;
  }

  // ── EXISTING CUSTOMER: scanning a new vendor's ref code reassigns
  // ownership (Model A — one owning vendor at a time via customers.vendor_id) ──
  if (vendorId && customer.vendor_id !== vendorId) {
    await supabaseAdmin.from('customers').update({ vendor_id: vendorId }).eq('id', customer.id);
    await supabaseAdmin.from('customer_vendors').upsert(
      { customer_id: customer.id, vendor_id: vendorId },
      { onConflict: 'customer_id,vendor_id' }
    );
    customer.vendor_id = vendorId;
    await sendWhatsAppMessage(
      customerPhone,
      `👋 Welcome back, ${customer.name}! You've been linked to a new vendor.`
    );
    await showMainMenu(customerPhone, customer.name);
    return;
  }

  // ── EXISTING CUSTOMER: check if they're mid-flow ──
  const { data: session } = await supabaseAdmin
    .from('whatsapp_sessions')
    .select('*')
    .eq('phone_number', customerPhone)
    .single();

  if (session) {
    await handleActiveSession(message, customerPhone, customer, session);
    return;
  }

  // ── EXISTING CUSTOMER: idle, handle top-level intent ──
  await handleIdleCustomer(message, customerPhone, customer);
}

// ─────────────────────────────────────────────────────────────
// IDLE CUSTOMER (no active session)
// ─────────────────────────────────────────────────────────────

async function handleIdleCustomer(message: any, phone: string, customer: any) {
  const msgType = message.type;

  if (msgType === 'text') {
    const text = message.text.body.toLowerCase().trim();
    if (['hi', 'hello', 'hey', 'order', 'water'].some(w => text.includes(w))) {
      await showMainMenu(phone, customer.name);
      return;
    }
  }

  // Handle main menu button replies
  if (msgType === 'interactive' && message.interactive.type === 'button_reply') {
    const id = message.interactive.button_reply.id;

    if (id === 'menu_order_water') {
      await startOrderFlow(phone, customer);
      return;
    }
    if (id === 'menu_my_deliveries') {
      await showMyDeliveries(phone, customer.id);
      return;
    }
    if (id === 'menu_update_address') {
      await startUpdateAddress(phone);
      return;
    }
    if (id === 'menu_help') {
      await showHelp(phone);
      return;
    }
    if (id === 'menu_repeat_last') {
      await repeatLastOrder(phone, customer);
      return;
    }

    // Help sub-menu
    if (id === 'help_delivery_issue' || id === 'help_wrong_order') {
      await sendWhatsAppMessage(
        phone,
        `We're sorry to hear that! Please describe your issue and our team will get back to you shortly.`
      );
      return;
    }
    if (id === 'help_contact_vendor') {
      const { data: vendorLink } = await getCustomerVendor(customer.id);
      const v = (vendorLink as any)?.vendors;
      const vendorContact = v?.phone ? `\n📞 ${v.phone}` : '';
      await sendWhatsAppMessage(phone, `Here are your vendor's contact details:${vendorContact || '\nContact details unavailable. Please try again later.'}`);
      return;
    }
    if (id === 'help_cancan_support') {
      await sendWhatsAppMessage(phone, `For Can Can support, please email us at support@cancan.in or call +91-XXXXXXXXXX.`);
      return;
    }

    // Delivery failed edge case
    if (id === 'failed_okay') {
      await sendWhatsAppMessage(phone, `Thank you for your patience. Your order will be delivered tomorrow.`);
      return;
    }
    if (id === 'failed_contact_vendor') {
      const { data: vendorLink } = await getCustomerVendor(customer.id);
      const v = (vendorLink as any)?.vendors;
      const vendorContact = v?.phone ? `\n📞 ${v.phone}` : '';
      await sendWhatsAppMessage(phone, `Vendor contact:${vendorContact || '\nUnavailable right now.'}`);
      return;
    }

    // My Deliveries: customer taps a delivery to see details
    if (id.startsWith('delivery_')) {
      const orderId = id.replace('delivery_', '');
    await showDeliveryDetail(phone, orderId, customer.id);
      return;
    }
  }

  // Fallback
  await showMainMenu(phone, customer.name);
}

// ─────────────────────────────────────────────────────────────
// ACTIVE SESSION HANDLER (ordering / updating address)
// ─────────────────────────────────────────────────────────────

async function handleActiveSession(
  message: any,
  phone: string,
  customer: any,
  session: any
) {
  const state: string = session.state;

  // ── SELF-HEALING GUARDS ───────────────────────────────────
  // These run before any state handling so a customer can NEVER get
  // permanently stuck in a mid-flow session (the #1 support problem).

  // 1) Reset keywords — typing any of these from ANY state escapes to the
  //    main menu. This is the universal "get me out" that a stuck customer
  //    reaches for. Onboarding (awaiting_name/location/address) is exempt so
  //    a new user typing "hi" as their name isn't trapped — actually we still
  //    let them reset; onboarding re-triggers cleanly on next message.
  if (message.type === 'text') {
    const t = (message.text?.body || '').trim().toLowerCase();
    const RESET_WORDS = ['hi', 'hello', 'hey', 'menu', 'main', 'start', 'restart', 'cancel', 'stop', 'reset', 'back', 'exit', 'home'];
    if (RESET_WORDS.includes(t)) {
      await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
      await handleIdleCustomer(message, phone, customer);
      return;
    }
  }

  // 2) Stale session auto-expiry — an abandoned session older than 30 min is
  //    treated as gone. Sessions persist in the DB across deploys and would
  //    otherwise resurrect an old flow the customer has long forgotten.
  const lastTouched = session.updated_at ? new Date(session.updated_at).getTime() : 0;
  if (lastTouched > 0 && Date.now() - lastTouched > 30 * 60 * 1000) {
    await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
    await handleIdleCustomer(message, phone, customer);
    return;
  }

  // 3) Main-menu buttons always win over a stale mid-flow session — a customer
  //    tapping "New Order" from an old menu expects a fresh start, not to be
  //    dropped into whatever step their abandoned session was stuck on.
  //    (Exception: awaiting_payment_choice keeps its own fallback so a just-placed
  //    order's payment question isn't silently discarded.)
  if (
    message.type === 'interactive' &&
    message.interactive.type === 'button_reply' &&
    String(message.interactive.button_reply.id).startsWith('menu_') &&
    state !== 'awaiting_payment_choice'
  ) {
    await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
    await handleIdleCustomer(message, phone, customer);
    return;
  }

  // ── ORDER FLOW ────────────────────────────────────────────

  if (state === 'awaiting_brand') {
    if (message.type === 'interactive' && message.interactive.type === 'list_reply') {
      const id = message.interactive.list_reply.id as string;
      if (id.startsWith('brand_')) {
        const productId = id.replace('brand_', '');
        const vendorId = session.vendor_id as string | null;
        if (!vendorId) {
          await sendWhatsAppMessage(
            phone,
            'Sorry, we could not resolve your vendor right now. Please type "hi" and try again.',
          );
          return;
        }

        const { data: selectedBrand } = await supabaseAdmin
          .from('vendor_products')
          .select('product_id, selling_price, current_stock, products(name)')
          .eq('vendor_id', vendorId)
          .eq('product_id', productId)
          .maybeSingle();

        const brandName = ((selectedBrand as any)?.products?.name as string | undefined) || 'Water Can';
        const brandPrice = Number(selectedBrand?.selling_price || DEFAULT_BOTTLE_PRICE);

        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({
            state: 'awaiting_can_count',
            pending_address: `${ORDER_META_PREFIX}${JSON.stringify({
              order_meta: {
                product_id: productId,
                product_name: brandName,
                unit_price: brandPrice,
              },
            })}`,
          })
          .eq('phone_number', phone);

        await sendCanCountButtons(phone, brandName);
        return;
      }
    }
    await showBrandCatalog(phone, customer, session.vendor_id as string | null);
    return;
  }

  if (state === 'awaiting_can_count') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;

      if (id === 'qty_custom') {
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'awaiting_custom_qty' })
          .eq('phone_number', phone);
        await sendWhatsAppMessage(phone, 'How many cans would you like? Please type a number (e.g. 5)');
        return;
      }

      const qty = Number.parseInt(id.replace('qty_', ''), 10);
      if (!Number.isNaN(qty)) {
        await setSessionQtyAndAskDate(phone, session, qty);
        return;
      }
    }

    // Support custom quantities via plain text reply (e.g. "5")
    if (message.type === 'text') {
      const qtyText = String(message.text?.body || '').trim();
      const qty = Number.parseInt(qtyText, 10);
      if (!Number.isNaN(qty) && qty > 0 && qty <= 1000) {
        await setSessionQtyAndAskDate(phone, session, qty);
        return;
      }
      await sendWhatsAppMessage(phone, `Please enter a valid can quantity (e.g. 5).`);
      return;
    }

    const sessionMeta = getOrderMeta(session);
    await sendCanCountButtons(phone, sessionMeta?.product_name || null);
    return;
  }

  if (state === 'awaiting_custom_qty') {
    if (message.type === 'text') {
      const qty = Number.parseInt(message.text.body.trim(), 10);
      if (!Number.isNaN(qty) && qty > 0 && qty <= 50) {
        await setSessionQtyAndAskDate(phone, session, qty);
        return;
      }
    }
    await sendWhatsAppMessage(phone, `Please enter a valid number of cans (e.g. 5).`);
    return;
  }

  if (state === 'awaiting_date') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;
      if (id.startsWith('date_')) {
        const date = id.replace('date_', '');
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'awaiting_time_slot', delivery_date: date })
          .eq('phone_number', phone);
        await sendTimeSlotButtons(phone);
        return;
      }
    }
    await sendDateButtons(phone);
    return;
  }

  if (state === 'awaiting_time_slot') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;
      if (id.startsWith('slot_')) {
        const slot = id.replace('slot_', '');
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'awaiting_confirmation', time_slot: slot })
          .eq('phone_number', phone);

        // Refresh session data to show confirmation
        const { data: updatedSession } = await supabaseAdmin
          .from('whatsapp_sessions')
          .select('*')
          .eq('phone_number', phone)
          .single();

        await sendOrderConfirmation(phone, customer, updatedSession);
        return;
      }
    }
    await sendTimeSlotButtons(phone);
    return;
  }

  if (state === 'awaiting_confirmation') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;

      if (id === 'confirm_order') {
        await placeOrder(phone, customer, session);
        return;
      }
      if (id === 'change_details') {
        // Restart from date selection
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'awaiting_date' })
          .eq('phone_number', phone);
        await sendDateButtons(phone);
        return;
      }
      if (id === 'cancel_order') {
        await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
        await sendWhatsAppMessage(phone, `Your order has been cancelled.`);
        await showMainMenu(phone, customer.name);
        return;
      }
    }
    const { data: fresh } = await supabaseAdmin
      .from('whatsapp_sessions')
      .select('*')
      .eq('phone_number', phone)
      .single();
    await sendOrderConfirmation(phone, customer, fresh);
    return;
  }

  // ── PAYMENT CHOICE FLOW ───────────────────────────────────

  if (state === 'awaiting_payment_choice') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id as string;

      if (id.startsWith('pay_cod_')) {
        const orderId = id.replace('pay_cod_', '');
        const { data: codOrder } = await supabaseAdmin
          .from('orders')
          .update({ payment_method: 'cash', payment_state: 'pending_cod' })
          .eq('id', orderId)
          .select('total_amount, order_number')
          .maybeSingle();
        await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
        const codAmt = Number((codOrder as any)?.total_amount || 0);
        await sendWhatsAppMessage(
          phone,
          `✅ *Cash on Delivery selected!*\n\n` +
            `💵 Please keep *₹${codAmt.toFixed(0)}* ready when your water arrives.\n` +
            `🚚 Your delivery partner will collect the payment at your door.\n\n` +
            `💡 _Tip: exact change makes the handover quicker!_\n\n` +
            `Thank you for choosing Can Can 💙 We'll message you when your order is out for delivery.`
        );
        await showMainMenu(phone, customer.name);
        return;
      }

      if (id.startsWith('pay_online_')) {
        const orderId = id.replace('pay_online_', '');
        try {
          const { data: ord } = await supabaseAdmin.from('orders').select('total_amount').eq('id', orderId).single();
          const amount = Number((ord as any)?.total_amount || 0);
          const provider = (process.env.PAYMENT_PROVIDER_DEFAULT || 'cashfree') as 'razorpay' | 'cashfree';
          const receipt = `wa_${orderId.slice(0, 8)}_${Date.now()}`;
          const providerOrder = await createProviderOrder({
            provider,
            amountInPaise: Math.round(amount * 100),
            receipt,
            customerId: customer.id,
            customerPhone: phone.replace(/\D/g, '').slice(-10),
            notes: { order_id: orderId, source: 'whatsapp' },
          });
          const paymentIntent = await createPaymentIntentRecord({
            orderId,
            customerId: customer.id,
            vendorId: session.vendor_id || null,
            provider,
            providerOrderId: providerOrder.providerOrderId,
            amount,
            checkoutUrl: providerOrder.checkoutUrl || null,
            idempotencyKey: `wa-intent:${orderId}`,
            metadata: { source: 'whatsapp' },
          });
          const checkoutUrl = paymentIntent.checkout_url || providerOrder.checkoutUrl;
          await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
          if (checkoutUrl) {
            await sendWhatsAppMessage(
              phone,
              `💳 *Here's your secure payment link for ₹${amount.toFixed(0)}:*\n\n` +
                `${checkoutUrl}\n\n` +
                `👆 Tap the link above to pay via UPI, card, or netbanking.\n\n` +
                `🔒 Payments are processed securely — we never see your card or UPI details.\n` +
                `✅ You'll get an instant confirmation here once the payment goes through.\n\n` +
                `_Changed your mind? No problem — you can always pay cash when your water arrives._`
            );
          } else {
            await sendWhatsAppMessage(
              phone,
              `😕 Sorry, we couldn't create your payment link right now.\n\n` +
                `💵 No worries — you can simply pay *₹${amount.toFixed(0)}* in cash when your water is delivered.\n\n` +
                `Your order is confirmed and on track! 👍`
            );
          }
        } catch (e) {
          console.error('Payment link error:', e);
          await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
          await sendWhatsAppMessage(
            phone,
            `😕 Sorry, we couldn't create your payment link right now.\n\n` +
              `💵 No worries — you can simply pay in cash when your water is delivered.\n\n` +
              `Your order is confirmed and on track! 👍`
          );
        }
        await showMainMenu(phone, customer.name);
        return;
      }
    }
    // Fallback: re-show the choice
    const { data: pendingOrder } = await supabaseAdmin
      .from('orders')
      .select('id, total_amount')
      .eq('customer_id', customer.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (pendingOrder) {
      const amt = Number((pendingOrder as any).total_amount || 0);
      await sendReplyButtons(
        phone,
        `💳 *How would you like to pay ₹${amt.toFixed(0)}?*\n\n` +
          `1️⃣ *Pay Online* — quick & secure UPI / card / netbanking. We'll send you a payment link right here.\n\n` +
          `2️⃣ *Cash on Delivery* — pay in cash when your water arrives.\n\n` +
          `Choose whichever is easier for you 👇`,
        [
          { id: `pay_online_${(pendingOrder as any).id}`, title: '💳 Pay Online' },
          { id: `pay_cod_${(pendingOrder as any).id}`, title: '💵 Cash on Delivery' },
        ]
      );
    } else {
      await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
      await showMainMenu(phone, customer.name);
    }
    return;
  }

  // ── REPEAT LAST ORDER FLOW ─────────────────────────────────

  if (state === 'repeat_awaiting_choice') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;

      if (id === 'repeat_confirm') {
        // Place repeat order with today's date and stored time_slot.
        // placeOrder's idempotency lock only proceeds from awaiting_confirmation.
        const today = new Date().toISOString().split('T')[0];
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ delivery_date: today, state: 'awaiting_confirmation' })
          .eq('phone_number', phone);
        session.delivery_date = today;
        session.state = 'awaiting_confirmation';
        await placeOrder(phone, customer, session);
        return;
      }

      if (id === 'repeat_change_slot') {
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'repeat_awaiting_time_slot' })
          .eq('phone_number', phone);
        await sendTimeSlotButtons(phone);
        return;
      }
    }
    // Fallback: re-show the repeat options
    await sendReplyButtons(
      phone,
      `Please choose an option:`,
      [
        { id: 'repeat_confirm', title: '✅ Confirm' },
        { id: 'repeat_change_slot', title: '🕐 Change Time Slot' },
      ]
    );
    return;
  }

  if (state === 'repeat_awaiting_time_slot') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;
      if (id.startsWith('slot_')) {
        const slot = id.replace('slot_', '');
        const today = new Date().toISOString().split('T')[0];
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ time_slot: slot, delivery_date: today, state: 'awaiting_confirmation' })
          .eq('phone_number', phone);
        session.time_slot = slot;
        session.delivery_date = today;
        session.state = 'awaiting_confirmation';
        await placeOrder(phone, customer, session);
        return;
      }
    }
    await sendTimeSlotButtons(phone);
    return;
  }

  // ── UPDATE ADDRESS FLOW ───────────────────────────────────

  if (state === 'update_address_location') {
    if (message.type !== 'location') {
      await sendLocationRequestMessage(phone, `Please use the 'Send Location' button to drop your new map pin.`);
      return;
    }
    const { latitude, longitude } = message.location;

    // Reverse geocode (replace with your actual geocoding call)
    const addressText = await reverseGeocode(latitude, longitude);

    await supabaseAdmin
      .from('whatsapp_sessions')
      .update({
        state: 'update_address_confirm',
        latitude,
        longitude,
        pending_address: addressText,
      })
      .eq('phone_number', phone);

    await sendReplyButtons(
      phone,
      `📍 We found this address:\n\n*${addressText}*\n\nIs this correct?`,
      [
        { id: 'addr_confirm', title: '✅ Yes, confirm' },
        { id: 'addr_edit', title: '✏️ Edit address' },
      ]
    );
    return;
  }

  if (state === 'update_address_confirm') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;

      if (id === 'addr_confirm') {
        await supabaseAdmin
          .from('customers')
          .update({
            address: session.pending_address,
            latitude: session.latitude,
            longitude: session.longitude,
          })
          .eq('phone', phone);
        await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
        await sendWhatsAppMessage(phone, `✅ Great! Your address has been updated.`);
        await showMainMenu(phone, customer.name);
        return;
      }

      if (id === 'addr_edit') {
        // Ask them to type their address manually
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'update_address_manual' })
          .eq('phone_number', phone);
        await sendWhatsAppMessage(
          phone,
          `Please type your full address (flat/house number, building name, street, landmark):`
        );
        return;
      }
    }
    return;
  }

  if (state === 'update_address_manual') {
    if (message.type === 'text') {
      const address = message.text.body.trim();
      await supabaseAdmin
        .from('customers')
        .update({
          address,
          latitude: session.latitude,
          longitude: session.longitude,
        })
        .eq('phone', phone);
      await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
      await sendWhatsAppMessage(phone, `✅ Your address has been updated to:\n\n_${address}_`);
      await showMainMenu(phone, customer.name);
      return;
    }
    await sendWhatsAppMessage(phone, `Please type your address.`);
    return;
  }

  // Unrecognized session state (e.g. stale state from a removed feature, or
  // manual DB edit) — never silently drop the customer's message. Reset to
  // a known-good state so the conversation can recover instead of stalling.
  console.error('Unrecognized whatsapp_sessions.state — resetting session', { sessionId: session.id, state });
  await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
  await sendWhatsAppMessage(phone, `Sorry, something went wrong. Let's start over — type "hi" to begin.`);
}

// ─────────────────────────────────────────────────────────────
// ONBOARDING (new customers)
// ─────────────────────────────────────────────────────────────

async function handleOnboarding(
  message: any,
  phone: string,
  vendorId: string | null = null
) {
  const { data: session } = await supabaseAdmin
    .from('whatsapp_sessions')
    .select('*')
    .eq('phone_number', phone)
    .single();

  if (!session) {
    await supabaseAdmin.from('whatsapp_sessions').insert({
      phone_number: phone,
      vendor_id: vendorId,
      state: 'awaiting_name',
    });
    await sendWhatsAppMessage(
      phone,
      `👋 Welcome to Can Can Water Delivery!\n\nLet's get you set up so you can order water instantly.\n\nWhat is your *Full Name*?`
    );
    return;
  }

  if (vendorId && !session.vendor_id) {
    await supabaseAdmin
      .from('whatsapp_sessions')
      .update({ vendor_id: vendorId })
      .eq('phone_number', phone);
    session.vendor_id = vendorId;
  }

  if (session.state === 'awaiting_name') {
    if (message.type !== 'text') {
      await sendWhatsAppMessage(phone, `Please type your full name to continue.`);
      return;
    }
    const name = message.text.body.trim();
    await supabaseAdmin
      .from('whatsapp_sessions')
      .update({ name, state: 'awaiting_location' })
      .eq('phone_number', phone);
    await sendLocationRequestMessage(
      phone,
      `Nice to meet you, ${name}! 📍 Please drop your location pin so we can find you for delivery.`
    );
    return;
  }

  if (session.state === 'awaiting_location') {
    if (message.type !== 'location') {
      await sendLocationRequestMessage(
        phone,
        `Please use the 'Send Location' button to drop your map pin.`
      );
      return;
    }
    const { latitude, longitude } = message.location;
    const addressText = await reverseGeocode(latitude, longitude);

    await supabaseAdmin
      .from('whatsapp_sessions')
      .update({
        latitude,
        longitude,
        pending_address: addressText,
        state: 'awaiting_address',
      })
      .eq('phone_number', phone);

    await sendReplyButtons(
      phone,
      `📍 We found this address:\n\n*${addressText}*\n\nIs this correct?`,
      [
        { id: 'onboard_addr_yes', title: '✅ Yes, looks right' },
        { id: 'onboard_addr_edit', title: '✏️ Edit address' },
      ]
    );
    return;
  }

  if (session.state === 'awaiting_address') {
    // Could be a button reply (yes/edit) or free-text edit
    let finalAddress = session.pending_address;

    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;
      if (id === 'onboard_addr_edit') {
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'awaiting_address_text' })
          .eq('phone_number', phone);
        await sendWhatsAppMessage(
          phone,
          `Please type your flat/house number and building name/landmark:`
        );
        return;
      }
      // id === 'onboard_addr_yes' → fall through to finalise
    } else if (message.type === 'text') {
      finalAddress = message.text.body.trim();
    } else {
      await sendWhatsAppMessage(phone, `Please confirm or type your address.`);
      return;
    }

    await finaliseOnboarding(phone, session, finalAddress);
    return;
  }

  if (session.state === 'awaiting_address_text') {
    if (message.type !== 'text') {
      await sendWhatsAppMessage(phone, `Please type your address.`);
      return;
    }
    const address = message.text.body.trim();
    await finaliseOnboarding(phone, session, address);
    return;
  }
}

async function finaliseOnboarding(phone: string, session: any, address: string) {
  // customers.vendor_id is the real ownership column RLS is scoped on
  // (UNIQUE(vendor_id, phone) — a phone can exist under multiple vendors as
  // separate rows). Must be set at insert time, not only in customer_vendors,
  // or this customer becomes invisible to the vendor's own app/dashboard.
  const { data: newCustomer, error } = await supabaseAdmin
    .from('customers')
    .insert({
      vendor_id: session.vendor_id || null,
      phone,
      name: session.name,
      address,
      latitude: session.latitude,
      longitude: session.longitude,
      is_verified: true,
      is_active: true,
    })
    .select('id')
    .single();

  if (error || !newCustomer) {
    console.error('Failed to create customer:', error);
    await sendWhatsAppMessage(
      phone,
      `Sorry, something went wrong saving your profile. Please try again.`
    );
    return;
  }

  if (session.vendor_id) {
    await supabaseAdmin.from('customer_vendors').insert({
      customer_id: newCustomer.id,
      vendor_id: session.vendor_id,
    });
  }

  await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);

  await sendWhatsAppMessage(
    phone,
    `✅ *Perfect! You're all set!*\n\nWelcome to Can Can, ${session.name}! 💧`
  );

  await showMainMenu(phone, session.name);
}

// ─────────────────────────────────────────────────────────────
// ORDER FLOW HELPERS
// ─────────────────────────────────────────────────────────────

async function startOrderFlow(phone: string, customer: any) {
  const resolvedVendorId = await resolveVendorForCustomerFlow(customer);
  if (!resolvedVendorId) {
    await sendWhatsAppMessage(
      phone,
      `Sorry, we could not find an active vendor within 2km of your location right now. Please try again later.`,
    );
    return;
  }

  await supabaseAdmin.from('whatsapp_sessions').upsert(
    {
      phone_number: phone,
      state: 'awaiting_brand',
      customer_id: customer.id,
      vendor_id: resolvedVendorId,
      pending_address: null,
    },
    { onConflict: 'phone_number' }
  );
  await showBrandCatalog(phone, customer, resolvedVendorId);
}

async function sendCanCountButtons(phone: string, brandName: string | null = null) {
  await sendReplyButtons(
    phone,
    brandName ? `💧 How many *${brandName}* cans would you like?` : `💧 How many cans would you like?`,
    [
      { id: 'qty_1', title: '1 Can' },
      { id: 'qty_2', title: '2 Cans' },
      { id: 'qty_3', title: '3 Cans' },
    ]
  );
  // Note: WhatsApp only allows 3 buttons. We send a follow-up for custom.
  await sendWhatsAppMessage(phone, `_For a different quantity, reply with the number (e.g. "5")_`);
}

async function resolveVendorForCustomerFlow(customer: any): Promise<string | null> {
  const { vendorId } = await resolveOwningVendor(customer);
  return vendorId;
}

async function showBrandCatalog(phone: string, customer: any, existingVendorId?: string | null) {
  const vendorId = existingVendorId || (await resolveVendorForCustomerFlow(customer));
  if (!vendorId) {
    await sendWhatsAppMessage(
      phone,
      `Sorry, we could not find an active vendor within 2km of your location right now.`,
    );
    return;
  }

  const { data: vendorProducts, error } = await supabaseAdmin
    .from('vendor_products')
    .select('product_id, selling_price, current_stock, products(name), is_active')
    .eq('vendor_id', vendorId)
    .eq('is_active', true)
    .gt('current_stock', 0)
    .order('updated_at', { ascending: false })
    .limit(10);

  if (error) {
    console.error('Failed to load brand catalog:', error);
    await sendWhatsAppMessage(phone, `Sorry, we could not load the catalog right now. Please try again.`);
    return;
  }

  if (!vendorProducts || vendorProducts.length === 0) {
    await sendWhatsAppMessage(
      phone,
      `No brands are currently in stock for your linked vendor. Please try again later.`,
    );
    return;
  }

  const rows = vendorProducts
    .map((vp: any) => {
      const productName = (vp.products?.name as string | undefined) || 'Water Can';
      const price = Number(vp.selling_price || DEFAULT_BOTTLE_PRICE);
      const stock = Number(vp.current_stock || 0);
      return {
        id: `brand_${vp.product_id}`,
        title: productName.substring(0, 24),
        description: `₹${price.toFixed(0)} • ${stock} in stock`.substring(0, 72),
      };
    })
    .slice(0, 10);

  await sendInteractiveList(phone, 'Select Brand', 'Choose a brand to continue your order:', 'View Brands', [
    { title: 'Available Brands', rows },
  ]);
}

async function setSessionQtyAndAskDate(phone: string, session: any, qty: number) {
  await supabaseAdmin
    .from('whatsapp_sessions')
    .update({ state: 'awaiting_date', can_count: qty })
    .eq('phone_number', phone);
  await sendDateButtons(phone);
}

async function sendDateButtons(phone: string) {
  const today = new Date();
  const dates = [0, 1, 2].map(offset => {
    const d = new Date(today);
    d.setDate(today.getDate() + offset);
    const label = offset === 0 ? 'Today' : offset === 1 ? 'Tomorrow' : d.toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short' });
    const value = d.toISOString().split('T')[0]; // YYYY-MM-DD
    return { id: `date_${value}`, title: label };
  });

  await sendReplyButtons(phone, `📅 Choose a delivery date:`, dates);
}

async function sendTimeSlotButtons(phone: string) {
  await sendReplyButtons(
    phone,
    `⏰ Choose a time slot:`,
    [
      { id: 'slot_morning', title: '🌅 Morning (8am–12pm)' },
      { id: 'slot_noon', title: '🌤 Noon (12pm–3pm)' },
      { id: 'slot_evening', title: '🌆 Evening (3pm–9pm)' },
    ]
  );
}

async function sendOrderConfirmation(phone: string, customer: any, session: any) {
  const slotLabels: Record<string, string> = {
    morning: 'Morning (8am–12pm)',
    noon: 'Noon (12pm–3pm)',
    evening: 'Evening (3pm–9pm)',
  };
  const slot = slotLabels[session.time_slot] || session.time_slot;
  const date = new Date(session.delivery_date).toLocaleDateString('en-IN', {
    weekday: 'long', day: 'numeric', month: 'long',
  });

  await sendReplyButtons(
    phone,
    `🧾 *Confirm your order:*\n\n💧 ${session.can_count} Water Can${session.can_count > 1 ? 's' : ''}\n📍 ${customer.address}\n📅 ${date}\n⏰ ${slot}`,
    [
      { id: 'confirm_order', title: '✅ Confirm Order' },
      { id: 'change_details', title: '✏️ Change Details' },
      { id: 'cancel_order', title: '❌ Cancel' },
    ]
  );
}

type ResolvedOrderFinancials = {
  vendorId: string | null;
  vendorResolutionSource: 'linked' | 'nearest_2km' | 'none';
  productId: string | null;
  productName: string | null;
  unitPrice: number;
  bottleSubtotal: number;
  commissionPerBottle: number;
  commissionAmount: number;
  grossAmount: number;
  vendorNetAmount: number;
  pricingVersion: string;
  policyId: string | null;
};

function toFiniteNumber(value: unknown): number | null {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function haversineDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

async function resolveNearestVendorFallback(customer: any, radiusKm: number): Promise<string | null> {
  const customerLat = toFiniteNumber(customer?.latitude);
  const customerLon = toFiniteNumber(customer?.longitude);
  if (customerLat === null || customerLon === null) return null;

  const { data: vendors, error: vendorError } = await supabaseAdmin
    .from('vendors')
    .select('id, latitude, longitude, is_active, is_on_vacation')
    .eq('is_active', true)
    .eq('is_on_vacation', false)
    .limit(500);

  if (vendorError || !vendors || vendors.length === 0) {
    console.warn('Nearest-vendor fallback failed while loading vendors:', vendorError?.message || 'No vendors');
    return null;
  }

  const vendorIds = vendors.map((vendor: any) => vendor.id).filter(Boolean);
  if (vendorIds.length === 0) return null;

  const { data: vendorProducts, error: stockError } = await supabaseAdmin
    .from('vendor_products')
    .select('vendor_id, current_stock, is_active')
    .in('vendor_id', vendorIds)
    .eq('is_active', true)
    .gt('current_stock', 0);

  if (stockError) {
    console.warn('Nearest-vendor fallback failed while loading stock:', stockError.message);
    return null;
  }

  const stockedVendorIds = new Set(
    (vendorProducts || []).map((row: any) => String(row.vendor_id)).filter(Boolean),
  );
  if (stockedVendorIds.size === 0) return null;

  let bestVendorId: string | null = null;
  let bestDistance = Number.POSITIVE_INFINITY;
  const stockByVendor = new Map<string, number>();

  for (const row of vendorProducts || []) {
    const vendorId = row?.vendor_id ? String(row.vendor_id) : null;
    if (!vendorId) continue;
    const current = stockByVendor.get(vendorId) || 0;
    stockByVendor.set(vendorId, current + Number(row.current_stock || 0));
  }

  for (const vendor of vendors) {
    const vendorId = vendor?.id ? String(vendor.id) : null;
    if (!vendorId || !stockedVendorIds.has(vendorId)) continue;

    const vendorLat = toFiniteNumber(vendor?.latitude);
    const vendorLon = toFiniteNumber(vendor?.longitude);
    if (vendorLat === null || vendorLon === null) continue;

    const distanceKm = haversineDistanceKm(customerLat, customerLon, vendorLat, vendorLon);
    if (distanceKm <= radiusKm && distanceKm < bestDistance) {
      bestDistance = distanceKm;
      bestVendorId = vendorId;
    }
  }

  if (!bestVendorId && ALLOW_STOCK_BASED_VENDOR_FALLBACK) {
    const fallbackVendorId = Array.from(stockedVendorIds).sort((a, b) => {
      const stockDiff = (stockByVendor.get(b) || 0) - (stockByVendor.get(a) || 0);
      if (stockDiff !== 0) return stockDiff;
      return a.localeCompare(b);
    })[0] || null;

    if (fallbackVendorId) {
      console.warn(
        'Nearest-vendor fallback used stock-based assignment because no geo-qualified vendor was found.',
      );
      return fallbackVendorId;
    }
  }

  return bestVendorId;
}

async function resolveNearestVendor(customer: any): Promise<string | null> {
  const radiusKm = 2;
  if (!customer?.latitude || !customer?.longitude) return null;

  const { data, error } = await supabaseAdmin.rpc('find_nearest_vendors', {
    p_latitude: Number(customer.latitude),
    p_longitude: Number(customer.longitude),
    p_radius_km: radiusKm,
    p_limit: 1,
  });

  if (error) {
    console.warn('Nearest-vendor RPC lookup failed, trying fallback resolver:', error.message);
    return resolveNearestVendorFallback(customer, radiusKm);
  }

  const nearest = Array.isArray(data) && data.length > 0 ? data[0] : null;
  const nearestVendorId = nearest?.vendor_id ? String(nearest.vendor_id) : null;
  return nearestVendorId;
}

function getOrderMeta(session: any): { product_id?: string; product_name?: string; unit_price?: number } | null {
  const raw = session?.pending_address;
  if (!raw || typeof raw !== 'string') return null;
  if (!raw.startsWith(ORDER_META_PREFIX)) return null;
  try {
    const parsed = JSON.parse(raw.slice(ORDER_META_PREFIX.length));
    return parsed?.order_meta || null;
  } catch {
    return null;
  }
}

async function linkCustomerVendor(customerId: string, vendorId: string) {
  await supabaseAdmin.from('customer_vendors').upsert(
    {
      customer_id: customerId,
      vendor_id: vendorId,
    },
    { onConflict: 'customer_id,vendor_id' },
  );
}

/**
 * Model A: a customer is owned by exactly one vendor at a time
 * (customers.vendor_id, RLS-enforced). But that owning vendor can go on
 * vacation or become inactive — when that happens the customer must be
 * reassigned to an available alternative rather than getting stuck unable
 * to order. Moves the customer (updates vendor_id in place) rather than
 * creating a second customer row, since vendor_id is a single-owner column.
 */
async function resolveOwningVendor(customer: any): Promise<{ vendorId: string | null; reassigned: boolean }> {
  const currentVendorId = customer?.vendor_id ? String(customer.vendor_id) : null;

  if (currentVendorId) {
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id, is_active, is_on_vacation')
      .eq('id', currentVendorId)
      .maybeSingle();

    if (vendor && vendor.is_active && !vendor.is_on_vacation) {
      return { vendorId: currentVendorId, reassigned: false };
    }
    console.warn(`Customer ${customer.id}'s vendor ${currentVendorId} is unavailable (active=${vendor?.is_active}, vacation=${vendor?.is_on_vacation}) — reassigning.`);
  }

  const nearestVendorId = await resolveNearestVendor(customer);
  if (!nearestVendorId) {
    return { vendorId: null, reassigned: false };
  }

  await supabaseAdmin.from('customers').update({ vendor_id: nearestVendorId }).eq('id', customer.id);
  await linkCustomerVendor(customer.id, nearestVendorId);
  customer.vendor_id = nearestVendorId;
  return { vendorId: nearestVendorId, reassigned: currentVendorId !== null };
}

async function resolveOrderFinancials(
  customer: any,
  canCount: number,
  selectedProductId?: string | null,
): Promise<ResolvedOrderFinancials> {
  const { vendorId: resolvedVendorId, reassigned } = await resolveOwningVendor(customer);
  let vendorId = resolvedVendorId;
  let vendorResolutionSource: ResolvedOrderFinancials['vendorResolutionSource'] = !vendorId
    ? 'none'
    : reassigned
      ? 'nearest_2km'
      : 'linked';

  let policyId: string | null = null;
  let commissionPerBottle = DEFAULT_PER_BOTTLE_COMMISSION;
  if (vendorId) {
    const { data: policy } = await supabaseAdmin
      .from('settlement_policy')
      .select('id, per_bottle_commission, commission_type, is_active, is_default')
      .eq('vendor_id', vendorId)
      .eq('is_active', true)
      .order('is_default', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (policy?.id) {
      policyId = policy.id;
      if (policy.commission_type === 'per_bottle' && Number(policy.per_bottle_commission) > 0) {
        commissionPerBottle = Number(policy.per_bottle_commission);
      }
    }
  }

  let unitPrice = DEFAULT_BOTTLE_PRICE;
  let productId: string | null = null;
  let productName: string | null = null;
  if (vendorId) {
    let vendorProductQuery = supabaseAdmin
      .from('vendor_products')
      .select('product_id, selling_price, is_active')
      .eq('vendor_id', vendorId)
      .eq('is_active', true);

    if (selectedProductId) {
      vendorProductQuery = vendorProductQuery.eq('product_id', selectedProductId);
    } else {
      vendorProductQuery = vendorProductQuery.order('updated_at', { ascending: false }).limit(1);
    }

    const { data: vendorProduct } = await vendorProductQuery.maybeSingle();

    if (vendorProduct?.selling_price && Number(vendorProduct.selling_price) > 0) {
      unitPrice = Number(vendorProduct.selling_price);
    }
    if (vendorProduct?.product_id) {
      productId = String(vendorProduct.product_id);
      const { data: product } = await supabaseAdmin
        .from('products')
        .select('name')
        .eq('id', productId)
        .maybeSingle();
      productName = (product?.name as string | undefined) || null;
    }
  }

  const bottleSubtotal = Number((unitPrice * canCount).toFixed(2));
  const commissionAmount = Number((commissionPerBottle * canCount).toFixed(2));
  const grossAmount = Number((bottleSubtotal + commissionAmount).toFixed(2));
  const vendorNetAmount = Number((grossAmount - commissionAmount).toFixed(2));

  return {
    vendorId,
    vendorResolutionSource,
    productId,
    productName,
    unitPrice,
    bottleSubtotal,
    commissionPerBottle,
    commissionAmount,
    grossAmount,
    vendorNetAmount,
    pricingVersion: 'marketplace_v1',
    policyId,
  };
}

async function insertOrderWithFallback(payload: Record<string, any>) {
  const orderPayload = { ...payload };
  const requiredFinancialColumns = new Set([
    'total_amount',
  ]);

  for (let i = 0; i < 12; i += 1) {
    const { data, error } = await supabaseAdmin
      .from('orders')
      .insert(orderPayload)
      .select('id, delivery_date, time_slot, total_amount, vendor_id, order_number, can_count')
      .single();

    if (!error) {
      return { data, usedPayload: orderPayload };
    }

    // Duplicate idempotency_key (concurrent placeOrder for the same order) —
    // recover the row that won the race instead of throwing a dead-end.
    if ((error as any).code === '23505' && orderPayload.idempotency_key) {
      const { data: winner } = await supabaseAdmin
        .from('orders')
        .select('id, delivery_date, time_slot, total_amount, vendor_id, order_number, can_count')
        .eq('idempotency_key', orderPayload.idempotency_key)
        .maybeSingle();
      if (winner?.id) {
        return { data: winner, usedPayload: orderPayload, deduped: true };
      }
    }

    const errorMessage = String(error.message || '');
    const missingColumnMatch = errorMessage.match(/Could not find the '([^']+)' column/);
    if (missingColumnMatch) {
      const missingColumn = missingColumnMatch[1];
      if (requiredFinancialColumns.has(missingColumn)) {
        throw error;
      }
      delete orderPayload[missingColumn];
      continue;
    }

    throw error;
  }

  throw new Error('Unable to insert order after schema fallback attempts');
}

async function insertCommissionLedgerWithFallback(payload: Record<string, any>) {
  const ledgerPayload = { ...payload };

  for (let i = 0; i < 10; i += 1) {
    const { error } = await supabaseAdmin.from('commission_ledger').insert(ledgerPayload);
    if (!error) return;

    const errorMessage = String(error.message || '');
    const missingColumnMatch = errorMessage.match(/Could not find the '([^']+)' column/);
    if (missingColumnMatch) {
      delete ledgerPayload[missingColumnMatch[1]];
      continue;
    }
    // If table is absent in older DBs, do not break order flow.
    if (
      errorMessage.includes('relation "commission_ledger" does not exist') ||
      errorMessage.includes('Could not find the table')
    ) {
      return;
    }
    throw error;
  }
}

async function insertOrderItemWithFallback(payload: Record<string, any>) {
  const itemPayload = { ...payload };

  for (let i = 0; i < 10; i += 1) {
    const { error } = await supabaseAdmin.from('order_items').insert(itemPayload);
    if (!error) return;

    const errorMessage = String(error.message || '');
    const missingColumnMatch = errorMessage.match(/Could not find the '([^']+)' column/);
    if (missingColumnMatch) {
      delete itemPayload[missingColumnMatch[1]];
      continue;
    }
    if (
      errorMessage.includes('relation "order_items" does not exist') ||
      errorMessage.includes('Could not find the table')
    ) {
      return;
    }
    throw error;
  }
}

async function placeOrder(phone: string, customer: any, session: any) {
  const { data: lockRows } = await supabaseAdmin
    .from('whatsapp_sessions')
    .update({ state: 'placing_order' })
    .eq('phone_number', phone)
    .eq('state', 'awaiting_confirmation')
    .select('id')
    .limit(1);

  const idempotencyKey = `wa:${session.id}:${session.delivery_date}:${session.time_slot}:${session.can_count}`;
  if (!lockRows || lockRows.length === 0) {
    // Strict lock (state must be awaiting_confirmation) didn't catch. Two cases:
    const { data: inflightOrder } = await supabaseAdmin
      .from('orders')
      .select('id')
      .eq('idempotency_key', idempotencyKey)
      .maybeSingle();

    if (inflightOrder?.id) {
      // The order genuinely already exists → tell the customer, don't dead-end.
      await sendWhatsAppMessage(
        phone,
        `✅ Your order is already placed! We'll notify you as it progresses.`
      );
      return;
    }

    // No order exists yet, but the lock wasn't in awaiting_confirmation — the
    // caller reached placeOrder from a different state. Rather than silently
    // dropping a real order (the old dead-end bug), acquire the lock
    // unconditionally and proceed. The orders.idempotency_key unique index is
    // the real duplicate guard, so this can't create a double order.
    await supabaseAdmin
      .from('whatsapp_sessions')
      .update({ state: 'placing_order' })
      .eq('phone_number', phone);
  }

  const { data: existingOrder } = await supabaseAdmin
    .from('orders')
    .select('id, delivery_date, time_slot, total_amount, vendor_id, order_number, can_count')
    .eq('idempotency_key', idempotencyKey)
    .maybeSingle();

  let order = existingOrder;
  let error: any = null;
  let resolvedFinancials: ResolvedOrderFinancials | null = null;

  if (!order) {
    const canCount = Number(session.can_count || 1);
    const sessionMeta = getOrderMeta(session);
    const financials = await resolveOrderFinancials(customer, canCount, sessionMeta?.product_id || null);
    resolvedFinancials = financials;

    if (!financials.vendorId) {
      await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
      await sendWhatsAppMessage(
        phone,
        `Sorry, we could not find an active vendor within 2km of your location right now. Our team has been notified and will help you shortly.`,
      );
      console.error('Order blocked: no linked/nearby vendor found', {
        customer_id: customer.id,
        phone,
        latitude: customer.latitude || null,
        longitude: customer.longitude || null,
      });
      return;
    }

    if (financials.productId) {
      const { data: stockReserved, error: stockError } = await supabaseAdmin.rpc('reserve_can_stock', {
        p_vendor_id: financials.vendorId,
        p_product_id: financials.productId,
        p_quantity: canCount,
      });

      if (stockError) {
        // RPC missing (migration not applied yet) must not silently allow unlimited overselling,
        // but also must not break orders for vendors who haven't run the migration —
        // log loudly and proceed only if the function genuinely doesn't exist.
        const message = String(stockError.message || '');
        if (!message.includes('function reserve_can_stock') && !message.includes('does not exist')) {
          console.error('Stock reservation check failed:', stockError);
          await supabaseAdmin.from('whatsapp_sessions').update({ state: 'awaiting_confirmation' }).eq('phone_number', phone);
          await sendWhatsAppMessage(phone, `Sorry, something went wrong placing your order. Please try again.`);
          return;
        }
        console.warn('reserve_can_stock RPC not found — apply supabase/migrations/20260628_add_whatsapp_stock_reservation.sql. Skipping stock check for this order.');
      } else if (stockReserved === false) {
        await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);
        await sendWhatsAppMessage(
          phone,
          `Sorry, this vendor is out of stock for the selected product right now. Please try again later or choose a different quantity.`,
        );
        return;
      }
    }

    const orderPayload = {
      order_number: `WA-${Date.now().toString(36).toUpperCase()}-${crypto
        .randomUUID()
        .replace(/-/g, '')
        .slice(0, 6)
        .toUpperCase()}`,
      customer_id: customer.id,
      vendor_id: financials.vendorId,
      can_count: canCount,
      delivery_date: session.delivery_date,
      time_slot: session.time_slot,
      delivery_address: customer.address,
      latitude: customer.latitude,
      longitude: customer.longitude,
      status: 'pending',
      source: 'whatsapp',
      total_amount: financials.grossAmount,
      gross_amount: financials.grossAmount,
      platform_commission_amount: financials.commissionAmount,
      vendor_net_amount: financials.vendorNetAmount,
      payment_status: 'unpaid',
      payment_state: 'pending',
      pricing_version: financials.pricingVersion,
      idempotency_key: idempotencyKey,
      financial_snapshot: {
        can_count: canCount,
        unit_price: financials.unitPrice,
        bottle_subtotal: financials.bottleSubtotal,
        commission_per_bottle: financials.commissionPerBottle,
        commission_amount: financials.commissionAmount,
        gross_amount: financials.grossAmount,
        vendor_net_amount: financials.vendorNetAmount,
        policy_id: financials.policyId,
      },
      notes: `[AUTO] WhatsApp order with pricing snapshot`,
    };

    try {
      const inserted = await insertOrderWithFallback(orderPayload);
      order = inserted.data;

      if (order?.id && financials.productId) {
        await insertOrderItemWithFallback({
          order_id: order.id,
          product_id: financials.productId,
          product_name: sessionMeta?.product_name || financials.productName || 'Water Can',
          quantity: canCount,
          unit_price: Number(sessionMeta?.unit_price || financials.unitPrice),
          subtotal: financials.bottleSubtotal,
        });
      }

      if (order?.id && financials.vendorId) {
        await insertCommissionLedgerWithFallback({
          order_id: order.id,
          vendor_id: financials.vendorId,
          customer_id: customer.id,
          commission_type: 'per_bottle',
          qty: canCount,
          per_bottle_commission: financials.commissionPerBottle,
          gross_amount: financials.grossAmount,
          commission_amount: financials.commissionAmount,
          net_vendor_amount: financials.vendorNetAmount,
          status: 'pending',
          rule_snapshot: {
            pricing_version: financials.pricingVersion,
            policy_id: financials.policyId,
            source: 'whatsapp',
          },
        });
      }
    } catch (insertError) {
      error = insertError;
    }
  }

  if (error || !order) {
    console.error('Failed to place order:', error);
    await supabaseAdmin
      .from('whatsapp_sessions')
      .update({ state: 'awaiting_confirmation' })
      .eq('phone_number', phone);
    await sendWhatsAppMessage(
      phone,
      `Sorry, something went wrong placing your order. Please try again.`
    );
    return;
  }

  // Clean up session only after successful order creation.
  await supabaseAdmin.from('whatsapp_sessions').delete().eq('phone_number', phone);

  if (order.vendor_id) {
    notifyVendorNewOrder(order.vendor_id, order.order_number || order.id, Number(order.can_count || session.can_count || 1));
  }

  const slotLabels: Record<string, string> = {
    morning: 'Morning (8am–12pm)',
    noon: 'Noon (12pm–3pm)',
    evening: 'Evening (3pm–9pm)',
  };

  // Vendor name makes the confirmation feel personal and tells the
  // customer who will actually show up at their door.
  let vendorName = 'your Can Can vendor';
  if (order.vendor_id) {
    const { data: v } = await supabaseAdmin
      .from('vendors')
      .select('business_name, name')
      .eq('id', order.vendor_id)
      .maybeSingle();
    vendorName = (v as any)?.business_name || (v as any)?.name || vendorName;
  }

  const orderAmount = Number(order.total_amount || 0);
  const canCount = Number(order.can_count || session.can_count || 1);
  const orderRef = order.order_number || String(order.id).slice(0, 8).toUpperCase();

  await sendWhatsAppMessage(
    phone,
    `🎉 *Order confirmed — thank you, ${customer.name}!* 💧\n\n` +
      `🧾 Order No: *${orderRef}*\n` +
      `💧 Items: ${canCount} Water Can${canCount > 1 ? 's' : ''}\n` +
      `💰 Total: *₹${orderAmount.toFixed(0)}*\n` +
      `📍 Delivery Address: ${(order as any).delivery_address || customer.address}\n` +
      `📅 Delivery Date: ${new Date(order.delivery_date).toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' })}\n` +
      `⏰ Time Slot: ${slotLabels[order.time_slot] || order.time_slot}\n` +
      `🚚 Delivered by: *${vendorName}*\n\n` +
      `_We'll send you updates here on WhatsApp as your order progresses._`
  );

  // Ask customer how they want to pay
  await supabaseAdmin
    .from('whatsapp_sessions')
    .upsert(
      { phone_number: phone, state: 'awaiting_payment_choice', customer_id: customer.id, vendor_id: resolvedFinancials?.vendorId || session.vendor_id || null },
      { onConflict: 'phone_number' }
    );

  await sendReplyButtons(
    phone,
    `💳 *How would you like to pay ₹${orderAmount.toFixed(0)}?*\n\n` +
      `1️⃣ *Pay Online* — quick & secure UPI / card / netbanking. We'll send you a payment link right here.\n\n` +
      `2️⃣ *Cash on Delivery* — pay ${vendorName} in cash when your water arrives.\n\n` +
      `Choose whichever is easier for you 👇`,
    [
      { id: `pay_online_${order.id}`, title: '💳 Pay Online' },
      { id: `pay_cod_${order.id}`, title: '💵 Cash on Delivery' },
    ]
  );
}

// ─────────────────────────────────────────────────────────────
// REPEAT LAST ORDER
// ─────────────────────────────────────────────────────────────

async function repeatLastOrder(phone: string, customer: any) {
  const { data: lastOrder } = await supabaseAdmin
    .from('orders')
    .select('*')
    .eq('customer_id', customer.id)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (!lastOrder) {
    await sendWhatsAppMessage(phone, `You don't have any previous orders. Let's place a new one!`);
    await startOrderFlow(phone, customer);
    return;
  }

  const slotLabels: Record<string, string> = {
    morning: 'Morning (8am–12pm)',
    noon: 'Noon (12pm–3pm)',
    evening: 'Evening (3pm–9pm)',
  };

  const lastAmt = Number(lastOrder.total_amount || 0);
  await sendReplyButtons(
    phone,
    `🔁 *Repeat your last order?*\n\n` +
      `💧 ${lastOrder.can_count} Water Can${lastOrder.can_count > 1 ? 's' : ''}\n` +
      `💰 Total: ₹${lastAmt.toFixed(0)}\n` +
      `📍 ${lastOrder.delivery_address}\n` +
      `⏰ ${slotLabels[lastOrder.time_slot] || lastOrder.time_slot}\n` +
      `📅 Delivery: *Today*\n\n` +
      `Tap *Confirm* to place this order for today, or change the time slot first 👇`,
    [
      { id: 'repeat_confirm', title: '✅ Confirm' },
      { id: 'repeat_change_slot', title: '🕐 Change Time Slot' },
    ]
  );

  // Store repeat order context in session
  await supabaseAdmin.from('whatsapp_sessions').upsert(
    {
      phone_number: phone,
      state: 'repeat_awaiting_choice',
      customer_id: customer.id,
      can_count: lastOrder.can_count,
      time_slot: lastOrder.time_slot,
      vendor_id: lastOrder.vendor_id || customer.vendor_id || null,
    },
    { onConflict: 'phone_number' }
  );
}

// ─────────────────────────────────────────────────────────────
// MY DELIVERIES
// ─────────────────────────────────────────────────────────────

async function showMyDeliveries(phone: string, customerId: string) {
  const oneMonthAgo = new Date();
  oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

  const { data: orders } = await supabaseAdmin
    .from('orders')
    .select('id, can_count, delivery_date, status')
    .eq('customer_id', customerId)
    .gte('delivery_date', oneMonthAgo.toISOString().split('T')[0])
    .order('delivery_date', { ascending: false })
    .limit(5);

  if (!orders || orders.length === 0) {
    await sendWhatsAppMessage(phone, `You have no recent deliveries in the last month.`);
    return;
  }

  const statusEmoji: Record<string, string> = {
    delivered: '✅',
    pending: '⏳',
    confirmed: '🔵',
    cancelled: '❌',
    failed: '🔴',
  };

  const list = orders
    .map(
      (o, i) =>
        `${i + 1}. ${statusEmoji[o.status] || '📦'} ${new Date(o.delivery_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })} — ${o.can_count} can${o.can_count > 1 ? 's' : ''} (${o.status})\n   _ID: ${o.id}_`
    )
    .join('\n\n');

  await sendWhatsAppMessage(
    phone,
    `📋 *Recent Deliveries (last 30 days):*\n\n${list}\n\nReply with an order number (1–${orders.length}) for full details.`
  );
}

async function showDeliveryDetail(phone: string, orderId: string, customerId: string) {
  const { data: order } = await supabaseAdmin
    .from('orders')
    .select('*')
    .eq('id', orderId)
    .eq('customer_id', customerId)
    .single();

  if (!order) {
    await sendWhatsAppMessage(phone, `Order not found.`);
    return;
  }

  const slotLabels: Record<string, string> = {
    morning: 'Morning (8am–12pm)',
    noon: 'Noon (12pm–3pm)',
    evening: 'Evening (3pm–9pm)',
  };

  await sendWhatsAppMessage(
    phone,
    `📦 *Order Details*\n\nID: ${order.id}\n💧 ${order.can_count} can${order.can_count > 1 ? 's' : ''}\n📍 ${order.delivery_address}\n📅 ${new Date(order.delivery_date).toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' })}\n⏰ ${slotLabels[order.time_slot] || order.time_slot}\n📊 Status: *${order.status}*`
  );
}

// ─────────────────────────────────────────────────────────────
// UPDATE ADDRESS
// ─────────────────────────────────────────────────────────────

async function startUpdateAddress(phone: string) {
  await supabaseAdmin.from('whatsapp_sessions').upsert(
    { phone_number: phone, state: 'update_address_location' },
    { onConflict: 'phone_number' }
  );
  await sendLocationRequestMessage(
    phone,
    `📍 Please drop your new location pin so we can update your delivery address.`
  );
}

// ─────────────────────────────────────────────────────────────
// HELP
// ─────────────────────────────────────────────────────────────

async function showHelp(phone: string) {
  await sendReplyButtons(
    phone,
    `🆘 *How can we help?*`,
    [
      { id: 'help_delivery_issue', title: '🚚 Delivery Issue' },
      { id: 'help_wrong_order', title: '❌ Wrong Order' },
      { id: 'help_contact_vendor', title: '📞 Contact Vendor' },
    ]
  );
  // 4th option: Can Can support via text since only 3 buttons allowed
  await sendWhatsAppMessage(
    phone,
    `_For Can Can support, reply "support" or email us at support@cancan.in_`
  );
}

// ─────────────────────────────────────────────────────────────
// MAIN MENU
// ─────────────────────────────────────────────────────────────

async function showMainMenu(phone: string, name: string) {
  // Check if they have a previous order to offer "Repeat Last Order"
  const { data: customer } = await supabaseAdmin
    .from('customers')
    .select('id')
    .eq('phone', phone)
    .single();

  let hasLastOrder = false;
  if (customer) {
    const { data: lastOrder } = await supabaseAdmin
      .from('orders')
      .select('id')
      .eq('customer_id', customer.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();
    hasLastOrder = !!lastOrder;
  }

  if (hasLastOrder) {
    // Returning customer menu with Repeat Last Order
    await sendReplyButtons(
      phone,
      `👋 Welcome back, *${name}*!\n\nWhat would you like to do?`,
      [
        { id: 'menu_repeat_last', title: '🔁 Repeat Last Order' },
        { id: 'menu_order_water', title: '💧 New Order' },
        { id: 'menu_my_deliveries', title: '📋 My Deliveries' },
      ]
    );
    // Send second set of options (WA only allows 3 buttons)
    await sendReplyButtons(
      phone,
      `More options:`,
      [
        { id: 'menu_update_address', title: '📍 Update Address' },
        { id: 'menu_help', title: '🆘 Help' },
      ]
    );
  } else {
    // First-time / no orders yet
    await sendReplyButtons(
      phone,
      `👋 Welcome, *${name}*!\n\nWhat would you like to do?`,
      [
        { id: 'menu_order_water', title: '💧 Order Water' },
        { id: 'menu_update_address', title: '📍 Update Address' },
        { id: 'menu_help', title: '🆘 Help' },
      ]
    );
  }
}

// ─────────────────────────────────────────────────────────────
// OUTBOUND NOTIFICATION HELPERS (call from your order management)
// ─────────────────────────────────────────────────────────────

/**
 * Call this from your vendor portal when vendor accepts an order.
 */
export async function notifyOrderAccepted(customerPhone: string, orderId: string, vendorName: string) {
  await sendWhatsAppMessage(
    customerPhone,
    `✅ *Order Confirmed!*\n\nYour order *${orderId}* has been accepted by *${vendorName}*.\n\nWe'll notify you when it's out for delivery. 💧`
  );
}

/**
 * Call this when the order is delivered.
 */
export async function notifyOrderDelivered(customerPhone: string, orderId: string, vendorName: string) {
  await sendWhatsAppMessage(
    customerPhone,
    `💧 *Your order has been delivered!*\n\nOrder *${orderId}* from *${vendorName}* is complete. Thank you!\n\n_Send "Hi" to begin your next order._`
  );
}

/**
 * Call this when a vendor fails to deliver on the confirmed date.
 */
export async function notifyDeliveryFailed(customerPhone: string, deliveryDate: string) {
  await sendReplyButtons(
    customerPhone,
    `⚠️ *Delivery Attempt Failed*\n\nWe're sorry — your delivery for *${deliveryDate}* could not be completed.\n\nYour order will be delivered tomorrow.`,
    [
      { id: 'failed_okay', title: '👍 Okay' },
      { id: 'failed_contact_vendor', title: '📞 Contact Vendor' },
    ]
  );
}

// ─────────────────────────────────────────────────────────────
// UTILITIES
// ─────────────────────────────────────────────────────────────

async function reverseGeocode(lat: number, lng: number): Promise<string> {
  const apiKey = process.env.GOOGLE_MAPS_GEOCODING_API_KEY;
  const fallback = `${lat.toFixed(4)}, ${lng.toFixed(4)}`;

  if (!apiKey) {
    console.warn('[reverseGeocode] GOOGLE_MAPS_GEOCODING_API_KEY not set — falling back to raw coordinates');
    return fallback;
  }

  try {
    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${apiKey}`;
    const res = await fetch(url);
    if (!res.ok) {
      console.error('[reverseGeocode] Google Geocoding API HTTP error', res.status);
      return fallback;
    }
    const data = await res.json();
    if (data.status !== 'OK') {
      console.error('[reverseGeocode] Google Geocoding API status', data.status, data.error_message);
      return fallback;
    }
    return data.results?.[0]?.formatted_address || fallback;
  } catch (e) {
    console.error('[reverseGeocode] request failed', e);
    return fallback;
  }
}

/** Returns the customer's current owning vendor (customers.vendor_id — Model A). */
async function getCustomerVendor(customerId: string) {
  return await supabaseAdmin
    .from('customers')
    .select('vendor_id, vendors(name, phone)')
    .eq('id', customerId)
    .single();
}
