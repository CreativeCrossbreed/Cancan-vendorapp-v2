import { supabaseAdmin } from './supabase';

/**
 * 2Factor.in OTP integration.
 *
 * AUTOGEN flow — 2Factor generates, sends AND verifies the OTP itself (using
 * its own DLT-approved template), so we store nothing server-side:
 *   send   → GET /API/V1/{key}/SMS/{phone10}/AUTOGEN
 *   verify → GET /API/V1/{key}/SMS/VERIFY3/{phone10}/{otp}   (verify-by-phone, no session id)
 *
 * The API key is sourced from a DB config row first (so it can be rotated
 * without a redeploy, matching the Cashfree/WhatsApp config pattern), then
 * falls back to the TWOFACTOR_API_KEY env var.
 */

let _keyCache: { key: string; at: number } | null = null;

async function getApiKey(): Promise<string> {
    if (_keyCache && Date.now() - _keyCache.at < 60_000) return _keyCache.key;
    let key = '';
    try {
        const { data } = await supabaseAdmin
            .from('whatsapp_sessions')
            .select('name')
            .eq('phone_number', '__2f_config__')
            .maybeSingle();
        if (data) key = (data as { name?: string }).name || '';
    } catch {
        // table/row absent — fall through to env
    }
    key = key || process.env.TWOFACTOR_API_KEY || '';
    if (key) _keyCache = { key, at: Date.now() };
    return key;
}

/** Reduce any Indian phone input to the bare 10-digit subscriber number. */
export function toTenDigits(phone: string): string | null {
    const digits = (phone || '').replace(/\D/g, '');
    // strip 91 / 0 country/trunk prefixes if present
    let n = digits;
    if (n.length === 12 && n.startsWith('91')) n = n.slice(2);
    else if (n.length === 11 && n.startsWith('0')) n = n.slice(1);
    return n.length === 10 ? n : null;
}

type TwoFactorResult = { success: boolean; details: string };

async function call(path: string): Promise<TwoFactorResult> {
    const key = await getApiKey();
    if (!key) return { success: false, details: 'OTP service not configured' };
    try {
        const res = await fetch(`https://2factor.in/API/V1/${key}/${path}`, {
            signal: AbortSignal.timeout(8000),
        });
        const json = (await res.json()) as { Status?: string; Details?: string };
        return {
            success: (json.Status || '').toLowerCase() === 'success',
            details: json.Details || '',
        };
    } catch (e) {
        return { success: false, details: e instanceof Error ? e.message : 'network error' };
    }
}

export async function sendOtp(phone10: string): Promise<TwoFactorResult> {
    return call(`SMS/${phone10}/AUTOGEN`);
}

export async function verifyOtp(phone10: string, otp: string): Promise<TwoFactorResult> {
    return call(`SMS/VERIFY3/${phone10}/${encodeURIComponent(otp)}`);
}
