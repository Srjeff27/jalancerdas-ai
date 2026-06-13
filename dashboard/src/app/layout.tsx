import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'JalanCerdas AI — Dashboard',
  description: 'AI-powered pothole detection and road monitoring dashboard',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id">
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-screen bg-[#f5f5f7] antialiased">{children}</body>
    </html>
  );
}
