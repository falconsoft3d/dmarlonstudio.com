import type { Lang } from "@/lib/i18n";

type Card = { title: string; text: string };

/** Textos del dossier (presentación del producto), por idioma. */
export type DossierText = {
  meta: { title: string; description: string };
  download: string;
  back: string;
  cover: { eyebrow: string; title: string; text: string; version: string };
  what: { eyebrow: string; title: string; text: string[]; audienceTitle: string; audience: Card[] };
  modules: { eyebrow: string; title: string; intro: string; items: Card[] };
  targets: {
    eyebrow: string;
    title: string;
    intro: string;
    head: [string, string, string];
    rows: [string, string, string][];
    note: string;
  };
  ai: { eyebrow: string; title: string; intro: string; items: Card[] };
  start: {
    eyebrow: string;
    title: string;
    steps: Card[];
    requirementsTitle: string;
    requirements: string[];
    contactTitle: string;
    web: string;
    repo: string;
    manual: string;
  };
};

const es: DossierText = {
  meta: {
    title: "Dossier",
    description:
      "Presentación de DMarlon Studio: qué es, para quién, módulos, destinos, inteligencia artificial y cómo empezar.",
  },
  download: "Descargar el dossier en PDF",
  back: "Volver al inicio",
  cover: {
    eyebrow: "Dossier de producto",
    title: "Diseñe ventanas arrastrando. Prográmelas en Python.",
    text: "DMarlon Studio es un IDE visual de escritorio para crear aplicaciones con interfaz gráfica: escritorio con tkinter y web con Flask.",
    version: "Versión",
  },
  what: {
    eyebrow: "Qué es",
    title: "Un estudio completo para aplicaciones con interfaz",
    text: [
      "Las ventanas se dibujan con una paleta de componentes y un inspector de propiedades y eventos. El código de cada evento se escribe en Python y el estudio genera un archivo legible que se ejecuta con F9 o se exporta.",
      "Alrededor del diseñador están las herramientas del día a día: un editor de código con git y terminal, un gestor de bases de datos, un cliente de API, FTP y diagramas. La inteligencia artificial, con Claude por defecto, ayuda a diseñar y a programar.",
      "Funciona en macOS y Windows, guarda los proyectos como carpetas normales que se pueden versionar con git y no necesita cuenta ni servidor.",
    ],
    audienceTitle: "Para quién",
    audience: [
      { title: "Desarrolladores de Python", text: "Que necesitan una interfaz para un script o una herramienta sin pelearse con la colocación de los widgets." },
      { title: "Equipos con herramientas internas", text: "Formularios y tablas sobre sus bases de datos (SQLite, PostgreSQL, MySQL) en poco tiempo." },
      { title: "Docentes y estudiantes", text: "Programación orientada a eventos con un resultado visible desde el primer minuto." },
      { title: "Quien prototipa", text: "Una ventana de escritorio o una página web con el mismo diseño y el mismo código." },
    ],
  },
  modules: {
    eyebrow: "Módulos",
    title: "Todo en una sola aplicación",
    intro: "Siete módulos en una barra lateral. Cada uno conserva lo que no se ha guardado al pasar a otro.",
    items: [
      { title: "Diseñador", text: "Paleta de componentes, inspector, eventos, rejilla, alinear, deshacer, Python generado y ejecución con F9." },
      { title: "Editor", text: "Explorador, pestañas, buscar y reemplazar, búsqueda en archivos, terminal y git con GitHub." },
      { title: "Bases de datos", text: "SQLite, PostgreSQL, MySQL/MariaDB y MongoDB: tablas, consultas y exportación a CSV." },
      { title: "API", text: "Peticiones HTTP con colecciones, variables de entorno, historial y copia como curl." },
      { title: "FTP", text: "Servidores FTP, FTPES y FTPS: navegar, subir, descargar y organizar archivos." },
      { title: "Diagramas", text: "De flujo y de base de datos, desde una conexión o con IA, exportables a PDF." },
    ],
  },
  targets: {
    eyebrow: "Destinos",
    title: "Un diseño, varios entornos",
    intro: "El diseño se guarda una vez y el estudio genera el código del entorno elegido al crear el proyecto.",
    head: ["Destino", "Tecnología", "Estado"],
    rows: [
      ["Escritorio", "Python + tkinter", "Disponible"],
      ["Web", "Python + Flask", "Disponible"],
      ["Escritorio", "JavaScript + Electron + React", "Disponible"],
      ["Extensión", "JavaScript + Chrome (Manifest V3)", "Disponible"],
      ["Web", "JavaScript + Next.js", "Disponible"],
      ["Escritorio nativo", "C++ + FLTK", "Disponible"],
      ["Escritorio nativo", "Object Pascal + Lazarus (LCL)", "Disponible"],
    ],
    note: "Lo generado funciona sin el estudio: el .py con Python 3, Electron y Next.js con npm, la extensión en Chrome, C++ con make y Pascal con lazbuild o el IDE de Lazarus.",
  },
  ai: {
    eyebrow: "Inteligencia artificial",
    title: "Claude, dentro del flujo de trabajo",
    intro: "La IA propone; usted revisa y aplica. Todo se puede deshacer.",
    items: [
      { title: "Chat con Claude Code", text: "A la derecha del Diseñador: Claude Code edita el diseño y el código del proyecto con la sesión del equipo, sin clave de API." },
      { title: "Claude implementa", text: "En el Editor: Claude explora la carpeta y propone cambios en varios archivos, con su diff, antes de escribir nada." },
      { title: "Pedir a la IA", text: "Diseña una ventana nueva (también desde un boceto), cambia la actual o escribe el código de un evento." },
      { title: "Su proveedor", text: "Claude por defecto, y también OpenAI, Gemini, Mistral, Ollama y otras API compatibles." },
    ],
  },
  start: {
    eyebrow: "Cómo empezar",
    title: "De la descarga a la primera ventana",
    steps: [
      { title: "1. Descargue", text: "El zip de macOS o de Windows desde dmarlonstudio.com." },
      { title: "2. Prepare Python", text: "Python 3 con tkinter; para la web, Flask." },
      { title: "3. Abra un ejemplo", text: "Calculadora, tareas, cronómetro, ficha de cliente… y pulse F9." },
      { title: "4. Cree el suyo", text: "Nuevo proyecto, arrastre componentes y programe los eventos." },
    ],
    requirementsTitle: "Requisitos",
    requirements: [
      "macOS 10.15 o posterior, o Windows 10/11 de 64 bits.",
      "Python 3 con tkinter (python.org o Homebrew).",
      "Opcional: git, Flask, Claude Code y una clave de API de IA.",
    ],
    contactTitle: "Contacto",
    web: "Web",
    repo: "Código y versiones",
    manual: "Manual",
  },
};

