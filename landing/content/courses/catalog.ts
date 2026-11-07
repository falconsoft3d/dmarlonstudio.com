import type { Lang } from "@/lib/i18n";

/**
 * Los cursos: un lenguaje de programación de los que usa DMarlon Studio, con
 * un nivel básico y uno avanzado de 20 lecciones cada uno.
 *
 * Las lecciones están en content/courses/<lenguaje>/<nivel>/<NN>-<slug>/
 * (main.<ext>, lesson.json y, si lee del teclado, input.txt) y
 * scripts/build-courses.mjs las ejecuta de verdad, guarda su salida y dibuja
 * su imagen en content/courses/data/<lenguaje>.json y public/courses/.
 */

export const LEVELS = ["basic", "advanced"] as const;
export type Level = (typeof LEVELS)[number];

/** Nivel en la ruta de cada idioma. */
export const LEVEL_SLUG: Record<Level, Record<Lang, string>> = {
  basic: { es: "basico", en: "basic" },
  advanced: { es: "avanzado", en: "advanced" },
};

export const LEVEL_NAME: Record<Level, Record<Lang, string>> = {
  basic: { es: "Básico", en: "Basic" },
  advanced: { es: "Avanzado", en: "Advanced" },
};

export type CourseInfo = {
  /** En la ruta y en content/courses/<id>. */
  id: string;
  name: string;
  /** Extensión del archivo de cada ejemplo. */
  ext: string;
  /** Lenguaje para el resaltado (Shiki). */
  shiki: string;
  /** Icono de simple-icons (si tiene). */
  icon?: string;
  /** Color de la marca del lenguaje. */
  color: string;
  /** La orden con la que se ejecuta cada ejemplo (se ve en la imagen). */
  command: string;
  /** Abre ventanas: la imagen lleva su captura y la salida puede estar vacía. */
  gui?: boolean;
  /** Base de datos: el tipo de conexión del módulo Bases de datos del
   * estudio. Cada lección es un script y su salida, las rejillas. */
  db?: "sqlite" | "postgres" | "mysql" | "mongodb" | "falcon" | "firebase";
  /** Los datos del curso (la tienda de ejemplo), para descargarlos. */
  seed?: string;
  /** Una línea: para qué sirve el lenguaje. */
  tagline: Record<Lang, string>;
  /** Cómo se usa en DMarlon Studio (destinos donde se escribe). */
  studio: Record<Lang, string>;
  /** Cómo probar un ejemplo en DMarlon Studio, paso a paso. */
  steps: Record<Lang, string[]>;
};

const consoleSteps = (language: string, file: string): Record<Lang, string[]> => ({
  es: [
    "Abra DMarlon Studio y pulse **Nuevo proyecto**.",
    `Elija el destino **Consola**, el lenguaje **${language}** y póngale un nombre.`,
    `Copie el código de la lección en \`${file}\` (pestaña **Código**).`,
    "Pulse **Ejecutar** (F9): la salida aparece en la consola del estudio, igual que en la imagen.",
  ],
  en: [
    "Open DMarlon Studio and click **New project**.",
    `Choose the **Console** target, the **${language}** language and give it a name.`,
    `Paste the lesson's code into \`${file}\` (**Code** tab).`,
    "Click **Run** (F9): the output shows in the studio console, just like in the picture.",
  ],
});

/** Probar una lección de base de datos: la conexión, los datos y el script. */
const dbSteps = (conn: Record<Lang, string>, seed: string): Record<Lang, string[]> => ({
  es: [
    "Abra DMarlon Studio y entre en el módulo **Bases de datos**.",
    conn.es,
    `Cargue una vez los datos del curso (\`${seed}\`, abajo): péguelos en el editor y pulse **Ejecutar** (⌘↵). Vuelva a ejecutarlos para empezar de cero.`,
    "Pegue el script de la lección y pulse **Ejecutar**: cada consulta deja su resultado en una pestaña, como en la imagen. Si selecciona una parte, solo se ejecuta esa.",
  ],
  en: [
    "Open DMarlon Studio and go to the **Databases** module.",
    conn.en,
    `Load the course data once (\`${seed}\`, below): paste it into the editor and click **Run** (⌘↵). Run it again to start from scratch.`,
    "Paste the lesson's script and click **Run**: each query leaves its result in a tab, as in the picture. If you select part of it, only that part runs.",
  ],
});

