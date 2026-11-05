part of 'tk_examples.dart';

// Ejemplos web de muestra (Flask) y el reproductor de música. Las
// aplicaciones web abren una conexión a SQLite en cada operación: cada
// petición del navegador puede llegar por otro hilo del servidor.

/// Funciones de base de datos y de importes comunes a los ejemplos web.
const _sqlHelpers = '''
def query(sql, args=()):
    with closing(sqlite3.connect(DB)) as db:
        db.row_factory = sqlite3.Row
        return db.execute(sql, args).fetchall()


def execute(sql, args=()):
    with closing(sqlite3.connect(DB)) as db:
        with db:
            return db.execute(sql, args).lastrowid


def parse_number(text):
    text = str(text).strip().replace(" ", "").replace("€", "")
    if "," in text and "." in text:
        text = text.replace(".", "").replace(",", ".")
    else:
        text = text.replace(",", ".")
    return Decimal(text)


def money(value):
    text = "{:,.2f}".format(Decimal(value))
    # Formato español: punto de miles y coma decimal.
    return text.replace(",", "_").replace(".", ",").replace("_", ".") + " €"


def round2(value):
    return Decimal(value).quantize(CENT, ROUND_HALF_UP)
''';

const _sqlImports = '''import datetime
import sqlite3
from contextlib import closing
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
''';

// ------------------------------------------------------------------- CRM
TkExample _crm(String Function(String) t) {
  final stages = [
    ('new', t(markTr('Nuevo'))),
    ('qualified', t(markTr('Calificado'))),
    ('proposal', t(markTr('Propuesta'))),
    ('won', t(markTr('Ganado'))),
    ('lost', t(markTr('Perdido'))),
  ];
  const lx = 600, fx = 704, fw = 240;
  TkWidget field(String name, int y, [String kind = 'Entry']) => _w(
    kind,
    name,
    fx,
    y,
    fw,
    24,
    kind == 'Combobox' ? {'state': 'readonly'} : {},
  );
  TkWidget caption(String name, String text, int y) =>
      _w('Label', name, lx, y, 104, 24, _label(text));
  TkWidget button(String name, String text, int x, int y, [int w = 108]) => _w(
    'Button',
    name,
    x,
    y,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  final design =
      TkDesign(
          width: 960,
          height: 600,
          target: tkTargetWeb,
          props: {'title': t(markTr('CRM')), 'bg': _paper},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w(
            'Label',
            'Heading',
            16,
            8,
            560,
            32,
            _title(t(markTr('Oportunidades de venta'))),
          ),
          _w('Label', 'LblSearch', 16, 48, 56, 24, _label(t(markTr('Buscar')))),
          _w('Entry', 'Search', 72, 48, 232, 24, {}, {
            'key_up': 'Search_key_up',
          }),
          _w('Label', 'LblFilter', 320, 48, 56, 24, _label(t(markTr('Etapa')))),
          _w(
            'Combobox',
            'StageFilter',
            376,
            48,
            200,
            24,
            {'state': 'readonly'},
            {'select': 'StageFilter_select'},
          ),
          _w(
            'Treeview',
            'Opps',
            16,
            80,
            560,
            392,
            {
              'columns': [
                'client|${t(markTr('Cliente'))}|120',
                'title|${t(markTr('Oportunidad'))}|150',
                'amount|${t(markTr('Importe'))}|100',
                'stage|${t(markTr('Etapa'))}|80',
                'next|${t(markTr('Próxima acción'))}|110',
              ].join('\n'),
            },
            {'select': 'Opps_select'},
          ),
          _w('Label', 'Summary', 16, 480, 560, 88, {
            'text': '',
            'anchor': 'nw',
            'justify': 'left',
            'fg': '#3c4049',
          }),
          _w('Label', 'FormTitle', lx, 48, 344, 24, {
            ..._label(t(markTr('Nueva oportunidad'))),
            'font_bold': true,
          }),
          caption('LblClient', t(markTr('Cliente')), 80),
          field('Client', 80),
          caption('LblTitle', t(markTr('Oportunidad')), 112),
          field('OppTitle', 112),
          caption('LblAmount', t(markTr('Importe (€)')), 144),
          field('Amount', 144),
          caption('LblStage', t(markTr('Etapa')), 176),
          field('Stage', 176, 'Combobox'),
          caption('LblNext', t(markTr('Próxima acción')), 208),
          field('NextAction', 208),
          caption('LblDate', t(markTr('Fecha')), 240),
          field('NextDate', 240),
          caption('LblNotes', t(markTr('Notas')), 272),
          _w('Text', 'Notes', fx, 272, fw, 96),
          button('BtnNew', t(markTr('Nueva')), lx, 384),
          button('BtnSave', t(markTr('Guardar')), lx + 116, 384),
          button('BtnDelete', t(markTr('Eliminar')), lx + 232, 384, 112),
          button('BtnNext', t(markTr('Avanzar etapa')), lx, 424),
          button('BtnWon', t(markTr('Ganada')), lx + 116, 424),
          button('BtnLost', t(markTr('Perdida')), lx + 232, 424, 112),
          _w('Label', 'Hint', lx, 472, 344, 48, {
            'text': t(
              markTr(
                'Fecha: AAAA-MM-DD. Avanzar etapa:\nNuevo → Calificado → Propuesta → Ganado.',
              ),
            ),
            'anchor': 'nw',
            'justify': 'left',
            'fg': '#5f6672',
          }),
          _w('StatusBar', 'Status', 0, 576, 960, 24, {
            'text': t(markTr('Listo')),
            'icon': 'user',
          }),
        ]);
  final stagesPy = stages.map((s) => '("${s.$1}", ${_py(s.$2)})').join(', ');
  final code =
      '''$_sqlImports
DB = "crm.sqlite"
CENT = Decimal("0.01")
STAGES = [$stagesPy]
LABELS = dict(STAGES)
KEYS = [key for key, _ in STAGES]
OPEN = ("new", "qualified", "proposal")
ALL = ${_py(t(markTr('Todas las etapas')))}
NEW_TITLE = ${_py(t(markTr('Nueva oportunidad')))}
EDIT_TITLE = ${_py(t(markTr('Oportunidad n.º {0}')))}
$_sqlHelpers

def create_tables():
    execute("""CREATE TABLE IF NOT EXISTS opportunity (
        id INTEGER PRIMARY KEY,
        client TEXT NOT NULL,
        title TEXT NOT NULL,
        amount TEXT NOT NULL DEFAULT '0',
        stage TEXT NOT NULL DEFAULT 'new',
        next_action TEXT NOT NULL DEFAULT '',
        next_date TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '')""")
    if query("SELECT COUNT(*) AS n FROM opportunity")[0]["n"]:
        return
    soon = (datetime.date.today() + datetime.timedelta(days=3)).isoformat()
    for row in [
        ("Comercial Norte", ${_py(t(markTr('Tienda online')))}, "8500", "proposal", ${_py(t(markTr('Llamar para cerrar')))}, soon),
        ("Ana Torres", ${_py(t(markTr('Logotipo')))}, "600", "new", ${_py(t(markTr('Enviar portafolio')))}, soon),
        ("Estudio Creativo", ${_py(t(markTr('Mantenimiento anual')))}, "2400", "qualified", ${_py(t(markTr('Preparar propuesta')))}, soon),
        ("Hotel Brisa", ${_py(t(markTr('Reservas web')))}, "12000", "won", "", ""),
        ("Grupo Sur", ${_py(t(markTr('Intranet')))}, "5000", "lost", "", ""),
    ]:
        execute(
            "INSERT INTO opportunity (client, title, amount, stage, next_action, next_date)"
            " VALUES (?, ?, ?, ?, ?, ?)",
            row,
        )


class Form1(FormDesign):
    def form_create(self):
        create_tables()
        self.current = None
        self.StageFilter.configure(values=[ALL] + [label for _, label in STAGES])
        self.StageFilter.current(0)
        self.Stage.configure(values=[label for _, label in STAGES])
        self.Stage.current(0)
        self.load()

    # -------------------------------------------------------------- lista
    def load(self, select=None):
        like = "%" + self.Search_var.get().strip() + "%"
        where, args = "(client LIKE ? OR title LIKE ?)", [like, like]
        index = self.StageFilter.current()
        if index > 0:
            where += " AND stage = ?"
            args.append(KEYS[index - 1])
        order = " ".join("WHEN '%s' THEN %d" % (key, i) for i, key in enumerate(KEYS))
        rows = query(
            "SELECT * FROM opportunity WHERE " + where
            + " ORDER BY CASE stage " + order + " END, next_date, client",
            args,
        )
        self.Opps.delete(*self.Opps.get_children())
        for row in rows:
            upcoming = (row["next_action"] + " " + row["next_date"]).strip()
            self.Opps.insert(
                "", "end", iid=str(row["id"]),
                values=(row["client"], row["title"], money(row["amount"]), LABELS[row["stage"]], upcoming),
            )
        if select is not None and str(select) in self.Opps.get_children():
            self.Opps.selection_set(str(select))
        self.show_summary()

    def show_summary(self):
        totals = {key: [0, Decimal(0)] for key in KEYS}
        for row in query("SELECT stage, amount FROM opportunity"):
            totals[row["stage"]][0] += 1
            totals[row["stage"]][1] += Decimal(row["amount"])
        lines = ["%s: %d · %s" % (LABELS[key], totals[key][0], money(totals[key][1])) for key in KEYS]
        open_value = sum(totals[key][1] for key in OPEN)
        self.Summary.configure(
            text="   ".join(lines[:3]) + "\\n" + "   ".join(lines[3:]) + "\\n"
            + ${_py(t(markTr('Valor en curso: {0}')))}.format(money(open_value))
        )

    # ---------------------------------------------------------- formulario
    def clear(self):
        self.current = None
        for var in (self.Client_var, self.OppTitle_var, self.Amount_var, self.NextAction_var, self.NextDate_var):
            var.set("")
        self.Stage.current(0)
        self.Notes.delete("1.0", "end")
        self.FormTitle.configure(text=NEW_TITLE)

    def Opps_select(self, event=None):
        chosen = self.Opps.selection()
        rows = query("SELECT * FROM opportunity WHERE id = ?", (int(chosen[0]),)) if chosen else []
        if not rows:
            return
        row = rows[0]
        self.current = row["id"]
        self.Client_var.set(row["client"])
        self.OppTitle_var.set(row["title"])
        self.Amount_var.set(money(row["amount"]).replace(" €", ""))
        self.Stage.current(KEYS.index(row["stage"]))
        self.NextAction_var.set(row["next_action"])
        self.NextDate_var.set(row["next_date"])
        self.Notes.delete("1.0", "end")
        self.Notes.insert("1.0", row["notes"])
        self.FormTitle.configure(text=EDIT_TITLE.format(row["id"]))

    def BtnNew_click(self):
        self.clear()
        self.Status.set(${_py(t(markTr('Escriba los datos de la nueva oportunidad.')))}, icon="add")

    def BtnSave_click(self):
        client = self.Client_var.get().strip()
        title = self.OppTitle_var.get().strip()
        if not client or not title:
            return self.Status.set(${_py(t(markTr('Escriba el cliente y la oportunidad.')))}, icon="warning")
        try:
            amount = round2(parse_number(self.Amount_var.get() or "0"))
        except (InvalidOperation, ValueError):
            return self.Status.set(${_py(t(markTr('El importe no es un número.')))}, icon="warning")
        date = self.NextDate_var.get().strip()
        if date:
            try:
                datetime.date.fromisoformat(date)
            except ValueError:
                return self.Status.set(${_py(t(markTr('La fecha debe ser AAAA-MM-DD.')))}, icon="warning")
        stage = KEYS[max(0, self.Stage.current())]
        data = (client, title, str(amount), stage, self.NextAction_var.get().strip(), date,
                self.Notes.get("1.0", "end").strip())
        if self.current is None:
            self.current = execute(
                "INSERT INTO opportunity (client, title, amount, stage, next_action, next_date, notes)"
                " VALUES (?, ?, ?, ?, ?, ?, ?)",
                data,
            )
        else:
            execute(
                "UPDATE opportunity SET client = ?, title = ?, amount = ?, stage = ?,"
                " next_action = ?, next_date = ?, notes = ? WHERE id = ?",
                data + (self.current,),
            )
        self.FormTitle.configure(text=EDIT_TITLE.format(self.current))
        self.load(select=self.current)
        self.Status.set(${_py(t(markTr('Guardada: {0}')))}.format(title), icon="check")

    def move(self, stage):
        if self.current is None:
            return self.Status.set(${_py(t(markTr('Elija una oportunidad de la lista.')))}, icon="info")
        execute("UPDATE opportunity SET stage = ? WHERE id = ?", (stage, self.current))
        self.Stage.current(KEYS.index(stage))
        self.load(select=self.current)
        self.Status.set(${_py(t(markTr('Ahora está en «{0}».')))}.format(LABELS[stage]), icon="check")

    def BtnNext_click(self):
        if self.current is None:
            return self.move(None)
        stage = query("SELECT stage FROM opportunity WHERE id = ?", (self.current,))[0]["stage"]
        if stage not in OPEN:
            return self.Status.set(${_py(t(markTr('Esta oportunidad ya está cerrada.')))}, icon="info")
        self.move(KEYS[KEYS.index(stage) + 1])

    def BtnWon_click(self):
        self.move("won")

    def BtnLost_click(self):
        self.move("lost")

    def BtnDelete_click(self):
        if self.current is None:
            return self.Status.set(${_py(t(markTr('Elija una oportunidad de la lista.')))}, icon="info")
        execute("DELETE FROM opportunity WHERE id = ?", (self.current,))
        self.clear()
        self.load()
        self.Status.set(${_py(t(markTr('Oportunidad eliminada.')))}, icon="delete")

    def Search_key_up(self, event=None):
        self.load()

    def StageFilter_select(self, event=None):
        self.load()
''';
  return TkExample(
    'web_crm',
    t(markTr('CRM web')),
    t(
      markTr(
        'Oportunidades por etapas con búsqueda, filtro, ficha para crear y editar y el valor del embudo, en SQLite.',
      ),
    ),
    design,
    code,
  );
}

