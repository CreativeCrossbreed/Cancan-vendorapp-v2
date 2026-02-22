import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;

    const { data: customer, error } = await supabaseAdmin
        .from('customers')
        .select('*')
        .eq('id', id)
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 404 });
    }

    return Response.json(customer);
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;
    const data = await req.json();

    const { data: updatedCustomer, error } = await supabaseAdmin
        .from('customers')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(updatedCustomer);
}
