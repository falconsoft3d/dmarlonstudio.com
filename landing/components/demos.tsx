import { Blocks, Code2, Package } from "lucide-react";
import { DemoDownloads } from "@/components/demo-downloads";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { TechChip } from "@/components/tech-chip";
import { contentOf } from "@/content";
import { LiveDemo } from "@/components/live-demo";
import { PlatformIcon } from "@/components/platform-icon";
import type { TargetIcon } from "@/content/types";
import {
  apkUrl,
  demoPath,
  DEMO_SEEDS,
  DEMOS_RELEASE_URL,
  demoImage,
  liveUrl,
  MOBILE_SEEDS,
  WEB_SEEDS,
  type DemoSeed,
  type MobileSeed,
  type WebSeed,
} from "@/lib/demos";
import { PATHS, type Lang } from "@/lib/i18n";

type DemoText = { name: string; text: string; shows: string[] };

type Section = { title: string; intro: string };

type DemosText = {
  sections: { desktop: Section; mobile: Section; web: Section };
  how2: string;
  tryPhone: string;
  tryWeb: string;
  close: string;
  newTab: string;
  android: string;
  mobileNote: string;
  mobileItems: Record<MobileSeed, DemoText>;
  webItems: Record<WebSeed, DemoText>;
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
  items: Record<DemoSeed | "pascal_odoo", DemoText>;
};

