import type { Metadata, Viewport } from "next";
import { contentOf } from "@/content";
import { HOME, OG_LOCALE, type Lang } from "@/lib/i18n";
import { SITE_URL } from "@/lib/site";

/** Metadatos de la portada en [lang], con su versión en el otro idioma. */
export function homeMetadata(lang: Lang): Metadata {
  const { title, description } = contentOf(lang).meta;
  return {
    metadataBase: new URL(SITE_URL),
    title: { default: title, template: "%s · DMarlon Studio" },
    description,
    alternates: {
      canonical: HOME[lang],
      languages: { es: HOME.es, en: HOME.en, "x-default": HOME.es },
    },
    openGraph: {
      type: "website",
      url: HOME[lang],
      siteName: "DMarlon Studio",
      title,
      description,
      locale: OG_LOCALE[lang],
      alternateLocale: [OG_LOCALE[lang === "es" ? "en" : "es"]],
    },
    twitter: { card: "summary", title, description },
  };
}

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f5f6f8" },
    { media: "(prefers-color-scheme: dark)", color: "#141518" },
  ],
};
