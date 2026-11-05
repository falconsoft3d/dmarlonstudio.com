import Image from "next/image";
import { Info, TriangleAlert } from "lucide-react";
import type { Block } from "@/content/manual";

/** Texto con **interfaz** y `código`. */
export function Inline({ text }: { text: string }) {
  const parts = text.split(/(\*\*[^*]+\*\*|`[^`]+`)/g);
  return (
    <>
      {parts.map((p, i) =>
        p.startsWith("**") && p.endsWith("**") ? (
          <strong key={i} className="font-semibold text-ink">
            {p.slice(2, -2)}
          </strong>
        ) : p.startsWith("`") && p.endsWith("`") ? (
          <code key={i} className="rounded bg-soft px-1 py-0.5 font-mono text-[0.88em] text-ink">
            {p.slice(1, -1)}
          </code>
        ) : (
          p
        ),
      )}
    </>
  );
}

/** Un bloque del manual. [print]: imágenes sin optimizar y cargadas ya. */
export function BlockView({ b, print = false }: { b: Block; print?: boolean }) {
  switch (b.type) {
    case "p":
      return (
        <p className="leading-relaxed text-muted text-pretty">
          <Inline text={b.text} />
        </p>
      );
    case "ul":
    case "ol": {
      const List = b.type === "ul" ? "ul" : "ol";
      return (
        <List
          className={`space-y-1.5 pl-5 leading-relaxed text-muted marker:text-accent ${
            b.type === "ul" ? "list-disc" : "list-decimal"
          }`}
        >
          {b.items.map((it, i) => (
            <li key={i} className="pl-1">
              <Inline text={it} />
            </li>
          ))}
        </List>
      );
    }
    case "table":
      return (
        <div className="overflow-x-auto rounded-lg border border-line print:overflow-visible">
          <table className="w-full border-collapse text-left text-sm">
            <thead className="bg-soft">
              <tr>
                {b.head.map((h) => (
                  <th key={h} className="px-3 py-2 font-semibold">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {b.rows.map((r, i) => (
                <tr key={i} className="border-t border-line align-top break-inside-avoid">
                  {r.map((c, j) => (
                    <td key={j} className={`px-3 py-2 ${j === 0 ? "" : "text-muted"}`}>
                      <Inline text={c} />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      );
    case "code":
      return (
        <pre className="overflow-x-auto rounded-lg border border-line bg-ide-panel p-4 font-mono text-[13px] leading-relaxed break-inside-avoid print:whitespace-pre-wrap">
          <code>{b.code}</code>
        </pre>
      );
    case "note": {
      const warn = b.tone === "warn";
      const Icon = warn ? TriangleAlert : Info;
      return (
        <div
          className={`flex gap-3 rounded-lg border p-4 text-sm leading-relaxed break-inside-avoid ${
            warn ? "border-warning/40 bg-warning/8" : "border-accent/30 bg-accent/6"
          }`}
        >
          <Icon className={`mt-0.5 size-4 shrink-0 ${warn ? "text-warning" : "text-accent"}`} aria-hidden />
          <p className="text-muted">
            <Inline text={b.text} />
          </p>
        </div>
      );
    }
    case "img":
      return (
        <figure className="break-inside-avoid">
          <Image
            src={b.src}
            alt={b.alt}
            width={1600}
            height={1000}
            sizes="(min-width: 1024px) 760px, 100vw"
            loading={print ? "eager" : "lazy"}
            unoptimized={print}
            className="h-auto w-full rounded-lg border border-line shadow-sm"
          />
          {b.caption && <figcaption className="mt-2 text-center text-sm text-muted">{b.caption}</figcaption>}
        </figure>
      );
  }
}
