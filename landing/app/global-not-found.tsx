import "./globals.css";
import type { Metadata } from "next";
import Link from "next/link";
import { Geist } from "next/font/google";
import { themeScript } from "@/components/theme-toggle";
import { en } from "@/content/en";
import { es } from "@/content/es";

const geist = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "404 · DMarlon Studio",
  description: `${es.notFound.title} · ${en.notFound.title}.`,
};

/** 404 de las direcciones sin página (en los dos idiomas). */
export default function GlobalNotFound() {
  return (
    <html lang="es" className={`${geist.variable} h-full antialiased`} suppressHydrationWarning>
      <body className="grid min-h-full place-items-center p-6 font-sans">
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
        <main className="max-w-md text-center">
          <p className="font-mono text-sm text-muted">404</p>
          <h1 className="mt-2 text-2xl font-semibold text-ink">{es.notFound.title}</h1>
          <p className="mt-1 text-muted" lang="en">
            {en.notFound.title}
          </p>
          <div className="mt-6 flex justify-center gap-3 text-sm">
            <Link href="/" className="rounded-md bg-accent px-4 py-2 font-medium text-on-accent hover:bg-accent-strong">
              {es.notFound.home}
            </Link>
            <Link href="/en" lang="en" className="rounded-md border border-line px-4 py-2 font-medium text-ink hover:bg-soft">
              {en.notFound.home}
            </Link>
          </div>
        </main>
      </body>
    </html>
  );
}
