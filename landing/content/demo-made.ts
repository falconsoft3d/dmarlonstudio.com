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

// ---- Monitor de sitios web (C++): fragmentos de Form1.cpp
const webmonCurl = `std::string curl_config(const std::string& url) {
  std::string c = "url = " + curl_quote(url) + "\\n";
  c += "silent\\nshow-error\\nlocation\\nmax-time = 20\\nconnect-timeout = 10\\n";
  c += "output = \\"/dev/null\\"\\n";
  c += "write-out = \\"\\\\n%{http_code} %{time_total}\\"\\n";
  return c;
}

void check(int i) {
  sites[i].checking = true;
  std::string url = sites[i].url;
  std::thread([url] {
    auto* d = new ProbeDone{url, um::probe(url), um::now_t()};
    Fl::awake(done, d);   // el resultado vuelve al hilo de la ventana
  }).detach();
}`;

const webmonBar = `template <class R = id, class... A>
R msg(id o, const char* s, A... a) {
  return ((R(*)(id, SEL, A...))objc_msgSend)(o, sel_registerName(s), a...);
}

bool create() {
  id sb = msg(cls("NSStatusBar"), "systemStatusBar");
  id it = msg<id, double>(sb, "statusItemWithLength:", -1.0);
  msg(it, "retain");
  item() = it;
  return true;
}

// Las opciones del menú llaman a una clase hecha en tiempo de ejecución.
Class c = objc_allocateClassPair((Class)objc_getClass("NSObject"), "DmsWebMonitorTarget", 0);
class_addMethod(c, sel_registerName("dmsAct:"), (IMP)on_act, "v@:@");
objc_registerClassPair(c);`;

const webmonLoop = `void to_bar() {
  save();
  in_bar = true;
  hide();
  bar::dock(false);   // fuera del Dock: setActivationPolicy:1
  refresh();
  // Sin ventanas, Fl::run terminaría: aquí sigue la app (como un diálogo).
  while (in_bar && !quitting) Fl::wait(1e20);
  if (quitting) quit_now();
}`;

const webmonState = `bool add(const Check& c) {
  bool first = history.empty();
  bool was = !first && is_up(history.back().code);
  bool now = is_up(c.code);
  if (first || was != now) changed = c.t;
  history.push_back(c);
  if (history.size() > KEEP) history.erase(history.begin(), history.begin() + (history.size() - KEEP));
  return !first && was != now;   // → aviso de macOS
}`;

// ---- Relojes del mundo (C++): fragmentos de Form1.cpp
const clocksRules = `bool is_dst(long long t, Rule r, int std_min) {
  // …
  case R_EU:   // último domingo de marzo y de octubre, a la 1:00 UTC
    start = at(nth_sunday(y, 3, -1), 60);
    end = at(nth_sunday(y, 10, -1), 60);
    return t >= start && t < end;
  case R_CUBA:
    // Salvo de marzo de 2026 a noviembre de 2027: Cuba se quedó en el
    // horario de verano (tzdata 2026f).
    if (t >= at(days_from_civil(2026, 3, 8), 300) && t < at(days_from_civil(2027, 11, 7), 300)) return true;
    start = at(nth_sunday(y, 3, 2), 0 - std_min);
    end = at(nth_sunday(y, 11, 1), 60 - (std_min + 60));
    return t >= start && t < end;
  case R_CHILE:   // en el hemisferio sur, al revés
    start = at(nth_sunday(y, 9, 1), 240);
    end = at(nth_sunday(y, 4, 1), 180);
    return t >= start || t < end;
  // …
}`;

const clocksZones = `const Zone ZONES[] = {
    {"ES", "ES", "Europe/Madrid", 60, R_EU},
    {"AR", "AR", "America/Argentina/Buenos_Aires", -180, R_NONE},
    {"VE", "VE", "America/Caracas", -240, R_NONE},
    {"DO", "DO", "America/Santo_Domingo", -240, R_NONE},
    {"CU", "CU", "America/Havana", -300, R_CUBA},
    // … 34 más
};
const char* const DEFAULTS[] = {"ES", "AR", "VE", "DO", "CU"};`;

