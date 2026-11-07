#!/usr/bin/env node
// Los cursos de la web (/cursos): ejecuta de verdad cada ejemplo, guarda su
// salida y su código resaltado en content/courses/data/<curso>.json y dibuja
// su imagen (el código y la salida en una ventana de DMarlon Studio) en
// public/courses/<curso>/<nivel>-<NN>.jpg.
//
//   node scripts/build-courses.mjs [curso ...] [--no-images]
//   node scripts/build-courses.mjs python --level=basic [--check]
//
// --check comprueba (ejecuta cada ejemplo) sin escribir nada; --level solo
// genera ese nivel (el otro se queda como estaba).
//
// Cada lección es una carpeta content/courses/<curso>/<nivel>/<NN>-<slug>/
// con main.<ext>, lesson.json y, si lee del teclado, input.txt. Hacen falta
// los compiladores (python3, node, cc, c++, fpc, go, dart) y, para las
// imágenes, Playwright: PLAYWRIGHT_DIR=<carpeta con node_modules/playwright>.

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { createHighlighter } from "shiki";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SRC = path.join(ROOT, "content", "courses");
const DATA = path.join(SRC, "data");
const IMAGES = path.join(ROOT, "public", "courses");
const LEVELS = ["basic", "advanced"];

// Lo que se necesita de cada curso (lo mismo que content/courses/catalog.ts).
const COURSES = {
  python: { ext: "py", shiki: "python", name: "Python", command: "python3 main.py" },
  javascript: { ext: "js", shiki: "javascript", name: "JavaScript", command: "node main.js" },
  c: { ext: "c", shiki: "c", name: "C", command: "cc main.c -o main && ./main" },
  cpp: { ext: "cpp", shiki: "cpp", name: "C++", command: "c++ -std=c++17 main.cpp -o main && ./main" },
  pascal: { ext: "pas", shiki: "pascal", name: "Pascal", command: "fpc main.pas && ./main" },
  go: { ext: "go", shiki: "go", name: "Go", command: "go run main.go" },
  dart: { ext: "dart", shiki: "dart", name: "Dart", command: "dart run main.dart" },
  // Ventanas: la imagen lleva la captura de verdad de cada ventana.
  tkinter: { ext: "py", shiki: "python", name: "tkinter", command: "python3 main.py", gui: true },
  // Bases de datos: el script se ejecuta con el módulo Bases de datos del
  // estudio (studio/tool/db_course.dart) y la salida son sus rejillas.
  sqlite: { ext: "sql", shiki: "sql", name: "SQLite", db: "sqlite", seed: "seed.sql" },
  postgres: { ext: "sql", shiki: "sql", name: "PostgreSQL", db: "postgres", seed: "seed.sql" },
  mysql: { ext: "sql", shiki: "sql", name: "MySQL", db: "mysql", seed: "seed.sql" },
  mongodb: { ext: "json", shiki: "jsonc", name: "MongoDB", db: "mongodb", seed: "seed.json" },
  falcondatabase: { ext: "json", shiki: "jsonc", name: "FalconDatabase", db: "falcon", seed: "seed.json" },
  firebase: { ext: "json", shiki: "jsonc", name: "Firebase", db: "firebase", seed: "seed.json" },
};
const STUDIO = path.join(ROOT, "..", "studio");

/** La conexión de cada base de datos (servidores de
 * scripts/courses/db_servers.sh; PostgreSQL, el que haya). [as]: el usuario
 * de FalconDatabase con el que entra la lección (course, ana, luis o anon). */
function dbConn(kind, tmp, as = "course") {
  switch (kind) {
    case "sqlite":
      return { path: path.join(tmp, "shop.db") };
    case "postgres": {
      const [host, port, user, password] = (process.env.DMS_COURSE_PG || `localhost:5434:${os.userInfo().username}:`).split(":");
      return { host, port, user, password, database: "dms_course" };
    }
    case "mysql":
      return { host: "127.0.0.1", port: process.env.DMS_COURSE_MYSQL_PORT || "3407", user: "root", password: "", database: "dms_course" };
    case "mongodb":
      return { uri: `mongodb://127.0.0.1:${process.env.DMS_COURSE_MONGO_PORT || "27027"}/dms_course` };
    case "firebase":
      return { project: "dms-cursos", emulator: `127.0.0.1:${process.env.DMS_COURSE_FIRESTORE_PORT || "8095"}` };
    case "falcon": {
      // El proyecto del curso: referencia, clave anon y sus usuarios.
      const file = process.env.DMS_COURSE_FALCON || path.join(os.homedir(), ".config", "dmarlonstudio", "course-falcon.json");
      const f = JSON.parse(fs.readFileSync(file, "utf8"));
      const user = as === "anon" ? {} : f.users[as];
      if (!user) throw new Error(`FalconDatabase: no existe el usuario ${as}`);
      return { url: f.url, project: f.project, key: f.key, ...user };
    }
  }
  throw new Error(`Base de datos: ${kind}`);
}

