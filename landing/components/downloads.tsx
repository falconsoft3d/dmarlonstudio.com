"use client";

import { useSyncExternalStore } from "react";
import { Download as DownloadIcon } from "lucide-react";
import { PlatformIcon } from "@/components/platform-icon";
import { DOWNLOADS, RELEASES_URL, type Platform } from "@/lib/downloads";

/** Sistema del visitante; en el servidor no se sabe (null). */
function useVisitorPlatform(): Platform | null {
  return useSyncExternalStore(
    () => () => {},
    () => {
      const ua = navigator.userAgent;
      if (/Windows/i.test(ua)) return "windows";
      if (/Macintosh|Mac OS X/i.test(ua) && !/iPhone|iPad/i.test(ua)) return "macos";
      if (/Linux/i.test(ua) && !/Android/i.test(ua)) return "linux";
      return null;
    },
    () => null,
  );
}

const NOTES: Record<Platform, { requirements: string; steps: string[] }> = {
  macos: {
    requirements: "macOS 10.15 o superior · Apple Silicon e Intel",
    steps: [
      "Descomprima el zip y mueva «DMarlon Studio» a Aplicaciones.",
      "La primera vez, haga clic derecho sobre la app → Abrir: la app aún no está firmada.",
      "Confirme «Abrir» en el aviso de desarrollador no identificado.",
    ],
  },
  windows: {
    requirements: "Windows 10 u 11 de 64 bits",
    steps: [
      "Descomprima la carpeta completa (por ejemplo, en el Escritorio).",
      "Abra DMarlonStudio.exe.",
      "Si aparece «Windows protegió su PC», pulse «Más información» → «Ejecutar de todas formas».",
    ],
  },
  linux: {
    requirements: "Próximamente",
    steps: ["El paquete para Linux está en camino. Mientras tanto, puede compilarlo desde el código fuente con Flutter."],
  },
};

export function Downloads() {
  const visitor = useVisitorPlatform();
  return (
    <div className="grid gap-4 md:grid-cols-3">
      {DOWNLOADS.map((d) => {
        const mine = visitor === d.platform && d.url !== null;
        const notes = NOTES[d.platform];
        return (
          <article
            key={d.platform}
            className={`flex flex-col rounded-xl border bg-surface p-5 transition-shadow ${
              mine ? "border-accent shadow-lg shadow-accent/10 ring-1 ring-accent" : "border-line"
            }`}
          >
            <div className="flex items-center gap-3">
              <PlatformIcon platform={d.platform} className="size-7" />
              <h3 className="text-lg font-semibold">{d.label}</h3>
              {mine && (
                <span className="ml-auto rounded-full bg-accent/12 px-2 py-0.5 text-xs font-medium text-accent">
                  Su sistema
                </span>
              )}
            </div>
            <p className="mt-1 text-sm text-muted">{notes.requirements}</p>
            <ol className="mt-4 flex-1 list-decimal space-y-1.5 pl-5 text-sm text-muted marker:text-muted">
              {notes.steps.map((s) => (
                <li key={s}>{s}</li>
              ))}
            </ol>
            {d.url ? (
              <a
                href={d.url}
                className={`mt-5 inline-flex items-center justify-center gap-2 rounded-md px-4 py-2.5 text-sm font-medium transition-colors ${
                  mine
                    ? "bg-accent text-on-accent hover:bg-accent-strong"
                    : "border border-line bg-soft text-ink hover:border-accent hover:text-accent"
                }`}
              >
                <DownloadIcon className="size-4" aria-hidden />
                Descargar {d.file}
              </a>
            ) : (
              <span
                aria-disabled
                className="mt-5 inline-flex cursor-not-allowed items-center justify-center rounded-md border border-dashed border-line px-4 py-2.5 text-sm text-muted"
              >
                Próximamente
              </span>
            )}
          </article>
        );
      })}
      <p className="text-sm text-muted md:col-span-3">
        Requisito para ejecutar lo que diseñe: <strong className="text-ink">Python 3 con tkinter</strong> para las
        ventanas de escritorio y <strong className="text-ink">Flask</strong> para las aplicaciones web (
        <code className="font-mono text-xs">pip install flask</code>). El estudio detecta el Python instalado y le dice
        qué falta. Versiones anteriores y notas en{" "}
        <a href={RELEASES_URL} className="text-accent underline-offset-2 hover:underline">
          GitHub Releases
        </a>
        .
      </p>
    </div>
  );
}
