'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import s from './landing.module.css';

const WA_LINK =
  'https://wa.me/919025320535?text=Hi%20Can%20Can%20Team%2C%20I%20want%20to%20order%20water%20cans';

function WhatsAppIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M20.52 3.48A11.94 11.94 0 0 0 12 0C5.373 0 .052 5.323.052 11.95c0 2.106.552 4.07 1.6 5.82L0 24l6.45-1.68a11.92 11.92 0 0 0 5.55 1.42c6.627 0 11.948-5.323 11.948-11.95 0-3.2-1.25-6.2-3.428-8.11z"
        fill="currentColor"
      />
      <path
        d="M17.472 14.382c-.297-.149-1.757-.866-2.03-.965-.273-.099-.472-.149-.672.15-.198.297-.768.965-.942 1.164-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.476-.884-.788-1.48-1.761-1.653-2.058-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.52.149-.173.198-.298.298-.497.099-.198.05-.372-.025-.52-.075-.149-.672-1.612-.92-2.214-.242-.579-.487-.5-.672-.51l-.573-.01c-.198 0-.52.074-.793.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.262.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.757-.718 2.006-1.411.248-.693.248-1.287.173-1.411-.074-.123-.272-.198-.57-.347z"
        fill="#ffffff"
      />
    </svg>
  );
}

