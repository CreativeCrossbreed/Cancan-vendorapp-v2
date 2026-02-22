import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;

    const { data: order, error } = await supabaseAdmin
        .from('orders')
        .select(`
            *,
            customers ( id, name, phone, address ),
            vendors ( id, name, business_name, phone ),
            order_items (
                id, product_name, quantity, unit_price, subtotal
            )
        `)
        .eq('id', id)
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 404 });
    }

    return Response.json(order);
}
