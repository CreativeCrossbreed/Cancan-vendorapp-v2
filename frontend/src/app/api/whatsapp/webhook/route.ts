import { NextRequest } from 'next/server';
import crypto from 'crypto';
import { supabaseAdmin } from '@/lib/supabase';
import { sendWhatsAppMessage, sendInteractiveList, sendReplyButtons } from '@/lib/whatsapp';

// WhatsApp Webhook — handles verification + incoming messages
// Flow: QR scan → detect vendor ref → new customer gets onboarding link, returning customer gets order menu

const WHATSAPP_WEBHOOK_SECRET = process.env.WHATSAPP_WEBHOOK_SECRET;
const META_APP_SECRET = process.env.META_APP_SECRET || process.env.WHATSAPP_APP_SECRET;
const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL || 'https://cancanindia.com';

// ── GET: Facebook verification handshake ──
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

        // Verify signature if secret is configured
        if (META_APP_SECRET && signature) {
            const hmac = crypto.createHmac('sha256', META_APP_SECRET);
            const expectedSignature = `sha256=${hmac.update(rawBody).digest('hex')}`;
            if (signature !== expectedSignature) {
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

// ────────────────────────────────────────────────────
// MESSAGE PROCESSING
// ────────────────────────────────────────────────────

async function processMessage(message: any, customerPhone: string) {
    if (!customerPhone) return;

    const msgType = message.type;

    // ── 1. Text message (first contact or free-form) ──
    if (msgType === 'text') {
        const text = message.text.body.toLowerCase().trim();

        // Check if this is a QR code scan (contains vendor ref)
        const refMatch = text.match(/ref[- ]?([a-f0-9-]+)/i);
        const vendorId = refMatch ? refMatch[1] : null;

        if (vendorId) {
            await handleVendorReferral(customerPhone, vendorId);
            return;
        }

        // Check if they want to order
        if (text === 'order' || text === 'hi' || text === 'hello' || text.includes('water') || text.includes('can')) {
            await handleOrderIntent(customerPhone);
            return;
        }

        // Default: greeting + help
        await sendWhatsAppMessage(
            customerPhone,
            '👋 Welcome to Can Can Water Delivery!\n\nSend "order" to place a water can order, or scan your vendor\'s QR code to get started.'
        );
        return;
    }

    // ── 2. Interactive list reply (product selection) ──
    if (msgType === 'interactive' && message.interactive.type === 'list_reply') {
        const selectedItem = message.interactive.list_reply.id;

        await sendReplyButtons(
            customerPhone,
            `Great! You selected ${message.interactive.list_reply.title}. How many cans do you need?`,
            [
                { id: `qty_1_${selectedItem}`, title: '1 Can' },
                { id: `qty_2_${selectedItem}`, title: '2 Cans' },
                { id: `qty_3_${selectedItem}`, title: '3 Cans' },
            ]
        );
        return;
    }

    // ── 3. Button reply (quantity / confirmation) ──
    if (msgType === 'interactive' && message.interactive.type === 'button_reply') {
        const buttonId = message.interactive.button_reply.id;

        if (buttonId.startsWith('qty_')) {
            const parts = buttonId.split('_');
            const qty = parseInt(parts[1], 10);

            await sendReplyButtons(
                customerPhone,
                `Almost done! Confirm your order of ${qty} can${qty > 1 ? 's' : ''} to your registered address.`,
                [
                    { id: 'confirm_order', title: '✅ Confirm Order' },
                    { id: 'cancel_order', title: '❌ Cancel' },
                ]
            );
            return;
        }

        if (buttonId === 'confirm_order') {
            await sendWhatsAppMessage(
                customerPhone,
                '🎉 Your order is confirmed! A vendor will deliver your water soon. We will notify you once they are on the way.'
            );
            return;
        }

        if (buttonId === 'cancel_order') {
            await sendWhatsAppMessage(
                customerPhone,
                '❌ Order cancelled. Send "order" anytime to try again!'
            );
            return;
        }
    }
}

// ────────────────────────────────────────────────────
// FLOW HELPERS
// ────────────────────────────────────────────────────

/**
 * Handle a vendor QR code referral.
 * - New customer → send onboarding form link
 * - Existing customer → link to vendor + show order menu
 */
async function handleVendorReferral(phone: string, vendorId: string) {
    // Validate vendor exists
    const { data: vendor } = await supabaseAdmin
        .from('vendors')
        .select('id, business_name')
        .eq('id', vendorId)
        .single();

    if (!vendor) {
        await sendWhatsAppMessage(phone, '❌ Sorry, we couldn\'t find that vendor. Please try scanning the QR code again.');
        return;
    }

    // Check if customer already exists
    const { data: existingCustomer } = await supabaseAdmin
        .from('customers')
        .select('id, name')
        .eq('phone', phone)
        .single();

    if (existingCustomer) {
        // Existing customer — link to this vendor (if not already) and show order menu
        await supabaseAdmin
            .from('customer_vendors')
            .upsert(
                { customer_id: existingCustomer.id, vendor_id: vendorId, referral_source: 'qr_code' },
                { onConflict: 'customer_id,vendor_id' }
            );

        await sendWhatsAppMessage(
            phone,
            `Welcome back, ${existingCustomer.name}! 🎉 You're now connected with ${vendor.business_name}.\n\nSend "order" to place a new water can order! 🚰`
        );
        return;
    }

    // New customer — send onboarding form link
    const formUrl = `${BASE_URL}/onboard?v=${vendorId}&p=${phone}`;

    await sendWhatsAppMessage(
        phone,
        `👋 Welcome to *Can Can Water Delivery*!\n\nYou're about to connect with *${vendor.business_name}*.\n\nPlease complete your profile so we can deliver water to your doorstep:\n\n🔗 ${formUrl}\n\nIt only takes 30 seconds! 🚰`
    );
}

/**
 * Handle an order intent from a known customer.
 * If customer is not registered, prompt them to scan a QR code.
 */
async function handleOrderIntent(phone: string) {
    // Check if customer exists
    const { data: customer } = await supabaseAdmin
        .from('customers')
        .select('id, name')
        .eq('phone', phone)
        .single();

    if (!customer) {
        await sendWhatsAppMessage(
            phone,
            '👋 Hi there! It looks like you haven\'t registered yet.\n\nPlease scan your vendor\'s QR code to get started, or ask your vendor for the link. 📱'
        );
        return;
    }

    // Show the ordering menu
    await sendInteractiveList(
        phone,
        '🚰 Can Can Water Delivery',
        `Hi ${customer.name}! What would you like to order today?`,
        'View Options',
        [
            {
                title: 'Available Options',
                rows: [
                    { id: '20l_mineral', title: '20L Mineral Water', description: '₹40 per can' },
                    { id: '20l_ro', title: '20L RO Purified', description: '₹60 per can' },
                    { id: '5l_mineral', title: '5L Mineral Water', description: '₹30 per can' },
                ],
            },
        ]
    );
}
