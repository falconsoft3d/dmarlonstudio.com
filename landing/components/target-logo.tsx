import type React from "react";
import {
  siCplusplus,
  siElectron,
  siFlask,
  siGooglechrome,
  siLazarus,
  siMongodb,
  siMysql,
  siNextdotjs,
  siNodedotjs,
  siPostgresql,
  siPython,
  siSqlite,
} from "simple-icons";
import type { TargetIcon } from "@/content/types";

const ICONS: Record<TargetIcon, { path: string; hex: string }> = {
  python: siPython,
  flask: siFlask,
  electron: siElectron,
  chrome: siGooglechrome,
  next: siNextdotjs,
  cpp: siCplusplus,
  lazarus: siLazarus,
  node: siNodedotjs,
  sqlite: siSqlite,
  postgres: siPostgresql,
  mysql: siMysql,
  mongodb: siMongodb,
  // Una API REST: llaves { } (dibujo propio).
  api: {
    hex: "7AA2F7",
    path: "M8 3C5.8 3 5 4.3 5 6v2.6c0 1-.6 1.6-2 1.9v3c1.4.3 2 .9 2 1.9V18c0 1.7.8 3 3 3h1v-2.4H8.4c-.7 0-.9-.4-.9-1.1v-2.8c0-1.4-.6-2.3-1.8-2.7 1.2-.4 1.8-1.3 1.8-2.7V6.5c0-.7.2-1.1.9-1.1H9V3H8zm8 0h-1v2.4h.6c.7 0 .9.4.9 1.1v2.8c0 1.4.6 2.3 1.8 2.7-1.2.4-1.8 1.3-1.8 2.7v2.8c0 .7-.2 1.1-.9 1.1H15V21h1c2.2 0 3-1.3 3-3v-2.6c0-1 .6-1.6 2-1.9v-3c-1.4-.3-2-.9-2-1.9V6c0-1.7-.8-3-3-3z",
  },
};

/** Color de la marca; los logotipos negros toman el color del texto (modo oscuro). */
export function targetColor(icon: TargetIcon): string | undefined {
  const hex = ICONS[icon].hex;
  return hex === "000000" ? undefined : `#${hex}`;
}

/** Logotipo de un entorno (Simple Icons, CC0), en el color de su marca. */
export function TargetLogo({ icon, className = "size-5" }: { icon: TargetIcon; className?: string }) {
  const color = targetColor(icon);
  return (
    <svg
      viewBox="0 0 24 24"
      className={`${className} ${color ? "brand-logo" : ""}`}
      aria-hidden
      fill={color ?? "currentColor"}
      style={color ? ({ "--brand": color } as React.CSSProperties) : undefined}
    >
      <path d={ICONS[icon].path} />
    </svg>
  );
}

/** El logotipo dentro de un cuadrado con un fondo suave de su color. */
export function TargetBadge({
  icon,
  size = "size-10",
  logo = "size-5",
}: {
  icon: TargetIcon;
  size?: string;
  logo?: string;
}) {
  const color = targetColor(icon);
  return (
    <span
      className={`grid shrink-0 place-items-center rounded-xl ${size} ${color ? "" : "bg-soft text-ink"}`}
      style={color ? { backgroundColor: `${color}1f` } : undefined}
    >
      <TargetLogo icon={icon} className={logo} />
    </span>
  );
}
