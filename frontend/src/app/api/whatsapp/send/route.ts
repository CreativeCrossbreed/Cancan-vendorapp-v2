import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { sendWhatsAppMessage } from '@/lib/whatsapp';

export async function POST(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    try {
        const { to, message } = await req.json();

        if (!to || !message) {
            return Response.json({ error: 'Phone number and message are required' }, { status: 400 });
        }

        const result = await sendWhatsAppMessage(to, message);
        return Response.json({ success: true, result });
    } catch (error: any) {
        console.error('Send custom message error:', error);
        return Response.json({ error: error.message || 'Internal server error' }, { status: 500 });
    }
}
