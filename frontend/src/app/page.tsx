'use client';

import { useRef, useState, Suspense } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import dynamic from 'next/dynamic';
import { motion, useScroll, useTransform, useInView } from 'framer-motion';
import WhatsAppSimulator from '@/components/landing/WhatsAppSimulator';
import VendorSimulation from '@/components/landing/VendorSimulation';



// Removed DeliveryScene in favor of luxury WaterVisual animations

const WA_LINK =
  'https://wa.me/919025320535?text=Hi%20Can%20Can%2C%20I%20want%20to%20order%20water%20cans';

/* ---- SVG Icons ---- */
function IconWhatsApp({ size = 24 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
      <path d="M17.472 14.382c-.297-.149-1.757-.866-2.03-.965-.273-.099-.472-.149-.672.15-.198.297-.768.965-.942 1.164-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.476-.884-.788-1.48-1.761-1.653-2.058-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.52.149-.173.198-.298.298-.497.099-.198.05-.372-.025-.52-.075-.149-.672-1.612-.92-2.214-.242-.579-.487-.5-.672-.51l-.573-.01c-.198 0-.52.074-.793.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.262.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.757-.718 2.006-1.411.248-.693.248-1.287.173-1.411-.074-.123-.272-.198-.57-.347z" />
      <path d="M20.52 3.48A11.94 11.94 0 0 0 12 0C5.373 0 .052 5.323.052 11.95c0 2.106.552 4.07 1.6 5.82L0 24l6.45-1.68a11.92 11.92 0 0 0 5.55 1.42c6.627 0 11.948-5.323 11.948-11.95 0-3.2-1.25-6.2-3.428-8.11z" />
    </svg>
  );
}

function IconTruck() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 3h15v13H1zM16 8h4l3 3v5h-7V8z" />
      <circle cx="5.5" cy="18.5" r="2.5" /><circle cx="18.5" cy="18.5" r="2.5" />
    </svg>
  );
}
function IconChat() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
    </svg>
  );
}
function IconShield() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}
function IconBell() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}
function IconBarChart() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="20" x2="12" y2="10" /><line x1="18" y1="20" x2="18" y2="4" /><line x1="6" y1="20" x2="6" y2="16" />
    </svg>
  );
}
function IconPackage() {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="16.5" y1="9.4" x2="7.5" y2="4.21" />
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
      <polyline points="3.27 6.96 12 12.01 20.73 6.96" /><line x1="12" y1="22.08" x2="12" y2="12" />
    </svg>
  );
}
function IconVolume() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
      <path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07" />
    </svg>
  );
}
function IconVolumeOff() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
      <line x1="23" y1="9" x2="17" y2="15" /><line x1="17" y1="9" x2="23" y2="15" />
    </svg>
  );
}

/* ---- Helpers ---- */
function Reveal({ children, delay = 0 }: { children: React.ReactNode; delay?: number }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.15 });
  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 50 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.7, delay, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}

function Counter({ value, suffix = '' }: { value: string; suffix?: string }) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.5 });
  return (
    <motion.span
      ref={ref}
      initial={{ opacity: 0, scale: 0.5 }}
      animate={isInView ? { opacity: 1, scale: 1 } : {}}
      transition={{ duration: 0.6 }}
      className="text-[2.2rem] font-black tracking-[-1px] bg-gradient-to-r from-cancan-primary to-cancan-secondary bg-clip-text text-transparent"
    >
      {value}{suffix}
    </motion.span>
  );
}

function WaterVisual() {
  return (
    <div className="relative w-full h-[500px] flex items-center justify-center">
      {/* Background Soft Glow */}
      <div className="absolute w-[600px] h-[600px] bg-cancan-primary/15 rounded-full blur-[120px] -z-10 animate-pulse" />

      <div className="relative w-full h-full">
        {/* Simple Falling Droplets distributed randomly */}
        {[...Array(6)].map((_, i) => (
          <Droplet key={i} delay={i * 1.5} xOffset={`${15 + i * 14}%`} />
        ))}
      </div>
    </div>
  );
}

