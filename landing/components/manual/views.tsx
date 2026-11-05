import { ArrowLeft, ArrowRight, BookOpen, FileDown } from "lucide-react";
import { Logo } from "@/components/logo";
import { BlockView } from "@/components/manual/rich";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { contentOf } from "@/content";
import { chapterAlternates, chapterPath, manualOf, type Chapter } from "@/content/manual";
import { DOCS, PATHS, type Lang } from "@/lib/i18n";
import { VERSION } from "@/lib/version";

function PdfButton({ lang, label }: { lang: Lang; label: string }) {
  return (
    <a
      href={DOCS.manual[lang]}
      download
      className="inline-flex items-center gap-2 rounded-md bg-accent px-4 py-2 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong"
    >
      <FileDown className="size-4" aria-hidden />
      {label}
    </a>
  );
}

/** Lista de capítulos de la barra lateral, con las secciones del actual. */
function Sidebar({ lang, current }: { lang: Lang; current: number }) {
  const m = manualOf(lang);
  return (
    <nav aria-label={m.ui.contents} className="text-sm">
      <p className="mb-3 font-semibold">{m.ui.contents}</p>
      <ol className="space-y-1">
        {m.chapters.map((c, i) => (
          <li key={c.slug}>
            <a
              href={chapterPath(lang, i)}
              aria-current={i === current ? "page" : undefined}
              className={`flex gap-2 rounded-md px-2 py-1.5 transition-colors ${
                i === current ? "bg-accent/10 font-medium text-accent" : "text-muted hover:bg-soft hover:text-ink"
              }`}
            >
              <span className="w-5 shrink-0 text-right font-mono text-xs leading-5 opacity-70">{i + 1}</span>
              <span>{c.title}</span>
            </a>
            {i === current && (
              <ul className="mt-1 mb-2 ml-9 space-y-1 border-l border-line pl-3">
                {c.sections.map((s) => (
                  <li key={s.id}>
                    <a href={`#${s.id}`} className="block py-0.5 text-muted hover:text-ink">
                      {s.title}
                    </a>
                  </li>
                ))}
              </ul>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}

function ChapterBody({ chapter, print = false }: { chapter: Chapter; print?: boolean }) {
  return (
    <div className="space-y-12">
      {chapter.sections.map((s) => (
        <section key={s.id} id={s.id} className="scroll-mt-20">
          <h2 className="text-xl font-semibold tracking-tight break-after-avoid">
            <a href={`#${s.id}`} className="hover:text-accent">
              {s.title}
            </a>
          </h2>
          <div className="mt-4 space-y-4">
            {s.blocks.map((b, i) => (
              <BlockView key={i} b={b} print={print} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}

/** Portada del manual: presentación y capítulos. */
export function ManualIndex({ lang }: { lang: Lang }) {
  const t = contentOf(lang);
  const m = manualOf(lang);
  return (
    <>
      <SiteHeader lang={lang} t={t} alternates={PATHS.manual} />
      <main className="flex-1">
        <section className="mx-auto max-w-6xl px-4 pt-14 pb-10 sm:px-6">
          <p className="inline-flex items-center gap-2 text-sm font-medium text-accent">
            <BookOpen className="size-4" aria-hidden />
            {m.ui.version} {VERSION}
          </p>
          <h1 className="mt-3 text-3xl font-semibold tracking-tight text-balance sm:text-4xl">{m.ui.title}</h1>
          <p className="mt-4 max-w-2xl text-lg leading-relaxed text-muted text-pretty">{m.ui.intro}</p>
          <div className="mt-6">
            <PdfButton lang={lang} label={m.ui.downloadPdf} />
          </div>
        </section>
        <section className="border-t border-line bg-surface">
          <ol className="mx-auto grid max-w-6xl gap-4 px-4 py-12 sm:grid-cols-2 sm:px-6 lg:grid-cols-3">
            {m.chapters.map((c, i) => (
              <li key={c.slug}>
                <a
                  href={chapterPath(lang, i)}
                  className="block h-full rounded-xl border border-line bg-canvas p-5 transition-colors hover:border-accent"
                >
                  <p className="font-mono text-xs text-muted">
                    {m.ui.chapter} {i + 1}
                  </p>
                  <h2 className="mt-1 font-semibold">{c.title}</h2>
                  <p className="mt-1.5 text-sm leading-relaxed text-muted">{c.summary}</p>
                </a>
              </li>
            ))}
          </ol>
        </section>
      </main>
      <SiteFooter lang={lang} t={t} />
    </>
  );
}

/** Un capítulo, con la lista de capítulos al lado y anterior / siguiente. */
export function ManualChapter({ lang, index }: { lang: Lang; index: number }) {
  const t = contentOf(lang);
  const m = manualOf(lang);
  const chapter = m.chapters[index];
  const prev = index > 0 ? index - 1 : null;
  const next = index < m.chapters.length - 1 ? index + 1 : null;
  return (
    <>
      <SiteHeader lang={lang} t={t} alternates={chapterAlternates(index)} />
      <main className="mx-auto grid w-full max-w-6xl flex-1 gap-10 px-4 py-10 sm:px-6 lg:grid-cols-[250px_1fr]">
        <aside className="lg:sticky lg:top-20 lg:max-h-[calc(100vh-6rem)] lg:self-start lg:overflow-y-auto">
          <a href={PATHS.manual[lang]} className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted hover:text-ink">
            <ArrowLeft className="size-3.5" aria-hidden />
            {m.ui.allChapters}
          </a>
          <div className="hidden lg:block">
            <Sidebar lang={lang} current={index} />
          </div>
        </aside>
        <article className="min-w-0 max-w-3xl">
          <p className="font-mono text-xs text-muted">
            {m.ui.chapter} {index + 1}
          </p>
          <h1 className="mt-1 text-3xl font-semibold tracking-tight">{chapter.title}</h1>
          <p className="mt-2 text-lg text-muted">{chapter.summary}</p>
          <nav aria-label={m.ui.onThisPage} className="mt-6 rounded-lg border border-line bg-surface p-4 text-sm lg:hidden">
            <p className="font-medium">{m.ui.onThisPage}</p>
            <ul className="mt-2 space-y-1">
              {chapter.sections.map((s) => (
                <li key={s.id}>
                  <a href={`#${s.id}`} className="text-muted hover:text-ink">
                    {s.title}
                  </a>
                </li>
              ))}
            </ul>
          </nav>
          <div className="mt-10">
            <ChapterBody chapter={chapter} />
          </div>
          <div className="mt-14 grid gap-3 border-t border-line pt-6 sm:grid-cols-2">
            {prev !== null ? (
              <a href={chapterPath(lang, prev)} className="rounded-lg border border-line p-4 hover:border-accent">
                <span className="flex items-center gap-1.5 text-xs text-muted">
                  <ArrowLeft className="size-3.5" aria-hidden />
                  {m.ui.previous}
                </span>
                <span className="mt-1 block font-medium">{m.chapters[prev].title}</span>
              </a>
            ) : (
              <span />
            )}
            {next !== null && (
              <a href={chapterPath(lang, next)} className="rounded-lg border border-line p-4 text-right hover:border-accent">
                <span className="flex items-center justify-end gap-1.5 text-xs text-muted">
                  {m.ui.next}
                  <ArrowRight className="size-3.5" aria-hidden />
                </span>
                <span className="mt-1 block font-medium">{m.chapters[next].title}</span>
              </a>
            )}
          </div>
          <div className="mt-8">
            <PdfButton lang={lang} label={m.ui.downloadPdf} />
          </div>
        </article>
      </main>
      <SiteFooter lang={lang} t={t} />
    </>
  );
}

/** El manual entero en una página para imprimir a PDF (A4). */
export function ManualPrint({ lang }: { lang: Lang }) {
  const m = manualOf(lang);
  const date = new Date().toISOString().slice(0, 10);
  return (
    <main className="manual-print mx-auto max-w-[180mm] text-[10.5pt]">
      {/* Portada */}
      <section className="print-cover flex min-h-[250mm] flex-col justify-between py-10">
        <div className="flex items-center gap-3">
          <Logo className="size-12" />
          <span className="text-xl font-semibold tracking-tight">DMarlon Studio</span>
        </div>
        <div>
          <p className="text-sm font-medium text-accent">{m.ui.printTitle}</p>
          <h1 className="mt-3 text-5xl font-semibold tracking-tight text-balance">{m.ui.title}</h1>
          <p className="mt-5 max-w-[140mm] text-lg leading-relaxed text-muted">{m.ui.subtitle}</p>
        </div>
        <div className="flex justify-between border-t border-line pt-4 text-sm text-muted">
          <span>
            {m.ui.version} {VERSION} · {date}
          </span>
          <span>dmarlonstudio.com</span>
        </div>
      </section>

      {/* Índice */}
      <section className="print-chapter py-6">
        <h1 className="text-3xl font-semibold tracking-tight">{m.ui.contents}</h1>
        <ol className="mt-8 space-y-4">
          {m.chapters.map((c, i) => (
            <li key={c.slug} className="break-inside-avoid">
              <a href={`#cap-${i + 1}`} className="flex gap-3">
                <span className="w-7 shrink-0 font-mono text-accent">{i + 1}</span>
                <span>
                  <span className="font-semibold">{c.title}</span>
                  <span className="block text-sm text-muted">{c.sections.map((s) => s.title).join(" · ")}</span>
                </span>
              </a>
            </li>
          ))}
        </ol>
      </section>

      {m.chapters.map((c, i) => (
        <section key={c.slug} id={`cap-${i + 1}`} className="print-chapter py-6">
          <p className="font-mono text-xs text-muted">
            {m.ui.chapter} {i + 1}
          </p>
          <h1 className="mt-1 text-3xl font-semibold tracking-tight">{c.title}</h1>
          <p className="mt-2 mb-8 text-muted">{c.summary}</p>
          <ChapterBody chapter={c} print />
        </section>
      ))}
    </main>
  );
}
