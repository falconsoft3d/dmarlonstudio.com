import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { SITE_URL } from "@/lib/site";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

const description =
  "IDE visual de escritorio al estilo de Delphi: diseñe ventanas arrastrando componentes, escriba los eventos en Python y ejecútelas. Hoy tkinter y Flask; próximamente Electron.";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "DMarlon Studio · IDE visual para Python",
    template: "%s · DMarlon Studio",
  },
  description,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: "/",
    siteName: "DMarlon Studio",
    title: "DMarlon Studio · IDE visual para Python",
    description,
    locale: "es_ES",
  },
  twitter: {
    card: "summary",
    title: "DMarlon Studio · IDE visual para Python",
    description,
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f5f6f8" },
    { media: "(prefers-color-scheme: dark)", color: "#141518" },
  ],
};

/**
 * Layout raíz en español. Para añadir inglés en /en, pase a dos layouts
 * raíz con grupos de rutas — app/(es) y app/(en) — como en la landing de
 * ERPSqlite, y traduzca content/es.ts a content/en.ts.
 */
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col font-sans">{children}</body>
    </html>
  );
}
