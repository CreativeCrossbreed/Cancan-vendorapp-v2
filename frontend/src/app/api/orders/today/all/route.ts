import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const { data: orders, error } = await supabaseAdmin
        .from('orders')
        .select(`
            *,
            customers ( name, phone ),
            vendors ( name, business_name )
        `)
        .gte('created_at', today.toISOString())
        .order('created_at', { ascending: false });

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(orders);
}
