import type { MetadataRoute } from "next";
import { HOME, LANGS } from "@/lib/i18n";
import { SITE_URL } from "@/lib/site";

/** Las dos portadas, cada una con su versión en el otro idioma. */
export default function sitemap(): MetadataRoute.Sitemap {
  const languages = Object.fromEntries(LANGS.map((l) => [l, `${SITE_URL}${HOME[l]}`]));
  return LANGS.map((l) => ({
    url: `${SITE_URL}${HOME[l]}`,
    changeFrequency: "weekly",
    priority: l === "es" ? 1 : 0.9,
    alternates: { languages },
  }));
}
