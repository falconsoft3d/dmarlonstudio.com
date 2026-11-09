// Los iconos de las demos (scripts/demo-icons/<ejemplo>.png, 1024×1024): un
// cuadrado redondeado con degradado y un símbolo blanco de Lucide (ISC,
// scripts/demo-icons/lucide). build_demos.py los convierte en .icns y .ico.
// Para cambiar uno: editar `demos` y volver a generarlos (hace falta Playwright):
//
//   PLAYWRIGHT_DIR=<carpeta con node_modules/playwright> node scripts/demo-icons/render.mjs [ejemplo ...]
//
// Con ejemplos, solo esos (los demás PNG no se tocan).
import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
const here = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(process.env.PLAYWRIGHT_DIR || here, 'node_modules', 'x.js'));
const { chromium } = require('playwright');
const dir = path.join(here, 'lucide'), out = here;
// seed: [icono de Lucide, color claro, color oscuro]
const demos = {
  agenda: ['calendar-days', '#ff7a59', '#e8433b'],
  calculator: ['calculator', '#7b8794', '#3e4c59'],
  cpp_explorer: ['folder-open', '#5aaef5', '#1c5fc6'],
  cpp_racing: ['flag', '#ff5a4f', '#c3141c'],
  pascal_malecon: ['flashlight', '#f08a5a', '#5a2a7a'],
  currency: ['coins', '#ffc53d', '#e08e0b'],
  disk_usage: ['hard-drive', '#5ac8fa', '#1f7fd6'],
  file_renamer: ['file-pen-line', '#a78bfa', '#6d3fd6'],
  investor: ['chart-candlestick', '#34d399', '#0f8a5f'],
  mp3_player: ['music', '#ff6b9d', '#d6246e'],
  notepad: ['notebook-pen', '#fcd34d', '#d9a400'],
  pascal_odoo: ['database-backup', '#a2708a', '#5a3a52'],
  pdf_editor: ['file-text', '#ff6b6b', '#c81e1e'],
  port_scanner: ['radar', '#2dd4bf', '#0b7f79'],
  pos: ['shopping-cart', '#60a5fa', '#1d4ed8'],
  train_monitor: ['train-front', '#4b5d7a', '#1c2a44'],
};
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
const only = process.argv.slice(2);
for (const [seed, [icon, a, b]] of Object.entries(demos)) {
  if (only.length && !only.includes(seed)) continue;
  const svg = fs.readFileSync(`${dir}/${icon}.svg`, 'utf8').replace(/<!--.*?-->/, '')
    .replace(/width="24"/, 'width="520"').replace(/height="24"/, 'height="520"')
    .replace(/stroke="currentColor"/, 'stroke="#fff"').replace(/stroke-width="2"/, 'stroke-width="1.7"');
  await page.setContent(`<html><body style="margin:0;background:transparent">
  <div style="position:absolute;left:100px;top:92px;width:824px;height:824px;border-radius:186px;
    background:linear-gradient(160deg, ${a} 0%, ${b} 100%);
    box-shadow:0 18px 30px rgba(0,0,0,.28), inset 0 2px 0 rgba(255,255,255,.35), inset 0 -6px 18px rgba(0,0,0,.12);
    display:flex;align-items:center;justify-content:center;overflow:hidden">
    <div style="position:absolute;inset:0;background:radial-gradient(120% 70% at 30% 0%, rgba(255,255,255,.28), transparent 60%)"></div>
    <div style="filter:drop-shadow(0 10px 14px rgba(0,0,0,.22));display:flex">${svg}</div>
  </div></body></html>`);
  await page.screenshot({ path: `${out}/${seed}.png`, omitBackground: true });
  console.log(seed);
}
await browser.close();
