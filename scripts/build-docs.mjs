#!/usr/bin/env node
// Genera los PDF del manual y del dossier, en español e inglés, imprimiendo
// las páginas de la landing con Chrome sin ventana.
//
//   node scripts/build-docs.mjs              # compila la landing y genera los PDF
//   node scripts/build-docs.mjs --no-build   # usa la compilación que ya hay
//
// Antes, si hay capturas nuevas en PNG en landing/public/manual (las deja
// `DMS_SCREENSHOTS=1 flutter test test/manual_screenshots_test.dart` en
// studio/), las pasa a JPEG de 1600 px (con sips, en macOS).
//
// Salida: landing/public/docs/DMarlonStudio-{Manual,Dossier}-{es,en}.pdf
import { execFileSync, spawn } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, rmSync, statSync } from "node:fs";
import { createServer } from "node:net";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const landing = join(root, "landing");
const out = join(landing, "public", "docs");
const build = !process.argv.includes("--no-build");

const PAGES = [
  ["/manual/imprimir", "DMarlonStudio-Manual-es.pdf"],
  ["/en/manual/print", "DMarlonStudio-Manual-en.pdf"],
  ["/dosier", "DMarlonStudio-Dossier-es.pdf"],
  ["/en/dossier", "DMarlonStudio-Dossier-en.pdf"],
];

function chrome() {
  const candidates = [
    process.env.CHROME,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  ].filter(Boolean);
  const found = candidates.find((c) => existsSync(c));
  if (!found) throw new Error("No se encontró Chrome ni Chromium (ruta en la variable CHROME).");
  return found;
}

/** PNG nuevos de las capturas → JPEG de 1600 px. */
function optimizeShots() {
  const dir = join(landing, "public", "manual");
  if (!existsSync(dir)) return;
  for (const lang of readdirSync(dir)) {
    const sub = join(dir, lang);
    if (!statSync(sub).isDirectory()) continue;
    for (const f of readdirSync(sub).filter((f) => f.endsWith(".png"))) {
      const png = join(sub, f);
      const jpg = png.replace(/\.png$/, ".jpg");
      if (process.platform !== "darwin") {
        console.warn(`Sin sips (solo macOS): convierta ${png} a JPEG a mano.`);
        continue;
      }
      execFileSync("sips", ["-s", "format", "jpeg", "-s", "formatOptions", "82", "-Z", "1600", png, "--out", jpg], {
        stdio: "ignore",
      });
      rmSync(png);
      console.log(`captura: ${lang}/${f.replace(/\.png$/, ".jpg")}`);
    }
  }
}

function freePort() {
  return new Promise((resolve, reject) => {
    const s = createServer();
    s.listen(0, () => {
      const { port } = s.address();
      s.close(() => resolve(port));
    });
    s.on("error", reject);
  });
}

async function waitFor(url, ms = 60000) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    try {
      const r = await fetch(url);
      if (r.ok) return;
    } catch {
      // Aún arrancando.
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`El servidor no respondió en ${url}`);
}

optimizeShots();

if (build) {
  console.log("Compilando la landing…");
  execFileSync("npm", ["run", "build"], { cwd: landing, stdio: "inherit" });
}

const port = await freePort();
const next = join(landing, "node_modules", ".bin", "next");
const server = spawn(next, ["start", "-p", String(port)], { cwd: landing, stdio: "ignore" });
const base = `http://127.0.0.1:${port}`;

try {
  await waitFor(base);
  mkdirSync(out, { recursive: true });
  const browser = chrome();
  for (const [path, file] of PAGES) {
    const target = join(out, file);
    execFileSync(
      browser,
      [
        "--headless=new",
        "--disable-gpu",
        "--no-first-run",
        "--no-pdf-header-footer",
        "--print-to-pdf-no-header",
        "--run-all-compositor-stages-before-draw",
        "--virtual-time-budget=20000",
        `--print-to-pdf=${target}`,
        `${base}${path}`,
      ],
      { stdio: "ignore" },
    );
    let pages = "";
    try {
      pages = execFileSync("pdfinfo", [target]).toString().match(/Pages:\s+(\d+)/)?.[1] ?? "";
    } catch {
      // pdfinfo es opcional.
    }
    const kb = Math.round(statSync(target).size / 1024);
    console.log(`${file}: ${pages ? `${pages} páginas, ` : ""}${kb} KB`);
  }
} finally {
  server.kill();
}