function Droplet({ delay, xOffset }: { delay: number; xOffset: string }) {
  return (
    <div className="absolute top-0 w-full h-full" style={{ left: xOffset }}>
      {/* The Falling Drop */}
      <motion.div
        initial={{ y: -50, opacity: 0, scale: 0.5 }}
        animate={{
          y: [0, 450],
          opacity: [0, 1, 1, 0],
          scale: [0.6, 1, 1, 0.6],
        }}
        transition={{
          duration: 3,
          repeat: Infinity,
          delay: delay,
          ease: "easeIn",
        }}
        className="w-2.5 h-7 bg-gradient-to-b from-white via-cancan-primary to-cancan-primary-dark rounded-full shadow-[0_4px_10px_rgba(109,211,220,0.4)]"
      />

      {/* The Ripple at "Impact" */}
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{
          scale: [0, 3.5],
          opacity: [0, 0.6, 0],
        }}
        transition={{
          duration: 2,
          repeat: Infinity,
          delay: delay + 2.8, // Timed with end of fall
          ease: "easeOut",
        }}
        className="absolute top-[450px] -left-12 w-24 h-6 border-cancan-primary/20 rounded-[100%] shadow-[0_0_20px_rgba(109,211,220,0.2)]"
      />
    </div>
  );
}

