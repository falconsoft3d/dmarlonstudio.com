"use client";

import { Moon, Sun } from "lucide-react";
import { useSyncExternalStore } from "react";

type Theme = "light" | "dark";

const KEY = "theme";

/** Textos del botón en el idioma de la página. */
export type ThemeLabels = { system: string; dark: string; light: string; change: string };

const media = () => window.matchMedia("(prefers-color-scheme: dark)");

/** El tema que se ve: el elegido o, sin elegir, el del sistema. */
function read(): Theme {
  try {
    const v = localStorage.getItem(KEY);
    if (v === "light" || v === "dark") return v;
  } catch {
    // Sin almacenamiento: el del sistema.
  }
  return media().matches ? "dark" : "light";
}

function apply(theme: Theme) {
  document.documentElement.setAttribute("data-theme", theme);
  try {
    localStorage.setItem(KEY, theme);
  } catch {
    // Sin almacenamiento, el tema dura lo que la página.
  }
}

const listeners = new Set<() => void>();

function subscribe(fn: () => void) {
  listeners.add(fn);
  // También si cambia el del sistema y no se ha elegido otro.
  const m = media();
  m.addEventListener("change", fn);
  return () => {
    listeners.delete(fn);
    m.removeEventListener("change", fn);
  };
}

/**
 * Interruptor claro / oscuro de la cabecera: cada clic pasa al contrario de
 * lo que se ve. Hasta el primer clic sigue el tema del sistema.
 */
export function ThemeToggle({ labels }: { labels: ThemeLabels }) {
  // En el servidor no se sabe: se pinta «claro» y se corrige al hidratar.
  const theme = useSyncExternalStore(subscribe, read, () => "light" as Theme);
  const next: Theme = theme === "dark" ? "light" : "dark";
  // Se muestra lo que hará el clic: la luna lleva al oscuro.
  const Icon = next === "dark" ? Moon : Sun;
  return (
    <button
      type="button"
      onClick={() => {
        apply(next);
        listeners.forEach((fn) => fn());
      }}
      title={labels[next]}
      aria-label={`${labels.change}: ${labels[next]}`}
      aria-pressed={theme === "dark"}
      className="inline-flex size-8 items-center justify-center rounded-md border border-line text-ink transition-colors hover:bg-soft"
    >
      <Icon className="size-4" aria-hidden />
    </button>
  );
}

/** Aplica el tema guardado antes de pintar, para no ver un destello claro. */
export const themeScript = `try{var t=localStorage.getItem("${KEY}");if(t==="light"||t==="dark")document.documentElement.setAttribute("data-theme",t)}catch(e){}`;
