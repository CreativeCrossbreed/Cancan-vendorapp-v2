'use client';

export default function GlobalError({
    error,
    reset,
}: {
    error: Error & { digest?: string };
    reset: () => void;
}) {
    const isFetchError = error.message?.toLowerCase().includes('fetch failed');
    const isSupabaseError = error.message?.toLowerCase().includes('supabase') || error.message?.toLowerCase().includes('postgrest');

    return (
        <html lang="en">
            <body
                style={{
                    margin: 0,
                    minHeight: '100vh',
                    backgroundColor: '#0f172a',
                    color: '#f8fafc',
                    fontFamily: '"SF Mono", "Fira Code", "Cascadia Code", Consolas, monospace',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    padding: '24px',
                }}
            >
                <div
                    style={{
                        maxWidth: 720,
                        width: '100%',
                        border: '1px solid #334155',
                        borderRadius: 16,
                        overflow: 'hidden',
                        boxShadow: '0 25px 50px rgba(0,0,0,0.5)',
                    }}
                >
                    {/* Red header bar */}
                    <div
                        style={{
                            background: 'linear-gradient(135deg, #dc2626, #991b1b)',
                            padding: '20px 24px',
                            display: 'flex',
                            alignItems: 'center',
                            gap: 12,
                        }}
                    >
                        <span style={{ fontSize: 32 }}>⚠️</span>
                        <div>
                            <h1 style={{ margin: 0, fontSize: 20, fontWeight: 800, letterSpacing: 1 }}>
                                CRITICAL SYSTEM FAILURE
                            </h1>
                            <p style={{ margin: '4px 0 0', fontSize: 13, color: '#fca5a5' }}>
                                The application crashed at the root level. Full diagnostic below.
                            </p>
                        </div>
                    </div>

                    <div style={{ padding: 24 }}>
                        {/* Error message */}
                        <div
                            style={{
                                background: '#1e293b',
                                borderLeft: '4px solid #ef4444',
                                padding: 16,
                                borderRadius: 8,
                                marginBottom: 20,
                                wordBreak: 'break-all',
                            }}
                        >
                            <p style={{ margin: 0, fontSize: 11, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>
                                Exception
                            </p>
                            <p style={{ margin: 0, fontSize: 16, color: '#f87171', fontWeight: 600 }}>
                                {error.name}: {error.message}
                            </p>
                            {error.digest && (
                                <p style={{ margin: '8px 0 0', fontSize: 12, color: '#64748b' }}>
                                    Digest: {error.digest}
                                </p>
                            )}
                        </div>

                        {/* Diagnostic hints */}
                        {isFetchError && (
                            <div style={{ background: '#422006', border: '1px solid #ca8a04', borderRadius: 8, padding: 16, marginBottom: 20 }}>
                                <p style={{ margin: 0, fontWeight: 800, fontSize: 14, color: '#fef08a', marginBottom: 6 }}>
                                    💡 Diagnostic: Network / Fetch Failure
                                </p>
                                <p style={{ margin: 0, fontSize: 13, color: '#fde68a' }}>
                                    The app tried to call an API endpoint but the request failed entirely. Common causes:
                                    <br />• The Supabase URL in your <code>.env.local</code> is incorrect or missing
                                    <br />• The backend API server is down or unreachable
                                    <br />• CORS is blocking the request (check browser Network tab)
                                    <br />• DNS resolution failed for the API domain
                                </p>
                            </div>
                        )}

                        {isSupabaseError && (
                            <div style={{ background: '#042f2e', border: '1px solid #14b8a6', borderRadius: 8, padding: 16, marginBottom: 20 }}>
                                <p style={{ margin: 0, fontWeight: 800, fontSize: 14, color: '#5eead4', marginBottom: 6 }}>
                                    💡 Diagnostic: Supabase Configuration Error
                                </p>
                                <p style={{ margin: 0, fontSize: 13, color: '#99f6e4' }}>
                                    This error originates from the Supabase client. Verify these environment variables:
                                    <br />• <code>NEXT_PUBLIC_SUPABASE_URL</code> — Must be a valid URL like <code>https://xyz.supabase.co</code>
                                    <br />• <code>SUPABASE_ANON_KEY</code> — Anon key from Supabase dashboard (server env only; do not use <code>NEXT_PUBLIC_</code>)
                                    <br />• <code>SUPABASE_SERVICE_ROLE_KEY</code> — Required for admin API routes
                                </p>
                            </div>
                        )}

                        {/* Stack trace */}
                        <div style={{ marginBottom: 20 }}>
                            <p style={{ margin: '0 0 8px', fontSize: 11, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 1 }}>
                                Stack Trace
                            </p>
                            <pre
                                style={{
                                    background: '#0f172a',
                                    border: '1px solid #334155',
                                    borderRadius: 8,
                                    padding: 16,
                                    margin: 0,
                                    fontSize: 11,
                                    color: '#94a3b8',
                                    whiteSpace: 'pre-wrap',
                                    wordBreak: 'break-all',
                                    maxHeight: 200,
                                    overflow: 'auto',
                                    lineHeight: 1.6,
                                }}
                            >
                                {error.stack || 'No stack trace available.'}
                            </pre>
                        </div>

                        {/* Actions */}
                        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                            <button
                                onClick={reset}
                                style={{
                                    padding: '12px 24px',
                                    background: '#3b82f6',
                                    color: '#fff',
                                    border: 'none',
                                    borderRadius: 8,
                                    fontWeight: 700,
                                    fontSize: 14,
                                    cursor: 'pointer',
                                }}
                            >
                                🔄 Try Again
                            </button>
                            <button
                                onClick={() => {
                                    localStorage.clear();
                                    sessionStorage.clear();
                                    window.location.href = '/';
                                }}
                                style={{
                                    padding: '12px 24px',
                                    background: 'transparent',
                                    color: '#94a3b8',
                                    border: '1px solid #475569',
                                    borderRadius: 8,
                                    fontWeight: 700,
                                    fontSize: 14,
                                    cursor: 'pointer',
                                }}
                            >
                                🗑️ Hard Reset
                            </button>
                            <button
                                onClick={() => {
                                    const text = `${error.name}: ${error.message}\n\nStack:\n${error.stack}`;
                                    navigator.clipboard.writeText(text);
                                    alert('Error copied!');
                                }}
                                style={{
                                    padding: '12px 24px',
                                    background: 'transparent',
                                    color: '#94a3b8',
                                    border: '1px solid #475569',
                                    borderRadius: 8,
                                    fontWeight: 700,
                                    fontSize: 14,
                                    cursor: 'pointer',
                                }}
                            >
                                📋 Copy Error
                            </button>
                        </div>
                    </div>
                </div>
            </body>
        </html>
    );
}
