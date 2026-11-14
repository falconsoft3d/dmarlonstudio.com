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

// ---- OpenD++ (Pascal): fragmentos de Form1.pas
const opendRaster = `{ Acumula el área con signo de un tramo (como font-rs): al sumar cada fila
  sale la cobertura exacta de cada píxel, con la regla de no-cero. }
procedure AccLine(var C: TCov; X0, Y0, X1, Y1: Double);
// …
  while y < yEnd do
  begin
    ls := y * C.Stride;
    dy := Min(y + 1, Y1) - Max(y, Y0);
    xnext := x + dxdy * dy;
    d := dy * dir;
    // … el tramo reparte su área entre los píxeles que cruza
  end;

{ Pinta la cobertura con la pintura Src: color, degradado, imagen o texto. }
procedure Composite(const C: TCov; const Src: TPaintSrc; Alpha: Double; DX: Integer = 0; DY: Integer = 0);
// …
      case Src.Kind of
        pkLinear: col := Mix(Src.C1, Src.C2, t);
        pkImage: col := SampleImg(Src.Img, q.X, q.Y, Src.Clamp);
        pkMask: cov := cov * SampleMask(Src.Mask, q.X, q.Y);
      end;
      BlendPx(Surf.P[py * Surf.W + px], col, cov * Alpha);`;

const opendDraw = `procedure DrawNodeAt(N: TNode; const PM: TMat; Op: Double; Ov: TStringList);
begin
  if not N.Visible then Exit;
  a := Op * N.Opacity;
  if N.Kind = kGroup then
  begin
    for i := 0 to N.Count - 1 do DrawNodeAt(N.Kid(i), PM, a, Ov);
    Exit;
  end;
  M := MatMul(PM, LocalMat(N));       // posición y giro de la capa
  if N.Kind = kInstance then
  begin
    DrawInstance(N, M, a);            // dibuja los hijos del componente
    Exit;
  end;
  P := XfPoly(Outline(N, MatScale(M)), M);
  if N.ShOn then ShadowPolys(PP, WithA(N.ShColor, a), N.ShX * sc, N.ShY * sc, N.ShBlur * sc);
  if N.Kind = kText then DrawTextNode(N, M, a, Ov)
  else if N.Fill.Vis then FillPolys(PP, PaintOf(N.Fill, M, N.W, N.H), a);
  if N.Clip then Surf.Clip := ClipRectOf(PP);   // un marco recorta lo de dentro
  for i := 0 to N.Count - 1 do DrawNodeAt(N.Kid(i), M, a, Ov);
  StrokeNode(N, N, P, M, a);
end;`;

const opendLayout = `{ Coloca los hijos de un marco con diseño automático. }
procedure Relayout(F: TNode);
begin
  pos := F.Pad;
  for i := 0 to F.Count - 1 do
  begin
    k := F.Kid(i);
    if F.Layout = 1 then
    begin
      MoveNode(k, pos - k.X, 0);
      pos := pos + k.W + F.Gap;
      cross := Max(cross, k.H);
    end
    else
    begin
      MoveNode(k, 0, pos - k.Y);
      pos := pos + k.H + F.Gap;
      cross := Max(cross, k.W);
    end;
  end;
  if F.Hug then
    if F.Layout = 1 then F.W := pos - F.Gap + F.Pad else F.H := pos - F.Gap + F.Pad;
end;`;

const opendJson = `{ Lee un diseño en JSON (el de la plantilla, aunque venga con texto alrededor). }
function ImportJson(const Txt: string; out Msg: string): Boolean;
// …
  a := Pos('{', s);                     // quita lo que la IA escribe alrededor
  while (b > a) and not (s[b] in ['}', ']']) do Dec(b);
  data := GetJSON(Copy(s, a, b - a + 1));
  // … cada página, sus marcos y sus capas
  JNode(TJSONObject(arr[j]), pg.Root, 0, 0);
  ResolvePending;   // enlaces del prototipo e instancias, por nombre
  NormalizeAll;     // textos, grupos y diseño automático`;

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

// ---- MyWhatsapp (C++): fragmentos de Form1.cpp
const mywaDb = `const char* sql =
    "SELECT Z_PK, ZPARTNERNAME, ZCONTACTJID, ZLASTMESSAGEDATE, ZLASTMESSAGETEXT, ZUNREADCOUNT "
    "FROM ZWACHATSESSION WHERE IFNULL(ZREMOVED,0)=0 AND IFNULL(ZHIDDEN,0)=0 "
    "AND ZCONTACTJID NOT LIKE '%status%' AND ZLASTMESSAGEDATE IS NOT NULL "
    "ORDER BY ZLASTMESSAGEDATE DESC LIMIT 300";

// Solo lectura: «?mode=ro», con el SQLite del sistema (dlopen).
std::string uri = "file:" + path + "?mode=ro";
q.open_v2(uri.c_str(), &db, OPEN_READONLY | OPEN_URI, nullptr);`;

const mywaClaude = `std::string claude_body(const std::string& system, const std::string& user) {
  return "{\\"model\\":" + jstr(CLAUDE_MODEL) +
         ",\\"max_tokens\\":4000,\\"output_config\\":{\\"effort\\":\\"low\\"},\\"fallbacks\\":\\"default\\",\\"system\\":" + jstr(system) +
         ",\\"messages\\":[{\\"role\\":\\"user\\",\\"content\\":" + jstr(user) + "}]}";
}

auto r = post_json(anthropic_url(),
                   {"Content-Type: application/json", "x-api-key: " + s.claude_key, "anthropic-version: 2026-10-21",
                    "anthropic-beta: server-side-fallback-2026-07-01"},
                   claude_body(sys, usr));`;

const mywaParse = `AiReply parse_claude(int http, const std::string& body) {
  AiReply r;
  Json j = parse_json(body, &ok);
  // …
  if (j["stop_reason"].str() == "refusal") {
    r.error = tx::ERR_AI_REFUSAL;
    return r;
  }
  std::string text;
  for (const auto& b : j["content"].a)
    if (b["type"].str() == "text") text += b["text"].str();
  r.options = split_options(text);   // tres respuestas separadas por «---»
  return r;
}`;

const mywaSend = `// La foto: «Media/Profile/…» + «.thumb» (96×96) o «.jpg».
std::string pic = col(st, 6);
if (!pic.empty()) {
  std::string b = base_dir(path) + "/" + pic;
  if (file_exists(b + ".thumb")) c.pic = b + ".thumb";
  else if (file_exists(b + ".jpg")) c.pic = b + ".jpg";
}

// …
// Los adjuntos descargados están en «Message/Media/…».
if (!local.empty() && file_exists(base_dir(path) + "/Message/" + local)) m.media = base_dir(path) + "/Message/" + local;`;

const mywaEnter = `// Enter en el borrador envía; Mayúsculas+Enter, otra línea.
static int dispatch(int e, Fl_Window* w) {
  Form1* f = self();
  if (f && e == FL_KEYBOARD && Fl::focus() == f->Draft &&
      (Fl::event_key() == FL_Enter || Fl::event_key() == FL_KP_Enter) &&
      !(Fl::event_state() & (FL_SHIFT | FL_CTRL | FL_ALT | FL_META))) {
    f->send_draft("");
    return 1;
  }
  return Fl::handle_(e, w);
}

// API oficial de WhatsApp Business (Cloud API de Meta)
std::string cloud_text_body(const std::string& to, const std::string& text) {
  return "{\\"messaging_product\\":\\"whatsapp\\",\\"recipient_type\\":\\"individual\\",\\"to\\":" + jstr(to) +
         ",\\"type\\":\\"text\\",\\"text\\":{\\"preview_url\\":true,\\"body\\":" + jstr(text) + "}}";
}`;

const mywaBridge = `// wabridge (Go + whatsmeow): habla con la app por stdin/stdout,
// una línea JSON por mensaje.
case "send", "send_file":
  to, err := types.ParseJID(c.To)
  // …
  if c.Cmd == "send" {
    msg = &waE2E.Message{Conversation: proto.String(c.Text)}
  } else {
    data, _ := os.ReadFile(c.Path)
    kind, mime := mediaKind(c.Path, data[:min(512, len(data))])
    up, err := b.cli.Upload(ctx, data, uploadType[kind])
    // …
    msg = fileMessage(kind, mime, filepath.Base(c.Path), c.Caption, up)
  }
  resp, err := b.cli.SendMessage(ctx, to, msg)`;

const mywaWho = `// Quién escribe en un grupo: el nombre de la agenda, el del grupo, el de su
// perfil («~ Ana», como WhatsApp) o su teléfono.
std::string sender_name(const std::string& book, const std::string& first, const std::string& push,
                        const std::string& member_jid, const std::string& raw_push) {
  if (!trim(book).empty()) return trim(book);
  if (!trim(first).empty()) return trim(first);
  if (!trim(push).empty()) return "~ " + trim(push);
  std::string ph = phone_of(member_jid);
  if (!ph.empty()) return "+" + ph;
  if (!raw_push.empty() && !looks_encoded(raw_push)) return raw_push;
  return "";
}`;

const mywaTasks = `// Clic derecho sobre un bocadillo: ese mensaje es la tarea.
case FL_PUSH: {
  bool right = Fl::event_button() == FL_RIGHT_MOUSE;
  for (const auto& h : hits)
    if (Fl::event_inside(h.x, h.y, h.w, h.h) && on_act && (h.act == 6) == right) {
      on_act(h.act, h.idx);
      break;
    }
  return 1;
}

// Cada tarea, una línea JSON en tareas.jsonl, con el chat del que salió.
std::string task_line(const Task& t) {
  return "{\\"id\\":" + std::to_string(t.id) + ",\\"title\\":" + jstr(t.title) + ",\\"jid\\":" + jstr(t.jid) +
         ",\\"chat\\":" + jstr(t.chat) + ",\\"t\\":" + std::to_string(t.created) + ",\\"done\\":" + (t.done ? "true" : "false") + "}";
}`;

const mywaSelect = `// La letra bajo el ratón: cada línea dibujada guarda dónde empieza cada letra.
bool pos_at(int mx, int my, bool strict, Pos& out) const {
  const LineBox* best = nullptr;
  int dist = 1 << 30;
  for (const auto& b : boxes) {
    bool in_y = my >= b.y && my < b.y + 19;
    if (strict && !(in_y && mx >= b.x - 4 && mx <= b.xs.back() + 6)) continue;
    int d = in_y ? 0 : std::min(std::abs(my - b.y), std::abs(my - (b.y + 19)));
    if (d < dist) { dist = d; best = &b; }
  }
  if (!best) return false;
  out = {best->msg, best->line, best->at.back()};
  for (size_t k = 0; k + 1 < best->xs.size(); k++)
    if (mx < (best->xs[k] + best->xs[k + 1]) / 2) { out.ch = best->at[k]; break; }
  return true;
}`;

const mywaAssist = `// El asistente: la conversación entera y, con Claude, la búsqueda en la web.
std::string claude_turns_body(const std::string& system, const std::vector<Turn>& turns, bool web) {
  std::string m;
  for (const auto& t : turns) m += (m.empty() ? "" : ",") + std::string("{\\"role\\":") + (t.user ? "\\"user\\"" : "\\"assistant\\"") + ",\\"content\\":" + jstr(t.text) + "}";
  return "{\\"model\\":" + jstr(CLAUDE_MODEL) + ",\\"max_tokens\\":4000,\\"output_config\\":{\\"effort\\":\\"medium\\"},\\"fallbacks\\":\\"default\\",\\"system\\":" +
         jstr(system) + ",\\"messages\\":[" + m + "]" +
         (web ? ",\\"tools\\":[{\\"type\\":\\"web_search_20260209\\",\\"name\\":\\"web_search\\",\\"max_uses\\":3}]" : "") + "}";
}
// Las respuestas listas van entre «<<<RESPUESTA» y «>>>»: cada una, una tarjeta con
// «Usar como respuesta», que la deja en el borrador del chat del cliente.
auto sp = split_replies(text);   // {el texto, las respuestas}`;
const mywaColors = `// Encima del tema claro u oscuro: el color de la app, el fondo y los bocadillos ("" = del color de la app).
void apply_colors(const std::string& accent, const std::string& chat, const std::string& bubbles) {
  Theme& t = th();
  const Palette& a = palettes()[(size_t)palette_index(accent)];
  const Palette& b = palettes()[(size_t)palette_index(bubbles.empty() ? accent : bubbles)];
  const ChatBg& c = chat_backgrounds()[(size_t)chat_bg_index(chat)];
  t.accent = t.dark ? a.accent_d : a.accent;
  t.button = t.dark ? a.button_d : a.button;
  t.soft = t.dark ? a.soft_d : a.soft;
  t.out = t.dark ? b.out_d : b.out;
  t.out_line = t.dark ? b.out_d : b.out_line;
  t.chat = t.dark ? c.dark : c.light;
}`;

const mywaConsole = `// MyWhatsapp --console: la misma app, sin abrir la ventana. Los diálogos se cambian por preguntas en la terminal…
confirm = [this](const std::string& q) { return con_yes(q); };
ask_text = [this](const char* q, std::string& io) { return con_ask(q, io); };
choose = [this](const std::vector<std::string>& items) { return con_choose(items); };
form = [this](const std::string& t, std::vector<wa::FormField>& fs, const char* ok) { return con_form(t, fs, ok); };
created();   // como al abrir la ventana: los ajustes, los chats, el puente…
con::start_reader();   // un hilo lee las líneas; la app sigue atendiendo al puente y a la IA
while (!con_quit) {
  std::string l;
  if (!con_read(con_prompt(), l)) break;   // mientras espera: Fl::wait(0.25) y con_watch()
  con_exec(l);
}

// El código QR del puente, con medios bloques: dos filas de módulos por línea.
out += t && b ? "█" : t ? "▀" : b ? "▄" : " ";`;

const mywaAccounts = `// Lo que llega de un puente: el del número que se ve, como siempre; el de otro, se cuenta en su pestaña.
void on_bridge_from(const std::string& id, const std::string& line) {
  int k = account_index(id);
  if (k < 0) return;   // un número quitado (su puente se está cerrando)
  if (k == account) {
    on_bridge(line);
    update_tabs();
    return;
  }
  bool ok = false;
  wa::Json j = wa::parse_json(line, &ok);
  if (!ok) return;
  std::string ev = j["ev"].str();
  Account& a = accounts[(size_t)k];
  if (ev == "msg" && !j["mine"].b && j["chat"].str() != "status@broadcast") a.unread++;
  else if (ev == "ready") a.linked = true;
  else if (ev == "logged_out" || ev == "exit") a.linked = false;
  update_tabs();
}`;

const psKey = `// La clave compuesta: SHA-256 de la contraseña y, si hay, de la clave del archivo de clave.
Bytes composite_key(const std::string& password, const Bytes& keyfile_key) {
  Bytes parts = sha256(bytes(password));
  if (!keyfile_key.empty()) parts.insert(parts.end(), keyfile_key.begin(), keyfile_key.end());
  Bytes k = sha256(parts);
  wipe(parts);
  return k;
}
Bytes transform_key(const Kdf& kdf, const Bytes& composite) {
  if (kdf.type == K_AESKDF) {
    Aes256 a(kdf.salt.data());
    Bytes k = composite;
    for (uint64_t r = 0; r < kdf.iterations; r++) {
      a.encrypt(k.data(), k.data());
      a.encrypt(k.data() + 16, k.data() + 16);
    }
    Bytes out = sha256(k);
    wipe(k);
    return out;
  }
  return argon2(kdf.type == K_ARGON2ID ? ARGON2_ID : ARGON2_D, composite, kdf.salt, (uint32_t)kdf.iterations,
                (uint32_t)std::min<uint64_t>(kdf.memory / 1024, 0xffffffffu), kdf.parallelism, 32, Bytes(), Bytes(), kdf.version);
}`;

