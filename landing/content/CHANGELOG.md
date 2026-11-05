# Cambios

Las versiones se llevan en el archivo `VERSION` y se cambian en todas partes
con `node scripts/version.mjs <versión|patch|minor|major>`.

## 1.0.31 — 2026-11-05

- **FalconDatabase** en el módulo Bases de datos: con la referencia del
  proyecto y su clave (y correo y contraseña si las tablas piden sesión) se
  ven las tablas con sus columnas y se consulta con un JSON:
  `{"table": "productos", "where": {"precio": "gte.10"}, "order": "id.desc"}`,
  con `insert`, `update` y `delete` para cambiar datos. Probado contra
  FalconDatabase de verdad.
- **Firebase (Cloud Firestore)**, también en Bases de datos: colecciones,
  consultas con filtros y orden, y altas, cambios y bajas, con la clave web y
  un usuario de Firebase Authentication, o con el emulador local.
- Web: FalconDatabase entre las bases de datos de la portada.

## 1.0.30 — 2026-11-05

- Pascal en macOS: la aplicación compilada se abría en segundo plano, sin
  ventana visible ni icono en el Dock, y el estudio parecía quedarse en
  «Compilando…». Ahora es una aplicación normal que se pone delante al abrir.
- Pascal y C++: tras compilar, la Salida avisa de que la aplicación está
  abierta y de cómo terminarla.

## 1.0.29 — 2026-11-05

- **Destino Pascal con Lazarus**: aplicaciones de escritorio nativas en
  Object Pascal con los componentes de la LCL de siempre (`TLabel`,
  `TButton`, `TEdit`, `TMemo`…). El código va en la unidad `Form1.pas`
  (`TForm1 = class(TFormDesign)`): al crear un evento, el estudio declara el
  método en la clase y lo escribe en `implementation`. Ejecutar compila con
  `lazbuild` y abre la aplicación; los errores llevan su línea de
  `Form1.pas`. Si falta Lazarus, ofrece instalarlo. Resaltado,
  autocompletado y ayuda de Pascal, exportar el proyecto de Lazarus y el
  ejemplo «Calculadora (Pascal)», que también funciona con el teclado.
- **Ayuda**: muchos más conceptos en Python (`pass`, `return`, `elif`,
  `lambda`, `with`, listas por comprensión, `json`, `datetime`…), JavaScript,
  C++ y Pascal.
- **MySQL 8**: el módulo Bases de datos ya conecta con la autenticación por
  defecto de MySQL 8 (`caching_sha2_password`), repitiendo con conexión
  cifrada cuando el servidor lo pide. SQLite, PostgreSQL, MySQL y MongoDB se
  prueban contra servidores reales.
- Web: entornos, backends y bases de datos con sus logotipos en la portada.

## 1.0.28 — 2026-11-05

- **Ayuda en el código**: clic derecho sobre una palabra → **Ayuda** (o
  **F1**) abre un panel a la derecha con la firma, la explicación y un ejemplo
  de cada comando, en Python, JavaScript y C++ (también lo propio del estudio:
  `self.Label1.text`, `storage`, `dms_run`…). Se busca cualquier comando, se
  cambia de lenguaje y el ejemplo se copia o se inserta en el cursor. El menú
  del clic derecho también copia, corta y pega.

## 1.0.27 — 2026-11-05

- **Subproyectos**: un proyecto puede tener partes, cada una con su propio
  destino (por ejemplo, «Odoo» con «bd» en Python y «front» en Next.js). Se
  crean desde el panel del proyecto con **Añadir subproyecto…**, cuelgan del
  nodo Proyecto del árbol y un clic los abre en su pestaña; desde un
  subproyecto, «Parte de» vuelve al proyecto. Cada uno es una carpeta dentro
  de la del proyecto y no aparece suelto en la lista.

## 1.0.26 — 2026-11-05

- C++: arreglado el icono de la ventana, que impedía compilar las
  aplicaciones de FLTK en la 1.0.25.

## 1.0.25 — 2026-11-05

- **Autocompletado** en el código del Diseñador (Python, JavaScript y C++):
  **Ctrl+Espacio** muestra lo que se puede escribir; tras `self.`, `this.` o
  `Label1->`, los componentes de la ventana y lo de cada uno. También aparece
  al escribir.
