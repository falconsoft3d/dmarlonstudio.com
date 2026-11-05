import Image from "next/image";
import { Bot, Database, FileDown, FolderSync, Globe, Code2, LayoutTemplate, Send, Workflow, Check, Clock } from "lucide-react";
import { Logo } from "@/components/logo";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { contentOf } from "@/content";
import { dossierOf } from "@/content/dossier";
import { REPO_URL } from "@/lib/downloads";
import { DOCS, PATHS, type Lang } from "@/lib/i18n";
import { SITE_URL } from "@/lib/site";
import { VERSION } from "@/lib/version";

const MODULE_ICONS = [LayoutTemplate, Code2, Database, Send, FolderSync, Workflow];

/** Hoja A4: en pantalla, una tarjeta; al imprimir, una página. */
function Sheet({ n, children, className = "" }: { n: number; children: React.ReactNode; className?: string }) {
  return (
    <section
      className={`dossier-sheet relative mx-auto flex w-full max-w-[210mm] flex-col overflow-hidden bg-surface shadow-xl ring-1 ring-line md:min-h-[297mm] ${className}`}
    >
      {children}
      <div className="mt-auto flex items-center justify-between px-[16mm] pb-[10mm] text-xs text-muted">
        <span className="flex items-center gap-2">
          <Logo className="size-4" /> DMarlon Studio
        </span>
        <span className="font-mono">{n} / 6</span>
      </div>
    </section>
  );
}

/** Captura de la app. Con [crop], solo la parte de arriba (para que la hoja quepa en A4). */
function Shot({ lang, name, alt, crop }: { lang: Lang; name: string; alt: string; crop?: string }) {
  const img = (
    <Image
      src={`/manual/${lang}/${name}.jpg`}
      alt={alt}
      width={1600}
      height={1000}
      loading="eager"
      unoptimized
      className={crop ? "h-auto w-full" : "h-auto w-full rounded-lg border border-line shadow-md"}
    />
  );
  return crop ? (
    <div className={`${crop} overflow-hidden rounded-lg border border-line shadow-md`}>{img}</div>
  ) : (
    img
  );
}

function Eyebrow({ children }: { children: React.ReactNode }) {
  return <p className="text-sm font-semibold tracking-wide text-accent uppercase">{children}</p>;
}

