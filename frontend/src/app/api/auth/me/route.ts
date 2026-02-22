import { NextRequest } from 'next/server';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const user = await authenticateAdmin(req);
    if (!user) return unauthorized();

    return Response.json({
        user: {
            id: user.id,
            email: user.email,
            role: user.role,
            type: user.type,
            last_login: user.last_login,
        },
    });
}
