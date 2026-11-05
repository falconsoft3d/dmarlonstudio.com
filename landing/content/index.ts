import type { Lang } from "@/lib/i18n";
import { en } from "./en";
import { es } from "./es";
import type { Content } from "./types";

export type { Content } from "./types";

const ALL: Record<Lang, Content> = { es, en };

/** Textos de la portada en [lang]. */
export const contentOf = (lang: Lang): Content => ALL[lang];