/** Dossier del producto: seis hojas A4. */
export function Dossier({ lang }: { lang: Lang }) {
  const t = contentOf(lang);
  const d = dossierOf(lang);
  const pad = "px-[16mm] pt-[16mm]";
  return (
    <>
      <SiteHeader lang={lang} t={t} alternates={PATHS.dossier} />
      <main className="flex-1 bg-canvas">
        <div className="mx-auto flex max-w-[210mm] flex-wrap items-center justify-between gap-3 px-4 pt-10 pb-6 print:hidden">
          <h1 className="text-2xl font-semibold tracking-tight">{d.meta.title}</h1>
          <a
            href={DOCS.dossier[lang]}
            download
            className="inline-flex items-center gap-2 rounded-md bg-accent px-4 py-2 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong"
          >
            <FileDown className="size-4" aria-hidden />
            {d.download}
          </a>
        </div>

        <div className="dossier space-y-10 px-4 pb-16 print:space-y-0 print:p-0">
          {/* 1 · Portada */}
          <Sheet n={1} className="dossier-cover">
            <div className="bg-gradient-to-br from-[#2b5fd9] to-[#34249e] px-[16mm] pt-[18mm] pb-[14mm] text-white">
              <div className="flex items-center gap-3">
                <Logo className="size-12 rounded-xl ring-2 ring-white/30" />
                <span className="text-2xl font-semibold tracking-tight">DMarlon Studio</span>
              </div>
              <p className="mt-[16mm] text-sm font-semibold tracking-wide uppercase opacity-80">{d.cover.eyebrow}</p>
              <h2 className="mt-3 text-4xl leading-tight font-semibold tracking-tight text-balance">{d.cover.title}</h2>
              <p className="mt-5 text-lg leading-relaxed opacity-90">{d.cover.text}</p>
            </div>
            <div className={`${pad} space-y-6`}>
              <Shot lang={lang} name="designer" alt={d.modules.items[0].title} />
              <div className="flex flex-wrap gap-2 text-sm">
                {["tkinter", "Flask"].map((x, i) => (
                  <span
                    key={x}
                    className={`rounded-full px-3 py-1 font-mono text-xs ${
                      i < 2 ? "bg-success/12 text-success" : "bg-soft text-muted"
                    }`}
                  >
                    {x}
                  </span>
                ))}
              </div>
              <p className="text-sm text-muted">
                {d.cover.version} {VERSION} · {SITE_URL.replace("https://", "")}
              </p>
            </div>
          </Sheet>

          {/* 2 · Qué es y para quién */}
          <Sheet n={2}>
            <div className={pad}>
              <Eyebrow>{d.what.eyebrow}</Eyebrow>
              <h2 className="mt-2 text-3xl font-semibold tracking-tight text-balance">{d.what.title}</h2>
              <div className="mt-6 space-y-4 leading-relaxed text-muted">
                {d.what.text.map((p) => (
                  <p key={p}>{p}</p>
                ))}
              </div>
              <h3 className="mt-10 text-xl font-semibold">{d.what.audienceTitle}</h3>
              <div className="mt-5 grid grid-cols-2 gap-4">
                {d.what.audience.map((a) => (
                  <div key={a.title} className="rounded-xl border border-line bg-canvas p-5">
                    <p className="font-semibold">{a.title}</p>
                    <p className="mt-1.5 text-sm leading-relaxed text-muted">{a.text}</p>
                  </div>
                ))}
              </div>
              <div className="mt-8">
                <Shot lang={lang} name="designer-code" alt={d.what.title} crop="md:h-[62mm] print:h-[62mm]" />
              </div>
            </div>
          </Sheet>

          {/* 3 · Módulos */}
          <Sheet n={3}>
            <div className={pad}>
              <Eyebrow>{d.modules.eyebrow}</Eyebrow>
              <h2 className="mt-2 text-3xl font-semibold tracking-tight">{d.modules.title}</h2>
              <p className="mt-3 leading-relaxed text-muted">{d.modules.intro}</p>
              <div className="mt-7 grid grid-cols-2 gap-4">
                {d.modules.items.map((m, i) => {
                  const Icon = MODULE_ICONS[i];
                  return (
                    <div key={m.title} className="rounded-xl border border-line bg-canvas p-5">
                      <Icon className="size-5 text-accent" aria-hidden />
                      <p className="mt-2 font-semibold">{m.title}</p>
                      <p className="mt-1 text-sm leading-relaxed text-muted">{m.text}</p>
                    </div>
                  );
                })}
              </div>
              <div className="mt-7">
                <Shot lang={lang} name="editor" alt={d.modules.items[1].title} crop="md:h-[80mm] print:h-[80mm]" />
              </div>
            </div>
          </Sheet>

          {/* 4 · Destinos */}
          <Sheet n={4}>
            <div className={pad}>
              <Eyebrow>{d.targets.eyebrow}</Eyebrow>
              <h2 className="mt-2 text-3xl font-semibold tracking-tight">{d.targets.title}</h2>
              <p className="mt-3 leading-relaxed text-muted">{d.targets.intro}</p>
              <table className="mt-7 w-full overflow-hidden rounded-xl border border-line text-left text-sm">
                <thead className="bg-soft">
                  <tr>
                    {d.targets.head.map((h) => (
                      <th key={h} className="px-4 py-3 font-semibold">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {d.targets.rows.map(([a, b, c], i) => (
                    <tr key={b} className="border-t border-line">
                      <td className="px-4 py-3">{a}</td>
                      <td className="px-4 py-3 font-mono text-xs">{b}</td>
                      <td className="px-4 py-3">
                        <span
                          className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium ${
                            i < 2 ? "bg-success/12 text-success" : "bg-accent/10 text-accent"
                          }`}
                        >
                          {i < 2 ? <Check className="size-3" aria-hidden /> : <Clock className="size-3" aria-hidden />}
                          {c}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <p className="mt-5 flex gap-2 text-sm leading-relaxed text-muted">
                <Globe className="mt-0.5 size-4 shrink-0 text-accent" aria-hidden />
                {d.targets.note}
              </p>
              <div className="mt-7">
                <Shot lang={lang} name="designer-generated" alt={d.targets.title} />
              </div>
            </div>
          </Sheet>

          {/* 5 · IA */}
          <Sheet n={5}>
            <div className={pad}>
              <Eyebrow>{d.ai.eyebrow}</Eyebrow>
              <h2 className="mt-2 text-3xl font-semibold tracking-tight">{d.ai.title}</h2>
              <p className="mt-3 leading-relaxed text-muted">{d.ai.intro}</p>
              <div className="mt-7 grid grid-cols-2 gap-4">
                {d.ai.items.map((a) => (
                  <div key={a.title} className="rounded-xl border border-line bg-canvas p-5">
                    <Bot className="size-5 text-accent" aria-hidden />
                    <p className="mt-2 font-semibold">{a.title}</p>
                    <p className="mt-1 text-sm leading-relaxed text-muted">{a.text}</p>
                  </div>
                ))}
              </div>
              <div className="mt-7">
                <Shot lang={lang} name="designer-claude" alt={d.ai.items[0].title} />
              </div>
            </div>
          </Sheet>

          {/* 6 · Cómo empezar y contacto */}
          <Sheet n={6}>
            <div className={pad}>
              <Eyebrow>{d.start.eyebrow}</Eyebrow>
              <h2 className="mt-2 text-3xl font-semibold tracking-tight">{d.start.title}</h2>
              <ol className="mt-7 grid grid-cols-2 gap-4">
                {d.start.steps.map((s) => (
                  <li key={s.title} className="rounded-xl border border-line bg-canvas p-5">
                    <p className="font-semibold">{s.title}</p>
                    <p className="mt-1 text-sm leading-relaxed text-muted">{s.text}</p>
                  </li>
                ))}
              </ol>
              <h3 className="mt-10 text-xl font-semibold">{d.start.requirementsTitle}</h3>
              <ul className="mt-4 space-y-2 text-muted">
                {d.start.requirements.map((r) => (
                  <li key={r} className="flex gap-2">
                    <Check className="mt-1 size-4 shrink-0 text-success" aria-hidden />
                    {r}
                  </li>
                ))}
              </ul>
              <div className="mt-10 rounded-xl bg-gradient-to-br from-[#2b5fd9] to-[#34249e] p-7 text-white">
                <h3 className="text-xl font-semibold">{d.start.contactTitle}</h3>
                <dl className="mt-4 grid gap-3 text-sm">
                  <div className="flex gap-3">
                    <dt className="w-36 shrink-0 opacity-75">{d.start.web}</dt>
                    <dd>
                      <a href={SITE_URL} className="font-medium underline-offset-2 hover:underline">
                        {SITE_URL.replace("https://", "")}
                      </a>
                    </dd>
                  </div>
                  <div className="flex gap-3">
                    <dt className="w-36 shrink-0 opacity-75">{d.start.manual}</dt>
                    <dd>
                      <a href={`${SITE_URL}${PATHS.manual[lang]}`} className="font-medium underline-offset-2 hover:underline">
                        {`${SITE_URL.replace("https://", "")}${PATHS.manual[lang]}`}
                      </a>
                    </dd>
                  </div>
                  <div className="flex gap-3">
                    <dt className="w-36 shrink-0 opacity-75">{d.start.repo}</dt>
                    <dd>
                      <a href={REPO_URL} className="font-medium underline-offset-2 hover:underline">
                        {REPO_URL.replace("https://", "")}
                      </a>
                    </dd>
                  </div>
                </dl>
              </div>
            </div>
          </Sheet>
        </div>
      </main>
      <SiteFooter lang={lang} t={t} />
    </>
  );
}
