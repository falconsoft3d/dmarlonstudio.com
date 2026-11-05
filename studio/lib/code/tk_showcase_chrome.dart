part of 'tk_examples.dart';

// Extensiones de Chrome: el diseño es la ventana emergente y el código, el
// mismo JavaScript de Electron con las API de la extensión (this.storage,
// this.currentTab(), this.runInPage(), this.badge()).

/// Los ejemplos de extensiones de Chrome.
List<TkExample> tkChromeExamples(String Function(String) t) => [
  _chromeNotes(t),
  _chromeWords(t),
];

// --------------------------------------------------------- notas por sitio
TkExample _chromeNotes(String Function(String) t) {
  final app = t(markTr('Notas por sitio'));
  final design =
      TkDesign(
          width: 360,
          height: 380,
          target: tkTargetChrome,
          props: {'title': app, 'bg': '#ffffff'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Site', 12, 10, 336, 22, {
            'text': '…',
            'anchor': 'w',
            'font_bold': true,
            'fg': '#1f2328',
          }),
          _w('Label', 'Address', 12, 32, 336, 18, {
            'text': '',
            'anchor': 'w',
            'fg': '#6e7781',
            'font_size': 11,
          }),
          _w('Text', 'Note', 12, 56, 336, 120, {'wrap': 'word'}),
          _w(
            'Button',
            'Save',
            12,
            184,
            110,
            30,
            {'text': t(markTr('Guardar')), 'bg': '#2563eb', 'fg': '#ffffff'},
            {'command': 'Save_click'},
          ),
          _w(
            'Button',
            'Remove',
            130,
            184,
            110,
            30,
            {'text': t(markTr('Borrar'))},
            {'command': 'Remove_click'},
          ),
          _w('Label', 'Saved', 12, 224, 336, 20, {
            'text': t(markTr('Sitios con nota (doble clic: abrir)')),
            'anchor': 'w',
            'fg': '#6e7781',
          }),
          _w('Listbox', 'Sites', 12, 246, 336, 104, {}, {
            'double': 'Sites_double',
          }),
          _w('StatusBar', 'Status', 0, 356, 360, 24, {
            'text': t(markTr('Listo')),
          }),
        ]);
  final code =
      '''// ${t(markTr('Una nota por cada web, guardada en el almacenamiento de la extensión.'))}
const SAVED = ${_jsStr(t(markTr('Nota guardada.')))};
const REMOVED = ${_jsStr(t(markTr('Nota borrada.')))};

class Form1 extends FormDesign {
  async form_create() {
    const tab = await this.currentTab();
    this.url = tab ? tab.url : "";
    this.host = this.hostOf(this.url);
    this.Site.text = tab ? tab.title || this.host : "";
    this.Address.text = this.host;
    const notes = await this.notes();
    this.Note.text = notes[this.host] || "";
    this.showSites(notes);
  }

  hostOf(url) {
    try {
      return new URL(url).host || url;
    } catch (error) {
      return url;
    }
  }

  async notes() {
    return await this.storage.get("notes", {});
  }

  showSites(notes) {
    const sites = Object.keys(notes).sort();
    this.Sites.items = sites;
    this.badge(sites.length ? String(sites.length) : "");
  }

  async Save_click() {
    const notes = await this.notes();
    const text = this.Note.text.trim();
    if (text) notes[this.host] = text;
    else delete notes[this.host];
    await this.storage.set("notes", notes);
    this.showSites(notes);
    this.Status.text = SAVED;
  }

  async Remove_click() {
    const notes = await this.notes();
    delete notes[this.host];
    await this.storage.set("notes", notes);
    this.Note.text = "";
    this.showSites(notes);
    this.Status.text = REMOVED;
  }

  Sites_double(event) {
    if (this.Sites.selected) this.openTab("https://" + this.Sites.selected);
  }
}
''';
  return TkExample(
    'chrome_notes',
    t(markTr('Notas por sitio (Chrome)')),
    t(
      markTr(
        'Extensión de Chrome: una nota para cada web, guardada con this.storage, y la lista de sitios con nota en la insignia.',
      ),
    ),
    design,
    code,
  );
}

// ------------------------------------------------------- contar palabras
TkExample _chromeWords(String Function(String) t) {
  final app = t(markTr('Contador de palabras'));
  final design =
      TkDesign(
          width: 340,
          height: 360,
          target: tkTargetChrome,
          props: {'title': app, 'bg': '#f8fafc'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Heading', 12, 10, 316, 26, {
            'text': app,
            'anchor': 'w',
            'font_size': 16,
            'font_bold': true,
            'fg': '#0f172a',
          }),
          _w(
            'Button',
            'Count',
            12,
            44,
            316,
            32,
            {
              'text': t(markTr('Contar las palabras de esta página')),
              'bg': '#0f172a',
              'fg': '#ffffff',
            },
            {'command': 'Count_click'},
          ),
          _w('Label', 'Words', 12, 86, 316, 22, {'text': '', 'anchor': 'w'}),
          _w('Label', 'Chars', 12, 108, 316, 22, {'text': '', 'anchor': 'w'}),
          _w('Label', 'Reading', 12, 130, 316, 22, {'text': '', 'anchor': 'w'}),
          _w('Treeview', 'Top', 12, 158, 316, 170, {
            'columns': [
              'word|${t(markTr('Palabra'))}|200',
              'times|${t(markTr('Veces'))}|80',
            ].join('\n'),
          }),
          _w('StatusBar', 'Status', 0, 336, 340, 24, {
            'text': t(markTr('Abra una web y pulse el botón.')),
          }),
        ]);
  final code =
      '''// ${t(markTr('Lee el texto de la página con this.runInPage() y lo cuenta en la ventana.'))}
const WORDS = ${_jsStr(t(markTr('Palabras: {0}')))};
const CHARS = ${_jsStr(t(markTr('Caracteres: {0}')))};
const READING = ${_jsStr(t(markTr('Lectura: {0} min')))};
const NO_PAGE = ${_jsStr(t(markTr('No se puede leer esta página (las de Chrome están protegidas).')))};

class Form1 extends FormDesign {
  async form_create() {
    const tab = await this.currentTab();
    this.Status.text = tab ? tab.title : "";
  }

  async Count_click() {
    // Esta función corre dentro de la página, no en la extensión.
    const text = await this.runInPage(() => document.body ? document.body.innerText : "");
    if (text === null || text === undefined) {
      this.Status.text = NO_PAGE;
      return;
    }
    const words = text.toLowerCase().match(/[\\p{L}\\p{N}'’-]+/gu) || [];
    this.Words.text = WORDS.replace("{0}", words.length.toLocaleString());
    this.Chars.text = CHARS.replace("{0}", text.length.toLocaleString());
    this.Reading.text = READING.replace("{0}", Math.max(1, Math.round(words.length / 220)));
    const counts = new Map();
    for (const w of words) if (w.length > 3) counts.set(w, (counts.get(w) || 0) + 1);
    this.Top.rows = [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 10);
    this.badge(words.length > 999 ? Math.round(words.length / 1000) + "k" : String(words.length), "#0f172a");
  }
}
''';
  return TkExample(
    'chrome_words',
    t(markTr('Contador de palabras (Chrome)')),
    t(
      markTr(
        'Extensión de Chrome: cuenta las palabras de la página abierta con this.runInPage(), el tiempo de lectura y las más repetidas.',
      ),
    ),
    design,
    code,
  );
}
