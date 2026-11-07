#!/usr/bin/env python3
"""El proyecto con el IDE de cada curso de bases de datos: la tienda del curso
hecha con DMarlon Studio (studio/lib/code/tk_showcase_shop.dart), de verdad.

    python3 scripts/courses/build_projects.py [curso…]

Cursos: sqlite, postgres, mysql, mongodb, falcondatabase, firebase (por
omisión, todos). Escribe, por curso:

    public/courses/<curso>/project-designer-es.png, -en.png
        el proyecto abierto en el Diseñador del estudio
        (studio/test/shop_projects_screenshots_test.dart);
    public/courses/<curso>/project-app.png (español), project-app-en.png
        la aplicación funcionando con los datos del curso: las ventanas de
        tkinter, fotografiadas con scripts/courses/tk_run.py; las apps de
        Flutter, compiladas para la web y fotografiadas con Playwright
        (scripts/courses/project_shots.mjs: catálogo, filtro y ficha);
    public/courses/<curso>/shop-project.zip (español), shop-project-en.zip
        el proyecto tal como lo guarda el estudio (project.dmsproj y su
        código): se descomprime y se abre con «Abrir proyecto»;
    content/courses/projects/<curso>.json
        los textos (seed, target, es, en: se escriben a mano y se conservan)
        y lo generado (files, designer, app, download, downloads).

Los datos: antes, la tienda del curso (content/courses/<curso>/seed.*) se
carga con studio/tool/db_course.dart en bases de datos que solo usa este
script: el archivo SQLite de la carpeta de trabajo, la base de datos
dms_project de PostgreSQL, MySQL y MongoDB, y el proyecto dms-project del
emulador de Firestore. FalconDatabase se lee del proyecto del curso con la
clave anon (solo lectura). Las ventanas reciben la conexión «shop» por las
variables DMSTUDIO_DB_SHOP_* que les daría el estudio (TkRunner.environment).

Hace falta:
  - los servidores: sh scripts/courses/db_servers.sh start (MySQL 3407,
    MongoDB 27027, Firestore 8095) y PostgreSQL (DMS_COURSE_PG=
    host:puerto:usuario:clave, por defecto localhost:5434:<usuario>:);
  - un Python con tkinter (DMS_PROJECT_PYTHON; si no, se crea un entorno
    con python3.12 de Homebrew en la carpeta de trabajo y se instalan
    pymongo, psycopg y pymysql);
  - Flutter, swiftc y Playwright (PLAYWRIGHT_DIR=<carpeta con
    node_modules/playwright>).

La app de Firebase usa el emulador de serie (127.0.0.1:8080) y el proyecto
dms-cursos; la que se fotografía se compila con el emulador y el proyecto de
arriba (lo único que cambia es lib/db.dart).
"""
import getpass
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

LANDING = Path(__file__).resolve().parents[2]
ROOT = LANDING.parent
STUDIO = ROOT / "studio"
COURSES = LANDING / "content" / "courses"
PUBLIC = LANDING / "public" / "courses"
PROJECTS = COURSES / "projects"
WORK = Path(os.environ.get("DMS_PROJECTS_WORK", Path(tempfile.gettempdir()) / "dms-course-projects"))

DESKTOP = ["sqlite", "postgres", "mysql", "mongodb"]
MOBILE = ["falcondatabase", "firebase"]
ALL = DESKTOP + MOBILE
# El seed de cada curso (y su tipo para db_course.dart).
SEED = {"sqlite": "seed.sql", "postgres": "seed.sql", "mysql": "seed.sql", "mongodb": "seed.json", "firebase": "seed.json"}
# La categoría y el producto que se fotografían en las apps de Flutter.
SHOTS = {"category": "Drinks", "product": "Baguette"}


