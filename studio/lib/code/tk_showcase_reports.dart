part of 'tk_examples.dart';

// ---------------------------------------------------------------- informes
/// Informes en PDF y en Excel de una tabla de ventas, con los componentes
/// Informe PDF e Informe Excel (sin bibliotecas que instalar).
TkExample _reports(String Function(String) t) {
  final app = t(markTr('Informes'));
  final design =
      TkDesign(
          width: 820,
          height: 540,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('Label', 'Title', 16, 12, 520, 32, {
            ..._title(t(markTr('Ventas por producto'))),
            'bg': _paper,
          }),
          _w('Label', 'Intro', 16, 44, 788, 24, {
            ..._label(
              t(
                markTr(
                  'Exporte la tabla a PDF o a Excel con los componentes Informe PDF e Informe Excel: no hace falta instalar nada.',
                ),
              ),
            ),
            'bg': _paper,
          }),
          _w('Treeview', 'Sales', 16, 76, 788, 372, {
            'columns': [
              'product|${t(markTr('Producto'))}|260',
              'category|${t(markTr('Categoría'))}|160',
              'units|${t(markTr('Unidades'))}|100',
              'price|${t(markTr('Precio'))}|100',
              'total|${t(markTr('Importe'))}|120',
            ].join('\n'),
          }),
          _w(
            'Button',
            'BtnPdf',
            16,
            460,
            180,
            34,
            {'text': t(markTr('Exportar a PDF…'))},
            {'command': 'BtnPdf_click'},
          ),
          _w(
            'Button',
            'BtnExcel',
            208,
            460,
            180,
            34,
            {'text': t(markTr('Exportar a Excel…'))},
            {'command': 'BtnExcel_click'},
          ),
          _w(
            'Button',
            'BtnPreview',
            400,
            460,
            180,
            34,
            {'text': t(markTr('Ver el PDF'))},
            {'command': 'BtnPreview_click'},
          ),
          _w('PdfReport', 'Pdf1', 760, 12, 24, 24, {
            'title': t(markTr('Ventas por producto')),
            'filename': t(markTr('ventas.pdf')),
            'author': 'DMarlon Studio',
          }),
          _w('ExcelReport', 'Excel1', 790, 12, 24, 24, {
            'filename': t(markTr('ventas.xlsx')),
            'sheet': t(markTr('Ventas')),
          }),
          _w('StatusBar', 'Status', 0, 516, 820, 24, {
            'text': t(markTr('Listo')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import datetime
import random

TITLE = ${_py(t(markTr('Ventas por producto')))}
HEADERS = [${[t(markTr('Producto')), t(markTr('Categoría')), t(markTr('Unidades')), t(markTr('Precio')), t(markTr('Importe'))].map(_py).join(', ')}]
TOTAL = ${_py(t(markTr('Total')))}
SUMMARY = ${_py(t(markTr('Resumen')))}
BY_CATEGORY = ${_py(t(markTr('Por categoría')))}
GENERATED = ${_py(t(markTr('Generado el {0} · {1} productos · {2} unidades')))}
SAVED = ${_py(t(markTr('Guardado en {0}')))}
CATEGORIES = [${[t(markTr('Portátiles')), t(markTr('Tabletas')), t(markTr('Accesorios'))].map(_py).join(', ')}]


class Form1(FormDesign):
    def form_create(self):
        # Datos de ejemplo, siempre los mismos.
        rnd = random.Random(7)
        self.rows = []
        for i in range(1, 41):
            category = CATEGORIES[i % 3]
            units = rnd.randint(1, 60)
            price = round(rnd.uniform(9, 1400), 2)
            self.rows.append(["%s %02d" % (category, i), category, units, price, round(units * price, 2)])
        for r in self.rows:
            self.Sales.insert("", "end", values=(r[0], r[1], r[2], "%.2f" % r[3], "%.2f" % r[4]))
        self.Status.set(self.subtitle())

    def subtitle(self):
        return GENERATED.format(
            datetime.date.today().strftime("%d/%m/%Y"),
            len(self.rows),
            sum(r[2] for r in self.rows),
        )

    def totals(self):
        return [TOTAL, "", sum(r[2] for r in self.rows), "", round(sum(r[4] for r in self.rows), 2)]

    # ---------------------------------------------------------------- PDF
    def build_pdf(self):
        pdf = self.Pdf1.clear()
        pdf.title(TITLE).text(self.subtitle()).line()
        pdf.heading(BY_CATEGORY)
        per = {}
        for r in self.rows:
            units, amount = per.get(r[1], (0, 0.0))
            per[r[1]] = (units + r[2], amount + r[4])
        pdf.table(
            [HEADERS[1], HEADERS[2], HEADERS[4]],
            [[c, u, round(a, 2)] for c, (u, a) in sorted(per.items())],
        )
        pdf.heading(SUMMARY)
        pdf.table(HEADERS, self.rows, widths=[3, 2, 1, 1, 1.4], totals=self.totals())
        return pdf

    def BtnPdf_click(self):
        path = self.build_pdf().save_dialog()
        if path:
            self.Status.set(SAVED.format(path), icon="check")

    def BtnPreview_click(self):
        self.build_pdf().open()

    # -------------------------------------------------------------- Excel
    def BtnExcel_click(self):
        book = self.Excel1.clear()
        book.sheet(${_py(t(markTr('Ventas')))}).write_rows([HEADERS] + self.rows, header=True)
        book.write_row(self.totals())
        book.sheet(SUMMARY).write_row([TITLE]).write_row([self.subtitle()])
        path = book.save_dialog()
        if path:
            self.Status.set(SAVED.format(path), icon="check")

    def form_close(self, *args):
        self.root.destroy()
''';
  return TkExample(
    'reports',
    app,
    t(
      markTr(
        'Una tabla de ventas exportada a PDF (con totales, tabla por categoría y número de página) y a Excel (con varias hojas), sin instalar nada.',
      ),
    ),
    design,
    code,
  );
}
