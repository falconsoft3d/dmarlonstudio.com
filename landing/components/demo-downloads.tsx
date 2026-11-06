"use client";

import { Download } from "lucide-react";
import { useVisitorPlatform } from "@/components/downloads";
import { PlatformIcon } from "@/components/platform-icon";
import { demoUrl, type DemoOs } from "@/lib/demos";
import type { Platform } from "@/lib/downloads";
import type { Lang } from "@/lib/i18n";

const SYSTEMS: { os: DemoOs; platform: Platform }[] = [
  { os: "macOS", platform: "macos" },
  { os: "Windows", platform: "windows" },
];

/** Los dos botones de descarga de una demo; el del sistema del visitante, destacado. */
export function DemoDownloads({ seed, lang, label }: { seed: string; lang: Lang; label: string }) {
  const visitor = useVisitorPlatform();
  return (
    <div className="mt-5 grid grid-cols-2 gap-2">
      {SYSTEMS.map(({ os, platform }) => (
        <a
          key={os}
          href={demoUrl(seed, lang, os)}
          aria-label={`${label} ${os}`}
          className={`inline-flex items-center justify-center gap-1.5 rounded-md px-3 py-2 text-sm font-medium transition-colors ${
            visitor === platform
              ? "bg-accent text-on-accent hover:bg-accent-strong"
              : "border border-line bg-soft text-ink hover:border-accent hover:text-accent"
          }`}
        >
          <PlatformIcon platform={platform} className="size-4" />
          {os}
          <Download className="size-3.5 opacity-70" aria-hidden />
        </a>
      ))}
    </div>
  );
}