/** Ejecuta en el estudio los [jobs] ({kind, conn, script, seed}): un
 * resultado por trabajo ({results, schema, error?} o {fatal}). */
function runDbJobs(jobs) {
  if (!jobs.length) return [];
  const file = path.join(os.tmpdir(), `dms-db-jobs-${process.pid}.json`);
  fs.writeFileSync(file, JSON.stringify(jobs));
  try {
    const r = spawnSync("dart", ["run", "tool/db_course.dart", "--batch", file], {
      cwd: STUDIO,
      encoding: "utf8",
      timeout: 30 * 60_000,
      maxBuffer: 256 * 1024 * 1024,
      env: { ...process.env, TZ: "UTC", LANG: "en_US.UTF-8" },
    });
    if (r.status !== 0) throw new Error(`db_course: ${r.stderr.slice(-2000)}`);
    // «Running build hooks…» va delante de la primera línea.
    const lines = r.stdout
      .split("\n")
      .map((l) => l.slice(Math.max(0, l.indexOf("{"))))
      .filter((l) => l.startsWith("{"));
    if (lines.length !== jobs.length) throw new Error(`db_course: ${lines.length} de ${jobs.length} resultados`);
    return lines.map((l) => JSON.parse(l));
  } finally {
    fs.rmSync(file, { force: true });
  }
}

/** Lo que cambia de una ejecución a otra sin ser un error: la hora de
 * created_at y los id que pone el servidor (FalconDatabase, ObjectId de
 * MongoDB, documentos de Firestore sin _id). */
function stable(kind, results) {
  return JSON.stringify(results, function (k, v) {
    if (k !== "rows" || !Array.isArray(v)) return v;
    const cols = this.columns ?? [];
    return v.map((row) =>
      row.map((x, i) => {
        const c = cols[i];
        if (c === "created_at" || c === "updated_at") return "<time>";
        if (kind === "falcon" && (c === "id" || c === "owner_id")) return "<id>";
        if (c === "_id" && typeof x === "string" && /^([0-9a-f]{24}|[A-Za-z0-9]{20})$/.test(x)) return "<id>";
        return x;
      }),
    );
  });
}

/** Los resultados como texto (lo que se compara y la salida de respaldo). */
function resultsText(results, lang = "en") {
  const out = [];
  for (const r of results) {
    if (r.columns) {
      out.push(r.columns.join(" | "));
      for (const row of r.rows) out.push(row.map((v) => (v == null ? "NULL" : String(v))).join(" | "));
      if (r.message) out.push(lang === "es" ? r.message : r.message_en);
    } else if (r.message) {
      out.push(lang === "es" ? r.message : r.message_en);
    }
    out.push("");
  }
  return out.join("\n").trim();
}

// tkinter: un Python con Tk (el de Homebrew no lo trae: brew install python-tk@3.12).
const TK_PYTHON =
  process.env.DMS_TK_PYTHON ||
  ["/opt/homebrew/opt/python@3.12/bin/python3.12", "/usr/local/opt/python@3.12/bin/python3.12"].find((p) =>
    fs.existsSync(p),
  ) ||
  "python3";
const TK_RUN = path.join(ROOT, "scripts", "courses", "tk_run.py");

/** El ayudante que dice qué ventanas tiene un proceso (macOS). */
let winid = null;
function winidTool() {
  if (winid) return winid;
  winid = path.join(os.tmpdir(), "dms-courses-winid");
  const src = path.join(ROOT, "scripts", "courses", "winid.swift");
  if (!fs.existsSync(winid) || fs.statSync(winid).mtimeMs < fs.statSync(src).mtimeMs) {
    const r = spawnSync("swiftc", ["-O", "-o", winid, src], { encoding: "utf8" });
    if (r.status !== 0) throw new Error(`swiftc winid.swift: ${r.stderr}`);
  }
  return winid;
}

// macOS: Free Pascal enlaza con la libc del SDK de Xcode.
const SDK =
  process.platform === "darwin"
    ? spawnSync("xcrun", ["--show-sdk-path"], { encoding: "utf8" }).stdout.trim()
    : "";

/** Cómo se compila (si hace falta) y se ejecuta un ejemplo en [dir]. [shot]:
 * dónde dejar las capturas de las ventanas (tkinter; "-" sin capturas). */
