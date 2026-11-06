/** Idiomas de la web: español en la raíz (/) e inglés en /en. */
export const LANGS = ["es", "en"] as const;
export type Lang = (typeof LANGS)[number];

/** Portada de cada idioma. */
export const HOME: Record<Lang, string> = { es: "/", en: "/en" };

/** Para Open Graph. */
export const OG_LOCALE: Record<Lang, string> = { es: "es_ES", en: "en_US" };

/** Páginas que existen en los dos idiomas, con su ruta en cada uno. */
export const PATHS = {
  home: HOME,
  manual: { es: "/manual", en: "/en/manual" },
  manualPrint: { es: "/manual/imprimir", en: "/en/manual/print" },
  dossier: { es: "/dosier", en: "/en/dossier" },
  changelog: { es: "/novedades", en: "/en/changelog" },
  demos: { es: "/demos", en: "/en/demos" },
} satisfies Record<string, Record<Lang, string>>;

/** Las rutas de una misma página en cada idioma. */
export type Alternates = Record<Lang, string>;

/** PDF generados por scripts/build-docs.mjs (en public/docs). */
export const DOCS = {
  manual: { es: "/docs/DMarlonStudio-Manual-es.pdf", en: "/docs/DMarlonStudio-Manual-en.pdf" },
  dossier: { es: "/docs/DMarlonStudio-Dossier-es.pdf", en: "/docs/DMarlonStudio-Dossier-en.pdf" },
} satisfies Record<string, Record<Lang, string>>;
