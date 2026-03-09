import Link from 'next/link';
import Image from 'next/image';
import type { Metadata } from 'next';

export const metadata: Metadata = {
    title: 'About Us — Can Can',
    description: 'Learn about Can Can’s mission to simplify water delivery in Chennai.',
};

export default function AboutPage() {
    return (
        <div className="min-h-screen bg-[#fafafa] font-inter antialiased text-slate-900 overflow-x-hidden">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-[100] bg-white/70 backdrop-blur-2xl border-b border-slate-200/50">
                <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
                    <Link href="/" className="flex items-center gap-3 no-underline group">
                        <div className="relative w-10 h-10 transition-transform duration-500 group-hover:rotate-[360deg]">
                            <Image src="/cancan/cancan-logo.png" alt="Can Can" width={40} height={40} className="object-contain" priority />
                        </div>
                        <span className="text-2xl font-black tracking-[-0.05em] text-slate-900 font-inter">Can Can</span>
                    </Link>
                    <nav className="hidden md:flex items-center gap-10">
                        <Link href="/" className="no-underline text-slate-500 font-medium text-sm tracking-wide transition-colors hover:text-cancan-primary">
                            Home
                        </Link>
                        <a href="/#order" className="no-underline text-slate-500 font-medium text-sm tracking-wide transition-colors hover:text-cancan-primary">Demo</a>
                        <Link href="/portal/login" className="no-underline bg-slate-900 text-white px-6 py-2.5 rounded-full text-[13px] font-bold tracking-tight transition-all hover:bg-cancan-primary hover:shadow-lg">
                            Vendor Login
                        </Link>
                    </nav>
                </div>
            </header>

            {/* Content */}
            <main className="w-full px-6 pt-32 pb-32 max-w-7xl mx-auto relative">
                {/* Decorative Blob */}
                <div className="absolute top-0 right-0 w-96 h-96 bg-cancan-primary/5 rounded-full blur-[100px] pointer-events-none -z-10" />

                <div className="mb-20">
                    <h4 className="text-xs font-black uppercase tracking-[0.2em] text-cancan-primary mb-6">Our Story</h4>
                    <h1 className="text-5xl md:text-7xl font-black tracking-tight leading-[0.9] mb-8">
                        Pure water.<br />
                        <span className="bg-gradient-to-br from-cancan-primary to-cancan-primary-dark bg-clip-text text-transparent">Zero friction.</span>
                    </h1>
                    <p className="text-xl md:text-2xl text-slate-500 font-medium leading-relaxed max-w-3xl">
                        We're on a mission to bring digital elegance to one of India's most essential services.
                    </p>
                </div>

                <div className="prose prose-slate prose-lg max-w-none prose-headings:font-black prose-headings:tracking-tight prose-p:leading-relaxed prose-p:text-slate-600">
                    <section className="mb-20">
                        <h2 className="text-3xl font-black mb-8 border-b border-slate-100 pb-4">The Challenge</h2>
                        <p>
                            For decades, ordering water cans in Chennai has been a game of chance. Manual phone calls,
                            uncertain delivery windows, and a total lack of transparency for both the customer and the vendor.
                            It's a high-frequency, essential task that remained stuck in the past.
                        </p>
                    </section>

                    <div className="grid md:grid-cols-2 gap-12 mb-20">
                        <section className="p-10 bg-white rounded-[32px] border border-slate-100 shadow-sm relative group transition-all hover:shadow-xl hover:-translate-y-1">
                            <div className="w-12 h-12 bg-slate-50 rounded-2xl flex items-center justify-center shadow-sm mb-6 text-2xl">⚡</div>
                            <h3 className="text-xl font-bold mb-4">The Solution</h3>
                            <p className="text-sm leading-relaxed text-slate-500 font-medium">
                                Can Can provides a seamless, WhatsApp-first ordering platform. No new apps to download,
                                no complex passwords—just a simple message to get pure water delivered to your door.
                            </p>
                        </section>

                        <section className="p-10 bg-slate-900 rounded-[32px] shadow-sm text-white relative group transition-all hover:shadow-xl hover:-translate-y-1">
                            <div className="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center shadow-sm mb-6 text-2xl">🤝</div>
                            <h3 className="text-xl font-bold mb-4 text-white">Vendor First</h3>
                            <p className="text-sm leading-relaxed text-slate-400 font-medium">
                                We empower local water vendors with professional tools to manage logistics,
                                track payments, and scale their businesses with data-driven insights.
                            </p>
                        </section>
                    </div>

                    <section className="mb-20">
                        <h2 className="text-3xl font-black mb-8 border-b border-slate-100 pb-4">Our Technology</h2>
                        <p className="mb-6">
                            We believe the best technology is invisible. Our engine sits behind the simplicity of a WhatsApp
                            conversation, handling complex routing, demand prediction, and vendor assignment in real-time.
                        </p>
                        <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                            {[
                                { label: 'Cloud Logic', desc: 'Real-time routing' },
                                { label: 'Secure Pay', desc: 'Encrypted transactions' },
                                { label: 'Deep Tracking', desc: 'GPS-enabled delivery' }
                            ].map((item, i) => (
                                <div key={i} className="p-6 bg-white border border-slate-100 rounded-2xl text-center shadow-sm">
                                    <div className="text-xs font-black uppercase text-cancan-primary mb-1">{item.label}</div>
                                    <div className="text-[10px] text-slate-400 font-bold">{item.desc}</div>
                                </div>
                            ))}
                        </div>
                    </section>

                    <section className="mb-20 py-20 bg-white rounded-[40px] border border-slate-100 shadow-sm relative overflow-hidden text-center">
                        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-cancan-primary to-transparent" />
                        <h2 className="text-3xl font-black mb-6">Born in Chennai</h2>
                        <p className="max-w-2xl mx-auto px-6 italic text-slate-500">
                            "We built Can Can to solve our own problem. We wanted a way to get reliable drinking water without
                            making five phone calls a day. Today, we're proud to serve thousands of families across our city."
                        </p>
                    </section>

                    <div className="flex flex-col items-center justify-center gap-8 py-10">
                        <h3 className="text-2xl font-black">Want to join us?</h3>
                        <div className="flex gap-4">
                            <Link href="/portal/login" className="no-underline bg-slate-900 text-white px-10 py-5 rounded-full font-black text-lg shadow-xl hover:bg-cancan-primary transition-all">
                                Vendor Portal
                            </Link>
                            <Link href="/" className="no-underline bg-white text-slate-900 border border-slate-200 px-10 py-5 rounded-full font-bold text-lg hover:border-slate-400 transition-all shadow-sm">
                                Back to Home
                            </Link>
                        </div>
                    </div>
                </div>
            </main>

            {/* Footer */}
            <footer className="py-12 border-t border-slate-200 text-center bg-white">
                <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-6">
                    <p className="text-slate-400 text-sm font-medium">
                        © 2025 Can Can. All Rights Reserved.
                    </p>
                    <div className="flex gap-8">
                        <Link href="/privacy" className="text-sm font-bold text-slate-500 hover:text-cancan-primary no-underline transition-colors">Privacy</Link>
                        <Link href="/terms" className="text-sm font-bold text-slate-500 hover:text-cancan-primary no-underline transition-colors">Terms</Link>
                    </div>
                </div>
            </footer>
        </div>
    );
}
