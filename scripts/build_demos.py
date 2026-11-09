#!/usr/bin/env python3
"""Compila las demos de la landing (dmarlonstudio.com/demos) para el sistema
en el que corre: macOS o Windows.

Las demos las exporta el estudio (studio/test/demos_export_test.dart) en
<entrada>/<idioma>/<ejemplo>/ (app.py y demo.json), en español y en inglés.
Cada demo sale como UNA aplicación con los dos idiomas y el menú
Idioma / Language (scripts/demo-lang): la de tkinter lleva los dos programas
y un lanzador (PyInstaller: una .app en macOS, una carpeta con el .exe en
Windows); las de Pascal (lazbuild) y C++ (FLTK enlazado de forma estática:
fltk-config de FLTK_CONFIG o del PATH en macOS, el de MSYS2 en Windows) se
compilan una vez por idioma y los dos ejecutables van juntos. Queda en
<salida>/<ejemplo>-<macOS|Windows>.zip y, con DMS_APPS_OUT=<carpeta>, la
aplicación también en esa carpeta (para probarla en local). Los paquetes de
pip que necesite una demo los declara su código con una línea
`REQUIRES = ["paquete", ...]`.

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


ICONS = Path(__file__).with_name("demo-icons")
LANG_DIR = Path(__file__).with_name("demo-lang")
LANGS = ("es", "en")


def icon(seed: str, d: Path):
    """El icono de la demo (demo-icons/<ejemplo>.png) como .icns en macOS y
    .ico en Windows, en la carpeta de la demo. None si no tiene o falta Pillow."""
    png = ICONS / f"{seed}.png"
    if not png.exists() or not (MAC or WIN):
        return None
    try:
        from PIL import Image
    except ImportError:
        print("aviso: sin Pillow (pip install pillow): la demo va sin icono", flush=True)
        return None
    im = Image.open(png).convert("RGBA")
    if MAC:
        dest = d / "app.icns"
        im.save(dest)
    else:
        dest = d / "app.ico"
        im.save(dest, sizes=[(n, n) for n in (16, 24, 32, 48, 64, 128, 256)])
    return dest


def rcedit_icon(exe: Path, ico: Path):
    """Windows: pone el icono en un .exe ya compilado (rcedit, el de Electron)."""
    import tempfile
    tool = Path(tempfile.gettempdir()) / "dms-rcedit"
    bin_ = tool / "node_modules" / "rcedit" / "bin" / "rcedit-x64.exe"
    try:
        if not bin_.exists():
            run(["npm", "install", "--silent", "--prefix", tool, "rcedit@4.0.1"], exe.parent)
        run([bin_, exe, "--set-icon", ico], exe.parent)
    except (subprocess.CalledProcessError, OSError) as e:
        print(f"aviso: el .exe va sin icono ({e})", flush=True)


def requires(app: Path):
    """Los paquetes de pip de la línea REQUIRES = [...] del código."""
    m = re.search(r"^REQUIRES = (\[.*?\])", app.read_text(encoding="utf-8"), re.M)
    return ast.literal_eval(m.group(1)) if m else []


def python_demo(src: dict, work: Path, name: str, titles: dict, seed: str) -> Path:
    """tkinter: los dos programas (app_es.py y app_en.py) y el lanzador
    (app.py), en una sola compilación de PyInstaller."""
    import shutil as sh
    sh.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    for lang in LANGS:
        sh.copy(src[lang] / "app.py", work / f"app_{lang}.py")
    sh.copy(LANG_DIR / "launcher.py", work / "app.py")
    out = work / "dist"
    ico = icon(seed, work)
    packages = sorted({p for lang in LANGS for p in requires(work / f"app_{lang}.py")})
    if packages:
        run([sys.executable, "-m", "pip", "install", *packages], work)
    run(
        [
            sys.executable, "-m", "PyInstaller", "--noconfirm", "--clean",
            "--windowed", "--name", name,
            "--hidden-import", "app_es", "--hidden-import", "app_en", "--paths", ".",
            *(["--icon", ico] if ico else []),
            # En CI (Python de python.org): una sola .app para Apple Silicon e
            # Intel, salvo con paquetes nativos que no traen las dos (pygame).
            *(["--target-arch", "universal2"] if MAC and os.environ.get("DMS_UNIVERSAL") == "1"
              and not NATIVE.intersection(packages) else []),
            "app.py",
        ],
        work,
    )
    if not MAC:
        return out / name
    app = out / f"{name}.app"
    light_and_sign(app, titles)
    return app


def light_and_sign(app: Path, titles: dict, aqua: bool = True):
    """macOS: las demos se diseñan en claro; que no las oscurezca el modo
    oscuro del sistema (salvo las que tienen su tema oscuro: aqua=False). El
    nombre que enseña el Finder va en el idioma del sistema (es.lproj y
    en.lproj). Cambiar Info.plist rompe la firma: se vuelve a firmar."""
    info = app / "Contents" / "Info.plist"
    with open(info, "rb") as f:
        plist = plistlib.load(f)
    if aqua:
        plist["NSRequiresAquaSystemAppearance"] = True
    plist["CFBundleDisplayName"] = titles["es"]
    plist["CFBundleDevelopmentRegion"] = "es"
    plist["CFBundleLocalizations"] = list(LANGS)
    plist["LSHasLocalizedDisplayName"] = True
    with open(info, "wb") as f:
        plistlib.dump(plist, f)
    for lang in LANGS:
        lproj = app / "Contents" / "Resources" / f"{lang}.lproj"
        lproj.mkdir(parents=True, exist_ok=True)
        t = titles[lang].replace('"', '\\"')
        (lproj / "InfoPlist.strings").write_text(
            f'"CFBundleDisplayName" = "{t}";\n"CFBundleName" = "{t}";\n', encoding="utf-8")
    sign(app)


# Firma de macOS. Con DMS_SIGN_ID (el certificado «Developer ID Application»,
# lo pone el flujo de CI) cada binario se firma con él, con el runtime
# endurecido y sello de tiempo, que es lo que pide la notarización de Apple.
# Sin él, firma local: la demo funciona, pero macOS avisa al abrirla.
SIGN_ID = os.environ.get("DMS_SIGN_ID", "")
ENTITLEMENTS = Path(__file__).with_name("demos.entitlements")


def macho(f: Path) -> bool:
    """¿Es un ejecutable o una biblioteca de macOS (Mach-O)?"""
    if f.is_symlink() or not f.is_file():
        return False
    with open(f, "rb") as h:
        magic = h.read(4)
    return magic in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xca\xfe\xba\xbe",
                     b"\xfe\xed\xfa\xcf", b"\xfe\xed\xfa\xce", b"\xbe\xba\xfe\xca")


def sign(app: Path):
    if not SIGN_ID:
        run(["codesign", "--force", "--deep", "--sign", "-", app], app.parent)
        run(["codesign", "--verify", "--deep", "--strict", app], app.parent)
        return
    base = ["codesign", "--force", "--timestamp", "--options", "runtime",
            "--entitlements", ENTITLEMENTS, "--sign", SIGN_ID]
    contents = app / "Contents"
    main = contents / "MacOS"
    # De dentro afuera: las bibliotecas sueltas, los .framework y, al final,
    # la .app (que sella todo lo que lleva dentro).
    inner = [f for f in contents.rglob("*") if macho(f) and f.parent != main]
    for f in sorted(inner, key=lambda f: -len(f.parts)):
        run([*base, f], app.parent)
    frameworks = [v for fw in contents.rglob("*.framework") if not fw.is_symlink()
                  for v in (fw / "Versions").glob("*") if v.is_dir() and not v.is_symlink()]
    for v in sorted(frameworks, key=lambda f: -len(f.parts)):
        run([*base, v], app.parent)
    for f in main.iterdir():
        if macho(f) and f.name != app.stem:
            run([*base, f], app.parent)
    run([*base, app], app.parent)
    run(["codesign", "--verify", "--deep", "--strict", "--verbose=2", app], app.parent)


def notarize(apps):
    """Notariza las .app en Apple y les grapa el resultado (stapler), para que
    abran sin aviso también sin conexión. Se envían todas y luego se espera a
    cada una: Apple las revisa a la vez. Necesita la clave de la API de App
    Store Connect: DMS_NOTARY_KEY (ruta del .p8), DMS_NOTARY_KEY_ID y
    DMS_NOTARY_ISSUER."""
    key = os.environ.get("DMS_NOTARY_KEY")
    if not (MAC and SIGN_ID and key and apps):
        return
    auth = ["--key", key, "--key-id", os.environ["DMS_NOTARY_KEY_ID"],
            "--issuer", os.environ["DMS_NOTARY_ISSUER"]]
    sent = []
    for app in apps:
        pkg = app.with_suffix(".notary.zip")
        zip_dir(app, pkg)
        res = subprocess.run(["xcrun", "notarytool", "submit", pkg, *auth, "--output-format", "json"],
                             capture_output=True, text=True, check=True)
        sent.append((app, pkg, json.loads(res.stdout)["id"]))
        print(f"notarización enviada: {app.name} ({sent[-1][2]})", flush=True)
    failed = []
    for app, pkg, sid in sent:
        res = subprocess.run(["xcrun", "notarytool", "wait", sid, *auth, "--timeout", "45m",
                              "--output-format", "json"], capture_output=True, text=True)
        status = (json.loads(res.stdout or "{}")).get("status", "?")
        print(f"{app.name}: {status}", flush=True)
        pkg.unlink(missing_ok=True)
        if status != "Accepted":
            subprocess.run(["xcrun", "notarytool", "log", sid, *auth])
            failed.append(app.name)
            continue
        run(["xcrun", "stapler", "staple", app], app.parent)
    if failed:
        raise SystemExit(f"Apple no notarizó: {', '.join(failed)}")


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


def lang_unit(d: Path, lang: str, other: str):
    """Pascal: la unidad dmslang (el menú Idioma y abrir el otro ejecutable),
    en el «uses» del programa."""
    text = (LANG_DIR / "dmslang.pas").read_text(encoding="utf-8")
    (d / "dmslang.pas").write_text(text.replace("@OWN@", lang).replace("@OTHER@", other),
                                   encoding="utf-8")
    lpr = d / "app.lpr"
    code = lpr.read_text(encoding="utf-8")
    if "dmslang" not in code:
        if "Interfaces, Forms," not in code:
            raise SystemExit(f"{d}: app.lpr sin «Interfaces, Forms,»")
        lpr.write_text(code.replace("Interfaces, Forms,", "Interfaces, Forms, dmslang,", 1),
                       encoding="utf-8")


def pascal_binary(d: Path, name: str):
    """Compila con lazbuild: en macOS, el ejecutable para Apple Silicon e
    Intel (lipo une las dos compilaciones; si falta una, la que se pueda).
    Devuelve (ejecutable, arquitecturas)."""
    import shutil as sh
    if not MAC:
        run([lazbuild(), "--build-mode=Default", "app.lpi"], d)
        return d / "app.exe", set()
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
    return d / "app", set(built)


def pascal_demo(src: dict, name: str, titles: dict, seed: str) -> Path:
    """Pascal (Lazarus): un ejecutable por idioma y, en macOS, una .app hecha
    a mano con los dos (Contents/MacOS/app en español y app-en en inglés)."""
    import shutil as sh
    out = src["es"] / "dist"
    ico = icon(seed, src["es"])
    sh.rmtree(out, ignore_errors=True)
    if MAC:
        files = {"es": "app", "en": "app-en"}
    else:
        files = {"es": f"{name}.exe", "en": f"{name}-en.exe"}
    bins, archs = {}, set()
    for lang in LANGS:
        other = files["en" if lang == "es" else "es"]
        lang_unit(src[lang], lang, other)
        bins[lang], a = pascal_binary(src[lang], name)
        archs = archs | a if archs else a
    if MAC:
        app = out / f"{name}.app"
        (app / "Contents" / "MacOS").mkdir(parents=True)
        (app / "Contents" / "Resources").mkdir()
        for lang in LANGS:
            sh.copy(bins[lang], app / "Contents" / "MacOS" / files[lang])
        mac_openssl(app / "Contents" / "Frameworks", archs)
        if ico:
            sh.copy(ico, app / "Contents" / "Resources" / "app.icns")
        with open(app / "Contents" / "Info.plist", "wb") as f:
            plistlib.dump({
                **({"CFBundleIconFile": "app.icns"} if ico else {}),
                "CFBundleExecutable": "app",
                "CFBundleIdentifier": "com.dmarlonstudio.demo." + seed.replace("_", ""),
                "CFBundleName": titles["es"],
                "CFBundleDisplayName": titles["es"],
                "CFBundlePackageType": "APPL",
                "CFBundleShortVersionString": "1.0",
                "NSHighResolutionCapable": True,
                # La LCL crea la aplicación con esta clase y espera la suya:
                # con NSApplication la demo se cierra al tocar un campo de texto.
                "NSPrincipalClass": "TCocoaApplication",
            }, f)
        light_and_sign(app, titles)
        return app
    folder = out / name
    folder.mkdir(parents=True)
    for lang in LANGS:
        sh.copy(bins[lang], folder / files[lang])
        if ico:
            rcedit_icon(folder / files[lang], ico)
    # HTTPS: fphttpclient necesita las DLL de OpenSSL junto al .exe (las de
    # OpenSSL 3 para Windows de 64 bits: libssl-3-x64.dll y libcrypto-3-x64.dll).
    ssl = Path(os.environ.get("OPENSSL_BIN", r"C:\Program Files\OpenSSL\bin"))
    for dll in ("libssl-3-x64.dll", "libcrypto-3-x64.dll"):
        if (ssl / dll).exists():
            sh.copy(ssl / dll, folder)
        else:
            print(f"aviso: falta {ssl / dll}: la demo no podrá usar HTTPS", flush=True)
    return folder


def fltk_flags():
    """(cxxflags, ldflags) de FLTK en macOS, con las bibliotecas de FLTK,
    libpng y libjpeg como .a (que la .app no dependa de Homebrew)."""
    import shutil as sh
    cfg = os.environ.get("FLTK_CONFIG") or sh.which("fltk-config")
    if not cfg:
        raise SystemExit("Falta FLTK (brew install fltk)")

    def ask(what):
        out = subprocess.run([cfg, "--use-images", what], capture_output=True, text=True, check=True).stdout
        return out.split()

    ld = ask("--ldflags")
    dirs = [f[2:] for f in ld if f.startswith("-L")] + ["/opt/homebrew/lib", "/usr/local/lib"]
    out = []
    for f in ld:
        name = f[2:] if f.startswith("-l") else None
        archive = None
        if name and name not in ("z", "pthread", "c++", "m"):
            archive = next((Path(d) / f"lib{name}.a" for d in dirs if (Path(d) / f"lib{name}.a").exists()), None)
        out.append(str(archive) if archive else f)
    return ask("--cxxflags"), out


def lang_header(d: Path, lang: str, other: str):
    """C++: dmslang.h (el menú Idioma y abrir el otro ejecutable) y main()
    que lo usa."""
    text = (LANG_DIR / "dmslang.h").read_text(encoding="utf-8")
    text = text.replace('#define DMS_LANG "es"', f'#define DMS_LANG "{lang}"')
    text = text.replace('#define DMS_OTHER "app-en"', f'#define DMS_OTHER "{other}"')
    (d / "dmslang.h").write_text(text, encoding="utf-8")
    main = d / "main.cpp"
    code = main.read_text(encoding="utf-8")
    old = "  return dms_run<Form1>(argc, argv);"
    if "dms_lang_start" not in code:
        if old not in code:
            raise SystemExit(f"{d}: main.cpp sin «{old.strip()}»")
        code = code.replace(old, "  dms_lang_start();\n  return dms_lang_finish(dms_run<Form1>(argc, argv));", 1)
        code = code.replace("int main(", '#include "dmslang.h"\n\nint main(', 1)
        main.write_text(code, encoding="utf-8")


def cpp_binary(d: Path, name: str):
    """Compila main.cpp con FLTK. En macOS, estático salvo los frameworks del
    sistema; en Windows, el g++ y el fltk-config de MSYS2 (UCRT64), desde su
    bash para que las rutas de fltk-config (/ucrt64/...) se entiendan:
    primero todo estático (un solo .exe); si no se puede, con las DLL de
    MSYS2. Devuelve (ejecutable, DLL que lleva al lado)."""
    if MAC:
        cflags, ldflags = fltk_flags()
        env = {**os.environ, "MACOSX_DEPLOYMENT_TARGET": os.environ.get("MACOSX_DEPLOYMENT_TARGET", "11.0")}
        cmd = ["c++", "-std=c++17", "-O2", *cflags, "main.cpp", "-o", "app", *ldflags,
               "-framework", "CoreFoundation"]
        print("$", " ".join(cmd), flush=True)
        subprocess.run(cmd, cwd=d, check=True, env=env)
        # Nada de Homebrew dentro: si quedara alguna biblioteca suya, se avisa.
        deps = subprocess.run(["otool", "-L", d / "app"], capture_output=True, text=True).stdout
        for line in deps.splitlines()[1:]:
            if "/opt/homebrew/" in line or "/usr/local/" in line:
                print(f"aviso: la demo depende de {line.strip().split(' (')[0]}", flush=True)
        return d / "app", []
    root = Path(os.environ.get("MSYS2_ROOT", r"C:\msys64"))
    bash = root / "usr" / "bin" / "bash.exe"
    if not bash.exists():
        raise SystemExit(f"Falta MSYS2 en {root} (pacman -S mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-fltk)")
    env = {**os.environ, "MSYSTEM": "UCRT64", "CHERE_INVOKING": "1"}
    base = ("g++ -std=c++17 -O2 -s $(fltk-config --use-images --cxxflags) main.cpp -o app.exe "
            "-mwindows -static-libgcc -static-libstdc++ ")
    static = base + "-static $(fltk-config --use-images --ldflags) -lshell32 -lole32 -luuid -ladvapi32 -lws2_32"
    shared = base + "$(fltk-config --use-images --ldflags) -lshell32 -lole32 -luuid -ladvapi32 -lws2_32"

    def sh_run(script):
        print("$", script, flush=True)
        return subprocess.run([str(bash), "-lc", script], cwd=d, env=env).returncode

    dlls = []
    if sh_run(static) != 0:
        print("aviso: no se pudo enlazar estático; se copian las DLL de MSYS2", flush=True)
        if sh_run(shared) != 0:
            raise SystemExit(f"{name}: no compila")
        listing = subprocess.run([str(bash), "-lc", "ldd app.exe"], cwd=d, env=env, capture_output=True, text=True).stdout
        for line in listing.splitlines():
            m = re.search(r"=> (/ucrt64/bin/\S+\.dll)", line)
            if m:
                dlls.append(root / m.group(1).lstrip("/"))
    return d / "app.exe", dlls


def cpp_demo(src: dict, name: str, titles: dict, seed: str) -> Path:
    """C++ con FLTK: un ejecutable por idioma; en macOS, una .app hecha a mano
    con los dos (app y app-en); en Windows, los dos .exe en una carpeta."""
    import shutil as sh
    out = src["es"] / "dist"
    ico = icon(seed, src["es"])
    sh.rmtree(out, ignore_errors=True)
    files = {"es": "app", "en": "app-en"} if MAC else {"es": f"{name}.exe", "en": f"{name}-en.exe"}
    bins, dlls = {}, []
    for lang in LANGS:
        lang_header(src[lang], lang, files["en" if lang == "es" else "es"])
        bins[lang], extra = cpp_binary(src[lang], name)
        dlls += extra
    if MAC:
        archs = subprocess.run(["lipo", "-archs", bins["es"]], capture_output=True, text=True).stdout.split()
        app = out / f"{name}.app"
        (app / "Contents" / "MacOS").mkdir(parents=True)
        (app / "Contents" / "Resources").mkdir()
        for lang in LANGS:
            sh.copy(bins[lang], app / "Contents" / "MacOS" / files[lang])
        if ico:
            sh.copy(ico, app / "Contents" / "Resources" / "app.icns")
        with open(app / "Contents" / "Info.plist", "wb") as f:
            plistlib.dump({
                **({"CFBundleIconFile": "app.icns"} if ico else {}),
                "CFBundleExecutable": "app",
                "CFBundleIdentifier": "com.dmarlonstudio.demo." + seed.replace("_", ""),
                "CFBundleName": titles["es"],
                "CFBundleDisplayName": titles["es"],
                "CFBundlePackageType": "APPL",
                "CFBundleShortVersionString": "1.0",
                "LSMinimumSystemVersion": os.environ.get("MACOSX_DEPLOYMENT_TARGET", "11.0"),
                "NSHighResolutionCapable": True,
            }, f)
        print(f"{name}: {' + '.join(archs)}", flush=True)
        # Tiene tema oscuro propio: se deja que siga al del sistema.
        light_and_sign(app, titles, aqua=False)
        return app
    folder = out / name
    folder.mkdir(parents=True)
    for lang in LANGS:
        sh.copy(bins[lang], folder / files[lang])
        if ico:
            rcedit_icon(folder / files[lang], ico)
    for dll in set(dlls):
        sh.copy(dll, folder)
    return folder


def main():
    import shutil as sh
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    src, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    only = set(sys.argv[3:])
    apps_out = os.environ.get("DMS_APPS_OUT")
    out.mkdir(parents=True, exist_ok=True)
    # Cada demo, con sus dos idiomas: {semilla: {idioma: (carpeta, demo.json)}}.
    demos = {}
    for meta in sorted(src.glob("*/*/demo.json")):
        demo = json.loads(meta.read_text(encoding="utf-8"))
        demos.setdefault(demo["seed"], {})[demo["lang"]] = (meta.parent, demo)
    built = []
    for seed, langs in sorted(demos.items()):
        if only and seed not in only:
            continue
        missing = [lang for lang in LANGS if lang not in langs]
        if missing:
            raise SystemExit(f"{seed}: falta en {', '.join(missing)}")
        dirs = {lang: langs[lang][0] for lang in LANGS}
        titles = {lang: langs[lang][1]["name"] for lang in LANGS}
        name, kind = safe(titles["es"]), langs["es"][1].get("kind")
        print(f"\n== {seed} (es + en) ==", flush=True)
        if kind == "pascal":
            result = pascal_demo(dirs, name, titles, seed)
        elif kind == "cpp":
            result = cpp_demo(dirs, name, titles, seed)
        else:
            result = python_demo(dirs, src / "_both" / seed, name, titles, seed)
        built.append((result, out / f"{seed}-{OS}.zip"))
    notarize([r for r, _ in built if r.suffix == ".app"])
    for result, dest in built:
        zip_dir(result, dest)
        print(f"-> {dest.name} ({dest.stat().st_size // 1024} KB)", flush=True)
        if apps_out:
            target = Path(apps_out) / result.name
            Path(apps_out).mkdir(parents=True, exist_ok=True)
            sh.rmtree(target, ignore_errors=True)
            if MAC:
                run(["ditto", result, target], result.parent)
            else:
                sh.copytree(result, target, symlinks=True)
    print(f"\n{len(built)} demos en {out}")


if __name__ == "__main__":
    main()
