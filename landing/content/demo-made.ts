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
    ],
  },
};

export const MADE: Record<Lang, Record<string, DemoMade>> = { es, en };
