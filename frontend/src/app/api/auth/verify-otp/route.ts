import { NextRequest } from 'next/server';
import crypto from 'node:crypto';
import { supabaseAdmin } from '@/lib/supabase';
import { verifyOtp, toTenDigits } from '@/lib/two-factor';
import { isRateLimited } from '@/lib/rate-limit';

export const dynamic = 'force-dynamic';
export const maxDuration = 30;

/**
 * Deterministic Supabase password for a phone. Stable across logins (so we can
 * hand it back and immediately signInWithPassword), and unguessable without the
 * server secret. 2Factor has already proven possession of the number by this
 * point — the password is just the bridge to a real, RLS-valid auth session.
 */
function derivePassword(phone10: string): string {
    const secret = process.env.OTP_PASSWORD_SECRET || process.env.JWT_SECRET;
    if (!secret) throw new Error('OTP_PASSWORD_SECRET/JWT_SECRET not set');
    return 'Cc9-' + crypto.createHmac('sha256', secret).update(phone10).digest('hex');
}

/** Scan auth.users for a phone (digits, no +). Small vendor base → cheap. */
async function findAuthUserIdByPhone(digits: string): Promise<string | null> {
    for (let page = 1; page <= 25; page++) {
        const { data, error } = await supabaseAdmin.auth.admin.listUsers({ page, perPage: 200 });
        if (error || !data?.users?.length) return null;
        const hit = data.users.find((u) => u.phone === digits);
        if (hit) return hit.id;
        if (data.users.length < 200) return null; // last page
    }
    return null;
}

export async function POST(req: NextRequest) {
    try {
        const { phone, otp } = await req.json();
        const phone10 = toTenDigits(String(phone ?? ''));
        const code = String(otp ?? '').trim();
        if (!phone10 || !/^\d{4,8}$/.test(code)) {
            return Response.json({ success: false, message: 'Invalid phone or OTP.' }, { status: 400 });
        }

        if (isRateLimited(`otp-verify:${phone10}`, 10, 10 * 60 * 1000)) {
            return Response.json(
                { success: false, message: 'Too many attempts. Please wait and try again.' },
                { status: 429 },
            );
        }

        // 1) Verify the code with 2Factor (verify-by-phone, stateless).
        const result = await verifyOtp(phone10, code);
        if (!result.success) {
            return Response.json({ success: false, message: 'Invalid or expired OTP.' }, { status: 401 });
        }

        // 2) Ensure a Supabase auth user exists for this phone, with our
        //    deterministic password set, then return it so the app can sign in.
        const digits = `91${phone10}`; // auth.users stores phone without '+'
        const plusE164 = `+91${phone10}`; // vendors.phone stores with '+'
        const password = derivePassword(phone10);

        // Resolve the REAL auth user by phone — auth.users is the source of
        // truth for identity. We deliberately do NOT trust vendors.id here: a
        // legacy/seed vendor row can carry an id that is not a live auth user,
        // and calling updateUserById() on it would 500. Resolving from auth
        // avoids that entirely (a mismatched vendor row simply falls through to
        // createUser and the user re-onboards cleanly).
        let userId = await findAuthUserIdByPhone(digits);

        if (userId) {
            const { error: updErr } = await supabaseAdmin.auth.admin.updateUserById(userId, {
                password,
                phone_confirm: true,
            });
            if (updErr) throw updErr;
        } else {
            const { data: created, error: createErr } = await supabaseAdmin.auth.admin.createUser({
                phone: plusE164,
                password,
                phone_confirm: true,
            });
            if (createErr || !created?.user) throw createErr ?? new Error('createUser returned no user');
            userId = created.user.id;
        }

        // 3) Does this vendor have a completed profile yet?
        const { data: profile } = await supabaseAdmin
            .from('vendors')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        return Response.json({
            success: true,
            message: 'OTP verified',
            phone: plusE164,
            password, // client uses this once for signInWithPassword over HTTPS
            vendorId: userId,
            hasProfile: !!profile,
        });
    } catch (e) {
        console.error('[verify-otp] error:', e);
        return Response.json({ success: false, message: 'Verification failed. Please try again.' }, { status: 500 });
    }
}
