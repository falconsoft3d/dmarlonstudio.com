# Cambios

Las versiones se llevan en el archivo `VERSION` y se cambian en todas partes
con `node scripts/version.mjs <versión|patch|minor|major>`.

## 1.0.78 — 2026-11-09

- **Demos de la web: filtro por lenguaje.** En la barra de la página de demos, botones para ver solo las de Python, C++, Pascal, Flutter, HTML, React o Vue, con cuántas hay de cada uno; las secciones que se quedan vacías se ocultan y el filtro va en la dirección (`?tech=cpp`) para poder compartirlo.

## 1.0.77 — 2026-11-09

- **Dominó doble 9: la ventana se agranda, se maximiza y pasa a pantalla completa** (menú Ver o F11; Esc para salir). La mesa se dibuja a escala, sin deformarse, al tamaño de la ventana, y el ratón sigue cayendo en su ficha; lo que sobra queda como borde de madera. La prueba de la ventana juega la mano con la mesa maximizada.

## 1.0.76 — 2026-11-09

- **Dominó doble 9 (Python): un juego de mesa, nuevo ejemplo del estudio y demo para macOS y Windows.** Dominó cubano en una mesa de cuatro: usted y su compañero (enfrente) contra dos rivales que juega la computadora, 10 fichas cada uno y 15 que no se juegan, sale el doble más alto, quien no lleva pasa, dominó (la pareja ganadora se anota todos los tantos que quedan) y tranque (gana quien tenga menos), y partida a 100 o a 200 tantos. La computadora suelta las fichas gordas, se queda con la mano de un número, no le cierra el juego al compañero y pone los números a los que pasaron los rivales. La mesa, las fichas de colores y la cadena, que gira como una serpiente al llegar al borde con los dobles atravesados, se dibujan en un lienzo de tkinter. Sus pruebas juegan cuarenta partidas enteras sin ventana, comprueban que ninguna ficha de la mesa pisa a otra y que la computadora gana a quien juega al azar, y juegan una mano con la ventana oculta (`domino_test.dart`). Las capturas de la web salen del mismo dibujo con Pillow, sin abrir la ventana (`DMS_DOMINO_SHOT`).

## 1.0.75 — 2026-11-09

- **Bajo la Sombra del Malecón (Pascal): una aventura gráfica de investigación, nuevo ejemplo del estudio y demo para macOS y Windows.** La Habana de 2026, en pleno apagón: usted es Mikel, ex-perito judicial, y busca a Ramiro «el Gestor», un mediador del mercado informal que ha desaparecido. Tiene cuatro actos (el Malecón, el puerto, el taller de Yari y Miramar), nueve personajes con su retrato, pistas y objetos en una libreta, una linterna que se gasta al examinar a oscuras, una barra de alerta en el puerto, una clave que descifrar antes de que se caiga la red y tres finales. Tiene el aspecto de los juegos VGA de MS-DOS: una pantalla de 360×220 píxeles con su paleta de 256 colores, dibujada píxel a píxel en código (escenas con tramado, retratos, iconos y letras sacadas de la fuente del sistema sin suavizar) y ampliada tres veces. Sus pruebas internas juegan la partida entera sin ventana, con los tres finales (`pascal_malecon_test.dart`), y las capturas de la web salen del propio juego (`DMS_MALECON_SHOT`).

## 1.0.74 — 2026-11-09

- **Carrera de motos (C++): un juego nativo con FLTK, nuevo ejemplo del estudio y demo para macOS y Windows.** Pista en pseudo-3D como en los arcades (segmentos proyectados con curvas y cuestas, niebla a lo lejos, pianos, escapatorias, grava, gradas, olivos y carteles), la moto que se inclina en las curvas, siete rivales que frenan antes de cada curva, trazan por dentro y adelantan, semáforo de salida, 1, 3 o 5 vueltas, tres dificultades, caídas contra los árboles, clasificación con las diferencias en segundos, minimapa, cuadro de mandos (marcha, velocidad, revoluciones, neumáticos) y récord de vuelta guardado. Todo se dibuja en código, sin imágenes; el Timer del diseño mueve la carrera 60 veces por segundo (6 ms por imagen a 1280×720). Sus pruebas internas corren una carrera entera sin ventana y comprueban que con las teclas del jugador se termina sin caerse (`cpp_racing_test.dart`). Las capturas de la web salen del propio juego, sin abrir la ventana (`DMS_RACING_SHOT`).

## 1.0.73 — 2026-11-09