const clocksTest = `// Compara las reglas con la base de zonas del sistema (en macOS y Linux):
// cada 3 horas de 2025 a 2027, para cada país.
for (int i = 0; i < ZONE_N; i++) {
  setenv("TZ", ZONES[i].iana, 1);
  tzset();
  for (long long t = from; t < to; t += 3 * 3600) {
    int sys = local_offset_min(t), ours = offset_min(i, t);
    if (sys != ours) bad++;
  }
}`;

const clocksBar = `std::string bar_title(const Settings& s, long long t) {
  std::string o;
  int here = local_offset_min(t);
  if (s.show_here) o = "📍 " + time_text(clock_at(t, here), s.h24);
  for (const auto& k : s.clocks) {
    if (!contains(s.in_bar, k)) continue;
    int i = zone_index(k);
    if (s.show_here && offset_min(i, t) == here) continue;
    if (!o.empty()) o += "   ";
    o += flag(i) + " " + time_text(clock_at(t, offset_min(i, t)), s.h24);
  }
  return o;   // «📍 17:02   🇨🇺 12:02»
}`;

const webmonScan = `// Todos los puertos a la vez: conexiones no bloqueantes y un select.
for (int port : ports) {
  sock_t s = socket(family, SOCK_STREAM, 0);
  set_nonblock(s);
  if (connect(s, (sockaddr*)&a, len) == 0) r.open.push_back(port);
  else pending.push_back({port, s});
}
while (!pending.empty() && now_s() < end) {
  // … FD_SET de cada uno y select(…, &w, &x, &tv)
  getsockopt(p.s, SOL_SOCKET, SO_ERROR, (char*)&err, &el);
  if (err == 0 && FD_ISSET(p.s, &w)) r.open.push_back(p.port);
}`;

// ---- Grabador de pantalla (C++): fragmentos de Form1.cpp
const recArgs = `std::vector<std::string> screencapture_args(const Options& o, const Area& a, const std::string& file) {
  std::vector<std::string> v = {"/usr/sbin/screencapture", "-x", "-v"};
  if (o.cursor) v.push_back("-C");
  if (o.clicks) v.push_back("-k");
  if (o.mic) v.push_back("-g");
  if (a.w > 0) v.push_back("-R" + std::to_string(a.x) + "," + std::to_string(a.y) + "," + std::to_string(a.w) + "," + std::to_string(a.h));
  if (o.limit_s > 0) v.push_back("-V" + std::to_string(o.limit_s));
  v.push_back(file);
  return v;
}`;

const recStartStop = `posix_spawn(&pid_, argv[0], nullptr, nullptr, argv.data(), environ);

// …
void stop() {
  kill(pid_, SIGINT);   // como Ctrl+C: screencapture cierra el vídeo
  int st = 0;
  waitpid(pid_, &st, 0);
}`;

const recArea = `// Una zona de [aw]×[ah] centrada en la pantalla; si no cabe, la más
// grande con la misma forma (los vídeos de YouTube son 16:9).
Area centered(int sw, int sh, int aw, int ah) {
  Area a;
  double k = std::min(1.0, std::min(sw / (double)aw, sh / (double)ah));
  a.w = (int)(aw * k) / 2 * 2;
  a.h = (int)(ah * k) / 2 * 2;
  a.x = (sw - a.w) / 2;
  a.y = (sh - a.h) / 2;
  return a;
}`;

