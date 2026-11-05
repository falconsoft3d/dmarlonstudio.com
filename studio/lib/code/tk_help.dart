/// Ayuda de los lenguajes y de lo del estudio: qué hace cada comando, su
/// forma y un ejemplo. Bilingüe (es/en) sin pasar por el catálogo: son
/// textos largos de referencia.
class TkHelpEntry {
  const TkHelpEntry(
    this.word,
    this.lang,
    this.signature,
    this.es,
    this.en,
    this.example, {
    this.studio = false,
  });

  final String word;

  /// py, js o cpp.
  final String lang;
  final String signature;
  final String es;
  final String en;
  final String example;

  /// Es de DMarlon Studio (componentes y ventana), no del lenguaje.
  final bool studio;

  String text(String language) => language == 'en' ? en : es;
}

/// Lenguaje de la ayuda para un destino.
String tkHelpLang({required bool js, required bool cpp}) => cpp
    ? 'cpp'
    : js
    ? 'js'
    : 'py';

/// Las entradas de [lang] que coinciden con [query] (vacío: todas). La que
/// es exactamente [query] va primero.
List<TkHelpEntry> tkHelpFind(String lang, String query) {
  final q = query.trim().toLowerCase();
  final mine = tkHelp.where((e) => e.lang == lang).toList();
  if (q.isEmpty) return mine;
  final exact = mine.where((e) => e.word.toLowerCase() == q).toList();
  final rest = mine.where(
    (e) =>
        e.word.toLowerCase() != q &&
        (e.word.toLowerCase().contains(q) ||
            e.signature.toLowerCase().contains(q) ||
            e.es.toLowerCase().contains(q) ||
            e.en.toLowerCase().contains(q)),
  );
  return [...exact, ...rest];
}