- **Cada demo de escritorio es una sola aplicación en español y en inglés**, con el menú **Idioma / Language** para cambiarlo: la app se cierra como siempre y se vuelve a abrir en el otro idioma, que queda guardado para todas las demos (la primera vez, el del sistema). En la web hay una sola descarga por sistema (`<demo>-macOS.zip`, `<demo>-Windows.zip`) y en macOS el nombre de la app sale en el idioma del sistema. Las de Python llevan los dos programas y un lanzador; las de Pascal y C++, los dos ejecutables juntos (`scripts/demo-lang`, `scripts/build_demos.py`). Probado en macOS con la calculadora (Python), Odoo sin conexión (Pascal) y el explorador de archivos (C++).

## 1.0.72 — 2026-11-08

- **Odoo sin conexión (Pascal): ventas y compras de principio a fin, también sin conexión.** Productos nuevos (ficha con nombre, referencia interna, precio y coste; en Odoo, un consumible que se vende y se compra), clientes y **proveedores** (casilla «Proveedor» en la ficha), presupuestos y **solicitudes de compra** (nueva página **Compras**), y los pasos de cada pedido con **Confirmar**, **Facturar** y **Registrar pago** (banco o efectivo). Todo se apunta en el equipo y, al sincronizar, Odoo hace los mismos pasos en orden: crea el producto y el contacto, el pedido, lo confirma, crea y publica la factura (o la factura de proveedor, con su fecha) y registra el pago. Cada paso mira antes cómo está en Odoo, así que un envío cortado sigue donde se quedó y reenviarlo no duplica nada. Al descargar se lee de Odoo si cada pedido está facturado o pagado.
- Probado de verdad contra Odoo 18, 19 y 20 (la prueba de `util_pascal_odoo_test.dart` hace la venta y la compra completas, las reenvía como si la respuesta se hubiera perdido y comprueba que Odoo tiene un solo pedido, una factura pagada y un pago).

## 1.0.71 — 2026-11-07

- **Un proyecto con el IDE en cada curso de bases de datos** (página «Proyecto» de cada curso, con la captura del Diseñador, la app funcionando con la tienda del curso, los pasos, el código y el proyecto para descargar y abrir con **Abrir proyecto**): un **Panel de la tienda** de escritorio (Python) con Conexión de datos, Tablas de datos, cifras y un gráfico para SQLite, PostgreSQL, MySQL y MongoDB, y un **Catálogo de la tienda** de Flutter con FalconDatabase (funciona tal cual con el proyecto del curso) y con Firebase. Son también ejemplos del estudio.
- **MongoDB en Conexión de datos**: las Tablas de datos y el código de las ventanas de escritorio leen MongoDB con la misma consulta JSON del módulo Bases de datos (`?` para los parámetros); el estudio ofrece instalar `pymongo`.
- **Firebase en Flutter**: `lib/db.dart` puede usar el emulador de Firestore (nuevo campo en las propiedades de la app).
- **Nueva demo: Explorador de archivos en C++ (FLTK)** al estilo de Windows 7, para macOS y Windows: árbol de carpetas, pestañas, vistas de iconos, lista y detalles, barra de dirección por partes, favoritos, copiar, cortar y pegar con Ctrl/Cmd+C, X y V usando el portapapeles del sistema (entre dos exploradores y con el Finder), papelera, propiedades, buscador y modo claro, oscuro o del sistema. También es un ejemplo del destino C++.
- Los menús de las apps de C++ dibujan sus separadores.

## 1.0.70 — 2026-11-07

- **Curso de FalconDatabase** en la web (/cursos/falcondatabase y /en/courses/falcondatabase): 40 lecciones, básico y avanzado, de la primera consulta a los filtros, la paginación, la columna JSON, insertar, cambiar y borrar, las reglas de acceso, las tablas con dueño, el inicio de sesión, los errores de validación y el cliente de Flutter (`lib/db.dart`) que genera el estudio. Se ejecutan de verdad contra un proyecto de FalconDatabase con la tienda de ejemplo, que se puede leer con su clave pública desde el módulo Bases de datos.
- FalconDatabase: «1 fila en total» en singular. Los mensajes en inglés de MongoDB («Index created…») ya salen traducidos en el curso.

## 1.0.69 — 2026-11-07

- **Curso de Firebase (Cloud Firestore)** en la web (/cursos/firebase y /en/courses/firebase): 40 lecciones, básico y avanzado, de documentos y colecciones a mapas, listas, subcolecciones, consultas de grupo, agregados, desnormalización, paginación, reglas de seguridad y el cliente de Flutter que genera el estudio, con consultas que se ejecutan de verdad en el módulo Bases de datos contra el emulador de Firestore sobre la tienda de ejemplo (`shop.json`).
- **Firebase en el módulo Bases de datos:** `"set": {"hours.close": "22:00"}` cambia solo ese subcampo del mapa (antes lo borraba) y `"where": {"campo": null}` busca los valores nulos (`IS_NULL`; con `neq`, los que no lo son).

## 1.0.68 — 2026-11-07