- El árbol empieza por el nodo **Proyecto** (en todos los lenguajes): nombre,
  descripción, destino, carpeta e **icono de la aplicación**, que se elige
  con el diálogo de archivos o se **genera con IA** (SVG convertido a PNG de
  512 × 512). Lo usan la ventana (tkinter, Electron, C++), la extensión de
  Chrome y la web de Next.js.
- Esc cierra el buscador y devuelve el cursor al código; F4, F5, F7, F8 y F9
  funcionan también con el cursor en el código, y al detenerse el depurador
  el cursor va a la línea.
- Manual: el proyecto, su icono y el autocompletado.

## 1.0.24 — 2026-11-05

- Nuevo destino **C++ (FLTK)**: aplicaciones de escritorio nativas con el
  mismo Diseñador. El código va en `Form1.cpp` (`class Form1 : public
  FormDesign`, con los eventos como métodos `override`) y cada componente es
  una clase de FLTK con métodos sencillos (`Label1->text("Hola")`).
  - **Ejecutar** compila con el compilador del equipo y FLTK y abre la
    aplicación; los errores salen con su línea de `Form1.cpp`.
  - Si falta FLTK o el compilador, el estudio ofrece **Instalar** (Homebrew
    en macOS).
  - **Depurar** compila con `-g`; **Exportar** crea las fuentes con un
    `Makefile`.
  - Ejemplo **Calculadora (C++)**.
- **Ir a la carpeta** en el menú «…» de cada proyecto.
- Landing: C++ entre los entornos disponibles. Manual: capítulo **C++ con
  FLTK**.

## 1.0.23 — 2026-11-05

- Nuevo destino **Web (Next.js)**: el diseño es la página de un proyecto de
  Next.js (app router) y el código, el mismo JavaScript con React que en
  Electron, ahora en módulos (las líneas de su código no cambian).
  - **Ejecutar** arranca `next dev` con los módulos del entorno compartido
    (Next.js se instala una sola vez) y abre el navegador cuando está listo.
  - `this.storage` guarda en el navegador; **Depurar** con las herramientas
    del navegador; **Exportar** deja el proyecto listo para npm o Vercel.
  - Ejemplos **Calculadora (Next.js)** y **Lista de tareas (Next.js)**,
    probados con `next dev` y Chromium.
- El diálogo «Nuevo proyecto» muestra los destinos en fichas.
- Landing: Next.js entre los entornos disponibles. Manual: capítulo **Web
  con Next.js**.

## 1.0.22 — 2026-11-05

- Nuevo destino **Extensión de Chrome** (Manifest V3), en la misma app: el
  diseño es la ventana emergente de la extensión y el código, JavaScript (el
  mismo motor de React que Electron, empaquetado dentro de la extensión).
  - Desde el código: `this.storage` (guardar datos), `this.currentTab()`,
    `this.openTab(url)`, `this.runInPage(función)` (código en la página
    abierta) y `this.badge(texto)`.
  - **Ejecutar** abre una vista previa de la ventana emergente; **Depurar**,
    con las herramientas de desarrollo; **Cargar en Chrome** la prepara y
    abre `chrome://extensions` con los pasos; **Exportar** crea la carpeta y
    el `.zip` para la Chrome Web Store.
  - Ejemplos **Notas por sitio** y **Contador de palabras**, probados en un
    Chromium de verdad.
- **⌘F / Ctrl+F** en las pestañas Código y Generado del Diseñador: buscar
  (con mayúsculas y expresiones regulares), ir de un resultado a otro y, en
  el código, reemplazar.
- Landing: las extensiones de Chrome, entre los entornos disponibles y en el
  carrusel. Manual: capítulo **Extensiones de Chrome**.

## 1.0.21 — 2026-11-05

- Nuevo destino **Electron + React** (escritorio), en la misma app: al crear
  la aplicación se elige entre Escritorio (Python), Web (Flask) y Electron +
  React. El mismo Diseñador; el código de los eventos, en **JavaScript**
  (`Form1.js`), con componentes de propiedades sencillas
  (`this.Label1.text = "Hola"`) que React vuelve a pintar.
  - Componentes: etiqueta, botón, entrada, contraseña, imagen, texto,
    casilla, opción, lista, combo, escala, marco, vista HTML, tabla, barra de
    progreso, páginas, barra de estado, menú nativo, temporizador y diálogos
    de abrir y guardar.
  - **Ejecutar** instala la primera vez Electron y React (con Node.js) y
    los comparte entre proyectos; la salida y los errores, con su línea de
    `Form1.js`, llegan a la pestaña Salida.
  - **Depurar** abre las herramientas de desarrollo de Chromium con sus
    puntos de parada.
  - **Exportar** crea una carpeta lista para `npm install` y `npm start`.
  - Ejemplos **Calculadora (Electron)** y **Bloc de notas (Electron)**.
  - El servidor MCP y el panel de Claude Code también conocen el destino.
