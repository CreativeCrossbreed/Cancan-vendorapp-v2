import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Can Can — Water can delivery, simplified',
  description:
    'Can Can streamlines drinking water can delivery across India via WhatsApp ordering and vendor apps.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