// ------------------------------------------------------------ facturador
TkExample _invoicing(String Function(String) t) {
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  TkWidget button(String name, String text, int x, int y, int w) => _w(
    'Button',
    name,
    x,
    y,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  final pages = [
    t(markTr('Facturas')),
    t(markTr('Nueva factura')),
    t(markTr('Clientes y productos')),
  ].join('\n');
  final design =
      TkDesign(
          width: 1000,
          height: 640,
          target: tkTargetWeb,
          props: {'title': t(markTr('Facturador')), 'bg': _paper},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w(
            'Label',
            'Heading',
            16,
            8,
            600,
            32,
            _title(t(markTr('Facturador'))),
          ),
          _w('SaveDialog', 'SaveInvoice', 960, 8, 32, 32, {
            'defaultext': '.html',
            'filter': 'HTML|*.html',
          }),
          _w('PageControl', 'Pages', 16, 48, 968, 552, {'pages': pages}),
          // Facturas.
          on(
            _w('Treeview', 'Invoices', 16, 40, 936, 400, {
              'columns': [
                'number|${t(markTr('Número'))}|130',
                'date|${t(markTr('Fecha'))}|100',
                'client|${t(markTr('Cliente'))}|330',
                'total|${t(markTr('Total'))}|130',
                'status|${t(markTr('Estado'))}|120',
              ].join('\n'),
            }),
            0,
          ),
          on(
            button('BtnPaid', t(markTr('Marcar como pagada')), 16, 452, 176),
            0,
          ),
          on(button('BtnDownload', t(markTr('Descargar')), 200, 452, 136), 0),
          on(
            _w('Label', 'Totals', 352, 456, 600, 24, {
              'text': '',
              'anchor': 'e',
            }),
            0,
          ),
          // Nueva factura.
          on(
            _w(
              'Label',
              'LblClient',
              16,
              40,
              80,
              24,
              _label(t(markTr('Cliente'))),
            ),
            1,
          ),
          on(
            _w('Combobox', 'InvClient', 96, 40, 320, 24, {'state': 'readonly'}),
            1,
          ),
          on(
            _w('Label', 'LblDate', 432, 40, 56, 24, _label(t(markTr('Fecha')))),
            1,
          ),
          on(_w('Entry', 'InvDate', 488, 40, 120, 24), 1),
          on(
            _w(
              'Label',
              'LblProduct',
              16,
              80,
              80,
              24,
              _label(t(markTr('Producto'))),
            ),
            1,
          ),
          on(
            _w('Combobox', 'InvProduct', 96, 80, 320, 24, {
              'state': 'readonly',
            }),
            1,
          ),
          on(
            _w(
              'Label',
              'LblQty',
              432,
              80,
              72,
              24,
              _label(t(markTr('Cantidad'))),
            ),
            1,
          ),
          on(_w('Entry', 'InvQty', 504, 80, 72, 24), 1),
          on(button('BtnAddLine', t(markTr('Añadir línea')), 592, 76, 128), 1),
          on(
            button('BtnRemoveLine', t(markTr('Quitar línea')), 728, 76, 128),
            1,
          ),
          on(
            _w('Treeview', 'Lines', 16, 120, 936, 296, {
              'columns': [
                'product|${t(markTr('Producto'))}|380',
                'qty|${t(markTr('Cantidad'))}|90',
                'price|${t(markTr('Precio'))}|120',
                'vat|${t(markTr('IVA %'))}|80',
                'amount|${t(markTr('Importe'))}|130',
              ].join('\n'),
            }),
            1,
          ),
          on(
            _w('Label', 'DraftTotals', 552, 424, 400, 72, {
              'text': '',
              'anchor': 'ne',
              'justify': 'right',
              'font_size': 13,
            }),
            1,
          ),
          on(button('BtnIssue', t(markTr('Emitir factura')), 16, 456, 160), 1),
          on(button('BtnClear', t(markTr('Vaciar')), 184, 456, 120), 1),
          // Clientes y productos.
          on(
            _w('Label', 'LblClients', 16, 40, 448, 24, {
              ..._label(t(markTr('Clientes'))),
              'font_bold': true,
            }),
            2,
          ),
          on(
            _w(
              'Label',
              'LblClientName',
              16,
              72,
              64,
              24,
              _label(t(markTr('Nombre'))),
            ),
            2,
          ),
          on(_w('Entry', 'ClientName', 80, 72, 200, 24), 2),
          on(
            _w('Label', 'LblTax', 296, 72, 40, 24, _label(t(markTr('NIF')))),
            2,
          ),
          on(_w('Entry', 'ClientTax', 336, 72, 128, 24), 2),
          on(
            button('BtnAddClient', t(markTr('Añadir cliente')), 16, 104, 144),
            2,
          ),
          on(
            _w('Treeview', 'Clients', 16, 144, 448, 344, {
              'columns': [
                'name|${t(markTr('Nombre'))}|300',
                'tax|${t(markTr('NIF'))}|148',
              ].join('\n'),
            }),
            2,
          ),
          on(
            _w('Label', 'LblProducts', 488, 40, 464, 24, {
              ..._label(t(markTr('Productos'))),
              'font_bold': true,
            }),
            2,
          ),
          on(
            _w(
              'Label',
              'LblCode',
              488,
              72,
              56,
              24,
              _label(t(markTr('Código'))),
            ),
            2,
          ),
          on(_w('Entry', 'ProdCode', 544, 72, 80, 24), 2),
          on(
            _w(
              'Label',
              'LblProdName',
              640,
              72,
              64,
              24,
              _label(t(markTr('Nombre'))),
            ),
            2,
          ),
          on(_w('Entry', 'ProdName', 704, 72, 248, 24), 2),
          on(
            _w(
              'Label',
              'LblPrice',
              488,
              104,
              56,
              24,
              _label(t(markTr('Precio'))),
            ),
            2,
          ),
          on(_w('Entry', 'ProdPrice', 544, 104, 80, 24), 2),
          on(
            _w('Label', 'LblVat', 640, 104, 64, 24, _label(t(markTr('IVA %')))),
            2,
          ),
          on(_w('Entry', 'ProdVat', 704, 104, 64, 24), 2),
          on(
            button(
              'BtnAddProduct',
              t(markTr('Añadir producto')),
              784,
              100,
              168,
            ),
            2,
          ),
          on(
            _w('Treeview', 'Products', 488, 144, 464, 344, {
              'columns': [
                'code|${t(markTr('Código'))}|80',
                'name|${t(markTr('Nombre'))}|224',
                'price|${t(markTr('Precio'))}|90',
                'vat|${t(markTr('IVA %'))}|70',
              ].join('\n'),
            }),
            2,
          ),
          _w('StatusBar', 'Status', 0, 616, 1000, 24, {
            'text': t(markTr('Listo')),
            'icon': 'calendar',
          }),
        ]);
  final code =
      '''import html
$_sqlImports
DB = "facturas.sqlite"
CENT = Decimal("0.01")
PENDING = ${_py(t(markTr('Pendiente')))}
PAID = ${_py(t(markTr('Pagada')))}
INVOICE = ${_py(t(markTr('Factura')))}
$_sqlHelpers

def create_tables():
    for sql in (
        "CREATE TABLE IF NOT EXISTS client (id INTEGER PRIMARY KEY, name TEXT NOT NULL, tax_id TEXT NOT NULL DEFAULT '')",
        "CREATE TABLE IF NOT EXISTS product (id INTEGER PRIMARY KEY, code TEXT NOT NULL,"
        " name TEXT NOT NULL, price TEXT NOT NULL, vat TEXT NOT NULL)",
        "CREATE TABLE IF NOT EXISTS invoice (id INTEGER PRIMARY KEY, number TEXT NOT NULL UNIQUE,"
        " date TEXT NOT NULL, client_id INTEGER NOT NULL, paid INTEGER NOT NULL DEFAULT 0,"
        " subtotal TEXT NOT NULL, vat TEXT NOT NULL, total TEXT NOT NULL)",
        "CREATE TABLE IF NOT EXISTS line (id INTEGER PRIMARY KEY, invoice_id INTEGER NOT NULL,"
        " product TEXT NOT NULL, qty TEXT NOT NULL, price TEXT NOT NULL, vat TEXT NOT NULL,"
        " amount TEXT NOT NULL)",
    ):
        execute(sql)
    if query("SELECT COUNT(*) AS n FROM client")[0]["n"]:
        return
    for row in [("Comercial Norte S.L.", "B12345678"), ("Ana Torres", "12345678Z"),
                ("Estudio Creativo S.L.", "B87654321")]:
        execute("INSERT INTO client (name, tax_id) VALUES (?, ?)", row)
    for row in [
        ("WEB", ${_py(t(markTr('Diseño web')))}, "1200.00", "21"),
        ("HOST", ${_py(t(markTr('Alojamiento anual')))}, "180.00", "21"),
        ("HORA", ${_py(t(markTr('Hora de consultoría')))}, "60.00", "21"),
        ("LIBRO", ${_py(t(markTr('Libro técnico')))}, "35.00", "4"),
    ]:
        execute("INSERT INTO product (code, name, price, vat) VALUES (?, ?, ?, ?)", row)
    today = datetime.date.today().isoformat()
    first = issue(1, today, [line_of(1, Decimal(1)), line_of(2, Decimal(1))])
    issue(2, today, [line_of(3, Decimal(5))])
    execute("UPDATE invoice SET paid = 1 WHERE number = ?", (first,))


def line_of(product_id, qty):
    row = query("SELECT * FROM product WHERE id = ?", (product_id,))[0]
    price, vat = Decimal(row["price"]), Decimal(row["vat"])
    return {"product": row["code"] + " · " + row["name"], "qty": qty, "price": price,
            "vat": vat, "amount": round2(qty * price)}


def totals(lines):
    subtotal = sum((line["amount"] for line in lines), Decimal(0))
    vat = sum((round2(line["amount"] * line["vat"] / 100) for line in lines), Decimal(0))
    return round2(subtotal), round2(vat), round2(subtotal + vat)


def next_number(date):
    year = date[:4]
    rows = query("SELECT number FROM invoice WHERE number LIKE ? ORDER BY number DESC LIMIT 1",
                 ("F-%s-%%" % year,))
    last = int(rows[0]["number"].rsplit("-", 1)[1]) if rows else 0
    return "F-%s-%04d" % (year, last + 1)


def issue(client_id, date, lines):
    subtotal, vat, total = totals(lines)
    number = next_number(date)
    invoice_id = execute(
        "INSERT INTO invoice (number, date, client_id, subtotal, vat, total) VALUES (?, ?, ?, ?, ?, ?)",
        (number, date, client_id, str(subtotal), str(vat), str(total)),
    )
    for line in lines:
        execute(
            "INSERT INTO line (invoice_id, product, qty, price, vat, amount) VALUES (?, ?, ?, ?, ?, ?)",
            (invoice_id, line["product"], str(line["qty"]), str(line["price"]), str(line["vat"]),
             str(line["amount"])),
        )
    return number


def invoice_html(number):
    head = query(
        "SELECT i.*, c.name, c.tax_id FROM invoice i JOIN client c ON c.id = i.client_id"
        " WHERE i.number = ?", (number,))[0]
    lines = query("SELECT * FROM line WHERE invoice_id = ? ORDER BY id", (head["id"],))
    e = html.escape
    rows = "".join(
        "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s %%</td><td>%s</td></tr>"
        % (e(r["product"]), e(r["qty"]), money(r["price"]), e(r["vat"]), money(r["amount"]))
        for r in lines
    )
    return (
        "<!doctype html><meta charset='utf-8'><title>%s %s</title>"
        "<style>body{font-family:sans-serif;margin:40px}table{border-collapse:collapse;width:100%%}"
        "td,th{border-bottom:1px solid #ddd;padding:6px;text-align:left}.t{text-align:right}</style>"
        "<h1>%s %s</h1><p>%s<br>%s · %s</p>"
        "<table><tr><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th></tr>%s</table>"
        "<p class='t'>%s: %s<br>%s: %s<br><b>%s: %s</b></p>"
        % (INVOICE, e(number), INVOICE, e(number), e(head["date"]), e(head["name"]), e(head["tax_id"]),
           ${_py(t(markTr('Producto')))}, ${_py(t(markTr('Cantidad')))}, ${_py(t(markTr('Precio')))},
           ${_py(t(markTr('IVA')))}, ${_py(t(markTr('Importe')))}, rows,
           ${_py(t(markTr('Base imponible')))}, money(head["subtotal"]), ${_py(t(markTr('IVA')))}, money(head["vat"]),
           ${_py(t(markTr('Total')))}, money(head["total"]))
    )


class Form1(FormDesign):
    def form_create(self):
        create_tables()
        self.lines = []
        self.InvDate_var.set(datetime.date.today().isoformat())
        self.InvQty_var.set("1")
        self.load_catalog()
        self.load_invoices()
        self.show_draft()

    # ------------------------------------------------------- catálogos
    def load_catalog(self):
        self.clients = query("SELECT * FROM client ORDER BY name")
        self.products = query("SELECT * FROM product ORDER BY code")
        self.InvClient.configure(values=[c["name"] for c in self.clients])
        self.InvProduct.configure(
            values=["%s · %s (%s)" % (p["code"], p["name"], money(p["price"])) for p in self.products]
        )
        if self.clients and self.InvClient.current() < 0:
            self.InvClient.current(0)
        if self.products and self.InvProduct.current() < 0:
            self.InvProduct.current(0)
        self.Clients.delete(*self.Clients.get_children())
        for c in self.clients:
            self.Clients.insert("", "end", iid=str(c["id"]), values=(c["name"], c["tax_id"]))
        self.Products.delete(*self.Products.get_children())
        for p in self.products:
            self.Products.insert("", "end", iid=str(p["id"]),
                                 values=(p["code"], p["name"], money(p["price"]), p["vat"]))

    def load_invoices(self, select=None):
        rows = query(
            "SELECT i.*, c.name FROM invoice i JOIN client c ON c.id = i.client_id ORDER BY i.number DESC"
        )
        self.Invoices.delete(*self.Invoices.get_children())
        billed = pending = Decimal(0)
        for row in rows:
            total = Decimal(row["total"])
            billed += total
            if not row["paid"]:
                pending += total
            day = datetime.date.fromisoformat(row["date"]).strftime("%d/%m/%Y")
            self.Invoices.insert("", "end", iid=row["number"],
                                 values=(row["number"], day, row["name"], money(total),
                                         PAID if row["paid"] else PENDING))
        if select:
            self.Invoices.selection_set(select)
        self.Totals.configure(
            text=${_py(t(markTr('Facturado: {0}   ·   Pendiente de cobro: {1}')))}.format(money(billed), money(pending))
        )

    def chosen_invoice(self):
        chosen = self.Invoices.selection()
        if not chosen:
            self.Status.set(${_py(t(markTr('Elija una factura de la lista.')))}, icon="info")
            return None
        return chosen[0]

    def BtnPaid_click(self):
        number = self.chosen_invoice()
        if number:
            execute("UPDATE invoice SET paid = 1 WHERE number = ?", (number,))
            self.load_invoices(select=number)
            self.Status.set(${_py(t(markTr('{0} marcada como pagada.')))}.format(number), icon="check")

    def BtnDownload_click(self):
        number = self.chosen_invoice()
        if number:
            self.SaveInvoice.download(number + ".html", invoice_html(number), type="text/html")
            self.Status.set(${_py(t(markTr('Descargando {0}.html')))}.format(number), icon="save")

    # ------------------------------------------------------ nueva factura
    def show_draft(self):
        self.Lines.delete(*self.Lines.get_children())
        for i, line in enumerate(self.lines):
            self.Lines.insert("", "end", iid=str(i),
                              values=(line["product"], line["qty"], money(line["price"]),
                                      line["vat"], money(line["amount"])))
        subtotal, vat, total = totals(self.lines)
        self.DraftTotals.configure(
            text="%s: %s\\n%s: %s\\n%s: %s" % (
                ${_py(t(markTr('Base imponible')))}, money(subtotal), ${_py(t(markTr('IVA')))}, money(vat),
                ${_py(t(markTr('Total')))}, money(total))
        )

    def BtnAddLine_click(self):
        index = self.InvProduct.current()
        if index < 0:
            return self.Status.set(${_py(t(markTr('Elija un producto.')))}, icon="info")
        try:
            qty = parse_number(self.InvQty_var.get())
            if qty <= 0:
                raise ValueError
        except (InvalidOperation, ValueError):
            return self.Status.set(${_py(t(markTr('La cantidad debe ser un número mayor que cero.')))}, icon="warning")
        self.lines.append(line_of(self.products[index]["id"], qty))
        self.show_draft()

    def BtnRemoveLine_click(self):
        chosen = self.Lines.selection()
        if chosen:
            del self.lines[int(chosen[0])]
            self.show_draft()

    def BtnClear_click(self):
        self.lines = []
        self.show_draft()

    def BtnIssue_click(self):
        if not self.lines:
            return self.Status.set(${_py(t(markTr('Añada al menos una línea.')))}, icon="warning")
        index = self.InvClient.current()
        if index < 0:
            return self.Status.set(${_py(t(markTr('Elija el cliente.')))}, icon="warning")
        date = self.InvDate_var.get().strip()
        try:
            datetime.date.fromisoformat(date)
        except ValueError:
            return self.Status.set(${_py(t(markTr('La fecha debe ser AAAA-MM-DD.')))}, icon="warning")
        number = issue(self.clients[index]["id"], date, self.lines)
        self.lines = []
        self.show_draft()
        self.load_invoices(select=number)
        self.Pages.select(0)
        self.Status.set(${_py(t(markTr('Factura {0} emitida.')))}.format(number), icon="check")

    # ------------------------------------------------ clientes y productos
    def BtnAddClient_click(self):
        name = self.ClientName_var.get().strip()
        if not name:
            return self.Status.set(${_py(t(markTr('Escriba el nombre del cliente.')))}, icon="warning")
        execute("INSERT INTO client (name, tax_id) VALUES (?, ?)", (name, self.ClientTax_var.get().strip()))
        self.ClientName_var.set("")
        self.ClientTax_var.set("")
        self.load_catalog()
        self.Status.set(${_py(t(markTr('Cliente añadido: {0}')))}.format(name), icon="check")

    def BtnAddProduct_click(self):
        code, name = self.ProdCode_var.get().strip().upper(), self.ProdName_var.get().strip()
        try:
            price = round2(parse_number(self.ProdPrice_var.get()))
            vat = parse_number(self.ProdVat_var.get() or "21")
        except (InvalidOperation, ValueError):
            return self.Status.set(${_py(t(markTr('El precio y el IVA deben ser números.')))}, icon="warning")
        if not code or not name:
            return self.Status.set(${_py(t(markTr('Escriba el código y el nombre del producto.')))}, icon="warning")
        execute("INSERT INTO product (code, name, price, vat) VALUES (?, ?, ?, ?)", (code, name, str(price), str(vat)))
        for var in (self.ProdCode_var, self.ProdName_var, self.ProdPrice_var, self.ProdVat_var):
            var.set("")
        self.load_catalog()
        self.Status.set(${_py(t(markTr('Producto añadido: {0}')))}.format(name), icon="check")
''';
  return TkExample(
    'web_invoicing',
    t(markTr('Facturador web')),
    t(
      markTr(
        'Facturas con líneas, IVA y numeración correlativa, clientes y productos, cobro y descarga de la factura.',
      ),
    ),
    design,
    code,
  );
}