export const COURSES: CourseInfo[] = [
  {
    id: "python",
    name: "Python",
    ext: "py",
    shiki: "python",
    icon: "python",
    color: "#3776AB",
    command: "python3 main.py",
    tagline: {
      es: "El lenguaje más fácil para empezar: scripts, datos, automatización y aplicaciones de escritorio.",
      en: "The easiest language to start with: scripts, data, automation and desktop apps.",
    },
    studio: {
      es: "En DMarlon Studio, Python es el lenguaje de las aplicaciones de escritorio (tkinter), de las webs con Flask y de la consola: diseña la ventana y el estudio escribe el código Python.",
      en: "In DMarlon Studio, Python powers desktop apps (tkinter), Flask websites and the console: design the window and the studio writes the Python code.",
    },
    steps: consoleSteps("Python", "main.py"),
  },
  {
    id: "tkinter",
    name: "tkinter",
    ext: "py",
    shiki: "python",
    icon: "python",
    color: "#2E6DA4",
    command: "python3 main.py",
    gui: true,
    tagline: {
      es: "Aplicaciones de escritorio con Python: todos los componentes de tkinter y ttk, de la etiqueta a la tabla de datos, con la ventana de verdad.",
      en: "Desktop apps with Python: every tkinter and ttk component, from labels to data tables, with the real window.",
    },
    studio: {
      es: "En DMarlon Studio, tkinter es el destino Escritorio (Python): arrastra los componentes de la paleta al formulario, ajusta sus propiedades en el inspector y el estudio escribe este mismo código tkinter.",
      en: "In DMarlon Studio, tkinter is the Desktop (Python) target: drag components from the palette onto the form, set their properties in the inspector and the studio writes this same tkinter code.",
    },
    steps: {
      es: [
        "Abra DMarlon Studio, pulse **Nuevo proyecto** y elija el destino **Escritorio (Python)**.",
        "Arrastre el componente de la lección desde la paleta al formulario, o pegue el código en la pestaña **Código**.",
        "Pulse **Ejecutar** (F9): se abre la misma ventana de la imagen.",
        "Cambie sus propiedades en el inspector y vea el código tkinter que genera el estudio en **Generado**.",
      ],
      en: [
        "Open DMarlon Studio, click **New project** and choose the **Desktop (Python)** target.",
        "Drag the lesson's component from the palette onto the form, or paste the code into the **Code** tab.",
        "Click **Run** (F9): the same window as in the picture opens.",
        "Change its properties in the inspector and see the tkinter code the studio generates in **Generated**.",
      ],
    },
  },
  {
    id: "javascript",
    name: "JavaScript",
    ext: "js",
    shiki: "javascript",
    icon: "javascript",
    color: "#F7DF1E",
    command: "node main.js",
    tagline: {
      es: "El lenguaje de la web: páginas, servidores con Node.js, apps de escritorio con Electron y móviles con React Native.",
      en: "The language of the web: pages, Node.js servers, Electron desktop apps and React Native mobile apps.",
    },
    studio: {
      es: "En DMarlon Studio, JavaScript es el lenguaje de los destinos Electron + React, Next.js, React, Vue, HTML, extensiones de Chrome y React Native: el estudio genera la interfaz y usted escribe la lógica.",
      en: "In DMarlon Studio, JavaScript is the language of the Electron + React, Next.js, React, Vue, HTML, Chrome extension and React Native targets: the studio generates the UI and you write the logic.",
    },
    steps: {
      es: [
        "Abra DMarlon Studio y cree un proyecto **Electron + React** o **Web (Next.js)**.",
        "En la pestaña **Código**, el módulo de la lógica es JavaScript: pegue allí las funciones de la lección.",
        "Para verlo tal cual, ejecútelo con Node.js desde la terminal del estudio (⌘J): `node main.js`.",
        "Después, llame a esas funciones desde un botón del diseñador.",
      ],
      en: [
        "Open DMarlon Studio and create an **Electron + React** or **Web (Next.js)** project.",
        "In the **Code** tab the logic module is JavaScript: paste the lesson's functions there.",
        "To see it exactly as shown, run it with Node.js from the studio terminal (⌘J): `node main.js`.",
        "Then call those functions from a button in the designer.",
      ],
    },
  },
  {
    id: "c",
    name: "C",
    ext: "c",
    shiki: "c",
    icon: "c",
    color: "#A8B9CC",
    command: "cc main.c -o main && ./main",
    tagline: {
      es: "El lenguaje de los sistemas: rápido, cercano a la máquina y la base de casi todo lo demás.",
      en: "The systems language: fast, close to the machine and the foundation of almost everything else.",
    },
    studio: {
      es: "En DMarlon Studio, C se escribe en la consola: el estudio compila y ejecuta con un clic y muestra los errores en la línea donde están.",
      en: "In DMarlon Studio, C is written in the console target: the studio compiles and runs with one click and shows errors on the line where they are.",
    },
    steps: consoleSteps("C", "main.c"),
  },
  {
    id: "cpp",
    name: "C++",
    ext: "cpp",
    shiki: "cpp",
    icon: "cplusplus",
    color: "#00599C",
    command: "c++ -std=c++17 main.cpp -o main && ./main",
    tagline: {
      es: "Rendimiento con abstracciones: clases, plantillas y la biblioteca estándar para programas grandes y rápidos.",
      en: "Performance with abstractions: classes, templates and the standard library for big, fast programs.",
    },
    studio: {
      es: "En DMarlon Studio, C++ es el lenguaje de las aplicaciones de escritorio nativas con FLTK y de la consola: diseña la ventana y el estudio genera el C++.",
      en: "In DMarlon Studio, C++ powers native desktop apps with FLTK and the console: design the window and the studio generates the C++.",
    },
    steps: consoleSteps("C++", "main.cpp"),
  },
  {
    id: "pascal",
    name: "Pascal",
    ext: "pas",
    shiki: "pascal",
    icon: "lazarus",
    color: "#1F5DA8",
    command: "fpc main.pas && ./main",
    tagline: {
      es: "Claro y estricto, ideal para aprender: Free Pascal y Lazarus crean aplicaciones nativas para Windows, macOS y Linux.",
      en: "Clear and strict, ideal for learning: Free Pascal and Lazarus build native apps for Windows, macOS and Linux.",
    },
    studio: {
      es: "En DMarlon Studio, Pascal es el lenguaje de las aplicaciones de escritorio con Lazarus (como la demo de Odoo sin conexión) y de la consola.",
      en: "In DMarlon Studio, Pascal powers desktop apps with Lazarus (like the offline Odoo demo) and the console.",
    },
    steps: consoleSteps("Pascal", "main.pas"),
  },
  {
    id: "go",
    name: "Go",
    ext: "go",
    shiki: "go",
    icon: "go",
    color: "#00ADD8",
    command: "go run main.go",
    tagline: {
      es: "Sencillo y concurrente: servidores web, herramientas de línea de órdenes y servicios en la nube.",
      en: "Simple and concurrent: web servers, command-line tools and cloud services.",
    },
    studio: {
      es: "En DMarlon Studio, Go es el servidor del destino Web (Go): usted diseña las pantallas y el estudio genera el servidor en Go que las sirve.",
      en: "In DMarlon Studio, Go is the server of the Web (Go) target: you design the screens and the studio generates the Go server that serves them.",
    },
    steps: {
      es: [
        "Abra DMarlon Studio y cree un proyecto **Web (Go)**.",
        "En la pestaña **Código** está el servidor en Go: añada allí las funciones de la lección.",
        "Para verlo tal cual, ejecútelo desde la terminal del estudio (⌘J): `go run main.go`.",
        "Pulse **Ejecutar** (F9) para arrancar la web con su servidor.",
      ],
      en: [
        "Open DMarlon Studio and create a **Web (Go)** project.",
        "The **Code** tab holds the Go server: add the lesson's functions there.",
        "To see it exactly as shown, run it from the studio terminal (⌘J): `go run main.go`.",
        "Click **Run** (F9) to start the website with its server.",
      ],
    },
  },
  {
    id: "dart",
    name: "Dart",
    ext: "dart",
    shiki: "dart",
    icon: "dart",
    color: "#0175C2",
    command: "dart run main.dart",
    tagline: {
      es: "El lenguaje de Flutter: una sola base de código para Android, iOS, web y escritorio.",
      en: "The language of Flutter: one codebase for Android, iOS, web and desktop.",
    },
    studio: {
      es: "En DMarlon Studio, Dart es el lenguaje de los destinos Flutter (móvil y escritorio): diseña las pantallas en el lienzo del teléfono y el estudio escribe el Dart.",
      en: "In DMarlon Studio, Dart is the language of the Flutter targets (mobile and desktop): design the screens on the phone canvas and the studio writes the Dart.",
    },
    steps: {
      es: [
        "Abra DMarlon Studio y cree un proyecto **Flutter (móvil)** o **Flutter (escritorio)**.",
        "En la pestaña **Código** está el Dart de los datos y la lógica: pegue allí las funciones de la lección.",
        "Para verlo tal cual, ejecútelo desde la terminal del estudio (⌘J): `dart run main.dart`.",
        "Pulse **Ejecutar** (F9) para verlo en el emulador del teléfono.",
      ],
      en: [
        "Open DMarlon Studio and create a **Flutter (mobile)** or **Flutter (desktop)** project.",
        "The **Code** tab holds the data and logic in Dart: paste the lesson's functions there.",
        "To see it exactly as shown, run it from the studio terminal (⌘J): `dart run main.dart`.",
        "Click **Run** (F9) to see it in the phone emulator.",
      ],
    },
  },
  {
    id: "sqlite",
    name: "SQLite",
    ext: "sql",
    shiki: "sql",
    icon: "sqlite",
    color: "#0F80CC",
    command: "SQLite",
    db: "sqlite",
    seed: "shop.sql",
    tagline: {
      es: "SQL con la base de datos más usada del mundo: un solo archivo, sin servidor, dentro de apps de escritorio y móviles.",
      en: "SQL with the most widely used database in the world: a single file, no server, inside desktop and mobile apps.",
    },
    studio: {
      es: "En DMarlon Studio, SQLite se abre en el módulo Bases de datos (consultas, tablas y CSV) y es la base de datos de las apps de escritorio que diseña: el componente Conexión de datos la enlaza con las tablas del formulario.",
      en: "In DMarlon Studio, SQLite opens in the Databases module (queries, tables and CSV) and is the database of the desktop apps you design: the Data connection component links it to the form's tables.",
    },
    steps: dbSteps(
      {
        es: "Pulse **+**, elija **SQLite** y escoja un archivo vacío (por ejemplo `shop.db`).",
        en: "Click **+**, choose **SQLite** and pick an empty file (for example `shop.db`).",
      },
      "shop.sql",
    ),
  },
  {
    id: "postgres",
    name: "PostgreSQL",
    ext: "sql",
    shiki: "sql",
    icon: "postgres",
    color: "#4169E1",
    command: "PostgreSQL",
    db: "postgres",
    seed: "shop.sql",
    tagline: {
      es: "La base de datos de código abierto más avanzada: SQL estándar, JSON, funciones, ventanas y transacciones de verdad.",
      en: "The most advanced open-source database: standard SQL, JSON, functions, window queries and real transactions.",
    },
    studio: {
      es: "En DMarlon Studio, PostgreSQL se conecta desde el módulo Bases de datos (servidor, base de datos, usuario y SSL) y lo usan las apps de escritorio con el componente Conexión de datos.",
      en: "In DMarlon Studio, PostgreSQL connects from the Databases module (server, database, user and SSL) and desktop apps use it through the Data connection component.",
    },
    steps: dbSteps(
      {
        es: "Pulse **+**, elija **PostgreSQL** y escriba el servidor, el puerto (5432), una base de datos vacía y su usuario. **Probar conexión** lo comprueba.",
        en: "Click **+**, choose **PostgreSQL** and enter the server, the port (5432), an empty database and its user. **Test connection** checks it.",
      },
      "shop.sql",
    ),
  },
  {
    id: "mysql",
    name: "MySQL",
    ext: "sql",
    shiki: "sql",
    icon: "mysql",
    color: "#00758F",
    command: "MySQL",
    db: "mysql",
    seed: "shop.sql",
    tagline: {
      es: "La base de datos de la web: SQL con MySQL 8 y MariaDB, de la primera consulta a los procedimientos y los disparadores.",
      en: "The database of the web: SQL with MySQL 8 and MariaDB, from the first query to procedures and triggers.",
    },
    studio: {
      es: "En DMarlon Studio, MySQL y MariaDB se conectan desde el módulo Bases de datos (con TLS si el servidor lo pide) y los usan las apps de escritorio con el componente Conexión de datos.",
      en: "In DMarlon Studio, MySQL and MariaDB connect from the Databases module (with TLS when the server asks for it) and desktop apps use them through the Data connection component.",
    },
    steps: dbSteps(
      {
        es: "Pulse **+**, elija **MySQL / MariaDB** y escriba el servidor, el puerto (3306), una base de datos vacía y su usuario.",
        en: "Click **+**, choose **MySQL / MariaDB** and enter the server, the port (3306), an empty database and its user.",
      },
      "shop.sql",
    ),
  },
  {
    id: "mongodb",
    name: "MongoDB",
    ext: "json",
    shiki: "jsonc",
    icon: "mongodb",
    color: "#47A248",
    command: "MongoDB",
    db: "mongodb",
    seed: "shop.json",
    tagline: {
      es: "La base de datos de documentos: colecciones JSON, filtros, índices y el pipeline de agregación.",
      en: "The document database: JSON collections, filters, indexes and the aggregation pipeline.",
    },
    studio: {
      es: "En DMarlon Studio, MongoDB se consulta desde el módulo Bases de datos con un JSON por consulta: find, aggregate, insert, update, delete, count, distinct e índices.",
      en: "In DMarlon Studio, MongoDB is queried from the Databases module with one JSON per query: find, aggregate, insert, update, delete, count, distinct and indexes.",
    },
    steps: dbSteps(
      {
        es: "Pulse **+**, elija **MongoDB** y escriba la URI (`mongodb://localhost:27017/shop`) o el servidor y la base de datos.",
        en: "Click **+**, choose **MongoDB** and enter the URI (`mongodb://localhost:27017/shop`) or the server and database.",
      },
      "shop.json",
    ),
  },
  {
    id: "falcondatabase",
    name: "FalconDatabase",
    ext: "json",
    shiki: "jsonc",
    color: "#E8590C",
    command: "FalconDatabase",
    db: "falcon",
    seed: "shop.json",
    tagline: {
      es: "Un backend en la nube con tablas de PostgreSQL, API REST, usuarios y reglas de acceso, sin escribir un servidor.",
      en: "A cloud backend with PostgreSQL tables, a REST API, users and access rules, without writing a server.",
    },
    studio: {
      es: "En DMarlon Studio, FalconDatabase se consulta desde el módulo Bases de datos y es la base de datos de las apps de Flutter: el estudio genera lib/db.dart con las tablas y el inicio de sesión.",
      en: "In DMarlon Studio, FalconDatabase is queried from the Databases module and is the database of Flutter apps: the studio generates lib/db.dart with the tables and sign-in.",
    },
    steps: {
      es: [
        "Abra DMarlon Studio y entre en el módulo **Bases de datos**.",
        "Pulse **+** y elija **FalconDatabase**. Para leer, use el proyecto de ejemplo del curso: **Proyecto** `ddbsnwfthlcufjjezqqf` y **Clave de API** `fdb_anon_01574d098100502b15344a0d9ba01bb4bcaeb60953030895` (solo lectura).",
        "Para las lecciones que escriben, cree su proyecto gratis en falcondatabase.com con las tablas de la tienda (`shop.json`, abajo, lleva las filas), un usuario y su correo y contraseña en la conexión.",
        "Pegue el script de la lección y pulse **Ejecutar** (⌘↵): cada consulta deja su resultado en una pestaña, como en la imagen.",
      ],
      en: [
        "Open DMarlon Studio and go to the **Databases** module.",
        "Click **+** and choose **FalconDatabase**. To read, use the course's sample project: **Project** `ddbsnwfthlcufjjezqqf` and **API key** `fdb_anon_01574d098100502b15344a0d9ba01bb4bcaeb60953030895` (read only).",
        "For the lessons that write, create your free project at falcondatabase.com with the shop tables (`shop.json`, below, has the rows), a user and their email and password in the connection.",
        "Paste the lesson's script and click **Run** (⌘↵): each query leaves its result in a tab, as in the picture.",
      ],
    },
  },
  {
    id: "firebase",
    name: "Firebase",
    ext: "json",
    shiki: "jsonc",
    icon: "firebase",
    color: "#DD2C00",
    command: "Firestore",
    db: "firebase",
    seed: "shop.json",
    tagline: {
      es: "Cloud Firestore, la base de datos de documentos de Google: colecciones, subcolecciones, consultas y agregados.",
      en: "Cloud Firestore, Google's document database: collections, subcollections, queries and aggregations.",
    },
    studio: {
      es: "En DMarlon Studio, Firestore se consulta desde el módulo Bases de datos (en la nube o con el emulador) y es una de las bases de datos de las apps de Flutter: el estudio genera lib/db.dart.",
      en: "In DMarlon Studio, Firestore is queried from the Databases module (in the cloud or with the emulator) and is one of the databases of Flutter apps: the studio generates lib/db.dart.",
    },
    steps: dbSteps(
      {
        es: "Pulse **+**, elija **Firebase** y escriba el ID del proyecto y, para practicar sin tocar datos de verdad, el **Emulador** (`localhost:8080`, con `firebase emulators:start --only firestore`).",
        en: "Click **+**, choose **Firebase** and enter the project ID and, to practise without touching real data, the **Emulator** (`localhost:8080`, with `firebase emulators:start --only firestore`).",
      },
      "shop.json",
    ),
  },
];

export const courseById = (id: string) => COURSES.find((c) => c.id === id);
