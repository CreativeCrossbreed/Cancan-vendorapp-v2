import React from 'react';
import { Link } from 'react-router-dom';
import '../cancan.css';

const Terms: React.FC = () => {
    return (
        <div className="cancan-site">
            <header className="site-header">
                <div className="container header-inner">
                    <Link className="brand" to="/">
                        <img src="/cancan/Can Can [Logo].png" alt="Can Can" className="logo" />
                    </Link>
                </div>
            </header>

            <main>
                <section className="legal">
                    <div className="container">
                        <h1>Terms &amp; Conditions</h1>
                        <p className="muted">Last updated: December 2025</p>

                        <p>The full Terms &amp; Conditions document is available for download below.</p>

                        <p>
                            <a href="/cancan/terms.pdf" download>
                                Download Terms &amp; Conditions (PDF)
                            </a>
                        </p>

                        <div>
                            <object
                                data="/cancan/terms.pdf"
                                type="application/pdf"
                                width="100%"
                                height="720"
                            >
                                <p>
                                    It appears your browser cannot display the PDF.{' '}
                                    <a href="/cancan/terms.pdf">Download the Terms &amp; Conditions (PDF)</a> to view it.
                                </p>
                            </object>
                        </div>

                        <h2>Summary</h2>
                        <p>
                            This page summarizes key points: service scope, ordering rules, cancellation &amp;
                            refund policies, vendor responsibilities, and limitation of liability. Refer to the
                            PDF for the complete legal text.
                        </p>

                        <h3>Contact</h3>
                        <p>
                            For further questions, please reach out to:{' '}
                            <a href="mailto:support@cancanindia.com">support@cancanindia.com</a>
                        </p>
                    </div>
                </section>
            </main>

            <footer className="site-footer">
                <div className="container footer-inner">
                    <small>
                        <Link to="/">Back to home</Link>
                    </small>
                </div>
            </footer>
        </div>
    );
};

export default Terms;