function steps(id, dir, shot = "-") {
  const exe = path.join(dir, "main");
  return {
    python: [["python3", ["-I", "main.py"]]],
    javascript: [["node", ["main.js"]]],
    c: [["cc", ["-std=c11", "-Wall", "-O1", "main.c", "-o", exe, "-lm"]], [exe, []]],
    cpp: [["c++", ["-std=c++17", "-Wall", "-O1", "main.cpp", "-o", exe]], [exe, []]],
    pascal: [
      ["fpc", ["-Mobjfpc", "-Sh", "-O1", "-vew", ...(SDK ? [`-XR${SDK}`] : []), `-FE${dir}`, `-o${exe}`, "main.pas"]],
      [exe, []],
    ],
    go: [["go", ["run", "main.go"]]],
    dart: [["dart", ["run", "main.dart"]]],
    tkinter: [[TK_PYTHON, ["-I", TK_RUN, "main.py", shot]]],
  }[id];
}

const args = process.argv.slice(2);
const check = args.includes("--check");
const noImages = check || args.includes("--no-images");
const onlyLevel = args.find((a) => a.startsWith("--level="))?.slice("--level=".length);
if (onlyLevel && !LEVELS.includes(onlyLevel)) throw new Error(`Nivel: ${LEVELS.join(" o ")}`);
const only = args.filter((a) => !a.startsWith("--"));
const ids = only.length ? only : Object.keys(COURSES).filter((id) => fs.existsSync(path.join(SRC, id)));
for (const id of ids) if (!COURSES[id]) throw new Error(`No existe el curso ${id}`);

const problems = [];
const fail = (where, msg) => problems.push(`${where}: ${msg}`);