/* ================================================================== */
/*  MAIN PAGE                                                          */
/* ================================================================== */
export default function LandingPage() {
  const [soundEnabled, setSoundEnabled] = useState(false);
  const heroRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: heroRef,
    offset: ['start start', 'end start'],
  });
  const heroY = useTransform(scrollYProgress, [0, 1], ['0%', '25%']);
  const heroOpacity = useTransform(scrollYProgress, [0, 0.7], [1, 0]);

  return (
    <div className="bg-cancan-bg text-cancan-text font-inter antialiased overflow-x-hidden min-h-screen">
      {/* Sound Toggle */}
      <button
        className="fixed top-5 right-6 z-[200] w-9 h-9 rounded-full bg-white/90 border border-black/10 backdrop-blur-md flex items-center justify-center cursor-pointer text-slate-500 transition-all hover:bg-white hover:text-cancan-primary hover:shadow-lg"
        onClick={() => setSoundEnabled(!soundEnabled)}
        title={soundEnabled ? 'Mute sounds' : 'Enable sounds'}
      >
        {soundEnabled ? <IconVolume /> : <IconVolumeOff />}
      </button>

      {/* ===== NAV ===== */}
      <header className="fixed top-0 left-0 right-0 z-[100] bg-white/70 backdrop-blur-2xl border-b border-slate-200/50">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3 no-underline group">
            <div className="relative w-10 h-10 transition-transform duration-500 group-hover:rotate-[360deg]">
              <Image src="/cancan/cancan-logo.png" alt="Can Can" width={40} height={40} className="object-contain" priority />
            </div>
            <span className="text-2xl font-black tracking-[-0.05em] text-slate-900">Can Can</span>
          </Link>
          <nav className="hidden md:flex items-center gap-10">
            <a href="#order" className="no-underline text-slate-500 font-medium text-sm tracking-wide transition-colors hover:text-cancan-primary">Demo</a>
            <a href="#vendors" className="no-underline text-slate-500 font-medium text-sm tracking-wide transition-colors hover:text-cancan-primary">Vendors</a>
            <a href="#how" className="no-underline text-slate-500 font-medium text-sm tracking-wide transition-colors hover:text-cancan-primary">How it works</a>
            <a href="#contact" className="no-underline text-slate-500 font-medium text-sm tracking-wide transition-colors hover:text-cancan-primary">Contact</a>
            <Link href="/portal/login" className="no-underline bg-slate-900 text-white px-7 py-3 rounded-full text-[13px] font-bold tracking-tight transition-all hover:bg-cancan-primary hover:shadow-[0_8px_20px_rgba(109,211,220,0.3)]">Vendor Login</Link>
          </nav>
        </div>
      </header>

      <main>
        {/* ===== HERO with 3D Delivery Scene ===== */}
        <section ref={heroRef} className="relative min-h-[95vh] flex items-center px-6 pt-32 pb-24 overflow-hidden bg-[radial-gradient(circle_at_50%_0%,rgba(109,211,220,0.12),transparent_50%),radial-gradient(circle_at_80%_80%,rgba(169,224,109,0.08),transparent_50%)]">
          <div className="max-w-7xl w-full mx-auto grid grid-cols-1 lg:grid-cols-2 gap-16 items-center relative z-[2]">
            <motion.div className="max-w-[600px]" style={{ y: heroY, opacity: heroOpacity }}>
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                className="inline-flex items-center gap-3 px-4 py-2 rounded-full bg-white/50 backdrop-blur-md border border-slate-200 mb-10 shadow-sm"
              >
                <span className="flex h-2 w-2 rounded-full bg-cancan-primary animate-pulse"></span>
                <span className="text-xs font-bold text-slate-600 uppercase tracking-widest">Premium Service in Chennai</span>
              </motion.div>
              <motion.h1 className="text-6xl md:text-8xl font-black leading-[0.95] tracking-[-0.04em] mb-8 text-slate-900" initial={{ opacity: 0, y: 50 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 1, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}>
                Pure water.<br /><span className="bg-gradient-to-br from-cancan-primary via-cancan-primary-dark to-slate-900 bg-clip-text text-transparent">Zero effort.</span>
              </motion.h1>
              <motion.p className="text-xl text-slate-500 leading-relaxed mb-12 font-medium" initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.9, delay: 0.25 }}>
                The ultimate convenience for your lifestyle. High-quality drinking water delivered to your doorstep with a single WhatsApp tap.
              </motion.p>
              <motion.div className="flex flex-col sm:flex-row gap-5" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8, delay: 0.4 }}>
                <a href={WA_LINK} className="group relative inline-flex items-center justify-center gap-3 px-10 py-5 bg-slate-900 text-white rounded-full no-underline font-black text-lg transition-all hover:bg-cancan-primary hover:shadow-[0_20px_40px_rgba(109,211,220,0.4)]">
                  <IconWhatsApp size={24} />
                  Order Now
                  <span className="absolute inset-0 rounded-full border border-white/10 group-hover:scale-105 transition-transform"></span>
                </a>
                <a href="#order" className="inline-flex items-center justify-center px-10 py-5 bg-white text-slate-900 border-2 border-slate-200 rounded-full no-underline font-bold text-lg transition-all hover:border-slate-900 hover:bg-slate-50">View Demo</a>
              </motion.div>
            </motion.div>

            <motion.div
              className="relative w-full h-[600px] flex items-center justify-center lg:justify-end"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 1.5, ease: 'easeOut', delay: 0.2 }}
            >
              <WaterVisual />
            </motion.div>
          </div>
        </section>

        {/* ===== INTERACTIVE WHATSAPP DEMO ===== */}
        <section id="order" className="py-32 px-6 bg-white border-y border-slate-100">
          <div className="max-w-7xl mx-auto">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-24 items-center">
              <Reveal>
                <div className="lg:pr-10">
                  <span className="inline-block text-[13px] font-bold tracking-[0.2em] uppercase text-cancan-primary mb-6">Simulation</span>
                  <h2 className="text-5xl md:text-6xl font-black tracking-tight mb-8 leading-tight text-slate-900">Experience the flow.</h2>
                  <p className="text-xl text-slate-500 leading-relaxed mb-10">
                    See how luxury seamlessly integrates with daily life. No downloads,
                    no accounts—just the world&apos;s most intuitive ordering system active in your WhatsApp.
                  </p>
                  <ul className="space-y-8 mb-12">
                    <li className="flex gap-6 items-start">
                      <div className="shrink-0 w-12 h-12 rounded-2xl bg-cancan-primary/10 text-cancan-primary flex items-center justify-center"><IconBell /></div>
                      <div><strong className="block text-lg font-bold text-slate-900 mb-1">Intelligent Alerts</strong><span className="text-slate-500">Real-time concierge updates on your delivery status.</span></div>
                    </li>
                    <li className="flex gap-6 items-start">
                      <div className="shrink-0 w-12 h-12 rounded-2xl bg-cancan-primary/10 text-cancan-primary flex items-center justify-center"><IconChat /></div>
                      <div><strong className="block text-lg font-bold text-slate-900 mb-1">Predictive Ordering</strong><span className="text-slate-500">One tap to repeat your history. Minimum friction.</span></div>
                    </li>
                  </ul>
                  <a href={WA_LINK} className="inline-flex items-center gap-3 px-8 py-4 bg-slate-900 text-white rounded-full no-underline font-bold text-lg transition-all hover:bg-cancan-primary hover:shadow-2xl">
                    <IconWhatsApp size={22} /> Start Chat
                  </a>
                </div>
              </Reveal>
              <Reveal delay={0.15}>
                <div className="relative group">
                  <div className="absolute -inset-4 bg-gradient-to-tr from-cancan-primary/20 to-cancan-secondary/20 rounded-[4rem] blur-3xl group-hover:scale-110 transition-transform duration-1000"></div>
                  <div className="relative flex justify-center bg-white p-4 rounded-[3.5rem] shadow-2xl border border-slate-100">
                    <WhatsAppSimulator soundEnabled={soundEnabled} />
                  </div>
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        {/* ===== VENDOR SHOWCASE (Dark & Luxurious) ===== */}
        <section id="vendors" className="py-32 px-6 bg-slate-900 text-white relative overflow-hidden">
          <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent"></div>
          <div className="max-w-7xl mx-auto relative z-10">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-24 items-center">
              <Reveal>
                <div className="lg:pr-10">
                  <span className="inline-block text-[13px] font-bold tracking-[0.2em] uppercase text-cancan-secondary mb-6">Exclusive Dashboard</span>
                  <h2 className="text-5xl md:text-6xl font-black tracking-tight mb-8 leading-tight">Master your supply chain.</h2>
                  <p className="text-xl text-slate-400 leading-relaxed mb-10">
                    Precision management for modern vendors. Real-time logistics,
                    automated revenue splits, and effortless scaling at your fingertips.
                  </p>
                  <div className="space-y-6 mb-12">
                    {[
                      { icon: <IconBell />, title: 'Real-time Orchestration', desc: 'Orders flow from WhatsApp to your fleet instantly.' },
                      { icon: <IconBarChart />, title: 'Financial Intelligence', desc: 'Predictive analytics to maximize your daily collections.' },
                    ].map((f, i) => (
                      <Reveal key={f.title} delay={i * 0.1}>
                        <div className="flex gap-6 items-start group">
                          <div className="shrink-0 w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center transition-colors group-hover:bg-cancan-secondary/20 group-hover:text-cancan-secondary">
                            {f.icon}
                          </div>
                          <div>
                            <strong className="block text-lg font-bold mb-1 text-slate-100">{f.title}</strong>
                            <span className="text-slate-400">{f.desc}</span>
                          </div>
                        </div>
                      </Reveal>
                    ))}
                  </div>
                  <Link href="/portal/login" className="inline-flex items-center gap-3 px-10 py-5 bg-white text-slate-900 rounded-full no-underline font-black text-lg transition-all hover:scale-105 active:scale-95 shadow-xl">
                    Open Portal
                  </Link>
                </div>
              </Reveal>
              <Reveal delay={0.2}>
                <div className="relative p-6 bg-white/5 rounded-[3rem] border border-white/10 shadow-3xl">
                  <VendorSimulation soundEnabled={soundEnabled} />
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        {/* ===== SOCIAL PROOF (Luxury Bar) ===== */}
        <section className="py-24 px-6 bg-slate-50 relative overflow-hidden">
          <div className="max-w-7xl mx-auto border-y border-slate-200 py-16">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-12 text-center">
              {[
                { val: '500', suf: '+', lab: 'Active Customers' },
                { val: '50', suf: '+', lab: 'Verified Vendors' },
                { val: '10', suf: 'k+', lab: 'Orders Delivered' },
                { val: '4.9', suf: '/5', lab: 'Satisfaction Rate' },
              ].map((stat, i) => (
                <div key={stat.lab} className="flex flex-col gap-3">
                  <Counter value={stat.val} suffix={stat.suf} />
                  <span className="text-sm font-bold uppercase tracking-[0.2em] text-slate-400">{stat.lab}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ===== HOW IT WORKS (Modern Stacked) ===== */}
        <section id="how" className="py-32 px-6 bg-white overflow-hidden">
          <div className="max-w-7xl mx-auto">
            <Reveal>
              <div className="text-center mb-24 max-w-3xl mx-auto">
                <span className="inline-block text-[13px] font-bold tracking-[0.2em] uppercase text-cancan-primary mb-6">Process</span>
                <h2 className="text-5xl md:text-7xl font-black text-slate-900 mb-8 tracking-tighter">Effortless as a morning breeze.</h2>
                <p className="text-xl text-slate-500 font-medium">Ordering water used to be a chore. With Can Can, it&apos;s a curated experience designed for the modern home.</p>
              </div>
            </Reveal>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-16 relative">
              <div className="hidden md:block absolute top-[100px] inset-x-0 h-px bg-gradient-to-r from-transparent via-slate-200 to-transparent"></div>
              {[
                { step: '01', title: 'Start Chat', desc: 'Scan our QR or click a link to launch your personal water concierge.', icon: <IconWhatsApp size={32} /> },
                { step: '02', title: 'Pick & Pay', desc: 'Browse verified brands. One tap to pay via your favorite app.', icon: <IconPackage /> },
                { step: '03', title: 'Arrival', desc: 'Real-time delivery orchestrated by our intelligent vendor network.', icon: <IconTruck /> },
              ].map((item, i) => (
                <Reveal key={item.step} delay={i * 0.15}>
                  <div className="relative group p-10 rounded-[3rem] transition-all hover:bg-slate-50 hover:shadow-luxury">
                    <div className="w-20 h-20 rounded-3xl bg-slate-900 text-white flex items-center justify-center mb-8 relative z-10 shadow-xl group-hover:scale-110 transition-transform">
                      {item.icon}
                    </div>
                    <span className="block text-cancan-primary font-black text-2xl mb-4 tabular-nums opacity-40">{item.step}</span>
                    <h3 className="text-2xl font-black mb-4 text-slate-900">{item.title}</h3>
                    <p className="text-slate-500 leading-relaxed text-lg">{item.desc}</p>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        {/* ===== FINAL CTA (Luxury) ===== */}
        <section id="contact" className="py-32 px-6 bg-slate-900 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-cancan-primary/5 rounded-full blur-[120px] -mr-64 -mt-64"></div>
          <div className="max-w-7xl mx-auto">
            <div className="glass-card bg-white/5 border-white/5 p-12 md:p-24 rounded-[4rem] text-center relative z-10">
              <Reveal>
                <div className="max-w-3xl mx-auto">
                  <h2 className="text-5xl md:text-7xl font-black text-white mb-8 tracking-tighter">Ready for the upgrade?</h2>
                  <p className="text-xl text-slate-400 mb-12 font-medium">Join thousands of households in Chennai experiencing the future of water delivery.</p>
                  <div className="flex flex-col sm:flex-row gap-6 justify-center">
                    <a href={WA_LINK} className="px-12 py-6 bg-white text-slate-900 rounded-full font-black text-xl transition-all hover:scale-105 active:scale-95 shadow-[0_20px_40px_rgba(255,255,255,0.1)]">
                      Order Your First Can
                    </a>
                    <a href="mailto:hello@cancan.in" className="px-12 py-6 bg-transparent border-2 border-white/20 text-white rounded-full font-bold text-xl transition-all hover:bg-white/5">
                      Partner with us
                    </a>
                  </div>
                </div>
              </Reveal>
            </div>
          </div>
        </section>
      </main>

      <footer className="py-32 px-6 bg-white border-t border-slate-100">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-20 mb-20">
            <div className="col-span-1 md:col-span-1">
              <div className="flex items-center gap-3 mb-8">
                <Image src="/cancan/cancan-logo.png" alt="Can Can" width={32} height={32} />
                <span className="text-xl font-black tracking-tight">Can Can</span>
              </div>
              <p className="text-slate-500 leading-relaxed font-medium">Drinking water delivery, reimagined for the modern world. Direct, daily, and delightful.</p>
            </div>
            <div>
              <h4 className="font-black text-slate-900 mb-8 uppercase text-xs tracking-widest">Product</h4>
              <ul className="space-y-4 text-slate-500 font-medium">
                <li><a href="#order" className="hover:text-cancan-primary transition-colors">Order Now</a></li>
                <li><a href="#vendors" className="hover:text-cancan-primary transition-colors">Vendor Portal</a></li>
                <li><a href="#how" className="hover:text-cancan-primary transition-colors">How it works</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-black text-slate-900 mb-8 uppercase text-xs tracking-widest">Company</h4>
              <ul className="space-y-4 text-slate-500 font-medium">
                <li><Link href="/about" className="hover:text-cancan-primary transition-colors">About Us</Link></li>
                <li><Link href="/privacy" className="hover:text-cancan-primary transition-colors">Privacy Policy</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="font-black text-slate-900 mb-8 uppercase text-xs tracking-widest">Social</h4>
              <div className="flex gap-4">
                <a href="#" className="w-12 h-12 rounded-2xl bg-slate-50 flex items-center justify-center text-slate-400 hover:bg-cancan-primary/10 hover:text-cancan-primary transition-all"><IconWhatsApp /></a>
              </div>
            </div>
          </div>
          <div className="pt-12 border-t border-slate-100 flex flex-col md:flex-row justify-between items-center gap-6">
            <p className="text-slate-400 text-sm font-medium">&copy; {new Date().getFullYear()} Can Can Technologies. Built for Chennai.</p>
            <div className="flex gap-8 text-sm font-bold text-slate-400 uppercase tracking-widest">
              <span>ISO 9001:2015</span>
              <span>Verified Brands</span>
            </div>
          </div>
        </div>
      </footer>

      {/* WhatsApp FAB */}
      <a className="fixed right-6 bottom-6 w-14 h-14 rounded-full bg-[#25D366] text-white flex items-center justify-center z-[1000] no-underline shadow-[0_6px_24px_rgba(37,211,102,0.4)] transition-all hover:scale-[1.08] hover:-translate-y-0.5 hover:shadow-[0_10px_32px_rgba(37,211,102,0.55)]" href={WA_LINK} target="_blank" rel="noopener noreferrer" aria-label="Order on WhatsApp">
        <IconWhatsApp size={28} />
      </a>
    </div>
  );
}
