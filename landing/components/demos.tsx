import { Blocks, Code2, Package } from "lucide-react";
import { DemoDownloads } from "@/components/demo-downloads";
import { DemoFilter } from "@/components/demo-filter";
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
  filter: string;
  filterAll: string;
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
  items: Record<DemoSeed, DemoText>;
};

const TEXT: Record<Lang, DemosText> = {
  es: {
    sections: {
      desktop: {
        title: "Escritorio",
        intro: "Veintiocho aplicaciones para macOS y Windows. Descárguelas, ábralas y úselas: no necesitan instalar nada más.",
      },
      mobile: {
        title: "Móvil",
        intro: "Apps de Flutter hechas con el editor de pantallas. Pruébelas aquí mismo, dentro de un teléfono, o instálelas en Android.",
      },
      web: {
        title: "Web",
        intro: "La misma tienda, diseñada una vez y generada en tres tecnologías (entre con demo@tienda.com y 1234), y el dominó doble 9 dibujado en un Lienzo. Ábralas en el navegador.",
      },
    },
    how2: "Cómo funciona",
    filter: "Lenguaje:",
    filterAll: "Todos",
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
      html_domino: {
        name: "Dominó doble 9 (web)",
        text: "El dominó de la mesa de cuatro, ahora en el navegador: una pantalla con un Lienzo que dibuja la mesa y recibe los toques. En el móvil, mejor en horizontal.",
        shows: ["El componente Lienzo del editor de pantallas", "Toda la partida en un app.js normal y corriente", "Sin instalar nada: se juega aquí mismo"],
      },
      next_world: {
        name: "El mundo en directo (Next.js)",
        text: "Un mapa del mundo con los aviones, los barcos y los trenes que se mueven ahora mismo, con datos públicos de OpenSky, Fintraffic, Renfe y VR. Corre en su propio servidor de Next.js, que descarga y junta los datos; la web los dibuja y se actualiza sola.",
        shows: ["Next.js con servidor: el código después de // @server", "Miles de puntos en un Lienzo, cada 30 segundos", "Sin claves ni APIs de fuera en el navegador"],
      },
      next_speed: {
        name: "Velocidad de internet (Next.js)",
        text: "Mide su conexión con el servidor de esta web: el ping y el jitter, la bajada y la subida, con un indicador que se mueve mientras mide. Al acabar le dice para qué le alcanza (videollamadas, 4K, juegos…) y guarda cada medición en su historial.",
        shows: ["El servidor envía y recibe los datos de la prueba", "Un indicador dibujado en un Lienzo", "El historial, guardado en su navegador"],
      },
      next_flights: {
        name: "Buscador de vuelos (Next.js)",
        text: "El buscador de vuelos de C++, ahora en el navegador: vigila sus rutas al abrirse y cada 30 minutos, con el mejor precio de cada aerolínea y dónde comprarlo, el precio de cada día del mes, cómo cambia y avisos cuando baja. El token de Travelpayouts se queda en el servidor; sin él, datos de ejemplo.",
        shows: ["La clave de la API, solo en el servidor", "Las rutas, guardadas en su navegador", "Gráficas en dos Lienzos y enlaces para comprar"],
      },
    },
    title: "Demos",
    eyebrow: "Hecho con DMarlon Studio",
    intro:
      "Aplicaciones de verdad hechas con DMarlon Studio: veintiocho aplicaciones de escritorio para macOS y Windows, tres apps móviles y siete webs que puede probar aquí mismo. Todas se diseñaron arrastrando componentes y vienen como ejemplo en el estudio: ábralas allí y cámbielas.",
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
        "Cada demo va en español y en inglés: el idioma se cambia en su menú Idioma (Language) y se recuerda para todas.",
        "Las demos aún no están firmadas: si macOS la bloquea, haga clic derecho → Abrir, o vaya a Ajustes del Sistema → Privacidad y seguridad → «Abrir igualmente».",
      ],
      windows: [
        "Descomprima la carpeta completa y abra el .exe con el nombre de la demo.",
        "Cada demo va en español y en inglés: el idioma se cambia en su menú Idioma (Language) y se recuerda para todas.",
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
        text: "Un panel de ventas nativo para Odoo 8 a 20: clientes, productos, presupuestos, punto de venta y obras de BIM 2.0, que se trabajan sin conexión y se envían a Odoo al volver, sin duplicados.",
        shows: ["Una app nativa en Object Pascal (Lazarus)", "JSON-RPC con todas las versiones de Odoo", "Presupuestos de obra por conceptos (BIM 2.0)"],
      },
      file_renamer: {
        name: "Renombrar archivos",
        text: "Cambie el nombre de muchos archivos a la vez con reglas, viendo el resultado antes de aplicarlo.",
        shows: ["Expresiones regulares y numeración", "Vista previa en vivo con conflictos marcados", "Deshacer el último cambio"],
      },
      cpp_explorer: {
        name: "Explorador de archivos (C++)",
        text: "Un explorador de archivos nativo con el aspecto azulado de Aero: árbol de carpetas, iconos, lista y detalles, pestañas, marcadores, copiar y pegar con el Finder o el Explorador, Papelera y tema claro u oscuro. En macOS, para Apple Silicon.",
        shows: ["Una app nativa en C++ con FLTK, diseñada en el estudio", "Componentes propios dibujados en código, sin imágenes", "Portapapeles de archivos del sistema y trabajo en segundo plano"],
      },
      cpp_racing: {
        name: "Carrera de motos (C++)",
        text: "Un juego de carreras de motos en pseudo-3D: curvas y cuestas, la moto que se inclina, siete rivales, semáforo de salida, vueltas, clasificación con diferencias, minimapa y cuadro de mandos. Teclado: flechas o WASD. En macOS, para Apple Silicon.",
        shows: ["Un juego nativo en C++ con FLTK, a 60 imágenes por segundo", "La pista, las motos y el paisaje se dibujan en código, sin imágenes", "Rivales que frenan, trazan y adelantan, y récord de vuelta guardado"],
      },
      cpp_image_editor: {
        name: "Editor de imágenes (C++)",
        text: "Un editor de imágenes por capas al estilo de los programas de retoque: pincel, borrador, bote, degradado, formas y texto; recortar, cambiar el tamaño, girar y voltear; niveles, tono y saturación y filtros, con historial. Abre y guarda PNG, JPEG y BMP. En macOS, para Apple Silicon.",
        shows: ["Una app nativa en C++ con FLTK, diseñada en el estudio", "Capas con opacidad y ocho modos de fusión, e historial", "Codificadores JPEG y BMP propios, sin más bibliotecas"],
      },
      cpp_flights: {
        name: "Buscador de vuelos (C++)",
        text: "Vigila sus rutas: al abrirse y cada 30 minutos analiza los precios de todas las aerolíneas (Travelpayouts, la API de Aviasales), dice el mejor precio de cada una y dónde comprarlo, el día más barato del mes y cómo cambia el precio, y avisa cuando baja. Sin token, con datos de ejemplo. En macOS, para Apple Silicon.",
        shows: ["Una app nativa en C++ con FLTK, diseñada en el estudio", "Consultas a una API REST con curl y JSON leído a mano", "Tablas y gráficas dibujadas en código, con avisos del sistema"],
      },
      cpp_hardware: {
        name: "Inspector del equipo (C++)",
        text: "Analiza su ordenador: el sistema, el procesador (con cada núcleo), la memoria, el modelo y el firmware, los gráficos y las pantallas, los discos, la red, la batería, el audio y los periféricos, con el uso en directo cada segundo. Guarda un informe en PDF, lo imprime o lo copia. Nada sale del equipo. En macOS, para Apple Silicon.",
        shows: ["Una app nativa en C++ con FLTK, diseñada en el estudio", "Datos de sysctl y system_profiler (macOS) o Win32 y PowerShell (Windows)", "Un informe en PDF de varias páginas dibujado con FLTK, sin más bibliotecas"],
      },
      cpp_wifi: {
        name: "Wifi de casa (C++)",
        text: "Analiza la wifi de su casa: su red, las de alrededor, los canales y el router, y le da una nota de 0 a 100 con lo grave, lo importante y lo que se puede mejorar (a qué canal cambiar, qué cifrado usar, qué cerrar en el router). Escriba su contraseña y le dice lo fuerte que es; no se guarda ni sale del equipo. En macOS, para Apple Silicon.",
        shows: ["Una app nativa en C++ con FLTK, diseñada en el estudio", "Datos de system_profiler (macOS) o netsh (Windows) y pruebas al router con sockets", "Un diagnóstico, un mapa de canales y un análisis de la contraseña, dibujados en código"],
      },
      cpp_console: {
        name: "Consola (C++)",
        text: "Una consola al estilo de iTerm: pestañas con su propia shell, la orden en verde mientras la escribe, una cola de órdenes que se ejecutan de una en una cuando termina la anterior, órdenes guardadas con Ctrl+Espacio, atajos (un nombre como conectar-servidor que ejecuta su orden), history para elegir entre las últimas, ayuda y diez apariencias. En macOS, para Apple Silicon.",
        shows: ["Una app nativa en C++ con FLTK y un pseudoterminal de verdad", "La shell avisa al volver al prompt: así sabe la cola cuándo seguir", "Atajos con varias órdenes que son funciones de la shell: uno puede llamar a otro"],
      },
      pascal_malecon: {
        name: "Bajo la Sombra del Malecón (Pascal)",
        text: "Una aventura de investigación en La Habana de 2026, con el aspecto de los juegos VGA de MS-DOS: interrogue a los vecinos, gestione la linterna en pleno apagón, entre al puerto sin que le vean, descifre una memoria antes de que se caiga la red y elija uno de los tres finales. En macOS, para Apple Silicon.",
        shows: ["Object Pascal con Lazarus, diseñada en el estudio", "Pixel art de 256 colores dibujado píxel a píxel en código", "Cuatro actos, pistas, objetos y tres finales"],
      },
      pascal_docker: {
        name: "Docker en la barra de menús (Pascal)",
        text: "Un icono en la barra de menús de macOS (en Windows, junto al reloj) con sus contenedores de Docker: los que están en marcha, agrupados por proyecto de Compose, con sus direcciones para abrirlas en el navegador y las opciones de parar, reiniciar o iniciar los parados. Encuentra Docker Desktop, Colima, OrbStack o Rancher Desktop. En macOS, para Apple Silicon.",
        shows: ["Object Pascal con Lazarus: TTrayIcon y su menú, sin ventana en el Dock", "«docker ps» cada tres segundos en un hilo, sin bloquear el menú", "Las direcciones salen de los puertos publicados (http o https)"],
      },
      pascal_launcher: {
        name: "Lanzador de apps (Pascal)",
        text: "Un icono en la barra de menús con las aplicaciones de la carpeta donde lo deja (por ejemplo, junto a estas demos), cada una con su icono: las favoritas y las recientes arriba, y un panel con buscador para abrirlas con el teclado. En macOS, para Apple Silicon.",
        shows: ["Object Pascal con Lazarus: TTrayIcon y un menú con el icono de cada app", "Los iconos y los nombres los da el sistema (NSWorkspace), como en el Finder", "Búsqueda sin acentos, favoritas con estrella y recientes guardadas"],
      },
      cpp_webmon: {
        name: "Monitor de sitios web (C++)",
        text: "Añada las direcciones de sus webs y el monitor comprueba cada 2 minutos (o el intervalo que elija) si contestan: el código, el tiempo de respuesta, la disponibilidad y un historial en barras. Cierre la ventana y sigue en la barra de menús, con un menú para abrir, comprobar o pausar cada sitio; si uno se cae, macOS le avisa. Y un escáner de puertos de cada servidor, que marca los que no conviene abrir a internet. En macOS, para Apple Silicon.",
        shows: ["C++17 con FLTK, diseñada en el estudio", "curl y sockets en otros hilos: la ventana nunca se congela", "El icono de la barra de menús hecho desde C++ con el runtime de Objective-C"],
      },
      cpp_clocks: {
        name: "Relojes del mundo (C++)",
        text: "La hora de varios países en la barra de menús, con su bandera: por defecto España, Argentina, Venezuela, República Dominicana y Cuba, y otros 34 para elegir. Cada reloj tiene su esfera (oscura de noche), la fecha y la diferencia con su hora, y el horario de verano de cada país se calcula solo. En macOS, para Apple Silicon.",
        shows: ["C++17 con FLTK, diseñada en el estudio", "Las reglas del horario de verano en el código, comprobadas contra la base de zonas del sistema", "La barra de menús desde C++ con el runtime de Objective-C"],
      },
      cpp_recorder: {
        name: "Grabador de pantalla (C++)",
        text: "Para hacer vídeos de YouTube: grabe la pantalla entera o una zona de 16:9 (1080p o 720p) o vertical para Shorts, con el sonido del micrófono, los clics y el cursor, cuenta atrás y límite de tiempo. Mientras graba, la ventana se esconde y el tiempo va en la barra de menús; después, cada vídeo con su miniatura, listo para subir. En macOS, para Apple Silicon.",
        shows: ["C++17 con FLTK, diseñada en el estudio", "Graba con screencapture (macOS) o ffmpeg (Windows y Linux)", "La duración y el tamaño se leen del propio vídeo (átomos mvhd y tkhd)"],
      },
      cpp_mywa: {
        name: "MyWhatsapp (C++)",
        text: "Lee sus chats de WhatsApp Desktop (en el Mac, solo lectura) o un chat exportado, y propone tres respuestas con la IA de Claude o de ChatGPT según la conversación, lo que quiere decir y el estilo que elija. Envía con «Enviar ➤» o Enter, también adjuntos, por la API oficial de WhatsApp Business o vinculando WhatsApp con un QR. Diseña y publica estados de WhatsApp (plantillas y textos con IA). Se queda en la barra de menús con cuántos chats esperan respuesta. Un asistente con IA responde sobre sus chats («¿qué hago con @juan?») e investiga el mensaje de un cliente para proponerle la respuesta. Con modos ocupado que contestan solos, filtros (por responder, sin respuesta, con tareas) y los archivados aparte, traducción para chatear en otro idioma, la bandera y la hora local de cada contacto, búsqueda y selección de texto en cada chat, tareas que se crean desde un chat (con bolitas según su edad), las fotos de perfil, quién escribe en cada grupo y tema claro u oscuro. En macOS, para Apple Silicon.",
        shows: ["C++17 con FLTK, diseñada en el estudio", "Claude (Opus 5.5) o ChatGPT por su API HTTP, con las claves en el Llavero", "La base de datos de WhatsApp Desktop, leída con el SQLite del sistema", "Envío por la API oficial de WhatsApp Business o por un puente en Go (QR)"],
      },
      domino: {
        name: "Dominó doble 9",
        text: "Dominó cubano en una mesa de cuatro: usted y su compañero contra dos rivales de la computadora, 10 fichas cada uno, pasar cuando no se lleva, dominó y tranque, y partida a 100 o a 200 tantos.",
        shows: ["Python con tkinter: la mesa y las fichas en un lienzo", "Rivales que recuerdan a qué números pasó cada uno", "La cadena gira como una serpiente al llegar al borde"],
      },
    },
  },
  en: {
    sections: {
      desktop: {
        title: "Desktop",
        intro: "Twenty-eight apps for macOS and Windows. Download them, open them and use them: nothing else to install.",
      },
      mobile: {
        title: "Mobile",
        intro: "Flutter apps made with the screen editor. Try them right here, inside a phone, or install them on Android.",
      },
      web: {
        title: "Web",
        intro: "The same shop, designed once and generated in three technologies (sign in with demo@tienda.com and 1234), and double-nine dominoes drawn on a Canvas. Open them in the browser.",
      },
    },
    how2: "How it works",
    filter: "Language:",
    filterAll: "All",
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
      html_domino: {
        name: "Double-Nine Dominoes (web)",
        text: "The four-player dominoes, now in the browser: one screen with a Canvas that draws the table and receives the taps. On a phone, landscape works best.",
        shows: ["The screen editor's Canvas component", "The whole game in a plain app.js", "Nothing to install: play it right here"],
      },
      next_world: {
        name: "Live World Map (Next.js)",
        text: "A world map with the planes, ships and trains moving right now, with public data from OpenSky, Fintraffic, Renfe and VR. It runs on its own Next.js server, which downloads and merges the data; the website draws it and updates itself.",
        shows: ["Next.js with a server: the code after // @server", "Thousands of points on a Canvas, every 30 seconds", "No keys or third-party APIs in the browser"],
      },
      next_speed: {
        name: "Internet Speed Test (Next.js)",
        text: "It measures your connection to this website's server: the ping and jitter, the download and the upload, with a gauge that moves while it measures. When it ends it tells you what it is good enough for (video calls, 4K, games…) and saves each measurement in its history.",
        shows: ["The server sends and receives the test data", "A gauge drawn on a Canvas", "The history, saved in your browser"],
      },
      next_flights: {
        name: "Flight Finder (Next.js)",
        text: "The C++ flight finder, now in the browser: it watches your routes when it opens and every 30 minutes, with each airline's best price and where to buy it, the price of each day of the month, how it changes and alerts when it drops. The Travelpayouts token stays on the server; without it, sample data.",
        shows: ["The API key, only on the server", "Your routes, saved in your browser", "Charts on two Canvases and links to buy"],
      },
    },
    title: "Demos",
    eyebrow: "Made with DMarlon Studio",
    intro:
      "Real apps made with DMarlon Studio: twenty-eight desktop apps for macOS and Windows, three mobile apps and seven websites you can try right here. They were all designed by dragging components and come as examples in the studio: open them there and change them.",
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
        "Every demo comes in English and Spanish: change it in its Language (Idioma) menu and it is remembered for all of them.",
        "The demos are not signed yet: if macOS blocks it, right-click → Open, or go to System Settings → Privacy & Security → “Open Anyway”.",
      ],
      windows: [
        "Unzip the whole folder and open the .exe named after the demo.",
        "Every demo comes in English and Spanish: change it in its Language (Idioma) menu and it is remembered for all of them.",
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
        text: "A native sales cockpit for Odoo 8 to 20: customers, products, quotations, point of sale and BIM 2.0 projects you work on offline and send to Odoo when you are back, without duplicates.",
        shows: ["A native app in Object Pascal (Lazarus)", "JSON-RPC with every Odoo version", "Construction budgets by concepts (BIM 2.0)"],
      },
      file_renamer: {
        name: "File renamer",
        text: "Rename many files at once with rules, seeing the result before applying it.",
        shows: ["Regular expressions and numbering", "Live preview with conflicts marked", "Undo the last change"],
      },
      cpp_explorer: {
        name: "File Explorer (C++)",
        text: "A native file explorer with a bluish Aero look: folder tree, icons, list and details, tabs, bookmarks, copy and paste with Finder or Explorer, Trash and a light or dark theme. On macOS, for Apple Silicon.",
        shows: ["A native C++ app with FLTK, designed in the studio", "Custom components drawn in code, no images", "The system file clipboard and background work"],
      },
      cpp_racing: {
        name: "Motorbike Racing (C++)",
        text: "A pseudo-3D motorbike racing game: bends and hills, a bike that leans into the corners, seven rivals, start lights, laps, standings with gaps, a minimap and a dashboard. Keyboard: arrows or WASD. On macOS, for Apple Silicon.",
        shows: ["A native C++ game with FLTK, at 60 frames per second", "The track, the bikes and the scenery are drawn in code, no images", "Rivals that brake, pick their line and overtake, and a saved lap record"],
      },
      cpp_image_editor: {
        name: "Image Editor (C++)",
        text: "A layer-based image editor in the style of photo retouching programs: brush, eraser, paint bucket, gradient, shapes and text; crop, resize, rotate and flip; levels, hue and saturation and filters, with history. Opens and saves PNG, JPEG and BMP. On macOS, for Apple Silicon.",
        shows: ["A native C++ app with FLTK, designed in the studio", "Layers with opacity and eight blend modes, and history", "Its own JPEG and BMP encoders, no other libraries"],
      },
      cpp_flights: {
        name: "Flight Finder (C++)",
        text: "It watches your routes: when it opens and every 30 minutes it checks the prices of every airline (Travelpayouts, the Aviasales API), shows each one's best price and where to buy it, the cheapest day of the month and how the price changes, and alerts you when it drops. Without a token, with sample data. On macOS, for Apple Silicon.",
        shows: ["A native C++ app with FLTK, designed in the studio", "REST API queries with curl and hand-parsed JSON", "Tables and charts drawn in code, with system alerts"],
      },
      cpp_hardware: {
        name: "Hardware Inspector (C++)",
        text: "It analyzes your computer: the system, the processor (with each core), the memory, the model and firmware, the graphics and displays, the disks, the network, the battery, the audio and the peripherals, with live usage every second. It saves a PDF report, prints it or copies it. Nothing leaves the computer. On macOS, for Apple Silicon.",
        shows: ["A native C++ app with FLTK, designed in the studio", "Data from sysctl and system_profiler (macOS) or Win32 and PowerShell (Windows)", "A multi-page PDF report drawn with FLTK, no other libraries"],
      },
      cpp_wifi: {
        name: "Home Wi-Fi (C++)",
        text: "It analyzes your home Wi-Fi: your network, the ones around, the channels and the router, and gives it a score from 0 to 100 with what is serious, what is important and what can be improved (which channel to switch to, which encryption to use, what to close on the router). Type your password and it tells you how strong it is; it is not saved and never leaves the computer. On macOS, for Apple Silicon.",
        shows: ["A native C++ app with FLTK, designed in the studio", "Data from system_profiler (macOS) or netsh (Windows) and router checks with sockets", "A diagnosis, a channel map and a password analysis, drawn in code"],
      },
      cpp_console: {
        name: "Console (C++)",
        text: "An iTerm-style console: tabs with their own shell, the command in green as you type it, a queue of commands that run one at a time when the previous one ends, saved commands with Ctrl+Space, shortcuts (a name like connect-server that runs its command), history to pick from the latest ones, help and ten looks. On macOS, for Apple Silicon.",
        shows: ["A native C++ app with FLTK and a real pseudo-terminal", "The shell reports when it returns to the prompt: that's how the queue knows when to go on", "Shortcuts with several commands that are shell functions: one can call another"],
      },
      pascal_malecon: {
        name: "Under the Shadow of the Malecón (Pascal)",
        text: "An investigation adventure in Havana in 2026, with the look of the MS-DOS VGA games: question the locals, manage your torch during the blackout, get into the port unseen, crack a USB stick before the network goes down and choose one of three endings. On macOS, for Apple Silicon.",
        shows: ["Object Pascal with Lazarus, designed in the studio", "256-colour pixel art drawn pixel by pixel in code", "Four acts, clues, items and three endings"],
      },
      pascal_docker: {
        name: "Docker in the Menu Bar (Pascal)",
        text: "An icon in the macOS menu bar (on Windows, next to the clock) with your Docker containers: the running ones, grouped by Compose project, with their addresses to open in the browser and options to stop, restart or start the stopped ones. It finds Docker Desktop, Colima, OrbStack or Rancher Desktop. On macOS, for Apple Silicon.",
        shows: ["Object Pascal with Lazarus: TTrayIcon and its menu, with no window in the Dock", "“docker ps” every three seconds on a thread, without blocking the menu", "The addresses come from the published ports (http or https)"],
      },
      pascal_launcher: {
        name: "App Launcher (Pascal)",
        text: "A menu bar icon with the apps in the folder where you put it (for example, next to these demos), each with its icon: favorites and recent ones at the top, and a panel with a search box to open them from the keyboard. On macOS, for Apple Silicon.",
        shows: ["Object Pascal with Lazarus: TTrayIcon and a menu with each app's icon", "The icons and names come from the system (NSWorkspace), as in the Finder", "Accent-insensitive search, starred favorites and saved recent apps"],
      },
      cpp_webmon: {
        name: "Website Monitor (C++)",
        text: "Add your websites and the monitor checks every 2 minutes (or the interval you choose) whether they answer: the status code, response time, uptime and a bar history. Close the window and it stays in the menu bar, with a menu to open, check or pause each site; if one goes down, macOS lets you know. Plus a port scanner for each server, which flags the ones that should not be open to the internet. On macOS, for Apple Silicon.",
        shows: ["C++17 with FLTK, designed in the studio", "curl and sockets on other threads: the window never freezes", "The menu bar icon made from C++ with the Objective-C runtime"],
      },
      cpp_clocks: {
        name: "World Clocks (C++)",
        text: "The time in several countries in the menu bar, with their flag: Spain, Argentina, Venezuela, the Dominican Republic and Cuba by default, and 34 more to choose from. Each clock has its dial (dark at night), the date and the difference with your time, and each country's daylight saving time is worked out automatically. On macOS, for Apple Silicon.",
        shows: ["C++17 with FLTK, designed in the studio", "Daylight saving rules in the code, checked against the system's time zone database", "The menu bar from C++ with the Objective-C runtime"],
      },
      cpp_recorder: {
        name: "Screen Recorder (C++)",
        text: "For making YouTube videos: record the whole screen or a 16:9 area (1080p or 720p) or a vertical one for Shorts, with microphone sound, clicks and cursor, a countdown and a time limit. While recording, the window hides and the time goes in the menu bar; afterwards, each video with its thumbnail, ready to upload. On macOS, for Apple Silicon.",
        shows: ["C++17 with FLTK, designed in the studio", "Records with screencapture (macOS) or ffmpeg (Windows and Linux)", "Duration and size are read from the video itself (mvhd and tkhd atoms)"],
      },
      cpp_mywa: {
        name: "MyWhatsapp (C++)",
        text: "Reads your WhatsApp Desktop chats (on the Mac, read-only) or an exported chat, and suggests three replies with Claude or ChatGPT based on the conversation, what you want to say and the style you choose. Sends with “Send ➤” or Enter, attachments too, through the official WhatsApp Business API or by linking WhatsApp with a QR code. It designs and publishes WhatsApp statuses (templates and AI-written texts). It stays in the menu bar with how many chats are waiting for a reply. An AI assistant answers questions about your chats (“what do I do with @juan?”) and investigates a client's message to suggest the reply. With busy modes that reply automatically, filters (to answer, no reply, with tasks) and archived chats apart, translation to chat in another language, each contact's flag and local time, search and text selection in each chat, tasks created from a chat (with dots by age), profile pictures, who writes in each group and a light or dark theme. On macOS, for Apple Silicon.",
        shows: ["C++17 with FLTK, designed in the studio", "Claude (Opus 5.5) or ChatGPT through their HTTP API, with the keys in the Keychain", "The WhatsApp Desktop database, read with the system's SQLite", "Sending through the official WhatsApp Business API or a Go bridge (QR)"],
      },
      domino: {
        name: "Double-Nine Dominoes",
        text: "Cuban dominoes at a table of four: you and your partner against two computer rivals, 10 tiles each, passing when you can't play, domino and blocked games, and a game to 100 or 200 points.",
        shows: ["Python with tkinter: the table and the tiles on a canvas", "Rivals that remember which numbers each player passed on", "The line of tiles snakes round when it reaches the edge"],
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
        : DESKTOP_TECH[seed] ?? { icon: "python", label: x.tech };
  return { kind, d, tech, x };
}

