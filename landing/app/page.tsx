import { ArrowRight, Download } from "lucide-react";
import { Downloads } from "@/components/downloads";
import { IdeMock } from "@/components/ide-mock";
import { Logo } from "@/components/logo";
import { SiteHeader } from "@/components/site-header";
import { hero, roadmap, sections, type Section, type Step } from "@/content/es";
import { REPO_URL, RELEASES_URL } from "@/lib/downloads";

function SectionBlock({ s, alt }: { s: Section; alt: boolean }) {
  return (
    <section id={s.id} className={`border-t border-line ${alt ? "bg-surface" : ""}`}>
      <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6 sm:py-20">
        <p className="text-sm font-medium text-accent">{s.eyebrow}</p>
        <h2 className="mt-2 max-w-2xl text-2xl font-semibold tracking-tight text-balance sm:text-3xl">{s.title}</h2>
        <p className="mt-3 max-w-2xl text-muted text-pretty">{s.intro}</p>
        <div className="mt-10 grid gap-x-8 gap-y-7 sm:grid-cols-2 lg:grid-cols-3">
          {s.features.map((f) => (
            <div key={f.title}>
              <h3 className="font-medium">{f.title}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-muted">{f.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

const STATUS: Record<Step["status"], { label: string; className: string }> = {
  listo: { label: "Disponible", className: "bg-success/12 text-success" },
  "en camino": { label: "En camino", className: "bg-accent/12 text-accent" },
  idea: { label: "Más adelante", className: "bg-soft text-muted" },
};

export default function Home() {
  return (
    <>
      <SiteHeader />
      <main id="inicio" className="flex-1">
        {/* Portada */}
        <section className="mx-auto grid max-w-6xl items-center gap-12 px-4 pt-14 pb-16 sm:px-6 lg:grid-cols-[1fr_1.15fr] lg:pt-20 lg:pb-24">
          <div>
            <p className="inline-flex items-center gap-2 rounded-full border border-line bg-surface px-3 py-1 text-xs font-medium text-muted">
              <span className="size-1.5 rounded-full bg-success" />
              {hero.eyebrow}
            </p>
            <h1 className="mt-5 text-4xl font-semibold tracking-tight text-balance sm:text-5xl">{hero.title}</h1>
            <p className="mt-5 text-lg leading-relaxed text-muted text-pretty">{hero.text}</p>
            <div className="mt-8 flex flex-wrap gap-3">
              <a
                href="#descargas"
                className="inline-flex items-center gap-2 rounded-md bg-accent px-5 py-2.5 font-medium text-on-accent transition-colors hover:bg-accent-strong"
              >
                <Download className="size-4" aria-hidden />
                {hero.primary}
              </a>
              <a
                href="#disenador"
                className="inline-flex items-center gap-2 rounded-md border border-line bg-surface px-5 py-2.5 font-medium transition-colors hover:border-accent hover:text-accent"
              >
                {hero.secondary}
                <ArrowRight className="size-4" aria-hidden />
              </a>
            </div>
            <ul className="mt-8 flex flex-wrap gap-2 text-sm" aria-label="Entornos">
              {hero.targets.map((t) => (
                <li key={t} className="rounded-md bg-soft px-2.5 py-1 font-mono text-xs text-muted">
                  {t}
                </li>
              ))}
            </ul>
          </div>
          <IdeMock />
        </section>

        {sections.map((s, i) => (
          <SectionBlock key={s.id} s={s} alt={i % 2 === 0} />
        ))}

        {/* Hoja de ruta */}
        <section id="hoja-de-ruta" className="border-t border-line bg-surface">
          <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6 sm:py-20">
            <p className="text-sm font-medium text-accent">Hoja de ruta</p>
            <h2 className="mt-2 text-2xl font-semibold tracking-tight sm:text-3xl">Un diseño, varios entornos</h2>
            <ol className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {roadmap.map((r) => (
                <li key={r.name} className="rounded-xl border border-line bg-canvas p-5">
                  <div className="flex items-center justify-between gap-2">
                    <h3 className="font-semibold">{r.name}</h3>
                    <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${STATUS[r.status].className}`}>
                      {STATUS[r.status].label}
                    </span>
                  </div>
                  <p className="mt-2 text-sm leading-relaxed text-muted">{r.text}</p>
                </li>
              ))}
            </ol>
          </div>
        </section>

        {/* Descargas */}
        <section id="descargas" className="border-t border-line">
          <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6 sm:py-20">
            <p className="text-sm font-medium text-accent">Descargas</p>
            <h2 className="mt-2 text-2xl font-semibold tracking-tight sm:text-3xl">Descargue DMarlon Studio</h2>
            <p className="mt-3 max-w-2xl text-muted">
              Gratis para macOS y Windows. Se compila automáticamente desde el repositorio con cada versión.
            </p>
            <div className="mt-10">
              <Downloads />
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-line bg-surface">
        <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-8 text-sm text-muted sm:flex-row sm:items-center sm:px-6">
          <div className="flex items-center gap-2">
            <Logo className="size-5" />
            <span>DMarlon Studio · © {new Date().getFullYear()} Marlon Falcón</span>
          </div>
          <nav aria-label="Enlaces" className="flex gap-5 sm:ml-auto">
            <a href={REPO_URL} className="hover:text-ink">
              GitHub
            </a>
            <a href={RELEASES_URL} className="hover:text-ink">
              Versiones
            </a>
            <a href="#descargas" className="hover:text-ink">
              Descargar
            </a>
          </nav>
        </div>
      </footer>
    </>
  );
}