def run(cmd, cwd=None, env=None, quiet=False):
    print("$", " ".join(str(c) for c in cmd), flush=True)
    r = subprocess.run([str(c) for c in cmd], cwd=cwd, env={**os.environ, **(env or {})},
                       capture_output=quiet, text=True)
    if r.returncode != 0:
        if quiet:
            print(r.stdout[-4000:], r.stderr[-4000:], file=sys.stderr)
        raise SystemExit(f"falló: {cmd[0]} ({r.returncode})")
    return r


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    return list(struct.unpack(">II", head[16:24]))


def connections():
    """Las conexiones «shop» de este script (nunca las de los cursos)."""
    host, port, user, password = (os.environ.get("DMS_COURSE_PG") or f"localhost:5434:{getpass.getuser()}:").split(":")
    return {
        "sqlite": {"path": str(WORK / "data" / "shop.db")},
        "postgres": {"host": host, "port": port, "user": user, "password": password, "database": "dms_project"},
        "mysql": {"host": "127.0.0.1", "port": os.environ.get("DMS_COURSE_MYSQL_PORT", "3407"), "user": "root",
                  "password": "", "database": "dms_project"},
        "mongodb": {"uri": f"mongodb://127.0.0.1:{os.environ.get('DMS_COURSE_MONGO_PORT', '27027')}/dms_project"},
        "firebase": {"project": "dms-project",
                     "emulator": f"127.0.0.1:{os.environ.get('DMS_COURSE_FIRESTORE_PORT', '8095')}"},
    }


def python():
    py = os.environ.get("DMS_PROJECT_PYTHON")
    if py:
        return py
    venv = WORK / "venv"
    if not (venv / "bin" / "python").exists():
        base = next(p for p in ["/opt/homebrew/opt/python@3.12/bin/python3.12",
                                "/usr/local/opt/python@3.12/bin/python3.12"] if os.path.exists(p))
        run([base, "-m", "venv", venv])
        run([venv / "bin" / "python", "-m", "pip", "install", "-q", "pymongo", "psycopg[binary]", "pymysql[rsa]"])
    return str(venv / "bin" / "python")


def seed(courses):
    """La tienda del curso en las bases de datos de este script."""
    (WORK / "data").mkdir(parents=True, exist_ok=True)
    conns = connections()
    for kind, conn in conns.items():
        (WORK / f"conn_{kind}.json").write_text(json.dumps(conn))
    for course in courses:
        if course not in SEED:
            continue
        probe = WORK / ("probe.json" if SEED[course].endswith(".json") else "probe.sql")
        probe.write_text('{"collection": "products", "count": true}\n' if probe.suffix == ".json"
                         else "SELECT COUNT(*) AS n FROM products;\n")
        r = run(["dart", "run", "tool/db_course.dart", course, WORK / f"conn_{course}.json", probe,
                 COURSES / course / SEED[course]], cwd=STUDIO, quiet=True)
        # «Running build hooks...» puede ir delante, en la misma línea.
        last = r.stdout.strip().splitlines()[-1]
        out = json.loads(last[last.index("{"):])
        if "fatal" in out or out.get("error"):
            raise SystemExit(f"{course}: {out.get('fatal') or out.get('error')}")
        print(f"   {course}: {out['results'][0]['rows'][0][0]} productos", flush=True)


def tk_shot(py, app, env, dest):
    winid = WORK / "winid"
    src = LANDING / "scripts" / "courses" / "winid.swift"
    if not winid.exists() or winid.stat().st_mtime < src.stat().st_mtime:
        run(["swiftc", "-O", "-o", winid, src])
    base = WORK / "shot"
    for old in WORK.glob("shot-*.png"):
        old.unlink()
    run([py, LANDING / "scripts" / "courses" / "tk_run.py", app, base], env={**env, "WINID": str(winid)})
    shutil.copy(WORK / "shot-1.png", dest)


