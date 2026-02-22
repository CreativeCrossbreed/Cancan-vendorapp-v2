import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function PUT(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    if (admin.role !== 'super_admin') {
        return Response.json({ error: 'Only super admins can bulk update commissions' }, { status: 403 });
    }

    const { commission_ids, status } = await req.json();

    if (!commission_ids || !Array.isArray(commission_ids) || !status) {
        return Response.json({ error: 'Invalid payload' }, { status: 400 });
    }

    const { error } = await supabaseAdmin
        .from('commissions')
        .update({ status })
        .in('id', commission_ids);

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json({ success: true, message: `Updated ${commission_ids.length} commissions to ${status}` });
}
