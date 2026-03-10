import { NextRequest } from 'next/server';
import crypto from 'crypto';
import { supabaseAdmin } from '@/lib/supabase';
import { sendWhatsAppMessage, sendInteractiveList, sendReplyButtons, sendLocationRequestMessage } from '@/lib/whatsapp';

const WHATSAPP_WEBHOOK_SECRET = process.env.WHATSAPP_WEBHOOK_SECRET;
const META_APP_SECRET = process.env.META_APP_SECRET || process.env.WHATSAPP_APP_SECRET;

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
// MESSAGE PROCESSING (State Machine)
// ────────────────────────────────────────────────────

async function processMessage(message: any, customerPhone: string) {
    if (!customerPhone) return;

    const msgType = message.type;

    // Check if customer exists in DB
    const { data: customer } = await supabaseAdmin
        .from('customers')
        .select('id, name')
        .eq('phone', customerPhone)
        .single();

    if (!customer) {
        // --- NEW CUSTOMER ONBOARDING STATE MACHINE ---
        await handleOnboarding(message, customerPhone);
        return;
    }

    // --- EXISTING CUSTOMER FLOW (ORDERS) ---

    // 1. Order Intent
    if (msgType === 'text') {
        const text = message.text.body.toLowerCase().trim();
        if (text === 'order' || text === 'hi' || text === 'hello' || text.includes('water')) {
            await showOrderMenu(customerPhone, customer.name);
            return;
        }
        await sendWhatsAppMessage(customerPhone, `👋 Welcome back, ${customer.name}!\n\nSend "order" to place a new water can order.`);
        return;
    }

    // 2. Interactive list reply (product selection)
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

    // 3. Button reply (quantity / confirmation)
    if (msgType === 'interactive' && message.interactive.type === 'button_reply') {
        const buttonId = message.interactive.button_reply.id;

        if (buttonId.startsWith('qty_')) {
            const parts = buttonId.split('_');
            const qty = parseInt(parts[1], 10);
            const productId = parts.slice(2).join('_');

            await sendReplyButtons(
                customerPhone,
                `Almost done! Confirm your order of ${qty} can${qty > 1 ? 's' : ''} to your registered address.`,
                [
                    { id: `confirm_${qty}_${productId}`, title: '✅ Confirm Order' },
                    { id: 'cancel_order', title: '❌ Cancel' },
                ]
            );
            return;
        }

        if (buttonId.startsWith('confirm_')) {
            // Ideally, here we insert into the `orders` table
            await sendWhatsAppMessage(
                customerPhone,
                '🎉 Your order is confirmed! A vendor will deliver your water soon. We will notify you once they are on the way.'
            );
            return;
        }

        if (buttonId === 'cancel_order') {
            await sendWhatsAppMessage(customerPhone, '❌ Order cancelled. Send "order" anytime to try again!');
            return;
        }
    }
}

// ────────────────────────────────────────────────────
// CONVERSATIONAL ONBOARDING HANDLER
// ────────────────────────────────────────────────────

async function handleOnboarding(message: any, phone: string) {
    const msgType = message.type;

    // Check if a session already exists
    const { data: session } = await supabaseAdmin
        .from('whatsapp_sessions')
        .select('*')
        .eq('phone_number', phone)
        .single();

    if (!session) {
        // Start brand new onboarding session
        await supabaseAdmin.from('whatsapp_sessions').insert({
            phone_number: phone,
            state: 'awaiting_name'
        });

        await sendWhatsAppMessage(phone, "👋 Welcome to Can Can Water Delivery!\n\nLet's get you set up so you can order water instantly. What is your Full Name?");
        return;
    }

    // --- STATE: AWAITING NAME ---
    if (session.state === 'awaiting_name') {
        if (msgType !== 'text') {
            await sendWhatsAppMessage(phone, "Please type your full name to continue.");
            return;
        }

        const name = message.text.body.trim();
        await supabaseAdmin.from('whatsapp_sessions')
            .update({ name, state: 'awaiting_location' })
            .eq('id', session.id);

        await sendLocationRequestMessage(phone, `Nice to meet you, ${name}! To ensure fast delivery, please drop your 📍 Location Pin using the button below.`);
        return;
    }

    // --- STATE: AWAITING LOCATION ---
    if (session.state === 'awaiting_location') {
        if (msgType !== 'location') {
            await sendLocationRequestMessage(phone, "Please use the 'Send Location' button to drop your map pin so we can find you.");
            return;
        }

        const { latitude, longitude } = message.location;
        await supabaseAdmin.from('whatsapp_sessions')
            .update({ latitude, longitude, state: 'awaiting_address' })
            .eq('id', session.id);

        await sendWhatsAppMessage(phone, "Got it! Thanks. Finally, what is your Flat/House No and Landmark?");
        return;
    }

    // --- STATE: AWAITING ADDRESS REFINEMENT ---
    if (session.state === 'awaiting_address') {
        if (msgType !== 'text') {
            await sendWhatsAppMessage(phone, "Please type your Flat/House number and Building name/Landmark.");
            return;
        }

        const address = message.text.body.trim();

        // Finalize! Create the actual customer in the DB.
        const { error } = await supabaseAdmin.from('customers').insert({
            phone,
            name: session.name,
            address: address, // combining flat/house directly into address
            latitude: session.latitude,
            longitude: session.longitude,
            is_verified: true,
            is_active: true
        });

        if (error) {
            console.error("Failed to create customer:", error);
            await sendWhatsAppMessage(phone, "Sorry, something went wrong saving your profile. Please try again.");
            return;
        }

        // Clean up session
        await supabaseAdmin.from('whatsapp_sessions').delete().eq('id', session.id);

        await sendWhatsAppMessage(phone, "✅ Perfect! Your profile is set up. Welcome aboard!");

        // Automatically show them the ordering menu
        await showOrderMenu(phone, session.name);
        return;
    }
}

// ────────────────────────────────────────────────────
// FLOW HELPERS
// ────────────────────────────────────────────────────

async function showOrderMenu(phone: string, name: string) {
    await sendInteractiveList(
        phone,
        '🚰 Can Can Water Delivery',
        `Hi ${name}! What would you like to order today?`,
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