- Landing: Electron + React entre los entornos probados y en el carrusel.
- Manual: capítulo **Electron + React**.

## 1.0.20 — 2026-11-05

- **Depurador** en el Diseñador, para proyectos de escritorio y web, sin
  instalar nada:
  - **Puntos de parada** en el margen del código (clic o F5), con
    **condición** (clic derecho).
  - **Depurar** (Mayús+F9), **Continuar** (F9), **Entrar** (F7), **Pasar por
    encima** (F8), **Salir de la función** (Mayús+F8), **Ejecutar hasta el
    cursor** (F4), **Pausar** y **Detener** (Ctrl+F2); la línea en curso se
    marca con una flecha amarilla.
  - Pestañas **Variables** (con listas, diccionarios y objetos desplegables),
    **Pila** (con la traza de los errores), **Evaluar** (también
    asignaciones), **Puntos de parada** y cuándo detenerse en las
    **excepciones**.
  - **Historial** de las líneas ejecutadas, **Llamadas** (el flujo de
    funciones con su duración), **Rendimiento** por función y **Objetos**
    vivos de cada clase.
  - **Pruebas**: ejecuta y depura las pruebas de `unittest` de la carpeta
    `tests`, y crea una de ejemplo.
- Manual: capítulo **Depurar** y atajos nuevos.

## 1.0.19 — 2026-11-05

- Componente **Vista HTML** (escritorio y web): HTML escrito por el código,
  con enlaces y formularios `data-action` que llaman al evento **Al pulsar un
  enlace o enviar un formulario** con un `HtmlAction`. Con **Página completa
  (web)** la página entera es la vista: una web normal, con su propio CSS.
  En el escritorio muestra el HTML sencillo con enlaces y formularios.
- **Blog web** y **Tienda web** rehechos como webs de verdad, con diseño
  propio: portada, categorías, buscador, artículos con comentarios y boletín
  en el blog; ofertas, ficha de producto, carrito, pago simulado y
  confirmación en la tienda.
- Los dos traen **cuentas**: crear cuenta, entrar y salir, con contraseñas en
  PBKDF2 con sal y espera tras cinco fallos. La primera cuenta es la de
  administración y ve el **Panel**: entradas, comentarios y papeles en el
  blog; ventas por categoría, pedidos y stock en la tienda, donde cada
  cliente ve sus pedidos en **Mi cuenta**.
- Si a un proyecto le falta un paquete de Python (Flask, el SDK de
  Anthropic, un controlador de base de datos o pystray), el estudio ofrece
  **Instalar** con el pip del mismo Python que lo ejecuta, y después sigue.
- Landing: el carrusel muestra el blog y la tienda tal como se ven en el
  navegador.

## 1.0.18 — 2026-11-05

- **Servidor MCP** para conectar DMarlon Studio con Claude (Ajustes →
  Conectar con Claude): mientras la app está abierta, Claude Code u otro
  cliente MCP puede listar, leer, crear y modificar proyectos (componentes,
  eventos y código), generar el Python, ejecutarlos y leer su salida. Solo en
  este equipo y con token; **Añadir a Claude Code** lo da de alta con un clic.
  Las pestañas abiertas se recargan solas con los cambios.
- Landing: página **Novedades** con el historial de versiones, generada a
  partir de este CHANGELOG; la versión del pie lleva a ella.

## 1.0.17 — 2026-11-05

- Componente **Asistente IA** (escritorio y web): Claude desde el código de
  las apps con el SDK oficial de Anthropic: `ask`, `chat` con memoria,
  `summarize`, `translate`, `classify`, `extract` (JSON con esquema) y sus
  variantes `*_async` sin congelar la ventana. Claude Opus 5.5 por defecto,
  con reintento en otro modelo si los filtros rechazan la petición. Al
  ejecutar desde el estudio recibe la clave de Ajustes por el entorno, y el
  estudio avisa si falta el SDK.
- Ejemplo **Asistente de textos** (también en web).

## 1.0.16 — 2026-11-05

