"use client";

import { Monitor, Moon, Sun } from "lucide-react";
import { useSyncExternalStore } from "react";

type Theme = "system" | "light" | "dark";

const KEY = "theme";
const NEXT: Record<Theme, Theme> = { system: "dark", dark: "light", light: "system" };
/** Textos del botón en el idioma de la página. */
export type ThemeLabels = { system: string; dark: string; light: string; change: string };

function read(): Theme {
  try {
    const v = localStorage.getItem(KEY);
    return v === "light" || v === "dark" ? v : "system";
  } catch {
    return "system";
  }
}

function apply(theme: Theme) {
  const root = document.documentElement;
  if (theme === "system") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", theme);
  try {
    if (theme === "system") localStorage.removeItem(KEY);
    else localStorage.setItem(KEY, theme);
  } catch {
    // Sin almacenamiento, el tema dura lo que la página.
  }
}

const listeners = new Set<() => void>();

function subscribe(fn: () => void) {
  listeners.add(fn);
  return () => {
    listeners.delete(fn);
  };
}

/** Botón de la cabecera: sistema → oscuro → claro. */
export function ThemeToggle({ labels }: { labels: ThemeLabels }) {
  // En el servidor no se sabe: se pinta «sistema» y se corrige al hidratar.
  const theme = useSyncExternalStore(subscribe, read, () => "system" as Theme);

  const Icon = theme === "dark" ? Moon : theme === "light" ? Sun : Monitor;
  return (
    <button
      type="button"
      onClick={() => {
        apply(NEXT[theme]);
        listeners.forEach((fn) => fn());
      }}
      title={labels[theme]}
      aria-label={`${labels[theme]}. ${labels.change}`}
      className="inline-flex size-8 items-center justify-center rounded-md text-muted transition-colors hover:bg-soft hover:text-ink"
    >
      <Icon className="size-4" aria-hidden />
    </button>
  );
}

/** Aplica el tema guardado antes de pintar, para no ver un destello claro. */
export const themeScript = `try{var t=localStorage.getItem("${KEY}");if(t==="light"||t==="dark")document.documentElement.setAttribute("data-theme",t)}catch(e){}`;
