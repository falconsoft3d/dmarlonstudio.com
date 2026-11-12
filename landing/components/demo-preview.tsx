"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/**
 * La vista previa de las demos: al pulsar la captura de una tarjeta se abre
 * en grande, con sus cuatro capturas (la demo y los tres pasos de su guía) y
 * flechas para pasar a la demo anterior o a la siguiente (también con ← → del
 * teclado y deslizando en el móvil). Lee las tarjetas de la página (cada
 * captura lleva data-preview) y se salta las que esconde el filtro.
 * ⌘/Ctrl + clic sigue abriendo la página de la demo.
 */
type Item = { id: string; base: string; title: string; text: string; href: string; tech: string; steps: string[] };

/** ?ver=<demo> en la dirección: abre la vista previa en esa demo (para compartirla). */
const PARAM = "ver";

function setParam(id: string | null) {
  const url = new URL(window.location.href);
  if (id) url.searchParams.set(PARAM, id);
  else url.searchParams.delete(PARAM);
  window.history.replaceState(null, "", url);
}

const visibleCards = () =>
  Array.from(document.querySelectorAll<HTMLElement>("[data-preview]")).filter((x) => !x.closest("[hidden]"));

export type PreviewLabels = {
  prev: string;
  next: string;
  close: string;
  open: string;
  demo: string;
  hint: string;
};

function read(el: HTMLElement): Item {
  let steps: string[] = [];
  try {
    steps = JSON.parse(el.dataset.previewSteps ?? "[]");
  } catch {
    steps = [];
  }
  return {
    id: el.closest("li")?.id ?? "",
    base: el.dataset.preview ?? "",
    title: el.dataset.previewTitle ?? "",
    text: el.dataset.previewText ?? "",
    href: el.getAttribute("href") ?? "#",
    tech: el.dataset.previewTech ?? "",
    steps,
  };
}

const shotsOf = (it: Item) => [`${it.base}.jpg`, `${it.base}-1.jpg`, `${it.base}-2.jpg`, `${it.base}-3.jpg`];

function Arrow({ dir }: { dir: "left" | "right" }) {
  return (
    <svg viewBox="0 0 24 24" className="size-6" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      {dir === "left" ? <path d="m15 18-6-6 6-6" /> : <path d="m9 18 6-6-6-6" />}
    </svg>
  );
}