- Componentes **Informe PDF** e **Informe Excel** (escritorio y web): títulos,
  texto, tablas con totales y cabecera en cada página, imágenes JPEG y número
  de página en PDF; libros .xlsx con varias hojas, tipos (números, fechas,
  casillas), cabecera fija con filtro y columnas a medida. Solo la biblioteca
  estándar de Python: no hay que instalar nada. En web se descargan.
- Ejemplo **Informes** (también en web).

## 1.0.15 — 2026-11-05

- Ejemplo **Visor 3D**: cubo, pirámide, esfera y toro dibujados con Python en
  un lienzo (perspectiva, orden por profundidad y luz por cara), giro con el
  ratón, animación, zoom y modo alambre.
- La lista de proyectos se abre en **tarjetas** (se ve el diseño de cada
  uno); la vista de lista se recuerda si se elige.

## 1.0.14 — 2026-11-05

- Landing: solo se anuncian los destinos que ya funcionan, **tkinter** y
  **Flask** (portada, sección «Entornos», dossier y manual).
- El **manual** abre directamente en su primer capítulo, con el índice de
  todos los capítulos al lado (en el móvil, desplegable) y el PDF a mano.

## 1.0.13 — 2026-11-05

- Diseñador: la lista de proyectos es un **explorador paginado** con columnas
  que se ordenan (nombre, tipo, componentes, modificado y carpeta),
  **buscador**, elección de 10, 15, 25 o 50 por página y **menú del botón
  derecho**: sobre un proyecto, abrir, ejecutar, mostrar la carpeta, GitHub,
  presupuesto de IA, duplicar y eliminar; sobre el fondo, **Agregar nuevo ›**
  proyecto de escritorio, proyecto web o abrir carpeta. Sigue habiendo vista
  de tarjetas.
- Botones, menús y etiquetas con esquinas de 6 px en lugar de redondeados.
- Manual y capturas actualizados.

## 1.0.12 — 2026-11-05

- Landing: **carrusel de ejemplos** en la portada con capturas reales del
  estudio (14 ejemplos, en español e inglés), que avanza solo, se pausa y se
  maneja con flechas o con el teclado.
- Hoja de ruta con todos los destinos: tkinter, Flask, Electron + React,
  Next.js, C++ (FLTK), Pascal (Lazarus), Flutter y React Native (también en el
  README y en el manual).
- Corregido el ejemplo **Correo**: su método `run` tapaba el que abre la
  ventana (`TypeError: run() missing 3 required positional arguments`). Una
  prueba nueva impide que un ejemplo redefina métodos de `FormDesign`.
- Diseñador: la cabecera de las tablas ya no se sale cuando las columnas
  suman más que la tabla, y los textos del gráfico usan Helvetica.

## 1.0.11 — 2026-11-05

- Ejemplo **Correo**: recibir por IMAP, leer, responder y enviar por SMTP con
  adjuntos, con la cuenta en la pestaña «Cuenta» y la red en segundo plano.
- Manual ampliado (es/en): pestañas de proyectos, posición de la ventana,
  centrar, copiar entre proyectos, componente Gráfico, lista de ejemplos,
  adjuntos en los chats, presupuesto de IA y GitHub.

## 1.0.10 — 2026-11-05

- Landing: el selector de tema es un interruptor **claro / oscuro** visible
  (luna o sol) que cambia a la primera; hasta el primer clic sigue el tema del
  sistema.

## 1.0.9 — 2026-11-05

- Ejemplo **Ventanas y diálogos**: mensajes (información, aviso, error,
  pregunta Sí/No/Cancelar), pedir un nombre, un número o un color, elegir un
  archivo, una ficha en otra ventana que devuelve el resultado, un diálogo
  modal propio y varias notas no modales a la vez.

## 1.0.8 — 2026-11-05

- Diseñador: componente **Gráfico** (líneas, área, barras y velas) para
  escritorio y web, con leyenda, rejilla, formato de los números, tooltip al
  pasar el ratón y puntos en vivo (`set_series`, `add_point`, `set_candles`).
- Demos nuevas: **Ventas mensuales** (gráfico de líneas, área o barras, con
  modo en vivo) y **Bolsa de valores** (velas, media móvil, volumen y
  cotización en vivo con datos simulados), también en web.

## 1.0.7 — 2026-11-05

- Diseñador: **pestañas de proyectos**. Varios proyectos abiertos a la vez,
  cada uno con sus cambios, deshacer y consola; punto en la pestaña con
  cambios sin guardar; cerrar con ✕ o clic central.
