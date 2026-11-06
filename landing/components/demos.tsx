import { Blocks, Code2, Package } from "lucide-react";
import { DemoDownloads } from "@/components/demo-downloads";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { TechChip } from "@/components/tech-chip";
import { contentOf } from "@/content";
import { DEMO_SEEDS, DEMOS_RELEASE_URL, demoImage, type DemoSeed } from "@/lib/demos";
import { PATHS, type Lang } from "@/lib/i18n";

type DemoText = { name: string; text: string; shows: string[] };

type DemosText = {
  title: string;
  eyebrow: string;
  intro: string;
  points: { title: string; text: string }[];
  tech: string;
  shows: string;
  download: string;
  how: { title: string; macos: string[]; windows: string[] };
  studio: string;
  release: string;
  items: Record<DemoSeed, DemoText>;
};

const TEXT: Record<Lang, DemosText> = {
  es: {
    title: "Demos",
    eyebrow: "Hecho con DMarlon Studio",
    intro:
      "Diez utilidades de verdad, hechas con DMarlon Studio. Cada una se diseñó arrastrando componentes, con la lógica en Python, y el estudio la convirtió en una aplicación para macOS y Windows. Descárguela y úsela; después ábrala en el estudio (está entre sus proyectos de ejemplo) y cámbiela.",
    points: [
      {
        title: "Del diseño a una aplicación",
        text: "La misma ventana que dibuja en el Diseñador es la aplicación que se descarga aquí: no hay que reescribir nada para entregarla.",
      },
      {
        title: "Lo que pide una app de verdad",
        text: "Archivos, red, bases de datos SQLite, trabajo en segundo plano, gráficos y paquetes de pip. Cada demo enseña algo distinto.",
      },
      {
        title: "Un código que es suyo",
        text: "Python normal y legible, con un método por evento. Lo puede leer, ampliar y llevar a donde quiera.",
      },
    ],
    tech: "Python · tkinter",
    shows: "Qué demuestra",
    download: "Descargar para",
    how: {
      title: "Cómo abrir una demo",
      macos: [
        "Descomprima el zip y abra la aplicación.",
        "Las demos aún no están firmadas: si macOS la bloquea, haga clic derecho → Abrir, o vaya a Ajustes del Sistema → Privacidad y seguridad → «Abrir igualmente».",
      ],
      windows: [
        "Descomprima la carpeta completa y abra el .exe que hay dentro.",
        "Si aparece «Windows protegió su PC», pulse «Más información» → «Ejecutar de todas formas».",
      ],
    },
    studio: "¿Quiere ver cómo están hechas? Todas vienen como ejemplo en DMarlon Studio: ábralas en el Diseñador, cambie lo que quiera y pulse Ejecutar.",
    release: "Todos los archivos, en GitHub",
    items: {
      calculator: {
        name: "Calculadora",
        text: "Las cuatro operaciones, porcentaje y cambio de signo, con el ratón o el teclado.",
        shows: ["Una ventana diseñada arrastrando botones", "Un evento por botón y el estado en la clase", "Atajos de teclado"],
      },
      notepad: {
        name: "Bloc de notas",
        text: "Abrir, editar y guardar textos, con la línea y la columna en la barra de estado.",
        shows: ["Menús clásicos y atajos", "Diálogos de abrir y guardar del sistema", "Avisar antes de perder cambios"],
      },
      pdf_editor: {
        name: "Editor de PDF",
        text: "Gire, borre, ordene y una páginas; extraiga, divida, edite los datos del documento y protéjalo con contraseña.",
        shows: ["Paquetes de pip (pypdf) dentro de la app", "Barra de herramientas y lista de páginas", "Deshacer y guardar como"],
      },
      disk_usage: {
        name: "Espacio en disco",
        text: "Un mapa del disco con lo que ocupa cada carpeta y cada archivo, por tipos; vea dónde está o mándelo a la Papelera.",
        shows: ["Un gráfico propio dibujado en un lienzo", "Trabajo en segundo plano sin bloquear la ventana", "Abrir el Finder o el Explorador y usar la Papelera"],
      },
      port_scanner: {
        name: "Escáner de puertos",
        text: "Qué puertos TCP están abiertos en un equipo, con el servicio de cada uno y exportación a CSV.",
        shows: ["Red con sockets", "Muchas conexiones en paralelo con progreso", "Validar lo que escribe el usuario"],
      },
      investor: {
        name: "Inversor de bolsa (demo)",
        text: "Compre y venda acciones de empresas ficticias con precios simulados en vivo y vea su cartera ganar o perder.",
        shows: ["Datos en vivo con un temporizador", "Gráfico de cotizaciones", "La cartera guardada entre sesiones"],
      },
      pos: {
        name: "Punto de venta",
        text: "Un TPV al estilo del de Odoo, con imágenes de los productos. Conéctelo a su Odoo con URL, usuario y contraseña: baja los productos y sus precios y envía los pedidos a Ventas.",
        shows: ["Conectarse a Odoo y trabajar sin conexión", "Ventas e imágenes guardadas en SQLite", "Cobro con cambio, ticket y resumen del día"],
      },
      agenda: {
        name: "Agenda",
        text: "Contactos y citas en pestañas, con búsqueda, guardados en una base de datos.",
        shows: ["SQLite sin instalar nada", "Pestañas, tablas y búsqueda", "Formularios de alta y edición"],
      },
      currency: {
        name: "Conversor de moneda",
        text: "Convierta entre divisas con los tipos de cambio reales del Banco Central Europeo.",
        shows: ["Llamar a una API de Internet", "Respuesta sin congelar la ventana", "Funciona sin conexión con los últimos datos"],
      },
      file_renamer: {
        name: "Renombrar archivos",
        text: "Cambie el nombre de muchos archivos a la vez con reglas, viendo el resultado antes de aplicarlo.",
        shows: ["Expresiones regulares y numeración", "Vista previa en vivo con conflictos marcados", "Deshacer el último cambio"],
      },
    },
  },
  en: {
    title: "Demos",
    eyebrow: "Made with DMarlon Studio",
    intro:
      "Ten real utilities made with DMarlon Studio. Each one was designed by dragging components, with its logic in Python, and the studio turned it into an app for macOS and Windows. Download it and use it; then open it in the studio (it is among your example projects) and change it.",
    points: [
      {
        title: "From design to an app",
        text: "The window you draw in the Designer is the app you download here: nothing has to be rewritten to ship it.",
      },
      {
        title: "What a real app needs",
        text: "Files, network, SQLite databases, background work, charts and pip packages. Each demo shows something different.",
      },
      {
        title: "Code that is yours",
        text: "Plain, readable Python, with one method per event. You can read it, extend it and take it anywhere.",
      },
    ],
    tech: "Python · tkinter",
    shows: "What it shows",
    download: "Download for",
    how: {
      title: "How to open a demo",
      macos: [
        "Unzip it and open the app.",
        "The demos are not signed yet: if macOS blocks it, right-click → Open, or go to System Settings → Privacy & Security → “Open Anyway”.",
      ],
      windows: [
        "Unzip the whole folder and open the .exe inside.",
        "If “Windows protected your PC” appears, click “More info” → “Run anyway”.",
      ],
    },
    studio: "Want to see how they are made? They all come as examples in DMarlon Studio: open them in the Designer, change anything and press Run.",
    release: "All files, on GitHub",
    items: {
      calculator: {
        name: "Calculator",
        text: "The four operations, percentage and sign change, with the mouse or the keyboard.",
        shows: ["A window designed by dragging buttons", "One event per button and the state in the class", "Keyboard shortcuts"],
      },
      notepad: {
        name: "Notepad",
        text: "Open, edit and save texts, with the line and column in the status bar.",
        shows: ["Classic menus and shortcuts", "The system's open and save dialogs", "Warning before losing changes"],
      },
      pdf_editor: {
        name: "PDF editor",
        text: "Rotate, delete, reorder and merge pages; extract, split, edit the document details and protect it with a password.",
        shows: ["pip packages (pypdf) inside the app", "Toolbar and page list", "Undo and save as"],
      },
      disk_usage: {
        name: "Disk space",
        text: "A map of the disk with what each folder and file takes up, by type; see where it is or move it to the Trash.",
        shows: ["A custom chart drawn on a canvas", "Background work without freezing the window", "Opening Finder or Explorer and using the Trash"],
      },
      port_scanner: {
        name: "Port scanner",
        text: "Which TCP ports are open on a computer, with the service of each one and CSV export.",
        shows: ["Networking with sockets", "Many parallel connections with progress", "Validating what the user types"],
      },
      investor: {
        name: "Stock investor (demo)",
        text: "Buy and sell shares of fictional companies with live simulated prices and watch your portfolio win or lose.",
        shows: ["Live data with a timer", "Price chart", "The portfolio saved between sessions"],
      },
      pos: {
        name: "Point of sale",
        text: "A POS in the style of Odoo's, with product pictures. Connect it to your Odoo with URL, user and password: it downloads the products and their prices and sends the orders to Sales.",
        shows: ["Connecting to Odoo and working offline", "Sales and pictures saved in SQLite", "Payment with change, receipt and daily summary"],
      },
      agenda: {
        name: "Agenda",
        text: "Contacts and appointments in tabs, with search, saved in a database.",
        shows: ["SQLite with nothing to install", "Tabs, tables and search", "Forms to add and edit"],
      },
      currency: {
        name: "Currency converter",
        text: "Convert between currencies with the real exchange rates of the European Central Bank.",
        shows: ["Calling an Internet API", "Answers without freezing the window", "Works offline with the latest data"],
      },
      file_renamer: {
        name: "File renamer",
        text: "Rename many files at once with rules, seeing the result before applying it.",
        shows: ["Regular expressions and numbering", "Live preview with conflicts marked", "Undo the last change"],
      },
    },
  },
};

