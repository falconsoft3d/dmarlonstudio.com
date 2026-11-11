import { FileCode2 } from "lucide-react";
import { codeToHtml } from "shiki";
import { ideImage, MADE, type MadeStep } from "@/content/demo-made";
import type { Lang } from "@/lib/i18n";

const TEXT = {
  es: { title: "Cómo se hizo", shot: "Captura de DMarlon Studio" },
  en: { title: "How it was made", shot: "DMarlon Studio screenshot" },
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
