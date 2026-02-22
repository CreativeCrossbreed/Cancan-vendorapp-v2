import { NextRequest } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase';
import { signToken, comparePassword } from '@/lib/auth';

const DEV_MODE = process.env.DEV_MODE === 'true';

export async function POST(req: NextRequest) {
    try {
        const { email, password } = await req.json();

        if (!email || !password) {
            return Response.json({ error: 'Email and password required' }, { status: 400 });
        }

        // Development mode — bypass database for demo
        if (DEV_MODE && email === 'admin@cancan.com' && password === 'admin123') {
            const token = signToken({ email: 'admin@cancan.com', role: 'super_admin', type: 'admin' });
            return Response.json({
                token,
                user: {
                    id: 'dev-admin-1',
                    email: 'admin@cancan.com',
                    role: 'super_admin',
                    last_login: new Date().toISOString(),
                },
            });
        }

        // Production-safe ENV-based Super Admin
        const envAdminEmail = process.env.ADMIN_EMAIL;
        const envAdminPassword = process.env.ADMIN_PASSWORD;

        if (envAdminEmail && envAdminPassword && email === envAdminEmail && password === envAdminPassword) {
            const token = signToken({ email: envAdminEmail, role: 'super_admin', type: 'admin' });
            return Response.json({
                token,
                user: {
                    id: 'env-admin',
                    email: envAdminEmail,
                    role: 'super_admin',
                    last_login: new Date().toISOString(),
                },
            });
        }

        // Fetch admin user from Supabase
        const { data: admin, error } = await supabase
            .from('admin_users')
            .select('*')
            .eq('email', email)
            .eq('is_active', true)
            .single();

        if (error || !admin) {
            return Response.json({ error: 'Invalid credentials' }, { status: 401 });
        }

        // Verify password
        const isValid = await comparePassword(password, admin.password);
        if (!isValid) {
            return Response.json({ error: 'Invalid credentials' }, { status: 401 });
        }

        // Update last login
        await supabase
            .from('admin_users')
            .update({ last_login: new Date().toISOString() })
            .eq('id', admin.id);

        // Generate JWT token
        const token = signToken({
            id: admin.id,
            email: admin.email,
            role: admin.role,
            type: 'admin',
        });

        return Response.json({
            token,
            user: {
                id: admin.id,
                email: admin.email,
                role: admin.role,
                last_login: admin.last_login,
            },
        });
    } catch (error) {
        console.error('Admin login error:', error);
        return Response.json({ error: 'Internal server error' }, { status: 500 });
    }
}

