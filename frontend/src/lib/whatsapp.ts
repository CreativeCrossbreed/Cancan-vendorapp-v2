import axios from 'axios';
import { supabaseAdmin } from './supabase';

const WHATSAPP_API_URL = 'https://graph.facebook.com/v17.0';

// Fetch WhatsApp credentials — DB first, env fallback
async function getWhatsAppCredentials() {
    try {
        const { data } = await supabaseAdmin
            .from('app_settings')
            .select('key, value')
            .in('key', ['whatsapp_api_token', 'whatsapp_phone_number_id']);

        const settings: Record<string, string> = {};
        for (const row of data || []) settings[row.key] = row.value;

        return {
            token: settings.whatsapp_api_token || process.env.WHATSAPP_API_TOKEN || '',
            phoneNumberId: settings.whatsapp_phone_number_id || process.env.WHATSAPP_PHONE_NUMBER_ID || '',
        };
    } catch {
        return {
            token: process.env.WHATSAPP_API_TOKEN || '',
            phoneNumberId: process.env.WHATSAPP_PHONE_NUMBER_ID || '',
        };
    }
}

export async function sendWhatsAppMessage(to: string, message: any, type: string = 'text') {
    const { token, phoneNumberId } = await getWhatsAppCredentials();

    if (!token || !phoneNumberId) {
        console.warn('WhatsApp API credentials missing. Running in dry-run mode.');
        return { mock: true, to, message };
    }

    const url = `${WHATSAPP_API_URL}/${phoneNumberId}/messages`;

    const payload: any = {
        messaging_product: 'whatsapp',
        to,
        type,
    };

    if (type === 'text') {
        payload.text = { body: message };
    } else if (type === 'interactive') {
        payload.interactive = message;
    }

    try {
        const response = await axios.post(url, payload, {
            headers: {
                Authorization: `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
        });

        // Save outbound message to history
        await supabaseAdmin.from('whatsapp_messages').insert([{
            message_id: response.data.messages?.[0]?.id || `mock_${Date.now()}`,
            customer_phone: to,
            message_type: type,
            message_content: type === 'text' ? message : JSON.stringify(message),
            direction: 'outbound',
            status: 'sent',
        }]);

        return response.data;
    } catch (error: any) {
        const failurePayload = error.response?.data || error.message;
        console.error('WhatsApp API Error:', failurePayload);

        // Do not crash upstream webhook handlers on outbound send failures.
        // Persist failure for observability and allow inbound flow to proceed.
        try {
            await supabaseAdmin.from('whatsapp_messages').insert([{
                message_id: `failed_${Date.now()}`,
                customer_phone: to,
                message_type: type,
                message_content: type === 'text' ? message : JSON.stringify(message),
                direction: 'outbound',
                status: 'failed',
            }]);
        } catch (persistError) {
            console.error('Failed to persist outbound WhatsApp failure log:', persistError);
        }

        return {
            ok: false,
            error: failurePayload,
        };
    }
}

// Helper: Send Interactive List (e.g. Can Brand Selection)
export async function sendInteractiveList(
    to: string,
    headerText: string,
    bodyText: string,
    buttonText: string,
    sections: { title: string; rows: { id: string; title: string; description?: string }[] }[]
) {
    const message = {
        type: 'list',
        header: { type: 'text', text: headerText },
        body: { text: bodyText },
        action: {
            button: buttonText,
            sections,
        },
    };
    return sendWhatsAppMessage(to, message, 'interactive');
}

// Helper: Send Reply Buttons (e.g. Quantity Selection / Confirmation)
export async function sendReplyButtons(
    to: string,
    bodyText: string,
    buttons: { id: string; title: string }[]
) {
    const message = {
        type: 'button',
        body: { text: bodyText },
        action: {
            buttons: buttons.map(b => ({
                type: 'reply',
                reply: { id: b.id, title: b.title.substring(0, 20) }, // Title max 20 chars
            })),
        },
    };
    return sendWhatsAppMessage(to, message, 'interactive');
}

// Helper: Send Location Request (Native WhatsApp location pin request)
export async function sendLocationRequestMessage(to: string, bodyText: string) {
    const message = {
        type: 'location_request_message',
        body: { text: bodyText },
        action: {
            name: 'send_location',
        },
    };
    return sendWhatsAppMessage(to, message, 'interactive');
}
