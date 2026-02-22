import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { supabaseAdmin as supabase } from './supabase';
import { NextRequest } from 'next/server';

const JWT_SECRET = process.env.JWT_SECRET || 'cancan-dev-jwt-secret';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const DEV_MODE = process.env.DEV_MODE === 'true';

export interface AdminUser {
    id: string;
    email: string;
    role: string;
    type: 'admin';
    last_login?: string;
}

export interface VendorUser {
    vendorId: string;
    phone: string;
    businessName?: string;
    type: 'vendor';
}

export type AuthUser = AdminUser | VendorUser;

// Generate JWT token
export function signToken(payload: Record<string, unknown>): string {
    return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN as unknown as number });
}

// Verify JWT token
export function verifyToken(token: string): Record<string, unknown> | null {
    try {
        return jwt.verify(token, JWT_SECRET) as Record<string, unknown>;
    } catch {
        return null;
    }
}

// Extract bearer token from request
export function extractToken(req: NextRequest): string | null {
    const authHeader = req.headers.get('authorization');
    if (!authHeader) return null;
    const parts = authHeader.split(' ');
    return parts.length === 2 && parts[0] === 'Bearer' ? parts[1] : null;
}

// Authenticate admin from request — returns admin user or null
export async function authenticateAdmin(req: NextRequest): Promise<AdminUser | null> {
    const token = extractToken(req);
    if (!token) return null;

    const decoded = verifyToken(token);
    if (!decoded || decoded.type !== 'admin') return null;

    // Dev mode bypass
    if (DEV_MODE && decoded.email === 'admin@cancan.com') {
        return {
            id: 'dev-admin-1',
            email: 'admin@cancan.com',
            role: 'super_admin',
            type: 'admin',
            last_login: new Date().toISOString(),
        };
    }

    // ENV-based super admin bypass (for production without DB admin_users)
    const envAdminEmail = process.env.ADMIN_EMAIL;
    if (envAdminEmail && decoded.email === envAdminEmail) {
        return {
            id: 'env-admin',
            email: envAdminEmail,
            role: 'super_admin',
            type: 'admin',
            last_login: new Date().toISOString(),
        };
    }

    // Fetch from Supabase
    const { data: admin, error } = await supabase
        .from('admin_users')
        .select('*')
        .eq('id', decoded.id)
        .eq('is_active', true)
        .single();

    if (error || !admin) return null;

    return { ...admin, type: 'admin' };
}

// Authenticate vendor from request
export async function authenticateVendor(req: NextRequest): Promise<VendorUser | null> {
    const token = extractToken(req);
    if (!token) return null;

    const decoded = verifyToken(token);
    if (!decoded || decoded.type !== 'vendor') return null;

    // Dev mode bypass
    if (DEV_MODE && decoded.phone === process.env.DEV_PHONE) {
        return {
            vendorId: 'dev-vendor-123',
            phone: decoded.phone as string,
            type: 'vendor',
        };
    }

    // Fetch from Supabase
    const { data: vendor, error } = await supabase
        .from('vendors')
        .select('*')
        .eq('id', decoded.vendorId)
        .eq('is_active', true)
        .single();

    if (error || !vendor) return null;

    return {
        vendorId: vendor.id,
        phone: vendor.phone,
        businessName: vendor.business_name,
        type: 'vendor',
    };
}

// Hash password
export async function hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, 12);
}

// Verify password
export async function comparePassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
}

// Unauthorized response helper
export function unauthorized(message = 'Unauthorized') {
    return Response.json({ error: message }, { status: 401 });
}

// Forbidden response helper
export function forbidden(message = 'Forbidden') {
    return Response.json({ error: message }, { status: 403 });
}
