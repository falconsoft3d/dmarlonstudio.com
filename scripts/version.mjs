#!/usr/bin/env node
// Versión única de DMarlon Studio. Uso:
//   node scripts/version.mjs            → muestra la versión actual
//   node scripts/version.mjs 1.0.2      → la cambia en todas partes
//   node scripts/version.mjs patch      → 1.0.1 → 1.0.2 (también minor, major)
//
// Escribe VERSION y la copia a studio/pubspec.yaml (con el número de
// compilación +1), studio/lib/version.dart, landing/package.json y
// landing/lib/version.ts. Añada después la entrada en CHANGELOG.md.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const file = (p) => join(root, p);
const current = readFileSync(file("VERSION"), "utf8").trim();
const arg = process.argv[2];

if (!arg) {
  console.log(current);
  process.exit(0);
}

const [ma, mi, pa] = current.split(".").map(Number);
const next =
  arg === "patch" ? `${ma}.${mi}.${pa + 1}`
  : arg === "minor" ? `${ma}.${mi + 1}.0`
  : arg === "major" ? `${ma + 1}.0.0`
  : arg;
if (!/^\d+\.\d+\.\d+$/.test(next)) {
  console.error(`Versión no válida: ${next}`);
  process.exit(1);
}

const edit = (p, fn) => writeFileSync(file(p), fn(readFileSync(file(p), "utf8")));

writeFileSync(file("VERSION"), `${next}\n`);
edit("studio/pubspec.yaml", (s) =>
  s.replace(/^version: (\S+?)\+(\d+)$/m, (_, _v, build) => `version: ${next}+${Number(build) + 1}`),
);
edit("studio/lib/version.dart", (s) => s.replace(/appVersion = '[^']*'/, `appVersion = '${next}'`));
edit("landing/package.json", (s) => s.replace(/"version": "[^"]*"/, `"version": "${next}"`));
edit("landing/lib/version.ts", (s) => s.replace(/VERSION = "[^"]*"/, `VERSION = "${next}"`));
console.log(`${current} → ${next}`);