- **Curso de PostgreSQL** en la web (/cursos/postgres y /en/courses/postgres): 40 lecciones, básico y avanzado, de la primera consulta a `DISTINCT ON`, `RETURNING`, CTE recursivas, funciones de ventana, `FILTER`, `jsonb`, arrays, `generate_series`, vistas materializadas, `EXPLAIN`, `SAVEPOINT`, `ON CONFLICT`, PL/pgSQL, disparadores, enums, dominios y `LATERAL`, con scripts que se ejecutan de verdad en el módulo Bases de datos sobre la tienda de ejemplo (`shop.sql`, PostgreSQL 16).

## 1.0.67 — 2026-11-07

- **Curso de MongoDB** en la web (/cursos/mongodb y /en/courses/mongodb): 40 lecciones, básico y avanzado, de `find` y los operadores de consulta a los arrays, el pipeline de agregación (`$group`, `$unwind`, `$lookup`, `$facet`, `$bucket`, `$graphLookup`), índices únicos y el diseño de documentos, con consultas JSON que se ejecutan de verdad en el módulo Bases de datos sobre la tienda de ejemplo (`shop.json`).

## 1.0.66 — 2026-11-07

- **Curso de MySQL** en la web (/cursos/mysql y /en/courses/mysql): 40 lecciones, básico y avanzado, de la primera consulta a JSON_TABLE, CTE recursivas, funciones de ventana, transacciones, procedimientos con `DELIMITER //`, funciones, disparadores y restricciones CHECK, con scripts que se ejecutan de verdad en el módulo Bases de datos sobre la tienda de ejemplo (`shop.sql`, MySQL 8.4).

## 1.0.65 — 2026-11-07

- **Curso de SQLite** en la web (/cursos/sqlite y /en/courses/sqlite): 40 lecciones, básico y avanzado, con scripts que se ejecutan de verdad en el módulo Bases de datos sobre una tienda de ejemplo que se puede descargar (`shop.sql`). Cada lección enseña su script, el resultado de cada consulta en tablas y la pantalla Bases de datos del estudio.
- **Bases de datos: scripts.** Varias consultas en el editor se ejecutan una tras otra y cada una deja su resultado en una pestaña. Si hay texto seleccionado, solo se ejecuta la selección. Los `;` de las cadenas, los comentarios, los bloques `$$` de PostgreSQL y los disparadores de SQLite no cortan; en MySQL vale `DELIMITER //`. En MongoDB, FalconDatabase y Firebase, un JSON tras otro (con comentarios `//`).
- **Bases de datos: más consultas.** MongoDB: `projection`, `count`, `distinct`, `createIndex`, `indexes` y `drop`, y los errores de escritura (clave duplicada…) ya se ven. FalconDatabase y Firebase: `update` y `delete` con `where`. Firebase: subcolecciones, consultas de grupo, `select`, `offset`, orden por varios campos y `count`, `sum` y `avg`.
- **Bases de datos: mejor resultado.** `CREATE` y demás dicen «Hecho» en vez de «0 filas afectadas»; «1 fila afectada» en singular; fechas como `2024-01-05`; `RETURNING` de SQLite muestra sus filas; los errores de SQLite, con su texto («FOREIGN KEY constraint failed»); los `enum` de PostgreSQL se ven.
- La web: la página de cursos separa **Lenguajes** y **Bases de datos**, y el código en negrita de los textos ya se ve bien.

## 1.0.64 — 2026-11-07

- **Curso de tkinter** (básico y avanzado, 40 lecciones, español e
  inglés): todos los componentes de tkinter y ttk, uno por lección, de la
  primera ventana y las etiquetas a la tabla de datos, las pestañas, los
  menús, los diálogos, el lienzo con un gráfico y una aplicación de
  productos como proyecto. Cada imagen lleva **la ventana de verdad** que
  abre el ejemplo, capturada al ejecutarlo, y cada lección dice qué
  componente de la paleta del destino Escritorio (Python) es.
- Los cursos ya pueden mostrar ventanas: `scripts/courses/tk_run.py` abre
  cada ejemplo, captura sus ventanas (también las secundarias) y las cierra.

## 1.0.63 — 2026-11-07

- **Curso de Go avanzado** (20 lecciones, español e inglés): interfaces,
  switch de tipos, incrustación, errores con `Is`/`As` y `%w`, `defer` y
  `recover`, genéricos, `sort`, goroutines, canales y `select`, grupos de
  trabajadores, `Mutex`, `context`, JSON, comprobaciones con tablas,
  manejadores HTTP con `httptest` y un procesador de pedidos como proyecto.
- **Los 14 cursos, completos**: Python, JavaScript, C, C++, Pascal, Go y
  Dart, básico y avanzado; 280 lecciones en español y en inglés.
- **Portada**: sección de cursos con los siete lenguajes.
- Los ejemplos de Go se compilan sin cgo (`CGO_ENABLED=0`).

