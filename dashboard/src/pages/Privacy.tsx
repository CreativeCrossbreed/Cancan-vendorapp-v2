import React from 'react';
import { Link } from 'react-router-dom';
import '../cancan.css';

const Privacy: React.FC = () => {
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
                        <h1>Privacy Policy</h1>
                        <p className="muted">Last updated: December 2025</p>

                        <p>The official Privacy Policy PDF is embedded below.</p>

                        <p>
                            <a className="btn outline" href="/cancan/privacy.pdf" download>
                                Download Privacy Policy (PDF)
                            </a>
                        </p>

                        <div style={{ marginTop: 18 }}>
                            <object
                                data="/cancan/privacy.pdf"
                                type="application/pdf"
                                width="100%"
                                height="720"
                            >
                                <p>
                                    It appears your browser cannot display the PDF.{' '}
                                    <a href="/cancan/privacy.pdf">Download the Privacy Policy (PDF)</a> to view it.
                                </p>
                            </object>
                        </div>

                        <h2>Summary</h2>
                        <p>
                            This page contains the official Privacy Policy as provided in the uploaded PDF. The
                            document details what personal information we collect, how we use it, retention and
                            security practices, and your rights regarding your personal information. For the
                            authoritative legal text, please download or view the PDF above.
                        </p>

                        <h2>Contact</h2>
                        <p>
                            For requests or questions, please reach out to:{' '}
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

export default Privacy;
