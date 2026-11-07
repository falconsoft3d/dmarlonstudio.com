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
