import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { supabaseAdmin } from '@/lib/supabase';

export async function GET(req: NextRequest) {
  const admin = await authenticateAdmin(req);
  if (!admin) return unauthorized();

  try {
    const searchParams = req.nextUrl.searchParams;
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);
    const status = searchParams.get('status');
    const severity = searchParams.get('severity');

    let query = supabaseAdmin
      .from('reconciliation_issues')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false });

    if (status && status !== 'all') query = query.eq('status', status);
    if (severity && severity !== 'all') query = query.eq('severity', severity);

    const { data, count, error } = await query.range((page - 1) * limit, page * limit - 1);
    if (error) {
      return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json({
      issues: data || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Failed to fetch reconciliation issues';
    return Response.json({ error: message }, { status: 500 });
  }
}
