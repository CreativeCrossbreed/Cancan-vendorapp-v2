import { createClient } from '@supabase/supabase-js';

/**
 * Supabase env — use ONLY these names in `.env` / `.env.local`:
 *
 *   NEXT_PUBLIC_SUPABASE_URL       — Project URL (same for browser + server)
 *   NEXT_PUBLIC_SUPABASE_ANON_KEY  — anon / publishable key (safe in browser)
 *   SUPABASE_SERVICE_ROLE_KEY      — service_role key (server-only, never NEXT_PUBLIC)
 *
 * Legacy aliases (optional): SUPABASE_URL, SUPABASE_ANON_KEY — same values if you prefer not to duplicate.
 */
const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.SUPABASE_URL ||
    'https://your-project.supabase.co';
const supabaseAnonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_ANON_KEY ||
    'your_anon_key';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'your_service_key';

if (process.env.NODE_ENV === 'development' && supabaseServiceKey === 'your_service_key') {
    console.warn(
        '[supabase] SUPABASE_SERVICE_ROLE_KEY is not set. Add it from Supabase → Settings → API (service_role). ' +
            'Without it, /api/customers, /api/vendors, /api/orders, etc. will return 500.',
    );
}

// Browser-safe client (uses NEXT_PUBLIC_* so it works in Client Components)
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
        persistSession: true,
        autoRefreshToken: true,
    },
});

// API routes only — bypasses RLS
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false,
    },
});

export const isSupabaseConfigured = () =>
    supabaseUrl !== 'https://your-project.supabase.co' && supabaseAnonKey !== 'your_anon_key';