## 1.0.62 — 2026-11-07

- **Curso de Pascal avanzado** (20 lecciones, español e inglés): clases y
  propiedades, herencia y métodos virtuales, clases abstractas e
  interfaces, excepciones y `try/finally`, punteros y lista enlazada,
  genéricos (`fgl` y `Generics.Collections`), `TStringList`, tipos
  procedurales, sobrecarga de operadores, recursión, quicksort, `StrUtils`,
  JSON con `fpjson` y un pequeño banco como proyecto: el Object Pascal de
  las aplicaciones de Lazarus del estudio.

## 1.0.61 — 2026-11-07

- **Curso de Dart avanzado** (20 lecciones, español e inglés): clases y
  constructores con nombre y `factory`, miembros privados, herencia,
  interfaces, mixins, extensiones, enums mejorados, genéricos, records,
  patrones y clases selladas, operadores, `Future`, `Stream`, isolates,
  JSON y generadores, con un procesador de pedidos como proyecto: la capa
  de lógica de una app de Flutter.

## 1.0.60 — 2026-11-07

- **Curso de Go básico** (20 lecciones, español e inglés): variables y
  `:=`, constantes, `Printf`, lectura del teclado, `if`, `switch` y `for`,
  arrays, slices y mapas, funciones con varios resultados, errores como
  valores, estructuras, métodos y punteros, `strings` y `strconv`, `range`,
  archivos y el inventario de una tienda como proyecto: el lenguaje del
  servidor del destino Web (Go) del estudio.

## 1.0.59 — 2026-11-07

- **Curso de Dart básico** (20 lecciones, español e inglés): `var`,
  `final` y `const`, números, cadenas e interpolación, lectura del teclado,
  `if` y expresiones `switch`, bucles, listas, conjuntos y mapas, funciones
  y parámetros con nombre, seguridad frente a `null`, métodos de colecciones,
  excepciones, archivos y un carrito de la compra como proyecto: la base de
  las apps de Flutter que diseña el estudio.

## 1.0.58 — 2026-11-07

- **Curso de C avanzado** (20 lecciones, español e inglés): punteros a
  punteros, `malloc`/`realloc`/`free`, cadenas a fondo, `const`, punteros a
  funciones, `qsort` y `bsearch`, lista enlazada, pila y cola, árbol
  binario, tabla hash, uniones y campos de bits, operadores de bits, el
  preprocesador, funciones variádicas, `errno`, archivos binarios,
  vuelta atrás y un gestor de inventario como proyecto. Sin fugas de memoria.

## 1.0.57 — 2026-11-07

- **Curso de Pascal básico** (20 lecciones, español e inglés): `WriteLn` y
  `ReadLn`, tipos, `div` y `mod`, formatos, `if` y `case`, bucles, arrays
  estáticos y dinámicos, cadenas, procedimientos y funciones, parámetros
  `var` y `const`, registros, enumerados y conjuntos, archivos de texto y la
  factura de una tienda como proyecto. Compilado con Free Pascal, como las
  aplicaciones de Lazarus del estudio.

## 1.0.56 — 2026-11-07

- **Curso de C++ avanzado** (20 lecciones, español e inglés): clases y
  encapsulación, herencia y polimorfismo, sobrecarga de operadores, RAII,
  punteros inteligentes, mover y copiar, plantillas, lambdas, algoritmos e
  iteradores de la STL, `optional`/`variant`, `enum class`, excepciones
  propias, `std::function`, `constexpr` y un editor de formas como proyecto.

## 1.0.55 — 2026-11-07

- **Curso de C++ básico** (20 lecciones, español e inglés): `cout` y
  `cin`, tipos y `auto`, `<cmath>`, `std::string`, decisiones y bucles,
  `std::vector` y `sort`, funciones, referencias, sobrecarga, `std::map`,
  pares y enlaces estructurados, `<iomanip>`, excepciones, archivos y un
  carrito de la compra como proyecto. Cada ejemplo, compilado en C++17 y
  ejecutado de verdad, con su salida y su imagen en DMarlon Studio.

## 1.0.54 — 2026-11-07

- **Curso de C básico** (20 lecciones, español e inglés): `printf` y
  `scanf`, tipos, operadores, decisiones y bucles, arrays, cadenas,
  funciones y prototipos, ámbito y `static`, punteros, estructuras,
  enumeraciones, archivos de texto y un cuaderno de notas como proyecto.
  Cada ejemplo, compilado con `-Wall` y ejecutado de verdad, con su salida y
  su imagen en DMarlon Studio.

## 1.0.53 — 2026-11-07

