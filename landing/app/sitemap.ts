import type { MetadataRoute } from "next";
import { chapterAlternates, manualOf } from "@/content/manual";
import { HOME, LANGS, PATHS, type Alternates } from "@/lib/i18n";
import { SITE_URL } from "@/lib/site";

/** Cada página en los dos idiomas, con su versión en el otro. */
function both(paths: Alternates, priority: number, changeFrequency: "weekly" | "monthly"): MetadataRoute.Sitemap {
  const languages = Object.fromEntries(LANGS.map((l) => [l, `${SITE_URL}${paths[l]}`]));
  return LANGS.map((l) => ({
    url: `${SITE_URL}${paths[l]}`,
    changeFrequency,
    priority: l === "es" ? priority : priority - 0.1,
    alternates: { languages },
  }));
}

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    ...both(HOME, 1, "weekly"),
    ...both(PATHS.manual, 0.8, "weekly"),
    ...manualOf("es").chapters.flatMap((_, i) => both(chapterAlternates(i), 0.7, "monthly")),
    ...both(PATHS.dossier, 0.7, "monthly"),
  ];
}