// ------------------------------------------------------------------ blog
TkExample _blog(String Function(String) t) {
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  TkWidget button(String name, String text, int x, int y, int w) => _w(
    'Button',
    name,
    x,
    y,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  final pages = [t(markTr('Entradas')), t(markTr('Editor'))].join('\n');
  final design =
      TkDesign(
          width: 1000,
          height: 660,
          target: tkTargetWeb,
          props: {'title': t(markTr('Blog')), 'bg': _paper},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Heading', 16, 8, 600, 32, _title(t(markTr('Mi blog')))),
          _w('PageControl', 'Pages', 16, 48, 968, 576, {'pages': pages}),
          // Entradas.
          on(
            _w(
              'Label',
              'LblCategory',
              16,
              40,
              80,
              24,
              _label(t(markTr('Categoría'))),
            ),
            0,
          ),
          on(
            _w(
              'Combobox',
              'CategoryFilter',
              96,
              40,
              160,
              24,
              {'state': 'readonly'},
              {'select': 'CategoryFilter_select'},
            ),
            0,
          ),
          on(
            _w('Entry', 'Search', 264, 40, 152, 24, {}, {
              'key_up': 'Search_key_up',
            }),
            0,
          ),
          on(
            _w(
              'Treeview',
              'Posts',
              16,
              72,
              400,
              440,
              {
                'columns': [
                  'title|${t(markTr('Título'))}|200',
                  'category|${t(markTr('Categoría'))}|90',
                  'date|${t(markTr('Fecha'))}|110',
                ].join('\n'),
              },
              {'select': 'Posts_select'},
            ),
            0,
          ),
          on(
            button('BtnEdit', t(markTr('Editar la elegida')), 16, 520, 160),
            0,
          ),
          on(
            _w('Label', 'PostTitle', 432, 40, 520, 32, {
              ..._title(t(markTr('Elija una entrada')), size: 16),
              'fg': '#1b1d22',
            }),
            0,
          ),
          on(
            _w('Label', 'PostMeta', 432, 72, 520, 24, {
              'text': '',
              'anchor': 'w',
              'fg': '#5f6672',
            }),
            0,
          ),
          on(
            _w('Label', 'PostBody', 432, 104, 520, 224, {
              'text': '',
              'anchor': 'nw',
              'justify': 'left',
              'wraplength': 512,
            }),
            0,
          ),
          on(
            _w('Label', 'LblComments', 432, 336, 520, 24, {
              ..._label(t(markTr('Comentarios'))),
              'font_bold': true,
            }),
            0,
          ),
          on(
            _w('Treeview', 'Comments', 432, 360, 520, 120, {
              'columns': [
                'name|${t(markTr('Nombre'))}|120',
                'text|${t(markTr('Comentario'))}|400',
              ].join('\n'),
            }),
            0,
          ),
          on(_w('Entry', 'CommentName', 432, 488, 144, 24), 0),
          on(_w('Entry', 'CommentText', 584, 488, 248, 24), 0),
          on(button('BtnComment', t(markTr('Comentar')), 840, 484, 112), 0),
          on(
            _w('Label', 'CommentHint', 432, 516, 520, 24, {
              'text': t(
                markTr(
                  'Su nombre (2-60 letras) y su comentario (3-500 letras).',
                ),
              ),
              'anchor': 'w',
              'fg': '#5f6672',
            }),
            0,
          ),
          // Editor.
          on(
            _w(
              'Label',
              'LblEdTitle',
              16,
              40,
              96,
              24,
              _label(t(markTr('Título'))),
            ),
            1,
          ),
          on(_w('Entry', 'EdTitle', 112, 40, 520, 24), 1),
          on(
            _w(
              'Label',
              'LblEdSlug',
              648,
              40,
              48,
              24,
              _label(t(markTr('Ruta'))),
            ),
            1,
          ),
          on(_w('Entry', 'EdSlug', 696, 40, 256, 24), 1),
          on(
            _w(
              'Label',
              'LblEdCategory',
              16,
              72,
              96,
              24,
              _label(t(markTr('Categoría'))),
            ),
            1,
          ),
          on(_w('Entry', 'EdCategory', 112, 72, 200, 24), 1),
          on(
            _w(
              'Label',
              'LblEdDate',
              328,
              72,
              56,
              24,
              _label(t(markTr('Fecha'))),
            ),
            1,
          ),
          on(_w('Entry', 'EdDate', 384, 72, 120, 24), 1),
          on(
            _w('Checkbutton', 'EdPublished', 520, 72, 160, 24, {
              'text': t(markTr('Publicada')),
            }),
            1,
          ),
          on(
            _w(
              'Label',
              'LblEdSummary',
              16,
              104,
              96,
              24,
              _label(t(markTr('Resumen'))),
            ),
            1,
          ),
          on(_w('Entry', 'EdSummary', 112, 104, 840, 24), 1),
          on(
            _w(
              'Label',
              'LblEdBody',
              16,
              136,
              96,
              24,
              _label(t(markTr('Contenido'))),
            ),
            1,
          ),
          on(_w('Text', 'EdBody', 112, 136, 840, 336), 1),
          on(
            _w('Label', 'EdHint', 112, 476, 840, 24, {
              'text': t(
                markTr(
                  'Formato sencillo: «# » para un título, «- » para una lista y **negrita**.',
                ),
              ),
              'anchor': 'w',
              'fg': '#5f6672',
            }),
            1,
          ),
          on(button('BtnNewPost', t(markTr('Nueva')), 112, 508, 112), 1),
          on(button('BtnSavePost', t(markTr('Guardar')), 232, 508, 112), 1),
          on(button('BtnDeletePost', t(markTr('Eliminar')), 352, 508, 112), 1),
          _w('StatusBar', 'Status', 0, 636, 1000, 24, {
            'text': t(markTr('Listo')),
            'icon': 'edit',
          }),
        ]);
  final code =
      '''import unicodedata
$_sqlImports
DB = "blog.sqlite"
CENT = Decimal("0.01")
ALL = ${_py(t(markTr('Todas')))}
DRAFT = ${_py(t(markTr('borrador')))}
$_sqlHelpers

def create_tables():
    execute("""CREATE TABLE IF NOT EXISTS post (
        id INTEGER PRIMARY KEY, title TEXT NOT NULL, slug TEXT NOT NULL UNIQUE,
        summary TEXT NOT NULL DEFAULT '', body TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT '', date TEXT NOT NULL, published INTEGER NOT NULL DEFAULT 1)""")
    execute("""CREATE TABLE IF NOT EXISTS comment (
        id INTEGER PRIMARY KEY, post_id INTEGER NOT NULL, name TEXT NOT NULL,
        text TEXT NOT NULL, date TEXT NOT NULL)""")
    if query("SELECT COUNT(*) AS n FROM post")[0]["n"]:
        return
    today = datetime.date.today()
    for days, title, category, summary, body in [
        (0, ${_py(t(markTr('Bienvenida')))}, ${_py(t(markTr('Noticias')))},
         ${_py(t(markTr('Primera entrada del blog.')))},
         ${_py(t(markTr('# Hola\nEste blog está hecho con **DMarlon Studio** y Flask.\n- Entradas con categorías\n- Comentarios\n- Editor sencillo')))}),
        (2, ${_py(t(markTr('Diseñar sin código')))}, ${_py(t(markTr('Tutoriales')))},
         ${_py(t(markTr('Cómo se diseña una ventana arrastrando componentes.')))},
         ${_py(t(markTr('Arrastre componentes desde la paleta y escriba solo el código de los eventos.')))}),
        (5, ${_py(t(markTr('Ideas para la próxima versión')))}, ${_py(t(markTr('Noticias')))},
         ${_py(t(markTr('Lo que viene.')))},
         ${_py(t(markTr('- Más componentes\n- Más destinos\n- Más ejemplos')))}),
    ]:
        date = (today - datetime.timedelta(days=days)).isoformat()
        execute("INSERT INTO post (title, slug, summary, body, category, date) VALUES (?, ?, ?, ?, ?, ?)",
                (title, slugify(title), summary, body, category, date))
    execute("INSERT INTO comment (post_id, name, text, date) VALUES (1, ?, ?, ?)",
            ("Ana", ${_py(t(markTr('¡Enhorabuena por el blog!')))}, today.isoformat()))


def slugify(text):
    plain = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    slug = "".join(c if c.isalnum() else "-" for c in plain)
    while "--" in slug:
        slug = slug.replace("--", "-")
    return slug.strip("-") or "entrada"


def render(body):
    """Formato sencillo como texto: nunca se interpreta HTML del autor."""
    lines = []
    for line in body.splitlines():
        if line.startswith("# "):
            line = line[2:].upper()
        elif line.startswith("- "):
            line = "  • " + line[2:]
        lines.append(line.replace("**", ""))
    return "\\n".join(lines)


class Form1(FormDesign):
    def form_create(self):
        create_tables()
        self.post_id = None
        self.editing = None
        self.load()
        self.BtnNewPost_click()

    # ------------------------------------------------------------ entradas
    def load(self, select=None):
        categories = [r["category"] for r in query("SELECT DISTINCT category FROM post ORDER BY category")]
        chosen = self.CategoryFilter.get()
        self.CategoryFilter.configure(values=[ALL] + categories)
        self.CategoryFilter_var.set(chosen if chosen in categories else ALL)
        like = "%" + self.Search_var.get().strip() + "%"
        where, args = "(title LIKE ? OR summary LIKE ? OR body LIKE ?)", [like, like, like]
        if self.CategoryFilter_var.get() != ALL:
            where += " AND category = ?"
            args.append(self.CategoryFilter_var.get())
        rows = query("SELECT * FROM post WHERE " + where + " ORDER BY date DESC, id DESC", args)
        self.Posts.delete(*self.Posts.get_children())
        for row in rows:
            title = row["title"] if row["published"] else "%s (%s)" % (row["title"], DRAFT)
            day = datetime.date.fromisoformat(row["date"]).strftime("%d/%m/%Y")
            self.Posts.insert("", "end", iid=str(row["id"]), values=(title, row["category"], day))
        if select is not None and str(select) in self.Posts.get_children():
            self.Posts.selection_set(str(select))
            self.show(select)
        self.Status.set(${_py(t(markTr('{0} entradas')))}.format(len(rows)), icon="edit")

    def show(self, post_id):
        rows = query("SELECT * FROM post WHERE id = ?", (post_id,))
        if not rows:
            return
        post = rows[0]
        self.post_id = post["id"]
        day = datetime.date.fromisoformat(post["date"]).strftime("%d/%m/%Y")
        self.PostTitle.configure(text=post["title"])
        self.PostMeta.configure(text="%s · %s · /%s" % (day, post["category"], post["slug"]))
        self.PostBody.configure(text=(post["summary"] + "\\n\\n" if post["summary"] else "") + render(post["body"]))
        self.Comments.delete(*self.Comments.get_children())
        for c in query("SELECT * FROM comment WHERE post_id = ? ORDER BY id", (post["id"],)):
            self.Comments.insert("", "end", iid=str(c["id"]), values=(c["name"], c["text"]))

    def Posts_select(self, event=None):
        chosen = self.Posts.selection()
        if chosen:
            self.show(int(chosen[0]))

    def Search_key_up(self, event=None):
        self.load()

    def CategoryFilter_select(self, event=None):
        self.load()

    def BtnComment_click(self):
        if self.post_id is None:
            return self.Status.set(${_py(t(markTr('Elija la entrada que quiere comentar.')))}, icon="info")
        name, text = self.CommentName_var.get().strip(), self.CommentText_var.get().strip()
        if not 2 <= len(name) <= 60 or not 3 <= len(text) <= 500:
            return self.Status.set(${_py(t(markTr('Escriba su nombre (2-60 letras) y un comentario (3-500 letras).')))}, icon="warning")
        execute("INSERT INTO comment (post_id, name, text, date) VALUES (?, ?, ?, ?)",
                (self.post_id, name, text, datetime.date.today().isoformat()))
        self.CommentText_var.set("")
        self.show(self.post_id)
        self.Status.set(${_py(t(markTr('Gracias por comentar.')))}, icon="check")

    # -------------------------------------------------------------- editor
    def BtnEdit_click(self):
        if self.post_id is None:
            return self.Status.set(${_py(t(markTr('Elija la entrada que quiere editar.')))}, icon="info")
        post = query("SELECT * FROM post WHERE id = ?", (self.post_id,))[0]
        self.editing = post["id"]
        self.EdTitle_var.set(post["title"])
        self.EdSlug_var.set(post["slug"])
        self.EdCategory_var.set(post["category"])
        self.EdDate_var.set(post["date"])
        self.EdSummary_var.set(post["summary"])
        self.EdPublished_var.set(post["published"])
        self.EdBody.delete("1.0", "end")
        self.EdBody.insert("1.0", post["body"])
        self.Pages.select(1)

    def BtnNewPost_click(self):
        self.editing = None
        for var in (self.EdTitle_var, self.EdSlug_var, self.EdSummary_var):
            var.set("")
        self.EdCategory_var.set(${_py(t(markTr('Noticias')))})
        self.EdDate_var.set(datetime.date.today().isoformat())
        self.EdPublished_var.set(1)
        self.EdBody.delete("1.0", "end")

    def BtnSavePost_click(self):
        title = self.EdTitle_var.get().strip()
        if not title:
            return self.Status.set(${_py(t(markTr('Escriba el título.')))}, icon="warning")
        slug = slugify(self.EdSlug_var.get().strip() or title)
        date = self.EdDate_var.get().strip()
        try:
            datetime.date.fromisoformat(date)
        except ValueError:
            return self.Status.set(${_py(t(markTr('La fecha debe ser AAAA-MM-DD.')))}, icon="warning")
        taken = query("SELECT id FROM post WHERE slug = ? AND id != ?", (slug, self.editing or 0))
        if taken:
            return self.Status.set(${_py(t(markTr('Ya hay otra entrada con la ruta «{0}».')))}.format(slug), icon="warning")
        data = (title, slug, self.EdSummary_var.get().strip(), self.EdBody.get("1.0", "end").rstrip(),
                self.EdCategory_var.get().strip(), date, 1 if self.EdPublished_var.get() else 0)
        if self.editing is None:
            self.editing = execute(
                "INSERT INTO post (title, slug, summary, body, category, date, published)"
                " VALUES (?, ?, ?, ?, ?, ?, ?)", data)
        else:
            execute("UPDATE post SET title = ?, slug = ?, summary = ?, body = ?, category = ?, date = ?,"
                    " published = ? WHERE id = ?", data + (self.editing,))
        self.EdSlug_var.set(slug)
        self.load(select=self.editing)
        self.Status.set(${_py(t(markTr('Entrada guardada: {0}')))}.format(title), icon="check")

    def BtnDeletePost_click(self):
        if self.editing is None:
            return self.Status.set(${_py(t(markTr('Abra en el editor la entrada que quiere eliminar.')))}, icon="info")
        execute("DELETE FROM comment WHERE post_id = ?", (self.editing,))
        execute("DELETE FROM post WHERE id = ?", (self.editing,))
        if self.post_id == self.editing:
            self.post_id = None
        self.BtnNewPost_click()
        self.load()
        self.Status.set(${_py(t(markTr('Entrada eliminada.')))}, icon="delete")
''';
  return TkExample(
    'web_blog',
    t(markTr('Blog web')),
    t(
      markTr(
        'Entradas con categorías, búsqueda, comentarios y un editor sencillo, guardadas en SQLite.',
      ),
    ),
    design,
    code,
  );
}