- **Curso de Python avanzado** (20 lecciones, español e inglés):
  comprensiones, `*args`/`**kwargs`, lambdas, clausuras, decoradores,
  generadores, iteradores, clases, herencia, métodos especiales,
  dataclasses, enumeraciones y `match`, excepciones propias y `with`, tipos y
  genéricos, `collections`, `itertools`/`functools`, recursividad, JSON y
  expresiones regulares, `asyncio` y un inventario con pruebas como
  proyecto. Cada ejemplo, con su salida real y su imagen en DMarlon Studio.

## 1.0.52 — 2026-11-07

- **Curso de JavaScript avanzado** (20 lecciones, español e inglés): ámbito
  y clausuras, `this`, prototipos, clases y campos privados, iteradores y
  generadores, Map/Set, composición y memoización, promesas y async/await,
  el bucle de eventos, módulos, errores propios, expresiones regulares,
  Proxy, EventEmitter y una cola de pedidos como proyecto. Cada ejemplo, con
  su salida real y su imagen en DMarlon Studio.

## 1.0.51 — 2026-11-07

- **Cursos** (menú nuevo de la web, en español e inglés): un curso por cada
  lenguaje del estudio, básico y avanzado, de 20 lecciones. Cada lección es
  un programa completo que se ha ejecutado de verdad, con su explicación, su
  salida real, la imagen del código y la salida en DMarlon Studio, un
  ejercicio y cómo probarlo en el estudio. Ya están **Python básico** y
  **JavaScript básico**; los demás llegan en las versiones siguientes.
- **500 iconos de aplicación** en el estudio: cada proyecto con ventana lleva
  uno sin hacer nada, elegido por las palabras del nombre (en español o en
  inglés) y con un color fijo para ese nombre; si cambia el nombre, el icono
  lo sigue. **Galería…** los muestra con un buscador y 12 colores; el que se
  elige se queda. **Automático** vuelve al del estudio.
- **Demos**: la de Pascal (Odoo sin conexión) ya no se cierra al tocar un
  campo de texto en macOS, y cada demo lleva su icono en la .app y en el .exe.
- Las demos de macOS se pueden firmar con Developer ID y notarizar en CI
  (`scripts/mac-signing-secrets.sh`): en cuanto estén los secretos, abren sin
  avisos.

## 1.0.50 — 2026-11-06

- **Manual**: sección nueva «Ejemplo: Odoo sin conexión y obras BIM» en el
  capítulo de Pascal (español e inglés), con su captura, los pasos para
  hacer una obra y su presupuesto por conceptos, los atajos del árbol y
  cómo se calculan los importes y se evitan los duplicados.
- **Página de la demo** «Odoo sin conexión»: el tercer paso son ahora los
  presupuestos de obra de BIM 2.0, con su captura; la tarjeta lo dice.
- En inglés, «Project» ya no se monta sobre la lista de obras.

## 1.0.49 — 2026-11-06

- **Obras BIM, como el árbol de conceptos de BIM 2.0** (su manual): a la
  izquierda el árbol con ⊞/⊟ y el icono de cada tipo (capítulo, partida,
  material, mano de obra, equipo, subcontrata), «[código] nombre»; a la
  derecha lo que hay dentro de lo elegido con Código, Nombre, Cantidad,
  Costo, Saldo y «Detalle», los recursos en cursiva y la fila de totales;
  arriba, la obra y el presupuesto, el botón «+», el de inicio, la ruta
  (Presupuestos / … › Concepto) y «UPD · Enviar a Odoo».
- Los atajos de BIM: N añade un hijo, Mayús + N al mismo nivel, Supr
  elimina, Intro abre, U envía y E / Mayús + E abre o cierra todo.
- Probado de verdad contra Odoo 18 (todo, también el punto de venta) y 20
  con BIM 2.0.

## 1.0.48 — 2026-11-06

- **Obras BIM en «Odoo sin conexión» (Pascal)**: si Odoo tiene BIM 2.0
  (`base_bim_2`), una página nueva para crear **obras y presupuestos por
  conceptos** también sin conexión: capítulos, partidas y recursos (mano de
  obra, equipo, material, subcontrata y función) con cantidad, precio y
  unidad, y los importes calculados como en BIM (recurso = cantidad × precio;
  partida = su cantidad × la suma de sus recursos; capítulo = la suma).
  «Guardar y enviar a Odoo» sube la obra, el presupuesto y su árbol, en
  orden, y pide a BIM que recalcule (UPD). **Sin duplicados**: la referencia
  DMS-… va en las observaciones de la obra, en el origen del presupuesto y en
  el «id_import» de cada concepto, y un envío cortado sigue donde se quedó.
  Los presupuestos de Odoo se ven en el mismo árbol. Probado contra Odoo 20
  con BIM 2.0.
- Las lecturas se repiten solas si el servidor (o su proxy) responde 502, 503
  o 504; las escrituras no, y se reintentan al sincronizar sin duplicar.
- El origen de las ventas del punto de venta llegaba a Odoo mal codificado
  («TPV Â· Tarjeta»): ahora «TPV · Tarjeta».

