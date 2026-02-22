import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    if (admin.role !== 'super_admin') {
        return Response.json({ error: 'Only super admins can update commission status' }, { status: 403 });
    }

    const { id } = await params;
    const { status } = await req.json();

    if (!status) {
        return Response.json({ error: 'Status is required' }, { status: 400 });
    }

    const { data: commission, error } = await supabaseAdmin
        .from('commissions')
        .update({ status })
        .eq('id', id)
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(commission);
}
