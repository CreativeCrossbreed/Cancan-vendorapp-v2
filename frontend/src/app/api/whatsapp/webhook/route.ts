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
      console.error('META_APP_SECRET is missing in production.');
      return new Response('Service Misconfigured', { status: 500 });
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

  // DEDUPLICATION
  const messageId = message.id;
  if (messageId) {
    const { data: existing } = await supabaseAdmin
      .from('whatsapp_messages')
      .select('id')
      .eq('message_id', messageId)
      .single();
    if (existing) return;

    await supabaseAdmin.from('whatsapp_messages').insert([{
      message_id: messageId,
      customer_phone: customerPhone,
      message_type: message.type,
      message_content: message.text?.body || JSON.stringify(message),
      direction: 'inbound',
      status: 'received',
    }]);
  }

  // RATE LIMIT
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count: recentCount } = await supabaseAdmin
    .from('whatsapp_messages')
    .select('*', { count: 'exact', head: true })
    .eq('customer_phone', customerPhone)
    .eq('direction', 'inbound')
    .gte('created_at', oneHourAgo);
  if ((recentCount ?? 0) > 20) return;

  // Check for vendor ref code in the message
  let vendorId: string | null = null;
  if (message.type === 'text') {
    const refMatch = message.text.body.trim().match(/^ref-([a-f0-9-]+)$/i);
    if (refMatch) vendorId = refMatch[1];
  }

  // Look up customer
  const { data: customer } = await supabaseAdmin
    .from('customers')
    .select('id, name, address, latitude, longitude')
    .eq('phone', customerPhone)
    .single();

  // ── NEW CUSTOMER: hand off to onboarding ──
  if (!customer) {
    await handleOnboarding(message, customerPhone, vendorId);
    return;
  }

  // ── EXISTING CUSTOMER: link to new vendor if ref code sent ──
  if (vendorId) {
    await supabaseAdmin.from('customer_vendors').upsert(
      { customer_id: customer.id, vendor_id: vendorId },
      { onConflict: 'customer_id,vendor_id' }
    );
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
          .eq('id', session.id);

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
          .eq('id', session.id);
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
          .eq('id', session.id);
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
          .eq('id', session.id);

        // Refresh session data to show confirmation
        const { data: updatedSession } = await supabaseAdmin
          .from('whatsapp_sessions')
          .select('*')
          .eq('id', session.id)
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
          .eq('id', session.id);
        await sendDateButtons(phone);
        return;
      }
      if (id === 'cancel_order') {
        await supabaseAdmin.from('whatsapp_sessions').delete().eq('id', session.id);
        await sendWhatsAppMessage(phone, `Your order has been cancelled.`);
        await showMainMenu(phone, customer.name);
        return;
      }
    }
    const { data: fresh } = await supabaseAdmin
      .from('whatsapp_sessions')
      .select('*')
      .eq('id', session.id)
      .single();
    await sendOrderConfirmation(phone, customer, fresh);
    return;
  }

  // ── REPEAT LAST ORDER FLOW ─────────────────────────────────

  if (state === 'repeat_awaiting_choice') {
    if (message.type === 'interactive' && message.interactive.type === 'button_reply') {
      const id = message.interactive.button_reply.id;

      if (id === 'repeat_confirm') {
        // Place repeat order with today's date and stored time_slot
        const today = new Date().toISOString().split('T')[0];
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ delivery_date: today })
          .eq('id', session.id);
        session.delivery_date = today;
        await placeOrder(phone, customer, session);
        return;
      }

      if (id === 'repeat_change_slot') {
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'repeat_awaiting_time_slot' })
          .eq('id', session.id);
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
          .update({ time_slot: slot, delivery_date: today })
          .eq('id', session.id);
        session.time_slot = slot;
        session.delivery_date = today;
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
      .eq('id', session.id);

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
        await supabaseAdmin.from('whatsapp_sessions').delete().eq('id', session.id);
        await sendWhatsAppMessage(phone, `✅ Great! Your address has been updated.`);
        await showMainMenu(phone, customer.name);
        return;
      }

      if (id === 'addr_edit') {
        // Ask them to type their address manually
        await supabaseAdmin
          .from('whatsapp_sessions')
          .update({ state: 'update_address_manual' })
          .eq('id', session.id);
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
      await supabaseAdmin.from('whatsapp_sessions').delete().eq('id', session.id);
      await sendWhatsAppMessage(phone, `✅ Your address has been updated to:\n\n_${address}_`);
      await showMainMenu(phone, customer.name);
      return;
    }
    await sendWhatsAppMessage(phone, `Please type your address.`);
    return;
  }
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
      .eq('id', session.id);
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
      .eq('id', session.id);
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
      .eq('id', session.id);

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
          .eq('id', session.id);
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
  const { data: newCustomer, error } = await supabaseAdmin
    .from('customers')
    .insert({
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

  await supabaseAdmin.from('whatsapp_sessions').delete().eq('id', session.id);

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
  const { data: vendorLink } = await supabaseAdmin
    .from('customer_vendors')
    .select('vendor_id')
    .eq('customer_id', customer.id)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (vendorLink?.vendor_id) return String(vendorLink.vendor_id);

  const nearestVendorId = await resolveNearestVendor(customer);
  if (!nearestVendorId) return null;

  await linkCustomerVendor(customer.id, nearestVendorId);
  return nearestVendorId;
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
    .eq('id', session.id);
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
    .select('id, latitude, longitude, is_active')
    .eq('is_active', true)
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

async function resolveOrderFinancials(
  customer: any,
  canCount: number,
  selectedProductId?: string | null,
): Promise<ResolvedOrderFinancials> {
  const { data: vendorLink } = await supabaseAdmin
    .from('customer_vendors')
    .select('vendor_id')
    .eq('customer_id', customer.id)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  let vendorId = vendorLink?.vendor_id ?? null;
  let vendorResolutionSource: ResolvedOrderFinancials['vendorResolutionSource'] = vendorId ? 'linked' : 'none';

  if (!vendorId) {
    const nearestVendorId = await resolveNearestVendor(customer);
    if (nearestVendorId) {
      vendorId = nearestVendorId;
      vendorResolutionSource = 'nearest_2km';
      await linkCustomerVendor(customer.id, nearestVendorId);
    }
  }

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
      .select('id, delivery_date, time_slot, total_amount')
      .single();

    if (!error) {
      return { data, usedPayload: orderPayload };
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
    .eq('id', session.id)
    .eq('state', 'awaiting_confirmation')
    .select('id')
    .limit(1);

  const idempotencyKey = `wa:${session.id}:${session.delivery_date}:${session.time_slot}:${session.can_count}`;
  if (!lockRows || lockRows.length === 0) {
    const { data: inflightOrder } = await supabaseAdmin
      .from('orders')
      .select('id')
      .eq('idempotency_key', idempotencyKey)
      .maybeSingle();

    if (inflightOrder?.id) {
      await sendWhatsAppMessage(
        phone,
        `Your order is already being processed. We'll confirm shortly.`
      );
    }
    return;
  }

  const { data: existingOrder } = await supabaseAdmin
    .from('orders')
    .select('id, delivery_date, time_slot, total_amount')
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
      await supabaseAdmin.from('whatsapp_sessions').delete().eq('id', session.id);
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
      .eq('id', session.id);
    await sendWhatsAppMessage(
      phone,
      `Sorry, something went wrong placing your order. Please try again.`
    );
    return;
  }

  // Clean up session only after successful order creation.
  await supabaseAdmin.from('whatsapp_sessions').delete().eq('id', session.id);

  const slotLabels: Record<string, string> = {
    morning: 'Morning (8am–12pm)',
    noon: 'Noon (12pm–3pm)',
    evening: 'Evening (3pm–9pm)',
  };

  await sendWhatsAppMessage(
    phone,
    `🎉 *Your order has been placed!* 💧\n\n📦 Order ID: *${order.id}*\n📅 Expected Delivery: ${new Date(order.delivery_date).toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' })}\n⏰ Time Slot: ${slotLabels[order.time_slot] || order.time_slot}\n\n_We'll notify you once the vendor confirms._`
  );

  // Best-effort payment link creation (non-blocking).
  try {
    const orderAmount = Number(order.total_amount || 0);
    if (orderAmount > 0) {
      const provider = (process.env.PAYMENT_PROVIDER_DEFAULT || 'razorpay') as 'razorpay' | 'cashfree';
      const receipt = `wa_${String(order.id).slice(0, 8)}_${Date.now()}`;
      const providerOrder = await createProviderOrder({
        provider,
        amountInPaise: Math.round(orderAmount * 100),
        receipt,
        notes: {
          order_id: order.id,
          source: 'whatsapp',
        },
      });

      const paymentIntent = await createPaymentIntentRecord({
        orderId: order.id,
        customerId: customer.id,
        vendorId: resolvedFinancials?.vendorId || session.vendor_id || null,
        provider,
        providerOrderId: providerOrder.providerOrderId,
        amount: orderAmount,
        checkoutUrl: providerOrder.checkoutUrl || null,
        idempotencyKey: `wa-intent:${order.id}`,
        metadata: {
          source: 'whatsapp',
        },
      });

      const checkoutUrl = paymentIntent.checkout_url || providerOrder.checkoutUrl;
      if (checkoutUrl) {
        await sendWhatsAppMessage(
          phone,
          `💳 You can pay online now: ${checkoutUrl}\n\nYou may also pay cash to CanCan at delivery.`,
        );
      }
    }
  } catch (paymentLinkError) {
    console.error('Failed to generate WhatsApp payment link:', paymentLinkError);
  }
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

  await sendReplyButtons(
    phone,
    `🔁 *Your last order:*\n\n💧 ${lastOrder.can_count} Water Can${lastOrder.can_count > 1 ? 's' : ''}\n📍 ${lastOrder.delivery_address}\n⏰ ${slotLabels[lastOrder.time_slot] || lastOrder.time_slot}`,
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
  // Replace with your preferred geocoding service.
  // Example using Google Maps Geocoding API:
  //
  // const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  // const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${apiKey}`;
  // const res = await fetch(url);
  // const data = await res.json();
  // return data.results?.[0]?.formatted_address || `${lat}, ${lng}`;

  return `${lat.toFixed(4)}, ${lng.toFixed(4)}`; // ← replace with real geocoding
}

async function getCustomerVendor(customerId: string) {
  return await supabaseAdmin
    .from('customer_vendors')
    .select('vendor_id, vendors(name, phone)')
    .eq('customer_id', customerId)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();
}