## 1.0.47 — 2026-11-06

- **Odoo sin conexión (Pascal)**, decimotercera demo de escritorio: se
  descarga ya compilada para macOS (Apple Silicon e Intel) y Windows desde la
  página Demos, con su página de cómo funciona en tres capturas (panel, venta
  sin conexión y sincronización).
- **Odoo 8**, probado de verdad: la entrega del punto de venta se valida con
  `do_transfer` (la 8 no tiene `do_new_transfer`). Ya van de Odoo 8 a 20.
- La prueba contra Odoo vende productos que se entregan (no servicios).
- La página de la tienda de Flutter enseña el carrito en su tercer paso.

## 1.0.46 — 2026-11-06

- **Una página por demo** (`/demos/<demo>`, en español y en inglés): qué es,
  sus botones de descarga o de prueba, lo que demuestra y **cómo funciona en
  tres pasos con su captura**. Las 18 demos de la web la tienen, enlazada
  desde su tarjeta («Cómo funciona»), con la anterior y la siguiente.
- **Odoo sin conexión (Pascal)**, ejemplo nuevo de Lazarus: panel de ventas
  con indicadores y gráficos, clientes, productos, presupuestos y un **punto
  de venta** que crea en Odoo el pedido confirmado, la entrega validada y la
  factura publicada. Trabaja con y sin conexión y sincroniza sin duplicados,
  retomando cada venta donde se quedó. Probado contra Odoo 9 a 20 por JSON-RPC
  (las rutas del cliente web); con OpenSSL dentro de la app.
- El botón de pago de la tienda decía «Payable» en inglés: ahora «Pay».

## 1.0.45 — 2026-11-06

- **Seguimiento de trenes**, ejemplo y duodécima demo de escritorio: los
  trenes de Cercanías y Rodalies en directo con los datos abiertos de Renfe
  (GTFS y GTFS-Realtime, licencia CC BY 4.0). Sitúa cada tren en su línea,
  avisa cuando dos de la misma línea y sentido se acercan (distancia y
  tiempo, umbrales configurables) o cuando uno se para fuera de una
  estación, y dibuja la malla de circulación y el mapa de la línea. Sin
  conexión, una simulación con estaciones reales. Demo educativa: no es un
  sistema de seguridad, y lo dice.

## 1.0.44 — 2026-11-06

- **Demos móviles y web** en la página Demos, que se prueban sin instalar
  nada:
  - **Móvil**: la tienda con login, los envíos y las tareas de Flutter,
    compiladas para el navegador y abiertas dentro de un teléfono, y como
    **APK de Android** (lo compila GitHub Actions).
  - **Web**: la misma tienda en **HTML**, **React** y **Vue**, publicada en
    la propia web.
  - `scripts/build_live_demos.py` las compila; la página tiene secciones
    Escritorio, Móvil y Web.
- **Reproductor MP3**, ejemplo y undécima demo de escritorio: reloj
  digital, analizador de espectro, título que se desplaza, kbps y kHz, lista
  de reproducción con listas M3U y etiquetas ID3 leídas sin bibliotecas; el
  sonido, con `pygame`.
- El carrusel de la portada lleva el logotipo también en los ejemplos nuevos.
- CI: las pruebas que fallan salen como anotaciones con su error.

## 1.0.43 — 2026-11-06

- **Demos para descargar** en la web (menú **Demos**, dmarlonstudio.com/demos):
  diez utilidades hechas con el estudio y compiladas para **macOS y
  Windows**, en español y en inglés (en macOS se abren siempre en claro), para enseñar lo que se puede hacer con
  él: calculadora, bloc de notas, editor de PDF, espacio en disco, escáner de
  puertos, inversor de bolsa, punto de venta, agenda, conversor de moneda y
  renombrar archivos. Cada una tiene su captura con el logotipo de su
  tecnología y lo que demuestra. Las compila GitHub Actions
  (`.github/workflows/demos.yml`): el estudio exporta cada ejemplo y
  `scripts/build_demos.py` lo empaqueta con PyInstaller; los paquetes de pip
  que necesite se declaran en el código con `REQUIRES = [...]`.
