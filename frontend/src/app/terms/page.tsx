import Link from 'next/link';
import Image from 'next/image';
import type { Metadata } from 'next';

export const metadata: Metadata = {
    title: 'Terms & Conditions — Can Can',
    description: 'Can Can terms of service and conditions of use.',
};

export default function TermsPage() {
    return (
        <div style={{ minHeight: '100vh', background: 'var(--cancan-bg)' }}>
            {/* Header */}
            <header
                style={{
                    background: 'rgba(250,248,240,0.88)',
                    backdropFilter: 'blur(16px)',
                    borderBottom: '1px solid rgba(15,23,42,0.06)',
                    position: 'sticky',
                    top: 0,
                    zIndex: 100,
                }}
            >
                <div style={{ maxWidth: 1140, margin: '0 auto', padding: '0 24px', height: 72, display: 'flex', alignItems: 'center', gap: 20 }}>
                    <Link href="/">
                        <Image src="/cancan/cancan-logo.png" alt="Can Can" width={120} height={44} style={{ display: 'block' }} priority />
                    </Link>
                    <nav style={{ marginLeft: 'auto' }}>
                        <Link href="/" style={{ color: 'var(--cancan-primary-dark)', fontWeight: 600, fontSize: '0.9rem' }}>← Back to Home</Link>
                    </nav>
                </div>
            </header>

            {/* Content */}
            <main style={{ maxWidth: 960, margin: '0 auto', padding: '48px 24px' }}>
                <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: 24, letterSpacing: '-0.02em' }}>Terms & Conditions</h1>
                <div style={{ marginBottom: 16 }}>
                    <a
                        href="/cancan/terms.pdf"
                        download
                        style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 8,
                            padding: '10px 20px',
                            background: 'var(--cancan-primary)',
                            color: '#fff',
                            borderRadius: 12,
                            fontWeight: 700,
                            fontSize: '0.9rem',
                        }}
                    >
                        📥 Download PDF
                    </a>
                </div>
                <object
                    data="/cancan/terms.pdf"
                    type="application/pdf"
                    width="100%"
                    height="720"
                    style={{ borderRadius: 12, border: '1px solid rgba(15,23,42,0.08)' }}
                >
                    <p style={{ color: 'var(--cancan-muted)' }}>
                        Your browser does not support inline PDFs.{' '}
                        <a href="/cancan/terms.pdf" download style={{ color: 'var(--cancan-primary-dark)' }}>
                            Click here to download
                        </a>.
                    </p>
                </object>
            </main>

            {/* Footer */}
            <footer style={{ padding: '24px 0', borderTop: '1px solid rgba(169,224,109,0.15)', textAlign: 'center' }}>
                <small style={{ color: 'var(--cancan-muted)', fontSize: '0.8rem' }}>
                    © 2025 Can Can. All Rights Reserved.
                </small>
            </footer>
        </div>
    );
}

