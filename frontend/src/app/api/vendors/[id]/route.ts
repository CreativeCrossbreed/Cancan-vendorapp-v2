import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;

    const { data: vendor, error } = await supabaseAdmin
        .from('vendors')
        .select('*')
        .eq('id', id)
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 404 });
    }

    return Response.json(vendor);
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    if (admin.role !== 'super_admin' && admin.id !== (await params).id) {
        return Response.json({ error: 'Permission denied' }, { status: 403 });
    }

    const { id } = await params;
    const data = await req.json();

    const { data: updatedVendor, error } = await supabaseAdmin
        .from('vendors')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(updatedVendor);
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    if (admin.role !== 'super_admin') {
        return Response.json({ error: 'Only super admins can delete vendors' }, { status: 403 });
    }

    const { id } = await params;

    const { error } = await supabaseAdmin
        .from('vendors')
        .delete()
        .eq('id', id);

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json({ success: true, message: 'Vendor deleted successfully' });
}
