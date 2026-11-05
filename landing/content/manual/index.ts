import type { Lang } from "@/lib/i18n";
import { PATHS } from "@/lib/i18n";
import { manualEn } from "./en";
import { manualEs } from "./es";
import type { Manual } from "./types";

export type { Block, Chapter, Manual, ManualSection } from "./types";

const ALL: Record<Lang, Manual> = { es: manualEs, en: manualEn };

/** Manual en [lang]. */
export const manualOf = (lang: Lang): Manual => ALL[lang];

/** Ruta del capítulo [index] en [lang]. */
export const chapterPath = (lang: Lang, index: number) =>
  `${PATHS.manual[lang]}/${ALL[lang].chapters[index].slug}`;

/** Rutas del mismo capítulo en los dos idiomas (van en el mismo orden). */
export const chapterAlternates = (index: number) => ({
  es: chapterPath("es", index),
  en: chapterPath("en", index),
});
