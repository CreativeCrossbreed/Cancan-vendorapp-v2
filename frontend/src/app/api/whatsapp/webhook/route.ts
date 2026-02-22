import { NextRequest } from 'next/server';
import crypto from 'crypto';
import { supabaseAdmin } from '@/lib/supabase';
import { sendWhatsAppMessage, sendInteractiveList, sendReplyButtons } from '@/lib/whatsapp';

// A lightweight version of the 900-line WhatsApp flow, adapted for Serverless + Interactive Messages

const WHATSAPP_WEBHOOK_SECRET = process.env.WHATSAPP_WEBHOOK_SECRET;
const META_APP_SECRET = process.env.META_APP_SECRET || process.env.WHATSAPP_APP_SECRET;

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

// ----- MESSAGE PROCESSING (The Flow) -----

async function processMessage(message: any, customerPhone: string) {
    if (!customerPhone) return;

    const msgType = message.type;

    // 1. User sends a text message (e.g. "I want to order water")
    if (msgType === 'text') {
        const text = message.text.body.toLowerCase();

        // Check if they are scanning a vendor's QR code (e.g. "Order from REF-123")
        let vendorId = null;
        if (text.includes('order from ref-')) {
            // In a real app, parse the ref
            vendorId = 'detected-vendor-id';
        }

        // Start flow: Send Interactive List of Water Cans
        await sendInteractiveList(
            customerPhone,
            '🚰 Can Can Water Delivery',
            'Please select the type of water can you would like to order:',
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

        // Save session state to DB here
        return;
    }

    // 2. User tapped an Interactive List item
    if (msgType === 'interactive' && message.interactive.type === 'list_reply') {
        const selectedItem = message.interactive.list_reply.id; // e.g., '20l_mineral'

        // Send Reply Buttons for quantity
        await sendReplyButtons(
            customerPhone,
            `Great! You selected ${selectedItem}. How many cans do you need?`,
            [
                { id: `qty_1_${selectedItem}`, title: '1 Can' },
                { id: `qty_2_${selectedItem}`, title: '2 Cans' },
                { id: `qty_3_${selectedItem}`, title: '3 Cans' },
            ]
        );

        // Update session state
        return;
    }

    // 3. User tapped a Reply Button (Quantity selection)
    if (msgType === 'interactive' && message.interactive.type === 'button_reply') {
        const buttonId = message.interactive.button_reply.id; // e.g., 'qty_2_20l_mineral'

        if (buttonId.startsWith('qty_')) {
            // Parse product and quantity
            const parts = buttonId.split('_');
            const qty = parseInt(parts[1], 10);

            // Order confirmation buttons
            await sendReplyButtons(
                customerPhone,
                `Almost done! Confirm your order of ${qty} cans to your registered address.`,
                [
                    { id: 'confirm_order', title: '✅ Confirm Order' },
                    { id: 'cancel_order', title: '❌ Cancel' },
                ]
            );
            return;
        }

        if (buttonId === 'confirm_order') {
            // Find assigned vendor, create order in DB

            await sendWhatsAppMessage(
                customerPhone,
                '🎉 Your order is confirmed! A vendor will deliver your water soon. We will notify you once they are on the way.'
            );
            return;
        }
    }
}