const tkHelp = <TkHelpEntry>[
  // ------------------------------------------------------------- Python
  TkHelpEntry(
    'print',
    'py',
    'print(*valores, sep=" ", end="\\n")',
    'Escribe valores en la salida (la pestaña Salida del estudio).',
    'Writes values to the output (the studio Output tab).',
    'print("Total:", total)',
  ),
  TkHelpEntry(
    'len',
    'py',
    'len(objeto) -> int',
    'Cuántos elementos tiene una lista, un texto o un diccionario.',
    'How many items a list, a string or a dictionary has.',
    'if len(self.Entry1.get()) < 3:\n    return',
  ),
  TkHelpEntry(
    'range',
    'py',
    'range(inicio, fin, paso)',
    'Una serie de números para un for (el fin no se incluye).',
    'A series of numbers for a for loop (the end is excluded).',
    'for i in range(1, 11):\n    print(i)',
  ),
  TkHelpEntry(
    'if',
    'py',
    'if condición: … elif …: … else: …',
    'Ejecuta un bloque según una condición.',
    'Runs a block depending on a condition.',
    'if total > 100:\n    descuento = 10\nelse:\n    descuento = 0',
  ),
  TkHelpEntry(
    'for',
    'py',
    'for elemento in colección: …',
    'Repite un bloque por cada elemento.',
    'Repeats a block for every item.',
    'for nombre in nombres:\n    self.Listbox1.insert("end", nombre)',
  ),
  TkHelpEntry(
    'while',
    'py',
    'while condición: …',
    'Repite mientras la condición sea verdadera.',
    'Repeats while the condition is true.',
    'while n > 0:\n    n -= 1',
  ),
  TkHelpEntry(
    'def',
    'py',
    'def nombre(self, parámetros): …',
    'Define un método de la ventana (o una función).',
    'Defines a method of the window (or a function).',
    'def total(self):\n    return sum(self.precios)',
  ),
  TkHelpEntry(
    'class',
    'py',
    'class Nombre(Base): …',
    'Define una clase. La ventana es class Form1(FormDesign).',
    'Defines a class. The window is class Form1(FormDesign).',
    'class Form1(FormDesign):\n    def form_create(self):\n        pass',
  ),
  TkHelpEntry(
    'try',
    'py',
    'try: … except Error as e: … finally: …',
    'Controla un error para que la aplicación no se detenga.',
    'Handles an error so the app does not stop.',
    'try:\n    n = int(self.Entry1.get())\nexcept ValueError:\n    n = 0',
  ),
  TkHelpEntry(
    'import',
    'py',
    'import módulo / from módulo import nombre',
    'Usa un módulo de Python (al principio del archivo).',
    'Uses a Python module (at the top of the file).',
    'import json\nfrom datetime import date',
  ),
  TkHelpEntry(
    'str',
    'py',
    'str(valor) -> str',
    'Convierte un valor en texto.',
    'Converts a value to text.',
    'self.Label1.configure(text="Total: " + str(total))',
  ),
  TkHelpEntry(
    'int',
    'py',
    'int(texto) -> int',
    'Convierte un texto en número entero (ValueError si no lo es).',
    'Converts text to an integer (ValueError if it is not one).',
    'edad = int(self.Entry1.get())',
  ),
  TkHelpEntry(
    'float',
    'py',
    'float(texto) -> float',
    'Convierte un texto en número con decimales.',
    'Converts text to a number with decimals.',
    'precio = float(self.Precio.get().replace(",", "."))',
  ),
  TkHelpEntry(
    'f-string',
    'py',
    'f"texto {expresión}"',
    'Un texto con valores dentro.',
    'A string with values inside.',
    'self.Label1.configure(text=f"Hola, {nombre}")',
  ),
  TkHelpEntry(
    'open',
    'py',
    'open(ruta, modo, encoding="utf-8")',
    'Abre un archivo para leer ("r") o escribir ("w").',
    'Opens a file to read ("r") or write ("w").',
    'with open("notas.txt", "w", encoding="utf-8") as f:\n    f.write(texto)',
  ),
  TkHelpEntry(
    'list',
    'py',
    '[a, b, c] / lista.append(x)',
    'Una lista de valores; append añade al final.',
    'A list of values; append adds at the end.',
    'nombres = []\nnombres.append("Ana")',
  ),
  TkHelpEntry(
    'dict',
    'py',
    '{"clave": valor} / d.get(clave, siNo)',
    'Un diccionario de claves y valores.',
    'A dictionary of keys and values.',
    'precios = {"pan": 1.2}\nprint(precios.get("leche", 0))',
  ),
  TkHelpEntry(
    'self.root',
    'py',
    'self.root',
    'La ventana de tkinter (title, after, destroy…).',
    'The tkinter window (title, after, destroy…).',
    'self.root.title("Ventas")\nself.root.after(1000, self.tick)',
    studio: true,
  ),
  TkHelpEntry(
    'configure',
    'py',
    'self.Componente.configure(opción=valor)',
    'Cambia propiedades de un componente: text, bg, fg, state…',
    'Changes component properties: text, bg, fg, state…',
    'self.Label1.configure(text="Listo", fg="green")',
    studio: true,
  ),
  TkHelpEntry(
    'get',
    'py',
    'self.Entry1.get() / self.Text1.get("1.0", "end-1c")',
    'Lee el texto de una entrada o de un texto de varias líneas.',
    'Reads the text of an entry or a multi-line text.',
    'nombre = self.Entry1.get().strip()',
    studio: true,
  ),
  TkHelpEntry(
    'insert',
    'py',
    'self.Lista.insert("end", texto)',
    'Añade un elemento a una lista o texto a un campo.',
    'Adds an item to a list or text to a field.',
    'self.Listbox1.insert("end", "Nuevo")',
    studio: true,
  ),
  TkHelpEntry(
    'delete',
    'py',
    'self.Entry1.delete(0, "end")',
    'Borra el contenido (en un texto: delete("1.0", "end")).',
    'Clears the content (in a text: delete("1.0", "end")).',
    'self.Entry1.delete(0, "end")',
    studio: true,
  ),
  TkHelpEntry(
    'messagebox',
    'py',
    'messagebox.showinfo(título, texto)',
    'Un mensaje o una pregunta: showinfo, showerror, askyesno.',
    'A message or a question: showinfo, showerror, askyesno.',
    'from tkinter import messagebox\nif messagebox.askyesno("Borrar", "¿Seguro?"):\n    self.borrar()',
    studio: true,
  ),
  TkHelpEntry(
    'after',
    'py',
    'self.root.after(ms, función)',
    'Llama a una función dentro de unos milisegundos.',
    'Calls a function in a number of milliseconds.',
    'self.root.after(500, self.actualizar)',
    studio: true,
  ),
  // --------------------------------------------------------- JavaScript
  TkHelpEntry(
    'console.log',
    'js',
    'console.log(...valores)',
    'Escribe en la salida (la pestaña Salida del estudio).',
    'Writes to the output (the studio Output tab).',
    'console.log("Total:", total);',
  ),
  TkHelpEntry(
    'let',
    'js',
    'let nombre = valor;',
    'Una variable que puede cambiar (const: una que no).',
    'A variable that can change (const: one that cannot).',
    'let total = 0;\nconst IVA = 0.21;',
  ),
  TkHelpEntry(
    'if',
    'js',
    'if (condición) { … } else { … }',
    'Ejecuta un bloque según una condición.',
    'Runs a block depending on a condition.',
    'if (total > 100) {\n  descuento = 10;\n}',
  ),
  TkHelpEntry(
    'for',
    'js',
    'for (const x of lista) { … }',
    'Repite un bloque por cada elemento.',
    'Repeats a block for every item.',
    'for (const nombre of nombres) {\n  this.List1.add(nombre);\n}',
  ),
  TkHelpEntry(
    'function',
    'js',
    'nombre(parámetros) { … }',
    'Un método de la ventana (dentro de la clase).',
    'A method of the window (inside the class).',
    'total() {\n  return this.precios.reduce((a, b) => a + b, 0);\n}',
  ),
  TkHelpEntry(
    'async',
    'js',
    'async metodo() { await … }',
    'Un método que espera algo (un diálogo, un archivo, la red).',
    'A method that waits for something (a dialog, a file, the network).',
    'async Abrir_click() {\n  const ruta = await this.OpenFile.execute();\n}',
  ),
  TkHelpEntry(
    'map',
    'js',
    'lista.map((x) => …)',
    'Una lista nueva con cada elemento transformado.',
    'A new list with every item transformed.',
    'this.List1.items = tareas.map((t) => t.texto);',
  ),
  TkHelpEntry(
    'filter',
    'js',
    'lista.filter((x) => condición)',
    'Los elementos que cumplen la condición.',
    'The items that meet the condition.',
    'const pendientes = tareas.filter((t) => !t.hecha);',
  ),
  TkHelpEntry(
    'JSON',
    'js',
    'JSON.stringify(valor) / JSON.parse(texto)',
    'Convierte datos en texto JSON y al revés.',
    'Converts data to JSON text and back.',
    'const texto = JSON.stringify(datos);',
  ),
  TkHelpEntry(
    'template',
    'js',
    r'`texto ${expresión}`',
    'Un texto con valores dentro.',
    'A string with values inside.',
    r'this.Label1.text = `Hola, ${nombre}`;',
  ),
  TkHelpEntry(
    'fetch',
    'js',
    'await fetch(url)',
    'Pide datos a una web o una API.',
    'Requests data from a website or an API.',
    'const r = await fetch("https://api.example.com/x");\nconst datos = await r.json();',
  ),
  TkHelpEntry(
    'text',
    'js',
    'this.Componente.text',
    'El texto de una etiqueta, botón, entrada…; se lee y se cambia.',
    'The text of a label, button, entry…; read and change it.',
    'this.Label1.text = "Hola, " + this.Entry1.text;',
    studio: true,
  ),
  TkHelpEntry(
    'value',
    'js',
    'this.Componente.value',
    'El valor: número de una escala o barra, texto de una entrada.',
    'The value: number of a scale or bar, text of an entry.',
    'this.Bar1.value = this.Scale1.value;',
    studio: true,
  ),
  TkHelpEntry(
    'checked',
    'js',
    'this.Check1.checked',
    'Si una casilla u opción está marcada.',
    'Whether a check box or radio button is checked.',
    'if (this.Check1.checked) this.Panel.visible = true;',
    studio: true,
  ),
  TkHelpEntry(
    'items',
    'js',
    'this.List1.items / index / selected',
    'Los elementos de una lista o combo, el elegido y su posición.',
    'The items of a list or combo box, the chosen one and its position.',
    'this.List1.items = ["uno", "dos"];\nconsole.log(this.List1.selected);',
    studio: true,
  ),
  TkHelpEntry(
    'rows',
    'js',
    'this.Grid1.rows = [[…], …]',
    'Las filas de una tabla (listas u objetos con los campos).',
    'The rows of a grid (lists or objects with the fields).',
    'this.Grid1.rows = [{ nombre: "Ana", edad: 30 }];',
    studio: true,
  ),
  TkHelpEntry(
    'message',
    'js',
    'this.message(texto, título)',
    'Muestra un mensaje.',
    'Shows a message.',
    'this.message("Guardado", "Notas");',
    studio: true,
  ),
  TkHelpEntry(
    'storage',
    'js',
    'await this.storage.get(clave, siNo) / set',
    'Guarda datos entre usos (extensión, web o escritorio).',
    'Saves data between uses (extension, web or desktop).',
    'await this.storage.set("notas", lista);',
    studio: true,
  ),
  TkHelpEntry(
    'runInPage',
    'js',
    'await this.runInPage(función, ...args)',
    'Extensión de Chrome: ejecuta la función en la página abierta.',
    'Chrome extension: runs the function in the open page.',
    'const titulo = await this.runInPage(() => document.title);',
    studio: true,
  ),
  // ---------------------------------------------------------------- C++
  TkHelpEntry(
    'std::cout',
    'cpp',
    'std::cout << valor << std::endl;',
    'Escribe en la salida (la pestaña Salida del estudio).',
    'Writes to the output (the studio Output tab).',
    '#include <iostream>\nstd::cout << "Total: " << total << std::endl;',
  ),
  TkHelpEntry(
    'std::string',
    'cpp',
    'std::string texto = "…";',
    'Un texto; se une con +.',
    'A string; join with +.',
    'std::string saludo = "Hola, " + Entry1->text();',
  ),
  TkHelpEntry(
    'std::vector',
    'cpp',
    'std::vector<T> lista; lista.push_back(x);',
    'Una lista que crece.',
    'A growing list.',
    'std::vector<std::string> nombres;\nnombres.push_back("Ana");',
  ),
  TkHelpEntry(
    'if',
    'cpp',
    'if (condición) { … } else { … }',
    'Ejecuta un bloque según una condición.',
    'Runs a block depending on a condition.',
    'if (total > 100) {\n  descuento = 10;\n}',
  ),
  TkHelpEntry(
    'for',
    'cpp',
    'for (const auto& x : lista) { … }',
    'Repite un bloque por cada elemento.',
    'Repeats a block for every item.',
    'for (const auto& n : nombres) List1->add(n);',
  ),
  TkHelpEntry(
    'override',
    'cpp',
    'void Button1_click() override { … }',
    'Cada evento del diseño es un método que se sobrescribe con override.',
    'Every design event is a method overridden with override.',
    'void Button1_click() override {\n  Label1->text("Hola");\n}',
  ),
  TkHelpEntry(
    'std::stod',
    'cpp',
    'std::stod(texto) -> double',
    'Convierte un texto en número (std::stoi para enteros).',
    'Converts text to a number (std::stoi for integers).',
    'double precio = std::stod(Entry1->text());',
  ),
  TkHelpEntry(
    'str',
    'cpp',
    'str(número) -> std::string',
    'Un número como texto, sin ceros de más (del estudio).',
    'A number as text, without extra zeros (from the studio).',
    'Label1->text("Total: " + str(total));',
    studio: true,
  ),
  TkHelpEntry(
    'text',
    'cpp',
    'Componente->text() / text("…")',
    'Lee o cambia el texto de una etiqueta, botón o entrada.',
    'Reads or changes the text of a label, button or entry.',
    'Label1->text("Hola, " + Entry1->text());',
    studio: true,
  ),
  TkHelpEntry(
    'checked',
    'cpp',
    'Check1->checked() / checked(true)',
    'Si una casilla u opción está marcada.',
    'Whether a check box or radio button is checked.',
    'if (Check1->checked()) Bar1->value(100);',
    studio: true,
  ),
  TkHelpEntry(
    'items',
    'cpp',
    'List1->items({…}) / index() / selected()',
    'Los elementos de una lista o combo y el elegido.',
    'The items of a list or combo box and the chosen one.',
    'List1->items({"uno", "dos"});\nStatus->text(List1->selected());',
    studio: true,
  ),
  TkHelpEntry(
    'message',
    'cpp',
    'message(texto) / ask(pregunta)',
    'Un mensaje, o una pregunta de sí o no (true si sí).',
    'A message, or a yes/no question (true for yes).',
    'if (ask("¿Borrar?")) clear();',
    studio: true,
  ),
  TkHelpEntry(
    'readText',
    'cpp',
    'readText(ruta) / writeText(ruta, texto)',
    'Lee o escribe un archivo de texto (del estudio).',
    'Reads or writes a text file (from the studio).',
    'std::string ruta = OpenFile.execute();\nif (!ruta.empty()) Text1->text(readText(ruta));',
    studio: true,
  ),
];