// ----------------------------------------------------------------- tienda
TkExample _shop(String Function(String) t) {
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  TkWidget button(String name, String text, int x, int y, int w) => _w(
    'Button',
    name,
    x,
    y,
    w,
    32,
    {'text': text},
    {'command': '${name}_click'},
  );
  final pages = [
    t(markTr('Catálogo')),
    t(markTr('Carrito')),
    t(markTr('Pedidos')),
  ].join('\n');
  final design =
      TkDesign(
          width: 1000,
          height: 640,
          target: tkTargetWeb,
          props: {'title': t(markTr('Mi Tienda')), 'bg': '#fbf7f2'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Heading', 16, 8, 600, 32, {
            ..._title(t(markTr('Mi Tienda'))),
            'fg': '#8a4b2a',
          }),
          _w('Label', 'CartBadge', 680, 8, 304, 32, {
            'text': '',
            'anchor': 'e',
            'fg': '#8a4b2a',
            'font_bold': true,
          }),
          _w('PageControl', 'Pages', 16, 48, 968, 552, {'pages': pages}),
          // Catálogo.
          on(
            _w(
              'Label',
              'LblCategory',
              16,
              40,
              80,
              24,
              _label(t(markTr('Categoría'))),
            ),
            0,
          ),
          on(
            _w(
              'Combobox',
              'Category',
              96,
              40,
              176,
              24,
              {'state': 'readonly'},
              {'select': 'Category_select'},
            ),
            0,
          ),
          on(
            _w('Entry', 'Search', 288, 40, 248, 24, {}, {
              'key_up': 'Search_key_up',
            }),
            0,
          ),
          on(
            _w(
              'Treeview',
              'Products',
              16,
              72,
              520,
              440,
              {
                'columns': [
                  'name|${t(markTr('Producto'))}|240',
                  'category|${t(markTr('Categoría'))}|110',
                  'price|${t(markTr('Precio'))}|100',
                  'stock|${t(markTr('Existencias'))}|70',
                ].join('\n'),
              },
              {'select': 'Products_select'},
            ),
            0,
          ),
          on(
            _w('Image', 'ProductImage', 552, 40, 400, 200, {
              'file': 'images/tienda_placeholder.png',
              'fit': 'cover',
            }),
            0,
          ),
          on(
            _w('Label', 'ProductName', 552, 248, 400, 32, {
              ..._title(t(markTr('Elija un producto')), size: 16),
              'fg': '#1b1d22',
            }),
            0,
          ),
          on(
            _w('Label', 'ProductCategory', 552, 280, 400, 24, {
              'text': '',
              'anchor': 'w',
              'fg': '#5f6672',
            }),
            0,
          ),
          on(
            _w('Label', 'ProductInfo', 552, 304, 400, 96, {
              'text': '',
              'anchor': 'nw',
              'justify': 'left',
              'wraplength': 392,
            }),
            0,
          ),
          on(
            _w('Label', 'ProductPrice', 552, 400, 400, 32, {
              'text': '',
              'anchor': 'w',
              'fg': '#8a4b2a',
              'font_size': 18,
              'font_bold': true,
            }),
            0,
          ),
          on(
            _w(
              'Label',
              'LblQty',
              552,
              444,
              72,
              24,
              _label(t(markTr('Cantidad'))),
            ),
            0,
          ),
          on(_w('Entry', 'Qty', 624, 444, 64, 24), 0),
          on(
            button(
              'BtnAddToCart',
              t(markTr('Añadir al carrito')),
              704,
              440,
              176,
            ),
            0,
          ),
          // Carrito.
          on(
            _w('Treeview', 'Cart', 16, 40, 600, 352, {
              'columns': [
                'product|${t(markTr('Producto'))}|280',
                'qty|${t(markTr('Cantidad'))}|80',
                'price|${t(markTr('Precio'))}|110',
                'amount|${t(markTr('Importe'))}|130',
              ].join('\n'),
            }),
            1,
          ),
          on(button('BtnLess', '−1', 16, 400, 64), 1),
          on(button('BtnMore', '+1', 88, 400, 64), 1),
          on(button('BtnRemove', t(markTr('Quitar')), 160, 400, 112), 1),
          on(
            _w('Label', 'CartTotals', 296, 400, 320, 72, {
              'text': '',
              'anchor': 'ne',
              'justify': 'right',
              'font_size': 13,
            }),
            1,
          ),
          on(
            _w('Label', 'LblCheckout', 640, 40, 312, 24, {
              ..._label(t(markTr('Datos de envío'))),
              'font_bold': true,
            }),
            1,
          ),
          on(
            _w(
              'Label',
              'LblName',
              640,
              72,
              312,
              24,
              _label(t(markTr('Nombre'))),
            ),
            1,
          ),
          on(_w('Entry', 'CustomerName', 640, 96, 312, 24), 1),
          on(
            _w(
              'Label',
              'LblEmail',
              640,
              128,
              312,
              24,
              _label(t(markTr('Correo'))),
            ),
            1,
          ),
          on(_w('Entry', 'CustomerEmail', 640, 152, 312, 24), 1),
          on(
            _w(
              'Label',
              'LblAddress',
              640,
              184,
              312,
              24,
              _label(t(markTr('Dirección'))),
            ),
            1,
          ),
          on(_w('Text', 'CustomerAddress', 640, 208, 312, 88), 1),
          on(
            button('BtnCheckout', t(markTr('Confirmar pedido')), 640, 312, 312),
            1,
          ),
          on(
            _w('Label', 'PaymentNote', 640, 352, 312, 48, {
              'text': t(
                markTr('Pago simulado: es un ejemplo,\nno se cobra nada.'),
              ),
              'anchor': 'nw',
              'justify': 'left',
              'fg': '#5f6672',
            }),
            1,
          ),
          // Pedidos.
          on(
            _w(
              'Treeview',
              'Orders',
              16,
              40,
              936,
              288,
              {
                'columns': [
                  'number|${t(markTr('Pedido'))}|110',
                  'date|${t(markTr('Fecha'))}|100',
                  'customer|${t(markTr('Cliente'))}|300',
                  'total|${t(markTr('Total'))}|120',
                  'status|${t(markTr('Estado'))}|120',
                ].join('\n'),
              },
              {'select': 'Orders_select'},
            ),
            2,
          ),
          on(
            _w('Label', 'OrderDetail', 16, 336, 736, 160, {
              'text': '',
              'anchor': 'nw',
              'justify': 'left',
            }),
            2,
          ),
          on(
            button(
              'BtnShipped',
              t(markTr('Marcar como enviado')),
              768,
              336,
              184,
            ),
            2,
          ),
          _w('StatusBar', 'Status', 0, 616, 1000, 24, {
            'text': t(markTr('Bienvenido a Mi Tienda')),
            'icon': 'home',
          }),
        ]);
  final code =
      '''import os
import struct
import zlib
$_sqlImports
DB = "tienda.sqlite"
CENT = Decimal("0.01")
ALL = ${_py(t(markTr('Todas')))}
CATEGORIES = {
    "ropa": (${_py(t(markTr('Ropa')))}, (196, 120, 82)),
    "hogar": (${_py(t(markTr('Hogar')))}, (96, 140, 120)),
    "libros": (${_py(t(markTr('Libros')))}, (88, 108, 160)),
}
STATUS = {"new": ${_py(t(markTr('Nuevo')))}, "shipped": ${_py(t(markTr('Enviado')))}}
$_sqlHelpers

def create_tables():
    execute("""CREATE TABLE IF NOT EXISTS product (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '', price TEXT NOT NULL, vat TEXT NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0)""")
    execute("""CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY, number TEXT NOT NULL, date TEXT NOT NULL, name TEXT NOT NULL,
        email TEXT NOT NULL, address TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'new',
        subtotal TEXT NOT NULL, vat TEXT NOT NULL, total TEXT NOT NULL)""")
    execute("""CREATE TABLE IF NOT EXISTS order_line (
        id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, product TEXT NOT NULL,
        qty INTEGER NOT NULL, price TEXT NOT NULL, amount TEXT NOT NULL)""")
    if query("SELECT COUNT(*) AS n FROM product")[0]["n"]:
        return
    for row in [
        (${_py(t(markTr('Camiseta de algodón')))}, "ropa", ${_py(t(markTr('Algodón orgánico, corte clásico.')))}, "19.90", "21", 25),
        (${_py(t(markTr('Sudadera con capucha')))}, "ropa", ${_py(t(markTr('Felpa suave, bolsillo delantero.')))}, "39.00", "21", 12),
        (${_py(t(markTr('Taza de cerámica')))}, "hogar", ${_py(t(markTr('350 ml, apta para lavavajillas.')))}, "9.50", "21", 40),
        (${_py(t(markTr('Lámpara de mesa')))}, "hogar", ${_py(t(markTr('Luz cálida regulable.')))}, "45.00", "21", 6),
        (${_py(t(markTr('Guía de Python')))}, "libros", ${_py(t(markTr('Del primer programa a las ventanas.')))}, "29.00", "4", 15),
        (${_py(t(markTr('Cuaderno de bocetos')))}, "libros", ${_py(t(markTr('A5, 120 hojas de papel grueso.')))}, "12.00", "21", 30),
    ]:
        execute("INSERT INTO product (name, category, description, price, vat, stock) VALUES (?, ?, ?, ?, ?, ?)", row)


def write_png(path, rgb, width=160, height=80):
    """Imagen lisa de un color, sin bibliotecas: hace de foto de ejemplo."""
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    row = b"\\x00" + bytes(rgb) * width
    data = (b"\\x89PNG\\r\\n\\x1a\\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(row * height)) + chunk(b"IEND", b""))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)


def image_of(category):
    path = "images/tienda_%s.png" % category
    if not os.path.exists(path):
        write_png(path, CATEGORIES.get(category, ("", (180, 180, 180)))[1])
    return path


def gross(price, vat):
    return round2(Decimal(price) * (1 + Decimal(vat) / 100))


class Form1(FormDesign):
    def form_create(self):
        create_tables()
        self.ProductImage_load(image_of("placeholder"))
        self.cart = {}
        self.product_id = None
        self.order_id = None
        self.Category.configure(values=[ALL] + [label for label, _ in CATEGORIES.values()])
        self.Category.current(0)
        self.Qty_var.set("1")
        self.load_products()
        self.show_cart()
        self.load_orders()

    # ------------------------------------------------------------ catálogo
    def load_products(self):
        like = "%" + self.Search_var.get().strip() + "%"
        where, args = "(name LIKE ? OR description LIKE ?)", [like, like]
        index = self.Category.current()
        if index > 0:
            where += " AND category = ?"
            args.append(list(CATEGORIES)[index - 1])
        self.Products.delete(*self.Products.get_children())
        for p in query("SELECT * FROM product WHERE " + where + " ORDER BY category, name", args):
            self.Products.insert("", "end", iid=str(p["id"]),
                                 values=(p["name"], CATEGORIES[p["category"]][0],
                                         money(gross(p["price"], p["vat"])), p["stock"]))

    def Products_select(self, event=None):
        chosen = self.Products.selection()
        rows = query("SELECT * FROM product WHERE id = ?", (int(chosen[0]),)) if chosen else []
        if not rows:
            return
        p = rows[0]
        self.product_id = p["id"]
        self.ProductImage_load(image_of(p["category"]))
        self.ProductName.configure(text=p["name"])
        self.ProductCategory.configure(text=CATEGORIES[p["category"]][0])
        self.ProductInfo.configure(text=p["description"] + "\\n\\n" + ${_py(t(markTr('{0} en existencias · IVA {1} % incluido')))}.format(p["stock"], p["vat"]))
        self.ProductPrice.configure(text=money(gross(p["price"], p["vat"])))

    def Category_select(self, event=None):
        self.load_products()

    def Search_key_up(self, event=None):
        self.load_products()

    def BtnAddToCart_click(self):
        if self.product_id is None:
            return self.Status.set(${_py(t(markTr('Elija un producto del catálogo.')))}, icon="info")
        try:
            qty = int(self.Qty_var.get().strip())
            if qty <= 0:
                raise ValueError
        except ValueError:
            return self.Status.set(${_py(t(markTr('La cantidad debe ser un número entero mayor que cero.')))}, icon="warning")
        stock = query("SELECT stock, name FROM product WHERE id = ?", (self.product_id,))[0]
        wanted = self.cart.get(self.product_id, 0) + qty
        if wanted > stock["stock"]:
            return self.Status.set(${_py(t(markTr('Solo quedan {0} unidades.')))}.format(stock["stock"]), icon="warning")
        self.cart[self.product_id] = wanted
        self.show_cart()
        self.Status.set(${_py(t(markTr('Añadido al carrito: {0}')))}.format(stock["name"]), icon="check")

    # ------------------------------------------------------------- carrito
    def cart_lines(self):
        lines = []
        for product_id, qty in self.cart.items():
            p = query("SELECT * FROM product WHERE id = ?", (product_id,))[0]
            price = Decimal(p["price"])
            amount = round2(price * qty)
            lines.append({"id": product_id, "product": p["name"], "qty": qty, "price": price,
                          "vat": Decimal(p["vat"]), "amount": amount})
        return lines

    def cart_totals(self, lines):
        subtotal = round2(sum((l["amount"] for l in lines), Decimal(0)))
        vat = round2(sum((l["amount"] * l["vat"] / 100 for l in lines), Decimal(0)))
        return subtotal, vat, subtotal + vat

    def show_cart(self, select=None):
        lines = self.cart_lines()
        self.Cart.delete(*self.Cart.get_children())
        for l in lines:
            self.Cart.insert("", "end", iid=str(l["id"]),
                             values=(l["product"], l["qty"], money(l["price"]), money(l["amount"])))
        if select is not None and str(select) in self.Cart.get_children():
            self.Cart.selection_set(str(select))
        subtotal, vat, total = self.cart_totals(lines)
        self.CartTotals.configure(text="%s: %s\\n%s: %s\\n%s: %s" % (
            ${_py(t(markTr('Subtotal')))}, money(subtotal), ${_py(t(markTr('IVA')))}, money(vat),
            ${_py(t(markTr('Total')))}, money(total)))
        units = sum(self.cart.values())
        self.CartBadge.configure(text=${_py(t(markTr('Carrito: {0} artículos · {1}')))}.format(units, money(total)))

    def chosen_line(self):
        chosen = self.Cart.selection()
        if not chosen:
            self.Status.set(${_py(t(markTr('Elija una línea del carrito.')))}, icon="info")
            return None
        return int(chosen[0])

    def BtnLess_click(self):
        product_id = self.chosen_line()
        if product_id is not None:
            self.cart[product_id] -= 1
            if self.cart[product_id] <= 0:
                del self.cart[product_id]
            self.show_cart(select=product_id)

    def BtnMore_click(self):
        product_id = self.chosen_line()
        if product_id is not None:
            stock = query("SELECT stock FROM product WHERE id = ?", (product_id,))[0]["stock"]
            if self.cart[product_id] < stock:
                self.cart[product_id] += 1
            self.show_cart(select=product_id)

    def BtnRemove_click(self):
        product_id = self.chosen_line()
        if product_id is not None:
            self.cart.pop(product_id, None)
            self.show_cart()

    def BtnCheckout_click(self):
        lines = self.cart_lines()
        if not lines:
            return self.Status.set(${_py(t(markTr('El carrito está vacío.')))}, icon="info")
        name = self.CustomerName_var.get().strip()
        email = self.CustomerEmail_var.get().strip()
        address = self.CustomerAddress.get("1.0", "end").strip()
        if not name or not address or "@" not in email or "." not in email.split("@")[-1]:
            return self.Status.set(${_py(t(markTr('Escriba su nombre, un correo válido y la dirección de envío.')))}, icon="warning")
        for l in lines:
            stock = query("SELECT stock FROM product WHERE id = ?", (l["id"],))[0]["stock"]
            if l["qty"] > stock:
                return self.Status.set(${_py(t(markTr('No hay existencias suficientes de {0}.')))}.format(l["product"]), icon="warning")
        subtotal, vat, total = self.cart_totals(lines)
        count = query("SELECT COUNT(*) AS n FROM orders")[0]["n"]
        number = "P-%05d" % (count + 1)
        order_id = execute(
            "INSERT INTO orders (number, date, name, email, address, subtotal, vat, total)"
            " VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (number, datetime.date.today().isoformat(), name, email, address, str(subtotal), str(vat), str(total)),
        )
        for l in lines:
            execute("INSERT INTO order_line (order_id, product, qty, price, amount) VALUES (?, ?, ?, ?, ?)",
                    (order_id, l["product"], l["qty"], str(l["price"]), str(l["amount"])))
            execute("UPDATE product SET stock = stock - ? WHERE id = ?", (l["qty"], l["id"]))
        self.cart = {}
        self.show_cart()
        self.load_products()
        self.load_orders(select=order_id)
        self.Status.set(${_py(t(markTr('Pedido {0} confirmado (pago simulado). ¡Gracias!')))}.format(number), icon="check")

    # ------------------------------------------------------------- pedidos
    def load_orders(self, select=None):
        self.Orders.delete(*self.Orders.get_children())
        for o in query("SELECT * FROM orders ORDER BY id DESC"):
            day = datetime.date.fromisoformat(o["date"]).strftime("%d/%m/%Y")
            self.Orders.insert("", "end", iid=str(o["id"]),
                               values=(o["number"], day, o["name"], money(o["total"]), STATUS[o["status"]]))
        if select is not None:
            self.Orders.selection_set(str(select))
            self.show_order(select)

    def show_order(self, order_id):
        rows = query("SELECT * FROM orders WHERE id = ?", (order_id,))
        if not rows:
            return
        o = rows[0]
        self.order_id = o["id"]
        lines = query("SELECT * FROM order_line WHERE order_id = ? ORDER BY id", (o["id"],))
        detail = ["%s · %s · %s" % (o["number"], o["name"], o["email"]), o["address"].replace("\\n", ", "), ""]
        detail += ["%d × %s = %s" % (l["qty"], l["product"], money(l["amount"])) for l in lines]
        detail += ["", "%s: %s" % (${_py(t(markTr('Total')))}, money(o["total"]))]
        self.OrderDetail.configure(text="\\n".join(detail))

    def Orders_select(self, event=None):
        chosen = self.Orders.selection()
        if chosen:
            self.show_order(int(chosen[0]))

    def BtnShipped_click(self):
        if self.order_id is None:
            return self.Status.set(${_py(t(markTr('Elija un pedido.')))}, icon="info")
        execute("UPDATE orders SET status = 'shipped' WHERE id = ?", (self.order_id,))
        self.load_orders(select=self.order_id)
        self.Status.set(${_py(t(markTr('Pedido marcado como enviado.')))}, icon="check")
''';
  return TkExample(
    'web_shop',
    t(markTr('Tienda web')),
    t(
      markTr(
        'Tienda con catálogo por categorías, carrito con IVA, pedido con pago simulado y gestión de envíos.',
      ),
    ),
    design,
    code,
  );
}

