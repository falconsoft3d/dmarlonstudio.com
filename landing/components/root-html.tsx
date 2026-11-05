import { Geist, Geist_Mono } from "next/font/google";
import { themeScript } from "@/components/theme-toggle";
import type { Lang } from "@/lib/i18n";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

/** <html> y <body> de los dos layouts raíz (español e inglés). */
export function RootHtml({ lang, children }: { lang: Lang; children: React.ReactNode }) {
  return (
    <html
      lang={lang}
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="min-h-full flex flex-col font-sans">
        {/* Tema guardado antes de pintar: sin destello claro. */}
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
        {children}
      </body>
    </html>
  );
}