const psArgon = `// G(X, Y): out = P(X ^ Y) ^ X ^ Y (y, si «xor_out», también ^ out).
void fill_block(const Block& x, const Block& y, Block& out, bool xor_out) {
  Block r, tmp;
  for (int i = 0; i < 128; i++) r.v[i] = x.v[i] ^ y.v[i];
  tmp = r;
  if (xor_out)
    for (int i = 0; i < 128; i++) tmp.v[i] ^= out.v[i];
  uint64_t* v = r.v;
  for (int i = 0; i < 8; i++) {
    int b = 16 * i;
    perm(v, b, b + 1, b + 2, b + 3, b + 4, b + 5, b + 6, b + 7, b + 8, b + 9, b + 10, b + 11, b + 12, b + 13, b + 14, b + 15);
  }
  for (int i = 0; i < 8; i++) {
    int b = 2 * i;
    perm(v, b, b + 1, b + 16, b + 17, b + 32, b + 33, b + 48, b + 49, b + 64, b + 65, b + 80, b + 81, b + 96, b + 97, b + 112, b + 113);
  }
  for (int i = 0; i < 128; i++) out.v[i] = tmp.v[i] ^ r.v[i];
}`;

const psBlocks = `// Bloques de 1 MiB con su HMAC; al final, uno vacío.
size_t p = 0;
for (uint64_t index = 0;; index++) {
  size_t sz = std::min<size_t>(1 << 20, enc.size() - p);
  Bytes msg;
  add64(msg, index);
  add32(msg, (uint32_t)sz);
  msg.insert(msg.end(), enc.begin() + (long)p, enc.begin() + (long)(p + sz));
  Bytes mac = hmac_sha256(block_key(index), msg);
  out.insert(out.end(), mac.begin(), mac.end());
  add32(out, (uint32_t)sz);
  out.insert(out.end(), enc.begin() + (long)p, enc.begin() + (long)(p + sz));
  p += sz;
  if (sz == 0) break;
}`;

const psProtect = `// Los valores protegidos (las contraseñas) van cifrados dentro del XML con un flujo aparte.
struct InnerStream {
  std::unique_ptr<ChaCha20> chacha;
  std::unique_ptr<Salsa20> salsa;
  InnerStream(uint32_t id, const Bytes& key) {
    if (id == 3) {
      Bytes h = sha512(key);
      chacha.reset(new ChaCha20(h.data(), h.data() + 32));
      wipe(h);
    } else if (id == 2) {
      Bytes h = sha256(key);
      static const uint8_t nonce[8] = {0xE8, 0x30, 0x09, 0x4B, 0x97, 0x20, 0x5D, 0x2A};
      salsa.reset(new Salsa20(h.data(), nonce));
      wipe(h);
    }
  }
  bool ok() const { return chacha || salsa; }
  void apply(Bytes& b) {
    if (chacha) chacha->apply(b.data(), b.size());
    else if (salsa) salsa->apply(b.data(), b.size());
  }
};
void unprotect(Node* n, InnerStream& st) {
  if (n->attr("Protected") == "True") {
    Bytes b = unb64(n->text);
    st.apply(b);
    n->text.assign(b.begin(), b.end());
    wipe(b);
  }
  for (auto& k : n->kids) unprotect(k.get(), st);
}`;

const psTest = `// Las bases de datos de KeePassXC y de pykeepass.
Database db;
std::string err;
bool ok3 = open_kdbx(unb64(FIXTURE_3), composite_key("prueba123", Bytes()), db, err);
Node* root = ok3 ? root_group(db) : nullptr;
Node* banco = root && !entries(root).empty() ? entries(root)[0] : nullptr;
chk(ok3 && db.major == 3 && db.kdf.type == K_AESKDF && banco && field(banco, "Title") == "Banco" && field(banco, "Password") == "Clave-Del-Banco-99" &&
        db.binaries.size() == 1 && db.binaries[0] == bytes("hola adjunto\\n") && field(entries(groups(root)[0])[0], "Password") == "ñandú€",
    "abrir una base de datos de KeePassXC (KDBX 3.1, AES-KDF, Salsa20)");`;

const psLock = `// Bloquear: se borra de la memoria todo lo descifrado y la clave.
void lock_now(bool keep_file) {
  if (unlocked && db.xml) db.xml->wipe_all();
  db = kp::Database();
  kp::wipe(master_key);
  unlocked = false;
  dirty = false;
  cur_group = nullptr;
  view->list.clear();
  view->rows.clear();
  view->selected = -1;
  view->show_password = false;
  view->auditing = false;
  search.clear();
  Search->value("");
  if (clip_until > 0) {
    copy("");
    clip_until = 0;
  }
  view->mode = keep_file && !path.empty() ? kp::M_LOCKED : kp::M_WELCOME;
  refresh();
}`;

const mlCourse = `# Cada frase, con su palabra más rara: se entiende al llegar a ella.
by_rank = defaultdict(list)
for t, ws in vocab.items():
    by_rank[max(rank[w] for w in ws)].append(t)

def score(t):
    n = len(t.split())
    return (0 if 3 <= n <= 9 else 1, abs(n - 6), len(tr[t]) * -1, t)

known, order, items = set(), [], []
for r in range(len(rank)):
    cands = sorted(by_rank.get(r, []), key=score)
    if not cands:
        continue
    for t in cands[:2]:
        new = sorted(vocab[t] - known, key=lambda w: rank[w])
        for w in new:
            known.add(w)
            order.append(w)
        items.append((t, tr[t], new))
    if len(known) >= TARGET_WORDS:
        break`;

const mlInstall = `// Instalar un idioma del catálogo: su paquete queda en la carpeta «paquetes».
bool install(const std::string& target) {
  std::string src = ml::ui_lang();
  if (!ml::in_catalog(target, src)) return false;
  ml::Pack p = ml::build_pack(target, src);
  for (const auto& q : packs)
    if (q.id == p.id) return true;
  if (!demo) {
    fl_make_path(ml::packs_dir().c_str());
    if (!ml::write_file(ml::packs_dir() + "/" + p.id + ".json", ml::pack_json(p))) return false;
  }
  packs.push_back(p);
  return true;
}`;

const mlLesson = `// Una lección: diez juegos con las frases nuevas de esa parte de la unidad y alguna de repaso.
std::vector<Exercise> make_lesson(const Pack& p, int u, int k, bool tts, unsigned seed) {
  std::mt19937 rng(seed);
  int n = (int)p.units[(size_t)u].items.size();
  int a = k * n / LESSONS, b = (k + 1) * n / LESSONS;
  std::vector<std::pair<int, int>> focus;
  for (int i = a; i < b; i++) focus.push_back({u, i});
  std::vector<std::pair<int, int>> review;
  for (int i = 0; i < a; i++) review.push_back({u, i});
  if (review.empty() && u > 0)
    for (int i = 0; i < (int)p.units[(size_t)u - 1].items.size(); i++) review.push_back({u - 1, i});
  std::shuffle(review.begin(), review.end(), rng);
  for (size_t i = 0; i < review.size() && i < 2; i++) focus.push_back(review[i]);
  static const Kind pattern[LESSONS][10] = {
      {K_CHOOSE, K_CHOOSE, K_BUILD, K_MATCH, K_CHOOSE_REV, K_BUILD, K_CHOOSE, K_BUILD, K_LISTEN, K_BUILD},
      {K_BUILD, K_CHOOSE, K_MATCH, K_BUILD, K_CHOOSE_REV, K_LISTEN, K_TYPE, K_BUILD, K_TYPE, K_BUILD},
      {K_BUILD, K_TYPE, K_MATCH, K_LISTEN, K_TYPE, K_BUILD, K_CHOOSE_REV, K_TYPE, K_LISTEN, K_TYPE}};
  std::vector<Exercise> out;
  size_t next = 0;
  for (Kind kind : pattern[std::max(0, std::min(LESSONS - 1, k))]) {
    auto f = focus[next++ % focus.size()];
    if (kind == K_MATCH) f = {u, a};
    out.push_back(make_exercise(kind, p, f.first, f.second, tts, rng));
  }
  return out;
}`;

const mlCheck = `Check check_text(const std::string& typed, const std::vector<std::string>& ok) {
  Check r;
  if (ok.empty()) return r;
  r.best = ok[0];
  std::string t = norm(typed, false), tf = norm(typed, true);
  if (t.empty()) return r;
  for (const auto& a : ok)
    if (norm(a, false) == t) return {V_OK, a};
  for (const auto& a : ok)
    if (norm(a, true) == tf) return {V_ACCENT, a};
  int best = 1 << 30;
  std::vector<uint32_t> T = cps(tf);
  for (const auto& a : ok) {
    int d = levenshtein(cps(norm(a, true)), T);
    if (d < best) {
      best = d;
      r.best = a;
    }
  }
  size_t len = cps(norm(r.best, true)).size();
  int allow = len >= 16 ? 2 : len >= 5 ? 1 : 0;
  r.v = best <= allow ? V_TYPO : V_WRONG;
  return r;
}`;

const mlRemember = `// Recordar una frase: bien, sube y se repasa más tarde; mal, baja y se repasa ya.
void remember(Progress& p, int u, int i, bool ok, long long today) {
  auto& m = p.mem[mem_key(u, i)];
  int s = ok ? std::min(6, m.first + 1) : std::max(0, m.first - 2);
  m = {s, today + (ok ? INTERVALS[s] : 0)};
}
void add_xp(Stats& s, int xp, long long today) {
  if (s.xp_day != today) {
    s.xp_today = 0;
    s.xp_day = today;
  }
  s.xp_today += xp;
  if (s.last_day == today - 1) s.streak++;
  else if (s.last_day != today) s.streak = 1;
  s.last_day = today;
  if (std::find(s.days.begin(), s.days.end(), today) == s.days.end()) s.days.push_back(today);
  while (s.days.size() > 60) s.days.erase(s.days.begin());
}`;

const mlSpeak = `void speak(const std::string& text, const std::string& lang, bool slow) {
#ifdef __APPLE__
  static std::atomic<int> last{0};
  int prev = last.exchange(0);
  if (prev > 0) kill((pid_t)prev, SIGTERM);   // la anterior se calla
  std::vector<std::string> args = {"/usr/bin/say"};
  std::string v = voice_for(lang);
  if (!v.empty()) {
    args.push_back("-v");
    args.push_back(v);
  }
  if (slow) {
    args.push_back("-r");
    args.push_back("115");
  }
  args.push_back(text);
  std::vector<char*> argv;
  for (auto& a : args) argv.push_back(&a[0]);
  argv.push_back(nullptr);
  pid_t pid = 0;
  if (posix_spawn(&pid, "/usr/bin/say", nullptr, nullptr, argv.data(), environ) == 0) {
    last = (int)pid;
    std::thread([pid] {
      int st = 0;
      waitpid(pid, &st, 0);
      int expected = (int)pid;
      last.compare_exchange_strong(expected, 0);   // ya terminó: no se le manda nada más
    }).detach();
  }
#else
  (void)text;
  (void)lang;
  (void)slow;
#endif
}`;

const mywaTranslate = `// Lo recibido: una tanda de mensajes a la IA, que devuelve JSON con el idioma
// y una traducción por mensaje; se guardan y no se vuelven a pedir.
std::thread([s, jid, sys, usr, keys, n] {
  wa::AiText r = wa::ai_ask(s, sys, usr);
  auto* d = new TransDone{jid, "", r.error, keys, {}};
  if (d->error.empty() && !wa::parse_translation(r.text, n, d->language, d->items)) d->error = tx::ERR_AI_ANSWER;
  Fl::awake(trans_done, d);
}).detach();

// La bandera y la hora del país, por el prefijo del teléfono.
for (const Country* k : chat_countries(*chat)) {
  std::string tm = time_in(k->tz, t_now);
  sub += "   ·   " + flag_of(k->iso) + (tm.empty() ? "" : " " + fmt(tx::LOCAL_TIME, {tm}));
}`;

// ---- Uso de Claude Code (C++): fragmentos de Form1.cpp
const ccLite = `bool parse_log_line(const char* b, const char* e, LogMsg& m) {
  Lite j(b, e);
  double cc = 0, c5 = -1, c1 = -1;
  bool ok = j.object([&](const std::string& k) {
    if (k == "type") return j.str(&m.type);
    if (k == "timestamp") return j.str(&m.ts);
    if (k == "sessionId") return j.str(&m.session);
    if (k == "requestId") return j.str(&m.request);
    if (k == "cwd") return j.str(&m.cwd);
    if (k != "message") return false;
    return j.object([&](const std::string& mk) {
      if (mk == "id") return j.str(&m.id);
      if (mk == "model") return j.str(&m.model);
      if (mk != "usage") return false;
      m.usage = true;
      return j.object([&](const std::string& uk) {
        if (uk == "input_tokens") return j.number(&m.t.in);
        if (uk == "output_tokens") return j.number(&m.t.out);
        if (uk == "cache_read_input_tokens") return j.number(&m.t.cr);
        if (uk == "cache_creation_input_tokens") return j.number(&cc);
        if (uk == "speed") return j.str(&m.speed);
        if (uk != "cache_creation") return false;
        return j.object([&](const std::string& ck) {
          if (ck == "ephemeral_5m_input_tokens") return j.number(&c5);
          if (ck == "ephemeral_1h_input_tokens") return j.number(&c1);
          return false;
        });
      });
    });
  });
  if (!ok) return false;
  if (c5 < 0 && c1 < 0) m.t.w5 = cc;
  else {
    m.t.w1 = std::max(0.0, c1);
    m.t.w5 = c5 >= 0 ? c5 : std::max(0.0, cc - m.t.w1);
  }
  return true;
}`;

const ccScan = `void count_line(const char* b, const char* e, const std::string& folder, LocalCache& c, ScanStats& st) {
  std::string_view sv(b, (size_t)(e - b));
  if (sv.find("\"usage\"") == std::string_view::npos || sv.find("\"assistant\"") == std::string_view::npos) return;
  LogMsg m;
  if (!parse_log_line(b, e, m) || m.type != "assistant" || !m.usage) return;
  if (!starts(m.model, "claude")) return;   // «<synthetic>»: avisos de Claude Code, sin coste
  long long t = parse_iso(m.ts);
  if (t < 0) return;
  if (!m.id.empty() && !c.seen.insert(hash64("m:" + m.id + ":" + m.request)).second) return;
  int day = local_day(t);
  Agg a;
  a.t = m.t;
  a.cost = cost_of(m.model, m.t, m.speed == "fast");
  a.msgs = 1;
  if (!m.session.empty() && c.seen.insert(hash64("s:" + m.session + ":" + std::to_string(day))).second) a.sessions = 1;
  c.rows[{day, m.model, project_name(m.cwd, folder)}].add(a);
  c.msgs++;
  st.msgs++;
}`;

const ccPrice = `Price price_of(const std::string& model, double prompt_tokens = 0) {
  std::string m = lower(model);
  auto is = [&](const char* k) { return m.find(k) != std::string::npos; };
  if (is("fable-5-2") || is("mythos-5-2")) return {8, 10, 16, 0.20, 40};
  if (is("fable-5-1") || is("mythos-5-1")) return {10, 12.5, 20, 0.25, 50};
  if (is("fable") || is("mythos")) return {10, 12.5, 20, 1, 50};
  if (is("opus-5-5")) return {4, 5, 8, 0.20, 20};
  if (is("opus-4-1") || is("opus-4-0") || is("opus-4-2025") || m == "claude-opus-4" || is("3-opus"))
    return {15, 18.75, 30, 1.5, 75};
  if (is("opus")) return {5, 6.25, 10, 0.5, 25};   // Opus 5, 4.8, 4.7, 4.6 y 4.5
  if (is("sonnet-5-5")) return {2, 2.5, 4, 0.10, 10};
  if (is("sonnet-5")) return {2, 2.5, 4, 0.20, 10};
  if (is("sonnet")) return {3, 3.75, 6, 0.30, 15};
  if (is("haiku-5-5")) {
    if (prompt_tokens > 100000) return {0.5, 0.625, 1, 0.05, 2.5};
    return {0.10, 0.125, 0.20, 0.01, 0.50};
  }
  if (is("haiku-4-5")) return {1, 1.25, 2, 0.10, 5};
  if (is("haiku-3-5") || is("3-5-haiku")) return {0.8, 1, 1.6, 0.08, 4};
  if (is("haiku")) return {0.25, 0.3, 0.5, 0.03, 1.25};
  return {3, 3.75, 6, 0.30, 15};
}`;

