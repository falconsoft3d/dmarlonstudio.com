import { ArrowLeft, ArrowRight } from "lucide-react";
import { DemoDownloads } from "@/components/demo-downloads";
import { ALL_DEMOS, demoInfo } from "@/components/demos";
import { LiveDemo } from "@/components/live-demo";
import { PlatformIcon } from "@/components/platform-icon";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { TechChip } from "@/components/tech-chip";
import { contentOf } from "@/content";
import { GUIDES, stepImage } from "@/content/demo-guides";
import { apkUrl, demoAlternates, demoPath, liveUrl } from "@/lib/demos";
import { PATHS, type Lang } from "@/lib/i18n";

const TEXT = {
  es: {
    back: "Todas las demos",
    how: "Cómo funciona",
    step: "Paso",
    previous: "Anterior",
    next: "Siguiente",
    studio:
      "Esta demo viene como ejemplo en DMarlon Studio: ábrala en el Diseñador para ver su diseño y su código, cámbiela y pulse Ejecutar.",
    section: { desktop: "Escritorio", mobile: "Móvil", web: "Web" },
  },
  en: {
    back: "All demos",
    how: "How it works",
    step: "Step",
    previous: "Previous",
    next: "Next",
    studio: "This demo comes as an example in DMarlon Studio: open it in the Designer to see its design and code, change it and press Run.",
    section: { desktop: "Desktop", mobile: "Mobile", web: "Web" },
  },
} satisfies Record<Lang, unknown>;

export function demoMeta(lang: Lang, seed: string) {
  const info = demoInfo(lang, seed);
  const guide = GUIDES[lang][seed];
  if (!info || !guide) return null;
  return { title: `${info.d.name} · Demo`, description: guide.intro };
}

/** Página de una demo: qué es, sus botones y cómo funciona en tres pasos con captura. */
export function DemoDetail({ lang, seed }: { lang: Lang; seed: string }) {
  const t = contentOf(lang);
  const info = demoInfo(lang, seed)!;
  const guide = GUIDES[lang][seed];
  const y = TEXT[lang];
  const { kind, d, tech, x } = info;
  const i = ALL_DEMOS.findIndex((e) => e.seed === seed);
  const prev = ALL_DEMOS[(i - 1 + ALL_DEMOS.length) % ALL_DEMOS.length];
  const next = ALL_DEMOS[(i + 1) % ALL_DEMOS.length];
  const nameOf = (s: string) => demoInfo(lang, s)!.d.name;
  const phone = kind === "mobile";
  return (
    <>
      <SiteHeader lang={lang} t={t} alternates={demoAlternates(seed)} />
      <main className="flex-1">
        <section className="mx-auto max-w-6xl px-4 pt-10 pb-12 sm:px-6">
          <a
            href={`${PATHS.demos[lang]}#${kind}`}
            className="inline-flex items-center gap-1.5 text-sm text-muted transition-colors hover:text-ink"
          >
            <ArrowLeft className="size-4" aria-hidden />
            {y.back} · {y.section[kind]}
          </a>
          <div className="mt-6 grid items-start gap-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]">
            <div>
              <TechChip icon={tech.icon} label={tech.label} />
              <h1 className="mt-4 text-3xl font-semibold tracking-tight text-balance sm:text-4xl">{d.name}</h1>
              <p className="mt-4 text-lg leading-relaxed text-muted text-pretty">{guide.intro}</p>
              <p className="mt-6 text-xs font-medium tracking-wide text-muted uppercase">{x.shows}</p>
              <ul className="mt-2 space-y-1.5">
                {d.shows.map((s) => (
                  <li key={s} className="flex gap-2">
                    <span className="mt-2.5 size-1.5 shrink-0 rounded-full bg-accent" aria-hidden />
                    {s}
                  </li>
                ))}
              </ul>
              <div className="mt-6 max-w-md">
                {kind === "desktop" && <DemoDownloads seed={seed} label={x.download} />}
                {kind !== "desktop" && (
                  <div className={`grid gap-2 ${phone ? "grid-cols-2" : ""}`}>
                    <LiveDemo
                      url={liveUrl(seed, lang)}
                      title={d.name}
                      label={phone ? x.tryPhone : x.tryWeb}
                      close={x.close}
                      newTab={x.newTab}
                      phone={phone}
                    />
                    {phone && (
                      <a
                        href={apkUrl(seed, lang)}
                        className="inline-flex items-center justify-center gap-1.5 rounded-md border border-line bg-soft px-3 py-2 text-sm font-medium text-ink transition-colors hover:border-accent hover:text-accent"
                      >
                        <PlatformIcon platform="android" className="size-4" />
                        {x.android}
                      </a>
                    )}
                  </div>
                )}
              </div>
            </div>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={stepImage(seed, lang, 1)}
              alt={`${d.name}: ${guide.steps[0].title}`}
              className="w-full rounded-xl border border-line shadow-xl shadow-black/10"
            />
          </div>
        </section>

        <section className="border-t border-line bg-surface">
          <div className="mx-auto max-w-6xl px-4 py-14 sm:px-6">
            <h2 className="text-2xl font-semibold tracking-tight">{y.how}</h2>
            <ol className="mt-10 space-y-16">
              {guide.steps.map((s, n) => (
                <li key={s.title} className="grid items-center gap-8 md:grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)]">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={stepImage(seed, lang, n + 1)}
                    alt={`${y.step} ${n + 1}: ${s.title}`}
                    loading="lazy"
                    className={`w-full rounded-xl border border-line shadow-lg shadow-black/5 ${n % 2 ? "md:order-2" : ""}`}
                  />
                  <div>
                    <span className="inline-grid size-9 place-items-center rounded-full bg-accent font-semibold text-on-accent">
                      {n + 1}
                    </span>
                    <h3 className="mt-4 text-xl font-semibold">{s.title}</h3>
                    <p className="mt-2 leading-relaxed text-muted text-pretty">{s.text}</p>
                  </div>
                </li>
              ))}
            </ol>
            <p className="mt-16 max-w-3xl rounded-xl border border-line bg-canvas p-5 text-sm leading-relaxed">{y.studio}</p>
          </div>
        </section>

        <nav className="mx-auto flex max-w-6xl justify-between gap-4 px-4 py-10 sm:px-6" aria-label={y.back}>
          <a href={demoPath(lang, prev.seed)} className="group flex flex-col text-sm">
            <span className="text-muted">{y.previous}</span>
            <span className="inline-flex items-center gap-1.5 font-medium group-hover:text-accent">
              <ArrowLeft className="size-4" aria-hidden />
              {nameOf(prev.seed)}
            </span>
          </a>
          <a href={demoPath(lang, next.seed)} className="group flex flex-col items-end text-right text-sm">
            <span className="text-muted">{y.next}</span>
            <span className="inline-flex items-center gap-1.5 font-medium group-hover:text-accent">
              {nameOf(next.seed)}
              <ArrowRight className="size-4" aria-hidden />
            </span>
          </a>
        </nav>
      </main>
      <SiteFooter lang={lang} t={t} />
    </>
  );
}
