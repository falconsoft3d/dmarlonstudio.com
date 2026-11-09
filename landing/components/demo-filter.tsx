"use client";

import { useEffect, useSyncExternalStore } from "react";
import { TargetLogo } from "@/components/target-logo";
import type { TargetIcon } from "@/content/types";

/**
 * Filtrar las demos por lenguaje: oculta las tarjetas de los demás (cada
 * tarjeta lleva data-demo-lang) y las secciones que se quedan vacías. El
 * filtro va en la dirección (?tech=cpp) para poder compartirlo.
 */
const EVENT = "dms-demo-filter";

function subscribe(onChange: () => void) {
  window.addEventListener(EVENT, onChange);
  window.addEventListener("popstate", onChange);
  return () => {
    window.removeEventListener(EVENT, onChange);
    window.removeEventListener("popstate", onChange);
  };
}

const fromUrl = () => new URLSearchParams(window.location.search).get("tech") ?? "";

function choose(id: string) {
  const url = new URL(window.location.href);
  if (id) url.searchParams.set("tech", id);
  else url.searchParams.delete("tech");
  window.history.replaceState(null, "", url);
  window.dispatchEvent(new Event(EVENT));
}

export function DemoFilter({
  langs,
  all,
  label,
}: {
  langs: { id: TargetIcon; label: string; count: number }[];
  all: string;
  label: string;
}) {
  const wanted = useSyncExternalStore(subscribe, fromUrl, () => "");
  const current = langs.some((l) => l.id === wanted) ? wanted : "";

  useEffect(() => {
    document.querySelectorAll<HTMLElement>("[data-demo-lang]").forEach((card) => {
      card.hidden = current !== "" && card.dataset.demoLang !== current;
    });
    document.querySelectorAll<HTMLElement>("[data-demo-section]").forEach((section) => {
      const cards = Array.from(section.querySelectorAll<HTMLElement>("[data-demo-lang]"));
      section.hidden = cards.length > 0 && cards.every((c) => c.hidden);
    });
  }, [current]);

  const chip = (id: string, text: string, count: number, icon?: TargetIcon) => (
    <button
      key={id || "all"}
      type="button"
      onClick={() => choose(id)}
      aria-pressed={current === id}
      className={`inline-flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-1 text-sm font-medium transition-colors ${
        current === id
          ? "border-accent bg-accent text-white"
          : "border-line bg-canvas text-muted hover:border-accent hover:text-ink"
      }`}
    >
      {icon && <TargetLogo icon={icon} className="size-4" />}
      {text}
      <span className={current === id ? "text-white/80" : "text-muted"}>{count}</span>
    </button>
  );

  return (
    <div role="group" aria-label={label} className="flex items-center gap-2">
      <span className="shrink-0 text-sm text-muted">{label}</span>
      {chip("", all, langs.reduce((n, l) => n + l.count, 0))}
      {langs.map((l) => chip(l.id, l.label, l.count, l.id))}
    </div>
  );
}