const ccApi = `bool fetch_day(const std::string& key, int day, Rows& rows, std::string& err, int& code) {
  std::vector<std::string> hdr = {"x-api-key: " + trim(key), std::string("anthropic-version: ") + API_VERSION,
                                  "Accept: application/json"};
  std::string page;
  for (int k = 0; k < 50; k++) {
    std::string url = api_base() + "/v1/organizations/usage_report/claude_code?starting_at=" + iso_day(day) + "&limit=1000";
    if (!page.empty()) url += "&page=" + url_encode(page);
    Http h = http_get(url, hdr);
    code = h.code;
    if (h.code != 200) {
      err = api_error(h);
      return false;
    }
    bool more = false;
    std::string next;
    if (!parse_report(h.body, rows, next, more)) {
      err = tx::ERR_BAD_ANSWER;
      return false;
    }
    if (!more || next.empty()) return true;
    page = next;
  }
  return true;
}`;

const ccHeat = `    int start = today - weekday(today) - (cols - 1) * 7;
    std::vector<double> vals;
    double sum = 0;
    int active = 0;
    for (int d = start; d <= today; d++) {
      Agg a = day_agg(d);
      double v = ::cu::metric(a, metric);
      vals.push_back(v);
      sum += v;
      if (a.active()) active++;
    }
    auto q = quartiles(vals);
    // …
    for (int c = 0; c < cols; c++)
      for (int r = 0; r < 7; r++) {
        int d = start + c * 7 + r;
        if (d > today) break;
        int cx = gx + c * step, cy = gy + r * step;
        fl_color(rgb(HEAT[level(::cu::metric(day_agg(d), metric), q)]));
        fl_rounded_rectf(cx, cy, cell, cell, 3);
        if (d == selected) {
          fl_color(rgb(0x1f2937));
          fl_line_style(FL_SOLID, 2);
          fl_rounded_rect(cx - 1, cy - 1, cell + 2, cell + 2, 3);
          fl_line_style(0);
        }
        hits.push_back({cx - 1, cy - 1, step, step, d});
      }`;

const ccBar = `std::string bar_title(const Rows& rows, int today, int m) {
  double v = metric(total(rows, today, today), m);
  if (m == M_TOKENS) return " " + tokens(v);
  if (m == M_SESSIONS) return " " + num(v, 0);
  return " " + money(v);
}

  void to_bar() {
    if (!bar::available()) { iconize(); return; }
    if (in_bar) return;
    save_settings();
    in_bar = true;
    hide();
    bar::dock(false);
    refresh();
    // Sin ventanas, Fl::run terminaría: aquí sigue la app (como un diálogo).
    while (in_bar && !quitting) Fl::wait(1e20);
    if (quitting) quit_now();
  }`;

// ---- Plan de viaje (Pascal): fragmentos de Form1.pas
const trClaude = `    P.Executable := Exe;
    P.Parameters.Add('-p');
    P.Parameters.Add('--output-format');
    P.Parameters.Add('json');
    P.Parameters.Add('--no-session-persistence');
    P.Parameters.Add('--tools=');   // sin herramientas: solo escribe el plan
    P.Parameters.Add('--json-schema');
    P.Parameters.Add(SCHEMA);
    P.Options := [poUsePipes];
    P.ShowWindow := swoHide;`;

const trParse = `function ParseClaude(const Output: string; out P: TPlan; out Err: string): Boolean;
var
  D, S: TJSONData;
  O: TJSONObject;
begin
  P := Default(TPlan);
  Err := '';
  Result := False;
  try
    D := GetJSON(Output);
  except
    Err := tx_ERR_ANSWER;
    Exit;
  end;
  try
    if not (D is TJSONObject) then begin Err := tx_ERR_ANSWER; Exit; end;
    O := TJSONObject(D);
    if O.Get('is_error', False) then
    begin
      Err := Fmt(tx_ERR_CLAUDE, [Str(O, 'result')]);
      Exit;
    end;
    S := O.Find('structured_output');
    if S is TJSONObject then Result := ParsePlan(TJSONObject(S), P)
    else Result := ParsePlanText(Str(O, 'result'), P);
    if not Result then Err := tx_ERR_ANSWER;
  finally
    D.Free;
  end;
end;`;

const trFit = `procedure RenderPoster(Cv: TCanvas; const P: TPlan);
var
  Level: Integer;
  Sc: Double;
begin
  for Level := 0 to 2 do
  begin
    Sc := 1;
    while (Sc > 0.79) and (DrawPoster(Cv, P, Level, Sc, False) > PH - 170) do Sc := Sc - 0.04;
    if DrawPoster(Cv, P, Level, Sc, False) <= PH - 170 then
    begin
      DrawPoster(Cv, P, Level, Sc, True);
      Exit;
    end;
  end;
  Sc := 0.8;
  while (Sc > 0.5) and (DrawPoster(Cv, P, 2, Sc, False) > PH - 170) do Sc := Sc - 0.04;
  DrawPoster(Cv, P, 2, Sc, True);
end;`;

const trPdf = `    Doc.Options := [poUseRawJPEG];   // el origen, abajo a la izquierda: la imagen ocupa la página entera
    Doc.DefaultPaperType := ptA4;
    Doc.DefaultUnitOfMeasure := uomMillimeters;
    Doc.Infos.Title := P.Title;
    Doc.Infos.Producer := 'DMarlon Studio';
    Doc.StartDocument;
    Sec := Doc.Sections.AddSection;
    for i := 0 to PageCount(P) - 1 do
    begin
      B := NewBitmap(AW, AH);
      J := TJPEGImage.Create;
      try
        RenderPage(B.Canvas, P, i);
        J.CompressionQuality := 88;
        J.Assign(B);
        Tmp := GetTempDir + 'dms-viaje-' + IntToStr(GetProcessID) + '-' + IntToStr(i) + '.jpg';
        J.SaveToFile(Tmp);
      finally
        J.Free;
        B.Free;
      end;
      ix := Doc.Images.AddFromFile(Tmp, False);
      DeleteFile(Tmp);
      Pg := Doc.Pages.AddPage;
      Sec.AddPage(Pg);
      Pg.DrawImage(0, 0, 210.0, 297.0, ix);
    end;`;

// ---- Mesa de radio (C++): fragmentos de Form1.cpp
const rdIcy = `Icy parse_icy(const std::string& data) {
  Icy r;
  size_t pos = 0;
  std::string block;
  // Las cabeceras (puede haber varias si hubo redirecciones): la última manda.
  while (pos < data.size() && (data.compare(pos, 5, "HTTP/") == 0 || data.compare(pos, 4, "ICY ") == 0)) {
    size_t e = data.find("\r\n\r\n", pos);
    if (e == std::string::npos) return r;
    block = data.substr(pos, e - pos);
    pos = e + 4;
  }
  if (block.empty()) return r;
  r.name = header_value(block, "icy-name");
  r.metaint = std::atoi(header_value(block, "icy-metaint").c_str());
  if (r.metaint <= 0 || pos + (size_t)r.metaint >= data.size()) return r;
  size_t m = pos + (size_t)r.metaint;
  size_t len = (unsigned char)data[m] * 16u;
  std::string meta = data.substr(m + 1, std::min(len, data.size() - m - 1));
  size_t a = meta.find("StreamTitle='");
  if (a != std::string::npos) {
    a += 13;
    size_t b = meta.find("';", a);
    r.title = trim(meta.substr(a, b == std::string::npos ? std::string::npos : b - a));
    r.ok = true;
  }
  return r;
}`;

const rdPlayer = `  void open(const std::string& url) {
    close();
    url_ = url;
#ifdef __APPLE__
    if (av_ready()) {
      id u = msg(cls("NSURL"), "URLWithString:", nsstr(url));
      if (u) p_ = msg(msg(cls("AVPlayer"), "alloc"), "initWithURL:", u);
      if (p_) {
        msg<void, float>(p_, "setVolume:", (float)vol_);
        msg<void>(p_, "play");
      }
      return;
    }
#endif
    restart();
  }`;

const rdFade = `  void step(double dt) {
    double rate = m.fade > 0 ? dt / m.fade : 1.0;
    for (int i = 0; i < rd::CH_N; i++) {
      double t = rd::target_gain(m, i);
      double& g = m.gain[i];
      g = g < t ? std::min(t, g + rate) : std::max(t, g - rate);
      if (live) {
        players[i]->volume(g);
        players[i]->tick();
      }
    }
    for (auto it = dying.begin(); it != dying.end();) {
      it->second -= rate;
      if (it->second <= 0) {
        it->first->close();
        it = dying.erase(it);
      } else {
        it->first->volume(it->second);
        ++it;
      }
    }
  }`;

const rdSearch = `std::string search_url(const std::string& tag, const std::string& name, const std::string& country) {
  std::string u = api_base() + "/json/stations/search?order=votes&reverse=true&limit=60&hidebroken=true";
  if (!tag.empty()) u += "&tag=" + url_encode(tag);
  if (!name.empty()) u += "&name=" + url_encode(name);
  if (!country.empty()) u += "&countrycode=" + url_encode(country);
  return u;
}`;

// ---- Bloques Neón (C++): fragmentos de Form1.cpp
const nbBag = `  void bag_fill() {
    while (queue.size() < 7) {
      int bag[PIECES] = {0, 1, 2, 3, 4, 5, 6};
      for (int i = PIECES - 1; i > 0; i--) std::swap(bag[i], bag[rnd() % (uint32_t)(i + 1)]);
      for (int k : bag) queue.push_back(k);
    }
  }`;

const nbRotate = `  bool rotate(int dir) {
    if (over || paused || cur.kind == 1) return false;
    static const Cell KICKS[] = {{0, 0}, {-1, 0}, {1, 0}, {0, -1}, {-2, 0}, {2, 0}, {-1, -1}, {1, -1}};
    Piece p = cur;
    p.rot = (p.rot + dir + 4) % 4;
    for (const Cell& k : KICKS) {
      Piece q = p;
      q.x += k.x;
      q.y += k.y;
      if (fits(q)) {
        cur = q;
        touch();
        return true;
      }
    }
    return false;
  }`;

const nbLock = `    c.lines = (int)c.rows.size();
    if (c.lines > 0) {
      static const int BASE[5] = {0, 100, 300, 500, 800};
      combo++;
      int pts = BASE[c.lines] * level;
      if (c.lines == 4 && last_quad) {
        pts = pts * 3 / 2;   // dos de cuatro seguidas: la mitad más
        c.b2b = true;
      }
      last_quad = c.lines == 4;
      pts += 50 * combo * level;
      c.points = pts;
      c.combo = combo;
      score += pts;
      int before = level;
      lines += c.lines;
      level = std::max(start_level, 1 + lines / 10);
      c.level_up = level > before;
    } else {
      combo = -1;
    }`;

