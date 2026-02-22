import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;
    const { status, notes, cancellation_reason } = await req.json();

    if (!status) {
        return Response.json({ error: 'Status is required' }, { status: 400 });
    }

    const { data: order, error } = await supabaseAdmin
        .from('orders')
        .update({ status, notes, cancellation_reason })
        .eq('id', id)
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(order);
}