export default function LandingPage() {
  const [mobileOpen, setMobileOpen] = useState(false);

  const toggleMobile = useCallback(() => {
    setMobileOpen((prev) => {
      document.documentElement.style.overflow = prev ? '' : 'hidden';
      return !prev;
    });
  }, []);

  const closeMobile = useCallback(() => {
    setMobileOpen(false);
    document.documentElement.style.overflow = '';
  }, []);

  return (
    <div className={s.page}>
      {/* ===== HEADER ===== */}
      <header className={s.header}>
        <div className={s.headerInner}>
          <Image
            src="/cancan/cancan-logo.png"
            alt="Can Can"
            width={120}
            height={44}
            className={s.logo}
            priority
          />

          <nav className={s.nav}>
            <a href="#how" className={s.navLink}>How it works</a>
            <a href="#vendors" className={s.navLink}>For Vendors</a>
            <a href="#contact" className={s.navLink}>Contact</a>
          </nav>

          <div className={s.headerActions}>
            <a href={WA_LINK} className={s.orderBtn}>
              Order Now
            </a>
            <button
              className={s.menuBtn}
              onClick={toggleMobile}
              aria-label="Toggle menu"
              aria-expanded={mobileOpen}
            >
              <span className={s.hamburger} />
            </button>
          </div>
        </div>

        {mobileOpen && (
          <div className={s.mobileNav}>
            <a href="#how" className={s.mobileLink} onClick={closeMobile}>How it works</a>
            <a href="#vendors" className={s.mobileLink} onClick={closeMobile}>For Vendors</a>
            <a href="#contact" className={s.mobileLink} onClick={closeMobile}>Contact</a>
            <Link href="/privacy" className={s.mobileLink} onClick={closeMobile}>Privacy Policy</Link>
            <Link href="/terms" className={s.mobileLink} onClick={closeMobile}>Terms & Conditions</Link>
            <a href={WA_LINK} className={s.mobileCta} onClick={closeMobile}>
              Order on WhatsApp
            </a>
          </div>
        )}
      </header>

      <main>
        {/* ===== HERO ===== */}
        <section className={s.hero}>
          <div className={s.heroInner}>
            <div>
              <div className={s.heroTag}>
                <span className={s.heroTagDot} />
                Now delivering across India
              </div>
              <h1 className={s.heroTitle}>
                Water can delivery,{' '}
                <span className={s.heroTitleHighlight}>simplified.</span>
              </h1>
              <p className={s.heroDesc}>
                Order purified drinking water cans via WhatsApp. Vendors receive
                orders on their app. Admins manage assignments and track
                deliveries — all in one seamless platform.
              </p>
              <div className={s.heroActions}>
                <a href={WA_LINK} className={s.btnPrimary}>
                  <WhatsAppIcon /> Order on WhatsApp
                </a>
                <a href="#how" className={s.btnOutline}>
                  Learn how it works →
                </a>
              </div>
            </div>

            <div className={s.heroVisual}>
              <div className={s.phoneMock}>
                <div className={s.phoneContent}>
                  <span className={s.phoneEmoji}>💧</span>
                  WhatsApp ordering<br />with quick-tap buttons
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ===== HOW IT WORKS ===== */}
        <section id="how" className={s.how}>
          <div className={s.container}>
            <div className={s.sectionHead}>
              <h2 className={s.sectionTitle}>How it works</h2>
              <p className={s.sectionDesc}>
                Simple WhatsApp ordering for customers — routed to nearby vendors
                for fast delivery.
              </p>
            </div>
            <div className={s.steps}>
              <div className={s.step}>
                <div className={s.stepNumber}>1</div>
                <h3 className={s.stepTitle}>Choose & Confirm</h3>
                <p className={s.stepDesc}>
                  Customers select brand, quantity, delivery date and timeslot
                  using interactive WhatsApp menus.
                </p>
              </div>
              <div className={s.step}>
                <div className={s.stepNumber}>2</div>
                <h3 className={s.stepTitle}>Routed Automatically</h3>
                <p className={s.stepDesc}>
                  Orders reach the admin portal and are assigned to the nearest
                  local vendor instantly.
                </p>
              </div>
              <div className={s.step}>
                <div className={s.stepNumber}>3</div>
                <h3 className={s.stepTitle}>Delivered & Paid</h3>
                <p className={s.stepDesc}>
                  The vendor delivers the cans and updates delivery & payment
                  status from the vendor app.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ===== VENDORS ===== */}
        <section id="vendors" className={s.vendors}>
          <div className={s.container}>
            <div className={s.sectionHead}>
              <h2 className={s.sectionTitle}>For Vendors</h2>
              <p className={s.sectionDesc}>
                A lightweight vendor app to manage orders, inventory and payments
                — built for quick daily operations.
              </p>
            </div>
            <div className={s.featureGrid}>
              {[
                { icon: '📋', title: 'Order management', desc: 'Accept, schedule and update deliveries in one place.' },
                { icon: '🚚', title: 'Delivery history', desc: 'Track completed deliveries and customer feedback.' },
                { icon: '💳', title: 'Payments', desc: 'Record cash or online payments and receipts.' },
                { icon: '📦', title: 'Inventory', desc: 'Monitor stock and get low-inventory alerts.' },
                { icon: '👥', title: 'Customers', desc: 'Access customer addresses and order records.' },
                { icon: '🗺️', title: 'Route & timeslots', desc: 'Organize delivery routes and manage timeslot availability.' },
              ].map((f) => (
                <div key={f.title} className={s.feature}>
                  <span className={s.featureIcon}>{f.icon}</span>
                  <h4 className={s.featureTitle}>{f.title}</h4>
                  <p className={s.featureDesc}>{f.desc}</p>
                </div>
              ))}
            </div>
            <div className={s.vendorCta}>
              <a href="#contact" className={s.btnPrimary}>
                Become a Vendor
              </a>
            </div>
          </div>
        </section>

        {/* ===== CONTACT ===== */}
        <section id="contact" className={s.contact}>
          <div className={s.container}>
            <div className={s.contactInner}>
              <div className={s.contactInfo}>
                <h3 className={s.contactTitle}>Contact Us</h3>
                <p>Email: <a href="mailto:admin@cancanindia.com">admin@cancanindia.com</a></p>
                <p>Email: <a href="mailto:support@cancanindia.com">support@cancanindia.com</a></p>
                <p>Phone: <a href="tel:+919025320535">+91 90253 20535</a></p>
              </div>
              <div>
                <h3 className={s.contactTitle}>Quick order</h3>
                <p style={{ color: 'var(--cancan-muted)', marginBottom: 14 }}>
                  Start an order on WhatsApp:
                </p>
                <a href={WA_LINK} className={s.btnPrimary}>
                  <WhatsAppIcon /> Message us on WhatsApp
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* ===== FOOTER ===== */}
      <footer className={s.footer}>
        <div className={`${s.container} ${s.footerInner}`}>
          <div className={s.footerLinks}>
            <Link href="/privacy">Privacy Policy</Link>
            <Link href="/terms">Terms & Conditions</Link>
          </div>
          <small className={s.footerCopy}>
            © 2025 Can Can. All Rights Reserved. Sole proprietorship registered in India.
          </small>
        </div>
      </footer>

      {/* ===== WHATSAPP FAB ===== */}
      <a
        className={s.whatsappFab}
        href={WA_LINK}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Message Can Can on WhatsApp"
      >
        <WhatsAppIcon />
      </a>
    </div>
  );
}

