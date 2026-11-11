/**
 * «Cómo se hizo» de cada demo: los pasos en DMarlon Studio, con capturas del
 * IDE (studio/test/examples_screenshots_test.dart, lista `made`: el Diseñador,
 * la pestaña Código y la del código generado, en public/examples/<idioma>/)
 * y fragmentos del código de verdad del ejemplo.
 */
import type { Lang } from "@/lib/i18n";

/** La captura del IDE: el Diseñador, la pestaña Código o el código generado. */
export type IdeShot = "design" | "code" | "generated";

export type MadeStep = {
  title: string;
  text: string;
  shot?: IdeShot;
  /** Un fragmento del código del ejemplo: el archivo y sus líneas. */
  code?: { file: string; text: string };
};

/** La ficha técnica: el lenguaje, la tecnología, los componentes del
 * Diseñador (y para qué sirve cada uno) y las bibliotecas o APIs. */
export type TechSheet = {
  language: string;
  target: string;
  components: { name: string; kind: string; text: string }[];
  apis: string[];
};

export type DemoMade = { intro: string; tech: TechSheet; steps: MadeStep[] };

export const ideImage = (seed: string, lang: Lang, shot: IdeShot) =>
  `/examples/${lang}/${seed}${shot === "design" ? "" : `-${shot}`}.jpg`;

// ---- Docker en la barra de menús (Pascal): fragmentos de Form1.pas
const dockerTray = `TrayMenu := TPopupMenu.Create(Self);
Tray := TTrayIcon.Create(Self);
Tray.PopUpMenu := TrayMenu;
Tray.OnClick := @TrayClick;
Application.QueueAsyncCall(@StartUp, 0);

procedure TForm1.StartUp(Data: PtrInt);
begin
  {$IFDEF DARWIN}
  NSApp.setActivationPolicy(NSApplicationActivationPolicyAccessory);
  {$ENDIF}
  Rebuild;
  SetIcon;
  Tray.Show;
  Tick.Enabled := True;
  Reload;
end;`;

const dockerJob = `const
  ListFormat = '{{.ID}}'#9'{{.Names}}'#9'{{.Image}}'#9'{{.State}}'#9 +
    '{{.Status}}'#9'{{.Ports}}'#9'{{.Label "com.docker.compose.project"}}';

procedure TDockJob.Execute;
var
  V: string;
begin
  if IsList then
  begin
    Code := RunDocker(Exe, ['ps', '-a', '--no-trunc', '--format', ListFormat], Output);
    if (Code = 0) and WantVersion and
      (RunDocker(Exe, ['version', '--format', '{{.Server.Version}}'], V) = 0) then
      Version := Trim(V);
  end
  else
    Code := RunDocker(Exe, Args, Output);
end;

procedure TForm1.Tick_timer;
begin
  Reload;
end;`;

const dockerPorts = `// «0.0.0.0:8080->80/tcp, :::8080->80/tcp» → http://localhost:8080
if (R = '443') or (R = '8443') or (HostPort = '443') or (HostPort = '8443') then
  Url := 'https://'
else
  Url := 'http://';
Url := Url + Host + ':' + HostPort;`;

const dockerMenu = `for k := 0 to High(B.Urls) do
  AddItem(Sub, Fmt(tx_OPEN, [B.Urls[k]]), 'open'#9 + B.Urls[k], H);
AddSep(Sub);
AddItem(Sub, tx_STOP, 'stop'#9 + B.Id, H);
AddItem(Sub, tx_RESTART, 'restart'#9 + B.Id, H);

// …
if (K = 'open') or (K = 'url') then
  OpenURL(V)
else if K = 'stop' then
  Run(['stop', V], [V], tx_STOPPING)`;

// ---- Lanzador de apps (Pascal): fragmentos de Form1.pas
const launcherScan = `function SelfPath: string;
var
  P: string;
begin
  P := ExpandFileName(ParamStr(0));
  Result := P;
  {$IFDEF DARWIN}
  P := ExtractFileDir(ExtractFileDir(ExtractFileDir(P)));
  if LowerCase(ExtractFileExt(P)) = '.app' then Result := P;
  {$ENDIF}
end;

function HomeDir: string;
begin
  Result := ExtractFileDir(SelfPath);
end;

// …
if SameFileName(ExcludeTrailingPathDelimiter(P), SelfPath) then Continue;
if E = '.app' then
  AddApp(List, P)
else if Deep and ((R.Attr and faDirectory) <> 0) then
  ScanDir(List, P, False);`;

