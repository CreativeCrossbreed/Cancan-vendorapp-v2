import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';

// Public endpoint — used by the onboarding form to display the vendor name
// Only returns the vendor's public info (business_name), no sensitive data
export async function GET(req: NextRequest, { params }: { params: Promise<{ vendorId: string }> }) {
    const { vendorId } = await params;

    const { data: vendor, error } = await supabaseAdmin
        .from('vendors')
        .select('id, business_name')
        .eq('id', vendorId)
        .single();

    if (error || !vendor) {
        return Response.json({ error: 'Vendor not found' }, { status: 404 });
    }

    return Response.json({ vendor });
}
