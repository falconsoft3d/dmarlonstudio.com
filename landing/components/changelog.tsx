import { readFileSync } from "node:fs";
import { join } from "node:path";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { contentOf } from "@/content";
import { PATHS, type Lang } from "@/lib/i18n";
import { VERSION } from "@/lib/version";

type Release = { version: string; date: string; items: string[] };

/** Lee content/CHANGELOG.md (copia de la raíz del repositorio). */
function releases(): Release[] {
  const text = readFileSync(join(process.cwd(), "content", "CHANGELOG.md"), "utf8");
  const out: Release[] = [];
  let current: Release | null = null;
  for (const raw of text.split("\n")) {
    const head = raw.match(/^##\s+(\S+)\s+[—-]\s+(.+)$/);
    if (head) {
      current = { version: head[1], date: head[2].trim(), items: [] };
      out.push(current);
      continue;
    }
    if (!current) continue;
    if (raw.startsWith("- ")) current.items.push(raw.slice(2).trim());
    else if (raw.startsWith("  ") && current.items.length) {
      current.items[current.items.length - 1] += " " + raw.trim();
    }
  }
  return out;
}

/** **negrita** y `código` del CHANGELOG. */
function Rich({ text }: { text: string }) {
  const parts = text.split(/(\*\*[^*]+\*\*|`[^`]+`)/g).filter(Boolean);
  return (
    <>
      {parts.map((p, i) =>
        p.startsWith("**") ? (
          <strong key={i} className="font-semibold text-ink">
            {p.slice(2, -2)}
          </strong>
        ) : p.startsWith("`") ? (
          <code key={i} className="rounded bg-soft px-1 py-0.5 font-mono text-[0.85em]">
            {p.slice(1, -1)}
          </code>
        ) : (
          <span key={i}>{p}</span>
        ),
      )}
    </>
  );
}

const TEXT = {
  es: {
    title: "Novedades",
    intro: "Lo que trae cada versión de DMarlon Studio, de la más reciente a la primera.",
    current: "Versión actual",
  },
  en: {
    title: "Changelog",
    intro: "What each version of DMarlon Studio brings, newest first. The notes are written in Spanish.",
    current: "Current version",
  },
} satisfies Record<Lang, Record<string, string>>;

export function changelogText(lang: Lang) {
  return TEXT[lang];
}

/** Historial de versiones: una tarjeta por versión. */
export function Changelog({ lang }: { lang: Lang }) {
  const t = contentOf(lang);
  const x = TEXT[lang];
  const list = releases();
  return (
    <>
      <SiteHeader lang={lang} t={t} alternates={PATHS.changelog} />
      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-12 sm:px-6">
        <h1 className="text-3xl font-semibold tracking-tight">{x.title}</h1>
        <p className="mt-2 text-muted">{x.intro}</p>
        <ol className="mt-10 space-y-8">
          {list.map((r) => (
            <li key={r.version} id={`v${r.version}`} className="scroll-mt-24 rounded-xl border border-line bg-surface p-6">
              <div className="flex flex-wrap items-baseline gap-3">
                <h2 className="font-mono text-xl font-semibold">v{r.version}</h2>
                <span className="text-sm text-muted">{r.date}</span>
                {r.version === VERSION && (
                  <span className="rounded-full bg-success/12 px-2 py-0.5 text-xs font-medium text-success">
                    {x.current}
                  </span>
                )}
              </div>
              <ul className="mt-4 list-disc space-y-2 pl-5 text-sm leading-relaxed text-muted">
                {r.items.map((it, i) => (
                  <li key={i}>
                    <Rich text={it} />
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ol>
      </main>
      <SiteFooter lang={lang} t={t} />
    </>
  );
}