export function demosText(lang: Lang) {
  return TEXT[lang];
}

const POINT_ICONS = [Blocks, Package, Code2];

/** Página de demos: utilidades hechas con el estudio, para macOS y Windows. */
export function Demos({ lang }: { lang: Lang }) {
  const t = contentOf(lang);
  const x = TEXT[lang];
  return (
    <>
      <SiteHeader lang={lang} t={t} alternates={PATHS.demos} />
      <main className="flex-1">
        <section className="mx-auto max-w-6xl px-4 pt-12 pb-10 sm:px-6 sm:pt-16">
          <p className="text-sm font-medium text-accent">{x.eyebrow}</p>
          <h1 className="mt-2 text-3xl font-semibold tracking-tight sm:text-4xl">{x.title}</h1>
          <p className="mt-4 max-w-3xl text-lg leading-relaxed text-muted text-pretty">{x.intro}</p>
          <ul className="mt-10 grid gap-6 sm:grid-cols-3">
            {x.points.map((p, i) => {
              const Icon = POINT_ICONS[i];
              return (
                <li key={p.title} className="flex gap-3">
                  <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-accent/12 text-accent">
                    <Icon className="size-5" aria-hidden />
                  </span>
                  <div>
                    <h2 className="font-medium">{p.title}</h2>
                    <p className="mt-1 text-sm leading-relaxed text-muted">{p.text}</p>
                  </div>
                </li>
              );
            })}
          </ul>
        </section>

        <section className="border-t border-line bg-surface">
          <ul className="mx-auto grid max-w-6xl gap-6 px-4 py-12 sm:px-6 md:grid-cols-2 lg:grid-cols-3">
            {DEMO_SEEDS.map((seed) => {
              const d = x.items[seed];
              return (
                <li
                  key={seed}
                  id={seed}
                  className="flex scroll-mt-24 flex-col overflow-hidden rounded-xl border border-line bg-canvas shadow-sm"
                >
                  <div className="relative aspect-[16/10] overflow-hidden border-b border-line bg-ide-panel">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={demoImage(seed, lang)}
                      alt={`${d.name}: ${d.text}`}
                      loading="lazy"
                      className="h-full w-full object-cover object-top"
                    />
                    <TechChip icon="python" label={x.tech} className="absolute top-3 left-3" />
                  </div>
                  <div className="flex flex-1 flex-col p-5">
                    <h2 className="text-lg font-semibold">{d.name}</h2>
                    <p className="mt-1 text-sm leading-relaxed text-muted">{d.text}</p>
                    <p className="mt-4 text-xs font-medium tracking-wide text-muted uppercase">{x.shows}</p>
                    <ul className="mt-1.5 flex-1 space-y-1 text-sm">
                      {d.shows.map((s) => (
                        <li key={s} className="flex gap-2">
                          <span className="mt-2 size-1.5 shrink-0 rounded-full bg-accent" aria-hidden />
                          {s}
                        </li>
                      ))}
                    </ul>
                    <DemoDownloads seed={seed} lang={lang} label={x.download} />
                  </div>
                </li>
              );
            })}
          </ul>
        </section>

        <section className="mx-auto grid max-w-6xl gap-8 px-4 py-12 sm:px-6 md:grid-cols-2">
          <div>
            <h2 className="text-xl font-semibold">{x.how.title}</h2>
            <h3 className="mt-4 font-medium">macOS</h3>
            <ol className="mt-1 list-decimal space-y-1 pl-5 text-sm text-muted">
              {x.how.macos.map((s) => (
                <li key={s}>{s}</li>
              ))}
            </ol>
            <h3 className="mt-4 font-medium">Windows</h3>
            <ol className="mt-1 list-decimal space-y-1 pl-5 text-sm text-muted">
              {x.how.windows.map((s) => (
                <li key={s}>{s}</li>
              ))}
            </ol>
          </div>
          <div className="rounded-xl border border-line bg-surface p-6">
            <p className="leading-relaxed">{x.studio}</p>
            <a href={DEMOS_RELEASE_URL} className="mt-4 inline-block text-sm text-accent underline-offset-2 hover:underline">
              {x.release} →
            </a>
          </div>
        </section>
      </main>
      <SiteFooter lang={lang} t={t} />
    </>
  );
}
