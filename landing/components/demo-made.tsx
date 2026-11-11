import { FileCode2 } from "lucide-react";
import { codeToHtml } from "shiki";
import { ideImage, MADE, type MadeStep } from "@/content/demo-made";
import type { Lang } from "@/lib/i18n";

const TEXT = {
  es: {
    title: "Cómo se hizo",
    shot: "Captura de DMarlon Studio",
    sheet: "Ficha técnica",
    language: "Lenguaje",
    target: "Tecnología",
    components: "Componentes del Diseñador",
    name: "Nombre",
    kind: "Componente",
    use: "Para qué",
    apis: "Bibliotecas y APIs",
  },
  en: {
    title: "How it was made",
    shot: "DMarlon Studio screenshot",
    sheet: "Technical sheet",
    language: "Language",
    target: "Technology",
    components: "Designer components",
    name: "Name",
    kind: "Component",
    use: "What for",
    apis: "Libraries and APIs",
  },
} satisfies Record<Lang, unknown>;

/** El lenguaje del resaltado según el archivo del fragmento. */
function shikiLang(file: string) {
  const ext = file.split(".").pop() ?? "";
  return (
    { pas: "pascal", cpp: "cpp", h: "cpp", py: "python", js: "javascript", jsx: "jsx", dart: "dart", go: "go" }[ext] ??
    "text"
  );
}

/** Un fragmento de código, resaltado al compilar la web (como en los cursos). */
async function Code({ file, text }: NonNullable<MadeStep["code"]>) {
  const html = await codeToHtml(text, { lang: shikiLang(file), theme: "dark-plus" });
  return (
    <section className="overflow-hidden rounded-xl border border-line bg-[#1e1e1e] text-[#d4d4d4]">
      <h4 className="flex items-center gap-2 border-b border-white/10 bg-[#252528] px-4 py-2 font-mono text-xs text-[#a8a8b0]">
        <FileCode2 className="size-3.5" aria-hidden />
        {file}
      </h4>
      <div
        className="overflow-x-auto px-4 py-3 font-mono text-[13px] leading-relaxed [&_pre]:!bg-transparent"
        dangerouslySetInnerHTML={{ __html: html }}
      />
    </section>
  );
}

/** «Cómo se hizo»: los pasos en el estudio, con capturas del IDE y el código. */
export async function DemoMade({ lang, seed, name }: { lang: Lang; seed: string; name: string }) {
  const made = MADE[lang][seed];
  if (!made) return null;
  const y = TEXT[lang];
  return (
    <section className="border-t border-line">
      <div className="mx-auto max-w-6xl px-4 py-14 sm:px-6">
        <h2 className="text-2xl font-semibold tracking-tight">{y.title}</h2>
        <p className="mt-3 max-w-3xl leading-relaxed text-muted text-pretty">{made.intro}</p>
        <div className="mt-8 rounded-xl border border-line bg-surface p-5 sm:p-6">
          <h3 className="text-lg font-semibold">{y.sheet}</h3>
          <dl className="mt-4 grid gap-x-6 gap-y-3 text-sm sm:grid-cols-[10rem_minmax(0,1fr)]">
            <dt className="font-medium text-muted">{y.language}</dt>
            <dd>{made.tech.language}</dd>
            <dt className="font-medium text-muted">{y.target}</dt>
            <dd>{made.tech.target}</dd>
            <dt className="font-medium text-muted">{y.apis}</dt>
            <dd>
              <ul className="space-y-1">
                {made.tech.apis.map((a) => (
                  <li key={a} className="flex gap-2">
                    <span className="mt-2 size-1.5 shrink-0 rounded-full bg-accent" aria-hidden />
                    {a}
                  </li>
                ))}
              </ul>
            </dd>
          </dl>
          <h4 className="mt-6 text-sm font-medium text-muted">{y.components}</h4>
          <div className="mt-2 overflow-x-auto">
            <table className="w-full min-w-[32rem] text-left text-sm">
              <thead className="border-b border-line text-xs tracking-wide text-muted uppercase">
                <tr>
                  <th className="py-2 pr-4 font-medium">{y.name}</th>
                  <th className="py-2 pr-4 font-medium">{y.kind}</th>
                  <th className="py-2 font-medium">{y.use}</th>
                </tr>
              </thead>
              <tbody>
                {made.tech.components.map((c) => (
                  <tr key={c.name} className="border-b border-line last:border-0 align-top">
                    <td className="py-2 pr-4 font-mono text-[13px]">{c.name}</td>
                    <td className="py-2 pr-4">{c.kind}</td>
                    <td className="py-2 text-muted">{c.text}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
        <ol className="mt-10 space-y-14">
          {made.steps.map((s) => (
            <li key={s.title} className="grid items-start gap-8 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.2fr)]">
              <div>
                <h3 className="text-xl font-semibold">{s.title}</h3>
                <p className="mt-2 leading-relaxed text-muted text-pretty">{s.text}</p>
              </div>
              <div className="min-w-0 space-y-4">
                {s.shot && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={ideImage(seed, lang, s.shot)}
                    alt={`${y.shot}: ${name} · ${s.title}`}
                    loading="lazy"
                    className="w-full rounded-xl border border-line shadow-lg shadow-black/5"
                  />
                )}
                {s.code && <Code {...s.code} />}
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