const POINT_ICONS = [Blocks, Package, Code2];

/** Los lenguajes de las demos (para filtrar), con cuántas hay de cada uno. */
const LANG_NAMES: Partial<Record<TargetIcon, string>> = {
  python: "Python",
  cpp: "C++",
  lazarus: "Pascal",
  flutter: "Flutter",
  html: "HTML",
  react: "React",
  vue: "Vue",
};

function demoLangs() {
  const icons: TargetIcon[] = [
    ...DEMO_SEEDS.map((s) => DESKTOP_TECH[s]?.icon ?? ("python" as TargetIcon)),
    ...MOBILE_SEEDS.map(() => "flutter" as TargetIcon),
    ...WEB_SEEDS.map((s) => WEB_TECH[s].icon),
  ];
  const order = Object.keys(LANG_NAMES) as TargetIcon[];
  return order
    .map((id) => ({ id, label: LANG_NAMES[id]!, count: icons.filter((i) => i === id).length }))
    .filter((l) => l.count > 0);
}

/** Las demos de escritorio que no son de Python. */
const DESKTOP_TECH: Partial<Record<string, { icon: TargetIcon; label: string }>> = {
  pascal_odoo: { icon: "lazarus", label: "Pascal · Lazarus" },
  cpp_explorer: { icon: "cpp", label: "C++ · FLTK" },
  cpp_racing: { icon: "cpp", label: "C++ · FLTK" },
  cpp_image_editor: { icon: "cpp", label: "C++ · FLTK" },
  cpp_flights: { icon: "cpp", label: "C++ · FLTK" },
  cpp_hardware: { icon: "cpp", label: "C++ · FLTK" },
  cpp_wifi: { icon: "cpp", label: "C++ · FLTK" },
  cpp_console: { icon: "cpp", label: "C++ · FLTK" },
  pascal_malecon: { icon: "lazarus", label: "Pascal · Lazarus" },
  pascal_docker: { icon: "lazarus", label: "Pascal · Lazarus" },
  pascal_launcher: { icon: "lazarus", label: "Pascal · Lazarus" },
  cpp_webmon: { icon: "cpp", label: "C++ · FLTK" },
  cpp_clocks: { icon: "cpp", label: "C++ · FLTK" },
  cpp_recorder: { icon: "cpp", label: "C++ · FLTK" },
  cpp_mywa: { icon: "cpp", label: "C++ · FLTK" },
};

