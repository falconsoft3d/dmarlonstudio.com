# Cursos de la web (/cursos)

Siete lenguajes (los que usa DMarlon Studio), cada uno con un curso **básico**
y uno **avanzado** de 20 lecciones. Cada lección es un programa completo que
se ejecuta de verdad: su salida y su imagen (el código y la salida en una
ventana de DMarlon Studio) las genera `scripts/build-courses.mjs`.

Los cursos son también escaparate del IDE: cada página lleva cómo probar el
ejemplo en DMarlon Studio y el enlace de descarga (eso lo pone la plantilla;
la lección no tiene que repetirlo).

## Carpetas

```
content/courses/<curso>/<nivel>/<NN>-<slug-en-inglés>/
  main.<ext>     el programa (py, js, c, cpp, pas, go, dart)
  lesson.json    los textos en español e inglés
  input.txt      solo si el programa lee del teclado (stdin)
```

`<curso>`: python, javascript, c, cpp, pascal, go, dart. `<nivel>`: basic o
advanced. `NN`: 01 a 20, sin huecos.

## main.<ext>

- Un programa completo y corto: **34 líneas como mucho** (es lo que cabe en la
  imagen; si pasa, la imagen corta y pone «⋯ more lines»). Mejor 12–30.
- El código, sus nombres, sus comentarios y lo que escribe, **en inglés** (es
  el mismo programa para la página en español y en inglés). Comentarios
  breves, solo donde ayudan.
- **Determinista**: la misma salida siempre (el script lo ejecuta dos veces y
  lo comprueba). Nada de la hora o la fecha actual, azar sin semilla, red,
  rutas absolutas ni hilos que escriban en orden variable.
- Que escriba algo que enseñe el resultado: la salida es la mitad de la
  imagen. 3–14 líneas de salida es lo ideal (se ven 14).
- Si lee del teclado, `input.txt` lleva lo que se teclearía. Pocas lecciones:
  la mayoría trabaja con datos del propio programa.
- Que termine bien (código de salida 0). Si enseña un error, que lo capture y
  lo muestre.

Versiones con las que se ejecuta (no use nada más nuevo):

| Curso | Orden | Versión |
|---|---|---|
| python | `python3 -I main.py` | 3.12+ (vale `match`, f-strings, `dataclasses`) |
| javascript | `node main.js` | Node 22+, CommonJS (sin `import` ni `await` de primer nivel; `async function main()` sí) |
| c | `cc -std=c11 -Wall -O1 main.c -lm` | C11, sin avisos |
| cpp | `c++ -std=c++17 -Wall -O1 main.cpp` | C++17, sin avisos |
| pascal | `fpc -Mobjfpc -Sh main.pas` | Free Pascal 3.2.2 (`program main;`, units de la RTL/FCL como SysUtils, Classes, fgl, Math, StrUtils) |
| go | `go run main.go` | **Go 1.19**: sin `min`/`max` incorporados, sin paquetes `slices`/`maps`, sin `range` sobre enteros |
| dart | `dart run main.dart` | Dart 3 (records, patrones, sealed) sin paquetes externos |

## lesson.json

```json
{
  "es": {
    "slug": "hola-mundo",
    "title": "Hola, mundo",
    "summary": "Una o dos frases (máximo 160 caracteres): la descripción para Google.",
    "body": ["Párrafo 1", "Párrafo 2", "Párrafo 3"],
    "points": ["Idea clave 1", "Idea clave 2", "Idea clave 3"],
    "exercise": "Un reto para practicar, que se pueda hacer cambiando el ejemplo."
  },
  "en": { "...": "lo mismo en inglés, con su propio slug" }
}
```

- `slug`: en el idioma de la página, en minúsculas con guiones, único dentro
  del nivel.
- `title`: corto (2–6 palabras), sin número ni nombre del lenguaje.
- `summary`: dice qué se aprende y con qué lenguaje; a veces, de forma
  natural, que se prueba en DMarlon Studio. Máximo 160 caracteres.
- `body`: 3–5 párrafos que explican el ejemplo **línea a línea o idea a
  idea**, refiriéndose al código de verdad. Con `**negrita**` para los
  términos que se presentan y `` `código` `` para nombres, órdenes y valores.
- `points`: 3–5 frases cortas (lo que hay que recordar).
- `exercise`: uno, concreto.
- El español, de usted y de España (como el resto de la web): «pulse»,
  «escriba», «ordenador». El inglés, natural, no traducido palabra a palabra.

## Comprobar y generar