const recMovie = `// La duración (átomo mvhd) y el tamaño (tkhd de la pista de vídeo).
size_t i = d.find("mvhd");
const unsigned char* p = b + i + 4;
if (p[0] == 0) {
  uint32_t scale = be32(p + 12), dur = be32(p + 16);
  if (scale) v.seconds = dur / (double)scale;
}
for (size_t k = d.find("tkhd"); k != std::string::npos; k = d.find("tkhd", k + 4)) {
  // … el ancho y el alto, en 16.16, al final del átomo
}`;

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
  cpp_webmon: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con sus campos, el intervalo, los botones, la barra de estado y el reloj; el código de Form1.cpp comprueba los sitios con curl, dibuja la lista con su historial y pone el icono en la barra de menús de macOS.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "La ventana del monitor; su botón de cerrar la esconde en la barra de menús." },
        { name: "Menu1", kind: "Menu", text: "Archivo (Añadir un sitio, Comprobar todos ahora, Minimizar a la barra de menús, Salir) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada 1000 ms: la cuenta atrás y, cuando toca, otra ronda de comprobaciones." },
        { name: "Top", kind: "Frame", text: "La franja de arriba con los campos y los botones." },
        { name: "Url / SiteName", kind: "Entry", text: "La dirección y el nombre del sitio; Intro (Url_enter) lo añade." },
        { name: "BtnAdd", kind: "Button", text: "Añade el sitio y lo comprueba en el momento." },
        { name: "Every", kind: "Combobox", text: "Comprobar cada 1, 2, 5, 10, 15 o 30 min (Every_select)." },
        { name: "BtnCheck / BtnBar", kind: "Button", text: "Comprobar todos ahora y minimizar a la barra de menús." },
        { name: "Board", kind: "Frame", text: "Donde el código dibuja la lista de sitios y sus puertos (un Fl_Widget propio)." },
        { name: "Status", kind: "StatusBar", text: "Cuántos sitios están en línea y la próxima comprobación." },
      ],
      apis: [
        "curl (lo traen macOS y Windows 10+): la petición GET, el código HTTP y el tiempo, con las opciones en un archivo temporal",
        "std::thread y Fl::awake: cada comprobación en su hilo, el resultado vuelve a la ventana",
        "Runtime de Objective-C (objc_msgSend, objc_allocateClassPair): NSStatusItem, NSMenu y el símbolo «globe» del sistema",
        "fl_draw y Fl_Image_Surface (FLTK): la lista, el historial y las capturas",
        "osascript: el aviso de macOS cuando un sitio se cae o vuelve",
        "Sockets (getaddrinfo, connect no bloqueante y select): el escáner de los 33 puertos habituales",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): arriba, un Frame con dos Entry (dirección y nombre), el botón Añadir, un Combobox con el intervalo y dos botones; debajo, un Frame grande para la lista y una StatusBar; además, un Menu y un Timer de un segundo.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "De ese diseño sale la clase FormDesign (pestaña «C++ generado») con cada componente y los métodos virtuales BtnAdd_click, Url_enter, Every_select, Tick_timer y Menu1_click; Form1 la hereda en Form1.cpp y los sobrescribe.",
        shot: "generated",
      },
      {
        title: "3. Comprobar con curl, sin congelar la ventana",
        text: "Cada sitio se comprueba en su propio hilo con curl: una petición GET que sigue las redirecciones, con un tiempo máximo, y que escribe al final el código HTTP y lo que tardó. El resultado vuelve al hilo de la ventana con Fl::awake.",
        shot: "code",
        code: { file: "Form1.cpp", text: webmonCurl },
      },
      {
        title: "4. En línea, lento o caído, y el historial",
        text: "Un 2xx o 3xx es «en línea» (lento si pasa de 2 segundos); un error o ninguna respuesta, «caído». Cada sitio guarda sus últimas 500 comprobaciones; con ellas salen la disponibilidad, el «desde hace…» y las barras del historial, y el cambio de estado lanza el aviso.",
        code: { file: "Form1.cpp", text: webmonState },
      },
      {
        title: "5. La barra de menús desde C++",
        text: "FLTK no tiene icono de barra de menús, así que se hace con el runtime de Objective-C, que ya está en la app por FLTK: objc_msgSend crea el NSStatusItem y el NSMenu, y una clase creada en tiempo de ejecución recibe los clics del menú.",
        code: { file: "Form1.cpp", text: webmonBar },
      },
      {
        title: "6. Seguir viva sin ventana",
        text: "Fl::run termina cuando no queda ninguna ventana. Al minimizar a la barra, la app esconde la ventana, sale del Dock y espera eventos con Fl::wait, como hace un diálogo, hasta que vuelve a abrir la ventana o elige Salir. Sus pruebas (DMS_WEBMON_SELFTEST y DMS_WEBMON_UITEST) comprueban las direcciones, curl, los estados, el guardado, el menú y la interfaz sin abrir ventanas.",
        code: { file: "Form1.cpp", text: webmonLoop },
      },
      {
        title: "7. El escáner de puertos",
        text: "«Puertos» resuelve el servidor del sitio (getaddrinfo) y prueba sus 33 puertos habituales a la vez, con conexiones TCP no bloqueantes y un select con tiempo máximo, en otro hilo. Los abiertos salen bajo el sitio; los que no conviene abrir a internet (MySQL, Redis, RDP…), en ámbar. La prueba interna abre un puerto en este equipo y comprueba que sale abierto y uno cerrado no.",
        code: { file: "Form1.cpp", text: webmonScan },
      },
    ],
  },
  cpp_clocks: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana, la lista de países, el formato, los botones, la barra de estado y el reloj de un segundo; el código de Form1.cpp calcula la hora de cada país, dibuja las esferas y pone las horas en la barra de menús de macOS.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "Las tarjetas de los relojes; su botón de cerrar la esconde en la barra de menús." },
        { name: "Menu1", kind: "Menu", text: "Archivo (Minimizar a la barra, Volver a los relojes de siempre, Salir) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada 1000 ms: las agujas, la hora de la barra y el menú." },
        { name: "Top", kind: "Frame", text: "La franja de arriba." },
        { name: "Zone", kind: "Combobox", text: "Los 39 países para añadir (España, Argentina, Venezuela, República Dominicana, Cuba…)." },
        { name: "BtnAdd", kind: "Button", text: "Añade el país elegido." },
        { name: "Format", kind: "Combobox", text: "24 o 12 horas (Format_select)." },
        { name: "BtnBar", kind: "Button", text: "Minimizar a la barra de menús." },
        { name: "Board", kind: "Frame", text: "Donde el código dibuja las tarjetas con las esferas (un Fl_Widget propio)." },
        { name: "Status", kind: "StatusBar", text: "La hora de aquí, con segundos, y cuántos relojes hay." },
      ],
      apis: [
        "El calendario en el código (los algoritmos de días de Howard Hinnant): la hora de cada país sin depender de las zonas del sistema",
        "Las reglas del horario de verano: Unión Europea, Estados Unidos, Cuba, Chile, Australia y Nueva Zelanda",
        "setenv(\"TZ\") y tzset (solo en las pruebas): la base de zonas del sistema, para comprobar las reglas",
        "Runtime de Objective-C (objc_msgSend): NSStatusItem con las banderas y las horas, y su NSMenu",
        "fl_draw, fl_pie y fl_line (FLTK): las esferas y las agujas",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): arriba, un Combobox con los países, el botón Añadir, otro Combobox con el formato y el botón de la barra; debajo, un Frame para las tarjetas y una StatusBar; además, un Menu y un Timer de un segundo.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae cada componente y los métodos virtuales BtnAdd_click, BtnBar_click, Format_select, Tick_timer y Menu1_click, que Form1 sobrescribe en Form1.cpp.",
        shot: "generated",
      },
      {
        title: "3. Los países y sus reglas",
        text: "Cada país lleva su diferencia normal con UTC y, si la cambia en verano, su regla. Por defecto salen España, Argentina, Venezuela, República Dominicana y Cuba; la zona del sistema (Europe/Madrid…) solo la usan las pruebas.",
        shot: "code",
        code: { file: "Form1.cpp", text: clocksZones },
      },
      {
        title: "4. El horario de verano, en el código",
        text: "Las reglas calculan el domingo del cambio con un calendario propio, sin zonas del sistema, para que la app funcione igual en Windows. Al comprobarlas apareció una excepción real: Cuba se quedó en el horario de verano en noviembre de 2026.",
        code: { file: "Form1.cpp", text: clocksRules },
      },
      {
        title: "5. Comprobado contra el sistema",
        text: "La prueba interna (DMS_CLOCKS_SELFTEST) compara, para los 39 países y cada 3 horas de 2025 a 2027, la hora de la app con la de la base de zonas del sistema: 341 640 horas, todas iguales. Así se encontró la excepción de Cuba.",
        code: { file: "Form1.cpp", text: clocksTest },
      },
      {
        title: "6. Las horas en la barra de menús",
        text: "El título del icono es su hora (📍) y, al lado, la de los países marcados, con su bandera (dos letras regionales en Unicode); los que tienen su misma hora no se repiten; se rehace cada segundo y el menú solo cuando cambia. Como en el monitor de sitios, el icono se hace desde C++ con el runtime de Objective-C y la app sigue viva en la barra con Fl::wait.",
        code: { file: "Form1.cpp", text: clocksBar },
      },
    ],
  },
  cpp_recorder: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con las opciones (qué grabar, micrófono, clics, cursor, cuenta atrás y límite), el botón Grabar y la barra de estado; el código de Form1.cpp lanza el grabador del sistema, lleva el tiempo en la barra de menús y dibuja las grabaciones.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "Las opciones arriba y las grabaciones debajo; se esconde mientras graba." },
        { name: "Menu1", kind: "Menu", text: "Archivo (Grabar, Abrir la carpeta de grabaciones, Salir) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada segundo: la barra de estado y, si cambia la carpeta, la lista." },
        { name: "AreaKind", kind: "Combobox", text: "Pantalla completa, 1920×1080, 1280×720 o vertical para Shorts." },
        { name: "Mic / Clicks / Cursor", kind: "Checkbutton", text: "El sonido del micrófono, los clics y el cursor en el vídeo." },
        { name: "Countdown / Limit", kind: "Combobox", text: "La cuenta atrás (0 a 10 s) y el límite (hasta 15 min)." },
        { name: "BtnRecord", kind: "Button", text: "● Grabar (BtnRecord_click)." },
        { name: "BtnFolder", kind: "Button", text: "Abre la carpeta de grabaciones." },
        { name: "Board", kind: "Frame", text: "Donde el código dibuja las grabaciones (un Fl_Widget propio)." },
        { name: "Status", kind: "StatusBar", text: "Cuántas grabaciones hay y dónde, o lo último que pasó." },
      ],
      apis: [
        "screencapture (macOS): graba la pantalla o una zona, con el cursor, los clics y el micrófono; ffmpeg (gdigrab o x11grab) en Windows y Linux",
        "posix_spawn y kill(SIGINT): lanzar la grabación y pararla dejando el vídeo cerrado",
        "Los átomos mvhd y tkhd del .mov: la duración y la resolución, leídas del archivo",
        "qlmanage (QuickLook): las miniaturas",
        "Runtime de Objective-C: el tiempo en la barra de menús con «Detener y guardar»",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): arriba, un Combobox con qué grabar, tres Checkbutton (micrófono, clics y cursor), dos Combobox (cuenta atrás y límite), el botón rojo Grabar y Abrir la carpeta; debajo, un Frame para las grabaciones y una StatusBar.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae cada componente con su tipo de FLTK (DmsCombo, DmsCheck…) y los métodos virtuales BtnRecord_click, BtnFolder_click, Tick_timer y Menu1_click, que Form1 sobrescribe.",
        shot: "generated",
      },
      {
        title: "3. La orden de grabar",
        text: "Las opciones de la ventana se convierten en los argumentos de screencapture: -v para vídeo, -C el cursor, -k los clics, -g el micrófono, -R la zona y -V el límite. En Windows y Linux se arma la orden de ffmpeg con lo mismo.",
        shot: "code",
        code: { file: "Form1.cpp", text: recArgs },
      },
      {
        title: "4. La zona de 16:9",
        text: "Las zonas de 1080p, 720p y vertical se centran en la pantalla; si la pantalla es más pequeña, se usa la más grande con la misma forma, para que YouTube no ponga bandas negras.",
        code: { file: "Form1.cpp", text: recArea },
      },
      {
        title: "5. Grabar y parar sin perder el vídeo",
        text: "La grabación es un proceso aparte: se lanza con posix_spawn y se para con SIGINT, como un Ctrl+C, para que screencapture cierre bien el archivo. Mientras tanto, la ventana se esconde y la app espera en la barra de menús con el tiempo. La prueba de humo (DMS_RECORDER_SMOKE) graba 2 segundos y comprueba que la ventana vuelve con el vídeo en la lista.",
        code: { file: "Form1.cpp", text: recStartStop },
      },
      {
        title: "6. Duración y resolución, del propio vídeo",
        text: "Spotlight tarda en saber la duración de un vídeo nuevo, así que la app lee los átomos del .mov: mvhd da la duración y el tkhd de la pista de vídeo, el ancho y el alto. Las miniaturas las hace QuickLook en otro hilo. La prueba interna (DMS_RECORDER_SELFTEST) arma un .mov mínimo y comprueba la lectura, las zonas y las órdenes.",
        code: { file: "Form1.cpp", text: recMovie },
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
  cpp_webmon: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with its fields, the interval, the buttons, the status bar and the timer; the code in Form1.cpp checks the sites with curl, draws the list with its history and puts the icon in the macOS menu bar.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The monitor window; its close button hides it in the menu bar." },
        { name: "Menu1", kind: "Menu", text: "File (Add a site, Check all now, Minimize to the menu bar, Quit) and Help." },
        { name: "Tick", kind: "Timer", text: "Every 1000 ms: the countdown and, when due, another round of checks." },
        { name: "Top", kind: "Frame", text: "The top strip with the fields and buttons." },
        { name: "Url / SiteName", kind: "Entry", text: "The site's address and name; Enter (Url_enter) adds it." },
        { name: "BtnAdd", kind: "Button", text: "Adds the site and checks it right away." },
        { name: "Every", kind: "Combobox", text: "Check every 1, 2, 5, 10, 15 or 30 min (Every_select)." },
        { name: "BtnCheck / BtnBar", kind: "Button", text: "Check all now and minimize to the menu bar." },
        { name: "Board", kind: "Frame", text: "Where the code draws the list of sites and their ports (a custom Fl_Widget)." },
        { name: "Status", kind: "StatusBar", text: "How many sites are up and the next check." },
      ],
      apis: [
        "curl (shipped with macOS and Windows 10+): the GET request, HTTP code and time, with the options in a temporary file",
        "std::thread and Fl::awake: each check on its own thread, the result goes back to the window",
        "Objective-C runtime (objc_msgSend, objc_allocateClassPair): NSStatusItem, NSMenu and the system “globe” symbol",
        "fl_draw and Fl_Image_Surface (FLTK): the list, the history and the screenshots",
        "osascript: the macOS notification when a site goes down or comes back",
        "Sockets (getaddrinfo, non-blocking connect and select): the scanner of the 33 usual ports",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: at the top, a Frame with two Entry fields (address and name), the Add button, a Combobox with the interval and two buttons; below, a large Frame for the list and a StatusBar; plus a Menu and a one-second Timer.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "That design becomes the FormDesign class (the “Generated C++” tab) with each component and the virtual methods BtnAdd_click, Url_enter, Every_select, Tick_timer and Menu1_click; Form1 inherits it in Form1.cpp and overrides them.",
        shot: "generated",
      },
      {
        title: "3. Checking with curl, without freezing the window",
        text: "Each site is checked on its own thread with curl: a GET request that follows redirects, with a time limit, and writes the HTTP code and how long it took at the end. The result goes back to the window's thread with Fl::awake.",
        shot: "code",
        code: { file: "Form1.cpp", text: webmonCurl },
      },
      {
        title: "4. Up, slow or down, and the history",
        text: "A 2xx or 3xx is “up” (slow over 2 seconds); an error or no answer, “down”. Each site keeps its last 500 checks; from them come the uptime, the “for…” and the history bars, and a change of state triggers the notification.",
        code: { file: "Form1.cpp", text: webmonState },
      },
      {
        title: "5. The menu bar from C++",
        text: "FLTK has no menu bar icon, so it is made with the Objective-C runtime, already in the app through FLTK: objc_msgSend creates the NSStatusItem and the NSMenu, and a class created at run time receives the menu clicks.",
        code: { file: "Form1.cpp", text: webmonBar },
      },
      {
        title: "6. Staying alive without a window",
        text: "Fl::run ends when no window is left. When minimized to the bar, the app hides the window, leaves the Dock and waits for events with Fl::wait, like a dialog does, until you open the window again or choose Quit. Its tests (DMS_WEBMON_SELFTEST and DMS_WEBMON_UITEST) check addresses, curl, states, saving, the menu and the interface without opening windows.",
        code: { file: "Form1.cpp", text: webmonLoop },
      },
      {
        title: "7. The port scanner",
        text: "“Ports” resolves the site's server (getaddrinfo) and tries its 33 usual ports at once, with non-blocking TCP connections and a select with a time limit, on another thread. The open ones show under the site; those that should not be open to the internet (MySQL, Redis, RDP…), in amber. The internal test opens a port on this machine and checks it shows as open and a closed one does not.",
        code: { file: "Form1.cpp", text: webmonScan },
      },
    ],
  },
  cpp_clocks: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window, the country list, the format, the buttons, the status bar and the one-second timer; the code in Form1.cpp works out each country's time, draws the dials and puts the times in the macOS menu bar.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The clock cards; its close button hides it in the menu bar." },
        { name: "Menu1", kind: "Menu", text: "File (Minimize to the bar, Back to the default clocks, Quit) and Help." },
        { name: "Tick", kind: "Timer", text: "Every 1000 ms: the hands, the time in the bar and the menu." },
        { name: "Top", kind: "Frame", text: "The top strip." },
        { name: "Zone", kind: "Combobox", text: "The 39 countries to add (Spain, Argentina, Venezuela, Dominican Republic, Cuba…)." },
        { name: "BtnAdd", kind: "Button", text: "Adds the chosen country." },
        { name: "Format", kind: "Combobox", text: "24 or 12 hours (Format_select)." },
        { name: "BtnBar", kind: "Button", text: "Minimize to the menu bar." },
        { name: "Board", kind: "Frame", text: "Where the code draws the cards with the dials (a custom Fl_Widget)." },
        { name: "Status", kind: "StatusBar", text: "The local time, with seconds, and how many clocks there are." },
      ],
      apis: [
        "The calendar in the code (Howard Hinnant's day algorithms): each country's time without relying on the system's time zones",
        "Daylight saving rules: European Union, United States, Cuba, Chile, Australia and New Zealand",
        "setenv(\"TZ\") and tzset (tests only): the system's time zone database, to check the rules",
        "Objective-C runtime (objc_msgSend): NSStatusItem with the flags and times, and its NSMenu",
        "fl_draw, fl_pie and fl_line (FLTK): the dials and hands",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: at the top, a Combobox with the countries, the Add button, another Combobox with the format and the bar button; below, a Frame for the cards and a StatusBar; plus a Menu and a one-second Timer.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (the “Generated C++” tab) has each component and the virtual methods BtnAdd_click, BtnBar_click, Format_select, Tick_timer and Menu1_click, which Form1 overrides in Form1.cpp.",
        shot: "generated",
      },
      {
        title: "3. The countries and their rules",
        text: "Each country has its normal UTC offset and, if it changes in summer, its rule. Spain, Argentina, Venezuela, the Dominican Republic and Cuba come by default; the system zone (Europe/Madrid…) is only used by the tests.",
        shot: "code",
        code: { file: "Form1.cpp", text: clocksZones },
      },
      {
        title: "4. Daylight saving, in the code",
        text: "The rules find the Sunday of the change with their own calendar, without system time zones, so the app works the same on Windows. Checking them revealed a real exception: Cuba stayed on summer time in November 2026.",
        code: { file: "Form1.cpp", text: clocksRules },
      },
      {
        title: "5. Checked against the system",
        text: "The internal test (DMS_CLOCKS_SELFTEST) compares, for the 39 countries and every 3 hours from 2025 to 2027, the app's time with the system's time zone database: 341,640 hours, all equal. That is how the Cuba exception was found.",
        code: { file: "Form1.cpp", text: clocksTest },
      },
      {
        title: "6. The times in the menu bar",
        text: "The icon's title is your time (📍) and, next to it, the marked countries' times with their flag (two Unicode regional letters); those with your same time are not repeated; it is rebuilt every second and the menu only when it changes. As in the website monitor, the icon is made from C++ with the Objective-C runtime and the app stays alive in the bar with Fl::wait.",
        code: { file: "Form1.cpp", text: clocksBar },
      },
    ],
  },
  cpp_recorder: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with the options (what to record, microphone, clicks, cursor, countdown and limit), the Record button and the status bar; the code in Form1.cpp launches the system recorder, keeps the time in the menu bar and draws the recordings.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The options at the top and the recordings below; it hides while recording." },
        { name: "Menu1", kind: "Menu", text: "File (Record, Open the recordings folder, Quit) and Help." },
        { name: "Tick", kind: "Timer", text: "Every second: the status bar and, if the folder changes, the list." },
        { name: "AreaKind", kind: "Combobox", text: "Full screen, 1920×1080, 1280×720 or vertical for Shorts." },
        { name: "Mic / Clicks / Cursor", kind: "Checkbutton", text: "Microphone sound, clicks and cursor in the video." },
        { name: "Countdown / Limit", kind: "Combobox", text: "The countdown (0 to 10 s) and the limit (up to 15 min)." },
        { name: "BtnRecord", kind: "Button", text: "● Record (BtnRecord_click)." },
        { name: "BtnFolder", kind: "Button", text: "Opens the recordings folder." },
        { name: "Board", kind: "Frame", text: "Where the code draws the recordings (a custom Fl_Widget)." },
        { name: "Status", kind: "StatusBar", text: "How many recordings there are and where, or the last thing that happened." },
      ],
      apis: [
        "screencapture (macOS): records the screen or an area, with cursor, clicks and microphone; ffmpeg (gdigrab or x11grab) on Windows and Linux",
        "posix_spawn and kill(SIGINT): start the recording and stop it leaving the video closed",
        "The .mov's mvhd and tkhd atoms: duration and resolution, read from the file",
        "qlmanage (QuickLook): the thumbnails",
        "Objective-C runtime: the time in the menu bar with “Stop and save”",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: at the top, a Combobox with what to record, three Checkbuttons (microphone, clicks and cursor), two Comboboxes (countdown and limit), the red Record button and Open the folder; below, a Frame for the recordings and a StatusBar.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (the “Generated C++” tab) has each component with its FLTK type (DmsCombo, DmsCheck…) and the virtual methods BtnRecord_click, BtnFolder_click, Tick_timer and Menu1_click, which Form1 overrides.",
        shot: "generated",
      },
      {
        title: "3. The record command",
        text: "The window's options become screencapture's arguments: -v for video, -C the cursor, -k clicks, -g the microphone, -R the area and -V the limit. On Windows and Linux the same goes into an ffmpeg command.",
        shot: "code",
        code: { file: "Form1.cpp", text: recArgs },
      },
      {
        title: "4. The 16:9 area",
        text: "The 1080p, 720p and vertical areas are centered on the screen; if the screen is smaller, the largest one with the same shape is used, so YouTube adds no black bars.",
        code: { file: "Form1.cpp", text: recArea },
      },
      {
        title: "5. Recording and stopping without losing the video",
        text: "Recording is a separate process: it starts with posix_spawn and stops with SIGINT, like Ctrl+C, so screencapture closes the file properly. Meanwhile, the window hides and the app waits in the menu bar with the time. The smoke test (DMS_RECORDER_SMOKE) records 2 seconds and checks the window comes back with the video in the list.",
        code: { file: "Form1.cpp", text: recStartStop },
      },
      {
        title: "6. Duration and resolution, from the video itself",
        text: "Spotlight takes a while to know a new video's duration, so the app reads the .mov's atoms: mvhd gives the duration and the video track's tkhd, the width and height. QuickLook makes the thumbnails on another thread. The internal test (DMS_RECORDER_SELFTEST) builds a minimal .mov and checks reading, areas and commands.",
        code: { file: "Form1.cpp", text: recMovie },
      },
    ],
  },
};

export const MADE: Record<Lang, Record<string, DemoMade>> = { es, en };
