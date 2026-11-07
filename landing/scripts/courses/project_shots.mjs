// Fotografía una app de Flutter de los proyectos de los cursos de bases de
// datos (compilada para la web, con sus datos de verdad) en tres pantallas
// de teléfono: el catálogo, el catálogo filtrado por una categoría y la
// ficha de un producto con sus opiniones. Las junta en una imagen.
//
//   node scripts/courses/project_shots.mjs <build/web> <salida.png> <categoría> <producto>
//
// Playwright: PLAYWRIGHT_DIR=<carpeta con node_modules/playwright>. Lo lanza
// scripts/courses/build_projects.py.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { createRequire } from "node:module";

const [web, out, category, product] = process.argv.slice(2);
if (!product) {
  console.error("uso: project_shots.mjs <build/web> <salida.png> <categoría> <producto>");
  process.exit(2);
}
const require = createRequire(path.join(process.env.PLAYWRIGHT_DIR || process.cwd(), "node_modules", "x.js"));
const { chromium } = require("playwright");

const TYPES = { ".html": "text/html", ".js": "text/javascript", ".json": "application/json", ".wasm": "application/wasm", ".png": "image/png", ".otf": "font/otf", ".ttf": "font/ttf" };
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split("?")[0]);
  let file = path.join(web, url === "/" ? "index.html" : url);
  if (!file.startsWith(path.resolve(web)) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(web, "index.html");
  res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}/`;

const browser = await chromium.launch();
const phone = { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true };
const shots = [];
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

/** El elemento de la lista (o la fila) que empieza por [text]. */
function item(page, text) {
  const esc = text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return page.locator("flt-semantics span").filter({ hasText: new RegExp(`^${esc}(\\n|$)`) }).first();
}

async function open() {
  const page = await browser.newPage(phone);
  page.on("pageerror", (e) => console.error("pageerror:", e.message));
  await page.goto(base);
  // Las etiquetas de accesibilidad: así se encuentran los textos del lienzo.
  await page.waitForSelector("flt-semantics-placeholder", { state: "attached", timeout: 60000 });
  await wait(3000);
  await page.evaluate(() => document.querySelector("flt-semantics-placeholder").click());
  await item(page, product).waitFor({ timeout: 60000 });
  await wait(800);
  return page;
}

// 1. El catálogo.
let page = await open();
shots.push(await page.screenshot());
// 2. Filtrado por una categoría (elegida en la pantalla Categorías).
await page.getByRole("checkbox", { name: /^(Elegir categoría|Choose a category)$/ }).click();
// Cada fila de la lista de categorías es un botón con su nombre.
const row = page.getByRole("button", { name: category, exact: true });
await row.waitFor();
await wait(500);
await row.click();
await wait(2500);
shots.push(await page.screenshot());
await page.close();
// 3. La ficha de un producto, con sus opiniones.
page = await open();
await item(page, product).click({ force: true });
await page.locator("flt-semantics span").filter({ hasText: /★/ }).first().waitFor({ timeout: 30000 });
await wait(1200);
shots.push(await page.screenshot());
await page.close();

// Las tres, como teléfonos, en una imagen.
const imgs = shots.map((b) => `<img src="data:image/png;base64,${b.toString("base64")}">`).join("");
const sheet = await browser.newPage({ viewport: { width: 1290, height: 940 }, deviceScaleFactor: 1.5 });
await sheet.setContent(`<!doctype html><style>
  html,body{margin:0;background:#efe9e4}
  body{display:flex;gap:42px;justify-content:center;align-items:center;height:940px}
  img{width:360px;height:779px;border-radius:34px;border:9px solid #1d1f24;box-shadow:0 18px 40px rgba(40,30,20,.25);background:#fff}
</style>${imgs}`);
await sheet.waitForLoadState("load");
await sheet.screenshot({ path: out });
await browser.close();
server.close();
console.log(out);
