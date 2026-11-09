#!/usr/bin/env python3
"""Compila las demos móviles y web de la landing (dmarlonstudio.com/demos).

Las exporta el estudio (DMS_LIVE_OUT=<entrada> flutter test
test/demos_export_test.dart) en <entrada>/<idioma>/<ejemplo>/ con un demo.json.

  python3 scripts/build_live_demos.py web <entrada> <landing/public/demos/live>
      Cada demo, compilada para el navegador en <salida>/<idioma>/<ejemplo>/
      (se abre con su index.html): HTML tal cual, React y Vue con Vite, y
      Flutter con `flutter build web`. Se sube con la landing.
      Las de Next.js (con servidor) no se compilan aparte: van dentro de la
      propia landing, en landing/app/(live)/demos/live/<idioma>/<ejemplo>/
      (sus páginas, su API y su lib/ en _lib), y Vercel las sirve con su
      servidor.

  python3 scripts/build_live_demos.py android <entrada> <salida>
      Las de Flutter como APK de Android: <ejemplo>-<idioma>-Android.apk
      (en GitHub Actions, que tiene el SDK de Android y Java).
"""

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

WIN = sys.platform == "win32"


def run(cmd, cwd):
    print("$", " ".join(str(c) for c in cmd), flush=True)
    subprocess.run([str(c) for c in cmd], cwd=cwd, check=True, shell=WIN)


def demos(src: Path, only):
    for meta in sorted(src.glob("*/*/demo.json")):
        demo = json.loads(meta.read_text(encoding="utf-8"))
        if not only or demo["seed"] in only:
            yield meta.parent, demo


def fresh(dest: Path):
    shutil.rmtree(dest, ignore_errors=True)
    dest.parent.mkdir(parents=True, exist_ok=True)


def web_html(d: Path, dest: Path):
    fresh(dest)
    shutil.copytree(d, dest, ignore=shutil.ignore_patterns("demo.json", "README.md"))


def web_vite(d: Path, dest: Path):
    run(["npm", "install", "--no-audit", "--no-fund"], d)
    fresh(dest)
    run(["npx", "vite", "build", "--base", "./", "--outDir", dest, "--emptyOutDir"], d)
    shutil.rmtree(d / "node_modules", ignore_errors=True)


def web_next(d: Path, dest: Path):
    """El proyecto de Next.js dentro de la landing: app/ en dest y lib/ en
    dest/_lib (una carpeta privada: no es una ruta), con los import de lib
    corregidos."""
    fresh(dest)
    for f in sorted((d / "app").rglob("*")):
        if f.is_dir():
            continue
        rel = f.relative_to(d / "app")
        depth = len(rel.parts)            # app/page.js: 1; app/x/page.js: 2
        text = f.read_text(encoding="utf-8")
        up = "../" * (depth - 1) or "./"
        text = text.replace("../" * depth + "lib/", up + "_lib/")
        out = dest / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    shutil.copytree(d / "lib", dest / "_lib")


def flutter_create(d: Path, seed: str, platforms: str):
    run(["flutter", "create", "--platforms", platforms, "--org", "com.dmarlonstudio",
         "--project-name", f"dms_{seed}", "."], d)
    shutil.rmtree(d / "test", ignore_errors=True)


def web_flutter(d: Path, dest: Path, seed: str, href: str):
    flutter_create(d, seed, "web")
    run(["flutter", "build", "web", "--release", "--base-href", href], d)
    fresh(dest)
    shutil.copytree(d / "build" / "web", dest)
    # CanvasKit se carga de la CDN de Google (lo que hace Flutter por
    # omisión): la copia local solo ocuparía sitio en la web.
    shutil.rmtree(dest / "canvaskit", ignore_errors=True)
    shutil.rmtree(d / "build", ignore_errors=True)


def android(d: Path, out: Path, demo: dict):
    seed = demo["seed"]
    flutter_create(d, seed, "android")
    # El nombre que se ve en el teléfono.
    manifest = d / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    label = demo["name"].replace("&", "&amp;").replace('"', "&quot;")
    manifest.write_text(re.sub(r'android:label="[^"]*"', f'android:label="{label}"', text, count=1),
                        encoding="utf-8")
    run(["flutter", "build", "apk", "--release"], d)
    apk = d / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
    dest = out / f"{seed}-{demo['lang']}-Android.apk"
    shutil.copy(apk, dest)
    print(f"-> {dest.name} ({dest.stat().st_size // 1024} KB)", flush=True)
    shutil.rmtree(d / "build", ignore_errors=True)


def main():
    if len(sys.argv) < 4 or sys.argv[1] not in ("web", "android"):
        raise SystemExit(__doc__)
    mode, src, out = sys.argv[1], Path(sys.argv[2]).resolve(), Path(sys.argv[3]).resolve()
    only = set(sys.argv[4:])
    out.mkdir(parents=True, exist_ok=True)
    for d, demo in demos(src, only):
        seed, lang, kind = demo["seed"], demo["lang"], demo["kind"]
        print(f"\n== {seed} ({lang}, {kind}) ==", flush=True)
        if mode == "android":
            if kind == "flutter":
                android(d, out, demo)
            continue
        dest = out / lang / seed
        if kind == "next":
            # out es landing/public/demos/live.
            landing = out.parents[2]
            dest = landing / "app" / "(live)" / "demos" / "live" / lang / seed
            web_next(d, dest)
        elif kind == "html":
            web_html(d, dest)
        elif kind in ("react", "vue"):
            web_vite(d, dest)
        else:
            web_flutter(d, dest, seed, f"/demos/live/{lang}/{seed}/")
        print(f"-> {dest}", flush=True)


if __name__ == "__main__":
    main()