Desde `landing/`:

```sh
node scripts/build-courses.mjs python --level=basic --check   # ejecuta y comprueba, sin escribir
PLAYWRIGHT_DIR=<carpeta con node_modules/playwright> node scripts/build-courses.mjs python   # datos e imágenes
```

`--check` debe terminar en «Listo» sin problemas. La segunda orden escribe
`content/courses/data/<curso>.json` (lo que leen las páginas) y las imágenes en
`public/courses/<curso>/`.

## tkinter (ventanas)

El curso `tkinter` no muestra la salida de la terminal sino **la ventana de
verdad**: `scripts/courses/tk_run.py` ejecuta el ejemplo con un Python que
tenga Tk (`brew install python-tk@3.12`; o `DMS_TK_PYTHON=<python>`), la deja
en aspecto claro, la captura con `screencapture -l` (cada ventana del
proceso, también las `Toplevel`) y la cierra. Solo funciona en macOS.

- La ventana tiene que **enseñar el componente en un estado con sentido nada
  más abrirse** (nadie hace clic al capturarla): campos rellenos, una fila
  elegida, la barra de progreso a medias, una pestaña con contenido…
- `root.geometry("ANCHOxALTO")` siempre, entre 360×220 y 760×520 (es lo que
  cabe bien en la imagen).
- Nada de diálogos modales al arrancar (`messagebox`, `filedialog`): solo
  desde un botón. Las ventanas secundarias (`Toplevel`) sí se capturan.
- Sin imágenes de archivo: las imágenes se crean en el código
  (`tk.PhotoImage` con `put`, o dibujadas en un `Canvas`).
- `ttk` siempre que exista el componente (Label, Button, Entry, Combobox…);
  `tk` para Text, Listbox, Canvas, Menu y Message.
- Puede escribir en la terminal (`print`) desde un evento, pero no hace falta:
  si no escribe nada, la página no muestra el panel de salida.

Comprobar sin capturar: `node scripts/build-courses.mjs tkinter --level=basic --check`
(abre y cierra cada ventana en un momento).

## Bases de datos (sqlite, postgres, mysql, mongodb, falcondatabase, firebase)

Cada lección es un **script del módulo Bases de datos** del estudio: varias
consultas que se ejecutan una tras otra, como al pulsar **Ejecutar** (⌘↵)
en el estudio. Las ejecuta `studio/tool/db_course.dart`, que usa el mismo
cliente que el estudio (`studio/lib/dev/`): lo que sale en la página es lo
que sale en el estudio. La imagen es la pantalla Bases de datos con el script
y la rejilla del **último resultado con filas** (los demás, en pestañas); la
página enseña todos.

```
content/courses/<curso>/seed.sql | seed.json   los datos del curso (la tienda)
content/courses/<curso>/<nivel>/<NN>-<slug>/
  main.sql | main.json   el script
  lesson.json            los textos (como arriba) y, si hace falta:
                         "error": true  → la última consulta falla a propósito
                         "seed": false  → sin los datos del curso
                         "as": "ana" | "luis" | "anon"  (solo FalconDatabase)
```

Antes de cada lección la base de datos se vacía y se cargan los datos del
curso (`seed.*`, generados por `scripts/courses/make_seeds.py`; la misma
tienda en todas: `categories`, `products` (con `tags`), `customers`, `orders`,
`order_items`, `employees` (con `manager_id`) y `reviews`). La lección puede
crear sus propias tablas o colecciones.

- **34 líneas como mucho** (mejor 8–25). Código, nombres y comentarios en
  inglés. En SQL, `--` para comentar; en JSON, `//` (una línea).
- **Determinista**: `ORDER BY` / `sort` / `order` siempre que salga más de una
  fila; nada de `now()`, `random()`, `CURRENT_DATE` sin fijar…
- El resultado que se ve en la imagen (el último con filas): **12 filas y 6
  columnas como mucho**, con valores cortos. Elija las columnas.
- La última consulta debe ser la que enseña el resultado de la lección.
- En el texto, refiérase al estudio cuando venga a cuento: **Ejecutar**
  (⌘↵), una pestaña por consulta, ejecutar solo la selección, la lista de
  tablas a la izquierda (doble clic → consulta de ejemplo), **CSV**.

