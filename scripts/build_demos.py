#!/usr/bin/env python3
"""Compila las demos de la landing (dmarlonstudio.com/demos) para el sistema
en el que corre: macOS o Windows.

Las demos las exporta el estudio (studio/test/demos_export_test.dart) en
<entrada>/<idioma>/<ejemplo>/ (app.py y demo.json). Cada una se compila con
PyInstaller (una .app en macOS, una carpeta con el .exe en Windows) y queda en
<salida>/<ejemplo>-<idioma>-<macOS|Windows>.zip. Los paquetes de pip que
necesite los declara su código con una línea `REQUIRES = ["paquete", ...]`.

  python3 scripts/build_demos.py <entrada> <salida> [ejemplo ...]
"""

import ast
import json
import os
import plistlib
import re
import subprocess
import unicodedata
import sys
import zipfile
from pathlib import Path

MAC = sys.platform == "darwin"
# Paquetes con binarios que no se publican como universal2 en macOS.
NATIVE = {"pygame"}
WIN = sys.platform == "win32"
OS = "macOS" if MAC else "Windows" if WIN else "Linux"


def run(cmd, cwd):
    print("$", " ".join(str(c) for c in cmd), flush=True)
    subprocess.run([str(c) for c in cmd], cwd=cwd, check=True, shell=WIN)


def zip_dir(src: Path, dest: Path):
    """Comprime la carpeta (o la .app) conservando permisos y enlaces."""
    dest.unlink(missing_ok=True)
    if MAC:
        run(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", src, dest], src.parent)
        return
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
        for f in src.rglob("*"):
            z.write(f, f.relative_to(src.parent))


def safe(name: str) -> str:
    """Nombre de archivo válido en los dos sistemas y sin acentos (codesign
    falla con rutas no ASCII; el nombre con acentos va en Info.plist)."""
    plain = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    return "".join(c for c in plain if c not in '<>:"/\\|?*').strip() or "Demo"


def requires(app: Path):
    """Los paquetes de pip de la línea REQUIRES = [...] del código."""
    m = re.search(r"^REQUIRES = (\[.*?\])", app.read_text(encoding="utf-8"), re.M)
    return ast.literal_eval(m.group(1)) if m else []


def python_demo(d: Path, name: str, title: str) -> Path:
    out = d / "dist"
    packages = requires(d / "app.py")
    if packages:
        run([sys.executable, "-m", "pip", "install", *packages], d)
    run(
        [
            sys.executable, "-m", "PyInstaller", "--noconfirm", "--clean",
            "--windowed", "--name", name,
            # En CI (Python de python.org): una sola .app para Apple Silicon e
            # Intel, salvo con paquetes nativos que no traen las dos (pygame).
            *(["--target-arch", "universal2"] if MAC and os.environ.get("DMS_UNIVERSAL") == "1"
              and not NATIVE.intersection(packages) else []),
            "app.py",
        ],
        d,
    )
    if not MAC:
        return out / name
    app = out / f"{name}.app"
    light_and_sign(app, title)
    return app


def light_and_sign(app: Path, title: str):
    """macOS: las demos se diseñan en claro; que no las oscurezca el modo
    oscuro del sistema. Cambiar Info.plist rompe la firma: se vuelve a firmar
    (firma local, sin certificado)."""
    info = app / "Contents" / "Info.plist"
    with open(info, "rb") as f:
        plist = plistlib.load(f)
    plist["NSRequiresAquaSystemAppearance"] = True
    plist["CFBundleDisplayName"] = title
    with open(info, "wb") as f:
        plistlib.dump(plist, f)
    run(["codesign", "--force", "--deep", "--sign", "-", app], app.parent)
    run(["codesign", "--verify", "--deep", "--strict", app], app.parent)


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    src, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    only = set(sys.argv[3:])
    out.mkdir(parents=True, exist_ok=True)
    built = []
    for meta in sorted(src.glob("*/*/demo.json")):
        demo = json.loads(meta.read_text(encoding="utf-8"))
        seed, lang = demo["seed"], demo["lang"]
        if only and seed not in only:
            continue
        d, name = meta.parent, safe(demo["name"])
        print(f"\n== {seed} ({lang}) ==", flush=True)
        result = python_demo(d, name, demo["name"])
        dest = out / f"{seed}-{lang}-{OS}.zip"
        zip_dir(result, dest)
        built.append(dest)
        print(f"-> {dest.name} ({dest.stat().st_size // 1024} KB)", flush=True)
    print(f"\n{len(built)} demos en {out}")


if __name__ == "__main__":
    main()
