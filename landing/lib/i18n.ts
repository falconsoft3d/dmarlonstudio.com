/** Idiomas de la web: español en la raíz (/) e inglés en /en. */
export const LANGS = ["es", "en"] as const;
export type Lang = (typeof LANGS)[number];

/** Portada de cada idioma. */
export const HOME: Record<Lang, string> = { es: "/", en: "/en" };

/** Para Open Graph. */
export const OG_LOCALE: Record<Lang, string> = { es: "es_ES", en: "en_US" };
