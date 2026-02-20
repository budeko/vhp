import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'SaaS Panel',
  description: 'Core panel — Phase 1',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
