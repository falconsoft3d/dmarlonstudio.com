/**
 * Textos de la portada en español. Para /en, cree content/en.ts con la
 * misma forma (tipo Content) y páselo a la página.
 */
export type Feature = { title: string; text: string };
export type Section = { id: string; eyebrow: string; title: string; intro: string; features: Feature[] };
export type Step = { name: string; status: "listo" | "en camino" | "idea"; text: string };

export const hero = {
  eyebrow: "IDE visual multi-entorno",
  title: "Diseñe ventanas como en Delphi. Prográmelas en Python.",
  text: "DMarlon Studio es un IDE de escritorio: arrastre componentes a un formulario, ajuste sus propiedades en el inspector de objetos, escriba el código de cada evento en Python y ejecútelo con F9. Hoy genera aplicaciones de escritorio con tkinter y aplicaciones web con Flask; Electron es el siguiente entorno.",
  primary: "Descargar",
  secondary: "Ver qué incluye",
  targets: ["tkinter", "Flask", "Electron (en camino)"],
};

export const sections: Section[] = [
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
    intro: "Las conexiones se guardan en el estudio, no en el código que genera: las contraseñas llegan a su aplicación por el entorno al ejecutarla.",
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
];

export const roadmap: Step[] = [
  { name: "tkinter", status: "listo", text: "Ventanas de escritorio de Python con su propia ventana del sistema." },
  { name: "Flask", status: "listo", text: "El mismo diseñador genera aplicaciones web que corren en un servidor local." },
  { name: "Electron", status: "en camino", text: "Aplicaciones de escritorio con tecnologías web a partir del mismo diseño." },
  { name: "Más entornos", status: "idea", text: "Un diseño, varios destinos: el objetivo es construir para múltiples entornos." },
];
