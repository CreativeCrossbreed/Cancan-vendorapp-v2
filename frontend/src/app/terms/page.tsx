import Link from 'next/link';
import Image from 'next/image';
import type { Metadata } from 'next';

export const metadata: Metadata = {
    title: 'Terms & Conditions — Can Can',
    description: 'Can Can terms of service and conditions of use.',
};

export default function TermsPage() {
    return (
        <div className="min-h-screen bg-[#fafafa] font-inter antialiased text-slate-900">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-[100] bg-white/70 backdrop-blur-2xl border-b border-slate-200/50">
                <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
                    <Link href="/" className="flex items-center gap-3 no-underline group">
                        <div className="relative w-10 h-10 transition-transform duration-500 group-hover:rotate-[360deg]">
                            <Image src="/cancan/cancan-logo.png" alt="Can Can" width={40} height={40} className="object-contain" priority />
                        </div>
                        <span className="text-2xl font-black tracking-[-0.05em] text-slate-900">Can Can</span>
                    </Link>
                    <nav className="hidden md:flex items-center gap-10">
                        <Link href="/" className="no-underline text-slate-500 font-medium text-sm tracking-wide transition-colors hover:text-cancan-primary">
                            ← Back to Home
                        </Link>
                    </nav>
                </div>
            </header>

            {/* Content */}
            <main className="w-full px-6 pt-32 pb-32 max-w-7xl mx-auto">
                <div className="mb-12">
                    <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">Terms & Conditions</h1>
                    <p className="text-slate-500 font-medium">Effective Date: December 30, 2025</p>
                </div>

                <div className="prose prose-slate prose-lg max-w-none prose-headings:font-black prose-headings:tracking-tight prose-p:leading-relaxed prose-p:text-slate-600 prose-li:text-slate-600">
                    <p className="text-xl font-bold italic text-slate-500 mb-10">Welcome to Can Can.</p>

                    <p>
                        By accessing or using our website, mobile application, WhatsApp services, or any
                        related services (collectively, the “Platform”), you agree to be bound by these Terms &
                        Conditions (“Terms”). If you do not agree, please do not use the Platform.
                    </p>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">1. About Can Can</h2>
                        <p>
                            Can Can is a platform that connects customers with independent water can delivery
                            providers and helps manage water delivery schedules, order tracking, reminders, and
                            usage insights.
                        </p>
                        <div className="p-6 bg-amber-50 rounded-2xl border border-amber-100 text-amber-900 text-sm font-bold">
                            NOTE: Can Can does not own, supply, manufacture, or transport water cans.
                        </div>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">2. Eligibility</h2>
                        <p>
                            You must be at least 18 years old to use the Platform. By using Can Can, you confirm
                            that you meet this requirement and that the information you provide is accurate.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">3. User Accounts</h2>
                        <ul className="space-y-3">
                            <li>You are responsible for maintaining the confidentiality of your account credentials.</li>
                            <li>You agree to provide accurate and up-to-date information.</li>
                            <li>Can Can is not responsible for any unauthorized access resulting from your failure to safeguard your account.</li>
                        </ul>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">4. Services</h2>
                        <p>Can Can provides:</p>
                        <ul className="grid sm:grid-cols-2 gap-4 list-none p-0 mt-4">
                            <li className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm flex items-start gap-4">
                                <span className="text-cancan-primary font-black mt-1">✓</span>
                                <span>Order placement and delivery scheduling</span>
                            </li>
                            <li className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm flex items-start gap-4">
                                <span className="text-cancan-primary font-black mt-1">✓</span>
                                <span>Usage tracking and reminders</span>
                            </li>
                            <li className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm flex items-start gap-4">
                                <span className="text-cancan-primary font-black mt-1">✓</span>
                                <span>Communication facilitation</span>
                            </li>
                            <li className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm flex items-start gap-4">
                                <span className="text-cancan-primary font-black mt-1">✓</span>
                                <span>Rewards and incentives</span>
                            </li>
                        </ul>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">5. Vendor Responsibility</h2>
                        <p>Vendors listed on Can Can are independent service providers.</p>
                        <ul className="space-y-3 mt-4">
                            <li>Can Can does not guarantee water quality, delivery timelines, pricing accuracy, or vendor performance.</li>
                            <li>Any disputes regarding delivery, quality, or payment must be resolved directly between the customer and the vendor.</li>
                        </ul>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">6. Payments</h2>
                        <p>
                            Payments, if enabled, may be processed through third-party payment gateways.
                            Can Can does not store sensitive payment information.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">7. Acceptable Use</h2>
                        <p>You agree not to:</p>
                        <ul className="space-y-3 text-slate-600 mt-4">
                            <li className="flex gap-3"><span className="text-red-500">✕</span> Misuse the Platform for unlawful or fraudulent purposes</li>
                            <li className="flex gap-3"><span className="text-red-500">✕</span> Interfere with platform functionality</li>
                            <li className="flex gap-3"><span className="text-red-500">✕</span> Attempt to access data without authorization</li>
                            <li className="flex gap-3"><span className="text-red-500">✕</span> Harass, threaten, or abuse vendors or users</li>
                        </ul>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">8. Rewards & Points</h2>
                        <p>
                            Reward points have no cash value unless explicitly stated. Can Can reserves the right
                            to modify or discontinue reward programs at any time.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">9. Intellectual Property</h2>
                        <p>
                            All content, branding, logos, and platform design belong to Can Can.
                            You may not copy, reproduce, or distribute any content without written permission.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">10. Service Availability</h2>
                        <p>
                            Can Can strives for reliability but does not guarantee uninterrupted access.
                            Temporary downtime may occur due to maintenance or technical issues.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">11. Limitation of Liability</h2>
                        <p className="text-slate-500 italic border-l-4 border-slate-200 pl-6 py-2">
                            To the maximum extent permitted by law, Can Can shall not be liable for indirect,
                            incidental, or consequential damages. Can Can is not responsible for water quality,
                            health outcomes, or vendor negligence.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">12. Termination</h2>
                        <p>
                            Can Can reserves the right to suspend or terminate access to the Platform without
                            notice if these Terms are violated.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">13. Changes to Terms</h2>
                        <p>
                            These Terms may be updated periodically. Continued use of the Platform after
                            changes indicates acceptance of the revised Terms.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">14. Governing Law</h2>
                        <p>These Terms are governed by the laws of India.</p>
                    </section>

                    <section className="mt-12 p-10 bg-slate-900 rounded-[32px] text-white">
                        <h2 className="text-2xl font-black mb-4 text-white">15. Contact Information</h2>
                        <p className="text-slate-300 mb-6 font-medium">For questions or concerns, contact us at:</p>
                        <div className="flex items-center gap-2 text-xl font-black tracking-tight underline decoration-cancan-primary underline-offset-8 decoration-4">
                            📧 support@cancanindia.com
                        </div>
                    </section>
                </div>
            </main>

            {/* Footer */}
            <footer className="py-12 border-t border-slate-200 text-center">
                <p className="text-slate-400 text-sm font-medium">
                    © 2025 Can Can. All Rights Reserved.
                </p>
            </footer>
        </div>
    );
}