// -------------------------------------------------- reproductor de música
TkExample _music(String Function(String) t) {
  final file = t(markTr('Archivo')), playMenu = t(markTr('Reproducción'));
  final add = t(markTr('Añadir canciones…')),
      clear = t(markTr('Vaciar la lista'));
  final quit = t(markTr('Salir'));
  final playPause = t(markTr('Reproducir / pausa')),
      stop = t(markTr('Detener'));
  final next = t(markTr('Siguiente')), prev = t(markTr('Anterior'));
  TkWidget button(String name, String text, int x, int w) => _w(
    'Button',
    name,
    x,
    344,
    w,
    36,
    {'text': text, 'font_size': 14},
    {'command': '${name}_click'},
  );
  final design =
      TkDesign(
          width: 560,
          height: 480,
          props: {
            'title': t(markTr('Reproductor de música')),
            'bg': _paper,
            'position': 'center',
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            520,
            8,
            32,
            32,
            {
              'items':
                  '$file\n  $add\n  $clear\n  -\n  $quit\n$playMenu\n  $playPause\n  $stop\n  -\n  $prev\n  $next',
            },
            {'command': 'Menu1_click'},
          ),
          _w(
            'Timer',
            'Clock',
            480,
            8,
            32,
            32,
            {'interval': 500, 'enabled': true},
            {'command': 'Clock_timer'},
          ),
          _w('OpenDialog', 'AddSongs', 440, 8, 32, 32, {
            'title': t(markTr('Añadir canciones')),
            'filter': '${t(markTr('Audio'))}|*.mp3;*.wav;*.ogg;*.m4a',
            'multiple': true,
          }),
          _w('Label', 'NowPlaying', 16, 12, 408, 32, {
            ..._title(t(markTr('Lista de reproducción')), size: 16),
          }),
          _w(
            'Listbox',
            'Playlist',
            16,
            52,
            528,
            216,
            {'font_size': 12},
            {'double': 'Playlist_double_click'},
          ),
          _w('Label', 'Elapsed', 16, 284, 64, 24, {
            'text': '0:00',
            'anchor': 'w',
          }),
          _w('Progressbar', 'Position', 80, 292, 400, 8, {'maximum': 100}),
          _w('Label', 'Total', 480, 284, 64, 24, {
            'text': '0:00',
            'anchor': 'e',
          }),
          button('BtnPrev', '◀◀', 16, 56),
          button('BtnPlay', '▶', 80, 72),
          button('BtnStop', '■', 160, 56),
          button('BtnNext', '▶▶', 224, 56),
          _w(
            'Label',
            'LblVolume',
            296,
            320,
            64,
            24,
            _label(t(markTr('Volumen'))),
          ),
          _w(
            'Scale',
            'Volume',
            296,
            344,
            248,
            36,
            {
              'from': 0,
              'to': 100,
              'value': 80,
              'orient': 'horizontal',
              'showvalue': false,
            },
            {'command': 'Volume_change'},
          ),
          _w(
            'Checkbutton',
            'Shuffle',
            16,
            396,
            160,
            24,
            {'text': t(markTr('Aleatorio'))},
            {'command': 'Options_click'},
          ),
          _w(
            'Checkbutton',
            'Repeat',
            184,
            396,
            200,
            24,
            {'text': t(markTr('Repetir la lista'))},
            {'command': 'Options_click'},
          ),
          _w('StatusBar', 'Status', 0, 456, 560, 24, {
            'text': '',
            'icon': 'info',
          }),
        ]);
  final code =
      '''import json
import os
import random
import shutil
import subprocess
import sys
import time

LIST_FILE = "playlist.json"
INSTALL = "python3 -m pip install pygame"
NOTHING = ${_py(t(markTr('Añada canciones con Archivo → Añadir canciones…')))}
DEGRADED = ${_py(t(markTr('Sin pygame: pausa, volumen y posición limitados. Instálelo con: {0}')))}
NO_AUDIO = ${_py(t(markTr('No hay forma de reproducir audio en este equipo. Instale pygame: {0}')))}
PLAYING = ${_py(t(markTr('Sonando: {0}')))}
PAUSED = ${_py(t(markTr('En pausa: {0}')))}
STOPPED = ${_py(t(markTr('Detenido')))}
CANT_PLAY = ${_py(t(markTr('No se pudo reproducir {0}: {1}')))}


def fmt_time(seconds):
    seconds = max(0, int(seconds or 0))
    return "%d:%02d" % (seconds // 60, seconds % 60)


def next_index(current, count, shuffle=False, repeat=False, step=1, rng=random):
    """La canción que sigue (o None al acabar la lista sin repetir)."""
    if count <= 0:
        return None
    if shuffle and count > 1:
        return rng.choice([i for i in range(count) if i != current])
    if current is None:
        return 0 if step > 0 else count - 1
    target = current + step
    if 0 <= target < count:
        return target
    return target % count if repeat else None


class PygamePlayer:
    """Reproducción completa con pygame.mixer: pausa, volumen y posición."""

    full = True

    def __init__(self, pygame):
        self.pygame = pygame
        pygame.mixer.init()
        self.length = None

    def play(self, path):
        self.pygame.mixer.music.load(path)
        self.pygame.mixer.music.play()
        try:
            self.length = self.pygame.mixer.Sound(path).get_length()
        except Exception:
            self.length = None

    def pause(self):
        self.pygame.mixer.music.pause()

    def resume(self):
        self.pygame.mixer.music.unpause()

    def stop(self):
        self.pygame.mixer.music.stop()

    def volume(self, value):
        self.pygame.mixer.music.set_volume(value)

    def position(self):
        return max(0.0, self.pygame.mixer.music.get_pos() / 1000.0)

    def finished(self):
        return not self.pygame.mixer.music.get_busy()


class SystemPlayer:
    """Sin pygame: el reproductor del sistema en otro proceso."""

    full = False

    def __init__(self, command):
        self.command = command
        self.process = None
        self.started = 0.0
        self.paused_at = None
        self.length = None

    def play(self, path):
        self.stop()
        if self.command == "winsound":
            import winsound
            winsound.PlaySound(path, winsound.SND_FILENAME | winsound.SND_ASYNC)
        else:
            self.process = subprocess.Popen(self.command + [path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.started = time.monotonic()
        self.paused_at = None

    def pause(self):
        if self.process is not None and hasattr(os, "kill"):
            import signal
            os.kill(self.process.pid, signal.SIGSTOP)
            self.paused_at = time.monotonic()

    def resume(self):
        if self.process is not None and self.paused_at is not None:
            import signal
            os.kill(self.process.pid, signal.SIGCONT)
            self.started += time.monotonic() - self.paused_at
            self.paused_at = None

    def stop(self):
        if self.command == "winsound":
            import winsound
            winsound.PlaySound(None, 0)
        if self.process is not None:
            self.process.terminate()
            self.process = None

    def volume(self, value):
        pass  # El reproductor del sistema no lo permite.

    def position(self):
        end = self.paused_at or time.monotonic()
        return end - self.started if self.started else 0.0

    def finished(self):
        return self.process is not None and self.process.poll() is not None


def make_player():
    """pygame si está; si no, el reproductor del sistema; None si nada."""
    try:
        import pygame
        return PygamePlayer(pygame)
    except Exception:
        pass
    if sys.platform == "darwin" and shutil.which("afplay"):
        return SystemPlayer(["afplay"])
    if sys.platform.startswith("win"):
        return SystemPlayer("winsound")
    for name, args in (("paplay", []), ("ffplay", ["-nodisp", "-autoexit", "-loglevel", "quiet"]), ("aplay", ["-q"])):
        if shutil.which(name):
            return SystemPlayer([name] + args)
    return None


class Form1(FormDesign):
    def form_create(self):
        self.songs = []
        self.current = None
        self.playing = False
        self.paused = False
        self.player = make_player()
        self.load_list()
        self.Volume_change(self.Volume_var.get())
        if self.player is None:
            self.Status.set(NO_AUDIO.format(INSTALL), icon="warning")
        elif not self.player.full:
            self.Status.set(DEGRADED.format(INSTALL), icon="warning")
        else:
            self.Status.set(NOTHING if not self.songs else STOPPED, icon="info")

    # ------------------------------------------------------------- lista
    def load_list(self):
        try:
            with open(LIST_FILE, encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError):
            data = {}
        self.songs = [str(p) for p in data.get("songs", []) if isinstance(p, str)]
        self.Shuffle_var.set(1 if data.get("shuffle") else 0)
        self.Repeat_var.set(1 if data.get("repeat") else 0)
        if "volume" in data:
            self.Volume_var.set(data["volume"])
        self.show_list()

    def save_list(self):
        data = {"songs": self.songs, "shuffle": bool(self.Shuffle_var.get()),
                "repeat": bool(self.Repeat_var.get()), "volume": self.Volume_var.get()}
        try:
            with open(LIST_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=1)
        except OSError:
            pass

    def show_list(self):
        self.Playlist.delete(0, "end")
        for i, path in enumerate(self.songs):
            mark = "▶  " if i == self.current else "    "
            self.Playlist.insert("end", mark + os.path.splitext(os.path.basename(path))[0])
        if self.current is not None:
            self.Playlist.selection_clear(0, "end")
            self.Playlist.selection_set(self.current)
            self.Playlist.see(self.current)

    def add_songs(self):
        chosen = self.AddSongs.execute()
        if not chosen:
            return
        paths = chosen if isinstance(chosen, list) else [chosen]
        self.songs.extend(p for p in paths if p not in self.songs)
        self.save_list()
        self.show_list()
        self.Status.set(${_py(t(markTr('{0} canciones en la lista.')))}.format(len(self.songs)), icon="check")

    # -------------------------------------------------------- reproducción
    def name(self, index):
        return os.path.basename(self.songs[index]) if index is not None else ""

    def play(self, index):
        if self.player is None or index is None or not 0 <= index < len(self.songs):
            return
        try:
            self.player.play(self.songs[index])
        except Exception as error:
            self.Status.set(CANT_PLAY.format(self.name(index), error), icon="warning")
            return
        self.current = index
        self.playing, self.paused = True, False
        self.BtnPlay.configure(text="❚❚")
        self.NowPlaying.configure(text=os.path.splitext(self.name(index))[0])
        self.Total.configure(text=fmt_time(self.player.length) if self.player.length else "–:––")
        self.Status.set(PLAYING.format(self.name(index)), icon="play")
        self.show_list()

    def toggle(self):
        if self.player is None:
            return
        if not self.playing:
            chosen = self.Playlist.curselection()
            return self.play(chosen[0] if chosen else (self.current if self.current is not None else 0))
        if self.paused:
            self.player.resume()
            self.paused = False
            self.BtnPlay.configure(text="❚❚")
            self.Status.set(PLAYING.format(self.name(self.current)), icon="play")
        else:
            self.player.pause()
            self.paused = True
            self.BtnPlay.configure(text="▶")
            self.Status.set(PAUSED.format(self.name(self.current)), icon="pause")

    def stop(self):
        if self.player is not None:
            self.player.stop()
        self.playing = self.paused = False
        self.BtnPlay.configure(text="▶")
        self.Position.configure(value=0)
        self.Elapsed.configure(text="0:00")
        self.Status.set(STOPPED, icon="info")

    def skip(self, step):
        index = next_index(self.current, len(self.songs), bool(self.Shuffle_var.get()),
                           repeat=True, step=step)
        if index is not None:
            self.play(index)

    # ------------------------------------------------------------- eventos
    def Clock_timer(self):
        if not self.playing or self.paused or self.player is None:
            return
        position = self.player.position()
        self.Elapsed.configure(text=fmt_time(position))
        length = self.player.length
        self.Position.configure(value=min(100, position * 100 / length) if length else 0)
        if self.player.finished():
            index = next_index(self.current, len(self.songs), bool(self.Shuffle_var.get()),
                               bool(self.Repeat_var.get()))
            if index is None:
                self.stop()
            else:
                self.play(index)

    def BtnPlay_click(self):
        self.toggle()

    def BtnStop_click(self):
        self.stop()

    def BtnNext_click(self):
        self.skip(1)

    def BtnPrev_click(self):
        self.skip(-1)

    def Playlist_double_click(self, event=None):
        chosen = self.Playlist.curselection()
        if chosen:
            self.play(chosen[0])

    def Volume_change(self, value):
        if self.player is not None:
            self.player.volume(float(value) / 100)

    def Options_click(self):
        self.save_list()

    def Menu1_click(self, item):
        if item == ${_py('$file/$add')}:
            self.add_songs()
        elif item == ${_py('$file/$clear')}:
            self.stop()
            self.songs, self.current = [], None
            self.save_list()
            self.show_list()
        elif item == ${_py('$file/$quit')}:
            self.form_close()
        elif item == ${_py('$playMenu/$playPause')}:
            self.toggle()
        elif item == ${_py('$playMenu/$stop')}:
            self.stop()
        elif item == ${_py('$playMenu/$next')}:
            self.skip(1)
        elif item == ${_py('$playMenu/$prev')}:
            self.skip(-1)

    def form_close(self, *args):
        if self.player is not None:
            self.player.stop()
        self.save_list()
        self.root.destroy()
''';
  return TkExample(
    'music_player',
    t(markTr('Reproductor de música')),
    t(
      markTr(
        'Lista de reproducción con aleatorio y repetición, volumen y posición, con pygame o el reproductor del sistema.',
      ),
    ),
    design,
    code,
  );
}
