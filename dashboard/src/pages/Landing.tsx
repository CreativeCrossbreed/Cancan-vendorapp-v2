import React, { useCallback, useState } from 'react';
import { Link } from 'react-router-dom';
import '../cancan.css';

const WhatsAppSvg = () => (
  <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
    <path d="M20.52 3.48A11.94 11.94 0 0 0 12 0C5.373 0 .052 5.323.052 11.95c0 2.106.552 4.07 1.6 5.82L0 24l6.45-1.68a11.92 11.92 0 0 0 5.55 1.42c6.627 0 11.948-5.323 11.948-11.95 0-3.2-1.25-6.2-3.428-8.11z" fill="currentColor"/>
    <path d="M17.472 14.382c-.297-.149-1.757-.866-2.03-.965-.273-.099-.472-.149-.672.15-.198.297-.768.965-.942 1.164-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.476-.884-.788-1.48-1.761-1.653-2.058-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.52.149-.173.198-.298.298-.497.099-.198.05-.372-.025-.52-.075-.149-.672-1.612-.92-2.214-.242-.579-.487-.5-.672-.51l-.573-.01c-.198 0-.52.074-.793.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.262.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.757-.718 2.006-1.411.248-.693.248-1.287.173-1.411-.074-.123-.272-.198-.57-.347z" fill="#ffffff"/>
  </svg>
);