- **Adjuntos** (📎) en los chats de IA: imágenes y archivos de texto o código
  para Claude Code, «Claude implementa» y el Chat con la IA.
- Nueve ejemplos nuevos: **Bloc de notas**, **Agenda**, **Conversor de
  moneda**, **La serpiente** y **Reproductor de música** (escritorio), y
  **CRM web**, **Facturador web**, **Blog web** y **Tienda web**. Guardan sus
  datos en la carpeta del proyecto y funcionan sin configurar nada.

## 1.0.6 — 2026-11-05

- Diseñador, componentes nuevos (escritorio y web): **Cinta de opciones** al
  estilo Office, **Integración API** (REST con autenticación por variables de
  entorno y llamadas en segundo plano), **Icono de bandeja** (pystray),
  **Contraseña**, **Imagen** (se copia a `images/` del proyecto) y los
  diálogos **Abrir** y **Guardar**. La Barra de estado admite un icono.
- La ventana puede abrirse **centrada en la pantalla** (por defecto en las
  nuevas), en su posición por defecto o en una posición manual.
- Botones para **centrar** lo seleccionado en la ventana o en su marco.
- **Copiar componentes entre proyectos**, con el código de sus eventos, por
  el portapapeles del sistema.
- **Presupuesto de IA** por proyecto: gasto en Claude por herramienta,
  modelo y día, con tope mensual o total que avisa o bloquea.
- **GitHub** desde el Diseñador: publicar el proyecto o confirmar y subir.
- La consola del Diseñador y la terminal del Editor se **redimensionan** y se
  **minimizan**.
- Diálogos con esquinas menos redondeadas.
- Ejemplos nuevos: «Editor de notas» y «Consulta API».

## 1.0.5 — 2026-11-05

- Diseñador: componentes nuevos **Menú** (opciones por líneas, submenús con
  sangría, un manejador `Menu1_click(item)`), **Barra de progreso**, **Barra
  de estado** (abajo, a todo el ancho), **Temporizador** (cada N ms, con
  `start`/`stop`) y **Control de páginas** (pestañas; cada componente en su
  página). En escritorio (tkinter) y en web (Flask).
- Ejemplos nuevos: «Cronómetro» y «Ficha de cliente» (también en web). Los
  ejemplos nuevos aparecen en áreas de trabajo ya creadas.
- Corregido `AttributeError: 'Form1' object has no attribute 'root'` cuando el
  código define su propio `__init__`: la ventana se crea antes y el evento
  «Al abrir» se ejecuta después.
- Botón «Copiar la salida» en la consola del Diseñador y en la terminal.
- En los chats, Intro envía y Mayús+Intro salta de línea.

## 1.0.4 — 2026-11-05

- Diseñador: **chat con Claude Code** desplegable a la derecha (botón del
  robot). Usa la sesión de Claude Code del equipo, sin clave de API: edita el
  diseño y el código del proyecto, y el resultado se carga en el Diseñador
  como un paso que se puede deshacer.

## 1.0.3 — 2026-11-05

- Diseñador: ejecutar (▶, F9) en verde y detener (■) en rojo.

## 1.0.2 — 2026-11-05

- Diseñador: la paleta de componentes es ahora una sola barra de iconos,
  sin texto; el nombre y la ayuda salen al pasar el ratón.

## 1.0.1 — 2026-11-05

Primera versión de DMarlon Studio, separada de la app «Código» de ERPSqlite.

- **Diseñador** de ventanas para tkinter (escritorio) y Flask (web), con
  proyectos en carpetas del disco y ejemplos incluidos.
- **Editor** al estilo de VS Code con git, GitHub, terminal y chat con la IA.
- **Bases de datos** (SQLite, PostgreSQL, MySQL/MariaDB, MongoDB), cliente de
  **API**, **FTP** y **Diagramas** de flujo y entidad-relación.
- **Claude implementa**: en el Editor, Claude (API de Anthropic, Claude Opus 5.5)
  explora la carpeta abierta y propone cambios en varios archivos, que se
  revisan con su diff y se aplican. Claude es la IA por defecto.
- Interfaz en **español e inglés** (Ajustes → Idioma).
- Tema claro y oscuro, con botón en la barra lateral.
- Icono propio de la aplicación.
- Landing en Next.js en español (`/`) e inglés (`/en`), con modo oscuro y
  descargas para macOS y Windows.
