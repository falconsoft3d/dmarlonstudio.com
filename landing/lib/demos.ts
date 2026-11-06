/**
 * Demos descargables: utilidades de ejemplo del estudio compiladas para macOS
 * y Windows por .github/workflows/demos.yml (studio/test/demos_export_test.dart
 * + scripts/build_demos.py) y publicadas en la release de etiqueta `demos`.
 * La lista debe coincidir con la de demos_export_test.dart; sus textos están
 * en components/demos.tsx y sus capturas (la ventana de la app de verdad), en
 * public/demos/<idioma>/<ejemplo>.jpg.
 */
import { REPO_URL } from "@/lib/downloads";
import type { Lang } from "@/lib/i18n";

export const DEMOS_TAG = "demos";
export const DEMOS_RELEASE_URL = `${REPO_URL}/releases/tag/${DEMOS_TAG}`;

export type DemoOs = "macOS" | "Windows";

export const DEMO_SEEDS = [
  "calculator",
  "notepad",
  "pdf_editor",
  "disk_usage",
  "port_scanner",
  "investor",
  "pos",
  "agenda",
  "currency",
  "file_renamer",
] as const;

export type DemoSeed = (typeof DEMO_SEEDS)[number];

/** El zip de una demo, en el idioma de la página. */
export const demoFile = (seed: string, lang: Lang, os: DemoOs) => `${seed}-${lang}-${os}.zip`;

export const demoUrl = (seed: string, lang: Lang, os: DemoOs) =>
  `${REPO_URL}/releases/download/${DEMOS_TAG}/${demoFile(seed, lang, os)}`;

/** La captura de la demo abierta (la ventana de la aplicación). */
export const demoImage = (seed: string, lang: Lang) => `/demos/${lang}/${seed}.jpg`;