const Landing: React.FC = () => {
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const toggleMobileNav = useCallback(() => {
    setMobileNavOpen(prev => !prev);
    document.documentElement.style.overflow = mobileNavOpen ? '' : 'hidden';
  }, [mobileNavOpen]);

  return (
    <div className="cancan-site">
      <header className="site-header">
        <div className="container header-inner">
          <a className="brand" href="#">
            <img src="/cancan/Can Can [Logo].png" alt="Can Can" className="logo" />
          </a>

          <nav className="nav" aria-label="Primary">
            <a href="#how">How it works</a>
            <a href="#vendor">For Vendors</a>
            <a href="#contact">Contact</a>
          </nav>

          <div className="header-actions">
            <a className="btn outline" href="#vendor">Vendor App</a>
            <a className="cta" href="https://wa.me/919025320535?text=Hello%20Can%20Can%2C%20I%20want%20to%20place%20an%20order">Order</a>
            <button
              className="menu-btn"
              aria-label="Open menu"
              aria-expanded={mobileNavOpen}
              aria-controls="mobile-nav"
              onClick={toggleMobileNav}
            >
              <span className="hamburger"></span>
            </button>
          </div>
        </div>

        {/* Mobile nav */}
        {mobileNavOpen && (
          <div id="mobile-nav" className="mobile-nav">
            <div className="mobile-inner container">
              <a className="mobile-link" href="#how" onClick={toggleMobileNav}>How it works</a>
              <a className="mobile-link" href="#vendor" onClick={toggleMobileNav}>For Vendors</a>
              <a className="mobile-link" href="#contact" onClick={toggleMobileNav}>Contact</a>
              <a className="mobile-cta" href="https://wa.me/919025320535?text=Hello%20Can%20Can" onClick={toggleMobileNav}>Order on WhatsApp</a>
              <Link className="mobile-link" to="/privacy" onClick={toggleMobileNav}>Privacy Policy</Link>
              <Link className="mobile-link" to="/terms" onClick={toggleMobileNav}>Terms &amp; Conditions</Link>
            </div>
          </div>
        )}
      </header>

      <main>
        <section className="hero">
          <div className="container hero-inner">
            <div className="hero-text">
              <h1>Can Can — Water can delivery, simplified</h1>
              <p>Order purified drinking water cans via WhatsApp. Vendors receive orders on their app. Admins manage assignments and track deliveries.</p>
              <div className="hero-actions">
                <a className="btn primary" href="https://wa.me/919025320535?text=Hi%20Can%20Can%20Team%2C%20I%20want%20to%20order%20water%20cans">Order on WhatsApp</a>
                <a className="btn outline" href="#how">Learn how it works</a>
              </div>
            </div>
            <div className="hero-visual">
              <div className="phone-mock">
                <div className="mock-screen">WhatsApp ordering with quick buttons</div>
              </div>
            </div>
          </div>
        </section>

        <section id="how" className="how">
          <div className="container">
            <div className="section-head">
              <h2>How it works</h2>
              <p className="muted">Simple WhatsApp ordering for customers — routed to nearby vendors for fast delivery.</p>
            </div>
            <div className="steps">
              <div className="step">
                <h3>1. Choose &amp; Confirm</h3>
                <p>Customers select brand, quantity, delivery date and a timeslot using WhatsApp quick buttons.</p>
              </div>
              <div className="step">
                <h3>2. Routed Automatically</h3>
                <p>Orders reach the admin portal and are assigned to the appropriate local vendor instantly.</p>
              </div>
              <div className="step">
                <h3>3. Delivered &amp; Paid</h3>
                <p>Vendor delivers the cans and updates delivery &amp; payment status from the vendor app.</p>
              </div>
            </div>
          </div>
        </section>

        <section id="vendor" className="vendor-section">
          <div className="container vendor-inner">
            <div className="section-head">
              <h2>Vendors</h2>
              <p className="muted">A lightweight vendor app to manage orders, inventory and payments — built for quick daily operations.</p>
            </div>
            <div className="feature-grid">
              <div className="feature">
                <h4>Order management</h4>
                <p className="muted-sm">Accept, schedule and update deliveries in one place.</p>
              </div>
              <div className="feature">
                <h4>Delivery history</h4>
                <p className="muted-sm">Track completed deliveries and customer feedback.</p>
              </div>
              <div className="feature">
                <h4>Payments</h4>
                <p className="muted-sm">Record cash or online payments and receipts.</p>
              </div>
              <div className="feature">
                <h4>Inventory</h4>
                <p className="muted-sm">Monitor stock and get low-inventory alerts.</p>
              </div>
              <div className="feature">
                <h4>Customers</h4>
                <p className="muted-sm">Access customer addresses and order records.</p>
              </div>
              <div className="feature">
                <h4>Route &amp; timeslots</h4>
                <p className="muted-sm">Organize delivery routes and manage timeslot availability.</p>
              </div>
            </div>
            <div className="vendor-cta">
              <a className="btn primary" href="#contact">Become a Vendor</a>
            </div>
          </div>
        </section>

        <section id="contact" className="contact">
          <div className="container contact-inner">
            <div>
              <h3>Contact Us</h3>
              <p>Email: <a href="mailto:admin@cancanindia.com">admin@cancanindia.com</a></p>
              <p>Email: <a href="mailto:support@cancanindia.com">support@cancanindia.com</a></p>
              <p>Phone: <a href="tel:+919025320535">+91 90253 20535</a></p>
            </div>
            <div>
              <h3>Quick order</h3>
              <p>Start an order on WhatsApp:</p>
              <a className="btn primary" href="https://wa.me/919025320535?text=I%20want%20to%20order%20water%20cans">Message us on WhatsApp</a>
            </div>
          </div>
        </section>
      </main>

      <footer className="site-footer">
        <div className="container footer-inner">
          <div className="footer-links">
            <Link to="/privacy">Privacy Policy</Link>
            <Link to="/terms">Terms &amp; Conditions</Link>
          </div>
          <small>2025 Can Can. All Rights Reserved. Sole proprietorship registered in India.</small>
        </div>
      </footer>

      {/* Floating WhatsApp CTA */}
      <a
        className="whatsapp-fab"
        href="https://wa.me/919025320535?text=Hi%20Can%20Can%20Team%2C%20I%20want%20to%20order%20water%20cans"
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Message Can Can on WhatsApp"
      >
        <WhatsAppSvg />
      </a>
    </div>
  );
};

export default Landing;