export function DemoPreview({ labels }: { labels: PreviewLabels }) {
  const [items, setItems] = useState<Item[]>([]);
  const [index, setIndex] = useState(-1);
  const [shot, setShot] = useState(0);
  const closeRef = useRef<HTMLButtonElement>(null);
  const opener = useRef<HTMLElement | null>(null);
  const touchX = useRef<number | null>(null);
  const open = index >= 0 && index < items.length;
  const item = open ? items[index] : null;

  const go = useCallback(
    (d: number) => {
      if (items.length === 0) return;
      setIndex((i) => (i + d + items.length) % items.length);
      setShot(0);
    },
    [items.length],
  );

  const close = useCallback(() => {
    setIndex(-1);
    setParam(null);
    opener.current?.focus();
  }, []);

  // Pulsar una captura abre la vista previa (con las tarjetas que se ven).
  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      const el = (e.target as HTMLElement).closest<HTMLElement>("[data-preview]");
      if (!el) return;
      const all = visibleCards();
      const i = all.indexOf(el);
      if (i < 0) return;
      e.preventDefault();
      opener.current = el;
      setItems(all.map(read));
      setIndex(i);
      setShot(0);
    };
    document.addEventListener("click", onClick);
    // Abierta desde un enlace con ?ver=<demo>.
    // (Después de pintar: el filtro ya ha escondido lo que no toca.)
    const wanted = new URLSearchParams(window.location.search).get(PARAM);
    const frame = window.requestAnimationFrame(() => {
      if (!wanted) return;
      const all = visibleCards();
      const i = all.findIndex((x) => x.closest("li")?.id === wanted);
      if (i >= 0) {
        setItems(all.map(read));
        setIndex(i);
      }
    });
    return () => {
      document.removeEventListener("click", onClick);
      window.cancelAnimationFrame(frame);
    };
  }, []);

  // La dirección dice qué demo se ve.
  useEffect(() => {
    if (index >= 0 && index < items.length) setParam(items[index].id);
  }, [index, items]);

  // Teclado, la página quieta detrás y el foco en el botón de cerrar.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") close();
      else if (e.key === "ArrowLeft") go(-1);
      else if (e.key === "ArrowRight") go(1);
      else if (e.key === "ArrowDown") setShot((s) => (s + 1) % 4);
      else if (e.key === "ArrowUp") setShot((s) => (s + 3) % 4);
      else return;
      e.preventDefault();
    };
    window.addEventListener("keydown", onKey);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    closeRef.current?.focus();
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = overflow;
    };
  }, [open, go, close]);

  // Las capturas de la demo anterior y de la siguiente, ya cargadas.
  useEffect(() => {
    if (!open || items.length < 2) return;
    for (const d of [-1, 1]) {
      const it = items[(index + d + items.length) % items.length];
      const img = new Image();
      img.src = `${it.base}.jpg`;
    }
  }, [open, index, items]);

  if (!item) return null;
  const shots = shotsOf(item);
  const captions = [labels.demo, ...item.steps];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={item.title}
      className="fixed inset-0 z-[60] flex flex-col bg-black/90 text-white backdrop-blur-sm"
      onClick={(e) => {
        if (e.target === e.currentTarget) close();
      }}
      onTouchStart={(e) => {
        touchX.current = e.touches[0]?.clientX ?? null;
      }}
      onTouchEnd={(e) => {
        const x0 = touchX.current;
        const x1 = e.changedTouches[0]?.clientX;
        touchX.current = null;
        if (x0 == null || x1 == null || Math.abs(x1 - x0) < 50) return;
        go(x1 < x0 ? 1 : -1);
      }}
    >
      {/* Arriba: cuál es, su tecnología y cerrar. */}
      <div className="flex items-center gap-3 px-4 py-3 sm:px-6">
        <span className="text-sm tabular-nums text-white/70">
          {index + 1} / {items.length}
        </span>
        {item.tech && <span className="rounded-full bg-white/10 px-2.5 py-0.5 text-xs font-medium text-white/85">{item.tech}</span>}
        <span className="hidden flex-1 text-center text-xs text-white/50 md:block">{labels.hint}</span>
        <button
          ref={closeRef}
          type="button"
          onClick={close}
          aria-label={labels.close}
          className="ml-auto grid size-10 place-items-center rounded-full bg-white/10 transition-colors hover:bg-white/20"
        >
          <svg viewBox="0 0 24 24" className="size-5" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden>
            <path d="M18 6 6 18M6 6l12 12" />
          </svg>
        </button>
      </div>

      {/* La captura, con las flechas para cambiar de demo. */}
      <div className="relative flex min-h-0 w-full flex-1 items-center justify-center overflow-hidden px-2 sm:px-20">
        <button
          type="button"
          onClick={() => go(-1)}
          aria-label={labels.prev}
          className="absolute left-2 z-10 grid size-11 place-items-center rounded-full bg-black/60 ring-1 ring-white/25 shadow-lg transition-colors hover:bg-black/85 sm:left-5 sm:size-12"
        >
          <Arrow dir="left" />
        </button>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          key={shots[shot]}
          src={shots[shot]}
          alt={`${item.title}: ${captions[shot] ?? ""}`}
          className="max-h-full min-w-0 max-w-full rounded-lg object-contain shadow-2xl ring-1 ring-white/10"
        />
        <button
          type="button"
          onClick={() => go(1)}
          aria-label={labels.next}
          className="absolute right-2 z-10 grid size-11 place-items-center rounded-full bg-black/60 ring-1 ring-white/25 shadow-lg transition-colors hover:bg-black/85 sm:right-5 sm:size-12"
        >
          <Arrow dir="right" />
        </button>
      </div>

      {/* Abajo: qué es, sus cuatro capturas y su página. */}
      <div className="mx-auto w-full max-w-5xl px-4 pt-3 pb-5 sm:px-6">
        <div className="flex flex-wrap items-baseline gap-x-4 gap-y-1">
          <h2 className="text-lg font-semibold">{item.title}</h2>
          <a href={item.href} className="text-sm font-medium text-emerald-300 hover:underline">
            {labels.open} →
          </a>
        </div>
        <p className="mt-1 line-clamp-2 text-sm text-white/70">{item.text}</p>
        <ul className="mt-3 grid grid-cols-4 gap-2 sm:gap-3">
          {shots.map((src, k) => (
            <li key={src}>
              <button
                type="button"
                onClick={() => setShot(k)}
                aria-pressed={shot === k}
                className={`block w-full overflow-hidden rounded-md text-left ring-2 transition ${
                  shot === k ? "ring-emerald-400" : "ring-transparent opacity-60 hover:opacity-100"
                }`}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={src} alt="" loading="lazy" className="aspect-[16/10] w-full object-cover object-top" />
                <span className="block truncate bg-white/5 px-2 py-1 text-[11px] text-white/80">{captions[k] ?? ""}</span>
              </button>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
