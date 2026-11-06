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


def lazbuild() -> str:
    """lazbuild: el de LAZBUILD, el del PATH o el de una instalación normal."""
    import shutil as sh
    for c in (os.environ.get("LAZBUILD"), sh.which("lazbuild"), "/Applications/Lazarus/lazbuild",
              r"C:\lazarus\lazbuild.exe"):
        if c and Path(c).exists():
            return c
    raise SystemExit("Falta lazbuild (Lazarus)")


def mac_openssl(frameworks: Path, archs: set):
    """HTTPS en la .app: libssl.3 y libcrypto.3 de la OpenSSL de Homebrew en
    Contents/Frameworks (la aplicación las busca ahí primero). libssl apunta
    a la libcrypto de al lado (@loader_path), no a la de Homebrew."""
    import shutil as sh
    src = None
    for c in (os.environ.get("OPENSSL_LIB"), "/opt/homebrew/opt/openssl@3/lib",
              "/usr/local/opt/openssl@3/lib"):
        if c and (Path(c) / "libssl.3.dylib").exists():
            src = Path(c)
            break
    if src is None:
        print("aviso: sin OpenSSL 3 de Homebrew; la demo usará la del sistema", flush=True)
        return
    have = set(subprocess.run(["lipo", "-archs", src / "libssl.3.dylib"], capture_output=True,
                              text=True).stdout.split())
    if not have & archs:
        print(f"aviso: la OpenSSL de {src} es {have} y la demo {archs}: no se incluye", flush=True)
        return
    frameworks.mkdir(parents=True, exist_ok=True)
    for lib in ("libcrypto.3.dylib", "libssl.3.dylib"):
        dest = frameworks / lib
        sh.copyfile(src / lib, dest)  # sigue el enlace de opt/ a Cellar/
        dest.chmod(0o755)
        run(["install_name_tool", "-id", f"@loader_path/{lib}", dest], frameworks)
    ssl = frameworks / "libssl.3.dylib"
    deps = subprocess.run(["otool", "-L", ssl], capture_output=True, text=True).stdout
    for line in deps.splitlines()[1:]:
        dep = line.strip().split(" (")[0]
        if dep.endswith("/libcrypto.3.dylib") and not dep.startswith("@"):
            run(["install_name_tool", "-change", dep, "@loader_path/libcrypto.3.dylib", ssl], frameworks)


def pascal_demo(d: Path, name: str, title: str) -> Path:
    """Pascal (Lazarus): lazbuild y, en macOS, una .app hecha a mano."""
    import shutil as sh
    out = d / "dist"
    sh.rmtree(out, ignore_errors=True)
    if MAC:
        # Una .app para Apple Silicon e Intel (cada una con su compilación;
        # lipo las une). Si falta una de las dos, la que se pueda.
        built = []
        for cpu, arch in (("aarch64", "arm64"), ("x86_64", "x86_64")):
            try:
                run([lazbuild(), "--build-mode=Default", "--ws=cocoa", f"--cpu={cpu}", "app.lpi"], d)
            except subprocess.CalledProcessError:
                print(f"aviso: no se pudo compilar para {arch}", flush=True)
                continue
            sh.move(d / "app", d / f"app-{arch}")
            built.append(arch)
        if not built:
            raise SystemExit(f"{name}: no compila")
        if len(built) > 1:
            run(["lipo", "-create", *[f"app-{a}" for a in built], "-output", "app"], d)
        else:
            sh.copy(d / f"app-{built[0]}", d / "app")
        app = out / f"{name}.app"
        (app / "Contents" / "MacOS").mkdir(parents=True)
        (app / "Contents" / "Resources").mkdir()
        sh.copy(d / "app", app / "Contents" / "MacOS" / "app")
        mac_openssl(app / "Contents" / "Frameworks", set(built))
        with open(app / "Contents" / "Info.plist", "wb") as f:
            plistlib.dump({
                "CFBundleExecutable": "app",
                "CFBundleIdentifier": "com.dmarlonstudio.demo." + re.sub(r"[^A-Za-z0-9]", "", name).lower(),
                "CFBundleName": title,
                "CFBundleDisplayName": title,
                "CFBundlePackageType": "APPL",
                "CFBundleShortVersionString": "1.0",
                "NSHighResolutionCapable": True,
                "NSPrincipalClass": "NSApplication",
            }, f)
        light_and_sign(app, title)
        return app
    run([lazbuild(), "--build-mode=Default", "app.lpi"], d)
    folder = out / name
    folder.mkdir(parents=True)
    sh.copy(d / "app.exe", folder / f"{name}.exe")
    # HTTPS: fphttpclient necesita las DLL de OpenSSL junto al .exe (las de
    # OpenSSL 3 para Windows de 64 bits: libssl-3-x64.dll y libcrypto-3-x64.dll).
    ssl = Path(os.environ.get("OPENSSL_BIN", r"C:\Program Files\OpenSSL\bin"))
    for dll in ("libssl-3-x64.dll", "libcrypto-3-x64.dll"):
        if (ssl / dll).exists():
            sh.copy(ssl / dll, folder)
        else:
            print(f"aviso: falta {ssl / dll}: la demo no podrá usar HTTPS", flush=True)
    return folder


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
        if demo.get("kind") == "pascal":
            result = pascal_demo(d, name, demo["name"])
        else:
            result = python_demo(d, name, demo["name"])
        dest = out / f"{seed}-{lang}-{OS}.zip"
        zip_dir(result, dest)
        built.append(dest)
        print(f"-> {dest.name} ({dest.stat().st_size // 1024} KB)", flush=True)
    print(f"\n{len(built)} demos en {out}")


if __name__ == "__main__":
    main()