const en: DossierText = {
  meta: {
    title: "Dossier",
    description:
      "DMarlon Studio at a glance: what it is, who it is for, modules, targets, artificial intelligence and how to start.",
  },
  download: "Download the PDF dossier",
  back: "Back to home",
  cover: {
    eyebrow: "Product dossier",
    title: "Design windows by dragging. Program them in Python.",
    text: "DMarlon Studio is a visual desktop IDE for building apps with a graphical interface: desktop with tkinter and web with Flask.",
    version: "Version",
  },
  what: {
    eyebrow: "What it is",
    title: "A complete studio for apps with an interface",
    text: [
      "Windows are drawn with a component palette and an inspector for properties and events. Each event's code is written in Python and the studio generates a readable file that runs with F9 or can be exported.",
      "Around the designer are the everyday tools: a code editor with git and a terminal, a database manager, an API client, FTP and diagrams. Artificial intelligence, with Claude by default, helps you design and code.",
      "It runs on macOS and Windows, keeps projects as plain folders you can version with git, and needs no account or server.",
    ],
    audienceTitle: "Who it is for",
    audience: [
      { title: "Python developers", text: "Who need an interface for a script or a tool without fighting widget layout." },
      { title: "Teams with internal tools", text: "Forms and tables on top of their databases (SQLite, PostgreSQL, MySQL) in little time." },
      { title: "Teachers and students", text: "Event-driven programming with a visible result from the first minute." },
      { title: "Prototypers", text: "A desktop window or a web page with the same design and the same code." },
    ],
  },
  modules: {
    eyebrow: "Modules",
    title: "Everything in one application",
    intro: "Seven modules in a side bar. Each one keeps anything unsaved when you move to another.",
    items: [
      { title: "Designer", text: "Component palette, inspector, events, grid, alignment, undo, generated Python and running with F9." },
      { title: "Editor", text: "Explorer, tabs, find and replace, search in files, terminal and git with GitHub." },
      { title: "Databases", text: "SQLite, PostgreSQL, MySQL/MariaDB and MongoDB: tables, queries and CSV export." },
      { title: "API", text: "HTTP requests with collections, environment variables, history and copy as curl." },
      { title: "FTP", text: "FTP, FTPES and FTPS servers: browse, upload, download and organize files." },
      { title: "Diagrams", text: "Flowcharts and database diagrams, from a connection or with AI, exportable to PDF." },
    ],
  },
  targets: {
    eyebrow: "Targets",
    title: "One design, several environments",
    intro: "The design is saved once and the studio generates the code for the environment chosen when the project is created.",
    head: ["Target", "Technology", "Status"],
    rows: [
      ["Desktop", "Python + tkinter", "Available"],
      ["Web", "Python + Flask", "Available"],
      ["Desktop", "JavaScript + Electron + React", "Available"],
      ["Extension", "JavaScript + Chrome (Manifest V3)", "Available"],
      ["Web", "JavaScript + Next.js", "Available"],
      ["Native desktop", "C++ + FLTK", "Available"],
      ["Native desktop", "Object Pascal + Lazarus (LCL)", "Available"],
    ],
    note: "The output runs without the studio: the .py with Python 3, Electron and Next.js with npm, the extension in Chrome, C++ with make and Pascal with lazbuild or the Lazarus IDE.",
  },
  ai: {
    eyebrow: "Artificial intelligence",
    title: "Claude, inside the workflow",
    intro: "The AI proposes; you review and apply. Everything can be undone.",
    items: [
      { title: "Chat with Claude Code", text: "To the right of the Designer: Claude Code edits the project's design and code with the computer's session, no API key needed." },
      { title: "Claude: implement", text: "In the Editor: Claude explores the folder and proposes changes to several files, with their diff, before writing anything." },
      { title: "Ask the AI", text: "Designs a new window (also from a sketch), changes the current one or writes an event's code." },
      { title: "Your provider", text: "Claude by default, and also OpenAI, Gemini, Mistral, Ollama and other compatible APIs." },
    ],
  },
  start: {
    eyebrow: "How to start",
    title: "From download to your first window",
    steps: [
      { title: "1. Download", text: "The macOS or Windows zip from dmarlonstudio.com." },
      { title: "2. Get Python ready", text: "Python 3 with tkinter; Flask for the web." },
      { title: "3. Open an example", text: "Calculator, tasks, stopwatch, customer form… and press F9." },
      { title: "4. Build your own", text: "New project, drag components and program the events." },
    ],
    requirementsTitle: "Requirements",
    requirements: [
      "macOS 10.15 or later, or 64-bit Windows 10/11.",
      "Python 3 with tkinter (python.org or Homebrew).",
      "Optional: git, Flask, Claude Code and an AI API key.",
    ],
    contactTitle: "Contact",
    web: "Website",
    repo: "Code and releases",
    manual: "Manual",
  },
};

export const dossierOf = (lang: Lang): DossierText => (lang === "en" ? en : es);
