import type { Content } from "./types";

/** Textos de la portada en español (/). La traducción está en content/en.ts. */
export const es: Content = {
  meta: {
    title: "DMarlon Studio · IDE visual para Python",
    description:
      "IDE visual de escritorio: diseñe ventanas arrastrando componentes, escriba los eventos en Python y ejecútelas. Hoy tkinter y Flask; próximamente Electron.",
  },
  header: {
    sectionsLabel: "Secciones",
    nav: [
      { href: "#disenador", label: "Diseñador" },
      { href: "#editor", label: "Editor" },
      { href: "#herramientas", label: "Herramientas" },
      { href: "#ia", label: "IA" },
      { href: "#hoja-de-ruta", label: "Hoja de ruta" },
    ],
    download: "Descargar",
    languageLabel: "Idioma",
  },
  theme: {
    system: "Tema: el del sistema",
    dark: "Tema: oscuro",
    light: "Tema: claro",
    change: "Cambiar tema",
  },
  hero: {
    eyebrow: "IDE visual multi-entorno",
    title: "Diseñe ventanas arrastrando. Prográmelas en Python.",
    text: "DMarlon Studio es un IDE de escritorio: arrastre componentes a un formulario, ajuste sus propiedades en el inspector de objetos, escriba el código de cada evento en Python y ejecútelo con F9. Hoy genera aplicaciones de escritorio con tkinter y aplicaciones web con Flask; Electron es el siguiente entorno.",
    primary: "Descargar",
    secondary: "Ver qué incluye",
    targetsLabel: "Entornos",
    targets: ["tkinter", "Flask", "Electron (en camino)"],
  },
  sections: [
    {
      id: "disenador",
      eyebrow: "Diseñador visual",
      title: "Formularios con paleta, inspector y eventos",
      intro:
        "El diseñador genera un archivo de Python legible a partir del diseño y de su código. Usted solo escribe los manejadores de los eventos; el resto lo mantiene el estudio.",
      features: [
        { title: "Paleta de componentes", text: "Etiquetas, botones, entradas, casillas, listas, combos, tablas, marcos, conexiones de datos y más: se arrastran al formulario o se añaden con doble clic." },
        { title: "Inspector de objetos", text: "Propiedades y eventos del componente seleccionado o de la ventana, con colores, fuentes, referencias entre componentes y validación de nombres." },
        { title: "Eventos en Python", text: "Doble clic en un componente crea su método (Button1_click) y lo abre en el código. Renombrar un componente renombra sus métodos." },
        { title: "Rejilla y alineación", text: "Ajuste a la rejilla, alinear a izquierda, centro o derecha, igualar ancho y alto, traer al frente y mover con las flechas." },
        { title: "Deshacer, copiar y pegar", text: "Cada cambio se puede deshacer; los componentes se copian entre ventanas con sus hijos." },
        { title: "F9 ejecuta, F12 alterna", text: "F9 lanza la ventana con su Python local y muestra la salida; F12 cambia entre diseño y código. También se exporta el .py." },
      ],
    },
    {
      id: "editor",
      eyebrow: "Editor de código",
      title: "Un editor al estilo de VS Code, dentro del estudio",
      intro: "Para el resto del proyecto, y para cualquier carpeta de su equipo.",
      features: [
        { title: "Explorador y pestañas", text: "Árbol de archivos con crear, renombrar y borrar; pestañas con resaltado de sintaxis para decenas de lenguajes y números de línea." },
        { title: "Buscar y reemplazar", text: "En el archivo abierto y en todos los archivos de la carpeta." },
        { title: "Terminal", text: "Una terminal integrada en la carpeta de trabajo, sin salir del estudio." },
        { title: "Git y GitHub", text: "Cambios, confirmar, subir y traer; clonar repositorios de su cuenta de GitHub." },
      ],
    },
    {
      id: "herramientas",
      eyebrow: "Herramientas",
      title: "Lo que necesita alrededor del código",
      intro:
        "Las conexiones se guardan en el estudio, no en el código que genera: las contraseñas llegan a su aplicación por el entorno al ejecutarla.",
      features: [
        { title: "Bases de datos", text: "Gestor para SQLite, PostgreSQL, MySQL / MariaDB y MongoDB: esquema, consultas y resultados." },
        { title: "Cliente de API", text: "Peticiones HTTP al estilo de Postman, con colecciones, historial y variables de entorno {{como_esta}}." },
        { title: "FTP", text: "Navegue, suba y descargue archivos de sus servidores FTP." },
        { title: "Diagramas", text: "Diagramas de flujo y de entidad-relación, con exportación a PDF." },
      ],
    },
    {
      id: "ia",
      eyebrow: "Inteligencia artificial",
      title: "Pídale una ventana, o el código de un evento",
      intro: "La IA propone; usted ve la propuesta y decide si la aplica. Funciona con su propia clave.",
      features: [
        { title: "Diseña ventanas", text: "Describa la ventana (o adjunte una imagen) y la IA devuelve el diseño y el código, validados contra el catálogo de componentes." },
        { title: "Escribe manejadores", text: "Seleccione un componente y pida lo que debe hacer su evento: solo cambia ese método." },
        { title: "Varios proveedores", text: "OpenAI, Anthropic y APIs compatibles con OpenAI. La clave se guarda solo en su equipo." },
      ],
    },
  ],
  roadmap: {
    id: "hoja-de-ruta",
    eyebrow: "Hoja de ruta",
    title: "Un diseño, varios entornos",
    status: { ready: "Disponible", next: "En camino", later: "Más adelante" },
    steps: [
      { name: "tkinter", status: "ready", text: "Ventanas de escritorio de Python con su propia ventana del sistema." },
      { name: "Flask", status: "ready", text: "El mismo diseñador genera aplicaciones web que corren en un servidor local." },
      { name: "Electron", status: "next", text: "Aplicaciones de escritorio con tecnologías web a partir del mismo diseño." },
      { name: "Más entornos", status: "later", text: "Un diseño, varios destinos: el objetivo es construir para múltiples entornos." },
    ],
  },
  downloads: {
    id: "descargas",
    eyebrow: "Descargas",
    title: "Descargue DMarlon Studio",
    intro: "Gratis para macOS y Windows. Se compila automáticamente desde el repositorio con cada versión.",
    yours: "Su sistema",
    download: "Descargar",
    soon: "Próximamente",
    notes: {
      macos: {
        requirements: "macOS 10.15 o superior · Apple Silicon e Intel",
        steps: [
          "Descomprima el zip y mueva «DMarlon Studio» a Aplicaciones.",
          "La primera vez, haga clic derecho sobre la app → Abrir: la app aún no está firmada.",
          "Confirme «Abrir» en el aviso de desarrollador no identificado.",
        ],
      },
      windows: {
        requirements: "Windows 10 u 11 de 64 bits",
        steps: [
          "Descomprima la carpeta completa (por ejemplo, en el Escritorio).",
          "Abra DMarlonStudio.exe.",
          "Si aparece «Windows protegió su PC», pulse «Más información» → «Ejecutar de todas formas».",
        ],
      },
      linux: {
        requirements: "Próximamente",
        steps: [
          "El paquete para Linux está en camino. Mientras tanto, puede compilarlo desde el código fuente con Flutter.",
        ],
      },
    },
    requirement: {
      before: "Requisito para ejecutar lo que diseñe:",
      python: "Python 3 con tkinter",
      middle: "para las ventanas de escritorio y",
      flask: "Flask",
      afterFlask: "para las aplicaciones web",
      after: "El estudio detecta el Python instalado y le dice qué falta. Versiones anteriores y notas en",
      releases: "GitHub Releases",
    },
  },
  footer: {
    changelogTitle: "Ver los cambios de esta versión",
    linksLabel: "Enlaces",
    versions: "Versiones",
    download: "Descargar",
  },
  mock: {
    save: "Guardar",
    properties: "Propiedades",
    events: "Eventos",
    design: "Diseño",
    code: "Código",
    generated: "Python generado",
    window: "Agenda",
    name: "Nombre",
    email: "Correo",
    phone: "Teléfono",
  },
  notFound: { title: "Esta página no existe", home: "Ir al inicio" },
};