const launcherIcon = `Img := NSWorkspace.sharedWorkspace.iconForFile(NS(Path));
Rep := NSBitmapImageRep(NSBitmapImageRep.alloc.initWithBitmapDataPlanes_pixelsWide_pixelsHigh__colorSpaceName_bitmapFormat_bytesPerRow_bitsPerPixel(
  nil, Size, Size, 8, 4, True, False, NSDeviceRGBColorSpace, 0, Size * 4, 32));
Ctx := NSGraphicsContext.graphicsContextWithBitmapImageRep(Rep);
NSGraphicsContext.classSaveGraphicsState;
NSGraphicsContext.setCurrentContext(Ctx);
Img.drawInRect_fromRect_operation_fraction(NSMakeRect(0, 0, Size, Size),
  NSMakeRect(0, 0, 0, 0), NSCompositeSourceOver, 1.0);`;

const launcherMenu = `Result.Bitmap := Icon;
{$IFDEF DARWIN}
// 32 píxeles en 16 puntos: nítido en Retina.
if Result.Bitmap.Handle <> 0 then
  TCocoaBitmap(Result.Bitmap.Handle).Image.setSize(NSMakeSize(16, 16));
{$ENDIF}

// …
L := Letter(Apps[i].Name);
if Sub = nil then Sub := AddItem(Root, L, 'sub', nil);
AddItem(Sub, Apps[i].Name, 'open'#9 + Apps[i].Path, H, AppIcon(Apps[i].Path, MenuIcon));`;

const launcherSearch = `k := Pos(Q, Apps[i].Key);
if k = 0 then Continue;
Starts := (k = 1) or (Pos(' ' + Q, Apps[i].Key) > 0);

// …
procedure TForm1.Search_enter;
var
  L: TAppArray;
begin
  L := Matches;
  if (FSel >= 0) and (FSel < Length(L)) and (Trim(Query) <> '') then
    Act('open'#9 + L[FSel].Path)
  else if Length(L) > 0 then
    Act('open'#9 + L[0].Path);
end;`;

