import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { supabaseAdmin } from '@/lib/supabase';
import { sendWhatsAppMessage, sendImageMessage } from '@/lib/whatsapp';

// Sending to many customers can take a while; give the function room.
export const maxDuration = 60;

/**
 * Promotional broadcast to customers who are within WhatsApp's 24-hour
 * messaging window (i.e. they messaged us in the last 24h). Free-form text
 * and/or an image are ALLOWED inside this window without a template.
 *
 * NOTE: To reach customers OUTSIDE this window you must use an approved
 * Marketing template — this endpoint intentionally only targets the window.
 */
export async function POST(req: NextRequest) {
  const admin = await authenticateAdmin(req);
  if (!admin) return unauthorized();

  try {
    const body = await req.json();
    const message: string = (body.message || '').trim();
    const imageUrl: string = (body.imageUrl || '').trim();

    if (!message && !imageUrl) {
      return Response.json({ error: 'Provide a message and/or an image URL.' }, { status: 400 });
    }

    // Eligible recipients: distinct customers with an inbound message in the
    // last 24 hours (the free-form window). Config rows (__wa_config__ etc.)
    // never appear here since they live in whatsapp_sessions, not messages.
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { data: inbound } = await supabaseAdmin
      .from('whatsapp_messages')
      .select('customer_phone')
      .eq('direction', 'inbound')
      .gte('created_at', since);

    const phones = Array.from(
      new Set(
        (inbound || [])
          .map((r: { customer_phone: string }) => r.customer_phone)
          .filter((p) => p && !p.startsWith('__')),
      ),
    );

    if (phones.length === 0) {
      return Response.json({
        sent: 0,
        failed: 0,
        total: 0,
        note: 'No customers are within the 24-hour messaging window right now. For a wider reach, an approved Marketing template is required.',
      });
    }

    let sent = 0;
    let failed = 0;
    for (const phone of phones) {
      try {
        if (imageUrl) {
          await sendImageMessage(phone, imageUrl, message || undefined);
        } else {
          await sendWhatsAppMessage(phone, message);
        }
        sent += 1;
      } catch (err) {
        console.error('Broadcast send failed for', phone, err);
        failed += 1;
      }
    }

    return Response.json({ sent, failed, total: phones.length });
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Broadcast failed';
    console.error('[POST /api/whatsapp/broadcast]', error);
    return Response.json({ error: msg }, { status: 500 });
  }
}