- **Seis ejemplos nuevos** de escritorio (tkinter):
  - **Editor de PDF** (con `pypdf`): girar, borrar, mover, duplicar, insertar
    otro PDF, extraer, dividir, propiedades, sello de texto, contraseña y
    deshacer.
  - **Espacio en disco**: un mapa del disco al estilo de WinDirStat
    (rectángulos por tamaño y colores por tipo, con zoom), árbol de
    carpetas, los 100 archivos más grandes y totales por tipo; análisis en
    segundo plano y «Mostrar en la carpeta», «Abrir» y «Mover a la
    Papelera» (nunca borra para siempre).
  - **Escáner de puertos**: conexiones TCP en paralelo con progreso,
    servicio y cabecera de cada puerto, y exportación a CSV.
  - **Inversor de bolsa (demo)**: empresas ficticias con precios simulados
    en vivo, compra y venta con comisión, cartera, órdenes y gráfico.
  - **Punto de venta** al estilo del de Odoo: productos con imagen (se puede
    cambiar), categorías, teclado de cantidad, descuento y precio, cobro con
    cambio, ticket y pedidos del día en SQLite. Se conecta a **Odoo** con
    URL, usuario y contraseña (la sesión del cliente web): descarga los
    productos con su precio e imagen y crea y confirma los pedidos en Ventas;
    sin conexión los deja pendientes y los envía después, sin duplicarlos.
  - **Renombrar archivos**: reglas encadenadas, vista previa con conflictos,
    intercambios seguros y deshacer.
- **Portada**: las capturas del carrusel de Flutter, React Native, Next.js,
  C++, Pascal y consola no se veían (eran PNG y se pedían en JPEG); ahora
  `scripts/build-docs.mjs` convierte también las del carrusel y las de las
  demos. Cada captura lleva el logotipo de su tecnología.

## 1.0.42 — 2026-11-06

- **Web (Vue)** con el editor de pantallas: las mismas pantallas y la misma
  lógica que las otras webs, pero cada pantalla es un componente `.vue` con
  su plantilla (`v-for`, `v-if`, `@click`). Web de una sola página con Vue y
  Vite (rutas tras `#`), publicable como archivos estáticos en cualquier
  hosting. Vite y Vue se instalan solos la primera vez, compartidos con
  React. Ejemplo **Tienda web (Vue)**: se compila con Vite y se recorre en
  Chrome de verdad en cada versión.
- **Web (Go)** con el editor de pantallas: las mismas pantallas y la misma
  lógica, servidas por un servidor de Go (solo la biblioteca estándar) con
  una API REST que guarda los datos en archivos JSON (`api.list`, `api.add`,
  `api.update`, `api.remove`). `go build` deja un solo ejecutable con la web
  dentro. Ejemplo **Tienda web (Go)**: los pedidos se guardan en el
  servidor; se recorre en Chrome de verdad y los datos siguen al reiniciar.
- El manual en PDF vuelve a incluir los capítulos nuevos (React Native,
  React, HTML, Vue y Go).

## 1.0.41 — 2026-11-06

- **Web (HTML)** con el editor de pantallas: las mismas pantallas y la misma
  lógica que Next.js y React, en HTML, CSS y JavaScript sin nada más (sin
  compilar, sin Node.js ni dependencias). Ejecutar la sirve con un servidor
  propio del estudio y se recarga al guardar; Exportar deja la carpeta lista
  para abrir `index.html` o subirla a cualquier hosting. Ejemplo **Tienda
  web (HTML)**: se recorre en Chrome de verdad en cada versión.
- Webs con pantallas: las tarjetas de una lista se separan como en Flutter.

## 1.0.40 — 2026-11-06

- **Web (React)** con el editor de pantallas: las mismas pantallas y la
  misma lógica que Next.js, como web de una sola página con React y Vite
  (rutas tras `#`), publicable como archivos estáticos en cualquier hosting.
  Vite se instala solo la primera vez. Ejemplo **Tienda web (React)**: se
  compila con Vite y se recorre en Chrome de verdad en cada versión.

## 1.0.39 — 2026-11-05

- **React Native (móvil)** con el editor de pantallas: las mismas pantallas,
  menú y plantillas que Flutter, generadas con los componentes de React
  Native (Expo) y la lógica en JavaScript (`lib/app.js`). Ejecutar arranca
  Expo y la abre en el simulador de teléfono del estudio (se recarga al
  guardar) y da la dirección para verla en el teléfono con Expo Go. React
  Native y Expo se instalan solos la primera vez, compartidos por todos los
  proyectos.
- Ejemplo **Tienda (React Native)**: se exporta y se recorre en Chrome de
  verdad en cada versión.

## 1.0.38 — 2026-11-05

- **Web (Next.js) con el editor de pantallas**: el mismo editor que Flutter
  (pantallas, árbol de widgets, propiedades, menú y las 20 plantillas)
  genera una web de verdad: cada pantalla es una página de React con HTML y
  CSS adaptables (contenido centrado en escritorio; menú lateral o barra de
  abajo según el ancho). La lógica va en `lib/app.js`. En el editor, la
  vista previa se ve en escritorio o en móvil.
- Ejemplo **Tienda web (Next.js)**: login, catálogo, ficha, carrito y pago.
  Se compila con `next build` y se recorre en Chrome de verdad en cada
  versión.
- Las mismas pantallas valen para Flutter y para la web (`.isEmpty` y
  `.isNotEmpty` se traducen), y en la web un botón dentro de una tarjeta ya
  no abre también la tarjeta.
