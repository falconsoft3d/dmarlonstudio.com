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

export type DemoMade = { intro: string; steps: MadeStep[] };

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

const es: Record<string, DemoMade> = {
  pascal_docker: {
    intro:
      "Se hizo entera en DMarlon Studio con el destino Pascal (Lazarus): el Diseñador pone la ventana, su menú y el reloj; el código de Form1.pas hace el icono de la barra, habla con Docker y dibuja el panel. Estos son los pasos, con el código de verdad del ejemplo.",
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
};

const en: Record<string, DemoMade> = {
  pascal_docker: {
    intro:
      "It was made entirely in DMarlon Studio with the Pascal (Lazarus) target: the Designer provides the window, its menu and the timer; the code in Form1.pas makes the menu bar icon, talks to Docker and draws the panel. These are the steps, with the example's real code.",
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
};

export const MADE: Record<Lang, Record<string, DemoMade>> = { es, en };
