import type React from "react";
import {
  siCplusplus,
  siElectron,
  siFlutter,
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
  flutter: siFlutter,
  node: siNodedotjs,
  sqlite: siSqlite,
  postgres: siPostgresql,
  mysql: siMysql,
  mongodb: siMongodb,
  // FalconDatabase: un cilindro de base de datos (dibujo propio).
  falcon: {
    hex: "2B5FD9",
    path: "M12 2C7 2 3.5 3.6 3.5 5.6v12.8C3.5 20.4 7 22 12 22s8.5-1.6 8.5-3.6V5.6C20.5 3.6 17 2 12 2zm0 2c4 0 6.5 1.1 6.5 1.6S16 7.2 12 7.2 5.5 6.1 5.5 5.6 8 4 12 4zm6.5 14.4c0 .5-2.5 1.6-6.5 1.6s-6.5-1.1-6.5-1.6v-2.5c1.5.9 3.9 1.4 6.5 1.4s5-.5 6.5-1.4v2.5zm0-5c0 .5-2.5 1.6-6.5 1.6s-6.5-1.1-6.5-1.6v-2.5c1.5.9 3.9 1.4 6.5 1.4s5-.5 6.5-1.4v2.5zm0-5c0 .5-2.5 1.6-6.5 1.6S5.5 8.9 5.5 8.4V8c1.5.9 3.9 1.4 6.5 1.4s5-.5 6.5-1.4v.4z",
  },
  // Consola: un terminal con su indicador (dibujo propio).
  console: {
    hex: "4EC9B0",
    path: "M3 4h18a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1zm1 2v12h16V6H4zm2.3 2.3L9.9 12l-3.6 3.7-1.4-1.4L7.1 12 4.9 9.7l1.4-1.4zM11 14h6v2h-6v-2z",
  },
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
