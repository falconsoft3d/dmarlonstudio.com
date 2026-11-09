/**
 * Demos descargables: utilidades de ejemplo del estudio compiladas para macOS
 * y Windows por .github/workflows/demos.yml (studio/test/demos_export_test.dart
 * + scripts/build_demos.py) y publicadas en la release de etiqueta `demos`.
 * La lista debe coincidir con la de demos_export_test.dart; sus textos están
 * en components/demos.tsx y sus capturas (la ventana de la app de verdad), en
 * public/demos/<idioma>/<ejemplo>.jpg.
 */
import { REPO_URL } from "@/lib/downloads";
import { PATHS, type Lang } from "@/lib/i18n";

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
  "mp3_player",
  "train_monitor",
  "pascal_odoo",
  "cpp_explorer",
  "cpp_racing",
  "cpp_image_editor",
  "cpp_flights",
  "cpp_hardware",
  "pascal_malecon",
  "domino",
] as const;

export type DemoSeed = (typeof DEMO_SEEDS)[number];

/** Apps móviles de Flutter: se prueban en el navegador y se instalan en Android (APK). */
export const MOBILE_SEEDS = ["flutter_store", "flutter_shipping", "flutter_todo"] as const;

/** Webs: la misma tienda en HTML, React y Vue, abiertas aquí mismo. */
export const WEB_SEEDS = ["html_store", "react_store", "vue_store", "html_domino", "next_world"] as const;

export type MobileSeed = (typeof MOBILE_SEEDS)[number];
export type WebSeed = (typeof WEB_SEEDS)[number];

/** La demo compilada para el navegador (scripts/build_live_demos.py), en
 * public/demos/live; las de Next.js con servidor son rutas de la propia
 * landing (app/(live)). */
export const liveUrl = (seed: string, lang: Lang) =>
  seed.startsWith("next_") ? `/demos/live/${lang}/${seed}` : `/demos/live/${lang}/${seed}/index.html`;

/** El APK de Android de una demo móvil (lo compila GitHub Actions). */
export const apkUrl = (seed: string, lang: Lang) =>
  `${REPO_URL}/releases/download/${DEMOS_TAG}/${seed}-${lang}-Android.apk`;

/** El zip de una demo: una sola app con los dos idiomas (menú Idioma /
 * Language, scripts/demo-lang). */
export const demoFile = (seed: string, os: DemoOs) => `${seed}-${os}.zip`;

export const demoUrl = (seed: string, os: DemoOs) =>
  `${REPO_URL}/releases/download/${DEMOS_TAG}/${demoFile(seed, os)}`;

/** La captura de la demo abierta (la ventana de la aplicación). */
export const demoImage = (seed: string, lang: Lang) => `/demos/${lang}/${seed}.jpg`;

/** La página de una demo (cómo funciona, en tres pasos). */
export const demoPath = (lang: Lang, seed: string) => `${PATHS.demos[lang]}/${seed}`;

export const demoAlternates = (seed: string) => ({ es: demoPath("es", seed), en: demoPath("en", seed) });
