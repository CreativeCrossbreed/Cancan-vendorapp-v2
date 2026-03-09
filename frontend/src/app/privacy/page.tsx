import Link from 'next/link';
import Image from 'next/image';
import type { Metadata } from 'next';

export const metadata: Metadata = {
    title: 'Privacy Policy — Can Can',
    description: 'Can Can privacy policy and data handling practices.',
};

export default function PrivacyPage() {
    return (
        <div className="min-h-screen bg-[#fafafa] font-inter antialiased text-slate-900">
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
                            ← Back to Home
                        </Link>
                    </nav>
                </div>
            </header>

            {/* Content */}
            <main className="w-full px-6 pt-32 pb-32 max-w-7xl mx-auto">
                <div className="mb-12">
                    <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">Privacy Policy</h1>
                    <p className="text-slate-500 font-medium">Effective Date: December, 2025</p>
                </div>

                <div className="prose prose-slate prose-lg max-w-none prose-headings:font-black prose-headings:tracking-tight prose-p:leading-relaxed prose-p:text-slate-600 prose-li:text-slate-600">
                    <p>
                        Can Can (“we”, “our”, “us”) respects your privacy and is committed to protecting the
                        personal information of our users. This Privacy Policy explains how we collect, use,
                        and safeguard information when you interact with our services.
                    </p>

                    <section className="mt-10">
                        <h2 className="text-2xl font-black mb-6">1. Information We Collect</h2>
                        <p>We may collect the following information:</p>

                        <div className="grid md:grid-cols-2 gap-8 mt-6">
                            <div className="p-8 bg-white rounded-3xl border border-slate-100 shadow-sm">
                                <h3 className="text-lg font-bold mb-4 text-cancan-primary-dark">From Customers (WhatsApp users):</h3>
                                <ul className="space-y-2 list-none p-0 m-0 text-sm">
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Name
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Mobile number
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Delivery address
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Order details
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Communication messages via WhatsApp
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Vendor-related operational data
                                    </li>
                                </ul>
                            </div>

                            <div className="p-8 bg-white rounded-3xl border border-slate-100 shadow-sm">
                                <h3 className="text-lg font-bold mb-4 text-cancan-primary-dark">From Vendors (Mobile app):</h3>
                                <ul className="space-y-2 list-none p-0 m-0 text-sm">
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Name
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Mobile number
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Business Address
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="text-cancan-primary">●</span> Delivery & Payment History
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">2. How We Use Your Information</h2>
                        <ul className="space-y-3">
                            <li>Process and fulfill water delivery orders</li>
                            <li>Communicate order updates via WhatsApp</li>
                            <li>Assign and manage deliveries with vendors</li>
                            <li>Improve our services and operational efficiency</li>
                            <li>Respond to customer support requests</li>
                        </ul>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">3. WhatsApp Communication</h2>
                        <p>
                            Customers may contact Can Can via WhatsApp to place orders or receive updates. By
                            initiating communication, you consent to receive transactional and service-related
                            messages from us on WhatsApp. We do not send unsolicited promotional messages
                            without user consent.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">4. Information Sharing</h2>
                        <p>
                            We do not sell or rent your personal information. Information may be shared only
                            with:
                        </p>
                        <ul className="space-y-3 mt-4 text-slate-600">
                            <li className="flex gap-3"><span className="text-cancan-primary">●</span> Delivery vendors for order fulfillment</li>
                            <li className="flex gap-3"><span className="text-cancan-primary">●</span> Service providers involved in operating our platform</li>
                            <li className="flex gap-3"><span className="text-cancan-primary">●</span> Legal authorities if required by law</li>
                        </ul>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">5. Data Security</h2>
                        <p>
                            We take reasonable measures to protect personal information against unauthorized
                            access, misuse, or disclosure.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">6. Data Retention</h2>
                        <p>
                            We retain personal data only for as long as necessary to fulfill the purposes outlined
                            in this policy or as required by law.
                        </p>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">7. Your Rights</h2>
                        <p>
                            You may request access, correction, or deletion of your personal data by contacting
                            us using the details below.
                        </p>
                    </section>

                    <section className="mt-12 p-10 bg-slate-900 rounded-[32px] text-white">
                        <h2 className="text-2xl font-black mb-6 text-white">8. Contact Information</h2>
                        <p className="text-slate-300 mb-6">For any privacy-related concerns, please contact us at:</p>
                        <div className="grid sm:grid-cols-2 gap-8">
                            <div>
                                <h4 className="text-xs font-black uppercase tracking-widest text-cancan-primary mb-3">Phone</h4>
                                <p className="font-bold">+91- 90253 20535</p>
                                <p className="font-bold">+91- 900801 26534</p>
                            </div>
                            <div>
                                <h4 className="text-xs font-black uppercase tracking-widest text-cancan-primary mb-3">Email</h4>
                                <p className="font-bold underline decoration-cancan-primary underline-offset-4">admin@cancanindia.com</p>
                                <p className="font-bold underline decoration-cancan-primary underline-offset-4">support@cancanindia.com</p>
                            </div>
                        </div>
                    </section>

                    <section className="mt-12">
                        <h2 className="text-2xl font-black mb-6">9. Changes to This Policy</h2>
                        <p>
                            We may update this Privacy Policy from time to time. Any changes will be posted on
                            this page.
                        </p>
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