const TEXT: Record<Lang, DemosText> = {
  es: {
    sections: {
      desktop: {
        title: "Escritorio",
        intro: "Doce aplicaciones para macOS y Windows. Descárguelas, ábralas y úselas: no necesitan instalar nada más.",
      },
      mobile: {
        title: "Móvil",
        intro: "Apps de Flutter hechas con el editor de pantallas. Pruébelas aquí mismo, dentro de un teléfono, o instálelas en Android.",
      },
      web: {
        title: "Web",
        intro: "La misma tienda, diseñada una vez y generada en tres tecnologías. Ábrala en el navegador: entre con demo@tienda.com y 1234.",
      },
    },
    how2: "Cómo funciona",
    tryPhone: "Probar aquí",
    tryWeb: "Abrir la web",
    close: "Cerrar",
    newTab: "Abrir en una pestaña nueva",
    android: "Android (APK)",
    mobileNote: "Para instalar el APK, permita en Android «instalar aplicaciones desconocidas». En iPhone se prueban desde el estudio (necesitan la firma de Apple para distribuirse).",
    mobileItems: {
      flutter_store: {
        name: "Tienda con login",
        text: "Entrar, buscar en el catálogo, ver un producto, llenar el carrito y pagar. Pruebe con demo@tienda.com y 1234.",
        shows: ["Pantallas diseñadas al estilo de FlutterFlow", "Login, navegación y estado de la app", "La misma app en Android, iPhone y la web"],
      },
      flutter_shipping: {
        name: "Envíos",
        text: "Los envíos por estado, el detalle con su seguimiento y el alta de uno nuevo.",
        shows: ["Listas, tarjetas e insignias", "Una pantalla de detalle que recibe datos", "Formularios con validación"],
      },
      flutter_todo: {
        name: "Tareas",
        text: "Tareas con filtros que se guardan en el teléfono (en la web, en el navegador).",
        shows: ["Guardar datos en el dispositivo", "Filtros y contadores en vivo", "Un paquete de pub (shared_preferences)"],
      },
    },
    webItems: {
      html_store: {
        name: "Tienda web (HTML)",
        text: "HTML, CSS y JavaScript, sin compilar ni instalar nada: se sube tal cual a cualquier hosting.",
        shows: ["Cero dependencias", "Rutas y estado en JavaScript", "Adaptable a escritorio y móvil"],
      },
      react_store: {
        name: "Tienda web (React)",
        text: "La misma tienda como web de React con Vite: archivos estáticos listos para publicar.",
        shows: ["Componentes de React generados", "Compilada con Vite", "La lógica en JavaScript, igual que en HTML"],
      },
      vue_store: {
        name: "Tienda web (Vue)",
        text: "La misma tienda con Vue: cada pantalla es un componente .vue.",
        shows: ["Componentes .vue con su plantilla", "Compilada con Vite", "Un diseño, tres tecnologías"],
      },
    },
    title: "Demos",
    eyebrow: "Hecho con DMarlon Studio",
    intro:
      "Aplicaciones de verdad hechas con DMarlon Studio: doce aplicaciones de escritorio para macOS y Windows, tres apps móviles y tres webs que puede probar aquí mismo. Todas se diseñaron arrastrando componentes y vienen como ejemplo en el estudio: ábralas allí y cámbielas.",
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
      mp3_player: {
        name: "Reproductor MP3",
        text: "Un reproductor al estilo de los clásicos: reloj digital, analizador de espectro, lista de reproducción y listas M3U. En macOS, para Apple Silicon.",
        shows: ["Una interfaz propia dibujada en lienzos", "Leer etiquetas ID3 y cabeceras MP3", "Un paquete de pip (pygame) para el sonido"],
      },
      train_monitor: {
        name: "Seguimiento de trenes",
        text: "Los trenes de Cercanías y Rodalies en directo con los datos abiertos de Renfe: avisa cuando dos trenes de la misma línea se acercan y dibuja la malla de circulación. Demo educativa: no es un sistema de seguridad.",
        shows: ["Datos públicos en directo (GTFS y GTFS-Realtime)", "Gráficos propios: malla de circulación y mapa", "Simulación cuando no hay conexión"],
      },
      pascal_odoo: {
        name: "Odoo sin conexión (Pascal)",
        text: "Un panel de ventas nativo para Odoo 8 a 20: clientes, productos y presupuestos que se trabajan sin conexión y se envían a Odoo al volver, sin duplicados.",
        shows: ["Una app nativa en Object Pascal (Lazarus)", "JSON-RPC con todas las versiones de Odoo", "Panel con indicadores y gráficos propios"],
      },
      file_renamer: {
        name: "Renombrar archivos",
        text: "Cambie el nombre de muchos archivos a la vez con reglas, viendo el resultado antes de aplicarlo.",
        shows: ["Expresiones regulares y numeración", "Vista previa en vivo con conflictos marcados", "Deshacer el último cambio"],
      },
    },
  },
  en: {
    sections: {
      desktop: {
        title: "Desktop",
        intro: "Twelve apps for macOS and Windows. Download them, open them and use them: nothing else to install.",
      },
      mobile: {
        title: "Mobile",
        intro: "Flutter apps made with the screen editor. Try them right here, inside a phone, or install them on Android.",
      },
      web: {
        title: "Web",
        intro: "The same shop, designed once and generated in three technologies. Open it in the browser: sign in with demo@tienda.com and 1234.",
      },
    },
    how2: "How it works",
    tryPhone: "Try it here",
    tryWeb: "Open the website",
    close: "Close",
    newTab: "Open in a new tab",
    android: "Android (APK)",
    mobileNote: "To install the APK, allow “install unknown apps” on Android. On iPhone they are tried from the studio (distributing them needs Apple's signature).",
    mobileItems: {
      flutter_store: {
        name: "Shop with login",
        text: "Sign in, search the catalog, open a product, fill the cart and pay. Try demo@tienda.com and 1234.",
        shows: ["Screens designed FlutterFlow-style", "Login, navigation and app state", "The same app on Android, iPhone and the web"],
      },
      flutter_shipping: {
        name: "Shipments",
        text: "Shipments by status, the detail with its tracking and adding a new one.",
        shows: ["Lists, cards and badges", "A detail screen that receives data", "Forms with validation"],
      },
      flutter_todo: {
        name: "Tasks",
        text: "Tasks with filters saved on the phone (on the web, in the browser).",
        shows: ["Saving data on the device", "Live filters and counters", "A pub package (shared_preferences)"],
      },
    },
    webItems: {
      html_store: {
        name: "Web shop (HTML)",
        text: "HTML, CSS and JavaScript with nothing to build or install: upload it as is to any hosting.",
        shows: ["Zero dependencies", "Routes and state in JavaScript", "Responsive on desktop and mobile"],
      },
      react_store: {
        name: "Web shop (React)",
        text: "The same shop as a React website with Vite: static files ready to publish.",
        shows: ["Generated React components", "Built with Vite", "The logic in JavaScript, as in HTML"],
      },
      vue_store: {
        name: "Web shop (Vue)",
        text: "The same shop with Vue: each screen is a .vue component.",
        shows: [".vue components with their template", "Built with Vite", "One design, three technologies"],
      },
    },
    title: "Demos",
    eyebrow: "Made with DMarlon Studio",
    intro:
      "Real apps made with DMarlon Studio: twelve desktop apps for macOS and Windows, three mobile apps and three websites you can try right here. They were all designed by dragging components and come as examples in the studio: open them there and change them.",
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
      mp3_player: {
        name: "MP3 player",
        text: "A player in the style of the classics: digital clock, spectrum analyzer, playlist and M3U lists. On macOS, for Apple Silicon.",
        shows: ["A custom interface drawn on canvases", "Reading ID3 tags and MP3 headers", "A pip package (pygame) for sound"],
      },
      train_monitor: {
        name: "Train tracking",
        text: "Spain's commuter trains live with Renfe's open data: it warns when two trains on the same line get close and draws the train graph. An educational demo: not a safety system.",
        shows: ["Live public data (GTFS and GTFS-Realtime)", "Custom charts: train graph and map", "A simulation when there is no connection"],
      },
      pascal_odoo: {
        name: "Offline Odoo (Pascal)",
        text: "A native sales cockpit for Odoo 8 to 20: customers, products and quotations you work on offline and send to Odoo when you are back, without duplicates.",
        shows: ["A native app in Object Pascal (Lazarus)", "JSON-RPC with every Odoo version", "A dashboard with KPIs and custom charts"],
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

export type DemoKind = "desktop" | "mobile" | "web";

/** Todas las demos, en el orden de la página. */
export const ALL_DEMOS: { seed: string; kind: DemoKind }[] = [
  ...DEMO_SEEDS.map((seed) => ({ seed, kind: "desktop" as const })),
  ...MOBILE_SEEDS.map((seed) => ({ seed, kind: "mobile" as const })),
  ...WEB_SEEDS.map((seed) => ({ seed, kind: "web" as const })),
];

/** Lo que la página de una demo necesita de ella: textos y tecnología. */
export function demoInfo(lang: Lang, seed: string) {
  const x = TEXT[lang];
  const entry = ALL_DEMOS.find((d) => d.seed === seed);
  if (!entry) return null;
  const { kind } = entry;
  const d =
    kind === "desktop"
      ? x.items[seed as DemoSeed]
      : kind === "mobile"
        ? x.mobileItems[seed as MobileSeed]
        : x.webItems[seed as WebSeed];
  const tech: { icon: TargetIcon; label: string } =
    kind === "mobile"
      ? { icon: "flutter", label: "Flutter" }
      : kind === "web"
        ? WEB_TECH[seed as WebSeed]
        : seed === "pascal_odoo"
          ? { icon: "lazarus", label: "Pascal · Lazarus" }
          : { icon: "python", label: x.tech };
  return { kind, d, tech, x };
}

const POINT_ICONS = [Blocks, Package, Code2];

const WEB_TECH: Record<WebSeed, { icon: TargetIcon; label: string }> = {
  html_store: { icon: "html", label: "HTML · CSS · JS" },
  react_store: { icon: "react", label: "React · Vite" },
  vue_store: { icon: "vue", label: "Vue · Vite" },
};

/** Una sección de demos (escritorio, móvil o web) con su rejilla de tarjetas. */
function DemoSection({
  id,
  section,
  note,
  alt = false,
  children,
}: {
  id: string;
  section: { title: string; intro: string };
  note?: string;
  alt?: boolean;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className={`scroll-mt-28 border-b border-line ${alt ? "bg-surface" : ""}`}>
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
        <h2 className="text-2xl font-semibold tracking-tight">{section.title}</h2>
        <p className="mt-2 max-w-3xl text-muted text-pretty">{section.intro}</p>
        <ul className="mt-8 grid gap-6 md:grid-cols-2 lg:grid-cols-3">{children}</ul>
        {note && <p className="mt-6 max-w-3xl text-sm text-muted">{note}</p>}
      </div>
    </section>
  );
}

/** Tarjeta de una demo: captura con su tecnología, qué hace, qué demuestra y sus botones. */
function DemoCard({
  id,
  href,
  how,
  image,
  icon,
  tech,
  d,
  shows,
  children,
}: {
  id: string;
  href: string;
  how: string;
  image: string;
  icon: TargetIcon;
  tech: string;
  d: DemoText;
  shows: string;
  children: React.ReactNode;
}) {
  return (
    <li id={id} className="flex scroll-mt-28 flex-col overflow-hidden rounded-xl border border-line bg-canvas shadow-sm">
      <a href={href} className="group relative block aspect-[16/10] overflow-hidden border-b border-line bg-ide-panel">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={image}
          alt={`${d.name}: ${d.text}`}
          loading="lazy"
          className="h-full w-full object-cover object-top transition-transform duration-300 group-hover:scale-[1.02]"
        />
        <TechChip icon={icon} label={tech} className="absolute top-3 left-3" />
      </a>
      <div className="flex flex-1 flex-col p-5">
        <h3 className="text-lg font-semibold">
          <a href={href} className="hover:text-accent">
            {d.name}
          </a>
        </h3>
        <p className="mt-1 text-sm leading-relaxed text-muted">{d.text}</p>
        <p className="mt-4 text-xs font-medium tracking-wide text-muted uppercase">{shows}</p>
        <ul className="mt-1.5 flex-1 space-y-1 text-sm">
          {d.shows.map((s) => (
            <li key={s} className="flex gap-2">
              <span className="mt-2 size-1.5 shrink-0 rounded-full bg-accent" aria-hidden />
              {s}
            </li>
          ))}
        </ul>
        {children}
        <a href={href} className="mt-3 inline-flex items-center gap-1 self-start text-sm font-medium text-accent hover:underline">
          {how} →
        </a>
      </div>
    </li>
  );
}

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

        <nav aria-label={x.title} className="sticky top-14 z-30 border-y border-line bg-canvas/90 backdrop-blur">
          <div className="mx-auto flex max-w-6xl gap-1 overflow-x-auto px-4 py-2 sm:px-6">
            {(["desktop", "mobile", "web"] as const).map((k) => (
              <a
                key={k}
                href={`#${k}`}
                className="rounded-md px-3 py-1.5 text-sm font-medium text-muted transition-colors hover:bg-soft hover:text-ink"
              >
                {x.sections[k].title}
              </a>
            ))}
          </div>
        </nav>

        <DemoSection id="desktop" section={x.sections.desktop} alt>
          {DEMO_SEEDS.map((seed) => (
            <DemoCard
              key={seed}
              id={seed}
              href={demoPath(lang, seed)}
              how={x.how2}
              image={demoImage(seed, lang)}
              icon={(seed as string) === "pascal_odoo" ? "lazarus" : "python"}
              tech={(seed as string) === "pascal_odoo" ? "Pascal · Lazarus" : x.tech}
              d={x.items[seed]}
              shows={x.shows}
            >
              <DemoDownloads seed={seed} lang={lang} label={x.download} />
            </DemoCard>
          ))}
        </DemoSection>

        <DemoSection id="mobile" section={x.sections.mobile} note={x.mobileNote}>
          {MOBILE_SEEDS.map((seed) => {
            const d = x.mobileItems[seed];
            return (
              <DemoCard key={seed} id={seed} href={demoPath(lang, seed)} how={x.how2} image={demoImage(seed, lang)} icon="flutter" tech="Flutter" d={d} shows={x.shows}>
                <div className="mt-5 grid grid-cols-2 gap-2">
                  <LiveDemo url={liveUrl(seed, lang)} title={d.name} label={x.tryPhone} close={x.close} newTab={x.newTab} phone />
                  <a
                    href={apkUrl(seed, lang)}
                    className="inline-flex items-center justify-center gap-1.5 rounded-md border border-line bg-soft px-3 py-2 text-sm font-medium text-ink transition-colors hover:border-accent hover:text-accent"
                  >
                    <PlatformIcon platform="android" className="size-4" />
                    {x.android}
                  </a>
                </div>
              </DemoCard>
            );
          })}
        </DemoSection>

        <DemoSection id="web" section={x.sections.web} alt>
          {WEB_SEEDS.map((seed) => {
            const d = x.webItems[seed];
            const tech = WEB_TECH[seed];
            return (
              <DemoCard key={seed} id={seed} href={demoPath(lang, seed)} how={x.how2} image={demoImage(seed, lang)} icon={tech.icon} tech={tech.label} d={d} shows={x.shows}>
                <div className="mt-5 grid">
                  <LiveDemo url={liveUrl(seed, lang)} title={d.name} label={x.tryWeb} close={x.close} newTab={x.newTab} phone={false} />
                </div>
              </DemoCard>
            );
          })}
        </DemoSection>

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
