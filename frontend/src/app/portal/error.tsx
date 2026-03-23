'use client';

export default function PortalError({
    error,
    reset,
}: {
    error: Error & { digest?: string };
    reset: () => void;
}) {
    const isFetchError = error.message?.toLowerCase().includes('fetch failed');
    const isAuthError = error.message?.toLowerCase().includes('jwt') || error.message?.toLowerCase().includes('unauthorized') || error.message?.toLowerCase().includes('token');
    const isSupabaseError = error.message?.toLowerCase().includes('supabase') || error.message?.toLowerCase().includes('postgrest') || error.message?.toLowerCase().includes('api key');

    return (
        <div className="min-h-screen bg-slate-900 text-slate-50 font-mono flex items-center justify-center p-6">
            <div className="max-w-[800px] w-full border border-slate-700 rounded-2xl overflow-hidden shadow-2xl">
                {/* Header */}
                <div className="bg-gradient-to-br from-red-600 to-red-800 px-6 py-5 flex items-center gap-3">
                    <span className="text-[28px]">🛑</span>
                    <div>
                        <h2 className="m-0 text-lg font-extrabold tracking-wide">
                            ADMIN PORTAL ERROR
                        </h2>
                        <p className="mt-1 text-xs text-red-300">
                            A component in the admin portal crashed. Diagnostic details below.
                        </p>
                    </div>
                </div>

                <div className="p-6 bg-slate-800">
                    {/* Error */}
                    <div className="border-l-4 border-red-500 p-4 bg-slate-900 rounded-lg mb-5">
                        <p className="m-0 text-[10px] text-slate-400 uppercase tracking-widest mb-1.5">
                            Fatal Exception
                        </p>
                        <p className="m-0 text-[15px] text-red-400 font-bold break-words">
                            {error.name}: {error.message}
                        </p>
                        {error.digest && (
                            <p className="mt-1.5 text-[11px] text-slate-500">digest: {error.digest}</p>
                        )}
                    </div>

                    {/* Smart Diagnostics */}
                    {isFetchError && (
                        <div className="bg-amber-950 border border-amber-600 rounded-lg p-4 mb-4">
                            <p className="m-0 font-extrabold text-[13px] text-amber-200 mb-1.5">💡 Fetch Failure Detected</p>
                            <ul className="m-0 pl-[18px] text-xs text-amber-100 leading-relaxed">
                                <li>Check if <code>NEXT_PUBLIC_SUPABASE_URL</code> is set correctly in <code>.env.local</code></li>
                                <li>Verify the Supabase project is online at your dashboard URL</li>
                                <li>Check your network connection and any VPN/proxy settings</li>
                                <li>Open browser DevTools → Network tab for the exact failing request</li>
                            </ul>
                        </div>
                    )}

                    {isAuthError && (
                        <div className="bg-indigo-950 border border-indigo-500 rounded-lg p-4 mb-4">
                            <p className="m-0 font-extrabold text-[13px] text-indigo-300 mb-1.5">🔐 Authentication Error</p>
                            <ul className="m-0 pl-[18px] text-xs text-indigo-200 leading-relaxed">
                                <li>Your session token may have expired — try logging out and back in</li>
                                <li>Check <code>JWT_SECRET</code> in <code>.env.local</code></li>
                                <li>Click &quot;Hard Reset&quot; below to clear all session data</li>
                            </ul>
                        </div>
                    )}

                    {isSupabaseError && (
                        <div className="bg-teal-950 border border-teal-500 rounded-lg p-4 mb-4">
                            <p className="m-0 font-extrabold text-[13px] text-teal-300 mb-1.5">🗄️ Supabase / API Key Error</p>
                            <ul className="m-0 pl-[18px] text-xs text-teal-200 leading-relaxed">
                                <li>Verify <code>SUPABASE_SERVICE_ROLE_KEY</code> is set (not a placeholder!)</li>
                                <li>Ensure <code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code> matches your Supabase project</li>
                                <li>Check Row Level Security (RLS) policies if getting permission denied</li>
                            </ul>
                        </div>
                    )}

                    {/* Environment Check */}
                    <div className="mb-5">
                        <p className="m-0 mb-2 text-[10px] text-slate-400 uppercase tracking-widest">
                            Environment Status
                        </p>
                        <div className="bg-slate-900 border border-slate-700 rounded-lg p-3 text-xs">
                            {[
                                { key: 'NEXT_PUBLIC_SUPABASE_URL', val: process.env.NEXT_PUBLIC_SUPABASE_URL },
                                { key: 'NEXT_PUBLIC_SUPABASE_ANON_KEY', val: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY },
                            ].map((e) => (
                                <div key={e.key} className="flex justify-between py-1.5 border-b border-slate-800 last:border-b-0">
                                    <span className="text-slate-300">{e.key}</span>
                                    <span className={e.val ? 'text-green-400 font-bold' : 'text-red-400 font-bold'}>
                                        {e.val ? '✅ Set' : '❌ MISSING'}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Stack Trace */}
                    <div className="mb-5">
                        <p className="m-0 mb-2 text-[10px] text-slate-400 uppercase tracking-widest">
                            Stack Trace
                        </p>
                        <pre className="bg-slate-900 border border-slate-700 rounded-lg p-3 m-0 text-[10px] text-slate-500 whitespace-pre-wrap break-all max-h-[180px] overflow-auto leading-relaxed">
                            {error.stack || 'No stack trace available.'}
                        </pre>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-2.5 flex-wrap">
                        <button
                            onClick={reset}
                            className="px-5 py-2.5 bg-blue-500 text-white border-0 rounded-lg font-bold text-[13px] cursor-pointer hover:bg-blue-600 transition-colors"
                        >
                            🔄 Retry
                        </button>
                        <button
                            onClick={() => { window.location.href = '/portal/login'; }}
                            className="px-5 py-2.5 bg-transparent text-slate-400 border border-slate-600 rounded-lg font-bold text-[13px] cursor-pointer hover:bg-slate-700 hover:text-slate-300 transition-colors"
                        >
                            🔑 Back to Login
                        </button>
                        <button
                            onClick={() => { localStorage.clear(); sessionStorage.clear(); window.location.href = '/'; }}
                            className="px-5 py-2.5 bg-transparent text-slate-400 border border-slate-600 rounded-lg font-bold text-[13px] cursor-pointer hover:bg-slate-700 hover:text-slate-300 transition-colors"
                        >
                            🗑️ Hard Reset
                        </button>
                        <button
                            onClick={() => { navigator.clipboard.writeText(`${error.name}: ${error.message}\n\n${error.stack}`); alert('Copied!'); }}
                            className="px-5 py-2.5 bg-transparent text-slate-400 border border-slate-600 rounded-lg font-bold text-[13px] cursor-pointer hover:bg-slate-700 hover:text-slate-300 transition-colors"
                        >
                            📋 Copy
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
