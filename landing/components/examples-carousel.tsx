"use client";

import { ChevronLeft, ChevronRight, Pause, Play } from "lucide-react";
import { useCallback, useEffect, useState, useSyncExternalStore } from "react";
import type { Content } from "@/content/types";
import type { Lang } from "@/lib/i18n";

const DELAY = 5000;

function subscribeMotion(fn: () => void) {
  const m = window.matchMedia("(prefers-reduced-motion: reduce)");
  m.addEventListener("change", fn);
  return () => m.removeEventListener("change", fn);
}

const reducedMotion = () =>
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/**
 * Carrusel de la portada: capturas reales del estudio con cada ejemplo
 * abierto en el Diseñador. Avanza solo (salvo con «reducir movimiento»),
 * se pausa al pasar el ratón o con su botón, y se maneja con las flechas.
 */
export function ExamplesCarousel({
  lang,
  t,
}: {
  lang: Lang;
  t: Content["examples"];
}) {
  const items = t.items;
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const [hover, setHover] = useState(false);
  const reduced = useSyncExternalStore(subscribeMotion, reducedMotion, () => true);
  const go = useCallback(
    (i: number) => setIndex((i + items.length) % items.length),
    [items.length],
  );

  useEffect(() => {
    if (paused || hover || reduced) return;
    const id = window.setTimeout(() => go(index + 1), DELAY);
    return () => window.clearTimeout(id);
  }, [index, paused, hover, reduced, go]);

  const current = items[index];
  return (
    <figure
      className="relative min-w-0"
      aria-roledescription="carousel"
      aria-label={t.label}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      onFocus={() => setHover(true)}
      onBlur={() => setHover(false)}
      onKeyDown={(e) => {
        if (e.key === "ArrowRight") go(index + 1);
        if (e.key === "ArrowLeft") go(index - 1);
      }}
    >
      <div className="relative aspect-[1360/860] overflow-hidden rounded-xl border border-line bg-ide-panel shadow-2xl shadow-black/10 dark:shadow-black/40">
        {items.map((it, i) => (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            key={it.seed}
            src={`/examples/${lang}/${it.seed}.jpg`}
            alt={`${it.name}: ${it.text}`}
            width={1360}
            height={860}
            loading={i === 0 ? "eager" : "lazy"}
            aria-hidden={i !== index}
            className={`absolute inset-0 h-full w-full object-cover object-left-top transition-opacity duration-700 ${
              i === index ? "opacity-100" : "opacity-0"
            }`}
          />
        ))}
        <button
          type="button"
          onClick={() => go(index - 1)}
          aria-label={t.previous}
          className="absolute top-1/2 left-2 -translate-y-1/2 rounded-full border border-line bg-surface/90 p-1.5 text-ink shadow transition-colors hover:bg-surface"
        >
          <ChevronLeft className="size-4" aria-hidden />
        </button>
        <button
          type="button"
          onClick={() => go(index + 1)}
          aria-label={t.next}
          className="absolute top-1/2 right-2 -translate-y-1/2 rounded-full border border-line bg-surface/90 p-1.5 text-ink shadow transition-colors hover:bg-surface"
        >
          <ChevronRight className="size-4" aria-hidden />
        </button>
      </div>
      <figcaption className="mt-4 flex items-start gap-3">
        <div className="min-w-0 flex-1" aria-live={paused || hover ? "polite" : "off"}>
          <p className="font-medium">
            {current.name}{" "}
            <span className="text-sm font-normal text-muted">
              · {index + 1}/{items.length}
            </span>
          </p>
          <p className="text-sm text-muted">{current.text}</p>
        </div>
        {!reduced && (
          <button
            type="button"
            onClick={() => setPaused((p) => !p)}
            aria-label={paused ? t.play : t.pause}
            title={paused ? t.play : t.pause}
            className="rounded-md border border-line p-1.5 text-muted transition-colors hover:bg-soft hover:text-ink"
          >
            {paused ? <Play className="size-4" aria-hidden /> : <Pause className="size-4" aria-hidden />}
          </button>
        )}
      </figcaption>
      <div className="mt-3 flex flex-wrap gap-1.5">
        {items.map((it, i) => (
          <button
            key={it.seed}
            type="button"
            onClick={() => go(i)}
            aria-label={`${t.goTo}: ${it.name}`}
            aria-current={i === index}
            className={`h-1.5 rounded-full transition-all ${
              i === index ? "w-6 bg-accent" : "w-1.5 bg-line hover:bg-muted"
            }`}
          />
        ))}
      </div>
    </figure>
  );
}
