"use client";

import { ExternalLink, Play, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";

/**
 * «Probar»: la demo compilada para el navegador. Las móviles se abren dentro
 * de un teléfono (en pantallas estrechas, en una pestaña nueva); las webs, en
 * una pestaña nueva.
 */
export function LiveDemo({
  url,
  title,
  label,
  close,
  newTab,
  phone,
}: {
  url: string;
  title: string;
  label: string;
  close: string;
  newTab: string;
  phone: boolean;
}) {
  const [open, setOpen] = useState(false);
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open]);

  const button =
    "inline-flex items-center justify-center gap-1.5 rounded-md bg-accent px-3 py-2 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong";

  if (!phone) {
    return (
      <a href={url} target="_blank" rel="noopener" className={button}>
        <ExternalLink className="size-4" aria-hidden />
        {label}
      </a>
    );
  }
  return (
    <>
      <a
        href={url}
        target="_blank"
        rel="noopener"
        className={button}
        onClick={(e) => {
          // En un móvil, la app a pantalla completa; en un ordenador, en un teléfono.
          if (window.matchMedia("(min-width: 640px)").matches) {
            e.preventDefault();
            setOpen(true);
          }
        }}
      >
        <Play className="size-4" aria-hidden />
        {label}
      </a>
      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label={title}
          className="fixed inset-0 z-50 grid place-items-center bg-black/60 p-4 backdrop-blur-sm"
          onClick={(e) => e.target === e.currentTarget && setOpen(false)}
        >
          <div className="flex flex-col items-center gap-3">
            <div className="flex w-full items-center justify-between gap-4 text-white">
              <span className="font-medium">{title}</span>
              <span className="flex items-center gap-2">
                <a
                  href={url}
                  target="_blank"
                  rel="noopener"
                  title={newTab}
                  aria-label={newTab}
                  className="rounded-md p-1.5 text-white/80 hover:bg-white/10 hover:text-white"
                >
                  <ExternalLink className="size-4" aria-hidden />
                </a>
                <button
                  ref={closeRef}
                  type="button"
                  onClick={() => setOpen(false)}
                  aria-label={close}
                  title={close}
                  className="rounded-md p-1.5 text-white/80 hover:bg-white/10 hover:text-white"
                >
                  <X className="size-5" aria-hidden />
                </button>
              </span>
            </div>
            {/* El teléfono: 390 × 780 si cabe; si no, a la altura de la ventana. */}
            <div className="h-[min(780px,calc(100dvh-7rem))] aspect-[390/780] rounded-[2.6rem] border-[10px] border-neutral-900 bg-neutral-900 shadow-2xl ring-1 ring-white/10">
              <iframe src={url} title={title} className="h-full w-full rounded-[2rem] bg-white" />
            </div>
          </div>
        </div>
      )}
    </>
  );
}
