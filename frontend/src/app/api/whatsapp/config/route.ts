import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { data, error } = await supabaseAdmin
        .from('app_settings')
        .select('key, value')
        .in('key', ['whatsapp_api_token', 'whatsapp_phone_number_id', 'whatsapp_webhook_secret']);

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const config: Record<string, string> = {};
    for (const row of data || []) {
        config[row.key] = row.value;
    }

    return Response.json(config);
}