const es: Record<string, DemoMade> = {
  pascal_docker: {
    intro:
      "Se hizo entera en DMarlon Studio con el destino Pascal (Lazarus): el Diseñador pone la ventana, su menú y el reloj; el código de Form1.pas hace el icono de la barra, habla con Docker y dibuja el panel. Estos son los pasos, con el código de verdad del ejemplo.",
    tech: {
      language: "Object Pascal (Free Pascal 3.2)",
      target: "Escritorio con Lazarus (LCL): destino Pascal del estudio, compilado con lazbuild para macOS (Cocoa) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "El panel con la lista; no se abre al arrancar y al cerrarse solo se esconde." },
        { name: "Menu1", kind: "Menu", text: "Archivo (Actualizar, Parar todos, Cerrar la ventana, Salir) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada 3000 ms pide la lista a Docker." },
        { name: "Stage", kind: "Frame", text: "El hueco donde el código dibuja las tarjetas de los contenedores (un TPaintBox)." },
        { name: "StageHint", kind: "Label", text: "Solo se ve en el Diseñador: explica que el panel lo dibuja el código." },
      ],
      apis: [
        "TTrayIcon y TPopupMenu (LCL): el icono de la barra de menús y su menú",
        "TThread y TProcess: «docker ps», «docker stop», «docker start» y «docker restart» sin bloquear",
        "Cocoa (NSApp): fuera del Dock y el icono como plantilla",
        "OpenURL (LCLIntf): abrir las direcciones en el navegador",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto nuevo con destino Pascal (Lazarus). En el Diseñador: un Menu (Archivo y Ayuda), un Timer de 3000 ms que actualiza la lista y un Frame que ocupa la ventana, donde el código dibuja el panel. La ventana no se abre al arrancar: la app vive en la barra de menús.",
        shot: "design",
      },
      {
        title: "2. El estudio genera la clase de la ventana",
        text: "De ese diseño sale design.pas (pestaña «Pascal generado»): la clase TFormDesign con Menu1, Tick y Stage, y los métodos virtuales Menu1_click y Tick_timer. Form1.pas la hereda y sobrescribe solo lo que necesita; nunca se edita el código generado.",
        shot: "generated",
      },
      {
        title: "3. El icono en la barra de menús",
        text: "En la pestaña Código, form_create crea un TTrayIcon con su TPopupMenu. Ya con la aplicación en marcha, en macOS se quita del Dock (política «Accessory») y el icono se marca como plantilla para que el sistema lo pinte blanco o negro según la barra.",
        shot: "code",
        code: { file: "Form1.pas", text: dockerTray },
      },
      {
        title: "4. «docker ps» en segundo plano",
        text: "Cada tres segundos el Timer pide la lista a Docker en un hilo (TThread), con un formato de columnas separadas por tabuladores; así el menú nunca se queda congelado. Como una app abierta desde el Finder no tiene el PATH de la terminal, busca docker donde lo instalan Docker Desktop, Homebrew, OrbStack, Colima o Rancher Desktop.",
        code: { file: "Form1.pas", text: dockerJob },
      },
      {
        title: "5. Las direcciones y las acciones",
        text: "Los puertos publicados se convierten en direcciones (http, o https para el 443 y el 8443) y cada contenedor tiene su submenú: abrir sus direcciones en el navegador, parar, reiniciar o copiar la orden para entrar. Parar es otra orden de docker en su hilo, y al terminar la lista se actualiza sola.",
        code: { file: "Form1.pas", text: dockerMenu + "\n\n" + dockerPorts },
      },
      {
        title: "6. Probar y compilar",
        text: "Con F9 el estudio la compila con lazbuild y la abre. El ejemplo trae sus pruebas internas sin ventana (DMS_DOCKER_SELFTEST=1): los puertos, la lista, el menú, el icono y el panel; y con un contenedor de verdad, lo para y lo vuelve a arrancar. Las capturas de esta página las dibuja la propia app (DMS_DOCKER_SHOT).",
      },
    ],
  },
  pascal_launcher: {
    intro:
      "Se hizo en DMarlon Studio con el destino Pascal (Lazarus), reutilizando la idea de la demo de Docker: el Diseñador pone la ventana con su buscador; el código de Form1.pas busca las apps de la carpeta donde está el propio lanzador, saca sus iconos del sistema y arma el menú de la barra.",
    tech: {
      language: "Object Pascal (Free Pascal 3.2)",
      target: "Escritorio con Lazarus (LCL): destino Pascal del estudio, compilado con lazbuild para macOS (Cocoa) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "El panel: el buscador y las apps en teselas; no se abre al arrancar." },
        { name: "Menu1", kind: "Menu", text: "Archivo (Actualizar la lista, Cerrar la ventana, Salir) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada 30 000 ms vuelve a mirar su carpeta por si hay apps nuevas o borradas." },
        { name: "Search", kind: "Entry", text: "El buscador; su evento Intro (Search_enter) abre la app elegida." },
        { name: "Stage", kind: "Frame", text: "Donde el código dibuja las teselas con los iconos (un TPaintBox)." },
        { name: "StageHint", kind: "Label", text: "Solo se ve en el Diseñador." },
      ],
      apis: [
        "TTrayIcon y TPopupMenu (LCL), con un TBitmap por opción: el menú con los iconos de las apps",
        "ParamStr(0) y FindFirst / FindNext: las apps de la carpeta del lanzador y de sus subcarpetas (.app en macOS; .exe y .lnk en Windows)",
        "NSWorkspace.iconForFile y NSFileManager.displayNameAtPath (Cocoa): el icono y el nombre que enseña el Finder",
        "OpenDocument (LCLIntf): abrir la app",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino Pascal (Lazarus): un Entry arriba para buscar (con su evento Intro), un Frame debajo para las teselas, un Menu y un Timer de medio minuto. Como en la de Docker, la ventana no se abre sola: la app vive en la barra de menús.",
        shot: "design",
      },
      {
        title: "2. La clase que genera el estudio",
        text: "design.pas trae Search, Stage, Menu1 y Tick, y los métodos virtuales Search_enter, Tick_timer y Menu1_click; Form1.pas los sobrescribe.",
        shot: "generated",
      },
      {
        title: "3. Las apps de su carpeta",
        text: "El lanzador sabe dónde está por ParamStr(0): en macOS sube tres carpetas para llegar a su paquete .app. FindFirst recorre esa carpeta (y una más adentro) y se salta a sí mismo. El nombre es el que enseña el Finder, traducido, y la lista se ordena sin tener en cuenta acentos ni mayúsculas. Póngalo, por ejemplo, junto a las demos del estudio.",
        shot: "code",
        code: { file: "Form1.pas", text: launcherScan },
      },
      {
        title: "4. El icono de cada app",
        text: "NSWorkspace da el mismo icono que el Finder; se dibuja en un mapa de bits de 32 píxeles para el menú (16 puntos en Retina) o de 128 para el panel, y se guarda en una caché para no repetirlo. El icono de la barra no es un TIcon sin más: se pone su imagen con transparencia y se marca como plantilla, para que macOS lo pinte blanco o negro según la barra.",
        code: { file: "Form1.pas", text: launcherIcon },
      },
      {
        title: "5. El menú: favoritas, recientes y por letras",
        text: "Arriba van las favoritas (la estrella del panel) y las seis últimas que abrió; debajo, una opción por letra con sus apps. Las favoritas y las recientes se guardan en un archivo de texto.",
        code: { file: "Form1.pas", text: launcherMenu },
      },
      {
        title: "6. El buscador y el teclado",
        text: "Al escribir, primero salen las apps con una palabra que empieza así («co» → Consola, Conversor de moneda) y después las que solo lo contienen. Las flechas eligen e Intro abre. Sus pruebas internas (DMS_LAUNCHER_SELFTEST=1) crean apps de mentira y comprueban la búsqueda, las favoritas, el menú con iconos de 16 puntos y el panel.",
        code: { file: "Form1.pas", text: launcherSearch },
      },
    ],
  },
};