def flutter_shot(course, lang, web, dest):
    seed_name = f"dms_shop_{course}"
    if not (web / "web" / "index.html").exists():
        run(["flutter", "create", "--platforms", "web", "--org", "com.dmarlonstudio", "--project-name", seed_name, "."],
            cwd=web, quiet=True)
        shutil.rmtree(web / "test", ignore_errors=True)
    run(["flutter", "build", "web", "--release"], cwd=web, quiet=True)
    run(["node", LANDING / "scripts" / "courses" / "project_shots.mjs", web / "build" / "web", dest,
         SHOTS["category"], SHOTS["product"]], cwd=LANDING)


def zip_project(src, dest):
    if dest.exists():
        dest.unlink()
    # La carpeta del proyecto, con su .gitignore y sin build/.
    run(["zip", "-r", "-X", "-q", dest, src.name, "-x", f"{src.name}/build/*", "-x", "*/__pycache__/*",
         "-x", "*.DS_Store"], cwd=src.parent)


def main():
    courses = [c for c in sys.argv[1:]] or ALL
    for c in courses:
        if c not in ALL:
            raise SystemExit(__doc__)
    WORK.mkdir(parents=True, exist_ok=True)
    py = python()
    seed(courses)
    out, shots = WORK / "out", WORK / "shots"
    shutil.rmtree(out, ignore_errors=True)
    shutil.rmtree(shots, ignore_errors=True)
    run(["flutter", "test", "test/shop_projects_test.dart", "--plain-name", "exportar"], cwd=STUDIO, quiet=True,
        env={"DMS_SHOP_OUT": str(out), "DMS_SHOP_CONN": str(WORK)})
    run(["flutter", "test", "test/shop_projects_screenshots_test.dart"], cwd=STUDIO, quiet=True,
        env={"DMS_SHOP_OUT": str(shots)})
    PROJECTS.mkdir(parents=True, exist_ok=True)
    for course in courses:
        print(f"\n== {course} ==", flush=True)
        pub = PUBLIC / course
        pub.mkdir(parents=True, exist_ok=True)
        url = f"/courses/{course}"
        meta = {lang: json.loads((out / course / lang / "meta.json").read_text()) for lang in ("es", "en")}
        for lang in ("es", "en"):
            shutil.copy(shots / course / f"designer-{lang}.png", pub / f"project-designer-{lang}.png")
            app = pub / ("project-app.png" if lang == "es" else "project-app-en.png")
            if course in DESKTOP:
                env = json.loads((out / course / lang / "env.json").read_text())
                tk_shot(py, out / course / lang / "app.py", env, app)
            else:
                flutter_shot(course, lang, out / course / lang / "web", app)
            folder = out / course / lang / "project" / meta[lang]["folder"]
            zip_project(folder, pub / ("shop-project.zip" if lang == "es" else "shop-project-en.zip"))
        file = PROJECTS / f"{course}.json"
        data = json.loads(file.read_text()) if file.exists() else {}
        unit = meta["es"]["unit"]
        data.update({
            "seed": meta["es"]["seed"],
            "files": [{
                "name": unit if course in DESKTOP else f"lib/{unit}",
                "lang": "python" if course in DESKTOP else "dart",
                "code": meta["es"]["code"],
            }],
            "designer": {"es": f"{url}/project-designer-es.png", "en": f"{url}/project-designer-en.png",
                         "size": png_size(pub / "project-designer-es.png")},
            "app": {"src": f"{url}/project-app.png", "size": png_size(pub / "project-app.png"),
                    "en": {"src": f"{url}/project-app-en.png", "size": png_size(pub / "project-app-en.png")}},
            "download": f"{url}/shop-project.zip",
            "downloads": {"es": f"{url}/shop-project.zip", "en": f"{url}/shop-project-en.zip"},
        })
        # Lo que se escribe a mano, primero.
        order = ["seed", "target", "es", "en", "files", "designer", "app", "download", "downloads"]
        data = {k: data[k] for k in order if k in data} | {k: v for k, v in data.items() if k not in order}
        file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"-> {file.relative_to(LANDING)}", flush=True)


if __name__ == "__main__":
    main()