const WEB_TECH: Record<WebSeed, { icon: TargetIcon; label: string }> = {
  html_store: { icon: "html", label: "HTML · CSS · JS" },
  react_store: { icon: "react", label: "React · Vite" },
  vue_store: { icon: "vue", label: "Vue · Vite" },
  html_domino: { icon: "html", label: "HTML · Canvas" },
  next_world: { icon: "next", label: "Next.js · API" },
  next_speed: { icon: "next", label: "Next.js · API" },
  next_flights: { icon: "next", label: "Next.js · API" },
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
    <section id={id} data-demo-section className={`scroll-mt-28 border-b border-line ${alt ? "bg-surface" : ""}`}>
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
    <li id={id} data-demo-lang={icon} className="flex scroll-mt-28 flex-col overflow-hidden rounded-xl border border-line bg-canvas shadow-sm">
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
          <div className="mx-auto flex max-w-6xl items-center gap-1 overflow-x-auto px-4 py-2 sm:px-6">
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
          <div className="mx-auto max-w-6xl overflow-x-auto border-t border-line px-4 py-2 sm:px-6">
            <DemoFilter langs={demoLangs()} all={x.filterAll} label={x.filter} />
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
              icon={DESKTOP_TECH[seed]?.icon ?? "python"}
              tech={DESKTOP_TECH[seed]?.label ?? x.tech}
              d={x.items[seed]}
              shows={x.shows}
            >
              <DemoDownloads seed={seed} label={x.download} />
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
