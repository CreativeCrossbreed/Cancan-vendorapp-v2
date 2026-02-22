import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    if (admin.role !== 'super_admin') {
        return Response.json({ error: 'Only super admins can assign orders' }, { status: 403 });
    }

    const { id } = await params;
    const { vendor_id } = await req.json();

    if (!vendor_id) {
        return Response.json({ error: 'Vendor ID is required' }, { status: 400 });
    }

    const { data: order, error } = await supabaseAdmin
        .from('orders')
        .update({ vendor_id, status: 'assigned' })
        .eq('id', id)
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(order);
}