- Los proyectos de Next.js anteriores siguen como «Web (Next.js,
  formulario)».

## 1.0.37 — 2026-11-05

- **Flutter (escritorio)**: el mismo editor al estilo de FlutterFlow, con la
  vista previa en una ventana de macOS. Ejecutar abre la app en su ventana
  nativa (macOS, Windows o Linux) y al guardar se recarga en caliente.
- **Menú de la app** (Pantalla|icono|texto): barra lateral en ventanas
  anchas y barra de abajo en las estrechas, en escritorio y en móvil.
- Ejemplo **Inventario (Flutter escritorio)**: panel con cifras y avisos de
  poco stock, productos con búsqueda, ficha con existencias y alta. Su
  recorrido se prueba en cada versión, y la app de escritorio se abre de
  verdad en su ventana y se recarga.

## 1.0.36 — 2026-11-05

- Flutter: **+** en Pantallas abre una galería con las **20 pantallas más
  usadas** (inicio de sesión, registro, recuperar contraseña, bienvenida,
  inicio, lista, detalle, perfil, editar perfil, ajustes, notificaciones,
  mensajes, conversación, búsqueda, carrito, pago, pedido confirmado, panel,
  contacto y ayuda) o una en blanco, con la vista previa real en el color de
  la app. Las 20 juntas compilan sin avisos.

## 1.0.35 — 2026-11-05

- **Flutter con FalconDatabase y Firebase**: en las propiedades de la app,
  Base de datos → Conectar con. El estudio genera `lib/db.dart`, la misma
  forma para los dos: `db.signIn`, `db.table('t').list/get/insert/update/
  delete` y `DbError`. Probado contra FalconDatabase de verdad (tablas,
  login, tabla con acceso solo con sesión); el de Firebase compila sin
  avisos y queda pendiente de probar con un proyecto real.
- Ejemplo **Notas en la nube (Flutter + FalconDatabase)**: login y notas en
  una tabla de FalconDatabase.
- Flutter: las acciones pueden esperar (`if (await app.entrar())
  home:Notas`).

## 1.0.34 — 2026-11-05

- Ejemplo de Flutter **Tienda con login**: entrar (con aviso si la clave es
  mala), catálogo con búsqueda y categorías, ficha de producto, carrito con
  cantidades y total, pago y salir. Su recorrido completo se prueba en cada
  versión dentro de la app generada.
- Flutter: las pantallas abiertas se vuelven a dibujar en cuanto App avisa
  de un cambio (antes, a veces, una lista no se actualizaba al quitar un
  filtro).
- Flutter: acciones con condición (`if (app.entrar()) home:Catalogo`),
  `home:Pantalla` para empezar de nuevo desde una pantalla, botones en la
  barra superior con insignia (el carrito con su cantidad) y filas que
  pasan a varias líneas si no caben.

## 1.0.33 — 2026-11-05

- **Apps móviles con Flutter**, al estilo de FlutterFlow: la pestaña Diseño
  tiene las pantallas y el árbol de widgets a la izquierda, la paleta y un
  teléfono con la vista previa en el centro, y las propiedades a la derecha.
  Los widgets se enlazan con la lógica de `lib/app.dart` (una clase `App`):
  textos con `${…}`, expresiones con `=` y acciones como `app.agregar()`,
  `go:Detalle(item)` o `back`.
- **Simulador del estudio**: Ejecutar compila la app con Flutter para la web
  y la abre dentro de un marco de teléfono (iPhone, Pixel, Galaxy o iPad
  mini, girable), sin Xcode ni Android. Al guardar se vuelve a compilar y se
  recarga solo.
- Dos demos: **Envíos** (resumen por estado, lista con filtro, detalle con
  seguimiento y alta) y **Tareas** (con filtros, guardadas en el teléfono).
- Ayuda (F1) y autocompletado de Dart; exportar el proyecto de Flutter.
- Web y manual: Flutter entre los entornos, con su capítulo.

## 1.0.32 — 2026-11-05

- **Aplicaciones de consola** en Python, C, C++ y Pascal: un programa sin
  ventana en un solo archivo (`main.py`, `main.c`, `main.cpp` o `main.pas`).
  Ejecutar compila si hace falta (Pascal con Free Pascal, sin Lazarus) y lo
  que escribe el programa sale en la pestaña Salida; cuando pide algo, se
  responde en el campo de abajo y la respuesta queda detrás de la pregunta,
  como en un terminal.
- Ejemplos de consola: **Gestión de animales** (altas, bajas y vacunas, con
  las próximas dosis y las pendientes, guardado en `animales.json`) y
  **Adivina el número** en los cuatro lenguajes.
- El ejemplo de C++ ya no da el aviso de `show()` al compilar.
- Web y manual: la consola entre los entornos.

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
