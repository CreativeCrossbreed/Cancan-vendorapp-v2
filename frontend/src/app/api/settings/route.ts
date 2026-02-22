import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

// GET /api/settings — fetch all settings as key-value object
export async function GET(req: NextRequest) {
    const user = await authenticateAdmin(req);
    if (!user) return unauthorized();

    const { data, error } = await supabaseAdmin
        .from('app_settings')
        .select('key, value');

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    // Convert rows to { key: value } object
    const settings: Record<string, string> = {};
    for (const row of data || []) {
        settings[row.key] = row.value;
    }

    return Response.json({ settings });
}

// PUT /api/settings — upsert multiple settings. Super admin only.
export async function PUT(req: NextRequest) {
    const user = await authenticateAdmin(req);
    if (!user) return unauthorized();

    if (user.role !== 'super_admin') {
        return Response.json({ error: 'Only super admins can update settings' }, { status: 403 });
    }

    const { settings } = await req.json();

    if (!settings || typeof settings !== 'object') {
        return Response.json({ error: 'Settings object required' }, { status: 400 });
    }

    const rows = Object.entries(settings).map(([key, value]) => ({
        key,
        value: String(value),
        updated_at: new Date().toISOString(),
    }));

    const { error } = await supabaseAdmin
        .from('app_settings')
        .upsert(rows, { onConflict: 'key' });

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json({ success: true, message: 'Settings saved successfully' });
}