Comprobar (sin imágenes): `node scripts/build-courses.mjs <curso> --level=basic --check`.
Hacen falta los servidores: `sh scripts/courses/db_servers.sh start` (MySQL
8.4 en 3407, MongoDB 4.4 en 27027 y el emulador de Firestore en 8095) y un
PostgreSQL (`DMS_COURSE_PG=host:puerto:usuario:clave`, por defecto
`localhost:5434:<usuario>:`). FalconDatabase usa el proyecto del curso
(`~/.config/dmarlonstudio/course-falcon.json`: referencia, clave anon y sus
usuarios).

### Qué devuelve cada base de datos

| Curso | Versión | Notas |
|---|---|---|
| sqlite | SQLite 3.4x | JSON (`json_extract`, `json_each`), ventanas, CTE, `RETURNING`, `UPSERT`, `STRICT`, columnas generadas, disparadores (`BEGIN … END;`) |
| postgres | PostgreSQL 16 | Funciones con `$$ … $$`. `numeric` sale como texto (`"1.20"`), las fechas `2024-01-05`, `json`/arrays como JSON. `RAISE NOTICE` no se ve: devuelva el dato con `SELECT` |
| mysql | MySQL 8.4 | Procedimientos y disparadores con `DELIMITER //` … `DELIMITER ;`. Todos los valores salen como texto. **Los `SELECT` de dentro de un `CALL` no se ven**: use parámetros `OUT` (`CALL p(@x); SELECT @x;`). `ONLY_FULL_GROUP_BY` activo |
| mongodb | MongoDB 4.4 | Sin `$setWindowFields` ni `$dateTrunc` (5.0+). Las fechas son texto `"2024-03-01"` |
| falcondatabase | API REST | Sin joins (dos consultas). La tienda no se vacía: se **restaura** (sus `id` son siempre 1…N, como en los datos) con el usuario del curso, y las notas de cada usuario se vacían con su sesión. Los `id` de las filas que inserta la lección los pone el servidor: no los use (filtre con `where`) |
| firebase | Emulador de Firestore 1.19 | Los `_id` de los datos son de texto (`p01`, `c1`, `o01`, `cat1`, `e1`, `r1`) |

### Las consultas JSON (mongodb, falcondatabase, firebase)

Un objeto por consulta, uno tras otro (con comentarios `//`):

- **mongodb** — `"collection"` y una de: `"find": {filtro}` (con
  `"projection"`, `"sort"`, `"limit"`, `"skip"`), `"aggregate": [pipeline]`,
  `"insert": {…} | [{…}]`, `"update": [filtro, cambio]` (updateMany),
  `"delete": {filtro}` (deleteMany), `"count": true` (con `"find"`),
  `"distinct": "campo"` (con `"find"`), `"createIndex": {claves}` (con
  `"unique"`, `"name"`), `"indexes": true`, `"drop": true`.
- **falcondatabase** — `"table"` y: `"where": {"col": "op.valor"}`
  (`eq neq gt gte lt lte like ilike is in`, p. ej. `"in.(1,2)"`,
  `"is.null"`, `"ilike.%tea%"`; sin operador es `eq`), `"order":
  "price.desc,name"`, `"limit"`, `"offset"`, `"select": "id,name"`;
  `"insert": {…} | [{…}]`; `"update": {"id": 1 | "where": {…}, "set": {…}}`;
  `"delete": 1 | {"where": {…}}`. Al listar dice cuántas filas hay en total.
  Cada consulta es una petición REST (`GET /api/v1/<ref>/tables/products?price=gte.10&order=price.desc`)
  y lo mismo que `db.table('products').list(where: {...}, order: ...)` en el
  `lib/db.dart` que el estudio genera para Flutter. Las tablas son de
  lectura pública y escritura con sesión; `notes` es «owner» (cada usuario ve
  solo sus filas, `owner_id` lo pone el servidor). Usuarios: `course` (por
  defecto, con sesión), `ana`, `luis` y `anon` (sin sesión: leer sí,
  escribir da error).
- **firebase** — `"collection"` (también una subcolección:
  `"orders/o01/notes"`) y: `"where": {"campo": valor | {"op": valor}}`
  (`eq neq gt gte lt lte in nin contains containsAny`; campos anidados con
  punto), `"order": "price desc, name"`, `"limit"`, `"offset"`,
  `"select": "name,price"`, `"group": true` (consulta de grupo en todas las
  subcolecciones con ese nombre), `"id": "p01"` (un documento);
  `"count": true`, `"sum": "campo"`, `"avg": "campo"` (una fila con el
  agregado); `"insert": {…} | [{…}]` (con `"_id"` para elegir el id);
  `"update": {"id": "p01" | "where": {…}, "set": {…}}`;
  `"delete": "p01" | {"where": {…}}`.