const en: Record<string, DemoMade> = {
  pascal_docker: {
    intro:
      "It was made entirely in DMarlon Studio with the Pascal (Lazarus) target: the Designer provides the window, its menu and the timer; the code in Form1.pas makes the menu bar icon, talks to Docker and draws the panel. These are the steps, with the example's real code.",
    tech: {
      language: "Object Pascal (Free Pascal 3.2)",
      target: "Desktop with Lazarus (LCL): the studio's Pascal target, built with lazbuild for macOS (Cocoa) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The panel with the list; it does not open at startup and closing it only hides it." },
        { name: "Menu1", kind: "Menu", text: "File (Refresh, Stop all, Close the window, Quit) and Help." },
        { name: "Tick", kind: "Timer", text: "Every 3000 ms it asks Docker for the list." },
        { name: "Stage", kind: "Frame", text: "The area where the code draws the container cards (a TPaintBox)." },
        { name: "StageHint", kind: "Label", text: "Only visible in the Designer: it explains that the code draws the panel." },
      ],
      apis: [
        "TTrayIcon and TPopupMenu (LCL): the menu bar icon and its menu",
        "TThread and TProcess: “docker ps”, “docker stop”, “docker start” and “docker restart” without blocking",
        "Cocoa (NSApp): out of the Dock and the icon as a template",
        "OpenURL (LCLIntf): open the addresses in the browser",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A new project with the Pascal (Lazarus) target. In the Designer: a Menu (File and Help), a 3000 ms Timer that refreshes the list and a Frame filling the window, where the code draws the panel. The window does not open at startup: the app lives in the menu bar.",
        shot: "design",
      },
      {
        title: "2. The studio generates the window class",
        text: "That design becomes design.pas (the “Generated Pascal” tab): the TFormDesign class with Menu1, Tick and Stage, and the virtual methods Menu1_click and Tick_timer. Form1.pas inherits it and overrides only what it needs; the generated code is never edited.",
        shot: "generated",
      },
      {
        title: "3. The menu bar icon",
        text: "In the Code tab, form_create makes a TTrayIcon with its TPopupMenu. Once the app is running, on macOS it leaves the Dock (the “Accessory” policy) and the icon is marked as a template so the system tints it white or black to match the bar.",
        shot: "code",
        code: { file: "Form1.pas", text: dockerTray },
      },
      {
        title: "4. “docker ps” in the background",
        text: "Every three seconds the Timer asks Docker for the list on a thread (TThread), with tab-separated columns; that way the menu never freezes. Since an app opened from the Finder doesn't get the terminal's PATH, it looks for docker where Docker Desktop, Homebrew, OrbStack, Colima or Rancher Desktop install it.",
        code: { file: "Form1.pas", text: dockerJob },
      },
      {
        title: "5. Addresses and actions",
        text: "The published ports become addresses (http, or https for 443 and 8443) and each container gets its submenu: open its addresses in the browser, stop, restart or copy the command to get in. Stopping is another docker command on its own thread, and when it ends the list refreshes itself.",
        code: { file: "Form1.pas", text: dockerMenu + "\n\n" + dockerPorts },
      },
      {
        title: "6. Test and build",
        text: "F9 builds it with lazbuild and opens it. The example comes with its own windowless tests (DMS_DOCKER_SELFTEST=1): ports, list, menu, icon and panel; and with a real container, it stops it and starts it again. The screenshots on this page are drawn by the app itself (DMS_DOCKER_SHOT).",
      },
    ],
  },
  pascal_launcher: {
    intro:
      "It was made in DMarlon Studio with the Pascal (Lazarus) target, reusing the idea of the Docker demo: the Designer provides the window with its search box; the code in Form1.pas finds the apps in the folder where the launcher itself is, takes their icons from the system and builds the menu bar menu.",
    tech: {
      language: "Object Pascal (Free Pascal 3.2)",
      target: "Desktop with Lazarus (LCL): the studio's Pascal target, built with lazbuild for macOS (Cocoa) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The panel: the search box and the app tiles; it does not open at startup." },
        { name: "Menu1", kind: "Menu", text: "File (Refresh the list, Close the window, Quit) and Help." },
        { name: "Tick", kind: "Timer", text: "Every 30,000 ms it looks at its folder again for new or deleted apps." },
        { name: "Search", kind: "Entry", text: "The search box; its Enter event (Search_enter) opens the chosen app." },
        { name: "Stage", kind: "Frame", text: "Where the code draws the tiles with the icons (a TPaintBox)." },
        { name: "StageHint", kind: "Label", text: "Only visible in the Designer." },
      ],
      apis: [
        "TTrayIcon and TPopupMenu (LCL), with a TBitmap per item: the menu with the app icons",
        "ParamStr(0) and FindFirst / FindNext: the apps in the launcher’s folder and its subfolders (.app on macOS; .exe and .lnk on Windows)",
        "NSWorkspace.iconForFile and NSFileManager.displayNameAtPath (Cocoa): the icon and the name the Finder shows",
        "OpenDocument (LCLIntf): open the app",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the Pascal (Lazarus) target: an Entry at the top to search (with its Enter event), a Frame below for the tiles, a Menu and a half-minute Timer. As in the Docker demo, the window does not open by itself: the app lives in the menu bar.",
        shot: "design",
      },
      {
        title: "2. The class the studio generates",
        text: "design.pas has Search, Stage, Menu1 and Tick, and the virtual methods Search_enter, Tick_timer and Menu1_click; Form1.pas overrides them.",
        shot: "generated",
      },
      {
        title: "3. The apps in its folder",
        text: "The launcher knows where it is from ParamStr(0): on macOS it goes up three folders to reach its .app bundle. FindFirst walks that folder (and one level deeper) and skips itself. The name is the one the Finder shows, translated, and the list is sorted ignoring accents and case. Put it, for example, next to the studio’s demos.",
        shot: "code",
        code: { file: "Form1.pas", text: launcherScan },
      },
      {
        title: "4. Each app's icon",
        text: "NSWorkspace gives the same icon as the Finder; it is drawn into a 32-pixel bitmap for the menu (16 points on Retina) or 128 for the panel, and cached so it isn't drawn twice. The menu bar icon is not just a TIcon: its image is set with transparency and marked as a template, so macOS paints it white or black to match the bar.",
        code: { file: "Form1.pas", text: launcherIcon },
      },
      {
        title: "5. The menu: favorites, recent and by letter",
        text: "At the top go your favorites (the star in the panel) and the last six you opened; below, one item per letter with its apps. Favorites and recent apps are saved in a text file.",
        code: { file: "Form1.pas", text: launcherMenu },
      },
      {
        title: "6. Search and keyboard",
        text: "As you type, apps with a word starting that way come first (“co” → Console, Currency converter) and then those that only contain it. The arrow keys choose and Enter opens. Its own tests (DMS_LAUNCHER_SELFTEST=1) create fake apps and check search, favorites, the menu with 16-point icons and the panel.",
        code: { file: "Form1.pas", text: launcherSearch },
      },
    ],
  },
};

export const MADE: Record<Lang, Record<string, DemoMade>> = { es, en };