const nbKeys = `  void frame(double dt) {
    arena->now += dt;
    arena->advance(dt);
    if (arena->mode == 1 && !game.paused && !game.over) {
      if (held) {
        das_t += dt;
        while (das_t > 0.17) {   // tras 0,17 s, una columna cada 0,05 s
          if (!game.shift(held)) break;
          das_t -= 0.05;
        }
      }
      if (soft) {
        soft_t += dt;
        while (soft_t > 0.04) {
          soft_t -= 0.04;
          game.soft_drop();
        }
      }
      cleared(game.step(dt));
      if (game.over) finished();
    }
    arena->redraw();
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
        text: "Arriba van las favoritas (la estrella del panel) y las seis últimas que abrió; todas las demás, en el submenú «Todas las aplicaciones», que macOS desplaza solo cuando la lista es larga (con más de 40, una opción por letra). Las favoritas y las recientes se guardan en un archivo de texto.",
        code: { file: "Form1.pas", text: launcherMenu },
      },
      {
        title: "6. El buscador y el teclado",
        text: "Al escribir, primero salen las apps con una palabra que empieza así («co» → Consola, Conversor de moneda) y después las que solo lo contienen. Las flechas eligen e Intro abre. Sus pruebas internas (DMS_LAUNCHER_SELFTEST=1) crean apps de mentira y comprueban la búsqueda, las favoritas, el menú con iconos de 16 puntos y el panel.",
        code: { file: "Form1.pas", text: launcherSearch },
      },
    ],
  },
  pascal_opend: {
    intro:
      "Se hizo en DMarlon Studio con el destino Pascal (Lazarus): el Diseñador pone la ventana con su menú, el reloj y los diálogos de abrir, guardar, colocar imágenes y exportar; todo lo demás (el lienzo, la columna de herramientas, el inspector, las capas y la presentación) lo dibuja el código de Form1.pas con un rasterizador propio, igual en macOS que en Windows.",
    tech: {
      language: "Object Pascal (Free Pascal 3.2)",
      target: "Escritorio con Lazarus (LCL): destino Pascal del estudio, compilado con lazbuild para macOS (Cocoa) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "La ventana del editor (1360 × 840, se puede agrandar)." },
        { name: "Menu1", kind: "Menu", text: "Archivo, Editar, Objeto, Ver, IA y Ayuda; los atajos (⌘Z, ⌘G, ⌥⌘K…) se ponen desde el código." },
        { name: "Tick", kind: "Timer", text: "Cada 33 ms: el cursor del texto y las animaciones del prototipo (sin nada que mover, no dibuja)." },
        { name: "DlgOpen / DlgSave", kind: "OpenDialog / SaveDialog", text: "Abrir y guardar diseños .opend." },
        { name: "DlgImage", kind: "OpenDialog", text: "Colocar una imagen (PNG, JPG o BMP) o ponerla de relleno." },
        { name: "DlgExport", kind: "SaveDialog", text: "Exportar la selección a PNG (1x a 4x) o SVG." },
        { name: "DlgJson / DlgJsonSave", kind: "OpenDialog / SaveDialog", text: "Importar el diseño JSON de la IA y guardar la plantilla." },
        { name: "Stage", kind: "Frame", text: "Donde el código pone un TPaintBox con todo el editor." },
        { name: "StageHint", kind: "Label", text: "Solo se ve en el Diseñador." },
      ],
      apis: [
        "Un rasterizador propio en Pascal: cobertura exacta por píxel (suavizado), transparencias, degradados, imágenes, sombras con desenfoque y trazos dentro, centrados o fuera",
        "TBitmap y TLazIntfImage (LCL): el texto se dibuja una vez como máscara y se guarda; el resultado se copia a la ventana a la escala de la pantalla Retina",
        "fpjson y jsonparser (FCL): la plantilla JSON para la IA, importar sus diseños y exportar la selección",
        "TFPWriterPNG y base64 (FCL): exportar a PNG con transparencia y a SVG con las imágenes dentro",
        "Clipbrd (LCL): copiar y pegar capas, código CSS o Flutter y JSON",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino Pascal (Lazarus): un Menu con sus seis menús, un Timer, seis diálogos y un Frame que ocupa la ventana. Los textos del menú y de la app se traducen con el resto del ejemplo: en inglés sale la misma app en inglés.",
        shot: "design",
      },
      {
        title: "2. La clase que genera el estudio",
        text: "design.pas trae Menu1, Tick, los diálogos y Stage, y los métodos virtuales Menu1_click y Tick_timer; Form1.pas los sobrescribe y crea dentro de Stage un TPaintBox donde se dibuja todo.",
        shot: "generated",
      },
      {
        title: "3. Un rasterizador propio",
        text: "La LCL no tiene transparencias ni suavizado en todas partes, así que OpenD++ pinta en su propia memoria: cada forma se convierte en polígonos, se calcula cuánto cubre cada píxel (el mismo método que usan las fuentes) y se mezcla con su color, degradado, imagen o la máscara de un texto. Así sale igual en macOS y Windows, y la misma función exporta a PNG.",
        shot: "code",
        code: { file: "Form1.pas", text: opendRaster },
      },
      {
        title: "4. Las capas: marcos, grupos y componentes",
        text: "El documento es un árbol de capas con sus coordenadas respecto a su marco. Cada capa se dibuja con su matriz (posición y giro), su sombra, su relleno y su trazo; los marcos recortan lo de dentro y una instancia dibuja los hijos de su componente, con los textos que se cambiaron en ella.",
        code: { file: "Form1.pas", text: opendDraw },
      },
      {
        title: "5. Diseño automático y guías inteligentes",
        text: "Un marco con diseño automático coloca a sus hijos en fila o en columna, con su hueco y su margen, y puede abrazar el contenido. Al mover, las guías inteligentes alinean bordes y centros con las capas vecinas y enseñan la distancia al marco; deshacer guarda el documento antes de cada cambio.",
        code: { file: "Form1.pas", text: opendLayout },
      },
      {
        title: "6. Diseños hechos por una IA",
        text: "El menú IA copia una plantilla JSON con las instrucciones, el formato y un ejemplo (páginas, marcos, componentes, instancias, diseño automático y enlaces del prototipo). Se pega en ChatGPT, Claude u otra IA con lo que se quiere, y su respuesta se pega en OpenD++ (o con ⌘V en el lienzo). Las pruebas internas (DMS_OPEND_SELFTEST=1) importan la plantilla y comprueban el rasterizador, guardar y abrir, deshacer, agrupar, las instancias, el CSS y la presentación; las capturas de esta página las dibuja la propia app (DMS_OPEND_SHOT).",
        code: { file: "Form1.pas", text: opendJson },
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
  cpp_mywa: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con la lista de chats, la zona de la conversación y el panel de la IA (proveedor, estilo, lo que quiere decir, el borrador y los botones); el código de Form1.cpp lee WhatsApp, llama a la IA y dibuja los chats y las respuestas.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "La lista a la izquierda, la conversación a la derecha y el panel de la IA debajo." },
        { name: "Menu1", kind: "Menu", text: "Archivo (Actualizar los chats, Importar un chat exportado, Claves de la IA, Conectar y Desconectar WhatsApp, Salir), Ver (tema) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada segundo: lo que llegó por el puente y, cada pocos, los mensajes nuevos de WhatsApp Desktop." },
        { name: "Side / Search", kind: "Frame / Entry", text: "La columna de los chats y su buscador." },
        { name: "ChatArea", kind: "Frame", text: "Donde el código dibuja los bocadillos y las tres respuestas propuestas." },
        { name: "AiBar", kind: "Frame", text: "El panel de la IA." },
        { name: "Provider / Tone", kind: "Combobox", text: "Claude o ChatGPT, y el estilo de la respuesta." },
        { name: "Intent", kind: "Entry", text: "Lo que quiere decir (opcional); Intro pide las respuestas." },
        { name: "BtnSuggest", kind: "Button", text: "✨ Sugerir respuestas." },
        { name: "Draft", kind: "Text", text: "El borrador; Enter lo envía (Mayúsculas+Enter, otra línea)." },
        { name: "BtnSend", kind: "Button", text: "Enviar ➤: manda el borrador al chat abierto." },
        { name: "BtnAttach", kind: "Button", text: "📎 Adjuntar: manda un archivo, con el borrador de pie." },
        { name: "Tareas", kind: "Código", text: "La fila de la lista y la vista de tareas las dibuja el código, en Side y en ChatArea." },
        { name: "Status", kind: "StatusBar", text: "Cuántos chats, de dónde, qué IA y cómo se envía." },
      ],
      apis: [
        "Claude por la API de Mensajes (HTTP con curl): claude-opus-5-5, esfuerzo bajo para respuestas rápidas y fallbacks del servidor si el modelo declina",
        "ChatGPT por la API de OpenAI (HTTP con curl), con el modelo que elija",
        "SQLite del sistema con dlopen: la base de datos de WhatsApp Desktop, solo lectura",
        "security (Llavero de macOS): las claves de la IA",
        "Fl_JPEG_Image y Fl_PNG_Image (FLTK): las fotos de perfil, las recibidas y el código QR",
        "API oficial de WhatsApp Business (Cloud API de Meta, Graph API con curl): enviar textos y adjuntos",
        "wabridge, un programa en Go con whatsmeow (el protocolo de WhatsApp Web): vincular con QR, enviar y recibir; la app lo arranca y le habla por stdin/stdout",
        "ContactsV2.sqlite de WhatsApp Desktop (solo lectura): los nombres de quien escribe en los grupos",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): a la izquierda un Frame con un Entry para buscar, a la derecha un Frame para la conversación y, debajo, otro con dos Combobox (IA y estilo), un Entry, el botón verde de sugerir, un Text para el borrador y los botones «Enviar ➤» y «📎 Adjuntar».",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae cada componente y los métodos virtuales BtnSuggest_click, Intent_enter, BtnSend_click, BtnAttach_click, Provider_select, Tick_timer y Menu1_click, que Form1 sobrescribe.",
        shot: "generated",
      },
      {
        title: "3. Leer WhatsApp sin tocarlo",
        text: "WhatsApp Desktop guarda los chats en una base de datos SQLite. La app la abre en solo lectura con el SQLite que trae macOS (cargado con dlopen, sin bibliotecas nuevas) y lee los chats y los últimos mensajes. Sin WhatsApp Desktop, lee un chat exportado del iPhone o de Android.",
        shot: "code",
        code: { file: "Form1.cpp", text: mywaDb },
      },
      {
        title: "4. Pedir respuestas a Claude",
        text: "C++ no tiene SDK oficial de Claude, así que la app llama a la API de Mensajes por HTTP con curl: Claude Opus 5.5 con esfuerzo bajo (son respuestas de chat cortas) y las respuestas de respaldo del servidor si el modelo declina. La clave va en un archivo temporal que solo puede leer el usuario, no en la línea de órdenes. ChatGPT va igual, con su API.",
        code: { file: "Form1.cpp", text: mywaClaude },
      },
      {
        title: "5. Leer la respuesta",
        text: "La respuesta se lee con un lector de JSON propio: solo los bloques de texto, y si el modelo declinó («refusal») se dice así. Las instrucciones piden tres respuestas separadas por «---», en el idioma del chat y sin inventar datos.",
        code: { file: "Form1.cpp", text: mywaParse },
      },
      {
        title: "6. Fotos, adjuntos y tema",
        text: "La foto de cada contacto sale de Media/Profile (la miniatura de 96×96) y se recorta en un círculo; las fotos recibidas se ven en el bocadillo y los documentos se abren con un clic. El tema claro u oscuro cambia los colores de los dibujos y de los controles del diseño. Sus pruebas (DMS_MYWA_SELFTEST) leen una base de datos inventada con la forma de la de WhatsApp, chats exportados de iPhone y Android y respuestas de Claude y de OpenAI; un servidor de prueba comprobó las cabeceras y el cuerpo de las dos API.",
        code: { file: "Form1.cpp", text: mywaSend },
      },
      {
        title: "7. Quién escribe en los grupos",
        text: "WhatsApp Desktop ya no guarda el nombre de quien escribe en claro (sale un código). La app lo busca en este orden: la agenda (ContactsV2.sqlite, adjuntada a la consulta en solo lectura), el nombre del miembro del grupo, el de su perfil («~ Ana») y, si no hay ninguno, su teléfono. Su prueba arma una agenda inventada y comprueba cada caso.",
        code: { file: "Form1.cpp", text: mywaWho },
      },
      {
        title: "8. Enviar: botón, Enter y la API oficial",
        text: "«Enviar ➤», Enter en el borrador o «Enviar» en una respuesta propuesta mandan el mensaje. Enter se atrapa con Fl::event_dispatch antes de que llegue al campo, y Mayúsculas+Enter sigue haciendo otra línea. Con la API oficial de WhatsApp Business se manda un JSON a la Graph API de Meta; los adjuntos se suben antes como formulario. Un servidor de prueba comprobó el token, el JSON y la subida del archivo.",
        code: { file: "Form1.cpp", text: mywaEnter },
      },
      {
        title: "9. El puente con WhatsApp (QR)",
        text: "Para usar su WhatsApp de siempre sin otra app, la demo lleva al lado wabridge, un programa en Go con la biblioteca whatsmeow (el protocolo de WhatsApp Web). La app lo arranca, le habla por stdin/stdout con una línea JSON por orden y enseña el código QR para vincularlo. Por él llegan los mensajes y los adjuntos, que se guardan en mensajes.jsonl y se juntan con los de WhatsApp Desktop sin repetirse. No es oficial, así que la app avisa del riesgo de bloqueo antes de activarlo.",
        code: { file: "main.go", text: mywaBridge },
      },
      {
        title: "10. Tareas desde un chat",
        text: "La fila «Tareas» la dibuja la misma lista de chats, arriba, con las pendientes; al pulsarla, la zona del chat cambia a la vista de tareas (pendientes primero, la más nueva arriba, y las hechas tachadas). «+ Tarea» en la cabecera toma el último mensaje que le escribieron y el clic derecho sobre un bocadillo, ese mensaje; cada tarea guarda el chat del que salió para volver a él. Se guardan en tareas.jsonl; las pruebas de la interfaz hacen los clics, también el derecho.",
        code: { file: "Form1.cpp", text: mywaTasks },
      },
      {
        title: "11. Seleccionar, buscar y subir",
        text: "La conversación la dibuja el código, así que seleccionar texto también: al dibujar cada línea se guarda dónde empieza cada letra, y el ratón se convierte en (mensaje, línea, letra). Arrastrar selecciona, el doble clic toma el mensaje entero y Cmd+C lo copia con sus saltos de línea. La rueda sube por el historial (al llegar arriba se cargan 200 mensajes más) y «🔍 Buscar» busca en todo el chat, resalta cada acierto y salta de uno a otro. Las tareas pendientes llevan una bolita verde, naranja o roja según su edad, también en el chat de la lista.",
        code: { file: "Form1.cpp", text: mywaSelect },
      },
      {
        title: "12. Otro idioma, banderas y stickers",
        text: "«🌐 Traducir» guarda, por contacto, el idioma (detectado o elegido). Lo recibido se traduce por tandas: la IA (con la misma función ai_ask que las sugerencias) devuelve un JSON con el idioma y una traducción por mensaje, que se guarda en traducciones.jsonl. Lo que escribe se traduce antes de enviarlo y su original queda debajo, en su bocadillo. La cabecera enseña la bandera y la hora local del país (por el prefijo del teléfono y la base de zonas horarias del sistema; en los grupos, la de quienes escriben). Los stickers son WebP: sips de macOS los pasa a PNG en otro hilo.",
        code: { file: "Form1.cpp", text: mywaTranslate },
      },
      {
        title: "13. El asistente: investigar un mensaje",
        text: "«🤖 Asistente», en la barra de apps, es un chat con la IA sobre sus chats. Cada pregunta lleva un resumen de los 60 chats más recientes (nombre, fecha, el principio del último mensaje, si espera respuesta, etiquetas, tareas y etapa del CRM) y, si nombra a alguien con @, su conversación, su ficha, su lead y sus tareas. El clic derecho sobre un mensaje de un cliente, «🤖 Investigar con la IA», abre el asistente con ese chat y ese mensaje. Con Claude, la petición lleva la herramienta de búsqueda en la web, por si hace falta algo de fuera; las respuestas listas se marcan entre «<<<RESPUESTA» y «>>>». Allí, Enter nunca envía nada por WhatsApp; las pruebas lo comprueban.",
        code: { file: "Form1.cpp", text: mywaAssist },
      },
      {
        title: "14. Los colores de la app",
        text: "Ver › Colores… (o ⚙️ Ajustes) abre una sola ficha con el tema, el color de la app, el fondo del chat y el de sus mensajes. Cada color es una paleta con su versión clara y oscura: el tema pone la base y apply_colors cambia encima el acento, los botones, lo resaltado, los bocadillos y el fondo. Los colores con significado (la edad de las tareas, las etapas del CRM, las etiquetas) no cambian. La prueba de la interfaz rellena la ficha, comprueba los colores en oscuro, que se guardan y que «Volver a los colores de siempre» los deja como estaban.",
        code: { file: "Form1.cpp", text: mywaColors },
      },
      {
        title: "15. Varios números en pestañas",
        text: "Cada número tiene su carpeta (la principal, la de siempre; los demás, cuentas/<id>) con su sesión de WhatsApp, sus mensajes, sus tareas, su CRM, sus fichas y sus etiquetas. Cada uno lleva su propio puente, todos a la vez: la clase Bridge ya no es única, cada puente guarda un número de generación distinto y sus líneas llegan a la ventana con el número del que vienen. Las del número que se ve siguen el camino de siempre; las de otro solo suman en su pestaña. Al cambiar de pestaña se cargan los datos de ese número; WhatsApp Desktop y el panel de cifras son del principal. Un candado del sistema impide dos puentes con la misma cuenta.",
        code: { file: "Form1.cpp", text: mywaAccounts },
      },
      {
        title: "16. El modo consola",
        text: "Archivo › Abrir el modo consola abre la Terminal con MyWhatsapp --console: la misma app, con todo, pero sin ventana. Se arranca igual que la ventana (los ajustes, los chats, los puentes de cada número) y lo que en la ventana es un diálogo se cambia por una pregunta en la terminal: confirmar, una ficha campo a campo, un menú numerado. Un hilo lee las órdenes (abrir, leer, enviar, sugerir, asistente, tareas, crm, panel, estados, cuentas…, en español o en inglés) y, mientras espera, la app sigue atendiendo al puente y a la IA: lo que llega (un mensaje nuevo, las respuestas propuestas, la del asistente) sale encima de la línea de la orden. El código QR para vincular se dibuja en la terminal con medios bloques, en negro sobre blanco. La prueba le pasa una lista de órdenes con los chats de ejemplo.",
        code: { file: "Form1.cpp", text: mywaConsole },
      },
    ],
  },
  cpp_minilang: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con su menú, el temporizador, el campo para escribir, el botón Comprobar y la barra de estado; el código de Form1.cpp dibuja las unidades, los juegos y los resultados, lleva el progreso y los paquetes de idiomas, y deja la app en la barra de menús.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "El inicio, las lecciones, los resultados y los idiomas; al cerrarla, la app sigue en la barra de menús." },
        { name: "Menu1", kind: "Menu", text: "Archivo (lección siguiente, repaso, prueba de nivel, idiomas, importar), Ver (la meta diaria y la voz) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada segundo: las vidas que vuelven y la barra de menús al día." },
        { name: "Board", kind: "Frame", text: "Donde el código dibuja todo: las unidades, los juegos y los resultados (un Fl_Widget propio)." },
        { name: "Answer", kind: "Entry", text: "Para escribir la traducción o lo que se oye; Enter comprueba (Answer_enter)." },
        { name: "BtnCheck", kind: "Button", text: "Comprobar y Continuar (BtnCheck_click): verde si está bien, rojo si no." },
        { name: "Status", kind: "StatusBar", text: "El idioma, la unidad por la que va, la racha y la meta del día." },
      ],
      apis: [
        "Los paquetes de idiomas: un .json por idioma en la carpeta «paquetes», leído con un lector de JSON propio",
        "La distancia de Levenshtein: aceptar una errata o los acentos, avisando",
        "Repaso espaciado: cada frase vuelve a los 1, 2, 4, 7, 15 o 30 días según lo bien que se sabe",
        "say (macOS), lanzado con posix_spawn: la voz para escuchar y para oír lo que se acierta",
        "Runtime de Objective-C: la racha y la meta en la barra de menús, con la lección siguiente y el repaso",
        "Tatoeba (tatoeba.org, CC BY 2.0 FR): las frases del curso de 10.000 palabras, ordenadas por un script de Python",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): un Frame que ocupa la ventana (Board), dentro un Entry para escribir (Answer) y el botón Comprobar (BtnCheck), el Menu, el Timer y una StatusBar. El resto (las unidades, los juegos y los resultados) lo dibuja el código.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae cada componente y los métodos virtuales BtnCheck_click, Answer_enter, Tick_timer y Menu1_click, que Form1 sobrescribe. El campo y el botón se ponen encima del dibujo y el código los coloca según el juego.",
        shot: "generated",
      },
      {
        title: "3. Los idiomas son paquetes",
        text: "Cada idioma es un archivo .json con sus unidades (de A1 a C1) y sus frases, con las formas que valen separadas por «/» («I'm fine/I am fine»). Instalar uno escribe su archivo en la carpeta «paquetes»; al abrir, la app lee los que haya, y «Importar un paquete…» acepta los hechos por otros con el mismo formato. El curso de inglés trae 15 unidades y 180 frases; el de español, para quien habla inglés, las mismas al revés.",
        shot: "code",
        code: { file: "Form1.cpp", text: mlInstall },
      },
      {
        title: "4. Diez juegos por lección",
        text: "Cada unidad tiene tres lecciones. Una lección toma las frases nuevas de su parte de la unidad y dos de repaso, y arma diez juegos con un orden que va de reconocer a escribir: elegir la traducción, ordenar las palabras (con alguna de más para despistar), unir parejas, entender la frase, escribirla y escucharla. Sin voz en el equipo, escuchar pasa a escribir.",
        code: { file: "Form1.cpp", text: mlLesson },
      },
      {
        title: "5. Corregir con calma",
        text: "Las respuestas se comparan sin mayúsculas ni signos. Si solo faltan los acentos, vale avisando («Ojo con los acentos»); si hay una errata (una letra, o dos en frases largas), también vale y enseña cómo se escribe. Las palabras cortas no tienen margen: «no» y «na» no son lo mismo.",
        code: { file: "Form1.cpp", text: mlCheck },
      },
      {
        title: "6. Repaso, racha y vidas",
        text: "Cada frase guarda lo bien que se sabe y cuándo repasarla: bien, sube y tarda más en volver; mal, baja y vuelve hoy. La experiencia suma a la meta del día y la racha cuenta días seguidos (sin practicar ayer ni hoy, se pierde). Un fallo cuesta una vida y el juego vuelve al final; las vidas vuelven solas cada media hora. Las pruebas internas (DMS_MINILANG_SELFTEST) comprueban todo esto con fechas fijas, y las de la interfaz (DMS_MINILANG_UITEST) juegan lecciones enteras con clics.",
        code: { file: "Form1.cpp", text: mlRemember },
      },
      {
        title: "7. La voz y la barra de menús",
        text: "En macOS, say lee la frase con una voz del idioma (la busca entre las instaladas), más despacio con 🐢, y la anterior se calla al empezar otra. Al cerrar la ventana, MiniLang sigue en la barra de menús con la racha y lo que falta para la meta («🔥 6  15/20»); su menú abre la lección siguiente o un repaso rápido.",
        code: { file: "Form1.cpp", text: mlSpeak },
      },
      {
        title: "8. Un curso de 10.000 palabras",
        text: "El curso grande sale de Tatoeba, una colección libre de frases traducidas por personas (CC BY 2.0 FR). Un script de Python (scripts/demo-extra/minilang/build_course.py) cuenta lo que se usa cada palabra en dos millones de frases en inglés, deja fuera los nombres propios (los que quedan igual en la traducción, como Tom) y recorre las palabras de la más usada a la menos: para cada una toma una o dos frases que ya se entienden con ella. Así cada frase solo usa palabras vistas más la nueva. Cada unidad junta unas 25 palabras y el nivel (A1 a C2) sale de cuántas se llevan; el resultado es un paquete .json que va dentro de la app y se instala solo.",
        code: { file: "build_course.py", text: mlCourse },
      },
    ],
  },
  cpp_pass: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con su menú, la barra de arriba (búsqueda y botones), el campo de la contraseña maestra, los diálogos de abrir y guardar y la barra de estado; el código de Form1.cpp trae toda la criptografía de KeePass escrita a mano, lee y escribe el formato KDBX y dibuja los grupos, las entradas y el bloqueo.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "La bienvenida, el bloqueo y la bóveda: grupos, entradas y la entrada elegida." },
        { name: "Menu1", kind: "Menu", text: "Archivo (nueva, abrir, guardar, bloquear), Contraseñas (entradas y grupos), Herramientas (generador, revisión, clave maestra, seguridad) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Cada segundo: vaciar el portapapeles a su hora y bloquear tras 5 minutos sin uso." },
        { name: "DlgOpen / DlgSave / DlgKey", kind: "OpenDialog / SaveDialog", text: "Abrir y guardar archivos .kdbx y elegir el archivo de clave." },
        { name: "Search", kind: "Entry", text: "Busca en títulos, usuarios, URL y notas mientras se escribe." },
        { name: "BtnAdd / BtnGen / BtnLock / BtnSave", kind: "Button", text: "Nueva entrada, generador, bloquear y guardar." },
        { name: "Board", kind: "Frame", text: "Donde el código dibuja todo (un Fl_Widget propio)." },
        { name: "Master / BtnUnlock", kind: "Password / Button", text: "La contraseña maestra y Desbloquear (Master_enter, BtnUnlock_click)." },
        { name: "Status", kind: "StatusBar", text: "El archivo, cuántas entradas y el cifrado y la derivación que usa." },
      ],
      apis: [
        "KDBX 4 (y lectura de KDBX 3.1): el formato de KeePass y KeePassXC",
        "AES-256-CBC, ChaCha20 y Salsa20; SHA-256, SHA-512 y HMAC-SHA-256; BLAKE2b; Argon2d y Argon2id, todo escrito en el código",
        "DEFLATE (gzip) para leer las bases de datos comprimidas",
        "arc4random_buf (macOS): el azar del sistema para las claves y el generador",
        "Probado con keepassxc-cli y pykeepass en los dos sentidos",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): arriba, un Frame con la búsqueda y cuatro botones; debajo, otro Frame (Board) con el campo Password de la contraseña maestra y el botón Desbloquear; tres componentes de diálogo (OpenDialog y SaveDialog) para los archivos .kdbx y el de clave, el Menu, el Timer y la StatusBar.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae cada componente y los métodos virtuales BtnUnlock_click, Master_enter, BtnAdd_click, BtnGen_click, BtnLock_click, BtnSave_click, Tick_timer y Menu1_click. Los diálogos ya traen su título y su filtro (*.kdbx): DlgOpen.execute() devuelve la ruta elegida.",
        shot: "generated",
      },
      {
        title: "3. La clave: contraseña, archivo de clave y Argon2",
        text: "Como en KeePass, la clave compuesta es el SHA-256 de la contraseña y, si hay, el del archivo de clave (DMarlonPass lee y crea el XML 2.0 de KeePass). Después, la derivación la hace lenta a propósito: Argon2d o Argon2id con 64 MiB, o AES-KDF con millones de rondas. El tiempo de apertura se mide en el propio equipo al crear la base de datos.",
        shot: "code",
        code: { file: "Form1.cpp", text: psKey },
      },
      {
        title: "4. Argon2 sin bibliotecas",
        text: "Argon2 llena memoria con bloques de 1 KiB mezclados con BLAKE2b; este es su corazón, la función G de la RFC 9106. Las pruebas internas lo comprueban con los vectores oficiales de Argon2d, Argon2i y Argon2id, y hace 64 MiB en unos 130 ms.",
        code: { file: "Form1.cpp", text: psArgon },
      },
      {
        title: "5. El archivo: HMAC por bloques y AES o ChaCha20",
        text: "El encabezado va con su SHA-256 y su HMAC; el contenido, cifrado con AES-256-CBC o ChaCha20, se parte en bloques de 1 MiB y cada uno lleva su HMAC-SHA-256 con una clave propia. Si cambia un solo byte, no abre; si la contraseña no es la buena, falla el HMAC del encabezado. Cada vez que se guarda, la semilla, el vector inicial y la sal de Argon2 son nuevos.",
        code: { file: "Form1.cpp", text: psBlocks },
      },
      {
        title: "6. Las contraseñas, cifradas también dentro",
        text: "Dentro del archivo, el XML guarda las contraseñas cifradas otra vez con un flujo aparte (ChaCha20 en KDBX 4, Salsa20 en KDBX 3), en el orden del documento. DMarlonPass trabaja sobre ese mismo XML: lo que no conoce (iconos, adjuntos, campos propios, datos de otros programas) se guarda tal cual, y al editar, la versión anterior pasa al historial como en KeePass.",
        code: { file: "Form1.cpp", text: psProtect },
      },
      {
        title: "7. Comprobado con KeePassXC y pykeepass",
        text: "Las pruebas internas (DMS_PASS_SELFTEST) llevan dentro dos bases de datos de verdad: una creada con KeePassXC (KDBX 3.1, AES-KDF) y otra con pykeepass (KDBX 4, Argon2d, con un adjunto y un campo protegido). En el otro sentido, lo que guarda DMarlonPass (AES-256 y ChaCha20 con Argon2d, Argon2id o AES-KDF, con y sin archivo de clave) lo abren keepassxc-cli y pykeepass.",
        code: { file: "Form1.cpp", text: psTest },
      },
      {
        title: "8. Bloquear sin dejar rastro",
        text: "Al bloquear (a mano, con ⌘L o tras 5 minutos sin uso) se borra con ceros todo lo descifrado y la clave, de forma que el compilador no se lo salte; el portapapeles se vacía a los 20 segundos. Los archivos se escriben aparte y luego se renombran, con permisos solo para usted.",
        code: { file: "Form1.cpp", text: psLock },
      },
    ],
  },
  cpp_ccusage: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con su menú, la barra de arriba (el origen, lo que se ve, el periodo y los botones), el reloj y la barra de estado; el código de Form1.cpp lee los registros de Claude Code o llama a la API de administración, calcula lo que cuesta cada mensaje y dibuja el panel con el mapa de calor.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "El panel: las cifras, el mapa de calor, las barras y las tablas." },
        { name: "Menu1", kind: "Menu", text: "Archivo (actualizar, exportar a CSV, ajustes, barra de menús, salir), Ver (coste, tokens, sesiones) y Ayuda (cómo funciona y los precios)." },
        { name: "Tick", kind: "Timer", text: "Cada segundo: la barra de estado, la medianoche y, cada 15 minutos, otra lectura." },
        { name: "Source / Metric / Period", kind: "Combobox", text: "De dónde salen los datos, qué se mide y el periodo de las tablas (Source_select, Metric_select, Period_select)." },
        { name: "BtnRefresh / BtnSettings / BtnBar", kind: "Button", text: "Actualizar ahora, los ajustes y minimizar a la barra de menús." },
        { name: "Board", kind: "Frame", text: "Donde el código pone el panel (un Fl_Widget propio que se dibuja entero)." },
        { name: "Status", kind: "StatusBar", text: "El origen, la hora de la última lectura y cuánto falta para la próxima, o cómo va la lectura." },
      ],
      apis: [
        "Los registros de Claude Code: un .jsonl por sesión en ~/.claude/projects, con el uso de cada respuesta",
        "La API de Claude Code Analytics (/v1/organizations/usage_report/claude_code) con una clave de administrador, por curl",
        "Los precios de la API de Anthropic por modelo: entrada, caché de 5 minutos y de 1 hora, lectura de la caché, salida y modo rápido",
        "NSStatusItem y NSMenu desde C++ con el runtime de Objective-C (objc_msgSend)",
        "Fl::awake para que los hilos que leen y bajan avisen a la ventana",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): arriba, un Frame con tres Combobox (Origen, Ver y Periodo) y tres botones; debajo, otro Frame (Board) para el panel, el Menu, el Timer de un segundo y la StatusBar.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae cada componente y los métodos virtuales Source_select, Metric_select, Period_select, BtnRefresh_click, BtnSettings_click, BtnBar_click, Tick_timer y Menu1_click; Form1 los rellena y pone el panel dentro de Board.",
        shot: "generated",
      },
      {
        title: "3. Leer gigas sin copiarlos",
        text: "Los registros pesan gigas, y casi todo es el texto de las conversaciones. Cada línea se recorre sin copiarla: se leen solo las claves que interesan (el tipo, la fecha, la sesión, el modelo y el uso) y el resto se salta. Así, un texto que contenga «\"usage\"» no engaña: solo cuenta el uso de verdad, el del mensaje.",
        shot: "code",
        code: { file: "Form1.cpp", text: ccLite },
      },
      {
        title: "4. Cada mensaje, una vez",
        text: "Claude Code escribe la misma respuesta en varias líneas (una por trozo) y a veces en varios archivos: cada mensaje se cuenta una vez por su id y el de la petición. De cada archivo se recuerda hasta dónde se leyó, así que la siguiente lectura solo trae lo nuevo; una línea a medias se deja para la próxima vez. Comprobado con los registros de verdad contra un cálculo aparte en Python: los mismos mensajes y el mismo coste.",
        code: { file: "Form1.cpp", text: ccScan },
      },
      {
        title: "5. Lo que cuesta cada modelo",
        text: "El coste se calcula con el precio de cada modelo por millón de tokens: la entrada, la escritura en la caché de 5 minutos y de 1 hora, la lectura de la caché y la salida; el modo rápido cuesta el doble y Haiku 5.5 cambia de precio con más de 100.000 tokens de entrada. Con un plan Pro o Max no se paga así: es lo que costaría con la API.",
        code: { file: "Form1.cpp", text: ccPrice },
      },
      {
        title: "6. La API de Claude Code Analytics",
        text: "Con el origen «API de administración», la app pide cada día a /v1/organizations/usage_report/claude_code con su clave sk-ant-admin, página a página, en otro hilo. La clave va en un archivo de configuración de curl que solo lee usted, no en la línea de órdenes. Los días cerrados se guardan; hoy y ayer se vuelven a pedir.",
        code: { file: "Form1.cpp", text: ccApi },
      },
      {
        title: "7. El mapa de calor",
        text: "Como en GitHub: 53 columnas de semanas, de lunes a domingo, y cuatro tonos de verde según los cuartiles de los días con uso. Cada casilla se apunta para el ratón: al pasar por encima sale el día con sus cifras y al pulsarla, su detalle a la derecha.",
        code: { file: "Form1.cpp", text: ccHeat },
      },
      {
        title: "8. En la barra de menús",
        text: "El icono de la barra de menús es un NSStatusItem hecho desde C++ con objc_msgSend: lo gastado hoy junto al icono y un menú con la semana, el mes, los últimos 7 días y el gasto por modelo. Al cerrar la ventana, la app sale del Dock y sigue en la barra, leyendo cada 15 minutos.",
        code: { file: "Form1.cpp", text: ccBar },
      },
    ],
  },
  pascal_travel: {
    intro:
      "Se hizo en DMarlon Studio con el destino Pascal (Lazarus): el Diseñador pone la ventana con su menú, el panel de la izquierda con los campos, los combos, las casillas, las opciones y los botones, el reloj y la barra de estado; el código de Form1.pas llama a Claude Code, lee el plan y dibuja la imagen vertical y las páginas del dosier.",
    tech: {
      language: "Object Pascal (Free Pascal)",
      target: "Escritorio con Lazarus (LCL): destino Pascal del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "El panel de la izquierda y la vista previa." },
        { name: "Menu1", kind: "Menu", text: "Archivo (preparar, guardar, abrir y guardar el plan, el ejemplo), Ver (imagen o dosier) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Mientras Claude Code trabaja: el tiempo que lleva." },
        { name: "Origin / Dest", kind: "Entry", text: "El origen y el destino; Enter en el destino prepara el plan (Dest_enter)." },
        { name: "Days / Pace / Budget", kind: "Combobox", text: "Los días (1 a 14), el ritmo y el presupuesto." },
        { name: "ChkHistory… ChkKids", kind: "Checkbutton", text: "Lo que le interesa: van al encargo para Claude." },
        { name: "RadImage / RadDossier", kind: "Radiobutton", text: "Imagen vertical o dosier en PDF (RadImage_click, RadDossier_click)." },
        { name: "BtnPlan / BtnSave", kind: "Button", text: "Preparar el plan (o cancelarlo) y guardarlo." },
        { name: "Stage", kind: "Frame", text: "Donde el código pone la vista previa (un TPaintBox)." },
        { name: "Status", kind: "StatusBar", text: "El plan que se ve, el tiempo que tardó o el error." },
      ],
      apis: [
        "Claude Code: «claude -p --output-format json --json-schema …» con TProcess, en un TThread",
        "fpjson y jsonparser para leer el plan (structured_output)",
        "El lienzo de la LCL (TBitmap) para la imagen de 1080 × 1920 y las páginas A4",
        "fpPDF (fcl-pdf) para el dosier, con las páginas en JPEG",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino Pascal (Lazarus): a la izquierda, un Frame blanco con dos Entry (origen y destino), tres Combobox (días, ritmo y presupuesto), seis Checkbutton con los intereses, dos Radiobutton para el formato y dos Button; a la derecha, otro Frame (Stage) para la vista previa, el Menu, el Timer y la StatusBar.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase TFormDesign (pestaña «Pascal generado») crea cada componente y declara los métodos virtuales BtnPlan_click, BtnSave_click, RadImage_click, RadDossier_click, Dest_enter, Tick_timer y Menu1_click; TForm1 los rellena.",
        shot: "generated",
      },
      {
        title: "3. Claude Code desde la app",
        text: "El encargo (el origen, el destino, los días y lo demás) va a «claude -p» por la entrada estándar, en otro hilo. Con --json-schema, Claude Code responde con un objeto que sigue el esquema del plan; --tools= le quita las herramientas (solo escribe) y --no-session-persistence no guarda la sesión.",
        shot: "code",
        code: { file: "Form1.pas", text: trClaude },
      },
      {
        title: "4. Leer el plan",
        text: "La respuesta de «--output-format json» trae el plan ya validado en structured_output (o como texto en result) y, si algo falla, is_error con el motivo. Se lee con fpjson; los títulos de los días se limpian («Día 1: …») porque el número ya lo pone la app.",
        code: { file: "Form1.pas", text: trParse },
      },
      {
        title: "5. Una imagen vertical en la que todo quepa",
        text: "La imagen mide 1080 × 1920. Se mide antes de dibujar: con las descripciones en dos líneas, en una o sin ellas, y con la letra un poco más pequeña si hace falta; se dibuja con el mayor detalle que quepa. Un plan de dos días lleva todo; uno de siete, lo justo.",
        code: { file: "Form1.pas", text: trFit },
      },
      {
        title: "6. El dosier en PDF",
        text: "Cada página A4 se dibuja en el lienzo a 150 ppp (portada, una por día y los consejos), se guarda en JPEG y fpPDF la mete tal cual en el PDF (poUseRawJPEG): un dosier de cinco páginas pesa menos de 1 MB y se ve igual en cualquier lector.",
        code: { file: "Form1.pas", text: trPdf },
      },
    ],
  },
  cpp_radio: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con su menú, la barra de búsqueda (el campo, el país y el botón), el reloj y la barra de estado; el código de Form1.cpp dibuja la mesa entera, busca en Radio Browser, lee lo que suena y hace sonar cada canal.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "La mesa: pantalla, mandos, canales y pads." },
        { name: "Menu1", kind: "Menu", text: "Archivo (grabar, carpeta de grabaciones), Canales (sonar, silenciar, vaciar, parar todo) y Ayuda." },
        { name: "Tick", kind: "Timer", text: "Diez veces por segundo: los fundidos, los medidores, el apagado y, cada 20 s, lo que suena." },
        { name: "Search / BtnSearch", kind: "Entry / Button", text: "Buscar emisoras por su nombre (Search_enter, BtnSearch_click)." },
        { name: "Country", kind: "Combobox", text: "El país de las emisoras (Country_select)." },
        { name: "Board", kind: "Frame", text: "Donde el código pone la mesa (un Fl_Widget propio)." },
        { name: "Status", kind: "StatusBar", text: "El canal elegido, lo que suena y la grabación." },
      ],
      apis: [
        "Radio Browser (api.radio-browser.info): una base de datos abierta de emisoras, por curl",
        "Los metadatos ICY de Shoutcast e Icecast (Icy-MetaData: 1, StreamTitle)",
        "AVPlayer (AVFoundation) desde C++ con el runtime de Objective-C, uno por canal",
        "ffplay (FFmpeg) en Windows y Linux",
        "curl también para grabar la emisora tal como llega",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK) y la ventana oscura: arriba, un Frame con el Entry de búsqueda, el Combobox del país y el botón; debajo, otro Frame (Board) para la mesa, el Menu, un Timer de 100 ms y la StatusBar.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae cada componente y los métodos virtuales Search_enter, BtnSearch_click, Country_select, Tick_timer y Menu1_click; Form1 los rellena y pone la mesa dentro de Board.",
        shot: "generated",
      },
      {
        title: "3. Buscar emisoras",
        text: "Cada pad de género busca en Radio Browser por su etiqueta (jazz, rock, news…), las más votadas primero y solo las que funcionan; con un país, solo las de ese país. La respuesta es JSON y se queda con las que tienen una dirección de audio válida.",
        shot: "code",
        code: { file: "Form1.cpp", text: rdSearch },
      },
      {
        title: "4. Lo que suena",
        text: "Cada 20 segundos, para los canales que suenan, se piden unos segundos de la emisora con «Icy-MetaData: 1»: el servidor intercala cada icy-metaint bytes un bloque con StreamTitle='Artista - Tema'. Probado con emisoras de verdad.",
        code: { file: "Form1.cpp", text: rdIcy },
      },
      {
        title: "5. Seis reproductores a la vez",
        text: "En macOS cada canal es un AVPlayer de AVFoundation, que se carga al vuelo y se usa desde C++ con objc_msgSend: initWithURL:, play, pause y setVolume:, cada uno con su volumen. En Windows y Linux, ffplay.",
        code: { file: "Form1.cpp", text: rdPlayer },
      },
      {
        title: "6. Fundidos y medidores",
        text: "Diez veces por segundo, el volumen de cada canal se acerca al que pide su fader por el general (o a cero si está en silencio), a la velocidad del mando de fundido; la emisora que se cambia se va apagando. Los medidores de la pantalla enseñan ese volumen.",
        code: { file: "Form1.cpp", text: rdFade },
      },
    ],
  },
  cpp_blocks: {
    intro:
      "Se hizo en DMarlon Studio con el destino C++ (FLTK): el Diseñador pone la ventana con su menú y un Timer de 16 ms (60 fotogramas por segundo); el código de Form1.cpp lleva el juego entero y lo dibuja todo, de la ciudad a las chispas.",
    tech: {
      language: "C++17",
      target: "Escritorio con FLTK 1.4: destino C++ del estudio, una app nativa para macOS (Apple Silicon e Intel) y Windows",
      components: [
        { name: "Form1", kind: "Ventana", text: "El juego: el pozo, los paneles, la ciudad y los efectos." },
        { name: "Menu1", kind: "Menu", text: "Juego (nueva partida, pausa, sonido, salir) y Ayuda (controles y acerca de)." },
        { name: "Tick", kind: "Timer", text: "Cada 16 ms: la caída, las teclas sostenidas, las chispas y el dibujo." },
        { name: "Board", kind: "Frame", text: "Donde el código pone el juego (un Fl_Widget propio que recibe el teclado)." },
      ],
      apis: [
        "FLTK: fl_draw para todo el dibujo y FL_KEYBOARD / FL_KEYUP para el teclado",
        "Sin bibliotecas de juegos: la lógica, las colisiones y la puntuación en el código",
        "afplay con los sonidos del sistema de macOS",
      ],
    },
    steps: [
      {
        title: "1. La ventana en el Diseñador",
        text: "Un proyecto con destino C++ (FLTK): un Frame (Board) que ocupa la ventana, el Menu y un Timer de 16 ms. Nada más: el resto se dibuja.",
        shot: "design",
      },
      {
        title: "2. El código que genera el estudio",
        text: "La clase FormDesign (pestaña «C++ generado») trae el Frame y los métodos virtuales Tick_timer y Menu1_click; Form1 pone el juego dentro de Board y lo mueve con el reloj.",
        shot: "generated",
      },
      {
        title: "3. La bolsa de siete",
        text: "Las piezas no salen al azar sin más: se mete una de cada en una bolsa, se baraja y se sacan; cuando se acaba, otra bolsa. Así nunca pasa mucho sin la pieza larga.",
        shot: "code",
        code: { file: "Form1.cpp", text: nbBag },
      },
      {
        title: "4. Girar con rebote",
        text: "Al girar, si la pieza choca con la pared o con otros bloques, se prueba a empujarla una o dos columnas (o una fila arriba) antes de rendirse: es lo que deja girar pegado a la pared.",
        code: { file: "Form1.cpp", text: nbRotate },
      },
      {
        title: "5. Puntos, combos y niveles",
        text: "Al fijar la pieza se quitan las filas llenas: 100, 300, 500 u 800 puntos por el nivel, la mitad más si son dos de cuatro seguidas y un extra por combo. Cada 10 filas sube el nivel y la caída se acelera.",
        code: { file: "Form1.cpp", text: nbLock },
      },
      {
        title: "6. Teclas que se sostienen",
        text: "La repetición del teclado del sistema no vale para jugar: el juego guarda qué flecha está pulsada (FL_KEYBOARD y FL_KEYUP) y, en cada fotograma, la mueve sola tras 0,17 s, una columna cada 0,05 s.",
        code: { file: "Form1.cpp", text: nbKeys },
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
        text: "At the top go your favorites (the star in the panel) and the last six you opened; all the rest go in the “All apps” submenu, which macOS scrolls when the list is long (over 40, one item per letter). Favorites and recent apps are saved in a text file.",
        code: { file: "Form1.pas", text: launcherMenu },
      },
      {
        title: "6. Search and keyboard",
        text: "As you type, apps with a word starting that way come first (“co” → Console, Currency converter) and then those that only contain it. The arrow keys choose and Enter opens. Its own tests (DMS_LAUNCHER_SELFTEST=1) create fake apps and check search, favorites, the menu with 16-point icons and the panel.",
        code: { file: "Form1.pas", text: launcherSearch },
      },
    ],
  },
  pascal_opend: {
    intro:
      "It was made in DMarlon Studio with the Pascal (Lazarus) target: the Designer provides the window with its menu, the timer and the dialogs to open, save, place images and export; everything else (the canvas, the tool column, the inspector, the layers and the presentation) is drawn by the code in Form1.pas with its own rasterizer, the same on macOS and Windows.",
    tech: {
      language: "Object Pascal (Free Pascal 3.2)",
      target: "Desktop with Lazarus (LCL): the studio's Pascal target, built with lazbuild for macOS (Cocoa) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The editor window (1360 × 840, resizable)." },
        { name: "Menu1", kind: "Menu", text: "File, Edit, Object, View, AI and Help; the shortcuts (⌘Z, ⌘G, ⌥⌘K…) are set from the code." },
        { name: "Tick", kind: "Timer", text: "Every 33 ms: the text caret and the prototype animations (with nothing to move, it does not draw)." },
        { name: "DlgOpen / DlgSave", kind: "OpenDialog / SaveDialog", text: "Open and save .opend designs." },
        { name: "DlgImage", kind: "OpenDialog", text: "Place an image (PNG, JPG or BMP) or use it as a fill." },
        { name: "DlgExport", kind: "SaveDialog", text: "Export the selection to PNG (1x to 4x) or SVG." },
        { name: "DlgJson / DlgJsonSave", kind: "OpenDialog / SaveDialog", text: "Import the AI's JSON design and save the template." },
        { name: "Stage", kind: "Frame", text: "Where the code places a TPaintBox with the whole editor." },
        { name: "StageHint", kind: "Label", text: "Only visible in the Designer." },
      ],
      apis: [
        "Its own rasterizer in Pascal: exact per-pixel coverage (antialiasing), transparency, gradients, images, blurred shadows and inside, center or outside strokes",
        "TBitmap and TLazIntfImage (LCL): text is drawn once as a mask and cached; the result is copied to the window at the Retina screen scale",
        "fpjson and jsonparser (FCL): the JSON template for the AI, importing its designs and exporting the selection",
        "TFPWriterPNG and base64 (FCL): export to PNG with transparency and to SVG with the images embedded",
        "Clipbrd (LCL): copy and paste layers, CSS or Flutter code and JSON",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the Pascal (Lazarus) target: a Menu with its six menus, a Timer, six dialogs and a Frame filling the window. The menu and app texts are translated with the rest of the example: in English you get the same app in English.",
        shot: "design",
      },
      {
        title: "2. The class the studio generates",
        text: "design.pas has Menu1, Tick, the dialogs and Stage, and the virtual methods Menu1_click and Tick_timer; Form1.pas overrides them and creates a TPaintBox inside Stage where everything is drawn.",
        shot: "generated",
      },
      {
        title: "3. Its own rasterizer",
        text: "The LCL does not have transparency and antialiasing everywhere, so OpenD++ paints in its own memory: each shape becomes polygons, it works out how much of each pixel they cover (the same method fonts use) and blends it with its color, gradient, image or a text mask. So it looks the same on macOS and Windows, and the same function exports to PNG.",
        shot: "code",
        code: { file: "Form1.pas", text: opendRaster },
      },
      {
        title: "4. The layers: frames, groups and components",
        text: "The document is a tree of layers with coordinates relative to their frame. Each layer is drawn with its matrix (position and rotation), its shadow, its fill and its stroke; frames clip what is inside and an instance draws its component's children, with the texts changed in it.",
        code: { file: "Form1.pas", text: opendDraw },
      },
      {
        title: "5. Auto layout and smart guides",
        text: "A frame with auto layout places its children in a row or column, with gap and padding, and can hug its contents. When moving, the smart guides align edges and centers with neighbouring layers and show the distance to the frame; undo saves the document before each change.",
        code: { file: "Form1.pas", text: opendLayout },
      },
      {
        title: "6. Designs made by an AI",
        text: "The AI menu copies a JSON template with the instructions, the format and an example (pages, frames, components, instances, auto layout and prototype links). Paste it into ChatGPT, Claude or another AI with what you want, and paste its answer back into OpenD++ (or with ⌘V on the canvas). The built-in tests (DMS_OPEND_SELFTEST=1) import the template and check the rasterizer, saving and opening, undo, grouping, instances, CSS and the presentation; the screenshots on this page are drawn by the app itself (DMS_OPEND_SHOT).",
        code: { file: "Form1.pas", text: opendJson },
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
  cpp_mywa: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with the chat list, the conversation area and the AI panel (provider, style, what you want to say, the draft and the buttons); the code in Form1.cpp reads WhatsApp, calls the AI and draws the chats and the replies.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The list on the left, the conversation on the right and the AI panel below." },
        { name: "Menu1", kind: "Menu", text: "File (Refresh chats, Import an exported chat, AI keys, Connect and Disconnect WhatsApp, Quit), View (theme) and Help." },
        { name: "Tick", kind: "Timer", text: "Every second: what arrived through the bridge and, every few, new messages from WhatsApp Desktop." },
        { name: "Side / Search", kind: "Frame / Entry", text: "The chat column and its search box." },
        { name: "ChatArea", kind: "Frame", text: "Where the code draws the bubbles and the three suggested replies." },
        { name: "AiBar", kind: "Frame", text: "The AI panel." },
        { name: "Provider / Tone", kind: "Combobox", text: "Claude or ChatGPT, and the style of the reply." },
        { name: "Intent", kind: "Entry", text: "What you want to say (optional); Enter asks for replies." },
        { name: "BtnSuggest", kind: "Button", text: "✨ Suggest replies." },
        { name: "Draft", kind: "Text", text: "The draft; Enter sends it (Shift+Enter, a new line)." },
        { name: "BtnSend", kind: "Button", text: "Send ➤: sends the draft to the open chat." },
        { name: "BtnAttach", kind: "Button", text: "📎 Attach: sends a file, with the draft as caption." },
        { name: "Tasks", kind: "Code", text: "The list row and the tasks view are drawn by the code, in Side and ChatArea." },
        { name: "Status", kind: "StatusBar", text: "How many chats, from where, which AI and how it sends." },
      ],
      apis: [
        "Claude through the Messages API (HTTP with curl): claude-opus-5-5, low effort for quick replies and server-side fallbacks if the model declines",
        "ChatGPT through the OpenAI API (HTTP with curl), with the model you choose",
        "The system's SQLite through dlopen: the WhatsApp Desktop database, read-only",
        "security (macOS Keychain): the AI keys",
        "Fl_JPEG_Image and Fl_PNG_Image (FLTK): profile pictures, received photos and the QR code",
        "Official WhatsApp Business API (Meta's Cloud API, Graph API with curl): sending texts and attachments",
        "wabridge, a Go program with whatsmeow (the WhatsApp Web protocol): link with a QR code, send and receive; the app starts it and talks to it over stdin/stdout",
        "WhatsApp Desktop's ContactsV2.sqlite (read-only): the names of who writes in groups",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: on the left a Frame with an Entry to search, on the right a Frame for the conversation and, below, another with two Comboboxes (AI and style), an Entry, the green suggest button, a Text for the draft and the “Send ➤” and “📎 Attach” buttons.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (the “Generated C++” tab) has each component and the virtual methods BtnSuggest_click, Intent_enter, BtnSend_click, BtnAttach_click, Provider_select, Tick_timer and Menu1_click, which Form1 overrides.",
        shot: "generated",
      },
      {
        title: "3. Reading WhatsApp without touching it",
        text: "WhatsApp Desktop keeps the chats in an SQLite database. The app opens it read-only with the SQLite that comes with macOS (loaded through dlopen, no new libraries) and reads the chats and the latest messages. Without WhatsApp Desktop, it reads a chat exported from an iPhone or Android.",
        shot: "code",
        code: { file: "Form1.cpp", text: mywaDb },
      },
      {
        title: "4. Asking Claude for replies",
        text: "C++ has no official Claude SDK, so the app calls the Messages API over HTTP with curl: Claude Opus 5.5 at low effort (they are short chat replies) and server-side fallbacks if the model declines. The key goes in a temporary file only the user can read, not on the command line. ChatGPT works the same, with its API.",
        code: { file: "Form1.cpp", text: mywaClaude },
      },
      {
        title: "5. Reading the answer",
        text: "The answer is read with a small JSON reader: only the text blocks, and if the model declined (“refusal”) the app says so. The instructions ask for three replies separated by “---”, in the chat's language and without making up details.",
        code: { file: "Form1.cpp", text: mywaParse },
      },
      {
        title: "6. Photos, attachments and theme",
        text: "Each contact's picture comes from Media/Profile (the 96×96 thumbnail) and is cropped into a circle; received photos show in the bubble and documents open with a click. The light or dark theme changes the colours of the drawings and of the design's controls. Its tests (DMS_MYWA_SELFTEST) read a made-up database shaped like WhatsApp's, chats exported from iPhone and Android and answers from Claude and OpenAI; a test server checked the headers and body of both APIs.",
        code: { file: "Form1.cpp", text: mywaSend },
      },
      {
        title: "7. Who writes in groups",
        text: "WhatsApp Desktop no longer stores the sender's name in clear text (it shows a code). The app looks it up in this order: the address book (ContactsV2.sqlite, attached read-only to the query), the group member's name, their profile name (“~ Ana”) and, if there is none, their phone number. Its test builds a made-up address book and checks each case.",
        code: { file: "Form1.cpp", text: mywaWho },
      },
      {
        title: "8. Sending: button, Enter and the official API",
        text: "“Send ➤”, Enter in the draft or “Send” on a suggested reply sends the message. Enter is caught with Fl::event_dispatch before it reaches the field, and Shift+Enter still makes a new line. With the official WhatsApp Business API, a JSON goes to Meta's Graph API; attachments are uploaded first as a form. A test server checked the token, the JSON and the file upload.",
        code: { file: "Form1.cpp", text: mywaEnter },
      },
      {
        title: "9. The bridge with WhatsApp (QR)",
        text: "To use your usual WhatsApp without another app, the demo ships wabridge next to it, a Go program with the whatsmeow library (the WhatsApp Web protocol). The app starts it, talks to it over stdin/stdout with one JSON line per command and shows the QR code to link it. Messages and attachments arrive through it, are saved to mensajes.jsonl and merged with WhatsApp Desktop's without duplicates. It is not official, so the app warns about the ban risk before enabling it.",
        code: { file: "main.go", text: mywaBridge },
      },
      {
        title: "10. Tasks from a chat",
        text: "The “Tasks” row is drawn by the chat list itself, at the top, with the pending count; clicking it switches the chat area to the tasks view (pending first, newest on top, and the done ones struck through). “+ Task” in the header takes the last message you received and a right-click on a bubble takes that message; each task keeps the chat it came from to go back to it. They are saved in tareas.jsonl; the interface tests make the clicks, the right one too.",
        code: { file: "Form1.cpp", text: mywaTasks },
      },
      {
        title: "11. Selecting, searching and scrolling",
        text: "The code draws the conversation, so it also handles text selection: drawing each line stores where each letter starts, and the mouse becomes (message, line, letter). Dragging selects, double-click takes the whole message and Cmd+C copies it with its line breaks. The wheel scrolls through the history (reaching the top loads 200 more messages) and “🔍 Search” searches the whole chat, highlights each hit and jumps between them. Pending tasks have a green, orange or red dot by age, also on the chat in the list.",
        code: { file: "Form1.cpp", text: mywaSelect },
      },
      {
        title: "12. Another language, flags and stickers",
        text: "“🌐 Translate” stores the language (detected or chosen) per contact. What you receive is translated in batches: the AI (through the same ai_ask function as the suggestions) returns JSON with the language and one translation per message, saved in traducciones.jsonl. What you write is translated before sending and your original stays below it, in your bubble. The header shows the country's flag and local time (from the phone prefix and the system's time zone database; in groups, those of who writes). Stickers are WebP: macOS's sips turns them into PNG on another thread.",
        code: { file: "Form1.cpp", text: mywaTranslate },
      },
      {
        title: "13. The assistant: investigating a message",
        text: "“🤖 Assistant”, in the app bar, is a chat with AI about your chats. Each question carries a summary of the 60 most recent chats (name, date, the start of the last message, whether it awaits a reply, labels, tasks and CRM stage) and, if you mention someone with @, their conversation, card, lead and tasks. Right-clicking a client's message, “🤖 Investigate with AI”, opens the assistant with that chat and that message. With Claude, the request carries the web search tool in case outside information is needed; ready replies are marked between “<<<RESPUESTA” and “>>>”. There, Enter never sends anything over WhatsApp; the tests check it.",
        code: { file: "Form1.cpp", text: mywaAssist },
      },
      {
        title: "14. The app colours",
        text: "View › Colours… (or ⚙️ Settings) opens a single sheet with the theme, the app colour, the chat background and that of your messages. Each colour is a palette with a light and a dark version: the theme sets the base and apply_colors changes the accent, buttons, highlights, bubbles and background on top. Colours with a meaning (task age, CRM stages, labels) don't change. The interface test fills in the sheet, checks the colours in dark mode, that they are saved and that “Back to the usual colours” restores them.",
        code: { file: "Form1.cpp", text: mywaColors },
      },
      {
        title: "15. Several numbers in tabs",
        text: "Each number has its own folder (the main one, the usual one; the others, cuentas/<id>) with its WhatsApp session, messages, tasks, CRM, cards and labels. Each has its own bridge, all running at once: the Bridge class is no longer a single instance, each bridge keeps a distinct generation number and its lines reach the window tagged with the number they come from. Lines from the visible number take the usual path; those from another just add to its tab. Switching tabs loads that number's data; WhatsApp Desktop and the figures panel belong to the main number. A system lock prevents two bridges on the same account.",
        code: { file: "Form1.cpp", text: mywaAccounts },
      },
      {
        title: "16. Console mode",
        text: "File › Open console mode opens Terminal with MyWhatsapp --console: the same app, with everything, but no window. It starts just like the window (settings, chats, each number's bridge) and whatever is a dialog in the window becomes a question in the terminal: a confirmation, a form field by field, a numbered menu. A thread reads the commands (open, read, send, suggest, assistant, tasks, crm, dash, status, accounts…, in English or Spanish) and, while it waits, the app keeps serving the bridge and the AI: whatever arrives (a new message, the suggested replies, the assistant's answer) is printed above the command line. The QR code for linking is drawn in the terminal with half blocks, black on white. The test feeds it a list of commands with the sample chats.",
        code: { file: "Form1.cpp", text: mywaConsole },
      },
    ],
  },
  cpp_minilang: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with its menu, the timer, the typing field, the Check button and the status bar; the code in Form1.cpp draws the units, the games and the results, keeps the progress and the language packages, and leaves the app in the menu bar.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "Home, lessons, results and languages; when closed, the app stays in the menu bar." },
        { name: "Menu1", kind: "Menu", text: "File (next lesson, review, placement test, languages, import), View (daily goal and voice) and Help." },
        { name: "Tick", kind: "Timer", text: "Every second: lives coming back and the menu bar kept up to date." },
        { name: "Board", kind: "Frame", text: "Where the code draws everything: units, games and results (a custom Fl_Widget)." },
        { name: "Answer", kind: "Entry", text: "To type the translation or what you hear; Enter checks (Answer_enter)." },
        { name: "BtnCheck", kind: "Button", text: "Check and Continue (BtnCheck_click): green if right, red if not." },
        { name: "Status", kind: "StatusBar", text: "The language, the current unit, the streak and today's goal." },
      ],
      apis: [
        "Language packages: one .json per language in the “paquetes” folder, read with a small JSON reader",
        "Levenshtein distance: accepting a typo or missing accents, with a note",
        "Spaced repetition: each sentence comes back after 1, 2, 4, 7, 15 or 30 days depending on how well you know it",
        "say (macOS), launched with posix_spawn: the voice for listening and for hearing what you got right",
        "Objective-C runtime: the streak and goal in the menu bar, with the next lesson and a review",
        "Tatoeba (tatoeba.org, CC BY 2.0 FR): the sentences of the 10,000-word course, ordered by a Python script",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: a Frame filling the window (Board), inside it an Entry to type (Answer) and the Check button (BtnCheck), the Menu, the Timer and a StatusBar. Everything else (units, games and results) is drawn by the code.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (the “Generated C++” tab) has each component and the virtual methods BtnCheck_click, Answer_enter, Tick_timer and Menu1_click, which Form1 overrides. The field and the button sit on top of the drawing and the code places them for each game.",
        shot: "generated",
      },
      {
        title: "3. Languages are packages",
        text: "Each language is a .json file with its units (A1 to C1) and its sentences, with the accepted forms separated by “/” (“I'm fine/I am fine”). Installing one writes its file to the “paquetes” folder; on start the app reads whatever is there, and “Import a package…” accepts packages made by others in the same format. The English course has 15 units and 180 sentences; the Spanish one, for English speakers, the same ones reversed.",
        shot: "code",
        code: { file: "Form1.cpp", text: mlInstall },
      },
      {
        title: "4. Ten games per lesson",
        text: "Each unit has three lessons. A lesson takes the new sentences of its part of the unit plus two to review, and builds ten games in an order that goes from recognising to writing: choose the translation, put the words in order (with a few extra ones as decoys), match pairs, understand the sentence, write it and listen to it. Without a voice on the computer, listening becomes writing.",
        code: { file: "Form1.cpp", text: mlLesson },
      },
      {
        title: "5. Gentle checking",
        text: "Answers are compared without capitals or punctuation. If only the accents are missing, it counts with a note (“Watch the accents”); a typo (one letter, or two in long sentences) also counts and shows how it is spelled. Short words get no leeway: “no” and “na” are not the same.",
        code: { file: "Form1.cpp", text: mlCheck },
      },
      {
        title: "6. Review, streak and lives",
        text: "Each sentence keeps how well you know it and when to review it: right, it goes up and takes longer to come back; wrong, it goes down and comes back today. XP adds to the daily goal and the streak counts days in a row (skip yesterday and today and it is lost). A mistake costs a life and the game comes back at the end; lives return on their own every half hour. The internal tests (DMS_MINILANG_SELFTEST) check all of this with fixed dates, and the interface tests (DMS_MINILANG_UITEST) play whole lessons with clicks.",
        code: { file: "Form1.cpp", text: mlRemember },
      },
      {
        title: "7. The voice and the menu bar",
        text: "On macOS, say reads the sentence with a voice for the language (it picks one among those installed), slower with 🐢, and the previous one stops when another starts. When you close the window, MiniLang stays in the menu bar with the streak and what is left for the goal (“🔥 6  15/20”); its menu opens the next lesson or a quick review.",
        code: { file: "Form1.cpp", text: mlSpeak },
      },
      {
        title: "8. A 10,000-word course",
        text: "The big course comes from Tatoeba, a free collection of sentences translated by people (CC BY 2.0 FR). A Python script (scripts/demo-extra/minilang/build_course.py) counts how often each word is used across two million sentences, leaves out proper names (those that stay the same in the translation, like Tom) and walks the words from the most to the least used: for each one it takes one or two sentences that become understandable with it. So each sentence only uses words already seen plus the new one. Each unit gathers about 25 words and the level (A1 to C2) comes from how many you have learned; the result is a .json package shipped inside the app that installs itself.",
        code: { file: "build_course.py", text: mlCourse },
      },
    ],
  },
  cpp_pass: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with its menu, the top bar (search and buttons), the master password field, the open and save dialogs and the status bar; the code in Form1.cpp has all of KeePass's cryptography written by hand, reads and writes the KDBX format and draws the groups, the entries and the lock screen.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The welcome screen, the lock screen and the vault: groups, entries and the selected entry." },
        { name: "Menu1", kind: "Menu", text: "File (new, open, save, lock), Passwords (entries and groups), Tools (generator, review, master key, security) and Help." },
        { name: "Tick", kind: "Timer", text: "Every second: clear the clipboard on time and lock after 5 minutes without use." },
        { name: "DlgOpen / DlgSave / DlgKey", kind: "OpenDialog / SaveDialog", text: "Open and save .kdbx files and choose the key file." },
        { name: "Search", kind: "Entry", text: "Searches titles, usernames, URLs and notes as you type." },
        { name: "BtnAdd / BtnGen / BtnLock / BtnSave", kind: "Button", text: "New entry, generator, lock and save." },
        { name: "Board", kind: "Frame", text: "Where the code draws everything (a custom Fl_Widget)." },
        { name: "Master / BtnUnlock", kind: "Password / Button", text: "The master password and Unlock (Master_enter, BtnUnlock_click)." },
        { name: "Status", kind: "StatusBar", text: "The file, how many entries, and the cipher and derivation in use." },
      ],
      apis: [
        "KDBX 4 (and reading KDBX 3.1): the KeePass and KeePassXC format",
        "AES-256-CBC, ChaCha20 and Salsa20; SHA-256, SHA-512 and HMAC-SHA-256; BLAKE2b; Argon2d and Argon2id, all written in the code",
        "DEFLATE (gzip) to read compressed databases",
        "arc4random_buf (macOS): the system's randomness for keys and the generator",
        "Tested with keepassxc-cli and pykeepass in both directions",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: at the top, a Frame with the search box and four buttons; below, another Frame (Board) with the Password field for the master password and the Unlock button; three dialog components (OpenDialog and SaveDialog) for .kdbx files and the key file, the Menu, the Timer and the StatusBar.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (the “Generated C++” tab) has each component and the virtual methods BtnUnlock_click, Master_enter, BtnAdd_click, BtnGen_click, BtnLock_click, BtnSave_click, Tick_timer and Menu1_click. The dialogs come with their title and filter (*.kdbx): DlgOpen.execute() returns the chosen path.",
        shot: "generated",
      },
      {
        title: "3. The key: password, key file and Argon2",
        text: "As in KeePass, the composite key is the SHA-256 of the password and, if there is one, of the key file (DMarlonPass reads and creates KeePass's XML 2.0 key files). Then the derivation makes it slow on purpose: Argon2d or Argon2id with 64 MiB, or AES-KDF with millions of rounds. The opening time is measured on the computer itself when the database is created.",
        shot: "code",
        code: { file: "Form1.cpp", text: psKey },
      },
      {
        title: "4. Argon2 without libraries",
        text: "Argon2 fills memory with 1 KiB blocks mixed with BLAKE2b; this is its heart, the G function from RFC 9106. The internal tests check it against the official Argon2d, Argon2i and Argon2id vectors, and it does 64 MiB in about 130 ms.",
        code: { file: "Form1.cpp", text: psArgon },
      },
      {
        title: "5. The file: per-block HMAC and AES or ChaCha20",
        text: "The header comes with its SHA-256 and its HMAC; the content, encrypted with AES-256-CBC or ChaCha20, is split into 1 MiB blocks, each with its own HMAC-SHA-256 key. If a single byte changes, it will not open; if the password is wrong, the header HMAC fails. Every save uses a new seed, initial vector and Argon2 salt.",
        code: { file: "Form1.cpp", text: psBlocks },
      },
      {
        title: "6. Passwords, encrypted inside too",
        text: "Inside the file, the XML keeps passwords encrypted again with a separate stream (ChaCha20 in KDBX 4, Salsa20 in KDBX 3), in document order. DMarlonPass works on that same XML: what it does not know (icons, attachments, custom fields, other programs' data) is saved as is, and when editing, the previous version goes to the history as in KeePass.",
        code: { file: "Form1.cpp", text: psProtect },
      },
      {
        title: "7. Checked with KeePassXC and pykeepass",
        text: "The internal tests (DMS_PASS_SELFTEST) carry two real databases: one created with KeePassXC (KDBX 3.1, AES-KDF) and one with pykeepass (KDBX 4, Argon2d, with an attachment and a protected field). In the other direction, what DMarlonPass saves (AES-256 and ChaCha20 with Argon2d, Argon2id or AES-KDF, with and without a key file) opens in keepassxc-cli and pykeepass.",
        code: { file: "Form1.cpp", text: psTest },
      },
      {
        title: "8. Locking without a trace",
        text: "On lock (by hand, with ⌘L or after 5 minutes without use) everything decrypted and the key are overwritten with zeros in a way the compiler cannot skip; the clipboard clears after 20 seconds. Files are written aside and then renamed, with permissions only for you.",
        code: { file: "Form1.cpp", text: psLock },
      },
    ],
  },
  cpp_ccusage: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with its menu, the top bar (the source, what is shown, the period and the buttons), the timer and the status bar; the code in Form1.cpp reads the Claude Code logs or calls the Admin API, works out what each message costs and draws the dashboard with the heatmap.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The dashboard: the figures, the heatmap, the bars and the tables." },
        { name: "Menu1", kind: "Menu", text: "File (refresh, export to CSV, settings, menu bar, quit), View (cost, tokens, sessions) and Help (how it works and the prices)." },
        { name: "Tick", kind: "Timer", text: "Every second: the status bar, midnight and, every 15 minutes, another read." },
        { name: "Source / Metric / Period", kind: "Combobox", text: "Where the data comes from, what is measured and the period of the tables (Source_select, Metric_select, Period_select)." },
        { name: "BtnRefresh / BtnSettings / BtnBar", kind: "Button", text: "Refresh now, the settings and minimize to the menu bar." },
        { name: "Board", kind: "Frame", text: "Where the code puts the dashboard (its own Fl_Widget, drawn entirely in code)." },
        { name: "Status", kind: "StatusBar", text: "The source, the time of the last read and how long until the next, or how the read is going." },
      ],
      apis: [
        "The Claude Code logs: one .jsonl per session in ~/.claude/projects, with the usage of each response",
        "The Claude Code Analytics API (/v1/organizations/usage_report/claude_code) with an admin key, through curl",
        "Anthropic API prices per model: input, 5-minute and 1-hour cache, cache reads, output and fast mode",
        "NSStatusItem and NSMenu from C++ with the Objective-C runtime (objc_msgSend)",
        "Fl::awake so the threads that read and download notify the window",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: at the top, a Frame with three Comboboxes (Source, View and Period) and three buttons; below, another Frame (Board) for the dashboard, the Menu, a one-second Timer and the StatusBar.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (“Generated C++” tab) has each component and the virtual methods Source_select, Metric_select, Period_select, BtnRefresh_click, BtnSettings_click, BtnBar_click, Tick_timer and Menu1_click; Form1 fills them in and puts the dashboard inside Board.",
        shot: "generated",
      },
      {
        title: "3. Reading gigabytes without copying them",
        text: "The logs weigh gigabytes, and almost all of it is the text of the conversations. Each line is walked through without copying it: only the keys that matter are read (the type, the date, the session, the model and the usage) and the rest is skipped. So a text that contains «\"usage\"» can't fool it: only the real usage, the message's, counts.",
        shot: "code",
        code: { file: "Form1.cpp", text: ccLite },
      },
      {
        title: "4. Each message, once",
        text: "Claude Code writes the same response on several lines (one per chunk) and sometimes in several files: each message is counted once by its id and its request's. For each file it remembers how far it read, so the next read only brings what's new; a half-written line is left for next time. Checked against the real logs with a separate calculation in Python: the same messages and the same cost.",
        code: { file: "Form1.cpp", text: ccScan },
      },
      {
        title: "5. What each model costs",
        text: "The cost uses each model's price per million tokens: input, 5-minute and 1-hour cache writes, cache reads and output; fast mode costs twice as much and Haiku 5.5 changes price above 100,000 input tokens. With a Pro or Max plan you don't pay this way: it's what it would cost with the API.",
        code: { file: "Form1.cpp", text: ccPrice },
      },
      {
        title: "6. The Claude Code Analytics API",
        text: "With the “Admin API” source, the app asks /v1/organizations/usage_report/claude_code for each day with your sk-ant-admin key, page by page, on another thread. The key goes in a curl config file that only you can read, not on the command line. Closed days are kept; today and yesterday are asked for again.",
        code: { file: "Form1.cpp", text: ccApi },
      },
      {
        title: "7. The heatmap",
        text: "Like GitHub's: 53 columns of weeks, Monday to Sunday, and four shades of green by the quartiles of the days with usage. Each square is recorded for the mouse: hovering shows the day with its figures and clicking shows its details on the right.",
        code: { file: "Form1.cpp", text: ccHeat },
      },
      {
        title: "8. In the menu bar",
        text: "The menu bar icon is an NSStatusItem made from C++ with objc_msgSend: today's spend next to the icon and a menu with the week, the month, the last 7 days and the spend by model. When you close the window, the app leaves the Dock and stays in the bar, reading every 15 minutes.",
        code: { file: "Form1.cpp", text: ccBar },
      },
    ],
  },
  pascal_travel: {
    intro:
      "It was made in DMarlon Studio with the Pascal (Lazarus) target: the Designer provides the window with its menu, the left panel with the fields, combo boxes, check boxes, options and buttons, the timer and the status bar; the code in Form1.pas calls Claude Code, reads the plan and draws the vertical image and the dossier pages.",
    tech: {
      language: "Object Pascal (Free Pascal)",
      target: "Desktop with Lazarus (LCL): the studio's Pascal target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The left panel and the preview." },
        { name: "Menu1", kind: "Menu", text: "File (prepare, save, open and save the plan, the example), View (image or dossier) and Help." },
        { name: "Tick", kind: "Timer", text: "While Claude Code works: how long it has taken." },
        { name: "Origin / Dest", kind: "Entry", text: "The origin and destination; Enter in the destination prepares the plan (Dest_enter)." },
        { name: "Days / Pace / Budget", kind: "Combobox", text: "The days (1 to 14), the pace and the budget." },
        { name: "ChkHistory… ChkKids", kind: "Checkbutton", text: "Your interests: they go into the request for Claude." },
        { name: "RadImage / RadDossier", kind: "Radiobutton", text: "Vertical image or PDF dossier (RadImage_click, RadDossier_click)." },
        { name: "BtnPlan / BtnSave", kind: "Button", text: "Prepare the plan (or cancel it) and save it." },
        { name: "Stage", kind: "Frame", text: "Where the code puts the preview (a TPaintBox)." },
        { name: "Status", kind: "StatusBar", text: "The plan shown, how long it took or the error." },
      ],
      apis: [
        "Claude Code: “claude -p --output-format json --json-schema …” with TProcess, in a TThread",
        "fpjson and jsonparser to read the plan (structured_output)",
        "The LCL canvas (TBitmap) for the 1080 × 1920 image and the A4 pages",
        "fpPDF (fcl-pdf) for the dossier, with the pages as JPEG",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the Pascal (Lazarus) target: on the left, a white Frame with two Entries (origin and destination), three Comboboxes (days, pace and budget), six Checkbuttons with the interests, two Radiobuttons for the format and two Buttons; on the right, another Frame (Stage) for the preview, the Menu, the Timer and the StatusBar.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The TFormDesign class (“Generated Pascal” tab) creates each component and declares the virtual methods BtnPlan_click, BtnSave_click, RadImage_click, RadDossier_click, Dest_enter, Tick_timer and Menu1_click; TForm1 fills them in.",
        shot: "generated",
      },
      {
        title: "3. Claude Code from the app",
        text: "The request (origin, destination, days and the rest) goes to “claude -p” through standard input, on another thread. With --json-schema, Claude Code answers with an object that follows the plan's schema; --tools= removes its tools (it only writes) and --no-session-persistence doesn't keep the session.",
        shot: "code",
        code: { file: "Form1.pas", text: trClaude },
      },
      {
        title: "4. Reading the plan",
        text: "The “--output-format json” answer carries the plan already validated in structured_output (or as text in result) and, if something fails, is_error with the reason. It is read with fpjson; day titles are cleaned (“Day 1: …”) because the app already adds the number.",
        code: { file: "Form1.pas", text: trParse },
      },
      {
        title: "5. A vertical image where everything fits",
        text: "The image is 1080 × 1920. It is measured before drawing: with descriptions on two lines, on one or without them, and with slightly smaller type if needed; it is drawn with the most detail that fits. A two-day plan gets everything; a seven-day one, just the essentials.",
        code: { file: "Form1.pas", text: trFit },
      },
      {
        title: "6. The PDF dossier",
        text: "Each A4 page is drawn on the canvas at 150 dpi (cover, one per day and the tips), saved as JPEG and fpPDF puts it into the PDF as is (poUseRawJPEG): a five-page dossier weighs less than 1 MB and looks the same in any reader.",
        code: { file: "Form1.pas", text: trPdf },
      },
    ],
  },
  cpp_radio: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with its menu, the search bar (the field, the country and the button), the timer and the status bar; the code in Form1.cpp draws the whole desk, searches Radio Browser, reads what is playing and plays each channel.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The desk: screen, knobs, channels and pads." },
        { name: "Menu1", kind: "Menu", text: "File (record, recordings folder), Channels (play, mute, clear, stop all) and Help." },
        { name: "Tick", kind: "Timer", text: "Ten times a second: fades, meters, the sleep timer and, every 20 s, what is playing." },
        { name: "Search / BtnSearch", kind: "Entry / Button", text: "Find stations by name (Search_enter, BtnSearch_click)." },
        { name: "Country", kind: "Combobox", text: "The stations' country (Country_select)." },
        { name: "Board", kind: "Frame", text: "Where the code puts the desk (its own Fl_Widget)." },
        { name: "Status", kind: "StatusBar", text: "The selected channel, what is playing and the recording." },
      ],
      apis: [
        "Radio Browser (api.radio-browser.info): an open database of stations, through curl",
        "Shoutcast and Icecast ICY metadata (Icy-MetaData: 1, StreamTitle)",
        "AVPlayer (AVFoundation) from C++ through the Objective-C runtime, one per channel",
        "ffplay (FFmpeg) on Windows and Linux",
        "curl also to record the station as it arrives",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target and a dark window: at the top, a Frame with the search Entry, the country Combobox and the button; below, another Frame (Board) for the desk, the Menu, a 100 ms Timer and the StatusBar.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (“Generated C++” tab) has each component and the virtual methods Search_enter, BtnSearch_click, Country_select, Tick_timer and Menu1_click; Form1 fills them in and puts the desk inside Board.",
        shot: "generated",
      },
      {
        title: "3. Finding stations",
        text: "Each genre pad searches Radio Browser by its tag (jazz, rock, news…), most voted first and only working ones; with a country, only that country's. The answer is JSON, and only stations with a valid audio address are kept.",
        shot: "code",
        code: { file: "Form1.cpp", text: rdSearch },
      },
      {
        title: "4. What's playing",
        text: "Every 20 seconds, for the channels that are playing, a few seconds of the station are requested with “Icy-MetaData: 1”: every icy-metaint bytes the server inserts a block with StreamTitle='Artist - Title'. Tested with real stations.",
        code: { file: "Form1.cpp", text: rdIcy },
      },
      {
        title: "5. Six players at once",
        text: "On macOS each channel is an AVFoundation AVPlayer, loaded on the fly and used from C++ with objc_msgSend: initWithURL:, play, pause and setVolume:, each with its own volume. On Windows and Linux, ffplay.",
        code: { file: "Form1.cpp", text: rdPlayer },
      },
      {
        title: "6. Fades and meters",
        text: "Ten times a second, each channel's volume moves towards its fader times the master (or zero if muted), at the speed of the fade knob; the station being replaced fades away. The screen's meters show that volume.",
        code: { file: "Form1.cpp", text: rdFade },
      },
    ],
  },
  cpp_blocks: {
    intro:
      "It was made in DMarlon Studio with the C++ (FLTK) target: the Designer provides the window with its menu and a 16 ms Timer (60 frames per second); the code in Form1.cpp holds the whole game and draws everything, from the city to the sparks.",
    tech: {
      language: "C++17",
      target: "Desktop with FLTK 1.4: the studio's C++ target, a native app for macOS (Apple Silicon and Intel) and Windows",
      components: [
        { name: "Form1", kind: "Window", text: "The game: the well, the panels, the city and the effects." },
        { name: "Menu1", kind: "Menu", text: "Game (new game, pause, sound, quit) and Help (controls and about)." },
        { name: "Tick", kind: "Timer", text: "Every 16 ms: falling, held keys, sparks and drawing." },
        { name: "Board", kind: "Frame", text: "Where the code puts the game (its own Fl_Widget that receives the keyboard)." },
      ],
      apis: [
        "FLTK: fl_draw for all the drawing and FL_KEYBOARD / FL_KEYUP for the keyboard",
        "No game libraries: the logic, collisions and scoring are in the code",
        "afplay with the macOS system sounds",
      ],
    },
    steps: [
      {
        title: "1. The window in the Designer",
        text: "A project with the C++ (FLTK) target: a Frame (Board) filling the window, the Menu and a 16 ms Timer. Nothing else: the rest is drawn.",
        shot: "design",
      },
      {
        title: "2. The code the studio generates",
        text: "The FormDesign class (“Generated C++” tab) has the Frame and the virtual methods Tick_timer and Menu1_click; Form1 puts the game inside Board and moves it with the timer.",
        shot: "generated",
      },
      {
        title: "3. The seven-bag",
        text: "Pieces don't just come out at random: one of each goes into a bag, it is shuffled and they are drawn; when it runs out, another bag. So you never go long without the long piece.",
        shot: "code",
        code: { file: "Form1.cpp", text: nbBag },
      },
      {
        title: "4. Rotating with kicks",
        text: "When rotating, if the piece hits the wall or other blocks, it tries pushing it one or two columns (or one row up) before giving up: that's what lets you rotate against the wall.",
        code: { file: "Form1.cpp", text: nbRotate },
      },
      {
        title: "5. Points, combos and levels",
        text: "When the piece locks, full lines are removed: 100, 300, 500 or 800 points times the level, half as much again for two fours in a row and an extra per combo. Every 10 lines the level goes up and falling speeds up.",
        code: { file: "Form1.cpp", text: nbLock },
      },
      {
        title: "6. Held keys",
        text: "The system's key repeat isn't good for playing: the game remembers which arrow is held (FL_KEYBOARD and FL_KEYUP) and, each frame, moves it by itself after 0.17 s, one column every 0.05 s.",
        code: { file: "Form1.cpp", text: nbKeys },
      },
    ],
  },
};

export const MADE: Record<Lang, Record<string, DemoMade>> = { es, en };
