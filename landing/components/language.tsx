import { HOME, LANGS, type Lang } from "@/lib/i18n";

/** Selector ES / EN de la cabecera: lleva a la portada en el otro idioma. */
export function LanguageSwitch({ lang, label }: { lang: Lang; label: string }) {
  return (
    <nav aria-label={label} className="flex shrink-0 items-center rounded-md border border-line p-0.5 text-xs font-medium">
      {LANGS.map((l) =>
        l === lang ? (
          <span key={l} aria-current="page" className="rounded bg-soft px-1.5 py-0.5 text-ink">
            {l.toUpperCase()}
          </span>
        ) : (
          <a
            key={l}
            href={HOME[l]}
            hrefLang={l}
            lang={l}
            title={l === "en" ? "English" : "Español"}
            className="rounded px-1.5 py-0.5 text-muted transition-colors hover:text-ink"
          >
            {l.toUpperCase()}
          </a>
        ),
      )}
    </nav>
  );
}