/** Ejecuta la lección [lessonDir]: su salida (o null si falla). */
function runLesson(id, lessonDir, where, shot) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), `curso-${id}-`));
  try {
    fs.cpSync(lessonDir, tmp, { recursive: true });
    const inputFile = path.join(tmp, "input.txt");
    const input = fs.existsSync(inputFile) ? fs.readFileSync(inputFile, "utf8") : "";
    const all = steps(id, tmp, shot);
    let out = "";
    for (const [i, [cmd, argv]] of all.entries()) {
      const last = i === all.length - 1;
      const r = spawnSync(cmd, argv, {
        cwd: tmp,
        input: last ? input : "",
        encoding: "utf8",
        timeout: 60_000,
        // Go sin cgo: el mismo binario en todas partes (y Go 1.19 con cgo
        // no arranca en macOS 26 si usa la red).
        env: {
          ...process.env,
          NO_COLOR: "1",
          LANG: "en_US.UTF-8",
          TZ: "UTC",
          CGO_ENABLED: "0",
          ...(COURSES[id].gui ? { WINID: winidTool() } : {}),
        },
      });
      if (r.error) {
        fail(where, `${cmd}: ${r.error.message}`);
        return null;
      }
      if (r.status !== 0) {
        fail(where, `${cmd} terminó con ${r.status}\n${(r.stdout + r.stderr).slice(-1500)}`);
        return null;
      }
      if (last) out = r.stdout + (r.stderr ? r.stderr : "");
    }
    return out.replaceAll(tmp, ".").replace(/\s+$/, "");
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

const TEXT_KEYS = ["slug", "title", "summary", "body", "points", "exercise"];

function checkTexts(where, t) {
  if (!t || typeof t !== "object") return fail(where, "faltan los textos");
  for (const k of TEXT_KEYS) if (t[k] == null || t[k].length === 0) fail(where, `falta «${k}»`);
  if (t.slug && !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(t.slug)) fail(where, `slug no válido: ${t.slug}`);
  if (!Array.isArray(t.body) || !Array.isArray(t.points)) fail(where, "body y points son listas");
  if (t.summary && t.summary.length > 170) fail(where, `summary de ${t.summary.length} caracteres (máximo 170)`);
}

const highlighter = await createHighlighter({
  themes: ["dark-plus"],
  langs: [...new Set(Object.values(COURSES).map((c) => c.shiki))],
});

const built = [];
for (const id of ids) {
  const course = COURSES[id];
  const data = { id, levels: {} };
  for (const level of LEVELS) {
    if (onlyLevel && level !== onlyLevel) continue;
    const levelDir = path.join(SRC, id, level);
    const dirs = fs.existsSync(levelDir)
      ? fs.readdirSync(levelDir).filter((d) => /^\d\d-/.test(d)).sort()
      : [];
    const lessons = [];
    // Bases de datos: todas las lecciones del nivel en un lote (dos veces
    // cada una, para ver que el resultado no cambia).
    const dbOut = new Map();
    if (course.db) {
      const seedFile = path.join(SRC, id, course.seed);
      const seed = fs.existsSync(seedFile) ? fs.readFileSync(seedFile, "utf8") : null;
      const tmp = fs.mkdtempSync(path.join(os.tmpdir(), `curso-${id}-`));
      const jobs = [];
      for (const d of dirs) {
        const dir = path.join(levelDir, d);
        const file = path.join(dir, `main.${course.ext}`);
        if (!fs.existsSync(file)) continue;
        let meta = {};
        try {
          meta = JSON.parse(fs.readFileSync(path.join(dir, "lesson.json"), "utf8"));
        } catch {
          // Lo dice el bucle de abajo.
        }
        const job = {
          kind: course.db,
          conn: dbConn(course.db, tmp, meta.as),
          script: fs.readFileSync(file, "utf8"),
          ...(seed && meta.seed !== false ? { seed } : {}),
          // FalconDatabase: se restaura con el usuario del curso y las notas
          // de cada usuario se vacían con su sesión (db_course.dart).
          ...(course.db === "falcon"
            ? { admin: dbConn("falcon", tmp, "course"), others: ["ana", "luis"].map((u) => dbConn("falcon", tmp, u)) }
            : {}),
        };
        jobs.push({ d, job });
      }
      process.stdout.write(`${id}/${level}: ${jobs.length} lecciones en ${course.name}… `);
      const res = runDbJobs(jobs.flatMap((j) => [j.job, j.job]));
      console.log("hecho");
      jobs.forEach((j, i) => dbOut.set(j.d, [res[2 * i], res[2 * i + 1]]));
      fs.rmSync(tmp, { recursive: true, force: true });
    }
    for (const [i, d] of dirs.entries()) {
      const where = `${id}/${level}/${d}`;
      const dir = path.join(levelDir, d);
      const n = Number(d.slice(0, 2));
      if (n !== i + 1) fail(where, `el número debería ser ${String(i + 1).padStart(2, "0")}`);
      const codeFile = path.join(dir, `main.${course.ext}`);
      if (!fs.existsSync(codeFile)) {
        fail(where, `falta main.${course.ext}`);
        continue;
      }
      let meta;
      try {
        meta = JSON.parse(fs.readFileSync(path.join(dir, "lesson.json"), "utf8"));
      } catch (e) {
        fail(where, `lesson.json: ${e.message}`);
        continue;
      }
      checkTexts(`${where} (es)`, meta.es);
      checkTexts(`${where} (en)`, meta.en);
      const code = fs.readFileSync(codeFile, "utf8").replace(/\s+$/, "");
      process.stdout.write(`${where} … `);
      // Con ventanas: una vez, con sus capturas (si hay imágenes que hacer).
      const shotBase = course.gui && !noImages ? path.join(os.tmpdir(), `dms-shot-${id}-${level}-${d.slice(0, 2)}`) : "-";
      if (shotBase !== "-") {
        for (const f of fs.readdirSync(os.tmpdir())) {
          if (f.startsWith(path.basename(shotBase) + "-")) fs.rmSync(path.join(os.tmpdir(), f));
        }
      }
      let db = null;
      if (course.db) {
        const [a, b] = dbOut.get(d) ?? [];
        if (!a || a.fatal) {
          fail(where, a?.fatal ?? "no se ejecutó");
          console.log("FALLA");
          continue;
        }
        // Una lección puede enseñar un error: lo dice con "error": true y
        // falla la última consulta.
        const nQueries = a.results.length + (a.error ? 1 : 0);
        if (a.error && !(meta.error && a.error.index === nQueries - 1)) {
          fail(where, `la consulta ${a.error.index + 1} falla: ${a.error.message}`);
        } else if (meta.error && !a.error) {
          fail(where, "debería fallar (\"error\": true) y no falla");
        }
        if (stable(course.db, a) !== stable(course.db, b)) fail(where, "el resultado cambia de una ejecución a otra");
        if (!a.results.length) fail(where, "no ejecuta nada");
        db = a;
      }
      const output = course.db ? resultsText(db.results) : runLesson(id, dir, where, shotBase);
      if (output == null) {
        console.log("FALLA");
        continue;
      }
      let shots = [];
      if (course.db) {
        // Ya comprobado.
      } else if (course.gui) {
        if (shotBase !== "-") {
          shots = fs
            .readdirSync(os.tmpdir())
            .filter((f) => f.startsWith(path.basename(shotBase) + "-") && f.endsWith(".png"))
            .sort()
            .map((f) => fs.readFileSync(path.join(os.tmpdir(), f)).toString("base64"));
          if (!shots.length) fail(where, "no se pudo capturar ninguna ventana");
        }
      } else {
        // La misma salida dos veces: nada de azar ni de horas.
        const again = runLesson(id, dir, where);
        if (again !== output) fail(where, "la salida cambia de una ejecución a otra");
        if (!output) fail(where, "no escribe nada");
      }
      console.log("ok");
      // Sin saltos entre las líneas: cada una ya es un bloque.
      const html = highlighter
        .codeToHtml(code, { lang: course.shiki, theme: "dark-plus" })
        .replaceAll('</span>\n<span class="line">', '</span><span class="line">');
      lessons.push({
        n,
        es: meta.es,
        en: meta.en,
        code,
        html,
        input: fs.existsSync(path.join(dir, "input.txt")) ? fs.readFileSync(path.join(dir, "input.txt"), "utf8") : undefined,
        output,
        image: `/courses/${id}/${level}-${String(n).padStart(2, "0")}.jpg`,
        ...(course.gui ? { gui: true, shots } : {}),
        ...(db
          ? {
              results: db.results,
              ...(db.error ? { error: db.error } : {}),
              schema: db.schema.map((t) => t.name),
              ...(meta.as && meta.as !== "course" ? { as: meta.as } : {}),
            }
          : {}),
      });
    }
    for (const lang of ["es", "en"]) {
      const seen = new Set();
      for (const l of lessons) {
        if (seen.has(l[lang].slug)) fail(`${id}/${level}`, `slug repetido (${lang}): ${l[lang].slug}`);
        seen.add(l[lang].slug);
      }
    }
    data.levels[level] = lessons;
  }
  built.push(data);
}

if (!noImages) await drawImages(built);

// Los datos de cada curso de bases de datos, para descargarlos.
if (!check) {
  for (const data of built) {
    const c = COURSES[data.id];
    if (!c.db || !fs.existsSync(path.join(SRC, data.id, c.seed))) continue;
    fs.mkdirSync(path.join(IMAGES, data.id), { recursive: true });
    fs.copyFileSync(path.join(SRC, data.id, c.seed), path.join(IMAGES, data.id, `shop.${c.ext}`));
  }
}

// Con --check no se escribe. Con --level, el otro nivel se queda como estaba.
// Sin imágenes nuevas, se conserva el tamaño de las que ya hay.
if (!check) {
  fs.mkdirSync(DATA, { recursive: true });
  for (const data of built) {
    const file = path.join(DATA, `${data.id}.json`);
    const before = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : null;
    if (onlyLevel) {
      for (const level of LEVELS) {
        if (level !== onlyLevel && before?.levels?.[level]) data.levels[level] = before.levels[level];
      }
      data.levels = Object.fromEntries(LEVELS.filter((l) => data.levels[l]).map((l) => [l, data.levels[l]]));
    }
    for (const level of LEVELS) {
      for (const l of data.levels[level] ?? []) {
        l.size ??= before?.levels?.[level]?.find((x) => x.image === l.image)?.size;
      }
    }
    fs.writeFileSync(file, `${JSON.stringify(data, (k, v) => (k === "shots" ? undefined : v), 1)}\n`);
  }
}

if (problems.length) {
  console.error(`\n${problems.length} problemas:\n- ${problems.join("\n- ")}`);
  process.exit(1);
}
console.log(`\nListo: ${built.map((d) => `${d.id} (${LEVELS.map((l) => d.levels[l]?.length ?? "-").join("+")})`).join(", ")}`);

// ------------------------------------------------------------- imágenes

function esc(s) {
  return s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}

/** La pantalla Bases de datos del estudio: las tablas, el script de la
 * lección y la rejilla de su último resultado (las demás, en pestañas). */
function dbWindowHtml(course, level, l) {
  const MAX_CODE = 34;
  const MAX_ROWS = 12;
  const lines = l.html.split('<span class="line">').length - 1;
  const results = l.results ?? [];
  const withRows = results.map((r, i) => (r.columns ? i : -1)).filter((i) => i >= 0);
  const shown = l.error ? -1 : withRows.length ? withRows.at(-1) : results.length - 1;
  const chip = (r, i) =>
    `<span class="chip${i === shown ? " on" : ""}">${i + 1} · ${r.columns ? `${r.rows.length} ${r.rows.length === 1 ? "row" : "rows"}` : "Done"}</span>`;
  const cell = (v) =>
    v == null
      ? '<td class="null">NULL</td>'
      : `<td class="${typeof v === "number" ? "num" : ""}">${esc(String(v))}</td>`;
  const r = shown >= 0 ? results[shown] : null;
  let body = "";
  if (l.error) {
    body = `<div class="err">${esc(l.error.message)}</div>`;
  } else if (r?.columns) {
    const rows = r.rows.slice(0, MAX_ROWS);
    body = `<div class="meta">${r.rows.length} ${r.rows.length === 1 ? "row" : "rows"}${r.message_en ? ` · ${esc(r.message_en)}` : ""}</div>
    <table><thead><tr><th class="n"></th>${r.columns.map((c) => `<th>${esc(c)}</th>`).join("")}</tr></thead>
    <tbody>${rows.map((row, i) => `<tr><td class="n">${i + 1}</td>${row.map(cell).join("")}</tr>`).join("")}</tbody></table>
    ${r.rows.length > MAX_ROWS ? `<div class="more">⋯ ${r.rows.length - MAX_ROWS} more rows</div>` : ""}`;
  } else if (r) {
    body = `<div class="ok">${esc(r.message_en ?? "Done")}</div>`;
  }
  const kindName = { sqlite: "SQLite", postgres: "PostgreSQL", mysql: "MySQL / MariaDB", mongodb: "MongoDB", falcon: "FalconDatabase", firebase: "Firebase (Firestore)" }[course.db];
  const conn = { falcon: "shop · falcondatabase.com", firebase: "shop · Firestore" }[course.db] ?? "shop";
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { box-sizing: border-box; }
  body { margin: 0; padding: 40px; font-size: 14px; background: linear-gradient(135deg, #1b2a4a 0%, #3b2a5a 55%, #6b3a5a 100%); font-family: -apple-system, "Segoe UI", Inter, sans-serif; width: 1200px; }
  .win { border-radius: 12px; overflow: hidden; background: #1e1e1e; box-shadow: 0 30px 60px rgba(0,0,0,.45), 0 0 0 1px rgba(255,255,255,.08); color: #d4d4d8; }
  .bar { display: flex; align-items: center; gap: 8px; height: 38px; padding: 0 14px; background: #2b2b2f; color: #a8a8b0; font-size: 13px; }
  .dot { width: 12px; height: 12px; border-radius: 50%; }
  .title { margin-left: 10px; flex: 1; text-align: center; margin-right: 60px; }
  .title b { color: #e6e6ea; font-weight: 600; }
  .main { display: flex; }
  .side { width: 230px; flex: none; background: #232326; border-right: 1px solid #333; padding: 12px 0; font-size: 13px; }
  .side h4 { margin: 0 14px 8px; font-size: 11px; letter-spacing: .08em; color: #8a8a92; font-weight: 600; }
  .conn { margin: 0 8px; padding: 7px 8px; border-radius: 6px; background: #4f8cff22; color: #e6e6ea; display: flex; gap: 8px; align-items: center; }
  .conn i { width: 9px; height: 9px; border-radius: 50%; background: #4ade80; }
  .filter { margin: 12px 12px 8px; padding: 6px 9px; border-radius: 6px; border: 1px solid #3a3a40; color: #6a6a72; font-size: 12px; }
  .tb { padding: 4px 14px 4px 18px; color: #c4c4ca; display: flex; gap: 8px; align-items: center; }
  .tb::before { content: ""; width: 11px; height: 9px; border: 1.5px solid #8a8a92; border-radius: 2px; flex: none; }
  .pane { flex: 1; min-width: 0; }
  .ctl { display: flex; align-items: center; gap: 10px; height: 46px; padding: 0 14px; border-bottom: 1px solid #333; background: #252528; font-size: 13px; }
  .crumb { font-weight: 600; color: #e6e6ea; }
  .btn { margin-left: auto; display: flex; align-items: center; gap: 6px; padding: 5px 12px; border-radius: 6px; background: #4f8cff; color: #fff; font-weight: 600; font-size: 12.5px; }
  .btn i { width: 0; height: 0; border-left: 8px solid #fff; border-top: 5px solid transparent; border-bottom: 5px solid transparent; }
  .btn2 { padding: 4px 11px; border-radius: 6px; border: 1px solid #4a4a52; color: #b8b8c0; font-size: 12.5px; }
  .badge { padding: 3px 9px; border-radius: 999px; background: #38bdf822; color: #7dd3fc; font-size: 12px; }
  .editor { margin: 12px 14px; border: 1px solid #3a3a40; border-radius: 6px; background: #1b1b1d; padding: 10px 0 12px; font: 13.5px/1.55 Menlo, Consolas, "DejaVu Sans Mono", monospace; }
  .editor pre { margin: 0; background: transparent !important; counter-reset: ln; font: inherit; white-space: pre-wrap; }
  .editor code { font: inherit; }
  .editor .line { display: block; padding-right: 16px; min-height: 1.55em; padding-left: 52px; text-indent: -52px; }
  .editor .line::before { counter-increment: ln; content: counter(ln); display: inline-block; width: 34px; margin-right: 18px; text-align: right; color: #5a5a62; text-indent: 0; }
  .moreCode { padding: 2px 0 0 52px; color: #6a6a72; }
  .res { padding: 0 14px 16px; }
  .chips { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }
  .chip { padding: 3px 10px; border-radius: 7px; border: 1px solid #3f3f46; color: #a1a1aa; font-size: 12px; }
  .chip.on { background: #4f8cff2e; border-color: #4f8cff; color: #e6e6ea; }
  .meta { color: #8a8a92; font-size: 12px; margin: 0 0 6px; }
  table { border-collapse: collapse; font: 13px Menlo, Consolas, monospace; min-width: 60%; }
  th, td { min-width: 120px; }
  th.n, td.n { min-width: 34px; }
  th { text-align: left; font: 600 12.5px -apple-system, "Segoe UI", sans-serif; color: #e6e6ea; background: #2c2c31; padding: 7px 10px; }
  td { padding: 5px 10px; border-bottom: 1px solid #2c2c31; max-width: 380px; overflow: hidden; text-overflow: ellipsis; white-space: pre; }
  td.num { text-align: right; }
  td.null { color: #6a6a72; }
  .n { width: 34px; color: #6a6a72; text-align: center; font-size: 11px; }
  .more { color: #6a6a72; font: 12.5px Menlo, monospace; padding: 6px 10px; }
  .ok { color: #4ade80; padding: 4px 2px; }
  .err { color: #f87171; padding: 4px 2px; font: 13px Menlo, monospace; white-space: pre-wrap; }
  </style></head><body><div class="win" id="win">
  <div class="bar"><span class="dot" style="background:#ff5f57"></span><span class="dot" style="background:#febc2e"></span><span class="dot" style="background:#28c840"></span>
    <span class="title"><b>DMarlon Studio</b> — Databases · ${esc(course.name)} ${level === "basic" ? "Basic" : "Advanced"} ${String(l.n).padStart(2, "0")}</span></div>
  <div class="main">
    <div class="side"><h4>CONNECTIONS</h4><div class="conn"><i></i>${esc(conn)}</div>
      <div class="filter">Filter tables</div>
      ${(l.schema ?? []).slice(0, 18).map((t) => `<div class="tb">${esc(t)}</div>`).join("")}
    </div>
    <div class="pane">
      <div class="ctl"><span class="crumb">${esc(conn)}</span><span class="btn"><i></i>Run</span><span class="btn2">CSV</span><span class="badge">${esc(kindName)}</span></div>
      <div class="editor">${trimHtml(l.html, MAX_CODE)}${lines > MAX_CODE ? `<div class="moreCode">⋯ ${lines - MAX_CODE} more lines</div>` : ""}</div>
      <div class="res">
        ${results.length > 1 || l.error ? `<div class="chips">${results.map(chip).join("")}${l.error ? `<span class="chip on" style="border-color:#f87171;color:#fca5a5">${results.length + 1} · Error</span>` : ""}</div>` : ""}
        ${body}
      </div>
    </div>
  </div>
  </div></body></html>`;
}

/** La ventana del estudio con el código de la lección y su salida. */
function windowHtml(course, level, l) {
  if (course.db) return dbWindowHtml(course, level, l);
  const MAX_CODE = 34;
  const MAX_OUT = 14;
  const lines = l.html.split('<span class="line">').length - 1;
  const out = l.output.split("\n");
  const shownOut = out.length > MAX_OUT ? [...out.slice(0, MAX_OUT - 1), "⋯"] : out;
  const file = `main.${course.ext}`;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  * { box-sizing: border-box; }
  body { margin: 0; padding: 40px; font-size: 14px; background: linear-gradient(135deg, #1b2a4a 0%, #3b2a5a 55%, #6b3a5a 100%); font-family: -apple-system, "Segoe UI", Inter, sans-serif; width: 1200px; }
  .win { border-radius: 12px; overflow: hidden; background: #1e1e1e; box-shadow: 0 30px 60px rgba(0,0,0,.45), 0 0 0 1px rgba(255,255,255,.08); }
  .bar { display: flex; align-items: center; gap: 8px; height: 38px; padding: 0 14px; background: #2b2b2f; color: #a8a8b0; font-size: 13px; }
  .dot { width: 12px; height: 12px; border-radius: 50%; }
  .title { margin-left: 10px; flex: 1; text-align: center; margin-right: 60px; }
  .title b { color: #e6e6ea; font-weight: 600; }
  .tools { display: flex; align-items: center; gap: 14px; height: 34px; padding: 0 14px; background: #252528; border-top: 1px solid #333; border-bottom: 1px solid #333; color: #9a9aa2; font-size: 12px; }
  .run { display: flex; align-items: center; gap: 6px; color: #4ade80; font-weight: 600; }
  .run i { width: 0; height: 0; border-left: 9px solid #4ade80; border-top: 6px solid transparent; border-bottom: 6px solid transparent; }
  .chip { margin-left: auto; padding: 3px 9px; border-radius: 6px; background: ${"#ffffff14"}; color: #d0d0d6; }
  .tabs { display: flex; background: #252528; font-size: 12.5px; }
  .tab { padding: 8px 16px; color: #e6e6ea; background: #1e1e1e; border-top: 2px solid #4f8cff; }
  .code { padding: 14px 0 16px; font: 14.5px/1.55 Menlo, Consolas, "DejaVu Sans Mono", monospace; }
  .code pre { margin: 0; background: transparent !important; counter-reset: ln; font: inherit; }
  .code code { font: inherit; }
  .code .line { display: block; padding-right: 20px; min-height: 1.55em; }
  .code .line::before { counter-increment: ln; content: counter(ln); display: inline-block; width: 46px; margin-right: 18px; text-align: right; color: #5a5a62; }
  .more { padding: 0 0 6px 64px; color: #6a6a72; font: 14px Menlo, monospace; }
  .term { border-top: 1px solid #333; background: #18181a; }
  .termbar { display: flex; gap: 18px; padding: 7px 16px; font-size: 11.5px; letter-spacing: .06em; color: #8a8a92; border-bottom: 1px solid #2a2a2e; }
  .termbar span:first-child { color: #e6e6ea; border-bottom: 1px solid #4f8cff; padding-bottom: 3px; }
  .out { margin: 0; padding: 12px 18px 16px; font: 14px/1.5 Menlo, Consolas, "DejaVu Sans Mono", monospace; color: #d4d4d4; white-space: pre-wrap; word-break: break-word; }
  .prompt { color: #4ade80; }
  .run-app { border-top: 1px solid #333; background: #18181a; }
  .app { display: flex; flex-wrap: wrap; gap: 28px; justify-content: center; align-items: flex-start; padding: 30px 24px 34px;
    background: radial-gradient(circle at 1px 1px, #ffffff10 1px, transparent 0) 0 0 / 18px 18px, #232327; }
  .app img { max-width: 100%; border-radius: 10px; box-shadow: 0 14px 34px rgba(0,0,0,.5), 0 0 0 1px rgba(0,0,0,.4); }
  </style></head><body><div class="win" id="win">
  <div class="bar"><span class="dot" style="background:#ff5f57"></span><span class="dot" style="background:#febc2e"></span><span class="dot" style="background:#28c840"></span>
    <span class="title"><b>DMarlon Studio</b> — ${esc(course.name)} · ${level === "basic" ? "Basic" : "Advanced"} ${String(l.n).padStart(2, "0")}</span></div>
  <div class="tools"><span class="run"><i></i>F9</span><span>■</span><span>⟲</span><span class="chip">${esc(course.name)}</span></div>
  <div class="tabs"><span class="tab">${esc(file)}</span></div>
  <div class="code">${trimHtml(l.html, MAX_CODE)}</div>
  ${lines > MAX_CODE ? `<div class="more">⋯ ${lines - MAX_CODE} more lines</div>` : ""}
  ${
    l.gui
      ? `<div class="run-app"><div class="termbar"><span>▶ ${esc(course.command)}</span><span>RUNNING</span></div>
  <div class="app">${(l.shots ?? []).map((b) => `<img src="data:image/png;base64,${b}">`).join("")}</div></div>
  ${l.output ? `<div class="term"><pre class="out">${esc(shownOut.join("\n"))}</pre></div>` : ""}`
      : `<div class="term"><div class="termbar"><span>TERMINAL</span><span>OUTPUT</span></div>
  <pre class="out"><span class="prompt">$</span> ${esc(course.command)}${l.input ? `  <span style="color:#8a8a92">&lt; input.txt</span>` : ""}\n${esc(shownOut.join("\n"))}</pre></div>`
  }
  </div></body></html>`;
}

/** El HTML de Shiki con solo las [max] primeras líneas. */
function trimHtml(html, max) {
  const parts = html.split('<span class="line">');
  if (parts.length - 1 <= max) return html;
  return `${parts.slice(0, max + 1).join('<span class="line">')}</code></pre>`;
}

async function drawImages(courses) {
  const require = createRequire(path.join(process.env.PLAYWRIGHT_DIR || ROOT, "node_modules", "x.js"));
  const { chromium } = require("playwright");
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 200 }, deviceScaleFactor: 1 });
  for (const data of courses) {
    const course = COURSES[data.id];
    const dir = path.join(IMAGES, data.id);
    fs.mkdirSync(dir, { recursive: true });
    for (const level of LEVELS) {
      for (const l of data.levels[level] ?? []) {
        await page.setContent(windowHtml(course, level, l));
        l.size = await page.evaluate(() => [document.body.scrollWidth, document.body.scrollHeight]);
        await page.screenshot({
          path: path.join(ROOT, "public", l.image),
          type: "jpeg",
          quality: 82,
          fullPage: true,
        });
      }
    }
    console.log(`imágenes: ${data.id}`);
  }
  await browser.close();
}
