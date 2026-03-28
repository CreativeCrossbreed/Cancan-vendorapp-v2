import { createClient } from '@supabase/supabase-js';

/**
 * Supabase env — use ONLY these names in `.env` / `.env.local`:
 *
 *   NEXT_PUBLIC_SUPABASE_URL or SUPABASE_URL — project URL
 *   SUPABASE_ANON_KEY — anon key (server-only; do not use NEXT_PUBLIC_ — it would ship to the browser)
 *   SUPABASE_SERVICE_ROLE_KEY — service_role (server-only)
 */
const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.SUPABASE_URL ||
    'https://your-project.supabase.co';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'your_anon_key';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'your_service_key';

if (process.env.NODE_ENV === 'development' && supabaseServiceKey === 'your_service_key') {
    console.warn(
        '[supabase] SUPABASE_SERVICE_ROLE_KEY is not set. Add it from Supabase → Settings → API (service_role). ' +
            'Without it, /api/customers, /api/vendors, /api/orders, etc. will return 500.',
    );
}

// Anon client — only use from server code; SUPABASE_ANON_KEY is not available in the browser bundle
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
