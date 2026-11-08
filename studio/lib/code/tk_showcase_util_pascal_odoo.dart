part of 'tk_examples.dart';

// --------------------------------------------- Odoo sin conexión (Pascal)
/// Un cockpit de ventas al estilo de SAP Business One que trabaja con Odoo
/// 8 a 20 por JSON-RPC (las rutas del cliente web) y también sin conexión:
/// los datos se guardan en un JSON de la carpeta del usuario y los clientes
/// y presupuestos nuevos esperan en una bandeja de salida hasta que vuelve
/// la conexión. Los gráficos se dibujan en un TPaintBox.
TkExample tkUtilPascalOdoo(String Function(String) t) {
  const side = '#1b2a3a', sideFg = '#c5d0dc', sideMuted = '#8fa3b8';
  const paper = '#eef1f4', card = '#ffffff', ink = '#1d2939';
  const muted = '#5b6670', accent = '#0a6ed1', note = '#fff8e1';
  final app = t(markTr('Odoo sin conexión'));
  // Con contexto (msgctxt «bim»): «Presupuestos» y «Concepto» como en BIM 2.0.
  String tc(String ctx, String id) {
    final k = contextKey(ctx, id);
    final r = t(k);
    return r == k ? id : r;
  }

  final pageNames = [
    t(markTr('Panel')),
    t(markTr('Clientes')),
    t(markTr('Productos')),
    t(markTr('Ventas')),
    t(markTr('Punto de venta')),
    t(markTr('Sincronización')),
    t(markTr('Configuración')),
    t(markTr('Obras BIM')),
    t(markTr('Compras')),
  ];
  const navNames = [
    'NavPanel',
    'NavCustomers',
    'NavProducts',
    'NavSales',
    'NavPos',
    'NavSync',
    'NavSettings',
    'NavBim',
    'NavPurchases',
  ];
  // El hueco de cada botón en el menú: Compras va detrás de Ventas y Obras
  // BIM detrás del punto de venta (y, sin BIM en Odoo, se oculta y los de
  // abajo suben).
  const navSlot = [0, 1, 2, 3, 5, 7, 8, 6, 4];
  // Los componentes de una página llevan 24 px más en y: la fila de
  // pestañas, que la aplicación oculta (se navega con el menú lateral).
  const oy = 24;
  TkWidget inside(TkWidget w, String frame) => w..parent = frame;
  TkWidget onPage(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  TkWidget text(
    String name,
    int x,
    int y,
    int w,
    int h,
    String value, {
    String fg = ink,
    int size = 0,
    bool bold = false,
    String anchor = 'w',
  }) => _w('Label', name, x, y, w, h, {
    'text': value,
    'anchor': anchor,
    'fg': fg,
    if (size > 0) 'font_size': size,
    if (bold) 'font_bold': true,
  });
  TkWidget primary(String name, int x, int y, int w, int h, String value) =>
      _w(
        'Button',
        name,
        x,
        y,
        w,
        h,
        {'text': value, 'bg': accent, 'fg': '#ffffff', 'font_bold': true},
        {'command': '${name}_click'},
      );
  TkWidget button(String name, int x, int y, int w, int h, String value) =>
      _w('Button', name, x, y, w, h, {'text': value}, {
        'command': '${name}_click',
      });
  TkWidget box(String name, int x, int y, int w, int h, [String bg = card]) =>
      _w('Frame', name, x, y, w, h, {'bg': bg});

  final kpis = [
    ('KpiSales', t(markTr('Ventas del mes')), '#107e3e'),
    ('KpiQuotes', t(markTr('Presupuestos abiertos')), accent),
    ('KpiCustomers', t(markTr('Clientes')), '#5b4bc4'),
    ('KpiPending', t(markTr('Pendientes de enviar')), '#e9730c'),
  ];
  final custFields = [
    ('Name', t(markTr('Nombre *'))),
    ('Email', t(markTr('Correo electrónico'))),
    ('Phone', t(markTr('Teléfono'))),
    ('Street', t(markTr('Dirección'))),
    ('City', t(markTr('Ciudad'))),
    ('Vat', t(markTr('NIF'))),
  ];

  final design =
      TkDesign(
          width: 1100,
          height: 720,
          target: tkTargetPascal,
          props: {'title': app, 'bg': paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          // ---- menú lateral
          box('Side', 0, 0, 200, 720, side),
          inside(
            text(
              'Brand',
              18,
              16,
              170,
              26,
              t(markTr('Cockpit de ventas')),
              fg: '#ffffff',
              size: 14,
              bold: true,
            ),
            'Side',
          ),
          inside(
            text(
              'BrandSub',
              18,
              44,
              170,
              40,
              t(markTr('Odoo 8–20, con y sin conexión')),
              fg: sideMuted,
              size: 9,
            ),
            'Side',
          ),
          for (final (i, n) in navNames.indexed)
            inside(
              _w(
                'Button',
                n,
                10,
                84 + navSlot[i] * 44,
                180,
                38,
                {'text': pageNames[i], 'bg': side, 'fg': sideFg},
                {'command': '${n}_click'},
              ),
              'Side',
            ),
          inside(
            text('SideState', 18, 596, 170, 40, '', fg: sideFg, bold: true),
            'Side',
          ),
          inside(
            text('SidePending', 18, 636, 170, 22, '', fg: sideMuted),
            'Side',
          ),
          inside(
            text('SideServer', 18, 660, 170, 48, '', fg: sideMuted, size: 9),
            'Side',
          ),
          // ---- barra superior
          box('TopBar', 200, 0, 900, 64),
          inside(
            text(
              'PageTitle',
              24,
              8,
              440,
              28,
              pageNames[0],
              size: 16,
              bold: true,
            ),
            'TopBar',
          ),
          inside(
            text('PageSub', 24, 36, 500, 20, '', fg: muted, size: 10),
            'TopBar',
          ),
          inside(
            _w('Label', 'Badge', 540, 18, 188, 28, {
              'text': '',
              'anchor': 'center',
              'bg': '#eef0f2',
              'fg': muted,
              'font_bold': true,
            }),
            'TopBar',
          ),
          inside(
            primary('BtnSync', 740, 16, 140, 32, t(markTr('Sincronizar'))),
            'TopBar',
          ),
          // ---- páginas (sin pestañas: se cambia con el menú lateral)
          _w('PageControl', 'Pages', 200, 64, 900, 656, {
            'pages': pageNames.join('\n'),
            'active': 0,
          }),
          // Panel: indicadores, gráficos y últimos pedidos.
          for (final (i, (n, caption, color)) in kpis.indexed) ...[
            onPage(box(n, 20 + i * 218, oy + 16, 202, 100), 0),
            inside(
              text('${n}Cap', 14, 10, 176, 20, caption, fg: muted, size: 10),
              n,
            ),
            inside(
              text(
                '${n}Val',
                14,
                32,
                176,
                36,
                '0',
                fg: color,
                size: 20,
                bold: true,
              ),
              n,
            ),
            inside(text('${n}Sub', 14, 70, 176, 20, '', fg: muted, size: 9), n),
          ],
          onPage(box('ChartMonth', 20, oy + 132, 538, 236), 0),
          onPage(box('ChartState', 574, oy + 132, 306, 236), 0),
          onPage(box('ChartTop', 20, oy + 384, 420, 232), 0),
          onPage(box('RecentBox', 456, oy + 384, 424, 232), 0),
          inside(
            text(
              'RecentHead',
              14,
              8,
              396,
              22,
              t(markTr('Últimos pedidos')),
              bold: true,
            ),
            'RecentBox',
          ),
          inside(
            _w('Listbox', 'RecentList', 8, 34, 408, 190, const {}, {
              'double': 'RecentList_double',
            }),
            'RecentBox',
          ),
          // Clientes: lista con búsqueda y ficha.
          onPage(_w('Entry', 'CustSearch', 20, oy + 16, 300, 28), 1),
          onPage(
            primary('CustNew', 332, oy + 16, 160, 28, t(markTr('Nuevo cliente'))),
            1,
          ),
          onPage(
            _w('Listbox', 'CustList', 20, oy + 56, 520, 540, const {}, {
              'select': 'CustList_select',
            }),
            1,
          ),
          onPage(text('CustCount', 20, oy + 602, 520, 22, '', fg: muted), 1),
          onPage(box('CustCard', 556, oy + 16, 324, 610), 1),
          inside(
            text(
              'CustCardTitle',
              16,
              12,
              292,
              26,
              t(markTr('Nuevo cliente')),
              size: 13,
              bold: true,
            ),
            'CustCard',
          ),
          for (final (i, (n, caption)) in custFields.indexed) ...[
            inside(
              text('LblCust$n', 16, 48 + i * 58, 292, 20, caption, fg: muted),
              'CustCard',
            ),
            inside(_w('Entry', 'Cust$n', 16, 68 + i * 58, 292, 28), 'CustCard'),
          ],
          inside(
            _w('Checkbutton', 'CustSupplier', 16, 394, 292, 24, {
              'text': t(markTr('Proveedor (también se le compra)')),
            }),
            'CustCard',
          ),
          inside(
            primary('CustSave', 16, 428, 140, 34, t(markTr('Guardar'))),
            'CustCard',
          ),
          inside(
            button('CustCancel', 168, 428, 140, 34, t(markTr('Cancelar'))),
            'CustCard',
          ),
          inside(
            text('CustInfo', 16, 474, 292, 120, '', fg: muted, size: 10),
            'CustCard',
          ),
          // Productos: lista con columnas y la ficha de un producto nuevo.
          onPage(_w('Entry', 'ProdSearch', 20, oy + 16, 200, 28), 2),
          onPage(
            primary(
              'ProdNew',
              228,
              oy + 16,
              150,
              28,
              t(markTr('Nuevo producto')),
            ),
            2,
          ),
          onPage(
            text(
              'ProdCount',
              386,
              oy + 16,
              154,
              28,
              '',
              fg: muted,
              anchor: 'e',
            ),
            2,
          ),
          onPage(box('ProdHeader', 20, oy + 56, 520, 28, '#e3e8ee'), 2),
          inside(
            text('LblPCode', 12, 2, 84, 24, t(markTr('Código')), fg: muted),
            'ProdHeader',
          ),
          inside(
            text('LblPName', 104, 2, 190, 24, t(markTr('Producto')), fg: muted),
            'ProdHeader',
          ),
          inside(
            text(
              'LblPPrice',
              300,
              2,
              110,
              24,
              t(markTr('Precio')),
              fg: muted,
              anchor: 'e',
            ),
            'ProdHeader',
          ),
          inside(
            text(
              'LblPStock',
              414,
              2,
              84,
              24,
              t(markTr('Stock')),
              fg: muted,
              anchor: 'e',
            ),
            'ProdHeader',
          ),
          onPage(
            _w('Listbox', 'ProdList', 20, oy + 84, 520, 540, const {}, {
              'select': 'ProdList_select',
            }),
            2,
          ),
          onPage(box('ProdCard', 556, oy + 16, 324, 610), 2),
          inside(
            text(
              'ProdCardTitle',
              16,
              12,
              292,
              26,
              t(markTr('Nuevo producto')),
              size: 13,
              bold: true,
            ),
            'ProdCard',
          ),
          for (final (i, (n, caption)) in [
            ('Name', t(markTr('Nombre *'))),
            ('Code', t(markTr('Referencia interna'))),
            ('Price', t(markTr('Precio de venta'))),
            ('Cost', t(markTr('Coste'))),
          ].indexed) ...[
            inside(
              text('LblProd$n', 16, 48 + i * 58, 292, 20, caption, fg: muted),
              'ProdCard',
            ),
            inside(_w('Entry', 'Prod$n', 16, 68 + i * 58, 292, 28), 'ProdCard'),
          ],
          inside(
            primary('ProdSave', 16, 290, 292, 34, t(markTr('Guardar producto'))),
            'ProdCard',
          ),
          inside(
            text('ProdInfo', 16, 336, 292, 140, '', fg: muted, size: 10),
            'ProdCard',
          ),
          // Ventas: pedidos y presupuesto nuevo.
          onPage(_w('Entry', 'SaleSearch', 20, oy + 16, 200, 28), 3),
          onPage(
            _w(
              'Combobox',
              'SaleFilter',
              228,
              oy + 16,
              160,
              28,
              {
                'items': [
                  t(markTr('Todos')),
                  t(markTr('Presupuestos')),
                  t(markTr('Pedidos de venta')),
                  t(markTr('Cancelados')),
                  t(markTr('Sin enviar')),
                  t(markTr('Ventas del punto de venta')),
                ].join('\n'),
                'state': 'readonly',
              },
              {'select': 'SaleFilter_select'},
            ),
            3,
          ),
          onPage(
            button(
              'SaleNew',
              396,
              oy + 16,
              144,
              28,
              t(markTr('Nuevo presupuesto')),
            ),
            3,
          ),
          onPage(
            _w('Listbox', 'SaleList', 20, oy + 56, 520, 496, const {}, {
              'double': 'SaleList_double',
            }),
            3,
          ),
          // Los pasos del pedido elegido: confirmar, facturar y cobrar.
          for (final (n, x, w, caption) in [
            ('SaleConfirm', 20, 120, t(markTr('Confirmar'))),
            ('SaleInvoice', 146, 120, t(markTr('Facturar'))),
            ('SalePay', 272, 130, t(markTr('Registrar pago'))),
          ])
            onPage(button(n, x, oy + 560, w, 32, caption), 3),
          onPage(
            _w('Combobox', 'SalePayKind', 408, oy + 562, 132, 28, {
              'items': [t(markTr('Banco')), t(markTr('Efectivo'))].join('\n'),
              'state': 'readonly',
            }),
            3,
          ),
          onPage(text('SaleCount', 20, oy + 602, 520, 22, '', fg: muted), 3),
          onPage(box('QuoteCard', 556, oy + 16, 324, 610), 3),
          inside(
            text(
              'QuoteTitle',
              16,
              12,
              292,
              26,
              t(markTr('Nuevo presupuesto')),
              size: 13,
              bold: true,
            ),
            'QuoteCard',
          ),
          inside(
            text('LblQuoteCust', 16, 46, 292, 20, t(markTr('Cliente')), fg: muted),
            'QuoteCard',
          ),
          inside(
            _w('Combobox', 'QuoteCust', 16, 66, 292, 28, {
              'state': 'readonly',
            }),
            'QuoteCard',
          ),
          inside(
            text(
              'LblQuoteProd',
              16,
              102,
              292,
              20,
              t(markTr('Producto')),
              fg: muted,
            ),
            'QuoteCard',
          ),
          inside(
            _w('Combobox', 'QuoteProd', 16, 122, 292, 28, {
              'state': 'readonly',
            }),
            'QuoteCard',
          ),
          inside(
            text('LblQuoteQty', 16, 158, 80, 20, t(markTr('Cantidad')), fg: muted),
            'QuoteCard',
          ),
          inside(
            _w('Entry', 'QuoteQty', 16, 178, 80, 28, {'text': '1'}, {
              'enter_key': 'QuoteAdd_click',
            }),
            'QuoteCard',
          ),
          inside(
            button('QuoteAdd', 104, 178, 96, 28, t(markTr('Añadir'))),
            'QuoteCard',
          ),
          inside(
            button('QuoteDel', 208, 178, 100, 28, t(markTr('Quitar'))),
            'QuoteCard',
          ),
          inside(
            _w('Listbox', 'QuoteLines', 16, 216, 292, 250),
            'QuoteCard',
          ),
          inside(
            text(
              'QuoteTotal',
              16,
              474,
              292,
              28,
              '',
              size: 13,
              bold: true,
              anchor: 'e',
            ),
            'QuoteCard',
          ),
          inside(
            primary(
              'QuoteSave',
              16,
              512,
              292,
              36,
              t(markTr('Guardar presupuesto')),
            ),
            'QuoteCard',
          ),
          inside(
            text(
              'QuoteInfo',
              16,
              556,
              292,
              44,
              t(
                markTr(
                  'Se guarda en este equipo y se envía a Odoo al sincronizar.',
                ),
              ),
              fg: muted,
              size: 9,
            ),
            'QuoteCard',
          ),
          // Compras: solicitudes y pedidos a proveedores, con sus pasos.
          onPage(_w('Entry', 'PurSearch', 20, oy + 16, 200, 28), 8),
          onPage(
            _w(
              'Combobox',
              'PurFilter',
              228,
              oy + 16,
              160,
              28,
              {
                'items': [
                  t(markTr('Todos')),
                  t(markTr('Solicitudes de presupuesto')),
                  t(markTr('Pedidos de compra')),
                  t(markTr('Sin enviar')),
                ].join('\n'),
                'state': 'readonly',
              },
              {'select': 'PurFilter_select'},
            ),
            8,
          ),
          onPage(
            button('PurNew', 396, oy + 16, 144, 28, t(markTr('Nueva solicitud'))),
            8,
          ),
          onPage(
            _w('Listbox', 'PurList', 20, oy + 56, 520, 496, const {}, {
              'double': 'PurList_double',
            }),
            8,
          ),
          for (final (n, x, w, caption) in [
            ('PurConfirm', 20, 120, t(markTr('Confirmar'))),
            ('PurBill', 146, 120, t(markTr('Facturar'))),
            ('PurPay', 272, 130, t(markTr('Registrar pago'))),
          ])
            onPage(button(n, x, oy + 560, w, 32, caption), 8),
          onPage(
            _w('Combobox', 'PurPayKind', 408, oy + 562, 132, 28, {
              'items': [t(markTr('Banco')), t(markTr('Efectivo'))].join('\n'),
              'state': 'readonly',
            }),
            8,
          ),
          onPage(text('PurCount', 20, oy + 602, 520, 22, '', fg: muted), 8),
          onPage(box('PurCard', 556, oy + 16, 324, 610), 8),
          inside(
            text(
              'PurTitle',
              16,
              12,
              292,
              26,
              t(markTr('Nueva solicitud de presupuesto')),
              size: 13,
              bold: true,
            ),
            'PurCard',
          ),
          inside(
            text('LblPurSupp', 16, 46, 292, 20, t(markTr('Proveedor')), fg: muted),
            'PurCard',
          ),
          inside(
            _w('Combobox', 'PurSupp', 16, 66, 292, 28, {'state': 'readonly'}),
            'PurCard',
          ),
          inside(
            text('LblPurProd', 16, 102, 292, 20, t(markTr('Producto')), fg: muted),
            'PurCard',
          ),
          inside(
            _w(
              'Combobox',
              'PurProd',
              16,
              122,
              292,
              28,
              {'state': 'readonly'},
              {'select': 'PurProd_select'},
            ),
            'PurCard',
          ),
          inside(
            text('LblPurQty', 16, 158, 64, 20, t(markTr('Cantidad')), fg: muted),
            'PurCard',
          ),
          inside(
            text('LblPurPrice', 88, 158, 84, 20, t(markTr('Coste')), fg: muted),
            'PurCard',
          ),
          for (final (n, x, w) in [('PurQty', 16, 64), ('PurPrice', 88, 84)])
            inside(
              _w('Entry', n, x, 178, w, 28, const {}, {
                'enter_key': 'PurAdd_click',
              }),
              'PurCard',
            ),
          inside(
            button('PurAdd', 180, 178, 60, 28, t(markTr('Añadir'))),
            'PurCard',
          ),
          inside(
            button('PurDel', 248, 178, 60, 28, t(markTr('Quitar'))),
            'PurCard',
          ),
          inside(_w('Listbox', 'PurLines', 16, 216, 292, 250), 'PurCard'),
          inside(
            text(
              'PurTotal',
              16,
              474,
              292,
              28,
              '',
              size: 13,
              bold: true,
              anchor: 'e',
            ),
            'PurCard',
          ),
          inside(
            primary(
              'PurSave',
              16,
              512,
              292,
              36,
              t(markTr('Guardar solicitud')),
            ),
            'PurCard',
          ),
          inside(
            text(
              'PurInfo',
              16,
              556,
              292,
              44,
              t(
                markTr(
                  'Se guarda en este equipo y se envía a Odoo al sincronizar.',
                ),
              ),
              fg: muted,
              size: 9,
            ),
            'PurCard',
          ),
          // Punto de venta: productos en mosaico y el ticket.
          onPage(_w('Entry', 'PosSearch', 20, oy + 16, 250, 28), 4),
          onPage(
            _w(
              'Combobox',
              'PosCat',
              280,
              oy + 16,
              280,
              28,
              {'state': 'readonly'},
              {'select': 'PosCat_select'},
            ),
            4,
          ),
          onPage(box('PosGrid', 20, oy + 56, 540, 520, paper), 4),
          onPage(button('PosPrev', 20, oy + 584, 90, 30, '‹'), 4),
          onPage(
            text(
              'PosPageLbl',
              120,
              oy + 584,
              340,
              30,
              '',
              fg: muted,
              anchor: 'center',
            ),
            4,
          ),
          onPage(button('PosNext', 470, oy + 584, 90, 30, '›'), 4),
          onPage(box('PosCard', 576, oy + 16, 304, 610), 4),
          inside(
            text(
              'PosHead',
              16,
              10,
              272,
              26,
              t(markTr('Ticket')),
              size: 13,
              bold: true,
            ),
            'PosCard',
          ),
          inside(
            text('LblPosCust', 16, 40, 272, 20, t(markTr('Cliente')), fg: muted),
            'PosCard',
          ),
          inside(
            _w('Combobox', 'PosCust', 16, 60, 272, 28, {'state': 'readonly'}),
            'PosCard',
          ),
          inside(
            _w('Listbox', 'PosLines', 16, 96, 272, 244, const {}, {
              'select': 'PosLines_select',
            }),
            'PosCard',
          ),
          inside(
            text('LblPosQty', 16, 346, 60, 20, t(markTr('Cantidad')), fg: muted),
            'PosCard',
          ),
          inside(
            text('LblPosPrice', 84, 346, 84, 20, t(markTr('Precio')), fg: muted),
            'PosCard',
          ),
          inside(
            text('LblPosDisc', 176, 346, 60, 20, t(markTr('Dto. %')), fg: muted),
            'PosCard',
          ),
          for (final (n, x, w) in [
            ('PosQty', 16, 60),
            ('PosPrice', 84, 84),
            ('PosDisc', 176, 56),
          ])
            inside(
              _w('Entry', n, x, 366, w, 28, const {}, {
                'enter_key': 'PosApply_click',
              }),
              'PosCard',
            ),
          inside(button('PosApply', 238, 366, 50, 28, 'OK'), 'PosCard'),
          inside(
            button('PosDel', 16, 402, 130, 28, t(markTr('Quitar línea'))),
            'PosCard',
          ),
          inside(
            button('PosClear', 158, 402, 130, 28, t(markTr('Vaciar'))),
            'PosCard',
          ),
          inside(
            text(
              'PosTotal',
              16,
              438,
              272,
              34,
              '',
              size: 16,
              bold: true,
              anchor: 'e',
            ),
            'PosCard',
          ),
          inside(
            _w('Radiobutton', 'PosCash', 16, 478, 130, 24, {
              'text': t(markTr('Efectivo')),
              'group': 'Payment',
              'value': 'cash',
              'checked': true,
            }),
            'PosCard',
          ),
          inside(
            _w('Radiobutton', 'PosCardPay', 150, 478, 138, 24, {
              'text': t(markTr('Tarjeta')),
              'group': 'Payment',
              'value': 'card',
            }),
            'PosCard',
          ),
          inside(
            primary('PosPay', 16, 510, 272, 44, t(markTr('Cobrar'))),
            'PosCard',
          ),
          inside(
            text(
              'PosInfo',
              16,
              560,
              272,
              44,
              t(
                markTr(
                  'Se envía a Odoo como pedido confirmado, con su entrega y su factura.',
                ),
              ),
              fg: muted,
              size: 9,
            ),
            'PosCard',
          ),
          // Sincronización: estado, bandeja de salida y registro.
          onPage(box('SyncCard', 20, oy + 16, 860, 150), 5),
          inside(
            text(
              'SyncHead',
              16,
              10,
              560,
              24,
              t(markTr('Estado de la sincronización')),
              size: 13,
              bold: true,
            ),
            'SyncCard',
          ),
          inside(
            text('SyncInfo', 16, 38, 560, 104, '', fg: muted, size: 10),
            'SyncCard',
          ),
          inside(
            primary(
              'SyncNow',
              600,
              14,
              244,
              34,
              t(markTr('Sincronizar ahora')),
            ),
            'SyncCard',
          ),
          inside(
            button(
              'SyncReload',
              600,
              54,
              244,
              30,
              t(markTr('Descargar todo de nuevo')),
            ),
            'SyncCard',
          ),
          inside(
            _w(
              'Checkbutton',
              'SyncAuto',
              600,
              90,
              244,
              24,
              {
                'text': t(markTr('Reintentar automáticamente')),
                'checked': true,
              },
              {'command': 'SyncAuto_click'},
            ),
            'SyncCard',
          ),
          inside(
            _w(
              'Checkbutton',
              'SyncOffline',
              600,
              116,
              244,
              24,
              {'text': t(markTr('Trabajar sin conexión'))},
              {'command': 'SyncOffline_click'},
            ),
            'SyncCard',
          ),
          onPage(
            text(
              'LblOutbox',
              20,
              oy + 180,
              420,
              22,
              t(markTr('Pendientes de enviar')),
              bold: true,
            ),
            5,
          ),
          onPage(_w('Listbox', 'Outbox', 20, oy + 204, 420, 380), 5),
          onPage(
            button(
              'OutboxDiscard',
              20,
              oy + 592,
              240,
              30,
              t(markTr('Descartar el cambio elegido')),
            ),
            5,
          ),
          onPage(
            text(
              'LblLog',
              456,
              oy + 180,
              424,
              22,
              t(markTr('Registro')),
              bold: true,
            ),
            5,
          ),
          onPage(_w('Text', 'SyncLog', 456, oy + 204, 424, 418), 5),
          // Configuración: conexión y ayuda.
          onPage(box('CfgCard', 20, oy + 16, 520, 500), 6),
          inside(
            text(
              'CfgHead',
              16,
              12,
              488,
              26,
              t(markTr('Conexión con Odoo')),
              size: 13,
              bold: true,
            ),
            'CfgCard',
          ),
          inside(
            text(
              'LblUrl',
              16,
              50,
              488,
              20,
              t(markTr('Dirección del servidor (https://…)')),
              fg: muted,
            ),
            'CfgCard',
          ),
          inside(_w('Entry', 'CfgUrl', 16, 70, 488, 28), 'CfgCard'),
          inside(
            text(
              'LblDb',
              16,
              108,
              488,
              20,
              t(markTr('Base de datos (vacía: la única del servidor)')),
              fg: muted,
            ),
            'CfgCard',
          ),
          inside(_w('Entry', 'CfgDb', 16, 128, 376, 28), 'CfgCard'),
          inside(
            button('CfgDetect', 400, 128, 104, 28, t(markTr('Detectar'))),
            'CfgCard',
          ),
          inside(
            text('LblUser', 16, 166, 240, 20, t(markTr('Usuario')), fg: muted),
            'CfgCard',
          ),
          inside(_w('Entry', 'CfgUser', 16, 186, 240, 28), 'CfgCard'),
          inside(
            text(
              'LblPass',
              264,
              166,
              240,
              20,
              t(markTr('Contraseña o clave de API')),
              fg: muted,
            ),
            'CfgCard',
          ),
          inside(_w('Password', 'CfgPass', 264, 186, 240, 28), 'CfgCard'),
          inside(
            _w('Checkbutton', 'CfgRemember', 16, 222, 488, 24, {
              'text': t(markTr('Recordar la contraseña en este equipo')),
            }),
            'CfgCard',
          ),
          inside(
            button('CfgTest', 16, 256, 236, 34, t(markTr('Probar conexión'))),
            'CfgCard',
          ),
          inside(
            primary(
              'CfgConnect',
              268,
              256,
              236,
              34,
              t(markTr('Conectar y descargar')),
            ),
            'CfgCard',
          ),
          inside(
            text('CfgResult', 16, 302, 488, 100, '', fg: muted, size: 10),
            'CfgCard',
          ),
          inside(
            text('CfgFolder', 16, 406, 488, 50, '', fg: muted, size: 9),
            'CfgCard',
          ),
          inside(
            button(
              'CfgReset',
              16,
              462,
              236,
              30,
              t(markTr('Borrar los datos locales')),
            ),
            'CfgCard',
          ),
          onPage(box('HelpCard', 556, oy + 16, 324, 610, note), 6),
          inside(
            text(
              'HelpHead',
              16,
              12,
              292,
              24,
              t(markTr('Cómo funciona')),
              size: 13,
              bold: true,
            ),
            'HelpCard',
          ),
          inside(
            text(
              'HelpText',
              16,
              42,
              292,
              556,
              t(
                markTr(
                  'Funciona con Odoo 8 a 20 (Community y Enterprise) por JSON-RPC, con las rutas del cliente web: /web/session/authenticate y /web/dataset/call_kw. Detecta la versión y usa los campos que tiene cada una.\n\n'
                  'Sin conexión: los clientes, productos y pedidos se guardan en un archivo JSON de su carpeta de usuario. Los clientes y presupuestos nuevos esperan en «Pendientes de enviar» y se envían al sincronizar o, solos, cuando vuelve la conexión.\n\n'
                  'Sin duplicados: cada registro creado aquí lleva una referencia DMS-… (en la referencia interna del cliente y en la referencia del cliente del pedido) que se busca en Odoo antes de crearlo.\n\n'
                  'Punto de venta: cada venta llega a Odoo como pedido confirmado, con su entrega validada (si está Inventario) y su factura publicada. Si algo falla, al sincronizar se sigue desde el último paso hecho.\n\n'
                  'HTTPS: la aplicación lleva su OpenSSL (en Windows, libssl-3-x64.dll y libcrypto-3-x64.dll junto al .exe). Si falta, en macOS se usa la de Homebrew o la del sistema; en Linux, la libssl del sistema.\n\n'
                  'Los presupuestos necesitan el módulo Ventas en Odoo; con Inventario se ve también el stock.\n\n'
                  'Obras BIM: si Odoo tiene BIM 2.0 (base_bim_2), se crean obras y presupuestos por conceptos (capítulos, partidas y recursos) sin conexión y se suben a Odoo, que recalcula los importes.',
                ),
              ),
              fg: '#5c4813',
              size: 9,
            ),
            'HelpCard',
          ),
          // Obras BIM, como el árbol de conceptos de BIM 2.0: arriba la obra y
          // el presupuesto; la barra (+, inicio, quitar, ruta y UPD); a la
          // izquierda el árbol y a la derecha lo que hay dentro de lo elegido
          // (Código, Nombre, Cantidad, Costo, Saldo), con el editor debajo.
          onPage(text('LblBimProj', 20, oy + 14, 56, 20, tc('bim', markTrc('bim', 'Obra')), fg: muted), 7),
          onPage(
            _w('Combobox', 'BimProject', 76, oy + 10, 284, 28, {'state': 'readonly'}, {
              'select': 'BimProject_select',
            }),
            7,
          ),
          onPage(button('BimProjAdd', 366, oy + 10, 110, 28, t(markTr('Nueva obra…'))), 7),
          onPage(
            text('LblBimBud', 488, oy + 14, 86, 20, tc('bim', markTrc('bim', 'Presupuesto')), fg: muted),
            7,
          ),
          onPage(
            _w('Combobox', 'BimBudSel', 576, oy + 10, 200, 28, {'state': 'readonly'}, {
              'select': 'BimBudSel_select',
            }),
            7,
          ),
          onPage(button('BimBudNew', 782, oy + 10, 98, 28, t(markTr('Nuevo…'))), 7),
          onPage(
            _w(
              'Button',
              'BimAdd',
              20,
              oy + 46,
              38,
              32,
              {'text': '+', 'bg': '#714b67', 'fg': '#ffffff', 'font_bold': true, 'font_size': 14},
              {'command': 'BimAdd_click'},
            ),
            7,
          ),
          onPage(button('BimHome', 62, oy + 46, 38, 32, '⌂'), 7),
          onPage(button('BimDel', 104, oy + 46, 38, 32, '✕'), 7),
          onPage(text('BimCrumb', 154, oy + 44, 520, 18, '', fg: '#017e84', size: 9), 7),
          onPage(text('BimCrumb2', 154, oy + 61, 520, 20, '', size: 10), 7),
          onPage(
            _w(
              'Button',
              'BimSend',
              690,
              oy + 46,
              190,
              32,
              {
                'text': t(markTr('UPD · Enviar a Odoo')),
                'bg': '#714b67',
                'fg': '#ffffff',
                'font_bold': true,
              },
              {'command': 'BimSend_click'},
            ),
            7,
          ),
          onPage(box('BimTreeBox', 20, oy + 88, 280, 538), 7),
          inside(
            _w('Listbox', 'BimTree', 0, 0, 280, 538, const {}, {'select': 'BimTree_select'}),
            'BimTreeBox',
          ),
          onPage(box('BimSplit', 300, oy + 88, 2, 538, '#cfd4da'), 7),
          onPage(box('BimRight', 302, oy + 88, 578, 538), 7),
          inside(
            text('LblBimHCode', 34, 8, 64, 20, t(markTr('Código')), bold: true),
            'BimRight',
          ),
          inside(
            text('LblBimHName', 102, 8, 140, 20, t(markTr('Nombre')), bold: true),
            'BimRight',
          ),
          inside(
            text(
              'LblBimHQty',
              246,
              8,
              84,
              20,
              t(markTr('Cantidad')),
              bold: true,
              anchor: 'e',
            ),
            'BimRight',
          ),
          inside(
            text('LblBimHCost', 326, 8, 84, 20, t(markTr('Costo')), bold: true, anchor: 'e'),
            'BimRight',
          ),
          inside(
            text('LblBimHBal', 404, 8, 84, 20, t(markTr('Saldo')), bold: true, anchor: 'e'),
            'BimRight',
          ),
          inside(box('BimHeadLine', 0, 34, 578, 1, '#dee2e6'), 'BimRight'),
          inside(
            _w('Listbox', 'BimRows', 0, 35, 578, 300, const {}, {
              'select': 'BimRows_select',
              'double': 'BimRows_double',
            }),
            'BimRight',
          ),
          inside(box('BimFootLine', 0, 335, 578, 1, '#dee2e6'), 'BimRight'),
          inside(
            text('BimFootQty', 246, 342, 84, 20, '', bold: true, anchor: 'e'),
            'BimRight',
          ),
          inside(
            text('BimFootCost', 326, 342, 84, 20, '', bold: true, anchor: 'e'),
            'BimRight',
          ),
          inside(
            text('BimFootBal', 404, 342, 84, 20, '', bold: true, anchor: 'e'),
            'BimRight',
          ),
          inside(box('BimEditLine', 0, 372, 578, 1, '#dee2e6'), 'BimRight'),
          inside(
            text('LblBimType', 12, 380, 130, 18, t(markTr('Tipo')), fg: muted),
            'BimRight',
          ),
          inside(
            _w(
              'Combobox',
              'BimType',
              12,
              398,
              130,
              28,
              {
                'items': [
                  t(markTr('Capítulo')),
                  t(markTr('Partida')),
                  t(markTr('Mano de obra')),
                  t(markTr('Equipo')),
                  t(markTr('Material')),
                  t(markTr('Subcontrata')),
                  t(markTr('Función')),
                ].join('\n'),
                'state': 'readonly',
              },
              {'select': 'BimType_select'},
            ),
            'BimRight',
          ),
          inside(
            text('LblBimCode', 150, 380, 80, 18, t(markTr('Código')), fg: muted),
            'BimRight',
          ),
          inside(_w('Entry', 'BimCode', 150, 398, 80, 28), 'BimRight'),
          inside(
            text('LblBimName', 238, 380, 328, 18, t(markTr('Nombre')), fg: muted),
            'BimRight',
          ),
          inside(
            _w('Entry', 'BimName', 238, 398, 328, 28, const {}, {'enter_key': 'BimEnter_key'}),
            'BimRight',
          ),
          inside(
            text('LblBimQty', 12, 432, 80, 18, t(markTr('Cantidad')), fg: muted),
            'BimRight',
          ),
          inside(
            _w('Entry', 'BimQty', 12, 450, 80, 28, {'text': '1'}, {'enter_key': 'BimEnter_key'}),
            'BimRight',
          ),
          inside(
            text('LblBimPrice', 98, 432, 90, 18, t(markTr('Precio')), fg: muted),
            'BimRight',
          ),
          inside(
            _w('Entry', 'BimPrice', 98, 450, 90, 28, {'text': '0'}, {'enter_key': 'BimEnter_key'}),
            'BimRight',
          ),
          inside(
            text('LblBimUom', 194, 432, 70, 18, t(markTr('Unidad')), fg: muted),
            'BimRight',
          ),
          inside(_w('Entry', 'BimUom', 194, 450, 70, 28), 'BimRight'),
          inside(
            button('BimChild', 270, 450, 104, 28, t(markTr('Añadir hijo'))),
            'BimRight',
          ),
          inside(
            button('BimSibling', 378, 450, 104, 28, t(markTr('Mismo nivel'))),
            'BimRight',
          ),
          inside(button('BimApply', 486, 450, 80, 28, t(markTr('Aplicar'))), 'BimRight'),
          inside(
            text('BimInfo', 12, 488, 554, 44, '', fg: muted, size: 9),
            'BimRight',
          ),
          _w('Timer', 'Tick', 0, 0, 24, 24, {'interval': 1000}, {
            'command': 'Tick_timer',
          }),
        ]);

  // Los textos de la aplicación, como constantes de Pascal.
  final texts = <String, String>{
    'SApp': app,
    'SPageSubs': [
      t(markTr('Resumen de las ventas de los últimos doce meses')),
      t(markTr('Clientes de Odoo y los creados en este equipo')),
      t(markTr('Productos que se pueden vender')),
      t(markTr('Pedidos y presupuestos; los nuevos se envían al sincronizar')),
      t(markTr('Venta en mostrador: pedido, entrega y factura en Odoo')),
      t(markTr('Cambios pendientes de enviar y registro')),
      t(markTr('Servidor de Odoo, base de datos y usuario')),
      t(markTr('Obras y presupuestos por conceptos de BIM 2.0, también sin conexión')),
      t(markTr('Solicitudes y pedidos a proveedores, con su factura y su pago')),
    ].join('|'),
    'SPageNames': pageNames.join('|'),
    'SMonths': t(markTr('ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic')),
    'SNumberSample': t(markTr('1.234,56')),
    'SOnline': t(markTr('En línea')),
    'SOffline': t(markTr('Sin conexión')),
    'SWorkOffline': t(markTr('Trabajando sin conexión')),
    'SSyncing': t(markTr('Sincronizando…')),
    'SPendingN': t(markTr('%d cambios pendientes')),
    'SNoPending': t(markTr('Todo enviado')),
    'SNotConfigured': t(markTr('Sin configurar: vaya a Configuración')),
    'SSync': t(markTr('Sincronizar')),
    'SOrdersN': t(markTr('%d pedidos confirmados')),
    'SQuotesSum': t(markTr('Por %s')),
    'SNewLocalN': t(markTr('%d creados sin conexión')),
    'SAllSynced': t(markTr('Todos en Odoo')),
    'SLastSync': t(markTr('Sincronizado: %s')),
    'SNeverSynced': t(markTr('Aún no se ha sincronizado')),
    'SChartMonth': t(markTr('Ventas por mes')),
    'SChartState': t(markTr('Pedidos por estado')),
    'SChartTop': t(markTr('Mejores clientes')),
    'SLegendOrders': t(markTr('Pedidos')),
    'SLegendQuotes': t(markTr('Presupuestos')),
    'SNoData': t(markTr('Sin datos: conecte con Odoo en Configuración.')),
    'STotalOrders': t(markTr('pedidos')),
    'SStDraft': t(markTr('Presupuesto')),
    'SStSent': t(markTr('Presupuesto enviado')),
    'SStSale': t(markTr('Pedido de venta')),
    'SStDone': t(markTr('Hecho')),
    'SStCancel': t(markTr('Cancelado')),
    'SStPending': t(markTr('Sin enviar')),
    'SNewOrder': t(markTr('Nuevo')),
    'SPendingTag': t(markTr('pendiente')),
    'SSearchCust': t(markTr('Buscar por nombre, correo o ciudad…')),
    'SSearchProd': t(markTr('Buscar por nombre o código…')),
    'SSearchSale': t(markTr('Buscar por número o cliente…')),
    'SCustCount': t(markTr('%d clientes · %d sin enviar')),
    'SProdCount': t(markTr('%d productos')),
    'SSaleCount': t(markTr('%d pedidos · %s')),
    'SEditCust': t(markTr('Editar cliente')),
    'SNewCust': t(markTr('Nuevo cliente')),
    'SCustLocal': t(
      markTr(
        'Creado en este equipo: se enviará a Odoo al sincronizar (con la referencia %s).',
      ),
    ),
    'SCustPending': t(
      markTr('Cliente %d de Odoo, con cambios pendientes de enviar.'),
    ),
    'SCustSynced': t(markTr('Cliente %d de Odoo, al día.')),
    'SCustNew': t(
      markTr(
        'Rellene la ficha y pulse Guardar: funciona también sin conexión.',
      ),
    ),
    'SNameRequired': t(markTr('Escriba el nombre del cliente.')),
    'SBadEmail': t(markTr('El correo electrónico no parece válido.')),
    'SChooseCust': t(markTr('Elija el cliente del presupuesto.')),
    'SChooseProd': t(markTr('Elija un producto.')),
    'SBadQty': t(markTr('Escriba una cantidad mayor que cero.')),
    'SNoLines': t(markTr('Añada al menos un producto.')),
    'SQuoteSaved': t(
      markTr('Presupuesto guardado: se enviará a Odoo al sincronizar.'),
    ),
    'STotalNoTax': t(markTr('Total: %s (sin impuestos)')),
    'SNoCustomers': t(
      markTr('No hay clientes: sincronice o cree uno en Clientes.'),
    ),
    'SOrderInfo': t(
      markTr('Pedido: %s\nCliente: %s\nFecha: %s\nTotal: %s\nEstado: %s'),
    ),
    'SOpNewPartner': t(markTr('Cliente nuevo: %s')),
    'SOpEditPartner': t(markTr('Cambios en el cliente: %s')),
    'SOpNewOrder': t(markTr('Presupuesto para %s (%s)')),
    'SOpGone': t(markTr('(ya no existe en este equipo)')),
    'SOpError': t(markTr('Error: %s')),
    'SOpWaiting': t(markTr('Esperando la conexión · %s')),
    'SDiscardAsk': t(
      markTr(
        '¿Descartar este cambio? Lo que se creó en este equipo y aún no está en Odoo se borrará.',
      ),
    ),
    'SChooseOp': t(markTr('Elija un cambio de la lista.')),
    'SSyncInfo': t(
      markTr(
        'Servidor: %s\nBase de datos: %s · %s\nÚltima sincronización: %s\nEn este equipo: %d clientes, %d productos y %d pedidos.',
      ),
    ),
    'SNever': t(markTr('nunca')),
    'SUnknownVersion': t(markTr('versión desconocida')),
    'SConnected': t(markTr('Conectado a Odoo %s (base de datos %s, usuario %d).')),
    'SDownloaded': t(
      markTr('Descargados %d clientes, %d productos y %d pedidos.'),
    ),
    'SSentN': t(markTr('Enviados %d cambios a Odoo.')),
    'SSyncDone': t(markTr('Sincronización terminada.')),
    'SSentPartner': t(markTr('Cliente «%s» creado en Odoo (id %d).')),
    'SFoundPartner': t(
      markTr('Cliente «%s» ya estaba en Odoo (id %d): no se duplica.'),
    ),
    'SSentEdit': t(markTr('Cambios del cliente «%s» enviados.')),
    'SSentOrder': t(markTr('Presupuesto %s creado en Odoo para %s.')),
    'SFoundOrder': t(
      markTr('El presupuesto %s ya estaba en Odoo: no se duplica.'),
    ),
    'SPushError': t(markTr('No se pudo enviar «%s»: %s')),
    'SSaleMissing': t(
      markTr(
        'El módulo Ventas no está instalado en esta base de datos de Odoo: no hay pedidos ni presupuestos.',
      ),
    ),
    'SPartnerNotSent': t(markTr('Su cliente aún no está en Odoo.')),
    'SNoUrl': t(markTr('Escriba la dirección del servidor de Odoo.')),
    'SNoNetwork': t(
      markTr(
        'No se puede conectar con %s. ¿Hay conexión a Internet y es correcta la dirección? (%s)',
      ),
    ),
    'SSslMissing': t(
      markTr(
        'No se encuentra OpenSSL, que hace falta para HTTPS. En Windows, copie libssl-3-x64.dll y libcrypto-3-x64.dll junto al programa; en macOS, instale OpenSSL con Homebrew (brew install openssl@3); en Linux, instale libssl.',
      ),
    ),
    'SNotOdoo': t(markTr('%s no responde como un servidor de Odoo.')),
    'SNotFound': t(markTr('El servidor no tiene la ruta %s: ¿es un Odoo?')),
    'SHttpError': t(markTr('El servidor respondió con el error HTTP %d.')),
    'SRedirect': t(markTr('El servidor redirige a %s: use esa dirección.')),
    'SBadLogin': t(markTr('Usuario o contraseña incorrectos.')),
    'SNoDatabase': t(markTr('La base de datos «%s» no existe en el servidor.')),
    'SNoDbList': t(
      markTr(
        'El servidor no muestra sus bases de datos: escriba el nombre de la suya.',
      ),
    ),
    'SManyDbs': t(markTr('El servidor tiene varias bases de datos: %s. Elija una.')),
    'SOneDb': t(markTr('Base de datos encontrada: %s.')),
    'SConfigureFirst': t(
      markTr(
        'Escriba la dirección, el usuario y la contraseña de Odoo y pulse Conectar y descargar.',
      ),
    ),
    'SOfflineOn': t(
      markTr(
        'Está trabajando sin conexión: desmarque esa casilla en Sincronización para enviar los cambios.',
      ),
    ),
    'STestOk': t(markTr('Conexión correcta: Odoo %s, base de datos %s.')),
    'SFolder': t(markTr('Datos de este equipo: %s')),
    'SResetAsk': t(
      markTr(
        '¿Borrar los clientes, productos y pedidos guardados en este equipo? Odoo no cambia.',
      ),
    ),
    'SResetPending': t(
      markTr(
        'Hay %d cambios sin enviar a Odoo, que se perderán. ¿Borrar de todos modos?',
      ),
    ),
    'SNoStock': '—',
    'SCounter': t(markTr('Cliente de mostrador')),
    'SAllCats': t(markTr('Todas las categorías')),
    'SSearchPos': t(markTr('Buscar producto…')),
    'SPosPageN': t(markTr('Página %d de %d · %d productos')),
    'SPosTotal': t(markTr('Total %s')),
    'SPosLine': t(markTr('%s × %s')),
    'SPosDisc': t(markTr('dto. %s %%')),
    'SPosEmpty': t(markTr('Toque un producto para añadirlo al ticket.')),
    'SPosNoLine': t(markTr('Elija una línea del ticket.')),
    'SPosNoItems': t(markTr('El ticket está vacío.')),
    'SPosBadDisc': t(markTr('El descuento va de 0 a 100.')),
    'SCash': t(markTr('Efectivo')),
    'SCard': t(markTr('Tarjeta')),
    'SPosPending': t(markTr('Pendiente')),
    'SPosOrder': t(markTr('Pedido')),
    'SPosDelivered': t(markTr('Entregado')),
    'SPosInvoiced': t(markTr('Facturado')),
    'SPosError': t(markTr('Error')),
    'SOpPos': t(markTr('Venta del punto de venta para %s (%s)')),
    'SReceipt': t(
      markTr(
        'Ticket %s\n%s · %s\nCliente: %s\n\n%s\nTotal: %s\n\nEstado: %s\nPedido: %s\nEntrega: %s\nFactura: %s',
      ),
    ),
    'SNoStockApp': t(markTr('sin Inventario en Odoo')),
    'SPosConfirmed': t(markTr('Pedido %s confirmado.')),
    'SPosDeliveredLog': t(markTr('Entrega %s validada.')),
    'SPosInvoicedLog': t(markTr('Factura %s publicada.')),
    'SPosNoStockLog': t(
      markTr('Inventario no está instalado en Odoo: la venta no tiene entrega.'),
    ),
    'SDeliveryFailed': t(markTr('La entrega %s no se pudo validar (estado %s).')),
    'SNoInvoice': t(markTr('Odoo no creó la factura del pedido %s.')),
    'SNoSsl': t(markTr('no encontrada')),
    // Productos, pasos de los pedidos (confirmar, facturar, pagar) y compras.
    'SStInvoiced': t(markTr('Facturado')),
    'SStPaid': t(markTr('Pagado')),
    'SPoDraft': t(markTr('Solicitud de presupuesto')),
    'SPoOrder': t(markTr('Pedido de compra')),
    'SBank': t(markTr('Banco')),
    'SSupplierTag': t(markTr('proveedor')),
    'SChooseOrder': t(markTr('Elija un pedido de la lista.')),
    'SPosNoSteps': t(
      markTr(
        'Las ventas del punto de venta se confirman, entregan y facturan solas.',
      ),
    ),
    'SIsCancelled': t(markTr('El pedido está cancelado.')),
    'SAlreadyStep': t(markTr('El pedido ya está así: %s.')),
    'SConfirmFirst': t(markTr('Confirme primero el pedido.')),
    'SInvoiceFirst': t(markTr('Facture primero el pedido.')),
    'SOrderSteps': t(markTr('Factura: %s\nPago: %s')),
    'SOpOrderStep': t(markTr('Pedido %s: %s')),
    'SOpPurStep': t(markTr('Compra %s: %s')),
    'SOpNewProduct': t(markTr('Producto nuevo: %s')),
    'SOpNewPurchase': t(markTr('Solicitud a %s (%s)')),
    'SSentProduct': t(markTr('Producto «%s» creado en Odoo (id %d).')),
    'SFoundProduct': t(
      markTr('El producto «%s» ya estaba en Odoo (id %d): no se duplica.'),
    ),
    'SProductNotSent': t(markTr('El producto «%s» aún no está en Odoo.')),
    'SPaidLog': t(markTr('Factura %s pagada (%s).')),
    'SNotPaid': t(markTr('Odoo no dejó pagada la factura %s.')),
    'SPayOld': t(
      markTr('Registrar pagos desde aquí necesita Odoo 9 o posterior.'),
    ),
    'SPurchaseMissing': t(
      markTr(
        'El módulo Compras no está instalado en esta base de datos de Odoo.',
      ),
    ),
    'SSentPurchase': t(markTr('Solicitud %s creada en Odoo para %s.')),
    'SFoundPurchase': t(
      markTr('La solicitud %s ya estaba en Odoo: no se duplica.'),
    ),
    'SPurConfirmed': t(markTr('Pedido de compra %s confirmado.')),
    'SReceivedLog': t(markTr('Recepción %s validada.')),
    'SBillOld': t(
      markTr('Facturar compras desde aquí necesita Odoo 14 o posterior.'),
    ),
    'SNoBill': t(markTr('Odoo no creó la factura del pedido de compra %s.')),
    'SBilledLog': t(markTr('Factura de proveedor %s publicada.')),
    'SChooseSupp': t(markTr('Elija el proveedor.')),
    'SNoSuppliers': t(
      markTr(
        'No hay contactos: sincronice o cree uno en Clientes (marque «Proveedor»).',
      ),
    ),
    'SPurSaved': t(
      markTr('Solicitud guardada: se enviará a Odoo al sincronizar.'),
    ),
    'SSearchPur': t(markTr('Buscar por número o proveedor…')),
    'SPurCount': t(markTr('%d compras · %s')),
    'SPurInfo': t(
      markTr(
        'Compra: %s\nProveedor: %s\nFecha: %s\nTotal: %s\nEstado: %s',
      ),
    ),
    'SNewProd': t(markTr('Nuevo producto')),
    'SShowProd': t(markTr('Producto')),
    'SProdLocal': t(
      markTr(
        'Creado en este equipo: se enviará a Odoo al sincronizar (con la referencia %s).',
      ),
    ),
    'SProdOdoo': t(
      markTr('Producto %d de Odoo: sus cambios se hacen en Odoo.'),
    ),
    'SProdHint': t(
      markTr(
        'Rellene la ficha y pulse Guardar: funciona también sin conexión. Se crea como consumible, para vender y comprar; sin referencia interna, lleva la de este equipo.',
      ),
    ),
    'SProdNameReq': t(markTr('Escriba el nombre del producto.')),
    'SBadPrice': t(markTr('Escriba precios de 0 o más.')),
    'SDupCode': t(markTr('Ya hay un producto con la referencia %s.')),
    'SBimNoCust': t(markTr('(sin cliente)')),
    'SBimCrumb': tc('bim', markTrc('bim', 'Presupuestos')),
    'SBimConcept': tc('bim', markTrc('bim', 'Concepto')),
    'SBimDetail': t(markTr('Detalle')),
    'SBimCustomer': t(markTr('Cliente')),
    'SBimCancel': t(markTr('Cancelar')),
    'SBimCreate': t(markTr('Crear')),
    'SBimNewProject': t(markTr('Obra nueva')),
    'SBimNewBudgetTitle': t(markTr('Presupuesto nuevo')),
    'SBimHintAdd': t(markTr('Añadir un hijo de lo elegido (N)')),
    'SBimHintHome': t(markTr('Volver al primer nivel del presupuesto')),
    'SBimHintDel': t(markTr('Eliminar lo elegido (Supr)')),
    'SBimKeys': t(
      markTr(
        'N: añadir hijo · Mayús + N: al mismo nivel · Supr: eliminar · Intro: abrir · U: enviar · E / Mayús + E: abrir o cerrar todo',
      ),
    ),
    'SBimHintProj': t(markTr('Nombre de la obra')),
    'SBimHintBud': t(markTr('Nombre del presupuesto (opcional)')),
    'SBimNoProject': t(markTr('Elija o cree una obra.')),
    'SBimProjName': t(markTr('Escriba el nombre de la obra.')),
    'SBimNewBudget': t(markTr('Presupuesto %s')),
    'SBimChooseBudget': t(markTr('Elija o cree un presupuesto de la obra.')),
    'SBimChapterTop': t(markTr('Los capítulos van en el primer nivel del presupuesto.')),
    'SBimNeedChapter': t(markTr('Elija en el árbol el capítulo donde va la partida.')),
    'SBimNeedDeparture': t(markTr('Elija en el árbol la partida donde va el recurso.')),
    'SBimCodeRequired': t(markTr('Escriba el código del concepto.')),
    'SBimNameRequired': t(markTr('Escriba la descripción del concepto.')),
    'SBimBadQty': t(
      markTr('Escriba una cantidad mayor que cero y un precio (0 o más).'),
    ),
    'SBimChoose': t(markTr('Elija un concepto del árbol.')),
    'SBimTypeChange': t(
      markTr(
        'Un capítulo, una partida y un recurso no se convierten entre sí: quítelo y añádalo de nuevo.',
      ),
    ),
    'SBimDelAsk': t(markTr('¿Quitar «%s» y lo que lleva dentro?')),
    'SBimEmpty': t(markTr('Añada al menos una partida al presupuesto.')),
    'SBimQueued': t(
      markTr('Presupuesto guardado: se enviará a Odoo al sincronizar.'),
    ),
    'SBimDraft': t(
      markTr(
        'Borrador en este equipo: añada capítulos, partidas y recursos y pulse UPD · Enviar a Odoo.',
      ),
    ),
    'SBimWaiting': t(markTr('Esperando la conexión para enviarse a Odoo.')),
    'SBimLocked': t(markTr('Está en Odoo: aquí se consulta; los cambios, en Odoo.')),
    'SBimLoad': t(markTr('Conéctese para ver los conceptos de este presupuesto.')),
    'SBimMissing': t(
      markTr('Esta base de datos de Odoo no tiene BIM 2.0 (módulo base_bim_2).'),
    ),
    'SBimRefNote': t(markTr('Creada desde DMarlon Studio · %s')),
    'SBimSentProject': t(markTr('Obra «%s» creada en Odoo (%s).')),
    'SBimFoundProject': t(markTr('La obra «%s» ya estaba en Odoo: no se duplica.')),
    'SBimFoundBudget': t(
      markTr(
        'El presupuesto «%s» ya estaba en Odoo: se añaden solo los conceptos que faltan.',
      ),
    ),
    'SBimNoParent': t(markTr('El concepto %s no tiene su padre en Odoo.')),
    'SBimSentBudget': t(
      markTr('Presupuesto %s «%s» enviado a Odoo: %d conceptos, total %s.'),
    ),
    'SBimDownloaded': t(markTr('BIM 2.0: %d obras y %d presupuestos.')),
    'SOpBimProject': t(markTr('Obra nueva: %s')),
    'SOpBimBudget': t(markTr('Presupuesto BIM «%s» (%s)')),
    'SPosInfo': t(
      markTr(
        'Se envía a Odoo como pedido confirmado, con su entrega y su factura.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      '  $key = ${_odooPas(value)};',
  ].join('\n');
  final code =
      '''// ${t(markTr('Cockpit de ventas para Odoo 8 a 20 en Pascal con Lazarus: JSON-RPC, datos sin conexión y sincronización sin duplicados.'))}
unit Form1;

{\$mode objfpc}{\$H+}
{\$IFDEF DARWIN}{\$modeswitch objectivec1}{\$ENDIF}

interface

uses
  {\$IFDEF DARWIN}CocoaAll, cocoa_extra,{\$ENDIF}
  ${PascalUnit.uses},
  LCLType, LazUTF8, Math, DateUtils, fpjson, jsonparser, fphttpclient,
  opensslsockets, openssl;
$_odooInterface
implementation

const
$consts
$_odooBody''';
  return TkExample(
    'pascal_odoo',
    t(markTr('Odoo sin conexión (Pascal)')),
    t(
      markTr(
        'Cockpit de ventas al estilo de SAP Business One para Odoo 8 a 20, en Pascal con Lazarus: indicadores y gráficos, clientes, productos y presupuestos que se crean sin conexión y se sincronizan sin duplicados.',
      ),
    ),
    design,
    code,
  );
}

/// Una cadena de Pascal ('…', con '' para la comilla y #10 para el salto).
String _odooPas(String v) {
  if (v.isEmpty) return "''";
  final out = StringBuffer();
  for (final (i, l) in v.split('\n').indexed) {
    if (i > 0) out.write('#10');
    if (l.isNotEmpty) out.write("'${l.replaceAll("'", "''")}'");
  }
  return out.toString();
}

const _odooInterface = r'''
type
  { Lo que puede fallar al hablar con Odoo. }
  TOdooErrorKind = (oeNetwork, oeSSL, oeLogin, oeDatabase, oeServer,
    oeSession, oeConfig);

  EOdoo = class(Exception)
  public
    Kind: TOdooErrorKind;
    constructor Make(AKind: TOdooErrorKind; const Msg: string);
  end;

  TOdooLog = procedure(const Line: string) of object;

  { Odoo por JSON-RPC con las rutas del cliente web, que existen de la 8 a la
    20: /web/session/authenticate (deja la cookie session_id) y
    /web/dataset/call_kw/<modelo>/<método>. }
  TOdooClient = class
  private
    FFields: TJSONObject;
    FId: Integer;
    function Post(const Path, Body: string): string;
    function Call(const Path: string; Params: TJSONObject): TJSONData;
    procedure LoadFields(const Model: string);
  public
    Url, Db, Login, Password: string;
    Uid, Major, Timeout: Integer;
    Version, Session: string;
    constructor Create;
    destructor Destroy; override;
    function Base: string;
    procedure Reset;
    procedure Detect;
    function Databases: TStringList;
    procedure Authenticate;
    function Kw(const Model, Method: string; Args: TJSONArray;
      Kwargs: TJSONObject = nil): TJSONData;
    function Exists(const Model: string): Boolean;
    function Has(const Model, Field: string): Boolean;
    function Selection(const Model, Field, Value: string): Boolean;
    function SearchRead(const Model: string; Domain: TJSONArray;
      const Wanted: array of string; Limit: Integer;
      const Order: string): TJSONArray;
    function FindRef(const Model, Field, Ref: string): Integer;
    function Count(const Model: string; Domain: TJSONArray): Integer;
  end;

  { Los datos de este equipo (un JSON): clientes, productos, pedidos, la
    bandeja de salida, el registro y la configuración. }
  TOdooStore = class
  public
    Data: TJSONObject;
    FileName: string;
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure Save;
    procedure Clear;
    function List(const Key: string): TJSONArray;
    function Settings: TJSONObject;
    function NewRef: string;
    function Find(const Key: string; Id: Integer;
      const Ref: string): TJSONObject;
    procedure Queue(const Op, Ref: string; Id: Integer);
    procedure AddLog(const Line: string);
    function AddPartner(const Name, Email, Phone, Street, City,
      Vat: string; Supplier: Boolean = False): TJSONObject;
    procedure EditPartner(P: TJSONObject; const Name, Email, Phone, Street,
      City, Vat: string);
    function AddProduct(const Name, Code: string; Price, Cost: Double): TJSONObject;
    function AddOrder(Partner: TJSONObject; Lines: TJSONArray): TJSONObject;
    function AddPurchase(Partner: TJSONObject; Lines: TJSONArray): TJSONObject;
    function SetStep(O: TJSONObject; Step: Integer; const Pay: string): string;
    function AddPos(Partner: TJSONObject; Lines: TJSONArray;
      const Payment: string): TJSONObject;
    function CounterPartner: TJSONObject;
    function Pending: Integer;
    function AddBimProject(const Name: string; Partner: TJSONObject): TJSONObject;
    function AddBimBudget(Project: TJSONObject; const Name: string): TJSONObject;
    function AddConcept(B: TJSONObject; const ParentRef, AType, Code,
      Name: string; Qty, Price: Double; const Uom: string;
      out Err: string): TJSONObject;
    procedure SendBimBudget(B: TJSONObject);
  end;

  { Enviar la bandeja de salida y descargar los datos. }
  TOdooSync = class
  private
    function PartnerVals(P: TJSONObject; Creating: Boolean): TJSONObject;
    procedure PushPartner(Op: TJSONObject; AWrite: Boolean);
    function EnsureOrder(O: TJSONObject): Integer;
    procedure RefreshOrder(O: TJSONObject; Id: Integer);
    procedure PushOrder(Op: TJSONObject);
    procedure PushPos(Op: TJSONObject);
    procedure PushProduct(Op: TJSONObject);
    function LinesVals(O: TJSONObject; const Model, QtyField: string): TJSONArray;
    function PartnerOf(O: TJSONObject): Integer;
    procedure Advance(O: TJSONObject; Id: Integer);
    function EnsurePurchase(O: TJSONObject): Integer;
    procedure RefreshPurchase(O: TJSONObject; Id: Integer);
    procedure PushPurchase(Op: TJSONObject);
    procedure ConfirmPurchase(Id: Integer);
    function Bill(Id: Integer): string;
    function JournalId(const Kind: string): Integer;
    function PayInvoices(const Model: string; Id: Integer; const Kind: string): string;
    function InvoiceLevels(Rows: TJSONArray): TJSONObject;
    procedure RunWizard(R: TJSONData);
    procedure LoadCurrency;
    function CompanyCurrency: Integer;
    function BimUomId(const Name: string): Integer;
    function EnsureBimProject(P: TJSONObject): Integer;
    procedure PushBimProject(Op: TJSONObject);
    procedure PushBimBudget(Op: TJSONObject);
    procedure DownloadBim;
  public
    Client: TOdooClient;
    Store: TOdooStore;
    OnLog: TOdooLog;
    SaleMissing, BimReady: Boolean;
    constructor Create(AClient: TOdooClient; AStore: TOdooStore);
    procedure Log(const Line: string);
    procedure Connect;
    procedure Download;
    function Push: Integer;
    procedure Confirm(Id: Integer);
    function Deliver(const Model: string; Id: Integer): string;
    function Invoice(Id: Integer): string;
    function Ids(const Model: string; Id: Integer; const Field: string): TJSONArray;
    procedure LoadBimConcepts(B: TJSONObject);
  end;

  { Comprueba en segundo plano si el servidor responde. }
  TPing = class(TThread)
  public
    Url: string;
    Ok: Boolean;
    procedure Execute; override;
  end;

  TForm1 = class(TFormDesign)
  public
    Client: TOdooClient;
    Store: TOdooStore;
    Sync: TOdooSync;
    Ping: TPing;
    Online, Busy: Boolean;
    PageNo, Ticks: Integer;
    Editing: TJSONObject;
    Draft: TJSONArray;
    CustRows, ProdRows, SaleRows, RecentRows, CustChoice: array of Integer;
    PosRows, PosCustRows: array of Integer;
    PosPageNo: Integer;
    Cart: TJSONArray;
    MonthBox, StateBox, TopBox, PosBox: TPaintBox;
    BimBudRows, BimTreeRows, BimRowRows: array of Integer;
    BimProjKey, BimBudKey, BimSelRef, BimRowRef: string;
    BimOpen: TStringList;
    BimSibMode: Boolean;
    PurRows, PurSuppChoice: array of Integer;
    PurDraft: TJSONArray;
    EditingProd: TJSONObject;
    destructor Destroy; override;
    procedure form_create; override;
    procedure form_close; override;
    procedure StyleUi;
    procedure ShowPage(N: Integer);
    procedure EditEnter(Sender: TObject);
    procedure Deselect(Data: PtrInt);
    procedure PaintNav(Data: PtrInt);
    procedure NavPanel_click; override;
    procedure NavCustomers_click; override;
    procedure NavProducts_click; override;
    procedure NavSales_click; override;
    procedure NavPos_click; override;
    procedure NavSync_click; override;
    procedure NavSettings_click; override;
    procedure AddLog(const Line: string);
    procedure RefreshAll;
    procedure RefreshStatus;
    procedure RefreshKpis;
    procedure RefreshCustomers;
    procedure RefreshProducts;
    procedure RefreshSales;
    procedure RefreshChoices;
    procedure RefreshDraft;
    procedure RefreshOutbox;
    procedure RefreshSyncInfo;
    procedure LoadSettings;
    procedure SaveSettings;
    function Configured: Boolean;
    procedure SetBusy(B: Boolean);
    procedure Fail(E: Exception; Quiet: Boolean);
    procedure DoSync(Quiet: Boolean);
    procedure StartPing;
    procedure BtnSync_click; override;
    procedure Tick_timer; override;
    procedure SearchChange(Sender: TObject);
    procedure CustList_select; override;
    procedure CustNew_click; override;
    procedure CustSave_click; override;
    procedure CustCancel_click; override;
    procedure ShowCustomer(P: TJSONObject);
    procedure SaleFilter_select; override;
    procedure SaleNew_click; override;
    procedure SaleList_double; override;
    procedure RecentList_double; override;
    procedure ShowOrder(O: TJSONObject);
    procedure QuoteAdd_click; override;
    procedure QuoteDel_click; override;
    procedure QuoteSave_click; override;
    procedure SyncNow_click; override;
    procedure SyncReload_click; override;
    procedure SyncAuto_click; override;
    procedure SyncOffline_click; override;
    procedure OutboxDiscard_click; override;
    procedure CfgDetect_click; override;
    procedure CfgTest_click; override;
    procedure CfgConnect_click; override;
    procedure CfgReset_click; override;
    procedure DrawCustomer(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DrawProduct(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DrawSale(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DrawRecent(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DrawOutbox(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure PaintMonth(Sender: TObject);
    procedure PaintState(Sender: TObject);
    procedure PaintTop(Sender: TObject);
    // punto de venta
    procedure RefreshPos;
    procedure RefreshCart;
    procedure RefreshPosCustomers;
    procedure PaintPos(Sender: TObject);
    procedure PosMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PosCat_select; override;
    procedure PosPrev_click; override;
    procedure PosNext_click; override;
    procedure PosLines_select; override;
    procedure PosApply_click; override;
    procedure PosDel_click; override;
    procedure PosClear_click; override;
    procedure PosPay_click; override;
    procedure DrawPosLine(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure LayoutNav;
    procedure NavBim_click; override;
    function CurBimProject: TJSONObject;
    function CurBimBudget: TJSONObject;
    function BimEditable(B: TJSONObject): Boolean;
    function BimShown(A: TJSONArray; I: Integer): Boolean;
    procedure BimReveal(A: TJSONArray; const R: string);
    function BimParentFor(B: TJSONObject; const T: string): string;
    function BimRead(out T: string; out Q, Pr: Double): Boolean;
    function AskBimProject(out AName: string; out Partner: TJSONObject): Boolean;
    procedure BimPrepare(Sibling: Boolean);
    procedure BimSuggestCode;
    procedure BimCommit;
    procedure BimOpenRow(R: Integer);
    procedure RefreshBim;
    procedure RefreshBimBudgets;
    procedure RefreshBimTree;
    procedure RefreshBimRows;
    procedure BimProject_select; override;
    procedure BimProjAdd_click; override;
    procedure BimBudSel_select; override;
    procedure BimBudNew_click; override;
    procedure BimTree_select; override;
    procedure BimRows_select; override;
    procedure BimRows_double; override;
    procedure BimType_select; override;
    procedure BimAdd_click; override;
    procedure BimHome_click; override;
    procedure BimChild_click; override;
    procedure BimSibling_click; override;
    procedure BimEnter_key; override;
    procedure BimApply_click; override;
    procedure BimDel_click; override;
    procedure BimSend_click; override;
    procedure BimTreeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BimRowsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BimKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DrawBimNode(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DrawBimRow(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    // productos, pasos de los pedidos y compras
    procedure ShowProduct(P: TJSONObject);
    procedure ProdNew_click; override;
    procedure ProdSave_click; override;
    procedure ProdList_select; override;
    procedure StepSelected(L: TListBox; const Rows: array of Integer;
      const Key: string; Step: Integer; PayKind: TComboBox);
    procedure SaleConfirm_click; override;
    procedure SaleInvoice_click; override;
    procedure SalePay_click; override;
    procedure NavPurchases_click; override;
    procedure RefreshPurchases;
    procedure RefreshPurChoices;
    procedure RefreshPurDraft;
    procedure PurFilter_select; override;
    procedure PurNew_click; override;
    procedure PurList_double; override;
    procedure PurProd_select; override;
    procedure PurAdd_click; override;
    procedure PurDel_click; override;
    procedure PurSave_click; override;
    procedure PurConfirm_click; override;
    procedure PurBill_click; override;
    procedure PurPay_click; override;
    procedure DrawPurchase(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
  end;

{ Prepara OpenSSL para HTTPS (antes de la primera conexión). }
procedure SetupOpenSSL;
{ La carpeta de datos del usuario. }
function DataDir: string;
''';

const _odooBody = r'''
const
  CInk = $00392A1B;      // #1b2a39 (los TColor van al revés: $BBGGRR)
  CMuted = $00706B5B;    // #5b6b70
  CLine = $00F3F0ED;     // #edf0f3
  CSel = $00FAF0E5;      // #e5f0fa
  CBlue = $00D16E0A;     // #0a6ed1
  CBlueSoft = $00F6C891; // #91c8f6
  CGreen = $003E7E10;    // #107e3e
  CGrey = $00A89683;     // #8396a8
  COrange = $000C73E9;   // #e9730c
  CPurple = $00C44B5B;   // #5b4bc4
  CSide = $003A2A1B;     // #1b2a3a
  CSideFg = $00DCD0C5;   // #c5d0dc
  CTeal = $00887A00;     // #007a88

var
  SSLFrom: string = ''; // la OpenSSL que se cargó (vacío: ninguna)
  CurSymbol: string = '';
  CurAfter: Boolean = True;
  Thousands: Char = '.';
  Decimals: Char = ',';

// ------------------------------------------------------------ ayudantes

function JStr(O: TJSONObject; const K: string): string;
var
  D: TJSONData;
begin
  Result := '';
  if O = nil then Exit;
  D := O.Find(K);
  if (D <> nil) and (D.JSONType = jtString) then Result := D.AsString;
end;

function JInt(O: TJSONObject; const K: string): Integer;
var
  D: TJSONData;
begin
  Result := 0;
  if O = nil then Exit;
  D := O.Find(K);
  if (D <> nil) and (D.JSONType = jtNumber) then Result := D.AsInteger;
end;

function JNum(O: TJSONObject; const K: string): Double;
var
  D: TJSONData;
begin
  Result := 0;
  if O = nil then Exit;
  D := O.Find(K);
  if (D <> nil) and (D.JSONType = jtNumber) then Result := D.AsFloat;
end;

function JBool(O: TJSONObject; const K: string): Boolean;
var
  D: TJSONData;
begin
  Result := False;
  if O = nil then Exit;
  D := O.Find(K);
  if (D <> nil) and (D.JSONType = jtBoolean) then Result := D.AsBoolean;
end;

{ Un many2one de Odoo llega como [id, "nombre"] o false. }
function M2OId(O: TJSONObject; const K: string): Integer;
var
  D: TJSONData;
begin
  Result := 0;
  D := O.Find(K);
  if (D is TJSONArray) and (TJSONArray(D).Count > 0) then
    Result := TJSONArray(D).Items[0].AsInteger;
end;

function M2OName(O: TJSONObject; const K: string): string;
var
  D: TJSONData;
begin
  Result := '';
  D := O.Find(K);
  if (D is TJSONArray) and (TJSONArray(D).Count > 1) then
    Result := TJSONArray(D).Items[1].AsString;
end;

{ Un dominio de Odoo con una condición: [[campo, op, valor]]. }
function Domain1(const Field, Op: string; Value: TJSONData): TJSONArray;
var
  C: TJSONArray;
begin
  C := TJSONArray.Create([Field, Op]);
  C.Add(Value);
  Result := TJSONArray.Create;
  Result.Add(C);
end;

function NowStamp: string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;

{ El primer número de un texto («saas~17.2» → 17). }
function LeadNumber(const S: string): Integer;
var
  I: Integer;
  N: string;
begin
  N := '';
  for I := 1 to Length(S) do
    if S[I] in ['0'..'9'] then N := N + S[I]
    else if N <> '' then Break;
  Result := StrToIntDef(N, 0);
end;

function Part(const S: string; Index: Integer): string;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.StrictDelimiter := True;
    L.Delimiter := '|';
    L.DelimitedText := S;
    if (Index >= 0) and (Index < L.Count) then Result := L[Index]
    else Result := '';
  finally
    L.Free;
  end;
end;

function Money(V: Double): string;
var
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.ThousandSeparator := Thousands;
  F.DecimalSeparator := Decimals;
  Result := FormatFloat('#,##0.00', V, F);
  if CurSymbol = '' then Exit;
  if CurAfter then Result := Result + ' ' + CurSymbol
  else Result := CurSymbol + ' ' + Result;
end;

{ 1234567 → «1,2M»; para los ejes de los gráficos. }
function Compact(V: Double): string;
var
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  if V >= 1e6 then Result := FormatFloat('0.#', V / 1e6, F) + 'M'
  else if V >= 1e3 then Result := FormatFloat('0.#', V / 1e3, F) + 'k'
  else Result := FormatFloat('0', V, F);
end;

function ShortDate(const Stamp: string): string;
begin
  // «2026-11-06 10:30:00» → «06/11/2026»
  if Length(Stamp) >= 10 then
    Result := Copy(Stamp, 9, 2) + '/' + Copy(Stamp, 6, 2) + '/' +
      Copy(Stamp, 1, 4)
  else Result := Stamp;
end;

{ 0 presupuesto, 1 pedido, 2 cancelado, 3 sin enviar. Los estados cambian
  con la versión: en la 8 hay progress, manual…; de la 9 a la 16, sale y
  done; desde la 17, done ya no existe. }
function StateKind(O: TJSONObject): Integer;
var
  S: string;
begin
  if JBool(O, 'pending') then Exit(3);
  S := JStr(O, 'state');
  if (S = 'draft') or (S = 'sent') or (S = 'to approve') then Result := 0
  else if S = 'cancel' then Result := 2
  else Result := 1;
end;

{ ¿Confirmado en Odoo? Venta: sale, done (y progress o manual en la 8);
  compra: purchase, done (approved en la 8). }
function Confirmed(O: TJSONObject): Boolean;
var
  S: string;
begin
  S := JStr(O, 'state');
  Result := (S <> '') and (S <> 'draft') and (S <> 'sent') and (S <> 'cancel') and
    (S <> 'to approve') and (S <> 'bid') and not (JBool(O, 'purchase') and (S = 'confirmed'));
end;

{ Hasta dónde llegó un pedido en Odoo: 0 presupuesto (o solicitud), 1
  confirmado, 2 facturado y 3 pagado. «want» es hasta dónde se pidió aquí
  (puede que aún sin enviar). }
function OrderLevel(O: TJSONObject): Integer;
begin
  Result := JInt(O, 'level');
  if (Result = 0) and Confirmed(O) then Result := 1;
end;

function StepLabel(O: TJSONObject; Step: Integer): string;
begin
  case Step of
    3: Result := SStPaid;
    2: Result := SStInvoiced;
    1:
      if JBool(O, 'purchase') then Result := SPoOrder
      else if JStr(O, 'state') = 'done' then Result := SStDone
      else Result := SStSale;
  else
    if JBool(O, 'purchase') then Result := SPoDraft
    else if JStr(O, 'state') = 'sent' then Result := SStSent
    else Result := SStDraft;
  end;
end;

{ El paso de una venta del punto de venta. }
function PosLabel(O: TJSONObject): string;
var
  S: string;
begin
  S := JStr(O, 'step');
  if JStr(O, 'error') <> '' then Result := SPosError
  else if S = 'invoiced' then Result := SPosInvoiced
  else if S = 'delivered' then Result := SPosDelivered
  else if S = 'order' then Result := SPosOrder
  else Result := SPosPending;
end;

function StateLabel(O: TJSONObject): string;
var
  Want, Level: Integer;
begin
  if JBool(O, 'pos') then Exit(PosLabel(O));
  if JStr(O, 'state') = 'cancel' then Exit(SStCancel);
  Want := JInt(O, 'want');
  Level := OrderLevel(O);
  if (JInt(O, 'id') = 0) and (Want = 0) then Exit(SStPending);
  Result := StepLabel(O, Max(Want, Level));
  if (Want > Level) or (JInt(O, 'id') = 0) then Result := Result + ' · ' + SPendingTag;
end;

function KindColor(Kind: Integer): TColor;
begin
  case Kind of
    0: Result := CBlue;
    1: Result := CGreen;
    2: Result := CGrey;
  else
    Result := COrange;
  end;
end;

function StateColor(O: TJSONObject): TColor;
begin
  if JBool(O, 'pos') then
  begin
    if JStr(O, 'error') <> '' then Exit(clRed);
    if JStr(O, 'step') = 'invoiced' then Exit(CPurple);
    if JStr(O, 'step') = 'delivered' then Exit(CGreen);
    if JStr(O, 'step') = 'order' then Exit(CBlue);
    Exit(COrange);
  end;
  if JStr(O, 'state') = 'cancel' then Exit(CGrey);
  if (JInt(O, 'id') = 0) or (JInt(O, 'want') > OrderLevel(O)) then Exit(COrange);
  case OrderLevel(O) of
    3: Result := CTeal;
    2: Result := CPurple;
    1: Result := CGreen;
  else
    Result := CBlue;
  end;
end;

function OrderTitle(O: TJSONObject): string;
begin
  Result := JStr(O, 'name');
  if Result = '' then Result := SNewOrder + ' · ' + JStr(O, 'ref');
  if JBool(O, 'pos') then Result := 'TPV ' + Result;
end;

{ Lo que dice una entrada de la bandeja de salida. }
function Describe(Store: TOdooStore; Op: TJSONObject): string;
var
  K: string;
  R: TJSONObject;
begin
  K := JStr(Op, 'op');
  if K = 'bim_project' then
  begin
    R := Store.Find('bim_projects', 0, JStr(Op, 'ref'));
    if R = nil then Exit(SOpGone);
    Exit(Format(SOpBimProject, [JStr(R, 'name')]));
  end;
  if K = 'bim_budget' then
  begin
    R := Store.Find('bim_budgets', 0, JStr(Op, 'ref'));
    if R = nil then Exit(SOpGone);
    Exit(Format(SOpBimBudget, [JStr(R, 'name'), Money(JNum(R, 'amount'))]));
  end;
  if K = 'product_create' then
  begin
    R := Store.Find('products', 0, JStr(Op, 'ref'));
    if R = nil then Exit(SOpGone);
    Exit(Format(SOpNewProduct, [JStr(R, 'name')]));
  end;
  if (K = 'order_step') or (K = 'purchase_step') then
  begin
    if K = 'order_step' then R := Store.Find('orders', JInt(Op, 'id'), '')
    else R := Store.Find('purchases', JInt(Op, 'id'), '');
    if R = nil then Exit(SOpGone);
    if K = 'order_step' then
      Exit(Format(SOpOrderStep, [OrderTitle(R), StepLabel(R, JInt(R, 'want'))]));
    Exit(Format(SOpPurStep, [OrderTitle(R), StepLabel(R, JInt(R, 'want'))]));
  end;
  if K = 'purchase_create' then
  begin
    R := Store.Find('purchases', 0, JStr(Op, 'ref'));
    if R = nil then Exit(SOpGone);
    Result := Format(SOpNewPurchase, [JStr(R, 'partner'), Money(JNum(R, 'amount'))]);
    if JInt(R, 'want') > 0 then Result := Result + ' → ' + StepLabel(R, JInt(R, 'want'));
    Exit;
  end;
  if (K = 'order_create') or (K = 'pos_sale') then
  begin
    R := Store.Find('orders', 0, JStr(Op, 'ref'));
    if R = nil then Exit(SOpGone);
    if K = 'pos_sale' then
      Result := Format(SOpPos, [JStr(R, 'partner'), Money(JNum(R, 'amount'))])
    else
    begin
      Result := Format(SOpNewOrder, [JStr(R, 'partner'), Money(JNum(R, 'amount'))]);
      if JInt(R, 'want') > 0 then Result := Result + ' → ' + StepLabel(R, JInt(R, 'want'));
    end;
  end
  else
  begin
    R := Store.Find('partners', JInt(Op, 'id'), JStr(Op, 'ref'));
    if R = nil then Exit(SOpGone);
    if K = 'partner_create' then Result := Format(SOpNewPartner, [JStr(R, 'name')])
    else Result := Format(SOpEditPartner, [JStr(R, 'name')]);
  end;
end;

{ El texto que cabe en W píxeles (con «…»). }
function Fit(C: TCanvas; const S: string; W: Integer): string;
var
  N: Integer;
begin
  Result := S;
  if (W <= 0) or (C.TextWidth(S) <= W) then Exit;
  N := UTF8Length(S);
  while (N > 0) and (C.TextWidth(UTF8Copy(S, 1, N) + '…') > W) do Dec(N);
  Result := UTF8Copy(S, 1, N) + '…';
end;

{ Prueba una OpenSSL: la unidad openssl carga Dir + Ssl + versión (+ .dylib
  en macOS, + .so en Linux) y la da por buena si están todas las funciones.
  Si falla, deja todo descargado y se puede probar la siguiente. }
function TryOpenSSL(const Dir, Ssl, Crypto: string;
  const Versions: array of string): Boolean;
{$IFNDEF MSWINDOWS}
var
  I: Integer;
{$ENDIF}
begin
  DLLSSLName := Dir + Ssl;
  DLLUtilName := Dir + Crypto;
  {$IFNDEF MSWINDOWS}
  // FPC 3.2.2 prueba DLLVersions[1..19]; en macOS cambia [1] (vacío) por [2]
  // porque cargar libssl.dylib sin número cierra el programa. Se dejan solo
  // las versiones de esta prueba.
  for I := 2 to High(DLLVersions) do
    if I - 2 <= High(Versions) then DLLVersions[I] := Versions[I - 2]
    else DLLVersions[I] := Versions[High(Versions)];
  {$ENDIF}
  Result := InitSSLInterface;
  if Result then SSLFrom := DLLSSLName;
end;

{ OpenSSL para HTTPS: primero la que va con la aplicación (junto al
  ejecutable o, en macOS, en Contents/Frameworks), luego la de Homebrew y por
  último la LibreSSL de macOS (siempre con número de versión). Cada una se
  prueba de verdad: una de otra arquitectura (arm64 con Intel) no sirve. }
procedure SetupOpenSSL;
var
  Exe: string;
{$IFDEF DARWIN}
const
  Brew3: array[0..1] of string = ('/opt/homebrew/opt/openssl@3/lib/',
    '/usr/local/opt/openssl@3/lib/');
  Brew11: array[0..1] of string = ('/opt/homebrew/opt/openssl@1.1/lib/',
    '/usr/local/opt/openssl@1.1/lib/');
var
  I: Integer;
  Dirs: array[0..3] of string;
{$ENDIF}
begin
  SSLFrom := '';
  Exe := ExtractFilePath(ExpandFileName(ParamStr(0)));
  {$IFDEF DARWIN}
  Dirs[0] := Exe;
  Dirs[1] := ExpandFileName(Exe + '../Frameworks') + '/';
  Dirs[2] := Brew3[0];
  Dirs[3] := Brew3[1];
  for I := 0 to High(Dirs) do
    if FileExists(Dirs[I] + 'libssl.3.dylib') and
      TryOpenSSL(Dirs[I], 'libssl', 'libcrypto', ['.3']) then Exit;
  for I := 0 to High(Brew11) do
    if FileExists(Brew11[I] + 'libssl.1.1.dylib') and
      TryOpenSSL(Brew11[I], 'libssl', 'libcrypto', ['.1.1']) then Exit;
  TryOpenSSL('/usr/lib/', 'libssl', 'libcrypto', ['.48', '.46', '.44', '.43',
    '.42', '.41', '.39', '.38', '.35']);
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  // Las DLL de OpenSSL 3 (o 1.1) junto al .exe; si no, las del sistema.
  if FileExists(Exe + 'libssl-3-x64.dll') and
    TryOpenSSL(Exe, 'libssl-3-x64.dll', 'libcrypto-3-x64.dll', []) then Exit;
  if FileExists(Exe + 'libssl-3.dll') and
    TryOpenSSL(Exe, 'libssl-3.dll', 'libcrypto-3.dll', []) then Exit;
  if FileExists(Exe + 'libssl-1_1-x64.dll') and
    TryOpenSSL(Exe, 'libssl-1_1-x64.dll', 'libcrypto-1_1-x64.dll', []) then Exit;
  TryOpenSSL('', 'libssl-3-x64.dll', 'libcrypto-3-x64.dll', []);
  {$ENDIF}
  {$IFDEF LINUX}
  if TryOpenSSL('', 'libssl', 'libcrypto', ['.3']) then Exit;
  TryOpenSSL('', 'libssl', 'libcrypto', ['.1.1']);
  {$ENDIF}
end;

function DataDir: string;
begin
  {$IFDEF DARWIN}
  Result := GetUserDir + 'Library/Application Support/DMarlon Odoo/';
  {$ELSE}
  Result := ExtractFilePath(ExcludeTrailingPathDelimiter(GetAppConfigDir(False))) +
    'DMarlonOdoo' + PathDelim;
  {$ENDIF}
  ForceDirectories(Result);
end;

// ---------------------------------------------------------------- EOdoo

constructor EOdoo.Make(AKind: TOdooErrorKind; const Msg: string);
begin
  inherited Create(Msg);
  Kind := AKind;
end;

// ----------------------------------------------------------- TOdooClient

constructor TOdooClient.Create;
begin
  FFields := TJSONObject.Create;
  Timeout := 15000;
end;

destructor TOdooClient.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

{ https://servidor (sin la barra final ni lo que vaya detrás). }
function TOdooClient.Base: string;
var
  P: Integer;
begin
  Result := Trim(Url);
  if Result = '' then Exit;
  if Pos('://', Result) = 0 then Result := 'https://' + Result;
  P := Pos('/', Copy(Result, Pos('://', Result) + 3, MaxInt));
  if P > 0 then Result := Copy(Result, 1, Pos('://', Result) + 1 + P);
end;

procedure TOdooClient.Reset;
begin
  FFields.Clear;
  Uid := 0;
  Major := 0;
  Version := '';
  Session := '';
end;

{ Una llamada que solo lee: si el servidor (o su proxy) responde 502, 503 o
  504, se puede repetir sin miedo. Las que escriben no se repiten: se quedan
  en la bandeja y, al sincronizar, se busca su referencia antes de crear. }
function ReadOnlyPath(const Path: string): Boolean;
const
  Reads: array[0..8] of string = ('/search', '/search_read', '/search_count',
    '/read', '/fields_get', '/name_search', 'version_info', 'database/list',
    'database/get_list');
var
  I: Integer;
begin
  for I := 0 to High(Reads) do
    if Copy(Path, Length(Path) - Length(Reads[I]) + 1, MaxInt) = Reads[I] then Exit(True);
  Result := False;
end;

function TOdooClient.Post(const Path, Body: string): string;
var
  C: TFPHTTPClient;
  Src, Res: TStringStream;
  I, P, Tries: Integer;
  H, V: string;
begin
  Result := '';
  if Base = '' then raise EOdoo.Make(oeConfig, SNoUrl);
  for Tries := 1 to 4 do
  begin
    C := TFPHTTPClient.Create(nil);
    Src := TStringStream.Create(Body);
    Res := TStringStream.Create('');
    try
      C.ConnectTimeout := Timeout;
      C.IOTimeout := Timeout * 4;
      C.AllowRedirect := False;
      C.AddHeader('Content-Type', 'application/json');
      C.AddHeader('Accept', 'application/json');
      C.AddHeader('User-Agent', 'DMarlonStudio-Odoo/1.0');
      if Session <> '' then C.AddHeader('Cookie', 'session_id=' + Session);
      C.RequestBody := Src;
      try
        C.HTTPMethod('POST', Base + Path, Res, []);
      except
        on E: Exception do
          if Pos('OpenSSL', E.Message) > 0 then
            raise EOdoo.Make(oeSSL, SSslMissing)
          else
            raise EOdoo.Make(oeNetwork, Format(SNoNetwork, [Base, E.Message]));
      end;
      // La sesión: la cookie session_id (cambia al iniciar sesión).
      for I := 0 to C.ResponseHeaders.Count - 1 do
      begin
        H := C.ResponseHeaders[I];
        P := Pos('session_id=', H);
        if SameText(Copy(H, 1, 11), 'Set-Cookie:') and (P > 0) then
        begin
          V := Copy(H, P + 11, MaxInt);
          if Pos(';', V) > 0 then V := Copy(V, 1, Pos(';', V) - 1);
          Session := Trim(V);
        end;
      end;
      case C.ResponseStatusCode of
        300..399:
          begin
            // http → https, o con www: se sigue a mano (POST se conserva).
            V := C.GetHeader(C.ResponseHeaders, 'Location');
            P := Pos(Path, V);
            if (P > 1) and (Tries < 3) then
            begin
              Url := Copy(V, 1, P - 1);
              Continue;
            end;
            raise EOdoo.Make(oeServer, Format(SRedirect, [V]));
          end;
        404: raise EOdoo.Make(oeServer, Format(SNotFound, [Path]));
        502..504:
          if ReadOnlyPath(Path) and (Tries < 4) then
          begin
            Sleep(1500 * Tries);
            Continue;
          end;
      end;
      Result := Res.DataString;
      if (C.ResponseStatusCode <> 200) and (Copy(TrimLeft(Result), 1, 1) <> '{') then
        raise EOdoo.Make(oeServer, Format(SHttpError, [C.ResponseStatusCode]));
      Exit;
    finally
      C.Free;
      Src.Free;
      Res.Free;
    end;
  end;
end;

{ Una llamada JSON-RPC 2.0: devuelve «result» (hay que liberarlo) o lanza
  EOdoo con el error de Odoo. }
function TOdooClient.Call(const Path: string; Params: TJSONObject): TJSONData;
var
  Req: TJSONObject;
  Doc, Err, D: TJSONData;
  Text, Msg, Name: string;
  Code: Integer;
begin
  Inc(FId);
  Req := TJSONObject.Create(['jsonrpc', '2.0', 'method', 'call', 'id', FId]);
  Req.Add('params', Params);
  try
    Text := Post(Path, Req.AsJSON);
  finally
    Req.Free;
  end;
  try
    Doc := GetJSON(Text);
  except
    raise EOdoo.Make(oeServer, Format(SNotOdoo, [Base]));
  end;
  try
    if not (Doc is TJSONObject) then
      raise EOdoo.Make(oeServer, Format(SNotOdoo, [Base]));
    Err := TJSONObject(Doc).Find('error');
    if Err is TJSONObject then
    begin
      Msg := JStr(TJSONObject(Err), 'message');
      Code := JInt(TJSONObject(Err), 'code');
      Name := '';
      D := TJSONObject(Err).Find('data');
      if D is TJSONObject then
      begin
        Name := JStr(TJSONObject(D), 'name');
        if JStr(TJSONObject(D), 'message') <> '' then
          Msg := JStr(TJSONObject(D), 'message');
      end;
      if (Code = 100) or (Pos('SessionExpired', Name) > 0) then
        raise EOdoo.Make(oeSession, Msg);
      if Pos('AccessDenied', Name) > 0 then raise EOdoo.Make(oeLogin, SBadLogin);
      if (Pos('database', LowerCase(Msg)) > 0) and ((Pos('does not exist', Msg) > 0)
        or (Pos('not found', LowerCase(Msg)) > 0)) then
        raise EOdoo.Make(oeDatabase, Format(SNoDatabase, [Db]));
      raise EOdoo.Make(oeServer, Trim(Msg));
    end;
    D := TJSONObject(Doc).Find('result');
    if D = nil then Result := TJSONNull.Create
    else Result := D.Clone;
  finally
    Doc.Free;
  end;
end;

{ La versión: /web/webclient/version_info no necesita sesión. }
procedure TOdooClient.Detect;
var
  R, A: TJSONData;
begin
  Major := 0;
  R := Call('/web/webclient/version_info', TJSONObject.Create);
  try
    if R is TJSONObject then
    begin
      Version := JStr(TJSONObject(R), 'server_version');
      A := TJSONObject(R).Find('server_version_info');
      if (A is TJSONArray) and (TJSONArray(A).Count > 0) then
        if TJSONArray(A).Items[0].JSONType = jtNumber then
          Major := TJSONArray(A).Items[0].AsInteger
        else
          Major := LeadNumber(TJSONArray(A).Items[0].AsString);
      if Major = 0 then Major := LeadNumber(JStr(TJSONObject(R), 'server_serie'));
      if Major = 0 then Major := LeadNumber(Version);
    end;
  finally
    R.Free;
  end;
  if Major = 0 then raise EOdoo.Make(oeServer, Format(SNotOdoo, [Base]));
end;

{ Las bases de datos: /web/database/list (9+), /web/database/get_list (8) o,
  si no, el servicio «db» de /jsonrpc. Puede estar desactivado (list_db). }
function TOdooClient.Databases: TStringList;
const
  Paths: array[0..1] of string = ('/web/database/list',
    '/web/database/get_list');
var
  R: TJSONData;
  P: string;
  I: Integer;
  Params: TJSONObject;
begin
  Result := TStringList.Create;
  R := nil;
  try
    for P in Paths do
    try
      R := Call(P, TJSONObject.Create);
      Break;
    except
      on E: EOdoo do
        if E.Kind in [oeNetwork, oeSSL, oeConfig] then raise;
    end;
    if R = nil then
    try
      Params := TJSONObject.Create(['service', 'db', 'method', 'list']);
      Params.Add('args', TJSONArray.Create);
      R := Call('/jsonrpc', Params);
    except
      on E: EOdoo do
        if E.Kind in [oeNetwork, oeSSL, oeConfig] then raise
        else raise EOdoo.Make(oeDatabase, SNoDbList);
    end;
    if R is TJSONArray then
      for I := 0 to TJSONArray(R).Count - 1 do
        Result.Add(TJSONArray(R).Items[I].AsString);
    R.Free;
  except
    Result.Free;
    raise;
  end;
end;

procedure TOdooClient.Authenticate;
var
  R: TJSONData;
  L: TStringList;
begin
  if Major = 0 then Detect;
  if Trim(Db) = '' then
  begin
    L := Databases;
    try
      if L.Count = 1 then Db := L[0]
      else if L.Count = 0 then raise EOdoo.Make(oeDatabase, SNoDbList)
      else raise EOdoo.Make(oeDatabase, Format(SManyDbs, [L.CommaText]));
    finally
      L.Free;
    end;
  end;
  Session := '';
  Uid := 0;
  R := Call('/web/session/authenticate',
    TJSONObject.Create(['db', Trim(Db), 'login', Login, 'password', Password]));
  try
    // Hasta la 11 una contraseña mala devuelve uid = false; después, error.
    if R is TJSONObject then Uid := JInt(TJSONObject(R), 'uid');
  finally
    R.Free;
  end;
  if Uid <= 0 then raise EOdoo.Make(oeLogin, SBadLogin);
end;

{ model.method(*args, **kwargs). Si la sesión caduca, entra otra vez. }
function TOdooClient.Kw(const Model, Method: string; Args: TJSONArray;
  Kwargs: TJSONObject): TJSONData;
var
  Params: TJSONObject;
  Again: Boolean;
begin
  if Kwargs = nil then Kwargs := TJSONObject.Create;
  Params := TJSONObject.Create(['model', Model, 'method', Method]);
  Params.Add('args', Args);
  Params.Add('kwargs', Kwargs);
  Again := True;
  try
    if Uid = 0 then Authenticate;
    while True do
    try
      Result := Call('/web/dataset/call_kw/' + Model + '/' + Method,
        TJSONObject(Params.Clone));
      Exit;
    except
      on E: EOdoo do
        if (E.Kind = oeSession) and Again then
        begin
          Again := False;
          Authenticate;
        end
        else raise;
    end;
  finally
    Params.Free;
  end;
end;

{ Qué campos tiene cada modelo en esta versión (fields_get solo de los que
  interesan): customer (hasta la 12) o customer_rank (13+), mobile (hasta
  la 18), product_uom o product_uom_id, qty_available (con Inventario)… }
procedure TOdooClient.LoadFields(const Model: string);
var
  Names: string;
  Wanted, Args: TJSONArray;
  K: TJSONObject;
  R: TJSONData;
  F: string;
  L: TStringList;
begin
  if FFields.Find(Model) <> nil then Exit;
  if Model = 'res.partner' then
    Names := 'name,email,phone,mobile,street,city,vat,ref,is_company,customer,customer_rank,' +
      'supplier,supplier_rank,user_ids'
  else if Model = 'product.product' then
    Names := 'name,default_code,lst_price,list_price,standard_price,qty_available,uom_id,' +
      'sale_ok,purchase_ok,categ_id,type,invoice_policy,purchase_method'
  else if Model = 'sale.order' then
    Names := 'name,partner_id,date_order,amount_total,state,client_order_ref,' +
      'origin,picking_ids,invoice_ids'
  else if Model = 'sale.order.line' then
    Names := 'name,product_id,product_uom_qty,price_unit,product_uom,' +
      'product_uom_id,discount,qty_delivered,qty_to_invoice,order_id'
  else if Model = 'purchase.order' then
    Names := 'name,partner_id,date_order,amount_total,state,origin,picking_ids,invoice_ids'
  else if Model = 'purchase.order.line' then
    Names := 'name,product_id,product_qty,price_unit,product_uom,product_uom_id,' +
      'date_planned,qty_to_invoice,order_id'
  else if Model = 'account.journal' then
    Names := 'name,type'
  else if Model = 'account.payment' then
    Names := 'payment_type,partner_type,partner_id,amount,journal_id,payment_method_id,invoice_ids'
  else if Model = 'stock.picking' then
    Names := 'name,state,move_ids,move_lines'
  else if Model = 'stock.move' then
    Names := 'product_uom_qty,quantity,quantity_done,picked,state'
  else if Model = 'sale.advance.payment.inv' then
    Names := 'advance_payment_method,sale_order_ids'
  else if (Model = 'account.invoice') or (Model = 'account.move') then
    Names := 'name,number,state,payment_state,invoice_payment_state,amount_residual,' +
      'residual,invoice_date,type,move_type,partner_id'
  else if Model = 'bim.project' then
    Names := 'name,nombre,notes,customer_id'
  else if Model = 'bim.budget' then
    Names := 'name,code,origin,project_id,balance'
  else if Model = 'bim.concepts' then
    Names := 'name,code,type,id_import,amount_type,amount_fixed,uom_id,parent_id'
  else
    Names := 'name';
  Wanted := TJSONArray.Create;
  L := TStringList.Create;
  try
    L.CommaText := Names;
    for F in L do Wanted.Add(F);
  finally
    L.Free;
  end;
  Args := TJSONArray.Create;
  Args.Add(Wanted);
  K := TJSONObject.Create;
  if Major >= 9 then K.Add('attributes', TJSONArray.Create(['type', 'selection']));
  try
    R := Kw(Model, 'fields_get', Args, K);
    if R is TJSONObject then FFields.Add(Model, R)
    else
    begin
      R.Free;
      FFields.Add(Model, TJSONObject.Create);
    end;
  except
    on E: EOdoo do
      if E.Kind = oeServer then
        FFields.Add(Model, TJSONObject.Create(['__missing', True]))
      else raise;
  end;
end;

function TOdooClient.Exists(const Model: string): Boolean;
begin
  LoadFields(Model);
  Result := TJSONObject(FFields.Find(Model)).Find('__missing') = nil;
end;

function TOdooClient.Has(const Model, Field: string): Boolean;
begin
  LoadFields(Model);
  Result := (TJSONObject(FFields.Find(Model)).Find(Field) <> nil) and
    (Field <> '__missing');
end;

{ ¿Tiene el campo de selección esa opción en esta versión? }
function TOdooClient.Selection(const Model, Field, Value: string): Boolean;
var
  F, Sel: TJSONData;
  I: Integer;
begin
  Result := False;
  if not Has(Model, Field) then Exit;
  F := TJSONObject(FFields.Find(Model)).Find(Field);
  if not (F is TJSONObject) then Exit;
  Sel := TJSONObject(F).Find('selection');
  if Sel is TJSONArray then
    for I := 0 to TJSONArray(Sel).Count - 1 do
      if (TJSONArray(Sel).Items[I] is TJSONArray) and
        (TJSONArray(TJSONArray(Sel).Items[I]).Items[0].AsString = Value) then
        Exit(True);
end;

function TOdooClient.SearchRead(const Model: string; Domain: TJSONArray;
  const Wanted: array of string; Limit: Integer;
  const Order: string): TJSONArray;
var
  Fields, Args: TJSONArray;
  K: TJSONObject;
  R: TJSONData;
  F: string;
begin
  try
    LoadFields(Model);
  except
    Domain.Free;
    raise;
  end;
  Fields := TJSONArray.Create;
  for F in Wanted do
    if Has(Model, F) then Fields.Add(F);
  Args := TJSONArray.Create;
  Args.Add(Domain);
  K := TJSONObject.Create;
  K.Add('fields', Fields);
  if Limit > 0 then K.Add('limit', Limit);
  if Order <> '' then K.Add('order', Order);
  R := Kw(Model, 'search_read', Args, K);
  if R is TJSONArray then Result := TJSONArray(R)
  else
  begin
    R.Free;
    Result := TJSONArray.Create;
  end;
end;

{ El id del registro con esa referencia (0 si no hay), archivados incluidos. }
function TOdooClient.FindRef(const Model, Field, Ref: string): Integer;
var
  Args: TJSONArray;
  K: TJSONObject;
  R: TJSONData;
begin
  Result := 0;
  Args := TJSONArray.Create;
  Args.Add(Domain1(Field, '=', TJSONString.Create(Ref)));
  K := TJSONObject.Create(['limit', 1]);
  K.Add('context', TJSONObject.Create(['active_test', False]));
  R := Kw(Model, 'search', Args, K);
  try
    if (R is TJSONArray) and (TJSONArray(R).Count > 0) then
      Result := TJSONArray(R).Items[0].AsInteger;
  finally
    R.Free;
  end;
end;

function TOdooClient.Count(const Model: string; Domain: TJSONArray): Integer;
var
  Args: TJSONArray;
  R: TJSONData;
begin
  Args := TJSONArray.Create;
  Args.Add(Domain);
  R := Kw(Model, 'search_count', Args,
    TJSONObject.Create(['context', TJSONObject.Create(['active_test', False])]));
  try
    Result := R.AsInteger;
  finally
    R.Free;
  end;
end;

// ------------------------------------------------------------ TOdooStore

constructor TOdooStore.Create(const AFileName: string);
var
  F: TFileStream;
  D: TJSONData;
begin
  FileName := AFileName;
  Data := nil;
  if FileExists(FileName) then
  try
    F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      D := GetJSON(F);
    finally
      F.Free;
    end;
    if D is TJSONObject then Data := TJSONObject(D)
    else D.Free;
  except
    // Un archivo estropeado no impide abrir: se aparta y se empieza de cero.
    RenameFile(FileName, FileName + '.bad');
  end;
  if Data = nil then Data := TJSONObject.Create;
end;

destructor TOdooStore.Destroy;
begin
  Data.Free;
  inherited Destroy;
end;

procedure TOdooStore.Save;
var
  F: TFileStream;
  S: string;
begin
  ForceDirectories(ExtractFilePath(FileName));
  S := Data.AsJSON;
  F := TFileStream.Create(FileName + '.tmp', fmCreate);
  try
    if S <> '' then F.WriteBuffer(S[1], Length(S));
  finally
    F.Free;
  end;
  // Se escribe aparte y se cambia de nombre: nunca queda a medias.
  if FileExists(FileName) then DeleteFile(FileName);
  RenameFile(FileName + '.tmp', FileName);
end;

procedure TOdooStore.Clear;
var
  S: TJSONObject;
begin
  S := TJSONObject(Settings.Clone);
  Data.Clear;
  Data.Add('settings', S);
  Save;
end;

function TOdooStore.List(const Key: string): TJSONArray;
begin
  if not (Data.Find(Key) is TJSONArray) then
    Data.Arrays[Key] := TJSONArray.Create;
  Result := Data.Arrays[Key];
end;

function TOdooStore.Settings: TJSONObject;
begin
  if not (Data.Find('settings') is TJSONObject) then
    Data.Objects['settings'] := TJSONObject.Create;
  Result := Data.Objects['settings'];
end;

{ Una referencia única para lo que se crea aquí: DMS-XXXXXXXXXXXX. }
function TOdooStore.NewRef: string;
var
  G: TGUID;
  S: string;
begin
  CreateGUID(G);
  S := GUIDToString(G);
  Result := 'DMS-' + Copy(S, 2, 8) + Copy(S, 11, 4);
end;

function TOdooStore.Find(const Key: string; Id: Integer;
  const Ref: string): TJSONObject;
var
  A: TJSONArray;
  I: Integer;
  O: TJSONObject;
begin
  Result := nil;
  A := List(Key);
  for I := 0 to A.Count - 1 do
  begin
    O := A.Objects[I];
    if ((Id > 0) and (JInt(O, 'id') = Id)) or
      ((Id <= 0) and (Ref <> '') and (JStr(O, 'ref') = Ref)) then
      Exit(O);
  end;
end;

procedure TOdooStore.Queue(const Op, Ref: string; Id: Integer);
var
  A: TJSONArray;
  I: Integer;
  O: TJSONObject;
begin
  A := List('outbox');
  for I := 0 to A.Count - 1 do
  begin
    O := A.Objects[I];
    if (JStr(O, 'op') = Op) and (JStr(O, 'ref') = Ref) and (JInt(O, 'id') = Id) then
    begin
      O.Strings['error'] := '';
      Exit;
    end;
  end;
  A.Add(TJSONObject.Create(['op', Op, 'ref', Ref, 'id', Id, 'at', NowStamp,
    'error', '']));
end;

procedure TOdooStore.AddLog(const Line: string);
var
  A: TJSONArray;
begin
  A := List('log');
  A.Add(FormatDateTime('dd/mm hh:nn:ss', Now) + '  ' + Line);
  while A.Count > 300 do A.Delete(0);
end;

function TOdooStore.AddPartner(const Name, Email, Phone, Street, City,
  Vat: string; Supplier: Boolean): TJSONObject;
begin
  Result := TJSONObject.Create(['id', 0, 'ref', NewRef, 'name', Trim(Name),
    'email', Trim(Email), 'phone', Trim(Phone), 'street', Trim(Street),
    'city', Trim(City), 'vat', Trim(Vat), 'supplier', Supplier, 'pending', True]);
  List('partners').Add(Result);
  Queue('partner_create', JStr(Result, 'ref'), 0);
  Save;
end;

procedure TOdooStore.EditPartner(P: TJSONObject; const Name, Email, Phone,
  Street, City, Vat: string);
begin
  P.Strings['name'] := Trim(Name);
  P.Strings['email'] := Trim(Email);
  P.Strings['phone'] := Trim(Phone);
  P.Strings['street'] := Trim(Street);
  P.Strings['city'] := Trim(City);
  P.Strings['vat'] := Trim(Vat);
  P.Booleans['pending'] := True;
  // Uno que aún no está en Odoo ya espera su «crear»: llevará estos datos.
  if JInt(P, 'id') > 0 then Queue('partner_write', '', JInt(P, 'id'));
  Save;
end;

function TOdooStore.AddOrder(Partner: TJSONObject; Lines: TJSONArray): TJSONObject;
var
  I: Integer;
  Total: Double;
begin
  Total := 0;
  for I := 0 to Lines.Count - 1 do
    Total := Total + JNum(Lines.Objects[I], 'qty') * JNum(Lines.Objects[I], 'price');
  Result := TJSONObject.Create(['id', 0, 'ref', NewRef, 'name', '',
    'partner_id', JInt(Partner, 'id'), 'partner_ref', JStr(Partner, 'ref'),
    'partner', JStr(Partner, 'name'), 'date', NowStamp, 'amount', Total,
    'state', 'draft', 'pending', True]);
  Result.Add('lines', Lines);
  List('orders').Insert(0, Result);
  Queue('order_create', JStr(Result, 'ref'), 0);
  Save;
end;

{ Un producto hecho aquí: en Odoo, un consumible que se vende y se compra,
  con la referencia interna escrita o, si no, la de este equipo (DMS-…),
  que es la que se busca antes de crearlo. }
function TOdooStore.AddProduct(const Name, Code: string; Price,
  Cost: Double): TJSONObject;
var
  R: string;
begin
  R := NewRef;
  Result := TJSONObject.Create(['id', 0, 'ref', R, 'name', Trim(Name),
    'code', Trim(Code), 'price', Price, 'cost', Cost, 'uom', 0, 'categ', '',
    'pending', True]);
  if JStr(Result, 'code') = '' then Result.Strings['code'] := R;
  List('products').Add(Result);
  Queue('product_create', R, 0);
  Save;
end;

{ Una solicitud de presupuesto a un proveedor (purchase.order); en Odoo
  lleva la referencia DMS-… en «origin». }
function TOdooStore.AddPurchase(Partner: TJSONObject; Lines: TJSONArray): TJSONObject;
var
  I: Integer;
  Total: Double;
begin
  Total := 0;
  for I := 0 to Lines.Count - 1 do
    Total := Total + JNum(Lines.Objects[I], 'qty') * JNum(Lines.Objects[I], 'price');
  Result := TJSONObject.Create(['id', 0, 'ref', NewRef, 'name', '',
    'partner_id', JInt(Partner, 'id'), 'partner_ref', JStr(Partner, 'ref'),
    'partner', JStr(Partner, 'name'), 'date', NowStamp, 'amount', Total,
    'state', 'draft', 'pending', True, 'purchase', True, 'want', 0, 'level', 0]);
  Result.Add('lines', Lines);
  List('purchases').Insert(0, Result);
  Queue('purchase_create', JStr(Result, 'ref'), 0);
  Save;
end;

{ Pide un paso de un pedido de venta o de compra: 1 confirmar, 2 facturar y
  3 pagar (Pay: bank o cash). Se apunta aquí y va a la bandeja de salida;
  al sincronizar, Odoo hace los pasos que falten, en orden. Devuelve el
  motivo si no se puede (vacío si se apuntó). }
function TOdooStore.SetStep(O: TJSONObject; Step: Integer; const Pay: string): string;
var
  Cur: Integer;
  Pur: Boolean;
begin
  Result := '';
  if O = nil then Exit(SChooseOrder);
  if JBool(O, 'pos') then Exit(SPosNoSteps);
  if JStr(O, 'state') = 'cancel' then Exit(SIsCancelled);
  Cur := Max(JInt(O, 'want'), OrderLevel(O));
  if Cur >= Step then Exit(Format(SAlreadyStep, [StepLabel(O, Cur)]));
  if (Step = 2) and (Cur < 1) then Exit(SConfirmFirst);
  if (Step = 3) and (Cur < 2) then Exit(SInvoiceFirst);
  Pur := JBool(O, 'purchase');
  O.Integers['want'] := Step;
  if Step = 3 then O.Strings['pay'] := Pay;
  O.Booleans['pending'] := True;
  O.Strings['error'] := '';
  if JInt(O, 'id') = 0 then
  begin
    if Pur then Queue('purchase_create', JStr(O, 'ref'), 0)
    else Queue('order_create', JStr(O, 'ref'), 0);
  end
  else if Pur then Queue('purchase_step', '', JInt(O, 'id'))
  else Queue('order_step', '', JInt(O, 'id'));
  Save;
end;

{ Una venta del punto de venta: un pedido con pos = True que al sincronizar
  se confirma, se entrega y se factura. }
function TOdooStore.AddPos(Partner: TJSONObject; Lines: TJSONArray;
  const Payment: string): TJSONObject;
var
  I: Integer;
  Total: Double;
  L: TJSONObject;
begin
  Total := 0;
  for I := 0 to Lines.Count - 1 do
  begin
    L := Lines.Objects[I];
    Total := Total + JNum(L, 'qty') * JNum(L, 'price') * (1 - JNum(L, 'discount') / 100);
  end;
  Result := TJSONObject.Create(['id', 0, 'ref', NewRef, 'name', '',
    'partner_id', JInt(Partner, 'id'), 'partner_ref', JStr(Partner, 'ref'),
    'partner', JStr(Partner, 'name'), 'date', NowStamp, 'amount', Total,
    'state', 'draft', 'pending', True, 'pos', True, 'payment', Payment,
    'step', 'pending', 'picking', '', 'invoice', '', 'error', '']);
  Result.Add('lines', Lines);
  List('orders').Insert(0, Result);
  Queue('pos_sale', JStr(Result, 'ref'), 0);
  Save;
end;

{ El «Cliente de mostrador»: uno solo, con la referencia DMS-POS (en Odoo se
  busca por ella antes de crearlo). }
function TOdooStore.CounterPartner: TJSONObject;
begin
  Result := Find('partners', 0, 'DMS-POS');
  if Result <> nil then Exit;
  Result := TJSONObject.Create(['id', 0, 'ref', 'DMS-POS', 'name', SCounter,
    'email', '', 'phone', '', 'street', '', 'city', '', 'vat', '',
    'pending', True]);
  List('partners').Add(Result);
  Queue('partner_create', 'DMS-POS', 0);
  Save;
end;

function TOdooStore.Pending: Integer;
begin
  Result := List('outbox').Count;
end;

// ------------------------------------------------------------- TOdooSync

constructor TOdooSync.Create(AClient: TOdooClient; AStore: TOdooStore);
begin
  Client := AClient;
  Store := AStore;
end;

procedure TOdooSync.Log(const Line: string);
begin
  Store.AddLog(Line);
  if Assigned(OnLog) then OnLog(Line);
end;

procedure TOdooSync.Connect;
begin
  Client.Reset;
  Client.Detect;
  Client.Authenticate;
  Log(Format(SConnected, [Client.Version, Client.Db, Client.Uid]));
end;

{ La moneda de la compañía del usuario (símbolo y si va delante o detrás). }
procedure TOdooSync.LoadCurrency;
var
  R: TJSONData;
  Rows: TJSONArray;
  Cid: Integer;
begin
  try
    Rows := Client.SearchRead('res.users', Domain1('id', '=',
      TJSONIntegerNumber.Create(Client.Uid)), ['company_id'], 1, '');
    try
      if Rows.Count = 0 then Exit;
      Cid := M2OId(Rows.Objects[0], 'company_id');
    finally
      Rows.Free;
    end;
    Rows := Client.SearchRead('res.company', Domain1('id', '=',
      TJSONIntegerNumber.Create(Cid)), ['currency_id'], 1, '');
    try
      if Rows.Count = 0 then Exit;
      Cid := M2OId(Rows.Objects[0], 'currency_id');
      Store.Settings.Integers['currency_id'] := Cid;
    finally
      Rows.Free;
    end;
    R := Client.SearchRead('res.currency', Domain1('id', '=',
      TJSONIntegerNumber.Create(Cid)), ['symbol', 'position'], 1, '');
    try
      if TJSONArray(R).Count > 0 then
      begin
        CurSymbol := JStr(TJSONArray(R).Objects[0], 'symbol');
        CurAfter := JStr(TJSONArray(R).Objects[0], 'position') <> 'before';
        Store.Settings.Strings['currency'] := CurSymbol;
        Store.Settings.Booleans['currency_after'] := CurAfter;
      end;
    finally
      R.Free;
    end;
  except
    on E: EOdoo do
      if E.Kind in [oeNetwork, oeSSL] then raise;
  end;
end;

procedure KeepLevel(O, R: TJSONObject; Levels: TJSONObject); forward;
procedure KeepWant(O, Keep: TJSONObject); forward;

procedure TOdooSync.Download;
const
  PosKeys: array[0..7] of string = ('pos', 'payment', 'step', 'picking',
    'invoice', 'error', 'lines', 'nostock');
var
  Rows, Fresh, Old: TJSONArray;
  R, O, Keep, Levels: TJSONObject;
  Dom: TJSONArray;
  I, J: Integer;
  Since: string;
begin
  // Clientes: customer = True hasta la 12; desde la 13, customer_rank > 0
  // (solo los que ya compraron) o los contactos que no son usuarios.
  // Los proveedores también (supplier_rank o, hasta la 12, supplier).
  if Client.Has('res.partner', 'customer_rank') and
    Client.Has('res.partner', 'user_ids') then
    Dom := TJSONArray(GetJSON('["|", "|", ["customer_rank", ">", 0], ' +
      '["supplier_rank", ">", 0], ["user_ids", "=", false]]'))
  else if Client.Has('res.partner', 'customer_rank') then
    Dom := TJSONArray(GetJSON('["|", ["customer_rank", ">", 0], ["supplier_rank", ">", 0]]'))
  else if Client.Has('res.partner', 'supplier') then
    Dom := TJSONArray(GetJSON('["|", ["customer", "=", true], ["supplier", "=", true]]'))
  else if Client.Has('res.partner', 'customer') then
    Dom := Domain1('customer', '=', TJSONBoolean.Create(True))
  else
    Dom := TJSONArray.Create;
  Rows := Client.SearchRead('res.partner', Dom, ['name', 'email', 'phone',
    'mobile', 'street', 'city', 'vat', 'ref', 'is_company', 'supplier',
    'supplier_rank'], 2000, 'name');
  if Rows.Count = 0 then
  begin
    Rows.Free;
    Rows := Client.SearchRead('res.partner', TJSONArray.Create, ['name',
      'email', 'phone', 'mobile', 'street', 'city', 'vat', 'ref'], 500, 'name');
  end;
  Fresh := TJSONArray.Create;
  try
    for I := 0 to Rows.Count - 1 do
    begin
      R := Rows.Objects[I];
      Keep := Store.Find('partners', JInt(R, 'id'), '');
      if (Keep <> nil) and JBool(Keep, 'pending') then
      begin
        Fresh.Add(Keep.Clone); // con cambios sin enviar: manda lo de aquí
        Continue;
      end;
      O := TJSONObject.Create(['id', JInt(R, 'id'), 'name', JStr(R, 'name'),
        'email', JStr(R, 'email'), 'phone', JStr(R, 'phone'),
        'street', JStr(R, 'street'), 'city', JStr(R, 'city'),
        'vat', JStr(R, 'vat'), 'ref', JStr(R, 'ref'), 'pending', False]);
      if JStr(O, 'phone') = '' then O.Strings['phone'] := JStr(R, 'mobile');
      O.Booleans['supplier'] := (JInt(R, 'supplier_rank') > 0) or JBool(R, 'supplier');
      O.Booleans['supplier_odoo'] := JBool(O, 'supplier');
      Fresh.Add(O);
    end;
    Old := Store.List('partners');
    for I := 0 to Old.Count - 1 do
      if JInt(Old.Objects[I], 'id') = 0 then Fresh.Add(Old.Objects[I].Clone);
  finally
    Rows.Free;
  end;
  Store.Data.Arrays['partners'] := Fresh;

  // Productos que se venden; el stock solo con Inventario.
  if Client.Has('product.product', 'sale_ok') then
    Dom := Domain1('sale_ok', '=', TJSONBoolean.Create(True))
  else
    Dom := TJSONArray.Create;
  Rows := Client.SearchRead('product.product', Dom, ['name', 'default_code',
    'lst_price', 'list_price', 'standard_price', 'qty_available', 'uom_id',
    'categ_id'], 2000, 'name');
  Fresh := TJSONArray.Create;
  try
    for I := 0 to Rows.Count - 1 do
    begin
      R := Rows.Objects[I];
      O := TJSONObject.Create(['id', JInt(R, 'id'), 'name', JStr(R, 'name'),
        'code', JStr(R, 'default_code'), 'uom', M2OId(R, 'uom_id'),
        'categ', M2OName(R, 'categ_id'), 'cost', JNum(R, 'standard_price')]);
      // «All / Saleable / Office» → «Office»
      while Pos(' / ', JStr(O, 'categ')) > 0 do
        O.Strings['categ'] := Copy(JStr(O, 'categ'), Pos(' / ', JStr(O, 'categ')) + 3, MaxInt);
      if R.Find('lst_price') <> nil then O.Floats['price'] := JNum(R, 'lst_price')
      else O.Floats['price'] := JNum(R, 'list_price');
      if R.Find('qty_available') <> nil then O.Floats['qty'] := JNum(R, 'qty_available');
      Fresh.Add(O);
    end;
    // Los hechos aquí que aún no están en Odoo.
    Old := Store.List('products');
    for I := 0 to Old.Count - 1 do
      if JInt(Old.Objects[I], 'id') = 0 then Fresh.Add(Old.Objects[I].Clone);
  finally
    Rows.Free;
  end;
  Store.Data.Arrays['products'] := Fresh;

  // Pedidos de los últimos doce meses (y los de aquí que aún no se enviaron).
  Fresh := TJSONArray.Create;
  Old := Store.List('orders');
  for I := 0 to Old.Count - 1 do
    if JInt(Old.Objects[I], 'id') = 0 then Fresh.Add(Old.Objects[I].Clone);
  SaleMissing := not Client.Exists('sale.order');
  if SaleMissing then Log(SSaleMissing)
  else
  begin
    Since := FormatDateTime('yyyy-mm', IncMonth(Now, -11)) + '-01 00:00:00';
    Rows := Client.SearchRead('sale.order', Domain1('date_order', '>=',
      TJSONString.Create(Since)), ['name', 'partner_id', 'date_order',
      'amount_total', 'state', 'client_order_ref', 'invoice_ids'], 3000, 'date_order desc');
    Levels := nil;
    try
      Levels := InvoiceLevels(Rows);
      for I := 0 to Rows.Count - 1 do
      begin
        R := Rows.Objects[I];
        O := TJSONObject.Create(['id', JInt(R, 'id'), 'name', JStr(R, 'name'),
          'partner_id', M2OId(R, 'partner_id'), 'partner', M2OName(R, 'partner_id'),
          'date', JStr(R, 'date_order'), 'amount', JNum(R, 'amount_total'),
          'state', JStr(R, 'state'), 'ref', JStr(R, 'client_order_ref'),
          'pending', False]);
        KeepLevel(O, R, Levels);
        // Lo del punto de venta (pago, pasos, entrega, factura y líneas) solo
        // está aquí: se conserva.
        Keep := Store.Find('orders', JInt(R, 'id'), '');
        if (Keep <> nil) and JBool(Keep, 'pos') then
          for J := 0 to High(PosKeys) do
            if Keep.Find(PosKeys[J]) <> nil then
              O.Elements[PosKeys[J]] := Keep.Elements[PosKeys[J]].Clone;
        KeepWant(O, Keep);
        Fresh.Add(O);
      end;
    finally
      Rows.Free;
      Levels.Free;
    end;
  end;
  Store.Data.Arrays['orders'] := Fresh;

  // Compras de los últimos doce meses (y las de aquí que aún no se enviaron).
  Fresh := TJSONArray.Create;
  Old := Store.List('purchases');
  for I := 0 to Old.Count - 1 do
    if JInt(Old.Objects[I], 'id') = 0 then Fresh.Add(Old.Objects[I].Clone);
  Store.Data.Booleans['purchase'] := Client.Exists('purchase.order');
  if JBool(Store.Data, 'purchase') then
  begin
    Since := FormatDateTime('yyyy-mm', IncMonth(Now, -11)) + '-01 00:00:00';
    Rows := Client.SearchRead('purchase.order', Domain1('date_order', '>=',
      TJSONString.Create(Since)), ['name', 'partner_id', 'date_order',
      'amount_total', 'state', 'origin', 'invoice_ids'], 3000, 'date_order desc');
    Levels := nil;
    try
      Levels := InvoiceLevels(Rows);
      for I := 0 to Rows.Count - 1 do
      begin
        R := Rows.Objects[I];
        O := TJSONObject.Create(['id', JInt(R, 'id'), 'name', JStr(R, 'name'),
          'partner_id', M2OId(R, 'partner_id'), 'partner', M2OName(R, 'partner_id'),
          'date', JStr(R, 'date_order'), 'amount', JNum(R, 'amount_total'),
          'state', JStr(R, 'state'), 'ref', JStr(R, 'origin'), 'purchase', True,
          'pending', False]);
        KeepLevel(O, R, Levels);
        KeepWant(O, Store.Find('purchases', JInt(R, 'id'), ''));
        Fresh.Add(O);
      end;
    finally
      Rows.Free;
      Levels.Free;
    end;
  end;
  Store.Data.Arrays['purchases'] := Fresh;

  // BIM 2.0, si está instalado: obras, presupuestos y unidades.
  BimReady := Client.Exists('bim.budget') and Client.Exists('bim.project') and
    Client.Has('bim.concepts', 'id_import');
  Store.Data.Booleans['bim'] := BimReady;
  if BimReady then DownloadBim;

  LoadCurrency;
  Store.Data.Strings['last_sync'] := NowStamp;
  Store.Data.Objects['server'] := TJSONObject.Create(['url', Client.Base,
    'db', Client.Db, 'version', Client.Version, 'major', Client.Major]);
  Store.Save;
  Log(Format(SDownloaded, [Store.List('partners').Count,
    Store.List('products').Count, Store.List('orders').Count]));
end;

{ Las facturas de unos pedidos (los que trae search_read con invoice_ids),
  leídas de una vez: {"id": {"state", "paid", "name"}}. Hasta la 12,
  account.invoice (open / paid); desde la 13, account.move (posted y
  payment_state paid o in_payment; invoice_payment_state en la 13). }
function TOdooSync.InvoiceLevels(Rows: TJSONArray): TJSONObject;
var
  All, Inv: TJSONArray;
  I, J: Integer;
  D: TJSONData;
  R: TJSONObject;
  InvModel, St, Ps: string;
begin
  Result := TJSONObject.Create;
  All := TJSONArray.Create;
  for I := 0 to Rows.Count - 1 do
  begin
    D := Rows.Objects[I].Find('invoice_ids');
    if D is TJSONArray then
      for J := 0 to TJSONArray(D).Count - 1 do All.Add(TJSONArray(D).Items[J].AsInteger);
  end;
  if All.Count = 0 then
  begin
    All.Free;
    Exit;
  end;
  if Client.Major >= 13 then InvModel := 'account.move' else InvModel := 'account.invoice';
  Inv := Client.SearchRead(InvModel, Domain1('id', 'in', All), ['name', 'number',
    'state', 'payment_state', 'invoice_payment_state'], 0, '');
  try
    for I := 0 to Inv.Count - 1 do
    begin
      R := Inv.Objects[I];
      St := JStr(R, 'state');
      Ps := JStr(R, 'payment_state');
      if Ps = '' then Ps := JStr(R, 'invoice_payment_state');
      if (St = 'open') or (St = 'paid') then St := 'posted';
      Result.Add(IntToStr(JInt(R, 'id')), TJSONObject.Create(['state', St,
        'paid', (JStr(R, 'state') = 'paid') or (Ps = 'paid') or (Ps = 'in_payment'),
        'name', JStr(R, 'name') + JStr(R, 'number')]));
    end;
  finally
    Inv.Free;
  end;
end;

{ El paso al que llegó en Odoo un pedido recién leído (O, con su state) con
  sus facturas (las de Levels): facturado si todas las vivas están
  publicadas; pagado si además están pagadas. }
procedure KeepLevel(O, R: TJSONObject; Levels: TJSONObject);
var
  Ids: TJSONData;
  I, Live, Posted, Paid: Integer;
  F: TJSONObject;
  Names: string;
begin
  O.Integers['level'] := 0;
  if Confirmed(O) then O.Integers['level'] := 1;
  Ids := R.Find('invoice_ids');
  Live := 0; Posted := 0; Paid := 0; Names := '';
  if (Ids is TJSONArray) and (Levels <> nil) then
    for I := 0 to TJSONArray(Ids).Count - 1 do
      if Levels.Find(IntToStr(TJSONArray(Ids).Items[I].AsInteger)) is TJSONObject then
      begin
        F := Levels.Objects[IntToStr(TJSONArray(Ids).Items[I].AsInteger)];
        if JStr(F, 'state') = 'cancel' then Continue;
        Inc(Live);
        if JStr(F, 'state') = 'posted' then
        begin
          Inc(Posted);
          if Names <> '' then Names := Names + ', ';
          Names := Names + JStr(F, 'name');
        end;
        if JBool(F, 'paid') then Inc(Paid);
      end;
  if (Live > 0) and (Posted = Live) and Confirmed(O) then
  begin
    O.Integers['level'] := 2;
    if Paid = Live then O.Integers['level'] := 3;
  end;
  O.Strings['invoice'] := Names;
end;

{ Un paso pedido aquí que aún no llegó a Odoo se conserva al descargar. }
procedure KeepWant(O, Keep: TJSONObject);
begin
  O.Integers['want'] := JInt(O, 'level');
  if Keep = nil then Exit;
  if JInt(Keep, 'want') > JInt(O, 'level') then
  begin
    O.Integers['want'] := JInt(Keep, 'want');
    O.Strings['pay'] := JStr(Keep, 'pay');
    O.Strings['error'] := JStr(Keep, 'error');
    O.Booleans['pending'] := True;
  end;
end;

function TOdooSync.PartnerVals(P: TJSONObject; Creating: Boolean): TJSONObject;
const
  Fields: array[0..4] of string = ('email', 'phone', 'street', 'city', 'vat');
var
  I: Integer;
begin
  Result := TJSONObject.Create(['name', JStr(P, 'name')]);
  for I := 0 to High(Fields) do
    if JStr(P, Fields[I]) <> '' then Result.Add(Fields[I], JStr(P, Fields[I]))
    else if not Creating then Result.Add(Fields[I], False);
  if Creating then
  begin
    Result.Add('ref', JStr(P, 'ref'));
    if JBool(P, 'supplier') then
    begin
      // Un proveedor: supplier_rank (13+) o supplier (hasta la 12).
      if Client.Has('res.partner', 'supplier_rank') then Result.Add('supplier_rank', 1)
      else if Client.Has('res.partner', 'supplier') then
      begin
        Result.Add('supplier', True);
        if Client.Has('res.partner', 'customer') then Result.Add('customer', False);
      end;
    end
    else if Client.Has('res.partner', 'customer_rank') then Result.Add('customer_rank', 1)
    else if Client.Has('res.partner', 'customer') then Result.Add('customer', True);
  end
  else if JBool(P, 'supplier') and not JBool(P, 'supplier_odoo') then
  begin
    if Client.Has('res.partner', 'supplier_rank') then Result.Add('supplier_rank', 1)
    else if Client.Has('res.partner', 'supplier') then Result.Add('supplier', True);
  end;
end;

procedure TOdooSync.PushPartner(Op: TJSONObject; AWrite: Boolean);
var
  P, O: TJSONObject;
  Args, IdList: TJSONArray;
  R: TJSONData;
  Id, I: Integer;
  Ref: string;
begin
  P := Store.Find('partners', JInt(Op, 'id'), JStr(Op, 'ref'));
  if P = nil then Exit;
  if AWrite then
  begin
    IdList := TJSONArray.Create([JInt(P, 'id')]);
    Args := TJSONArray.Create;
    Args.Add(IdList);
    Args.Add(PartnerVals(P, False));
    Client.Kw('res.partner', 'write', Args).Free;
    P.Booleans['pending'] := False;
    P.Booleans['supplier_odoo'] := JBool(P, 'supplier');
    Log(Format(SSentEdit, [JStr(P, 'name')]));
    Exit;
  end;
  // Antes de crear se busca la referencia: si el envío anterior llegó a
  // Odoo pero la respuesta no volvió, no se duplica.
  Ref := JStr(P, 'ref');
  Id := Client.FindRef('res.partner', 'ref', Ref);
  if Id > 0 then Log(Format(SFoundPartner, [JStr(P, 'name'), Id]))
  else
  begin
    Args := TJSONArray.Create;
    Args.Add(PartnerVals(P, True));
    R := Client.Kw('res.partner', 'create', Args);
    try
      if R is TJSONArray then Id := TJSONArray(R).Items[0].AsInteger
      else Id := R.AsInteger;
    finally
      R.Free;
    end;
    Log(Format(SSentPartner, [JStr(P, 'name'), Id]));
  end;
  P.Integers['id'] := Id;
  P.Booleans['pending'] := False;
  P.Booleans['supplier_odoo'] := JBool(P, 'supplier');
  // Los presupuestos y compras que esperaban a este contacto ya tienen su id.
  for I := 0 to Store.List('orders').Count - 1 do
  begin
    O := Store.List('orders').Objects[I];
    if (JInt(O, 'partner_id') = 0) and (JStr(O, 'partner_ref') = Ref) then
      O.Integers['partner_id'] := Id;
  end;
  for I := 0 to Store.List('purchases').Count - 1 do
  begin
    O := Store.List('purchases').Objects[I];
    if (JInt(O, 'partner_id') = 0) and (JStr(O, 'partner_ref') = Ref) then
      O.Integers['partner_id'] := Id;
  end;
end;

{ Un producto hecho aquí: antes de crearlo se busca su referencia interna
  (si un envío anterior llegó, no se duplica). Consumible (en la 8–17
  «consu»; en la 18+ también, sin control de stock), que se vende y se
  compra, y se factura por lo pedido (invoice_policy y purchase_method):
  así se puede facturar sin esperar a la entrega o la recepción. }
procedure TOdooSync.PushProduct(Op: TJSONObject);
var
  P, Vals, O, L: TJSONObject;
  Args, Rows: TJSONArray;
  R: TJSONData;
  Id, Uom, I, J, K: Integer;
  Ref: string;
const
  Keys: array[0..1] of string = ('orders', 'purchases');
begin
  P := Store.Find('products', 0, JStr(Op, 'ref'));
  if P = nil then Exit;
  Ref := JStr(P, 'ref');
  Id := Client.FindRef('product.product', 'default_code', JStr(P, 'code'));
  if Id > 0 then Log(Format(SFoundProduct, [JStr(P, 'name'), Id]))
  else
  begin
    Vals := TJSONObject.Create(['name', JStr(P, 'name'), 'default_code', JStr(P, 'code'),
      'list_price', JNum(P, 'price'), 'standard_price', JNum(P, 'cost')]);
    if Client.Has('product.product', 'sale_ok') then Vals.Add('sale_ok', True);
    if Client.Has('product.product', 'purchase_ok') then Vals.Add('purchase_ok', True);
    if Client.Selection('product.product', 'type', 'consu') then Vals.Add('type', 'consu');
    if Client.Selection('product.product', 'invoice_policy', 'order') then
      Vals.Add('invoice_policy', 'order');
    if Client.Selection('product.product', 'purchase_method', 'purchase') then
      Vals.Add('purchase_method', 'purchase');
    Args := TJSONArray.Create;
    Args.Add(Vals);
    R := Client.Kw('product.product', 'create', Args);
    try
      if R is TJSONArray then Id := TJSONArray(R).Items[0].AsInteger
      else Id := R.AsInteger;
    finally
      R.Free;
    end;
    Log(Format(SSentProduct, [JStr(P, 'name'), Id]));
  end;
  Uom := 0;
  Rows := Client.SearchRead('product.product', Domain1('id', '=',
    TJSONIntegerNumber.Create(Id)), ['uom_id'], 1, '');
  try
    if Rows.Count > 0 then Uom := M2OId(Rows.Objects[0], 'uom_id');
  finally
    Rows.Free;
  end;
  P.Integers['id'] := Id;
  P.Integers['uom'] := Uom;
  P.Booleans['pending'] := False;
  // Las líneas que esperaban a este producto ya tienen su id.
  for K := 0 to High(Keys) do
    for I := 0 to Store.List(Keys[K]).Count - 1 do
    begin
      O := Store.List(Keys[K]).Objects[I];
      if not (O.Find('lines') is TJSONArray) then Continue;
      for J := 0 to O.Arrays['lines'].Count - 1 do
      begin
        L := O.Arrays['lines'].Objects[J];
        if (JInt(L, 'product_id') = 0) and (JStr(L, 'product_ref') = Ref) then
        begin
          L.Integers['product_id'] := Id;
          if JInt(L, 'uom') = 0 then L.Integers['uom'] := Uom;
        end;
      end;
    end;
end;

{ El contacto del pedido: su id o, si se creó aquí, el que recibió al
  enviarse (falla si aún no está en Odoo). }
function TOdooSync.PartnerOf(O: TJSONObject): Integer;
var
  P: TJSONObject;
begin
  Result := JInt(O, 'partner_id');
  if Result = 0 then
  begin
    P := Store.Find('partners', 0, JStr(O, 'partner_ref'));
    if P <> nil then Result := JInt(P, 'id');
  end;
  if Result = 0 then raise EOdoo.Make(oeServer, SPartnerNotSent);
end;

{ Las líneas de un pedido para create: [(0, 0, {…})]. Los productos hechos
  aquí deben estar ya en Odoo (van antes en la bandeja de salida). }
function TOdooSync.LinesVals(O: TJSONObject; const Model, QtyField: string): TJSONArray;
var
  L, LV, P: TJSONObject;
  Cmd: TJSONArray;
  I, Pid: Integer;
  UomField: string;
begin
  if Client.Has(Model, 'product_uom') then UomField := 'product_uom'
  else if Client.Has(Model, 'product_uom_id') then UomField := 'product_uom_id'
  else UomField := '';
  Result := TJSONArray.Create;
  try
    for I := 0 to O.Arrays['lines'].Count - 1 do
    begin
      L := O.Arrays['lines'].Objects[I];
      Pid := JInt(L, 'product_id');
      if (Pid = 0) and (JStr(L, 'product_ref') <> '') then
      begin
        P := Store.Find('products', 0, JStr(L, 'product_ref'));
        if P <> nil then Pid := JInt(P, 'id');
        if (P <> nil) and (JInt(L, 'uom') = 0) then L.Integers['uom'] := JInt(P, 'uom');
        if Pid = 0 then raise EOdoo.Make(oeServer, Format(SProductNotSent, [JStr(L, 'name')]));
        L.Integers['product_id'] := Pid;
      end;
      LV := TJSONObject.Create(['product_id', Pid, 'name', JStr(L, 'name'),
        QtyField, JNum(L, 'qty'), 'price_unit', JNum(L, 'price')]);
      if JNum(L, 'discount') <> 0 then LV.Add('discount', JNum(L, 'discount'));
      if (UomField <> '') and (JInt(L, 'uom') > 0) then LV.Add(UomField, JInt(L, 'uom'));
      if (Model = 'purchase.order.line') and Client.Has(Model, 'date_planned') then
        LV.Add('date_planned', NowStamp);
      Cmd := TJSONArray.Create([0, 0]);
      Cmd.Add(LV);
      Result.Add(Cmd);
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ Crea en Odoo el pedido de O (o lo encuentra por su referencia DMS-…, si
  un envío anterior llegó) y pone en O su id, nombre, estado e importe. }
function TOdooSync.EnsureOrder(O: TJSONObject): Integer;
var
  Vals: TJSONObject;
  Args: TJSONArray;
  R: TJSONData;
  PartnerId, Id, I: Integer;
  Ref: string;
begin
  if not Client.Exists('sale.order') then raise EOdoo.Make(oeServer, SSaleMissing);
  PartnerId := PartnerOf(O);
  Ref := JStr(O, 'ref');
  Id := Client.FindRef('sale.order', 'client_order_ref', Ref);
  if Id > 0 then Log(Format(SFoundOrder, [Ref]))
  else
  begin
    Vals := TJSONObject.Create(['partner_id', PartnerId, 'client_order_ref', Ref]);
    try
      if Client.Has('sale.order', 'origin') then
        if JBool(O, 'pos') then
        begin
          // Con Format: un literal con «·» unido a otro iría a fpjson como
          // UnicodeString y llegaría a Odoo mal codificado («TPV Â· …»).
          if JStr(O, 'payment') = 'card' then Vals.Add('origin', Format('TPV · %s', [SCard]))
          else Vals.Add('origin', Format('TPV · %s', [SCash]));
        end
        else Vals.Add('origin', 'DMarlon Studio');
      // En la 8, create no rellena direcciones ni tarifa: lo hace el onchange.
      if Client.Major <= 8 then
      try
        Args := TJSONArray.Create;
        Args.Add(TJSONArray.Create);
        Args.Add(PartnerId);
        R := Client.Kw('sale.order', 'onchange_partner_id', Args);
        try
          if (R is TJSONObject) and (TJSONObject(R).Find('value') is TJSONObject) then
            with TJSONObject(R).Objects['value'] do
              for I := 0 to Count - 1 do
                if Vals.Find(Names[I]) = nil then Vals.Add(Names[I], Items[I].Clone);
        finally
          R.Free;
        end;
      except
        on E: EOdoo do
          if E.Kind in [oeNetwork, oeSSL] then raise;
      end;
      Vals.Add('order_line', LinesVals(O, 'sale.order.line', 'product_uom_qty'));
    except
      Vals.Free;
      raise;
    end;
    Args := TJSONArray.Create;
    Args.Add(Vals);
    R := Client.Kw('sale.order', 'create', Args);
    try
      if R is TJSONArray then Id := TJSONArray(R).Items[0].AsInteger
      else Id := R.AsInteger;
    finally
      R.Free;
    end;
  end;
  O.Integers['id'] := Id;
  O.Integers['partner_id'] := PartnerId;
  if JInt(O, 'want') = 0 then O.Booleans['pending'] := False;
  RefreshOrder(O, Id);
  Result := Id;
end;

{ El nombre, estado, total y fecha del pedido, como están en Odoo. }
procedure TOdooSync.RefreshOrder(O: TJSONObject; Id: Integer);
var
  Rows: TJSONArray;
  Back: TJSONObject;
begin
  Rows := Client.SearchRead('sale.order', Domain1('id', '=',
    TJSONIntegerNumber.Create(Id)), ['name', 'state', 'amount_total',
    'date_order'], 1, '');
  try
    if Rows.Count > 0 then
    begin
      Back := Rows.Objects[0];
      O.Strings['name'] := JStr(Back, 'name');
      O.Strings['state'] := JStr(Back, 'state');
      O.Floats['amount'] := JNum(Back, 'amount_total');
      O.Strings['date'] := JStr(Back, 'date_order');
    end;
  finally
    Rows.Free;
  end;
end;

{ Un presupuesto hecho aquí (order_create) o un paso pedido aquí de un
  pedido de Odoo (order_step): se crea si falta y se lleva hasta el paso
  pedido. }
procedure TOdooSync.PushOrder(Op: TJSONObject);
var
  O: TJSONObject;
  Id: Integer;
begin
  O := Store.Find('orders', JInt(Op, 'id'), JStr(Op, 'ref'));
  if O = nil then Exit;
  try
    Id := JInt(O, 'id');
    if Id = 0 then
    begin
      Id := EnsureOrder(O);
      Log(Format(SSentOrder, [JStr(O, 'name'), JStr(O, 'partner')]));
      Store.Save;
    end;
    Advance(O, Id);
  except
    on E: EOdoo do
    begin
      if E.Kind = oeServer then O.Strings['error'] := E.Message;
      raise;
    end;
  end;
end;

{ Lleva un pedido de venta o de compra en Odoo hasta el paso que se pidió
  aquí (want): 1 confirmado, 2 facturado y 3 pagado. Cada paso mira antes
  cómo está en Odoo: un envío cortado sigue donde se quedó, sin repetir. }
procedure TOdooSync.Advance(O: TJSONObject; Id: Integer);
var
  Want: Integer;
  Pur: Boolean;
  Names, Model: string;
begin
  Want := JInt(O, 'want');
  Pur := JBool(O, 'purchase');
  if Pur then Model := 'purchase.order' else Model := 'sale.order';
  if Want >= 1 then
  begin
    if Pur then
    begin
      ConfirmPurchase(Id);
      RefreshPurchase(O, Id);
      Log(Format(SPurConfirmed, [JStr(O, 'name')]));
    end
    else
    begin
      Confirm(Id);
      RefreshOrder(O, Id);
      Log(Format(SPosConfirmed, [JStr(O, 'name')]));
    end;
    O.Integers['level'] := Max(1, JInt(O, 'level'));
    Store.Save;
  end;
  if Want >= 2 then
  begin
    if Pur then
    begin
      Names := Bill(Id);
      Log(Format(SBilledLog, [Names]));
    end
    else
    begin
      Names := Invoice(Id);
      Log(Format(SPosInvoicedLog, [Names]));
    end;
    O.Strings['invoice'] := Names;
    O.Integers['level'] := Max(2, JInt(O, 'level'));
    Store.Save;
  end;
  if Want >= 3 then
  begin
    Names := PayInvoices(Model, Id, JStr(O, 'pay'));
    if JStr(O, 'pay') = 'cash' then Log(Format(SPaidLog, [Names, SCash]))
    else Log(Format(SPaidLog, [Names, SBank]));
    O.Integers['level'] := 3;
  end;
  O.Booleans['pending'] := False;
  O.Strings['error'] := '';
  if Pur then RefreshPurchase(O, Id) else RefreshOrder(O, Id);
  Store.Save;
end;

{ Una compra hecha aquí: se busca por su referencia (en «origin») antes de
  crearla. }
function TOdooSync.EnsurePurchase(O: TJSONObject): Integer;
var
  Vals: TJSONObject;
  Args: TJSONArray;
  R: TJSONData;
  PartnerId, Id: Integer;
  Ref: string;
begin
  if not Client.Exists('purchase.order') then raise EOdoo.Make(oeServer, SPurchaseMissing);
  PartnerId := PartnerOf(O);
  Ref := JStr(O, 'ref');
  Id := Client.FindRef('purchase.order', 'origin', Ref);
  if Id > 0 then Log(Format(SFoundPurchase, [Ref]))
  else
  begin
    Vals := TJSONObject.Create(['partner_id', PartnerId, 'origin', Ref]);
    try
      Vals.Add('order_line', LinesVals(O, 'purchase.order.line', 'product_qty'));
    except
      Vals.Free;
      raise;
    end;
    Args := TJSONArray.Create;
    Args.Add(Vals);
    R := Client.Kw('purchase.order', 'create', Args);
    try
      if R is TJSONArray then Id := TJSONArray(R).Items[0].AsInteger
      else Id := R.AsInteger;
    finally
      R.Free;
    end;
  end;
  O.Integers['id'] := Id;
  O.Integers['partner_id'] := PartnerId;
  if JInt(O, 'want') = 0 then O.Booleans['pending'] := False;
  RefreshPurchase(O, Id);
  Result := Id;
end;

procedure TOdooSync.RefreshPurchase(O: TJSONObject; Id: Integer);
var
  Rows: TJSONArray;
  Back: TJSONObject;
begin
  Rows := Client.SearchRead('purchase.order', Domain1('id', '=',
    TJSONIntegerNumber.Create(Id)), ['name', 'state', 'amount_total',
    'date_order'], 1, '');
  try
    if Rows.Count > 0 then
    begin
      Back := Rows.Objects[0];
      O.Strings['name'] := JStr(Back, 'name');
      O.Strings['state'] := JStr(Back, 'state');
      O.Floats['amount'] := JNum(Back, 'amount_total');
      O.Strings['date'] := JStr(Back, 'date_order');
    end;
  finally
    Rows.Free;
  end;
end;

procedure TOdooSync.PushPurchase(Op: TJSONObject);
var
  O: TJSONObject;
  Id: Integer;
begin
  O := Store.Find('purchases', JInt(Op, 'id'), JStr(Op, 'ref'));
  if O = nil then Exit;
  try
    Id := JInt(O, 'id');
    if Id = 0 then
    begin
      Id := EnsurePurchase(O);
      Log(Format(SSentPurchase, [JStr(O, 'name'), JStr(O, 'partner')]));
      Store.Save;
    end;
    Advance(O, Id);
  except
    on E: EOdoo do
    begin
      if E.Kind = oeServer then O.Strings['error'] := E.Message;
      raise;
    end;
  end;
end;

{ Confirmar la compra: button_confirm (9+; en la 8, la señal
  purchase_confirm); si la compañía pide aprobación, button_approve. }
procedure TOdooSync.ConfirmPurchase(Id: Integer);
var
  Rows, Args: TJSONArray;
  St: string;

  function State: string;
  begin
    Rows := Client.SearchRead('purchase.order', Domain1('id', '=',
      TJSONIntegerNumber.Create(Id)), ['state'], 1, '');
    try
      Result := '';
      if Rows.Count > 0 then Result := JStr(Rows.Objects[0], 'state');
    finally
      Rows.Free;
    end;
  end;

begin
  St := State;
  if (St = 'draft') or (St = 'sent') then
  begin
    Args := TJSONArray.Create;
    Args.Add(TJSONArray.Create([Id]));
    if Client.Major <= 8 then
    begin
      Args.Add('purchase_confirm');
      Client.Kw('purchase.order', 'signal_workflow', Args).Free;
    end
    else Client.Kw('purchase.order', 'button_confirm', Args).Free;
    St := State;
  end;
  if St = 'to approve' then
  begin
    Args := TJSONArray.Create;
    Args.Add(TJSONArray.Create([Id]));
    Client.Kw('purchase.order', 'button_approve', Args).Free;
  end;
end;

{ La factura de proveedor (14+): purchase.order.action_create_invoice. Si
  no hay nada que facturar (productos que se facturan por lo recibido), se
  valida antes la recepción. La fecha de factura es obligatoria para
  publicarla: hoy, si no tiene. }
function TOdooSync.Bill(Id: Integer): string;
var
  Invs, Lines, Args, Found: TJSONArray;
  I, Live: Integer;
  ToBill: Double;
  Names: string;

  function LoadBills: TJSONArray;
  begin
    Found := Ids('purchase.order', Id, 'invoice_ids');
    Result := Client.SearchRead('account.move', Domain1('id', 'in', Found),
      ['state', 'name', 'invoice_date'], 0, 'id');
  end;

begin
  Result := '';
  if Client.Major < 14 then raise EOdoo.Make(oeServer, SBillOld);
  Invs := LoadBills;
  try
    Live := 0;
    for I := 0 to Invs.Count - 1 do
      if JStr(Invs.Objects[I], 'state') <> 'cancel' then Inc(Live);
    if Live = 0 then
    begin
      ToBill := 0;
      Lines := Client.SearchRead('purchase.order.line', Domain1('order_id', '=',
        TJSONIntegerNumber.Create(Id)), ['qty_to_invoice'], 0, '');
      try
        for I := 0 to Lines.Count - 1 do
          ToBill := ToBill + JNum(Lines.Objects[I], 'qty_to_invoice');
      finally
        Lines.Free;
      end;
      if (ToBill <= 0) and Client.Has('purchase.order', 'picking_ids') then
      begin
        Names := Deliver('purchase.order', Id);
        if Names <> '' then Log(Format(SReceivedLog, [Names]));
      end;
      Args := TJSONArray.Create;
      Args.Add(TJSONArray.Create([Id]));
      Client.Kw('purchase.order', 'action_create_invoice', Args).Free;
      Invs.Free;
      Invs := LoadBills;
      if Invs.Count = 0 then
        raise EOdoo.Make(oeServer, Format(SNoBill, [IntToStr(Id)]));
    end;
    for I := 0 to Invs.Count - 1 do
    begin
      if JStr(Invs.Objects[I], 'state') <> 'draft' then Continue;
      if JStr(Invs.Objects[I], 'invoice_date') = '' then
      begin
        Args := TJSONArray.Create;
        Args.Add(TJSONArray.Create([JInt(Invs.Objects[I], 'id')]));
        Args.Add(TJSONObject.Create(['invoice_date', FormatDateTime('yyyy-mm-dd', Now)]));
        Client.Kw('account.move', 'write', Args).Free;
      end;
      Args := TJSONArray.Create;
      Args.Add(TJSONArray.Create([JInt(Invs.Objects[I], 'id')]));
      Client.Kw('account.move', 'action_post', Args).Free;
    end;
    Invs.Free;
    Invs := LoadBills;
    for I := 0 to Invs.Count - 1 do
    begin
      if JStr(Invs.Objects[I], 'state') = 'cancel' then Continue;
      if JStr(Invs.Objects[I], 'state') <> 'posted' then
        raise EOdoo.Make(oeServer, Format(SNoBill, [IntToStr(Id)]));
      if Result <> '' then Result := Result + ', ';
      Result := Result + JStr(Invs.Objects[I], 'name');
    end;
  finally
    Invs.Free;
  end;
end;

{ El primer diario de ese tipo (bank o cash); 0 si no hay. }
function TOdooSync.JournalId(const Kind: string): Integer;
var
  Rows: TJSONArray;
begin
  Result := 0;
  Rows := Client.SearchRead('account.journal', Domain1('type', '=',
    TJSONString.Create(Kind)), ['name'], 1, 'sequence, id');
  try
    if Rows.Count > 0 then Result := JInt(Rows.Objects[0], 'id');
  finally
    Rows.Free;
  end;
end;

{ Paga las facturas publicadas de un pedido que aún no lo estén, en el
  diario de banco o de caja. Desde la 13, el asistente del botón «Registrar
  pago» (account.payment.register: action_create_payments en la 14+,
  create_payments en la 13); de la 9 a la 12, un account.payment con la
  factura y post. Pagada es paid o in_payment (pendiente de conciliar con
  el banco). }
function TOdooSync.PayInvoices(const Model: string; Id: Integer;
  const Kind: string): string;
var
  Invs, Args, Found, M: TJSONArray;
  Inv, Ctx, Vals, K: TJSONObject;
  R: TJSONData;
  I, J, W, Method: Integer;
  PayField, PType, Typ: string;

  function Load: TJSONArray;
  begin
    Found := Ids(Model, Id, 'invoice_ids');
    if Client.Major >= 13 then
      Result := Client.SearchRead('account.move', Domain1('id', 'in', Found),
        ['name', 'state', PayField, 'amount_residual'], 0, 'id')
    else
      Result := Client.SearchRead('account.invoice', Domain1('id', 'in', Found),
        ['number', 'state', 'residual', 'partner_id', 'type'], 0, 'id');
  end;

  function Paid(O: TJSONObject): Boolean;
  begin
    if Client.Major >= 13 then
      Result := (JStr(O, PayField) = 'paid') or (JStr(O, PayField) = 'in_payment') or
        (JStr(O, PayField) = 'reversed')
    else Result := JStr(O, 'state') = 'paid';
  end;

  function Live(O: TJSONObject): Boolean;
  begin
    Result := (JStr(O, 'state') = 'posted') or (JStr(O, 'state') = 'open') or
      (JStr(O, 'state') = 'paid');
  end;

begin
  Result := '';
  if Client.Has('account.move', 'payment_state') then PayField := 'payment_state'
  else PayField := 'invoice_payment_state';
  if Kind = 'cash' then J := JournalId('cash') else J := JournalId('bank');
  Invs := Load;
  try
    for I := 0 to Invs.Count - 1 do
    begin
      Inv := Invs.Objects[I];
      if not Live(Inv) or Paid(Inv) then Continue;
      if Client.Major >= 13 then
      begin
        Ctx := TJSONObject.Create(['active_model', 'account.move', 'active_id', JInt(Inv, 'id')]);
        Ctx.Add('active_ids', TJSONArray.Create([JInt(Inv, 'id')]));
        Vals := TJSONObject.Create;
        if J > 0 then Vals.Add('journal_id', J);
        Args := TJSONArray.Create;
        Args.Add(Vals);
        K := TJSONObject.Create;
        K.Add('context', Ctx.Clone);
        R := Client.Kw('account.payment.register', 'create', Args, K);
        try
          if R is TJSONArray then W := TJSONArray(R).Items[0].AsInteger
          else W := R.AsInteger;
        finally
          R.Free;
        end;
        Args := TJSONArray.Create;
        Args.Add(TJSONArray.Create([W]));
        K := TJSONObject.Create;
        K.Add('context', Ctx);
        if Client.Major >= 14 then
          Client.Kw('account.payment.register', 'action_create_payments', Args, K).Free
        else
          Client.Kw('account.payment.register', 'create_payments', Args, K).Free;
      end
      else
      begin
        if not Client.Exists('account.payment') then raise EOdoo.Make(oeServer, SPayOld);
        Typ := JStr(Inv, 'type');
        if (Typ = 'in_invoice') or (Typ = 'out_refund') then PType := 'outbound'
        else PType := 'inbound';
        Method := 0;
        M := Client.SearchRead('account.payment.method', TJSONArray(GetJSON(
          '[["code", "=", "manual"], ["payment_type", "=", "' + PType + '"]]')), ['name'], 1, '');
        try
          if M.Count > 0 then Method := JInt(M.Objects[0], 'id');
        finally
          M.Free;
        end;
        Vals := TJSONObject.Create(['payment_type', PType, 'partner_id',
          M2OId(Inv, 'partner_id'), 'amount', JNum(Inv, 'residual'),
          'journal_id', J, 'payment_method_id', Method]);
        if (Typ = 'in_invoice') or (Typ = 'in_refund') then Vals.Add('partner_type', 'supplier')
        else Vals.Add('partner_type', 'customer');
        Vals.Add('invoice_ids', TJSONArray.Create([TJSONArray.Create([6, 0,
          TJSONArray.Create([JInt(Inv, 'id')])])]));
        Args := TJSONArray.Create;
        Args.Add(Vals);
        R := Client.Kw('account.payment', 'create', Args);
        try
          if R is TJSONArray then W := TJSONArray(R).Items[0].AsInteger
          else W := R.AsInteger;
        finally
          R.Free;
        end;
        Args := TJSONArray.Create;
        Args.Add(TJSONArray.Create([W]));
        Client.Kw('account.payment', 'post', Args).Free;
      end;
    end;
    // Cómo quedaron.
    Invs.Free;
    Invs := Load;
    for I := 0 to Invs.Count - 1 do
    begin
      Inv := Invs.Objects[I];
      if not Live(Inv) then Continue;
      if not Paid(Inv) then
        raise EOdoo.Make(oeServer, Format(SNotPaid, [JStr(Inv, 'name') + JStr(Inv, 'number')]));
      if Result <> '' then Result := Result + ', ';
      Result := Result + JStr(Inv, 'name') + JStr(Inv, 'number');
    end;
  finally
    Invs.Free;
  end;
end;

{ Los ids de un campo x2many de un registro (vacío si no hay). }
function TOdooSync.Ids(const Model: string; Id: Integer;
  const Field: string): TJSONArray;
var
  Rows: TJSONArray;
  D: TJSONData;
begin
  Result := TJSONArray.Create;
  if not Client.Has(Model, Field) then Exit;
  Rows := Client.SearchRead(Model, Domain1('id', '=',
    TJSONIntegerNumber.Create(Id)), [Field], 1, '');
  try
    if Rows.Count > 0 then
    begin
      D := Rows.Objects[0].Find(Field);
      if D is TJSONArray then
      begin
        Result.Free;
        Result := TJSONArray(D.Clone);
      end;
    end;
  finally
    Rows.Free;
  end;
end;

{ Confirmar: action_button_confirm hasta la 8; action_confirm desde la 9. }
procedure TOdooSync.Confirm(Id: Integer);
var
  Rows, Args: TJSONArray;
  St: string;
begin
  Rows := Client.SearchRead('sale.order', Domain1('id', '=',
    TJSONIntegerNumber.Create(Id)), ['state'], 1, '');
  try
    St := '';
    if Rows.Count > 0 then St := JStr(Rows.Objects[0], 'state');
  finally
    Rows.Free;
  end;
  if (St <> 'draft') and (St <> 'sent') then Exit; // ya confirmado
  Args := TJSONArray.Create;
  Args.Add(TJSONArray.Create([Id]));
  if Client.Major <= 8 then Client.Kw('sale.order', 'action_button_confirm', Args).Free
  else Client.Kw('sale.order', 'action_confirm', Args).Free;
end;

{ Lo que devuelve validar una entrega puede ser un asistente que pregunta
  algo: se crea (o se usa el que ya viene) y se acepta. }
procedure TOdooSync.RunWizard(R: TJSONData);
var
  N, W: Integer;
  Model, Method: string;
  Ctx, K: TJSONObject;
  Args: TJSONArray;
  Next: TJSONData;
begin
  try
    for N := 1 to 4 do
    begin
      if not (R is TJSONObject) then Exit;
      Model := JStr(TJSONObject(R), 'res_model');
      if (Model = 'stock.immediate.transfer') or (Model = 'stock.backorder.confirmation') then
        Method := 'process'
      else if Model = 'stock.overprocessed.transfer' then Method := 'action_confirm'
      else if Model = 'confirm.stock.sms' then Method := 'dont_send_sms'
      else Exit;
      if TJSONObject(R).Find('context') is TJSONObject then
        Ctx := TJSONObject(TJSONObject(R).Objects['context'].Clone)
      else Ctx := TJSONObject.Create;
      Ctx.Booleans['skip_sms'] := True;
      W := JInt(TJSONObject(R), 'res_id');
      if W = 0 then
      begin
        Args := TJSONArray.Create;
        Args.Add(TJSONObject.Create);
        K := TJSONObject.Create;
        K.Add('context', Ctx.Clone);
        Next := Client.Kw(Model, 'create', Args, K);
        try
          W := Next.AsInteger;
        finally
          Next.Free;
        end;
      end;
      Args := TJSONArray.Create;
      Args.Add(TJSONArray.Create([W]));
      K := TJSONObject.Create;
      K.Add('context', Ctx);
      Next := Client.Kw(Model, Method, Args, K);
      R.Free;
      R := Next;
    end;
  finally
    R.Free;
  end;
end;

{ Valida las entregas del pedido que no estén hechas, con las cantidades
  pedidas: en la 17+, quantity y picked de cada movimiento; de la 11 a la 16,
  quantity_done; hasta la 11 se fuerza la disponibilidad (force_assign); luego
  button_validate (do_new_transfer en la 9 y la 10; do_transfer en la 8) y sus
  asistentes. }
function TOdooSync.Deliver(const Model: string; Id: Integer): string;
var
  Picks, Moves, Rows, Args: TJSONArray;
  P, M, Vals, K: TJSONObject;
  I, J: Integer;
  MoveField: string;
  R: TJSONData;
begin
  Result := '';
  Picks := Ids(Model, Id, 'picking_ids');
  try
    if Picks.Count = 0 then Exit;
    if Client.Has('stock.picking', 'move_ids') then MoveField := 'move_ids'
    else MoveField := 'move_lines';
    Rows := Client.SearchRead('stock.picking', Domain1('id', 'in', Picks.Clone),
      ['name', 'state', MoveField], 0, 'id');
    try
      for I := 0 to Rows.Count - 1 do
      begin
        P := Rows.Objects[I];
        if (JStr(P, 'state') = 'done') or (JStr(P, 'state') = 'cancel') then Continue;
        if JStr(P, 'state') = 'draft' then
        begin
          Args := TJSONArray.Create;
          Args.Add(TJSONArray.Create([JInt(P, 'id')]));
          Client.Kw('stock.picking', 'action_confirm', Args).Free;
        end;
        // Hasta la 10, forzar la disponibilidad antes de reservar: así las
        // operaciones son por toda la cantidad (sin entregas pendientes).
        if Client.Major <= 10 then
        try
          Args := TJSONArray.Create;
          Args.Add(TJSONArray.Create([JInt(P, 'id')]));
          Client.Kw('stock.picking', 'force_assign', Args).Free;
        except
          on E: EOdoo do
            if E.Kind <> oeServer then raise;
        end;
        try
          Args := TJSONArray.Create;
          Args.Add(TJSONArray.Create([JInt(P, 'id')]));
          Client.Kw('stock.picking', 'action_assign', Args).Free;
        except
          on E: EOdoo do
            if E.Kind <> oeServer then raise; // sin existencias: se sigue
        end;
        if P.Find(MoveField) is TJSONArray then
        begin
          Moves := Client.SearchRead('stock.move', Domain1('id', 'in',
            P.Arrays[MoveField].Clone), ['product_uom_qty', 'state'], 0, '');
          try
            for J := 0 to Moves.Count - 1 do
            begin
              M := Moves.Objects[J];
              if (JStr(M, 'state') = 'done') or (JStr(M, 'state') = 'cancel') then
                Continue;
              Vals := nil;
              if Client.Has('stock.move', 'picked') then
                Vals := TJSONObject.Create(['quantity', JNum(M, 'product_uom_qty'),
                  'picked', True])
              else if Client.Has('stock.move', 'quantity_done') and (Client.Major >= 11) then
                Vals := TJSONObject.Create(['quantity_done', JNum(M, 'product_uom_qty')]);
              if Vals = nil then Continue;
              Args := TJSONArray.Create;
              Args.Add(TJSONArray.Create([JInt(M, 'id')]));
              Args.Add(Vals);
              Client.Kw('stock.move', 'write', Args).Free;
            end;
          finally
            Moves.Free;
          end;
        end;
        if Client.Major = 11 then
        try
          Args := TJSONArray.Create;
          Args.Add(TJSONArray.Create([JInt(P, 'id')]));
          Client.Kw('stock.picking', 'force_assign', Args).Free;
        except
          on E: EOdoo do
            if E.Kind <> oeServer then raise;
        end;
        Args := TJSONArray.Create;
        Args.Add(TJSONArray.Create([JInt(P, 'id')]));
        K := TJSONObject.Create;
        K.Add('context', TJSONObject.Create(['skip_sms', True]));
        if Client.Major <= 8 then R := Client.Kw('stock.picking', 'do_transfer', Args, K)
        else if Client.Major <= 10 then R := Client.Kw('stock.picking', 'do_new_transfer', Args, K)
        else R := Client.Kw('stock.picking', 'button_validate', Args, K);
        RunWizard(R);
      end;
    finally
      Rows.Free;
    end;
    // Cómo quedaron.
    Rows := Client.SearchRead('stock.picking', Domain1('id', 'in', Picks.Clone),
      ['name', 'state'], 0, 'id');
    try
      for I := 0 to Rows.Count - 1 do
      begin
        P := Rows.Objects[I];
        if JStr(P, 'state') = 'cancel' then Continue;
        if JStr(P, 'state') <> 'done' then
          raise EOdoo.Make(oeServer, Format(SDeliveryFailed, [JStr(P, 'name'),
            JStr(P, 'state')]));
        if Result <> '' then Result := Result + ', ';
        Result := Result + JStr(P, 'name');
      end;
    finally
      Rows.Free;
    end;
  finally
    Picks.Free;
  end;
end;

{ La factura: si el pedido no tiene, se crea con el asistente de Odoo
  (sale.advance.payment.inv, el del botón «Crear factura») y se publica:
  account.move.action_post desde la 13; account.invoice.action_invoice_open
  (11-12) o la señal invoice_open del flujo (8-10). }
function TOdooSync.Invoice(Id: Integer): string;
var
  InvModel, Method, NameField: string;
  Invs, Rows, Args, Lines: TJSONArray;
  Ctx, Vals, K, L: TJSONObject;
  R: TJSONData;
  I, W, Live: Integer;
  ToInvoice: Double;

  function LoadInvoices: TJSONArray;
  var
    Found: TJSONArray;
  begin
    Found := Ids('sale.order', Id, 'invoice_ids');
    Result := Client.SearchRead(InvModel, Domain1('id', 'in', Found),
      ['state', 'name', 'number'], 0, 'id');
  end;

  function NewContext: TJSONObject;
  begin
    Result := TJSONObject.Create(['active_model', 'sale.order', 'active_id', Id]);
    Result.Add('active_ids', TJSONArray.Create([Id]));
  end;

begin
  Result := '';
  if Client.Major >= 13 then InvModel := 'account.move' else InvModel := 'account.invoice';
  if Client.Major >= 13 then NameField := 'name' else NameField := 'number';
  Invs := LoadInvoices;
  try
    Live := 0;
    for I := 0 to Invs.Count - 1 do
      if JStr(Invs.Objects[I], 'state') <> 'cancel' then Inc(Live);
    if Live = 0 then
    begin
      // Productos que se facturan por lo entregado y nada entregado aún:
      // primero la entrega.
      if Client.Has('sale.order', 'picking_ids') and
        Client.Has('sale.order.line', 'qty_to_invoice') then
      begin
        ToInvoice := 0;
        Lines := Client.SearchRead('sale.order.line', Domain1('order_id', '=',
          TJSONIntegerNumber.Create(Id)), ['qty_to_invoice'], 0, '');
        try
          for I := 0 to Lines.Count - 1 do
            ToInvoice := ToInvoice + JNum(Lines.Objects[I], 'qty_to_invoice');
        finally
          Lines.Free;
        end;
        if ToInvoice <= 0 then
        begin
          Method := Deliver('sale.order', Id);
          if Method <> '' then Log(Format(SPosDeliveredLog, [Method]));
        end;
      end;
      // Sin Inventario no hay entregas: lo entregado se apunta a mano.
      if not Client.Has('sale.order', 'picking_ids') then
      begin
        Lines := Client.SearchRead('sale.order.line', Domain1('order_id', '=',
          TJSONIntegerNumber.Create(Id)), ['product_uom_qty', 'qty_delivered'], 0, '');
        try
          for I := 0 to Lines.Count - 1 do
          begin
            L := Lines.Objects[I];
            if JNum(L, 'qty_delivered') >= JNum(L, 'product_uom_qty') then Continue;
            try
              Args := TJSONArray.Create;
              Args.Add(TJSONArray.Create([JInt(L, 'id')]));
              Args.Add(TJSONObject.Create(['qty_delivered', JNum(L, 'product_uom_qty')]));
              Client.Kw('sale.order.line', 'write', Args).Free;
            except
              on E: EOdoo do
                if E.Kind <> oeServer then raise;
            end;
          end;
        finally
          Lines.Free;
        end;
      end;
      if Client.Selection('sale.advance.payment.inv', 'advance_payment_method',
        'delivered') then Method := 'delivered'
      else Method := 'all';
      Vals := TJSONObject.Create(['advance_payment_method', Method]);
      if Client.Has('sale.advance.payment.inv', 'sale_order_ids') then
        Vals.Add('sale_order_ids', TJSONArray.Create([TJSONArray.Create([6, 0,
          TJSONArray.Create([Id])])]));
      Args := TJSONArray.Create;
      Args.Add(Vals);
      K := TJSONObject.Create;
      K.Add('context', NewContext);
      R := Client.Kw('sale.advance.payment.inv', 'create', Args, K);
      try
        W := R.AsInteger;
      finally
        R.Free;
      end;
      Args := TJSONArray.Create;
      Args.Add(TJSONArray.Create([W]));
      K := TJSONObject.Create;
      K.Add('context', NewContext);
      Client.Kw('sale.advance.payment.inv', 'create_invoices', Args, K).Free;
      Invs.Free;
      Invs := LoadInvoices;
      if Invs.Count = 0 then
        raise EOdoo.Make(oeServer, Format(SNoInvoice, [IntToStr(Id)]));
    end;
    // Publicar las que sigan en borrador.
    for I := 0 to Invs.Count - 1 do
    begin
      if JStr(Invs.Objects[I], 'state') <> 'draft' then Continue;
      Args := TJSONArray.Create;
      Args.Add(TJSONArray.Create([JInt(Invs.Objects[I], 'id')]));
      if Client.Major >= 13 then Client.Kw('account.move', 'action_post', Args).Free
      else
      try
        Client.Kw('account.invoice', 'action_invoice_open', Args).Free;
      except
        on E: EOdoo do
        begin
          if E.Kind <> oeServer then raise;
          Args := TJSONArray.Create;
          Args.Add(TJSONArray.Create([JInt(Invs.Objects[I], 'id')]));
          Args.Add('invoice_open');
          Client.Kw('account.invoice', 'signal_workflow', Args).Free;
        end;
      end;
    end;
    Invs.Free;
    Invs := LoadInvoices;
    for I := 0 to Invs.Count - 1 do
    begin
      if JStr(Invs.Objects[I], 'state') = 'cancel' then Continue;
      if JStr(Invs.Objects[I], 'state') = 'draft' then
        raise EOdoo.Make(oeServer, Format(SNoInvoice, [IntToStr(Id)]));
      if Result <> '' then Result := Result + ', ';
      Result := Result + JStr(Invs.Objects[I], NameField);
    end;
  finally
    Invs.Free;
  end;
end;

{ Una venta del punto de venta: pedido, confirmación, entrega y factura.
  Cada paso mira antes cómo está en Odoo: si se corta a medias, al
  sincronizar otra vez se sigue donde se quedó, sin repetir nada. }
procedure TOdooSync.PushPos(Op: TJSONObject);
var
  O: TJSONObject;
  Id: Integer;
  Names: string;
begin
  O := Store.Find('orders', 0, JStr(Op, 'ref'));
  if O = nil then Exit;
  try
    Id := EnsureOrder(O);
    Confirm(Id);
    O.Strings['step'] := 'order';
    Log(Format(SPosConfirmed, [JStr(O, 'name')]));
    Store.Save;
    if Client.Has('sale.order', 'picking_ids') then
    begin
      Names := Deliver('sale.order', Id);
      O.Strings['picking'] := Names;
      O.Strings['step'] := 'delivered';
      if Names <> '' then Log(Format(SPosDeliveredLog, [Names]));
    end
    else
    begin
      O.Booleans['nostock'] := True;
      Log(SPosNoStockLog);
    end;
    Store.Save;
    Names := Invoice(Id);
    O.Strings['invoice'] := Names;
    O.Strings['step'] := 'invoiced';
    O.Strings['error'] := '';
    Log(Format(SPosInvoicedLog, [Names]));
    RefreshOrder(O, Id); // el estado y el total finales
  except
    on E: EOdoo do
    begin
      if E.Kind = oeServer then O.Strings['error'] := E.Message;
      raise;
    end;
  end;
end;

{ Envía la bandeja de salida en orden (los clientes antes que sus
  presupuestos). Sin red se para; un error de Odoo deja ese cambio con su
  mensaje y sigue con los demás. }
function TOdooSync.Push: Integer;
var
  Box: TJSONArray;
  Op: TJSONObject;
  I: Integer;
  K: string;
begin
  Result := 0;
  Box := Store.List('outbox');
  I := 0;
  while I < Box.Count do
  begin
    Op := Box.Objects[I];
    K := JStr(Op, 'op');
    try
      if K = 'partner_create' then PushPartner(Op, False)
      else if K = 'partner_write' then PushPartner(Op, True)
      else if K = 'product_create' then PushProduct(Op)
      else if (K = 'order_create') or (K = 'order_step') then PushOrder(Op)
      else if (K = 'purchase_create') or (K = 'purchase_step') then PushPurchase(Op)
      else if K = 'pos_sale' then PushPos(Op)
      else if K = 'bim_project' then PushBimProject(Op)
      else if K = 'bim_budget' then PushBimBudget(Op);
      Box.Delete(I);
      Inc(Result);
      Store.Save;
    except
      on E: EOdoo do
      begin
        if E.Kind in [oeNetwork, oeSSL, oeLogin, oeDatabase, oeConfig] then raise;
        Op.Strings['error'] := E.Message;
        Log(Format(SPushError, [Describe(Store, Op), E.Message]));
        Store.Save;
        Inc(I);
      end;
    end;
  end;
end;

// ----------------------------------------------------------------- TPing

procedure TPing.Execute;
var
  C: TFPHTTPClient;
  Src: TStringStream;
  S: string;
begin
  Ok := False;
  C := TFPHTTPClient.Create(nil);
  Src := TStringStream.Create('{"jsonrpc":"2.0","method":"call","params":{},"id":1}');
  try
    try
      C.ConnectTimeout := 6000;
      C.IOTimeout := 8000;
      C.AddHeader('Content-Type', 'application/json');
      C.RequestBody := Src;
      S := C.Post(Url + '/web/webclient/version_info');
      Ok := Pos('"result"', S) > 0;
    except
      Ok := False;
    end;
  finally
    C.Free;
    Src.Free;
  end;
end;

{ El ticket de una venta del punto de venta, con los nombres de Odoo. }
function Receipt(O: TJSONObject): string;
var
  I: Integer;
  L: TJSONObject;
  Lines, Pay, Pick, Inv, Name, St: string;
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  Lines := '';
  if O.Find('lines') is TJSONArray then
    for I := 0 to O.Arrays['lines'].Count - 1 do
    begin
      L := O.Arrays['lines'].Objects[I];
      Lines := Lines + Format(SPosLine, [FormatFloat('0.##', JNum(L, 'qty'), F),
        JStr(L, 'name')]) + '   ' + Money(JNum(L, 'qty') * JNum(L, 'price') *
        (1 - JNum(L, 'discount') / 100));
      if JNum(L, 'discount') <> 0 then
        Lines := Lines + ' (' + Format(SPosDisc, [FormatFloat('0.##',
          JNum(L, 'discount'), F)]) + ')';
      Lines := Lines + LineEnding;
    end;
  if JStr(O, 'payment') = 'card' then Pay := SCard else Pay := SCash;
  Name := JStr(O, 'name');
  if Name = '' then Name := SNoStock;
  Pick := JStr(O, 'picking');
  if JBool(O, 'nostock') then Pick := SNoStockApp
  else if Pick = '' then Pick := SNoStock;
  Inv := JStr(O, 'invoice');
  if Inv = '' then Inv := SNoStock;
  St := PosLabel(O);
  if JStr(O, 'error') <> '' then St := St + ': ' + JStr(O, 'error');
  Result := Format(SReceipt, [JStr(O, 'ref'), ShortDate(JStr(O, 'date')) + ' ' +
    Copy(JStr(O, 'date'), 12, 5), Pay, JStr(O, 'partner'), Lines,
    Money(JNum(O, 'amount')), St, Name, Pick, Inv]);
end;

// ---------------------------------------------------------------- TForm1

destructor TForm1.Destroy;
begin
  if Ping <> nil then
  begin
    Ping.WaitFor;
    Ping.Free;
  end;
  Sync.Free;
  Client.Free;
  Store.Free;
  Draft.Free;
  Cart.Free;
  PurDraft.Free;
  BimOpen.Free;
  inherited Destroy;
end;

procedure TForm1.form_create;
begin
  {$IFDEF DARWIN}
  // Los colores del diseño son claros: con el modo oscuro de macOS, las
  // casillas y los botones del sistema saldrían con letra blanca.
  NSApp.setAppearance(NSAppearance.appearanceNamed(
    NSString.stringWithUTF8String('NSAppearanceNameAqua')));
  {$ENDIF}
  SetupOpenSSL;
  if Length(SNumberSample) >= 6 then
  begin
    Thousands := SNumberSample[2];
    Decimals := SNumberSample[6];
  end;
  Store := TOdooStore.Create(DataDir + 'odoo-offline.json');
  Client := TOdooClient.Create;
  Sync := TOdooSync.Create(Client, Store);
  Sync.OnLog := @AddLog;
  Draft := TJSONArray.Create;
  Cart := TJSONArray.Create;
  PurDraft := TJSONArray.Create;
  StyleUi;
  LoadSettings;
  ShowPage(0);
  CustNew_click;
  ShowProduct(nil);
  RefreshAll;
  // Con los datos guardados, se prueba la conexión en segundo plano.
  if Configured and SyncAuto.Checked and not SyncOffline.Checked then StartPing;
end;

procedure TForm1.form_close;
begin
  SaveSettings;
  Store.Save;
end;

function MakeBox(Owner: TComponent; Parent: TWinControl;
  Handler: TNotifyEvent): TPaintBox;
begin
  Result := TPaintBox.Create(Owner);
  Result.Parent := Parent;
  Result.Align := alClient;
  Result.OnPaint := Handler;
end;

procedure OwnerDraw(L: TListBox; Height: Integer; Handler: TDrawItemEvent);
begin
  L.Style := lbOwnerDrawFixed;
  L.ItemHeight := Height;
  L.OnDrawItem := Handler;
  L.Color := clWhite;
end;

procedure TForm1.StyleUi;
const
  Glyphs: array[0..8] of string = ('▦', '☺', '▣', '€', '▥', '↻', '⚙', '⌂', '▤');
var
  I: Integer;
  Navs: array[0..8] of TDmsButton;
  Folder: string;
begin
  for I := 0 to ComponentCount - 1 do
    if (Components[I] is TPanel) and not (Components[I] is TDmsButton) then
      TPanel(Components[I]).BevelOuter := bvNone;
  Pages.ShowTabs := False;
  Navs[0] := NavPanel; Navs[1] := NavCustomers; Navs[2] := NavProducts;
  Navs[3] := NavSales; Navs[4] := NavPos; Navs[5] := NavSync;
  Navs[6] := NavSettings; Navs[7] := NavBim; Navs[8] := NavPurchases;
  for I := 0 to 8 do
  begin
    Navs[I].Alignment := taLeftJustify;
    Navs[I].Caption := '   ' + Glyphs[I] + '   ' + Navs[I].Caption;
  end;
  MonthBox := MakeBox(Self, ChartMonth, @PaintMonth);
  StateBox := MakeBox(Self, ChartState, @PaintState);
  TopBox := MakeBox(Self, ChartTop, @PaintTop);
  OwnerDraw(CustList, 46, @DrawCustomer);
  OwnerDraw(ProdList, 30, @DrawProduct);
  OwnerDraw(SaleList, 46, @DrawSale);
  OwnerDraw(PurList, 46, @DrawPurchase);
  OwnerDraw(RecentList, 38, @DrawRecent);
  OwnerDraw(Outbox, 46, @DrawOutbox);
  OwnerDraw(PosLines, 40, @DrawPosLine);
  OwnerDraw(BimTree, 36, @DrawBimNode);
  OwnerDraw(BimRows, 40, @DrawBimRow);
  BimTree.OnMouseUp := @BimTreeMouseUp;
  BimRows.OnMouseUp := @BimRowsMouseUp;
  BimTree.OnKeyDown := @BimKeyDown;
  BimRows.OnKeyDown := @BimKeyDown;
  BimAdd.Hint := SBimHintAdd;
  BimHome.Hint := SBimHintHome;
  BimDel.Hint := SBimHintDel;
  BimAdd.ShowHint := True;
  BimHome.ShowHint := True;
  BimDel.ShowHint := True;
  BimOpen := TStringList.Create;
  BimType.ItemIndex := 0;
  PosBox := MakeBox(Self, PosGrid, @PaintPos);
  PosBox.OnMouseUp := @PosMouseUp;
  PosBox.Cursor := crHandPoint;
  PosSearch.TextHint := SSearchPos;
  PosSearch.OnChange := @SearchChange;
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TEdit then
    begin
      TEdit(Components[I]).AutoSelect := False;
      TEdit(Components[I]).OnEnter := @EditEnter;
    end;
  CustSearch.TextHint := SSearchCust;
  ProdSearch.TextHint := SSearchProd;
  SaleSearch.TextHint := SSearchSale;
  CustSearch.OnChange := @SearchChange;
  ProdSearch.OnChange := @SearchChange;
  SaleSearch.OnChange := @SearchChange;
  SaleFilter.ItemIndex := 0;
  PurSearch.TextHint := SSearchPur;
  PurSearch.OnChange := @SearchChange;
  PurFilter.ItemIndex := 0;
  SalePayKind.ItemIndex := 0;
  PurPayKind.ItemIndex := 0;
  PurQty.Text := '1';
  SyncLog.ReadOnly := True;
  SyncLog.ScrollBars := ssAutoVertical;
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TLabel then
      with TLabel(Components[I]) do
        if Height > 40 then Layout := tlTop;
  Folder := StringReplace(DataDir, GetUserDir, '~' + PathDelim, []);
  if SSLFrom <> '' then
    CfgFolder.Caption := Format(SFolder, [Folder]) + LineEnding + 'OpenSSL: ' +
      StringReplace(SSLFrom, GetUserDir, '~' + PathDelim, [])
  else
    CfgFolder.Caption := Format(SFolder, [Folder]) + LineEnding + 'OpenSSL: ' + SNoSsl;
end;

// ---- navegación

{ Al entrar en un campo, el cursor al final y sin texto elegido: macOS lo
  elige todo y una tecla pulsada sin querer borraría, por ejemplo, la
  dirección del servidor. }
procedure TForm1.EditEnter(Sender: TObject);
begin
  Application.QueueAsyncCall(@Deselect, PtrInt(Sender));
end;

procedure TForm1.Deselect(Data: PtrInt);
var
  E: TEdit;
begin
  E := TEdit(Data);
  if E.Focused and (E.SelLength = Length(E.Text)) and (E.Text <> '') then
  begin
    E.SelStart := Length(E.Text);
    E.SelLength := 0;
  end;
end;

procedure TForm1.ShowPage(N: Integer);
begin
  PageNo := N;
  Pages.PageIndex := N;
  PageTitle.Caption := Part(SPageNames, N);
  PageSub.Caption := Part(SPageSubs, N);
  case N of
    1: RefreshCustomers;
    2: RefreshProducts;
    3: begin RefreshSales; RefreshChoices; end;
    4: RefreshPos;
    5: begin RefreshOutbox; RefreshSyncInfo; end;
    7: begin RefreshBim; BimPrepare(False); end;
    8: begin RefreshPurchases; RefreshPurChoices; end;
  end;
  // Que ningún campo se quede con el foco (y todo el texto elegido): una
  // tecla pulsada sin querer lo cambiaría.
  ActiveControl := nil;
  // Después del clic (el botón recupera su color al soltarlo).
  Application.QueueAsyncCall(@PaintNav, 0);
end;

procedure TForm1.PaintNav(Data: PtrInt);
var
  I: Integer;
  B: TDmsButton;
begin
  for I := 0 to 8 do
  begin
    case I of
      8: B := NavPurchases;
      7: B := NavBim;
      0: B := NavPanel;
      1: B := NavCustomers;
      2: B := NavProducts;
      3: B := NavSales;
      4: B := NavPos;
      5: B := NavSync;
    else
      B := NavSettings;
    end;
    if I = PageNo then
    begin
      B.Color := CBlue;
      B.Font.Color := clWhite;
    end
    else
    begin
      B.Color := CSide;
      B.Font.Color := CSideFg;
    end;
  end;
end;

procedure TForm1.NavPanel_click;
begin
  ShowPage(0);
end;

procedure TForm1.NavCustomers_click;
begin
  ShowPage(1);
end;

procedure TForm1.NavProducts_click;
begin
  ShowPage(2);
end;

procedure TForm1.NavSales_click;
begin
  ShowPage(3);
end;

procedure TForm1.NavPos_click;
begin
  ShowPage(4);
end;

procedure TForm1.NavSync_click;
begin
  ShowPage(5);
end;

procedure TForm1.NavSettings_click;
begin
  ShowPage(6);
end;

// ---- estado y listas

procedure TForm1.AddLog(const Line: string);
begin
  SyncLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + Line);
  SyncLog.SelStart := Length(SyncLog.Text);
end;

procedure TForm1.RefreshAll;
begin
  RefreshStatus;
  RefreshKpis;
  RefreshCustomers;
  RefreshProducts;
  RefreshSales;
  RefreshChoices;
  RefreshOutbox;
  RefreshSyncInfo;
  RefreshPos;
  RefreshPurchases;
  RefreshPurChoices;
  LayoutNav;
  RefreshBim;
end;

procedure TForm1.RefreshStatus;
var
  N: Integer;
  S: string;
  Bg, Fg: TColor;
begin
  N := Store.Pending;
  if Busy then
  begin
    S := SSyncing; Bg := $00FAF0E5; Fg := CBlue;
  end
  else if SyncOffline.Checked then
  begin
    S := SWorkOffline; Bg := $00E2F3FE; Fg := $000945B4;
  end
  else if Online then
  begin
    S := SOnline + ' · Odoo ' + IntToStr(Client.Major); Bg := $00EAF4E6; Fg := CGreen;
  end
  else
  begin
    S := SOffline; Bg := $00F2F0EE; Fg := CMuted;
  end;
  Badge.Caption := '● ' + S;
  Badge.Color := Bg;
  Badge.Font.Color := Fg;
  SideState.Caption := '● ' + S;
  if Online then SideState.Font.Color := $0080D8A0
  else SideState.Font.Color := CSideFg;
  if N > 0 then SidePending.Caption := Format(SPendingN, [N])
  else SidePending.Caption := SNoPending;
  if Configured or (Trim(CfgUrl.Text) <> '') then
    SideServer.Caption := StringReplace(Client.Base, 'https://', '', []) +
      LineEnding + Trim(CfgDb.Text)
  else SideServer.Caption := SNotConfigured;
  if N > 0 then BtnSync.Caption := SSync + ' (' + IntToStr(N) + ')'
  else BtnSync.Caption := SSync;
end;

procedure TForm1.RefreshKpis;
var
  Orders, Partners: TJSONArray;
  O: TJSONObject;
  I, K, NSales, NQuotes, NLocal: Integer;
  Sales, Quotes: Double;
  Month, Last: string;
begin
  Orders := Store.List('orders');
  Month := FormatDateTime('yyyy-mm', Now);
  NSales := 0; NQuotes := 0; Sales := 0; Quotes := 0;
  for I := 0 to Orders.Count - 1 do
  begin
    O := Orders.Objects[I];
    K := StateKind(O);
    if JBool(O, 'pos') and (K <> 2) then K := 1;
    case K of
      0, 3:
        begin
          Inc(NQuotes);
          Quotes := Quotes + JNum(O, 'amount');
        end;
      1:
        if Copy(JStr(O, 'date'), 1, 7) = Month then
        begin
          Inc(NSales);
          Sales := Sales + JNum(O, 'amount');
        end;
    end;
  end;
  Partners := Store.List('partners');
  NLocal := 0;
  for I := 0 to Partners.Count - 1 do
    if JInt(Partners.Objects[I], 'id') = 0 then Inc(NLocal);
  KpiSalesVal.Caption := Money(Sales);
  KpiSalesSub.Caption := Format(SOrdersN, [NSales]);
  KpiQuotesVal.Caption := IntToStr(NQuotes);
  KpiQuotesSub.Caption := Format(SQuotesSum, [Money(Quotes)]);
  KpiCustomersVal.Caption := IntToStr(Partners.Count);
  if NLocal > 0 then KpiCustomersSub.Caption := Format(SNewLocalN, [NLocal])
  else KpiCustomersSub.Caption := SAllSynced;
  KpiPendingVal.Caption := IntToStr(Store.Pending);
  if Store.Pending > 0 then KpiPendingVal.Font.Color := COrange
  else KpiPendingVal.Font.Color := CGreen;
  Last := JStr(Store.Data, 'last_sync');
  if Last <> '' then
    KpiPendingSub.Caption := Format(SLastSync, [Copy(ShortDate(Last), 1, 5) + ' ' +
      Copy(Last, 12, 5)])
  else KpiPendingSub.Caption := SNeverSynced;
  // Últimos pedidos.
  SetLength(RecentRows, 0);
  RecentList.Items.BeginUpdate;
  try
    RecentList.Items.Clear;
    for I := 0 to Min(Orders.Count, 30) - 1 do
    begin
      SetLength(RecentRows, Length(RecentRows) + 1);
      RecentRows[High(RecentRows)] := I;
      RecentList.Items.Add(OrderTitle(Orders.Objects[I]));
    end;
  finally
    RecentList.Items.EndUpdate;
  end;
  MonthBox.Invalidate;
  StateBox.Invalidate;
  TopBox.Invalidate;
end;

{ ¿Es esta línea de ese producto? Por su id o, si se hizo aquí y aún no
  está en Odoo, por su referencia. }
function SameProduct(L, P: TJSONObject): Boolean;
begin
  if JInt(P, 'id') > 0 then Result := JInt(L, 'product_id') = JInt(P, 'id')
  else Result := (JInt(L, 'product_id') = 0) and (JStr(L, 'product_ref') = JStr(P, 'ref'));
end;

{ Lo que identifica un pedido aunque cambie de sitio en la lista (o reciba
  su id al enviarse): la referencia DMS-… si se hizo aquí; si no, el id. }
function OrderKey(O: TJSONObject): string;
begin
  if Copy(JStr(O, 'ref'), 1, 4) = 'DMS-' then Result := JStr(O, 'ref')
  else Result := '#' + IntToStr(JInt(O, 'id'));
end;

function Matches(const Needle: string; const Values: array of string): Boolean;
var
  N: string;
  I: Integer;
begin
  N := UTF8LowerCase(Trim(Needle));
  if N = '' then Exit(True);
  for I := 0 to High(Values) do
    if Pos(N, UTF8LowerCase(Values[I])) > 0 then Exit(True);
  Result := False;
end;

procedure TForm1.RefreshCustomers;
var
  A: TJSONArray;
  P: TJSONObject;
  I, NLocal: Integer;
begin
  A := Store.List('partners');
  SetLength(CustRows, 0);
  NLocal := 0;
  CustList.Items.BeginUpdate;
  try
    CustList.Items.Clear;
    for I := 0 to A.Count - 1 do
    begin
      P := A.Objects[I];
      if JBool(P, 'pending') then Inc(NLocal);
      if not Matches(CustSearch.Text, [JStr(P, 'name'), JStr(P, 'email'),
        JStr(P, 'city'), JStr(P, 'phone'), JStr(P, 'vat')]) then Continue;
      SetLength(CustRows, Length(CustRows) + 1);
      CustRows[High(CustRows)] := I;
      CustList.Items.Add(JStr(P, 'name'));
    end;
  finally
    CustList.Items.EndUpdate;
  end;
  CustCount.Caption := Format(SCustCount, [Length(CustRows), NLocal]);
end;

procedure TForm1.RefreshProducts;
var
  A: TJSONArray;
  P: TJSONObject;
  I: Integer;
begin
  A := Store.List('products');
  SetLength(ProdRows, 0);
  ProdList.Items.BeginUpdate;
  try
    ProdList.Items.Clear;
    for I := 0 to A.Count - 1 do
    begin
      P := A.Objects[I];
      if not Matches(ProdSearch.Text, [JStr(P, 'name'), JStr(P, 'code')]) then
        Continue;
      SetLength(ProdRows, Length(ProdRows) + 1);
      ProdRows[High(ProdRows)] := I;
      ProdList.Items.Add(JStr(P, 'name'));
    end;
  finally
    ProdList.Items.EndUpdate;
  end;
  ProdCount.Caption := Format(SProdCount, [Length(ProdRows)]);
end;

procedure TForm1.RefreshSales;
var
  A: TJSONArray;
  O: TJSONObject;
  I, K: Integer;
  Keep: string;
  Total: Double;
begin
  A := Store.List('orders');
  Keep := '';
  if (SaleList.ItemIndex >= 0) and (SaleList.ItemIndex <= High(SaleRows)) and
    (SaleRows[SaleList.ItemIndex] < A.Count) then
    Keep := OrderKey(A.Objects[SaleRows[SaleList.ItemIndex]]);
  SetLength(SaleRows, 0);
  Total := 0;
  SaleList.Items.BeginUpdate;
  try
    SaleList.Items.Clear;
    for I := 0 to A.Count - 1 do
    begin
      O := A.Objects[I];
      K := StateKind(O);
      case SaleFilter.ItemIndex of
        1: if K <> 0 then Continue;
        2: if K <> 1 then Continue;
        3: if K <> 2 then Continue;
        4: if K <> 3 then Continue;
        5: if not JBool(O, 'pos') then Continue;
      end;
      if not Matches(SaleSearch.Text, [OrderTitle(O), JStr(O, 'partner'),
        JStr(O, 'ref')]) then Continue;
      SetLength(SaleRows, Length(SaleRows) + 1);
      SaleRows[High(SaleRows)] := I;
      SaleList.Items.Add(OrderTitle(O));
      if (Keep <> '') and (OrderKey(O) = Keep) then SaleList.ItemIndex := High(SaleRows);
      Total := Total + JNum(O, 'amount');
    end;
  finally
    SaleList.Items.EndUpdate;
  end;
  SaleCount.Caption := Format(SSaleCount, [Length(SaleRows), Money(Total)]);
end;

{ Los clientes y productos de los desplegables del presupuesto. }
procedure TForm1.RefreshChoices;
var
  A: TJSONArray;
  P: TJSONObject;
  Sorted: TStringList;
  I, Keep: Integer;
  S: string;
begin
  Keep := -1;
  if (QuoteCust.ItemIndex >= 0) and (QuoteCust.ItemIndex <= High(CustChoice)) then
    Keep := CustChoice[QuoteCust.ItemIndex];
  A := Store.List('partners');
  Sorted := TStringList.Create;
  try
    for I := 0 to A.Count - 1 do
      Sorted.AddObject(JStr(A.Objects[I], 'name'), TObject(PtrInt(I)));
    Sorted.CaseSensitive := False;
    Sorted.Sort;
    SetLength(CustChoice, Sorted.Count);
    QuoteCust.Items.BeginUpdate;
    try
      QuoteCust.Items.Clear;
      for I := 0 to Sorted.Count - 1 do
      begin
        CustChoice[I] := PtrInt(Sorted.Objects[I]);
        QuoteCust.Items.Add(Sorted[I]);
        if CustChoice[I] = Keep then QuoteCust.ItemIndex := I;
      end;
    finally
      QuoteCust.Items.EndUpdate;
    end;
  finally
    Sorted.Free;
  end;
  Keep := QuoteProd.ItemIndex;
  A := Store.List('products');
  QuoteProd.Items.BeginUpdate;
  try
    QuoteProd.Items.Clear;
    for I := 0 to A.Count - 1 do
    begin
      P := A.Objects[I];
      S := JStr(P, 'name');
      if JStr(P, 'code') <> '' then S := '[' + JStr(P, 'code') + '] ' + S;
      QuoteProd.Items.Add(S + ' — ' + Money(JNum(P, 'price')));
    end;
  finally
    QuoteProd.Items.EndUpdate;
  end;
  if Keep < QuoteProd.Items.Count then QuoteProd.ItemIndex := Keep;
end;

procedure TForm1.RefreshDraft;
var
  I: Integer;
  L: TJSONObject;
  Total: Double;
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  Total := 0;
  QuoteLines.Items.BeginUpdate;
  try
    QuoteLines.Items.Clear;
    for I := 0 to Draft.Count - 1 do
    begin
      L := Draft.Objects[I];
      QuoteLines.Items.Add(FormatFloat('0.##', JNum(L, 'qty'), F) + ' × ' +
        JStr(L, 'name') + ' — ' + Money(JNum(L, 'qty') * JNum(L, 'price')));
      Total := Total + JNum(L, 'qty') * JNum(L, 'price');
    end;
  finally
    QuoteLines.Items.EndUpdate;
  end;
  QuoteTotal.Caption := Format(STotalNoTax, [Money(Total)]);
end;

procedure TForm1.RefreshOutbox;
var
  A: TJSONArray;
  I: Integer;
begin
  A := Store.List('outbox');
  Outbox.Items.BeginUpdate;
  try
    Outbox.Items.Clear;
    for I := 0 to A.Count - 1 do
      Outbox.Items.Add(Describe(Store, A.Objects[I]));
  finally
    Outbox.Items.EndUpdate;
  end;
end;

procedure TForm1.RefreshSyncInfo;
var
  Last, Ver: string;
  Server: TJSONObject;
begin
  Last := JStr(Store.Data, 'last_sync');
  if Last = '' then Last := SNever
  else Last := ShortDate(Last) + ' ' + Copy(Last, 12, 5);
  Server := nil;
  if Store.Data.Find('server') is TJSONObject then Server := Store.Data.Objects['server'];
  Ver := JStr(Server, 'version');
  if Ver = '' then Ver := SUnknownVersion
  else Ver := 'Odoo ' + Ver;
  SyncInfo.Caption := Format(SSyncInfo, [Client.Base, Trim(CfgDb.Text), Ver,
    Last, Store.List('partners').Count, Store.List('products').Count,
    Store.List('orders').Count]);
end;

// ---- configuración

procedure TForm1.LoadSettings;
var
  S: TJSONObject;
  I: Integer;
  Log: TJSONArray;
begin
  S := Store.Settings;
  CfgUrl.Text := JStr(S, 'url');
  CfgDb.Text := JStr(S, 'db');
  CfgUser.Text := JStr(S, 'login');
  CfgRemember.Checked := JBool(S, 'remember');
  CfgPass.Text := JStr(S, 'password');
  SyncAuto.Checked := (S.Find('auto') = nil) or JBool(S, 'auto');
  SyncOffline.Checked := JBool(S, 'offline');
  CurSymbol := JStr(S, 'currency');
  CurAfter := (S.Find('currency_after') = nil) or JBool(S, 'currency_after');
  Client.Url := CfgUrl.Text;
  Client.Db := CfgDb.Text;
  Client.Login := CfgUser.Text;
  Client.Password := CfgPass.Text;
  Log := Store.List('log');
  SyncLog.Lines.BeginUpdate;
  try
    SyncLog.Lines.Clear;
    for I := Max(0, Log.Count - 100) to Log.Count - 1 do
      SyncLog.Lines.Add(Log.Strings[I]);
  finally
    SyncLog.Lines.EndUpdate;
  end;
end;

procedure TForm1.SaveSettings;
var
  S: TJSONObject;
begin
  S := Store.Settings;
  // Otro servidor, base o usuario: hay que volver a entrar.
  if (Client.Url <> Trim(CfgUrl.Text)) or (Client.Db <> Trim(CfgDb.Text)) or
    (Client.Login <> Trim(CfgUser.Text)) or (Client.Password <> CfgPass.Text) then
  begin
    Client.Reset;
    Online := False;
  end;
  Client.Url := Trim(CfgUrl.Text);
  Client.Db := Trim(CfgDb.Text);
  Client.Login := Trim(CfgUser.Text);
  Client.Password := CfgPass.Text;
  S.Strings['url'] := Client.Url;
  S.Strings['db'] := Client.Db;
  S.Strings['login'] := Client.Login;
  S.Booleans['remember'] := CfgRemember.Checked;
  if CfgRemember.Checked then S.Strings['password'] := CfgPass.Text
  else S.Strings['password'] := '';
  S.Booleans['auto'] := SyncAuto.Checked;
  S.Booleans['offline'] := SyncOffline.Checked;
  Store.Save;
end;

function TForm1.Configured: Boolean;
begin
  Result := (Trim(CfgUrl.Text) <> '') and (Trim(CfgUser.Text) <> '') and
    (CfgPass.Text <> '');
end;

// ---- sincronizar

procedure TForm1.SetBusy(B: Boolean);
begin
  Busy := B;
  if B then Screen.Cursor := crHourGlass
  else Screen.Cursor := crDefault;
  BtnSync.Enabled := not B;
  SyncNow.Enabled := not B;
  CfgConnect.Enabled := not B;
  RefreshStatus;
  Application.ProcessMessages;
end;

procedure TForm1.Fail(E: Exception; Quiet: Boolean);
begin
  AddLog(E.Message);
  Store.AddLog(E.Message);
  if not Quiet then MessageDlg(SApp, E.Message, mtError, [mbOK], 0);
end;

procedure TForm1.DoSync(Quiet: Boolean);
var
  Sent, EditId: Integer;
  EditRef: string;
begin
  if Busy then Exit;
  // La descarga cambia las listas: la ficha abierta se vuelve a buscar.
  EditId := JInt(Editing, 'id');
  EditRef := JStr(Editing, 'ref');
  if SyncOffline.Checked then
  begin
    if not Quiet then ShowMessage(SOfflineOn);
    Exit;
  end;
  if not Configured then
  begin
    if not Quiet then
    begin
      ShowPage(6);
      CfgResult.Font.Color := CMuted;
      CfgResult.Caption := SConfigureFirst;
    end;
    Exit;
  end;
  SaveSettings;
  SetBusy(True);
  try
    try
      if Client.Uid = 0 then Sync.Connect;
      Sent := Sync.Push;
      if Sent > 0 then Sync.Log(Format(SSentN, [Sent]));
      Sync.Download;
      Online := True;
      Sync.Log(SSyncDone);
    except
      on E: EOdoo do
      begin
        Online := False;
        if E.Kind in [oeLogin, oeDatabase, oeSession] then Client.Uid := 0;
        Fail(E, Quiet);
      end;
      on E: Exception do
      begin
        Online := False;
        Fail(E, Quiet);
      end;
    end;
  finally
    Store.Save;
    if Editing <> nil then
    begin
      Editing := Store.Find('partners', EditId, EditRef);
      ShowCustomer(Editing);
    end;
    SetBusy(False);
    RefreshAll;
  end;
end;

procedure TForm1.StartPing;
begin
  if (Ping <> nil) or (Client.Base = '') then Exit;
  Ping := TPing.Create(True);
  Ping.Url := Client.Base;
  Ping.Start;
end;

procedure TForm1.BtnSync_click;
begin
  DoSync(False);
end;

procedure TForm1.Tick_timer;
var
  Ok: Boolean;
begin
  Inc(Ticks);
  // La comprobación en segundo plano terminó: si hay red, se sincroniza.
  if (Ping <> nil) and Ping.Finished then
  begin
    Ok := Ping.Ok;
    Ping.Free;
    Ping := nil;
    if Ok and Configured and not SyncOffline.Checked then DoSync(True)
    else
    begin
      Online := False;
      RefreshStatus;
    end;
  end;
  // Sin conexión y con cambios pendientes: se reintenta cada 30 segundos.
  if (Ticks mod 30 = 0) and SyncAuto.Checked and not SyncOffline.Checked and
    not Busy and not Online and Configured and (Store.Pending > 0) then
    StartPing;
end;

// ---- clientes

procedure TForm1.SearchChange(Sender: TObject);
begin
  if Sender = CustSearch then RefreshCustomers
  else if Sender = ProdSearch then RefreshProducts
  else if Sender = PosSearch then
  begin
    PosPageNo := 0;
    RefreshPos;
  end
  else if Sender = PurSearch then RefreshPurchases
  else RefreshSales;
end;

procedure TForm1.ShowCustomer(P: TJSONObject);
begin
  Editing := P;
  if P = nil then
  begin
    CustCardTitle.Caption := SNewCust;
    CustName.Text := ''; CustEmail.Text := ''; CustPhone.Text := '';
    CustStreet.Text := ''; CustCity.Text := ''; CustVat.Text := '';
    CustSupplier.Checked := False;
    CustInfo.Caption := SCustNew;
    Exit;
  end;
  CustCardTitle.Caption := SEditCust;
  CustName.Text := JStr(P, 'name');
  CustEmail.Text := JStr(P, 'email');
  CustPhone.Text := JStr(P, 'phone');
  CustStreet.Text := JStr(P, 'street');
  CustCity.Text := JStr(P, 'city');
  CustVat.Text := JStr(P, 'vat');
  CustSupplier.Checked := JBool(P, 'supplier');
  if JInt(P, 'id') = 0 then CustInfo.Caption := Format(SCustLocal, [JStr(P, 'ref')])
  else if JBool(P, 'pending') then CustInfo.Caption := Format(SCustPending, [JInt(P, 'id')])
  else CustInfo.Caption := Format(SCustSynced, [JInt(P, 'id')]);
end;

procedure TForm1.CustList_select;
begin
  if (CustList.ItemIndex >= 0) and (CustList.ItemIndex <= High(CustRows)) then
    ShowCustomer(Store.List('partners').Objects[CustRows[CustList.ItemIndex]]);
end;

procedure TForm1.CustNew_click;
begin
  CustList.ItemIndex := -1;
  ShowCustomer(nil);
  if PageNo = 1 then CustName.SetFocus;
end;

procedure TForm1.CustCancel_click;
begin
  ShowCustomer(Editing);
end;

procedure TForm1.CustSave_click;
var
  P: TJSONObject;
  E: string;
begin
  if Trim(CustName.Text) = '' then
  begin
    ShowMessage(SNameRequired);
    CustName.SetFocus;
    Exit;
  end;
  E := Trim(CustEmail.Text);
  if (E <> '') and ((Pos('@', E) < 2) or (Pos('.', Copy(E, Pos('@', E), MaxInt)) = 0)) then
  begin
    ShowMessage(SBadEmail);
    CustEmail.SetFocus;
    Exit;
  end;
  if Editing = nil then
    P := Store.AddPartner(CustName.Text, E, CustPhone.Text, CustStreet.Text,
      CustCity.Text, CustVat.Text, CustSupplier.Checked)
  else
  begin
    P := Editing;
    P.Booleans['supplier'] := CustSupplier.Checked or JBool(P, 'supplier_odoo');
    Store.EditPartner(P, CustName.Text, E, CustPhone.Text, CustStreet.Text,
      CustCity.Text, CustVat.Text);
  end;
  RefreshAll;
  ShowCustomer(P);
  // Con conexión se envía ya; sin ella, espera en la bandeja de salida.
  if Online and not SyncOffline.Checked then DoSync(True);
end;

// ---- ventas

procedure TForm1.SaleFilter_select;
begin
  RefreshSales;
end;

procedure TForm1.SaleNew_click;
begin
  Draft.Clear;
  QuoteCust.ItemIndex := -1;
  QuoteQty.Text := '1';
  RefreshChoices;
  RefreshDraft;
  if QuoteCust.Items.Count = 0 then ShowMessage(SNoCustomers);
end;

procedure TForm1.ShowOrder(O: TJSONObject);
var
  L: TJSONObject;
  S, Pay, Inv: string;
  I: Integer;
begin
  if O = nil then Exit;
  if JBool(O, 'pos') then
  begin
    ShowMessage(Receipt(O));
    Exit;
  end;
  if JBool(O, 'purchase') then
    S := Format(SPurInfo, [OrderTitle(O), JStr(O, 'partner'),
      ShortDate(JStr(O, 'date')), Money(JNum(O, 'amount')), StateLabel(O)])
  else
    S := Format(SOrderInfo, [OrderTitle(O), JStr(O, 'partner'),
      ShortDate(JStr(O, 'date')), Money(JNum(O, 'amount')), StateLabel(O)]);
  if Max(JInt(O, 'want'), OrderLevel(O)) >= 2 then
  begin
    Pay := SNoStock;
    if Max(JInt(O, 'want'), OrderLevel(O)) >= 3 then
      if JStr(O, 'pay') = 'cash' then Pay := SCash
      else if JStr(O, 'pay') = 'bank' then Pay := SBank
      else Pay := SStPaid;
    Inv := JStr(O, 'invoice');
    if Inv = '' then Inv := SStPending;
    S := S + LineEnding + Format(SOrderSteps, [Inv, Pay]);
  end;
  if JStr(O, 'error') <> '' then S := S + LineEnding + Format(SOpError, [JStr(O, 'error')]);
  if O.Find('lines') is TJSONArray then
    for I := 0 to O.Arrays['lines'].Count - 1 do
    begin
      L := O.Arrays['lines'].Objects[I];
      S := S + LineEnding + '  ' + JStr(L, 'name') + ' × ' +
        FloatToStr(JNum(L, 'qty')) + ' — ' + Money(JNum(L, 'qty') * JNum(L, 'price'));
    end;
  ShowMessage(S);
end;

procedure TForm1.SaleList_double;
begin
  if (SaleList.ItemIndex >= 0) and (SaleList.ItemIndex <= High(SaleRows)) then
    ShowOrder(Store.List('orders').Objects[SaleRows[SaleList.ItemIndex]]);
end;

procedure TForm1.RecentList_double;
begin
  if (RecentList.ItemIndex >= 0) and (RecentList.ItemIndex <= High(RecentRows)) then
    ShowOrder(Store.List('orders').Objects[RecentRows[RecentList.ItemIndex]]);
end;

procedure TForm1.QuoteAdd_click;
var
  P, L: TJSONObject;
  Q: Double;
  I: Integer;
  F: TFormatSettings;
begin
  if QuoteProd.ItemIndex < 0 then
  begin
    ShowMessage(SChooseProd);
    Exit;
  end;
  F := DefaultFormatSettings;
  F.DecimalSeparator := '.';
  Q := StrToFloatDef(StringReplace(Trim(QuoteQty.Text), ',', '.', []), 0, F);
  if Q <= 0 then
  begin
    ShowMessage(SBadQty);
    QuoteQty.SetFocus;
    Exit;
  end;
  P := Store.List('products').Objects[QuoteProd.ItemIndex];
  for I := 0 to Draft.Count - 1 do
    if SameProduct(Draft.Objects[I], P) then
    begin
      L := Draft.Objects[I];
      L.Floats['qty'] := JNum(L, 'qty') + Q;
      RefreshDraft;
      Exit;
    end;
  Draft.Add(TJSONObject.Create(['product_id', JInt(P, 'id'), 'product_ref',
    JStr(P, 'ref'), 'name', JStr(P, 'name'), 'qty', Q, 'price', JNum(P, 'price'),
    'uom', JInt(P, 'uom')]));
  QuoteQty.Text := '1';
  RefreshDraft;
end;

procedure TForm1.QuoteDel_click;
begin
  if QuoteLines.ItemIndex < 0 then Exit;
  Draft.Delete(QuoteLines.ItemIndex);
  RefreshDraft;
end;

procedure TForm1.QuoteSave_click;
var
  P: TJSONObject;
begin
  if (QuoteCust.ItemIndex < 0) or (QuoteCust.ItemIndex > High(CustChoice)) then
  begin
    ShowMessage(SChooseCust);
    Exit;
  end;
  if Draft.Count = 0 then
  begin
    ShowMessage(SNoLines);
    Exit;
  end;
  P := Store.List('partners').Objects[CustChoice[QuoteCust.ItemIndex]];
  Store.AddOrder(P, Draft); // el presupuesto se queda con las líneas
  Draft := TJSONArray.Create;
  RefreshDraft;
  SaleFilter.ItemIndex := 0;
  SaleList.ItemIndex := -1;
  RefreshAll;
  SaleList.ItemIndex := 0;
  if Online and not SyncOffline.Checked then DoSync(True);
  ShowMessage(SQuoteSaved);
end;

// ---- productos

procedure TForm1.ShowProduct(P: TJSONObject);
var
  F: TFormatSettings;
begin
  EditingProd := P;
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  F.ThousandSeparator := Thousands;
  if P = nil then
  begin
    ProdCardTitle.Caption := SNewProd;
    ProdName.Text := ''; ProdCode.Text := ''; ProdPrice.Text := ''; ProdCost.Text := '';
    ProdSave.Enabled := True;
    ProdInfo.Caption := SProdHint;
    Exit;
  end;
  ProdCardTitle.Caption := SShowProd;
  ProdName.Text := JStr(P, 'name');
  ProdCode.Text := JStr(P, 'code');
  ProdPrice.Text := FormatFloat('0.##', JNum(P, 'price'), F);
  ProdCost.Text := FormatFloat('0.##', JNum(P, 'cost'), F);
  // Solo se cambia aquí lo que aún no está en Odoo.
  ProdSave.Enabled := JInt(P, 'id') = 0;
  if JInt(P, 'id') = 0 then ProdInfo.Caption := Format(SProdLocal, [JStr(P, 'ref')])
  else ProdInfo.Caption := Format(SProdOdoo, [JInt(P, 'id')]);
end;

procedure TForm1.ProdList_select;
begin
  if (ProdList.ItemIndex >= 0) and (ProdList.ItemIndex <= High(ProdRows)) then
    ShowProduct(Store.List('products').Objects[ProdRows[ProdList.ItemIndex]]);
end;

procedure TForm1.ProdNew_click;
begin
  ProdList.ItemIndex := -1;
  ShowProduct(nil);
  if PageNo = 2 then ProdName.SetFocus;
end;

{ Un número escrito con coma o punto decimal; -1 si no lo es. }
function ReadNumber(const S: string): Double;
var
  F: TFormatSettings;
  T: string;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := '.';
  T := StringReplace(Trim(S), ' ', '', [rfReplaceAll]);
  if T = '' then Exit(0);
  // «1.234,5» → «1234.5»; «1234.5» se queda.
  if (Pos(',', T) > 0) and (Pos('.', T) > 0) then T := StringReplace(T, '.', '', [rfReplaceAll]);
  T := StringReplace(T, ',', '.', []);
  Result := StrToFloatDef(T, -1, F);
end;

procedure TForm1.ProdSave_click;
var
  P: TJSONObject;
  A: TJSONArray;
  Price, Cost: Double;
  I: Integer;
  Code: string;
begin
  if Trim(ProdName.Text) = '' then
  begin
    ShowMessage(SProdNameReq);
    ProdName.SetFocus;
    Exit;
  end;
  Price := ReadNumber(ProdPrice.Text);
  Cost := ReadNumber(ProdCost.Text);
  if (Price < 0) or (Cost < 0) then
  begin
    ShowMessage(SBadPrice);
    Exit;
  end;
  Code := Trim(ProdCode.Text);
  A := Store.List('products');
  if Code <> '' then
    for I := 0 to A.Count - 1 do
      if (A.Objects[I] <> EditingProd) and SameText(JStr(A.Objects[I], 'code'), Code) then
      begin
        ShowMessage(Format(SDupCode, [Code]));
        ProdCode.SetFocus;
        Exit;
      end;
  if EditingProd = nil then P := Store.AddProduct(ProdName.Text, Code, Price, Cost)
  else
  begin
    // Uno de aquí que aún no se envió: su «crear» llevará estos datos.
    P := EditingProd;
    P.Strings['name'] := Trim(ProdName.Text);
    if Code <> '' then P.Strings['code'] := Code else P.Strings['code'] := JStr(P, 'ref');
    P.Floats['price'] := Price;
    P.Floats['cost'] := Cost;
    Store.Save;
  end;
  RefreshAll;
  ShowProduct(P);
  if Online and not SyncOffline.Checked then DoSync(True);
end;

// ---- pasos de un pedido: confirmar, facturar y registrar el pago

procedure TForm1.StepSelected(L: TListBox; const Rows: array of Integer;
  const Key: string; Step: Integer; PayKind: TComboBox);
var
  O: TJSONObject;
  Msg, Pay: string;
begin
  O := nil;
  if (L.ItemIndex >= 0) and (L.ItemIndex <= High(Rows)) then
    O := Store.List(Key).Objects[Rows[L.ItemIndex]];
  if PayKind.ItemIndex = 1 then Pay := 'cash' else Pay := 'bank';
  Msg := Store.SetStep(O, Step, Pay);
  if Msg <> '' then
  begin
    ShowMessage(Msg);
    Exit;
  end;
  RefreshAll;
  // Con conexión se envía ya; sin ella, espera en la bandeja de salida.
  if Online and not SyncOffline.Checked then DoSync(True);
end;

procedure TForm1.SaleConfirm_click;
begin
  StepSelected(SaleList, SaleRows, 'orders', 1, SalePayKind);
end;

procedure TForm1.SaleInvoice_click;
begin
  StepSelected(SaleList, SaleRows, 'orders', 2, SalePayKind);
end;

procedure TForm1.SalePay_click;
begin
  StepSelected(SaleList, SaleRows, 'orders', 3, SalePayKind);
end;

// ---- compras

procedure TForm1.NavPurchases_click;
begin
  ShowPage(8);
end;

procedure TForm1.RefreshPurchases;
var
  A: TJSONArray;
  O: TJSONObject;
  I, K: Integer;
  Keep: string;
  Total: Double;
begin
  A := Store.List('purchases');
  Keep := '';
  if (PurList.ItemIndex >= 0) and (PurList.ItemIndex <= High(PurRows)) and
    (PurRows[PurList.ItemIndex] < A.Count) then
    Keep := OrderKey(A.Objects[PurRows[PurList.ItemIndex]]);
  SetLength(PurRows, 0);
  Total := 0;
  PurList.Items.BeginUpdate;
  try
    PurList.Items.Clear;
    for I := 0 to A.Count - 1 do
    begin
      O := A.Objects[I];
      K := StateKind(O);
      case PurFilter.ItemIndex of
        1: if K <> 0 then Continue;
        2: if K <> 1 then Continue;
        3: if K <> 3 then Continue;
      end;
      if not Matches(PurSearch.Text, [OrderTitle(O), JStr(O, 'partner'),
        JStr(O, 'ref')]) then Continue;
      SetLength(PurRows, Length(PurRows) + 1);
      PurRows[High(PurRows)] := I;
      PurList.Items.Add(OrderTitle(O));
      if (Keep <> '') and (OrderKey(O) = Keep) then PurList.ItemIndex := High(PurRows);
      Total := Total + JNum(O, 'amount');
    end;
  finally
    PurList.Items.EndUpdate;
  end;
  PurCount.Caption := Format(SPurCount, [Length(PurRows), Money(Total)]);
end;

{ Los contactos (los proveedores primero) y los productos de la solicitud. }
procedure TForm1.RefreshPurChoices;
var
  A: TJSONArray;
  P: TJSONObject;
  Sorted: TStringList;
  I, Keep: Integer;
  S: string;
begin
  Keep := -1;
  if (PurSupp.ItemIndex >= 0) and (PurSupp.ItemIndex <= High(PurSuppChoice)) then
    Keep := PurSuppChoice[PurSupp.ItemIndex];
  A := Store.List('partners');
  Sorted := TStringList.Create;
  try
    for I := 0 to A.Count - 1 do
      if JBool(A.Objects[I], 'supplier') then
        Sorted.AddObject('0' + JStr(A.Objects[I], 'name'), TObject(PtrInt(I)))
      else
        Sorted.AddObject('1' + JStr(A.Objects[I], 'name'), TObject(PtrInt(I)));
    Sorted.CaseSensitive := False;
    Sorted.Sort;
    SetLength(PurSuppChoice, Sorted.Count);
    PurSupp.Items.BeginUpdate;
    try
      PurSupp.Items.Clear;
      for I := 0 to Sorted.Count - 1 do
      begin
        PurSuppChoice[I] := PtrInt(Sorted.Objects[I]);
        S := Copy(Sorted[I], 2, MaxInt);
        if Sorted[I][1] = '0' then S := S + '  (' + SSupplierTag + ')';
        PurSupp.Items.Add(S);
        if PurSuppChoice[I] = Keep then PurSupp.ItemIndex := I;
      end;
    finally
      PurSupp.Items.EndUpdate;
    end;
  finally
    Sorted.Free;
  end;
  Keep := PurProd.ItemIndex;
  A := Store.List('products');
  PurProd.Items.BeginUpdate;
  try
    PurProd.Items.Clear;
    for I := 0 to A.Count - 1 do
    begin
      P := A.Objects[I];
      S := JStr(P, 'name');
      if JStr(P, 'code') <> '' then S := '[' + JStr(P, 'code') + '] ' + S;
      PurProd.Items.Add(S + ' — ' + Money(JNum(P, 'cost')));
    end;
  finally
    PurProd.Items.EndUpdate;
  end;
  if Keep < PurProd.Items.Count then PurProd.ItemIndex := Keep;
end;

procedure TForm1.RefreshPurDraft;
var
  I: Integer;
  L: TJSONObject;
  Total: Double;
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  Total := 0;
  PurLines.Items.BeginUpdate;
  try
    PurLines.Items.Clear;
    for I := 0 to PurDraft.Count - 1 do
    begin
      L := PurDraft.Objects[I];
      PurLines.Items.Add(FormatFloat('0.##', JNum(L, 'qty'), F) + ' × ' +
        JStr(L, 'name') + ' — ' + Money(JNum(L, 'qty') * JNum(L, 'price')));
      Total := Total + JNum(L, 'qty') * JNum(L, 'price');
    end;
  finally
    PurLines.Items.EndUpdate;
  end;
  PurTotal.Caption := Format(STotalNoTax, [Money(Total)]);
end;

procedure TForm1.PurFilter_select;
begin
  RefreshPurchases;
end;

procedure TForm1.PurNew_click;
begin
  PurDraft.Clear;
  PurSupp.ItemIndex := -1;
  PurQty.Text := '1';
  PurPrice.Text := '';
  RefreshPurChoices;
  RefreshPurDraft;
  if PurSupp.Items.Count = 0 then ShowMessage(SNoSuppliers);
end;

procedure TForm1.PurList_double;
begin
  if (PurList.ItemIndex >= 0) and (PurList.ItemIndex <= High(PurRows)) then
    ShowOrder(Store.List('purchases').Objects[PurRows[PurList.ItemIndex]]);
end;

procedure TForm1.PurProd_select;
var
  F: TFormatSettings;
begin
  if PurProd.ItemIndex < 0 then Exit;
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  PurPrice.Text := FormatFloat('0.##',
    JNum(Store.List('products').Objects[PurProd.ItemIndex], 'cost'), F);
end;

procedure TForm1.PurAdd_click;
var
  P, L: TJSONObject;
  Q, Pr: Double;
  I: Integer;
begin
  if PurProd.ItemIndex < 0 then
  begin
    ShowMessage(SChooseProd);
    Exit;
  end;
  Q := ReadNumber(PurQty.Text);
  if Q <= 0 then
  begin
    ShowMessage(SBadQty);
    PurQty.SetFocus;
    Exit;
  end;
  P := Store.List('products').Objects[PurProd.ItemIndex];
  if Trim(PurPrice.Text) = '' then Pr := JNum(P, 'cost')
  else Pr := ReadNumber(PurPrice.Text);
  if Pr < 0 then
  begin
    ShowMessage(SBadPrice);
    PurPrice.SetFocus;
    Exit;
  end;
  for I := 0 to PurDraft.Count - 1 do
    if SameProduct(PurDraft.Objects[I], P) and (JNum(PurDraft.Objects[I], 'price') = Pr) then
    begin
      L := PurDraft.Objects[I];
      L.Floats['qty'] := JNum(L, 'qty') + Q;
      RefreshPurDraft;
      Exit;
    end;
  PurDraft.Add(TJSONObject.Create(['product_id', JInt(P, 'id'), 'product_ref',
    JStr(P, 'ref'), 'name', JStr(P, 'name'), 'qty', Q, 'price', Pr,
    'uom', JInt(P, 'uom')]));
  PurQty.Text := '1';
  RefreshPurDraft;
end;

procedure TForm1.PurDel_click;
begin
  if PurLines.ItemIndex < 0 then Exit;
  PurDraft.Delete(PurLines.ItemIndex);
  RefreshPurDraft;
end;

procedure TForm1.PurSave_click;
var
  P: TJSONObject;
begin
  if (PurSupp.ItemIndex < 0) or (PurSupp.ItemIndex > High(PurSuppChoice)) then
  begin
    ShowMessage(SChooseSupp);
    Exit;
  end;
  if PurDraft.Count = 0 then
  begin
    ShowMessage(SNoLines);
    Exit;
  end;
  P := Store.List('partners').Objects[PurSuppChoice[PurSupp.ItemIndex]];
  Store.AddPurchase(P, PurDraft); // la solicitud se queda con las líneas
  PurDraft := TJSONArray.Create;
  RefreshPurDraft;
  PurFilter.ItemIndex := 0;
  PurList.ItemIndex := -1;
  RefreshAll;
  PurList.ItemIndex := 0;
  if Online and not SyncOffline.Checked then DoSync(True);
  ShowMessage(SPurSaved);
end;

procedure TForm1.PurConfirm_click;
begin
  StepSelected(PurList, PurRows, 'purchases', 1, PurPayKind);
end;

procedure TForm1.PurBill_click;
begin
  StepSelected(PurList, PurRows, 'purchases', 2, PurPayKind);
end;

procedure TForm1.PurPay_click;
begin
  StepSelected(PurList, PurRows, 'purchases', 3, PurPayKind);
end;

// ---- página de sincronización

procedure TForm1.SyncNow_click;
begin
  DoSync(False);
end;

procedure TForm1.SyncReload_click;
begin
  Client.Reset;
  DoSync(False);
end;

procedure TForm1.SyncAuto_click;
begin
  SaveSettings;
end;

procedure TForm1.SyncOffline_click;
begin
  SaveSettings;
  if SyncOffline.Checked then Online := False
  else if Configured then StartPing;
  RefreshStatus;
end;

procedure TForm1.OutboxDiscard_click;
var
  Op, R: TJSONObject;
  K: string;
  A: TJSONArray;
  I, J: Integer;
begin
  if Outbox.ItemIndex < 0 then
  begin
    ShowMessage(SChooseOp);
    Exit;
  end;
  if not Ask(SDiscardAsk) then Exit;
  Op := Store.List('outbox').Objects[Outbox.ItemIndex];
  K := JStr(Op, 'op');
  R := nil;
  if K = 'bim_project' then
  begin
    // La obra y sus presupuestos que aún no están en Odoo se borran.
    R := Store.Find('bim_projects', 0, JStr(Op, 'ref'));
    if (R <> nil) and (JInt(R, 'id') = 0) then
    begin
      A := Store.List('bim_budgets');
      for I := A.Count - 1 downto 0 do
        if (JStr(A.Objects[I], 'project_ref') = JStr(R, 'ref')) and
          (JInt(A.Objects[I], 'id') = 0) then
        begin
          for J := Store.List('outbox').Count - 1 downto 0 do
            if (JStr(Store.List('outbox').Objects[J], 'op') = 'bim_budget') and
              (JStr(Store.List('outbox').Objects[J], 'ref') = JStr(A.Objects[I], 'ref')) then
              Store.List('outbox').Delete(J);
          A.Delete(I);
        end;
      Store.List('bim_projects').Remove(R);
    end;
    R := nil;
  end
  else if K = 'bim_budget' then
  begin
    // Vuelve a ser un borrador (si aún no está en Odoo).
    R := Store.Find('bim_budgets', 0, JStr(Op, 'ref'));
    if (R <> nil) and (JInt(R, 'id') = 0) then
    begin
      R.Booleans['queued'] := False;
      R.Booleans['pending'] := True;
    end;
    R := nil;
  end
  else if (K = 'order_create') or (K = 'pos_sale') then
  begin
    // Lo que ya está en Odoo se queda en la lista; lo que no, se borra.
    A := Store.List('orders');
    R := Store.Find('orders', 0, JStr(Op, 'ref'));
    if (R <> nil) and (JInt(R, 'id') = 0) then A.Remove(R)
    else if R <> nil then
    begin
      R.Integers['want'] := OrderLevel(R);
      R.Booleans['pending'] := False;
    end;
    R := nil;
  end
  else if K = 'purchase_create' then
  begin
    A := Store.List('purchases');
    R := Store.Find('purchases', 0, JStr(Op, 'ref'));
    if (R <> nil) and (JInt(R, 'id') = 0) then A.Remove(R)
    else if R <> nil then
    begin
      R.Integers['want'] := OrderLevel(R);
      R.Booleans['pending'] := False;
    end;
    R := nil;
  end
  else if (K = 'order_step') or (K = 'purchase_step') then
  begin
    // El paso pedido se olvida: el pedido vuelve a como está en Odoo.
    if K = 'order_step' then R := Store.Find('orders', JInt(Op, 'id'), '')
    else R := Store.Find('purchases', JInt(Op, 'id'), '');
    if R <> nil then
    begin
      R.Integers['want'] := OrderLevel(R);
      R.Booleans['pending'] := False;
      R.Strings['error'] := '';
    end;
    R := nil;
  end
  else if K = 'product_create' then
  begin
    A := Store.List('products');
    R := Store.Find('products', 0, JStr(Op, 'ref'));
    if (R <> nil) and (JInt(R, 'id') = 0) then
    begin
      if EditingProd = R then ShowProduct(nil);
      A.Remove(R);
    end;
    R := nil;
  end
  else if K = 'partner_create' then
  begin
    A := Store.List('partners');
    R := Store.Find('partners', 0, JStr(Op, 'ref'));
    if R <> nil then A.Remove(R);
  end
  else
  begin
    R := Store.Find('partners', JInt(Op, 'id'), '');
    if R <> nil then R.Booleans['pending'] := False;
  end;
  Store.List('outbox').Remove(Op);
  Store.Save;
  if Editing = R then ShowCustomer(nil);
  RefreshAll;
end;

// ---- página de configuración

procedure TForm1.CfgDetect_click;
var
  L: TStringList;
begin
  SaveSettings;
  SetBusy(True);
  try
    try
      L := Client.Databases;
      try
        if L.Count = 1 then
        begin
          CfgDb.Text := L[0];
          CfgResult.Caption := Format(SOneDb, [L[0]]);
        end
        else if L.Count = 0 then CfgResult.Caption := SNoDbList
        else CfgResult.Caption := Format(SManyDbs, [L.CommaText]);
        CfgResult.Font.Color := CInk;
      finally
        L.Free;
      end;
    except
      on E: Exception do
      begin
        CfgResult.Font.Color := clRed;
        CfgResult.Caption := E.Message;
      end;
    end;
  finally
    SetBusy(False);
  end;
  SaveSettings;
end;

procedure TForm1.CfgTest_click;
begin
  SaveSettings;
  SetBusy(True);
  try
    try
      Sync.Connect;
      Online := True;
      CfgDb.Text := Client.Db;
      CfgResult.Font.Color := CGreen;
      CfgResult.Caption := Format(STestOk, [Client.Version, Client.Db]);
    except
      on E: Exception do
      begin
        Online := False;
        CfgResult.Font.Color := clRed;
        CfgResult.Caption := E.Message;
      end;
    end;
  finally
    SetBusy(False);
  end;
  SaveSettings;
end;

procedure TForm1.CfgConnect_click;
begin
  CfgTest_click;
  if Online then
  begin
    DoSync(False);
    ShowPage(0);
  end;
end;

procedure TForm1.CfgReset_click;
begin
  if Store.Pending > 0 then
  begin
    if not Ask(Format(SResetPending, [Store.Pending])) then Exit;
  end
  else if not Ask(SResetAsk) then Exit;
  Store.Clear;
  Draft.Clear;
  ShowCustomer(nil);
  RefreshDraft;
  RefreshAll;
end;

// ---- dibujo de las listas

procedure Row(C: TCanvas; R: TRect; Selected: Boolean);
begin
  C.Brush.Style := bsSolid;
  if Selected then C.Brush.Color := CSel
  else C.Brush.Color := clWhite;
  C.FillRect(R);
  if Selected then
  begin
    C.Brush.Color := CBlue;
    C.FillRect(Rect(R.Left, R.Top, R.Left + 3, R.Bottom));
  end;
  C.Pen.Color := CLine;
  C.Line(R.Left + 10, R.Bottom - 1, R.Right, R.Bottom - 1);
  C.Brush.Style := bsClear;
end;

procedure Say(C: TCanvas; X, Y: Integer; const S: string; Color: TColor;
  Size: Integer; Bold: Boolean; MaxW: Integer);
begin
  C.Font.Color := Color;
  C.Font.Size := Size;
  if Bold then C.Font.Style := [fsBold] else C.Font.Style := [];
  C.TextOut(X, Y, Fit(C, S, MaxW));
end;

procedure TextRight(C: TCanvas; Right, Y: Integer; const S: string;
  Color: TColor; Size: Integer; Bold: Boolean);
begin
  C.Font.Color := Color;
  C.Font.Size := Size;
  if Bold then C.Font.Style := [fsBold] else C.Font.Style := [];
  C.TextOut(Right - C.TextWidth(S), Y, S);
end;

{ Una etiqueta de color con el texto dentro; devuelve su ancho. }
function Pill(C: TCanvas; X, Y: Integer; const S: string; Color: TColor): Integer;
begin
  C.Font.Size := 8;
  C.Font.Style := [fsBold];
  Result := C.TextWidth(S) + 14;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Color;
  C.Pen.Color := Color;
  C.RoundRect(X, Y, X + Result, Y + C.TextHeight(S) + 4, 10, 10);
  C.Brush.Style := bsClear;
  C.Font.Color := clWhite;
  C.TextOut(X + 7, Y + 2, S);
end;

procedure TForm1.DrawCustomer(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  P: TJSONObject;
  Sub: string;
  Parts: array[0..2] of string;
  W, I: Integer;
begin
  if (Index < 0) or (Index > High(CustRows)) then Exit;
  C := TListBox(Control).Canvas;
  P := Store.List('partners').Objects[CustRows[Index]];
  Row(C, ARect, odSelected in State);
  W := 0;
  if JBool(P, 'pending') then
  begin
    C.Font.Size := 8;
    W := C.TextWidth(SPendingTag) + 24;
    Pill(C, ARect.Right - W, ARect.Top + 6, SPendingTag, COrange);
  end;
  if JBool(P, 'supplier') then
  begin
    C.Font.Size := 8;
    W := W + C.TextWidth(SSupplierTag) + 20;
    Pill(C, ARect.Right - W, ARect.Top + 6, SSupplierTag, CPurple);
  end;
  Say(C, ARect.Left + 14, ARect.Top + 5, JStr(P, 'name'), CInk, 10, True,
    ARect.Right - ARect.Left - 28 - W);
  Parts[0] := JStr(P, 'email');
  Parts[1] := JStr(P, 'phone');
  Parts[2] := JStr(P, 'city');
  Sub := '';
  for I := 0 to 2 do
    if Parts[I] <> '' then
      if Sub = '' then Sub := Parts[I] else Sub := Sub + '  ·  ' + Parts[I];
  Say(C, ARect.Left + 14, ARect.Top + 25, Sub, CMuted, 9, False,
    ARect.Right - ARect.Left - 28);
end;

procedure TForm1.DrawProduct(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  P: TJSONObject;
  Stock: string;
  F: TFormatSettings;
  W: Integer;
begin
  if (Index < 0) or (Index > High(ProdRows)) then Exit;
  C := TListBox(Control).Canvas;
  P := Store.List('products').Objects[ProdRows[Index]];
  Row(C, ARect, odSelected in State);
  Say(C, ARect.Left + 12, ARect.Top + 6, JStr(P, 'code'), CMuted, 9, False, 86);
  if JBool(P, 'pending') then
  begin
    C.Font.Size := 8;
    W := C.TextWidth(SPendingTag) + 18;
    Pill(C, ARect.Left + 296 - W, ARect.Top + 6, SPendingTag, COrange);
  end
  else W := 0;
  Say(C, ARect.Left + 104, ARect.Top + 6, JStr(P, 'name'), CInk, 10, False, 186 - W);
  TextRight(C, ARect.Left + 410, ARect.Top + 6, Money(JNum(P, 'price')), CInk, 10, True);
  if P.Find('qty') <> nil then
  begin
    F := DefaultFormatSettings;
    F.DecimalSeparator := Decimals;
    F.ThousandSeparator := Thousands;
    Stock := FormatFloat('#,##0.##', JNum(P, 'qty'), F);
  end
  else Stock := SNoStock;
  if JNum(P, 'qty') < 0 then
    TextRight(C, ARect.Left + 498, ARect.Top + 6, Stock, clRed, 10, False)
  else
    TextRight(C, ARect.Left + 498, ARect.Top + 6, Stock, CMuted, 10, False);
end;

procedure DrawOrderRow(C: TCanvas; O: TJSONObject; R: TRect; Selected: Boolean);
var
  K, W: Integer;
begin
  Row(C, R, Selected);
  K := StateKind(O);
  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  W := C.TextWidth(Money(JNum(O, 'amount')));
  Say(C, R.Left + 14, R.Top + 5, OrderTitle(O) + '   ' + JStr(O, 'partner'),
    CInk, 10, True, R.Right - R.Left - W - 40);
  TextRight(C, R.Right - 12, R.Top + 5, Money(JNum(O, 'amount')), CInk, 10, True);
  Say(C, R.Left + 14, R.Top + 24, ShortDate(JStr(O, 'date')), CMuted, 9, False, 90);
  C.Font.Size := 8;
  C.Font.Style := [fsBold];
  Pill(C, R.Right - 24 - C.TextWidth(StateLabel(O)), R.Top + 23, StateLabel(O),
    StateColor(O));
end;

procedure TForm1.DrawSale(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
begin
  if (Index < 0) or (Index > High(SaleRows)) then Exit;
  DrawOrderRow(TListBox(Control).Canvas,
    Store.List('orders').Objects[SaleRows[Index]], ARect, odSelected in State);
end;

procedure TForm1.DrawPurchase(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
begin
  if (Index < 0) or (Index > High(PurRows)) then Exit;
  DrawOrderRow(TListBox(Control).Canvas,
    Store.List('purchases').Objects[PurRows[Index]], ARect, odSelected in State);
end;

procedure TForm1.DrawRecent(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  O: TJSONObject;
begin
  if (Index < 0) or (Index > High(RecentRows)) then Exit;
  C := TListBox(Control).Canvas;
  O := Store.List('orders').Objects[RecentRows[Index]];
  Row(C, ARect, odSelected in State);
  C.Font.Size := 9;
  C.Font.Style := [fsBold];
  Say(C, ARect.Left + 10, ARect.Top + 3, OrderTitle(O), CInk, 9, True, 150);
  Say(C, ARect.Left + 10, ARect.Top + 19, JStr(O, 'partner'), CMuted, 8, False, 200);
  TextRight(C, ARect.Right - 10, ARect.Top + 3, Money(JNum(O, 'amount')), CInk, 9, True);
  C.Font.Size := 8;
  C.Font.Style := [fsBold];
  Pill(C, ARect.Right - 24 - C.TextWidth(StateLabel(O)), ARect.Top + 18,
    StateLabel(O), StateColor(O));
end;

procedure TForm1.DrawOutbox(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  Op: TJSONObject;
begin
  if (Index < 0) or (Index >= Store.List('outbox').Count) then Exit;
  C := TListBox(Control).Canvas;
  Op := Store.List('outbox').Objects[Index];
  Row(C, ARect, odSelected in State);
  Say(C, ARect.Left + 14, ARect.Top + 5, Describe(Store, Op), CInk, 10, True,
    ARect.Right - ARect.Left - 28);
  if JStr(Op, 'error') <> '' then
    Say(C, ARect.Left + 14, ARect.Top + 25, Format(SOpError, [JStr(Op, 'error')]),
      clRed, 9, False, ARect.Right - ARect.Left - 28)
  else
    Say(C, ARect.Left + 14, ARect.Top + 25, Format(SOpWaiting,
      [ShortDate(JStr(Op, 'at')) + ' ' + Copy(JStr(Op, 'at'), 12, 5)]), CMuted, 9,
      False, ARect.Right - ARect.Left - 28);
end;

// ---- gráficos

procedure ChartFrame(C: TCanvas; W, H: Integer; const Title: string);
begin
  C.Brush.Style := bsSolid;
  C.Brush.Color := clWhite;
  C.FillRect(0, 0, W, H);
  C.Brush.Style := bsClear;
  Say(C, 16, 10, Title, CInk, 11, True, W - 32);
end;

procedure EmptyNote(C: TCanvas; W, H: Integer);
begin
  C.Font.Size := 9;
  C.Font.Style := [];
  C.Font.Color := CMuted;
  C.TextOut((W - C.TextWidth(SNoData)) div 2, H div 2, Fit(C, SNoData, W - 20));
end;

{ Un tope «redondo» para el eje: 1, 2, 2,5 o 5 por una potencia de diez. }
function NiceMax(V: Double): Double;
var
  M: Double;
begin
  if V <= 0 then Exit(1);
  M := Power(10, Floor(Log10(V)));
  if V <= M then Result := M
  else if V <= 2 * M then Result := 2 * M
  else if V <= 2.5 * M then Result := 2.5 * M
  else if V <= 5 * M then Result := 5 * M
  else Result := 10 * M;
end;

procedure TForm1.PaintMonth(Sender: TObject);
var
  B: TPaintBox;
  C: TCanvas;
  Conf, Quote: array[0..11] of Double;
  Keys: array[0..11] of string;
  Orders: TJSONArray;
  O: TJSONObject;
  I, J, X, W, H, L, T, R, Bm, Slot, BW, Y1, Y2: Integer;
  Peak, Any: Double;
begin
  B := TPaintBox(Sender);
  C := B.Canvas;
  W := B.Width;
  H := B.Height;
  ChartFrame(C, W, H, SChartMonth);
  // Leyenda.
  C.Font.Size := 8;
  C.Font.Style := [];
  X := W - 16 - C.TextWidth(SLegendQuotes);
  C.Font.Color := CMuted;
  C.TextOut(X, 13, SLegendQuotes);
  C.Brush.Style := bsSolid;
  C.Brush.Color := CBlueSoft;
  C.FillRect(X - 14, 15, X - 4, 25);
  X := X - 30 - C.TextWidth(SLegendOrders);
  C.Brush.Color := CBlue;
  C.FillRect(X - 14, 15, X - 4, 25);
  C.Brush.Style := bsClear;
  C.TextOut(X, 13, SLegendOrders);
  for I := 0 to 11 do
  begin
    Keys[I] := FormatDateTime('yyyy-mm', IncMonth(Now, I - 11));
    Conf[I] := 0;
    Quote[I] := 0;
  end;
  Orders := Store.List('orders');
  Any := 0;
  for J := 0 to Orders.Count - 1 do
  begin
    O := Orders.Objects[J];
    for I := 0 to 11 do
      if Copy(JStr(O, 'date'), 1, 7) = Keys[I] then
      begin
        case StateKind(O) of
          1: Conf[I] := Conf[I] + JNum(O, 'amount');
          0, 3: Quote[I] := Quote[I] + JNum(O, 'amount');
        end;
        Break;
      end;
  end;
  Peak := 0;
  for I := 0 to 11 do
  begin
    Peak := Max(Peak, Conf[I] + Quote[I]);
    Any := Any + Conf[I] + Quote[I];
  end;
  if Any <= 0 then
  begin
    EmptyNote(C, W, H);
    Exit;
  end;
  Peak := NiceMax(Peak);
  L := 58; T := 44; R := W - 16; Bm := H - 28;
  // Rejilla y eje.
  C.Font.Size := 8;
  C.Font.Style := [];
  for I := 0 to 4 do
  begin
    Y1 := Bm - Round((Bm - T) * I / 4);
    C.Pen.Color := CLine;
    C.Line(L, Y1, R, Y1);
    C.Font.Color := CMuted;
    C.TextOut(L - 8 - C.TextWidth(Compact(Peak * I / 4)), Y1 - 7, Compact(Peak * I / 4));
  end;
  Slot := (R - L) div 12;
  BW := Max(6, Slot * 3 div 5);
  for I := 0 to 11 do
  begin
    X := L + I * Slot + (Slot - BW) div 2;
    Y1 := Bm - Round((Bm - T) * Conf[I] / Peak);
    Y2 := Y1 - Round((Bm - T) * Quote[I] / Peak);
    C.Brush.Style := bsSolid;
    if Conf[I] > 0 then
    begin
      C.Brush.Color := CBlue;
      C.FillRect(X, Y1, X + BW, Bm);
    end;
    if Quote[I] > 0 then
    begin
      C.Brush.Color := CBlueSoft;
      C.FillRect(X, Y2, X + BW, Y1);
    end;
    C.Brush.Style := bsClear;
    C.Font.Color := CMuted;
    C.TextOut(X + (BW - C.TextWidth(Part(SMonths, StrToInt(Copy(Keys[I], 6, 2)) - 1))) div 2,
      Bm + 6, Part(SMonths, StrToInt(Copy(Keys[I], 6, 2)) - 1));
  end;
end;

{ Un sector de un anillo, como polígono (igual en todas las plataformas). }
procedure Ring(C: TCanvas; CX, CY, R1, R2: Integer; A0, A1: Double; Color: TColor);
var
  Pts: array of TPoint;
  N, I: Integer;
  A: Double;
begin
  N := Max(2, Round((A1 - A0) / 2) + 1);
  SetLength(Pts, N * 2);
  for I := 0 to N - 1 do
  begin
    A := DegToRad(A0 + (A1 - A0) * I / (N - 1) - 90);
    Pts[I] := Point(CX + Round(R2 * Cos(A)), CY + Round(R2 * Sin(A)));
    Pts[2 * N - 1 - I] := Point(CX + Round(R1 * Cos(A)), CY + Round(R1 * Sin(A)));
  end;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Color;
  C.Pen.Color := Color;
  C.Polygon(Pts);
end;

procedure TForm1.PaintState(Sender: TObject);
var
  B: TPaintBox;
  C: TCanvas;
  Counts: array[0..3] of Integer;
  Names: array[0..3] of string;
  Orders: TJSONArray;
  I, Total, W, H, CX, CY, R, Y: Integer;
  A: Double;
begin
  B := TPaintBox(Sender);
  C := B.Canvas;
  W := B.Width;
  H := B.Height;
  ChartFrame(C, W, H, SChartState);
  Names[0] := SLegendQuotes; Names[1] := SLegendOrders;
  Names[2] := SStCancel; Names[3] := SStPending;
  for I := 0 to 3 do Counts[I] := 0;
  Orders := Store.List('orders');
  for I := 0 to Orders.Count - 1 do Inc(Counts[StateKind(Orders.Objects[I])]);
  Total := Counts[0] + Counts[1] + Counts[2] + Counts[3];
  if Total = 0 then
  begin
    EmptyNote(C, W, H);
    Exit;
  end;
  R := Min(W div 2 - 30, H - 70) div 2 + 6;
  CX := 20 + R;
  CY := 40 + (H - 40) div 2;
  A := 0;
  for I := 0 to 3 do
    if Counts[I] > 0 then
    begin
      Ring(C, CX, CY, R - 18, R, A, A + 360 * Counts[I] / Total, KindColor(I));
      A := A + 360 * Counts[I] / Total;
    end;
  C.Brush.Style := bsClear;
  C.Font.Size := 15;
  C.Font.Style := [fsBold];
  C.Font.Color := CInk;
  C.TextOut(CX - C.TextWidth(IntToStr(Total)) div 2, CY - 16, IntToStr(Total));
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := CMuted;
  C.TextOut(CX - C.TextWidth(STotalOrders) div 2, CY + 6, STotalOrders);
  // Leyenda.
  Y := CY - 44;
  for I := 0 to 3 do
  begin
    C.Brush.Style := bsSolid;
    C.Brush.Color := KindColor(I);
    C.FillRect(CX + R + 18, Y + 4, CX + R + 28, Y + 14);
    C.Brush.Style := bsClear;
    Say(C, CX + R + 34, Y, Names[I], CInk, 9, False, W - (CX + R + 34) - 34);
    TextRight(C, W - 14, Y, IntToStr(Counts[I]), CInk, 9, True);
    Inc(Y, 24);
  end;
end;

procedure TForm1.PaintTop(Sender: TObject);
var
  B: TPaintBox;
  C: TCanvas;
  Names: TStringList;
  Sums: array of Double;
  Orders: TJSONArray;
  O: TJSONObject;
  I, J, K, Best, W, H, Y, BarL, BarR: Integer;
  Peak: Double;
  OnlyConfirmed: Boolean;
begin
  B := TPaintBox(Sender);
  C := B.Canvas;
  W := B.Width;
  H := B.Height;
  ChartFrame(C, W, H, SChartTop);
  Orders := Store.List('orders');
  // Con pedidos confirmados, solo esos; si no, también los presupuestos.
  OnlyConfirmed := False;
  for I := 0 to Orders.Count - 1 do
    if StateKind(Orders.Objects[I]) = 1 then OnlyConfirmed := True;
  Names := TStringList.Create;
  try
    for I := 0 to Orders.Count - 1 do
    begin
      O := Orders.Objects[I];
      K := StateKind(O);
      if (K = 2) or (OnlyConfirmed and (K <> 1)) then Continue;
      J := Names.IndexOf(JStr(O, 'partner'));
      if J < 0 then
      begin
        J := Names.Add(JStr(O, 'partner'));
        SetLength(Sums, Names.Count);
        Sums[J] := 0;
      end;
      Sums[J] := Sums[J] + JNum(O, 'amount');
    end;
    if Names.Count = 0 then
    begin
      EmptyNote(C, W, H);
      Exit;
    end;
    Peak := 0;
    for I := 0 to High(Sums) do Peak := Max(Peak, Sums[I]);
    if Peak <= 0 then Peak := 1;
    BarL := 150;
    BarR := W - 100;
    Y := 44;
    for K := 1 to Min(6, Names.Count) do
    begin
      Best := 0;
      for I := 1 to High(Sums) do
        if Sums[I] > Sums[Best] then Best := I;
      if Sums[Best] < 0 then Break;
      Say(C, 16, Y + 4, Names[Best], CInk, 9, False, BarL - 26);
      C.Brush.Style := bsSolid;
      C.Brush.Color := $00F7F3F0;
      C.FillRect(BarL, Y + 3, BarR, Y + 21);
      C.Brush.Color := CPurple;
      C.FillRect(BarL, Y + 3, BarL + Max(2, Round((BarR - BarL) * Sums[Best] / Peak)), Y + 21);
      C.Brush.Style := bsClear;
      TextRight(C, W - 14, Y + 4, Compact(Sums[Best]), CInk, 9, True);
      Sums[Best] := -1;
      Inc(Y, 30);
    end;
  finally
    Names.Free;
  end;
end;

// ---- punto de venta

const
  PosCols = 4;
  PosRowsPerPage = 5;
  PosGap = 8;

{ Un número escrito con coma o punto. }
function ParseNum(const S: string; out V: Double): Boolean;
var
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := '.';
  Result := TryStrToFloat(StringReplace(Trim(S), ',', '.', []), V, F);
end;

function CategColor(const Cat: string): TColor;
const
  Palette: array[0..5] of TColor = (CBlue, CGreen, CPurple, COrange,
    $00808000, $00A0522D);
var
  I, H: Integer;
begin
  H := 0;
  for I := 1 to Length(Cat) do H := (H * 31 + Ord(Cat[I])) and $FFFF;
  Result := Palette[H mod Length(Palette)];
end;

procedure TForm1.RefreshPosCustomers;
var
  A: TJSONArray;
  Sorted: TStringList;
  I, Keep: Integer;
begin
  Keep := -1;
  if (PosCust.ItemIndex > 0) and (PosCust.ItemIndex - 1 <= High(PosCustRows)) then
    Keep := PosCustRows[PosCust.ItemIndex - 1];
  A := Store.List('partners');
  Sorted := TStringList.Create;
  try
    for I := 0 to A.Count - 1 do
      if JStr(A.Objects[I], 'ref') <> 'DMS-POS' then
        Sorted.AddObject(JStr(A.Objects[I], 'name'), TObject(PtrInt(I)));
    Sorted.CaseSensitive := False;
    Sorted.Sort;
    SetLength(PosCustRows, Sorted.Count);
    PosCust.Items.BeginUpdate;
    try
      PosCust.Items.Clear;
      PosCust.Items.Add(SCounter);
      PosCust.ItemIndex := 0;
      for I := 0 to Sorted.Count - 1 do
      begin
        PosCustRows[I] := PtrInt(Sorted.Objects[I]);
        PosCust.Items.Add(Sorted[I]);
      end;
      for I := 0 to High(PosCustRows) do
        if PosCustRows[I] = Keep then PosCust.ItemIndex := I + 1;
    finally
      PosCust.Items.EndUpdate;
    end;
  finally
    Sorted.Free;
  end;
end;

procedure TForm1.RefreshPos;
var
  A: TJSONArray;
  P: TJSONObject;
  Cats: TStringList;
  I, NPages: Integer;
  Keep, Cat: string;
begin
  A := Store.List('products');
  Keep := '';
  if PosCat.ItemIndex > 0 then Keep := PosCat.Items[PosCat.ItemIndex];
  Cats := TStringList.Create;
  try
    Cats.Sorted := True;
    Cats.Duplicates := dupIgnore;
    for I := 0 to A.Count - 1 do
      if JStr(A.Objects[I], 'categ') <> '' then Cats.Add(JStr(A.Objects[I], 'categ'));
    PosCat.Items.BeginUpdate;
    try
      PosCat.Items.Clear;
      PosCat.Items.Add(SAllCats);
      PosCat.Items.AddStrings(Cats);
    finally
      PosCat.Items.EndUpdate;
    end;
    PosCat.ItemIndex := Max(0, PosCat.Items.IndexOf(Keep));
  finally
    Cats.Free;
  end;
  Cat := '';
  if PosCat.ItemIndex > 0 then Cat := PosCat.Items[PosCat.ItemIndex];
  SetLength(PosRows, 0);
  for I := 0 to A.Count - 1 do
  begin
    P := A.Objects[I];
    if (Cat <> '') and (JStr(P, 'categ') <> Cat) then Continue;
    if not Matches(PosSearch.Text, [JStr(P, 'name'), JStr(P, 'code')]) then Continue;
    SetLength(PosRows, Length(PosRows) + 1);
    PosRows[High(PosRows)] := I;
  end;
  NPages := Max(1, (Length(PosRows) + PosCols * PosRowsPerPage - 1) div
    (PosCols * PosRowsPerPage));
  PosPageNo := Max(0, Min(PosPageNo, NPages - 1));
  PosPageLbl.Caption := Format(SPosPageN, [PosPageNo + 1, NPages, Length(PosRows)]);
  PosPrev.Enabled := PosPageNo > 0;
  PosNext.Enabled := PosPageNo < NPages - 1;
  PosBox.Invalidate;
  RefreshPosCustomers;
  RefreshCart;
end;

procedure TForm1.RefreshCart;
var
  I, Keep: Integer;
  Total: Double;
  L: TJSONObject;
begin
  Keep := PosLines.ItemIndex;
  Total := 0;
  PosLines.Items.BeginUpdate;
  try
    PosLines.Items.Clear;
    for I := 0 to Cart.Count - 1 do
    begin
      L := Cart.Objects[I];
      PosLines.Items.Add(JStr(L, 'name'));
      Total := Total + JNum(L, 'qty') * JNum(L, 'price') * (1 - JNum(L, 'discount') / 100);
    end;
  finally
    PosLines.Items.EndUpdate;
  end;
  if Keep < Cart.Count then PosLines.ItemIndex := Keep;
  PosTotal.Caption := Format(SPosTotal, [Money(Total)]);
  if Cart.Count = 0 then PosInfo.Caption := SPosEmpty
  else PosInfo.Caption := SPosInfo;
end;

procedure TForm1.PaintPos(Sender: TObject);
var
  B: TPaintBox;
  C: TCanvas;
  P: TJSONObject;
  K, Idx, X, Y, TW, TH: Integer;
  TS: TTextStyle;
  Sub: string;
begin
  B := TPaintBox(Sender);
  C := B.Canvas;
  C.Brush.Style := bsSolid;
  C.Brush.Color := $00F4F1EE;
  C.FillRect(0, 0, B.Width, B.Height);
  if Length(PosRows) = 0 then
  begin
    EmptyNote(C, B.Width, B.Height);
    Exit;
  end;
  TW := (B.Width - (PosCols - 1) * PosGap) div PosCols;
  TH := (B.Height - (PosRowsPerPage - 1) * PosGap) div PosRowsPerPage;
  for K := 0 to PosCols * PosRowsPerPage - 1 do
  begin
    Idx := PosPageNo * PosCols * PosRowsPerPage + K;
    if Idx > High(PosRows) then Break;
    P := Store.List('products').Objects[PosRows[Idx]];
    X := (K mod PosCols) * (TW + PosGap);
    Y := (K div PosCols) * (TH + PosGap);
    C.Brush.Style := bsSolid;
    C.Brush.Color := clWhite;
    C.Pen.Color := $00E2DCD6;
    C.RoundRect(X, Y, X + TW, Y + TH, 10, 10);
    C.Brush.Color := CategColor(JStr(P, 'categ'));
    C.FillRect(X + 1, Y + 6, X + 5, Y + TH - 6);
    C.Brush.Style := bsClear;
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Font.Color := CInk;
    TS := C.TextStyle;
    TS.Wordbreak := True;
    TS.SingleLine := False;
    TS.Clipping := True;
    C.TextRect(Rect(X + 12, Y + 8, X + TW - 8, Y + TH - 26), X + 12, Y + 8,
      JStr(P, 'name'), TS);
    Sub := JStr(P, 'code');
    if (P.Find('qty') <> nil) then
    begin
      if Sub <> '' then Sub := Sub + ' · ';
      Sub := Sub + FloatToStr(JNum(P, 'qty'));
    end;
    Say(C, X + 12, Y + TH - 22, Sub, CMuted, 8, False, TW - 90);
    TextRight(C, X + TW - 10, Y + TH - 23, Money(JNum(P, 'price')), CInk, 10, True);
  end;
end;

procedure TForm1.PosMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  TW, TH, Col, Row, Idx, I: Integer;
  P, L: TJSONObject;
begin
  if Button <> mbLeft then Exit;
  TW := (PosBox.Width - (PosCols - 1) * PosGap) div PosCols;
  TH := (PosBox.Height - (PosRowsPerPage - 1) * PosGap) div PosRowsPerPage;
  Col := X div (TW + PosGap);
  Row := Y div (TH + PosGap);
  if (Col >= PosCols) or (Row >= PosRowsPerPage) or (X mod (TW + PosGap) > TW) or
    (Y mod (TH + PosGap) > TH) then Exit;
  Idx := PosPageNo * PosCols * PosRowsPerPage + Row * PosCols + Col;
  if Idx > High(PosRows) then Exit;
  P := Store.List('products').Objects[PosRows[Idx]];
  // El mismo producto sin descuento suma una unidad a su línea.
  for I := 0 to Cart.Count - 1 do
  begin
    L := Cart.Objects[I];
    if SameProduct(L, P) and (JNum(L, 'discount') = 0) then
    begin
      L.Floats['qty'] := JNum(L, 'qty') + 1;
      RefreshCart;
      PosLines.ItemIndex := I;
      PosLines_select;
      Exit;
    end;
  end;
  Cart.Add(TJSONObject.Create(['product_id', JInt(P, 'id'), 'product_ref', JStr(P, 'ref'),
    'name', JStr(P, 'name'), 'qty', 1, 'price', JNum(P, 'price'), 'discount', 0,
    'uom', JInt(P, 'uom')]));
  RefreshCart;
  PosLines.ItemIndex := Cart.Count - 1;
  PosLines_select;
end;

procedure TForm1.PosCat_select;
begin
  PosPageNo := 0;
  RefreshPos;
end;

procedure TForm1.PosPrev_click;
begin
  Dec(PosPageNo);
  RefreshPos;
end;

procedure TForm1.PosNext_click;
begin
  Inc(PosPageNo);
  RefreshPos;
end;

procedure TForm1.PosLines_select;
var
  L: TJSONObject;
  F: TFormatSettings;
begin
  if (PosLines.ItemIndex < 0) or (PosLines.ItemIndex >= Cart.Count) then Exit;
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  L := Cart.Objects[PosLines.ItemIndex];
  PosQty.Text := FormatFloat('0.##', JNum(L, 'qty'), F);
  PosPrice.Text := FormatFloat('0.00', JNum(L, 'price'), F);
  PosDisc.Text := FormatFloat('0.##', JNum(L, 'discount'), F);
end;

procedure TForm1.PosApply_click;
var
  L: TJSONObject;
  Q, Pr, D: Double;
begin
  if (PosLines.ItemIndex < 0) or (PosLines.ItemIndex >= Cart.Count) then
  begin
    ShowMessage(SPosNoLine);
    Exit;
  end;
  if not ParseNum(PosQty.Text, Q) or (Q <= 0) then
  begin
    ShowMessage(SBadQty);
    Exit;
  end;
  if not ParseNum(PosPrice.Text, Pr) or (Pr < 0) then Pr := 0;
  if PosDisc.Text = '' then D := 0
  else if not ParseNum(PosDisc.Text, D) or (D < 0) or (D > 100) then
  begin
    ShowMessage(SPosBadDisc);
    Exit;
  end;
  L := Cart.Objects[PosLines.ItemIndex];
  L.Floats['qty'] := Q;
  L.Floats['price'] := Pr;
  L.Floats['discount'] := D;
  RefreshCart;
end;

procedure TForm1.PosDel_click;
begin
  if (PosLines.ItemIndex < 0) or (PosLines.ItemIndex >= Cart.Count) then
  begin
    ShowMessage(SPosNoLine);
    Exit;
  end;
  Cart.Delete(PosLines.ItemIndex);
  PosLines.ItemIndex := -1;
  RefreshCart;
end;

procedure TForm1.PosClear_click;
begin
  Cart.Clear;
  PosLines.ItemIndex := -1;
  RefreshCart;
end;

procedure TForm1.PosPay_click;
var
  P, O: TJSONObject;
  Ref, Pay: string;
begin
  if Cart.Count = 0 then
  begin
    ShowMessage(SPosNoItems);
    Exit;
  end;
  if (PosCust.ItemIndex > 0) and (PosCust.ItemIndex - 1 <= High(PosCustRows)) then
    P := Store.List('partners').Objects[PosCustRows[PosCust.ItemIndex - 1]]
  else
    P := Store.CounterPartner;
  if PosCardPay.Checked then Pay := 'card' else Pay := 'cash';
  O := Store.AddPos(P, Cart, Pay); // la venta se queda con las líneas
  Ref := JStr(O, 'ref');
  Cart := TJSONArray.Create;
  PosLines.ItemIndex := -1;
  RefreshAll;
  // Con conexión se completa ya en Odoo; sin ella, al sincronizar.
  if Online and not SyncOffline.Checked then DoSync(True);
  O := Store.Find('orders', 0, Ref);
  if O <> nil then ShowMessage(Receipt(O));
end;

procedure TForm1.DrawPosLine(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  L: TJSONObject;
  Sub: string;
  F: TFormatSettings;
  W: Integer;
begin
  if (Index < 0) or (Index >= Cart.Count) then Exit;
  C := TListBox(Control).Canvas;
  L := Cart.Objects[Index];
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  Row(C, ARect, odSelected in State);
  Sub := Money(JNum(L, 'qty') * JNum(L, 'price') * (1 - JNum(L, 'discount') / 100));
  C.Font.Size := 10;
  C.Font.Style := [fsBold];
  W := C.TextWidth(Sub);
  Say(C, ARect.Left + 10, ARect.Top + 3, JStr(L, 'name'), CInk, 10, True,
    ARect.Right - ARect.Left - W - 30);
  TextRight(C, ARect.Right - 8, ARect.Top + 3, Sub, CInk, 10, True);
  Sub := Format(SPosLine, [FormatFloat('0.##', JNum(L, 'qty'), F),
    Money(JNum(L, 'price'))]);
  if JNum(L, 'discount') <> 0 then
    Sub := Sub + '  ·  ' + Format(SPosDisc, [FormatFloat('0.##', JNum(L, 'discount'), F)]);
  Say(C, ARect.Left + 10, ARect.Top + 21, Sub, CMuted, 9, False,
    ARect.Right - ARect.Left - 20);
end;

// ------------------------------------------------------------- Obras BIM
// BIM 2.0 (módulo base_bim_2): bim.project (obra), bim.budget (presupuesto)
// y bim.concepts (el árbol: capítulos, partidas y recursos). Se hacen aquí,
// también sin conexión, y se suben a Odoo con su referencia DMS-…: en las
// observaciones de la obra, en «origin» del presupuesto y en «id_import» de
// cada concepto. Antes de crear algo se busca: nada se duplica y un envío
// cortado sigue donde se quedó.

const
  BimTypeKeys: array[0..6] of string = ('chapter', 'departure', 'labor',
    'equip', 'material', 'subcontract', 'aux');
  BimCodePrefix: array[0..6] of string = ('', '', 'MO', 'EQ', 'MT', 'SC', 'FN');

function BimTypeIndex(const T: string): Integer;
var
  I: Integer;
begin
  for I := 0 to High(BimTypeKeys) do
    if BimTypeKeys[I] = T then Exit(I);
  Result := 2;
end;

function BimIsResource(const T: string): Boolean;
begin
  Result := (T <> 'chapter') and (T <> 'departure');
end;

{ La clave de una obra o un presupuesto: su referencia o, si viene de Odoo
  sin ella, su id. }
function BimKey(O: TJSONObject): string;
begin
  if O = nil then Exit('');
  Result := JStr(O, 'ref');
  if Result = '' then Result := '#' + IntToStr(JInt(O, 'id'));
end;

function BimConcepts(B: TJSONObject): TJSONArray;
begin
  if not (B.Find('concepts') is TJSONArray) then
    B.Arrays['concepts'] := TJSONArray.Create;
  Result := B.Arrays['concepts'];
end;

{ El índice del concepto con la referencia R (-1 si no está). }
function BimIndex(A: TJSONArray; const R: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  if R = '' then Exit;
  for I := 0 to A.Count - 1 do
    if JStr(A.Objects[I], 'ref') = R then Exit(I);
end;

function BimLevel(A: TJSONArray; I: Integer): Integer;
var
  N: Integer;
begin
  Result := 0;
  N := 0;
  while (I >= 0) and (JStr(A.Objects[I], 'parent') <> '') and (N < 64) do
  begin
    Inc(Result);
    Inc(N);
    I := BimIndex(A, JStr(A.Objects[I], 'parent'));
  end;
end;

function BimHasKids(A: TJSONArray; I: Integer): Boolean;
var
  J: Integer;
  R: string;
begin
  R := JStr(A.Objects[I], 'ref');
  for J := 0 to A.Count - 1 do
    if JStr(A.Objects[J], 'parent') = R then Exit(True);
  Result := False;
end;

{ El precio de una unidad del concepto, como lo calcula BIM 2.0: el de un
  recurso es el suyo; el de una partida, la suma de sus recursos (o el suyo,
  si no tiene); el de un capítulo, la suma de lo que lleva dentro. }
function BimAmount(A: TJSONArray; I: Integer): Double; forward;

function BimUnit(A: TJSONArray; I: Integer): Double;
var
  J: Integer;
  R, T: string;
  Kids: Boolean;
begin
  T := JStr(A.Objects[I], 'type');
  if BimIsResource(T) then Exit(JNum(A.Objects[I], 'price'));
  R := JStr(A.Objects[I], 'ref');
  Result := 0;
  Kids := False;
  for J := 0 to A.Count - 1 do
    if JStr(A.Objects[J], 'parent') = R then
    begin
      Kids := True;
      Result := Result + BimAmount(A, J);
    end;
  if (T = 'departure') and not Kids then Result := JNum(A.Objects[I], 'price');
end;

{ Cantidad × precio (un capítulo cuenta una vez). }
function BimAmount(A: TJSONArray; I: Integer): Double;
begin
  if JStr(A.Objects[I], 'type') = 'chapter' then Result := BimUnit(A, I)
  else Result := JNum(A.Objects[I], 'qty') * BimUnit(A, I);
end;

function BimSum(A: TJSONArray): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to A.Count - 1 do
    if JStr(A.Objects[I], 'parent') = '' then Result := Result + BimAmount(A, I);
end;

{ El último concepto que cuelga de I (la lista va en orden de árbol). }
function BimEnd(A: TJSONArray; I: Integer): Integer;
var
  L: Integer;
begin
  Result := I;
  L := BimLevel(A, I);
  while (Result + 1 < A.Count) and (BimLevel(A, Result + 1) > L) do Inc(Result);
end;

{ El código que toca: 01, 02… los capítulos; 01.01… las partidas; MO001,
  MT001… los recursos. }
function BimNextCode(A: TJSONArray; const T, ParentRef: string): string;
var
  I, N, P: Integer;
  Pre: string;
begin
  N := 0;
  if BimIsResource(T) then
  begin
    Pre := BimCodePrefix[BimTypeIndex(T)];
    for I := 0 to A.Count - 1 do
      if JStr(A.Objects[I], 'type') = T then Inc(N);
    Exit(Pre + Format('%.3d', [N + 1]));
  end;
  for I := 0 to A.Count - 1 do
    if JStr(A.Objects[I], 'parent') = ParentRef then Inc(N);
  Result := Format('%.2d', [N + 1]);
  P := BimIndex(A, ParentRef);
  if P >= 0 then Result := JStr(A.Objects[P], 'code') + '.' + Result;
end;

// ---- TOdooStore: obras, presupuestos y conceptos

function TOdooStore.AddBimProject(const Name: string;
  Partner: TJSONObject): TJSONObject;
begin
  Result := TJSONObject.Create(['id', 0, 'ref', NewRef, 'code', '',
    'name', Trim(Name), 'partner_id', 0, 'partner_ref', '', 'partner', '',
    'pending', True]);
  if Partner <> nil then
  begin
    Result.Integers['partner_id'] := JInt(Partner, 'id');
    Result.Strings['partner_ref'] := JStr(Partner, 'ref');
    Result.Strings['partner'] := JStr(Partner, 'name');
  end;
  List('bim_projects').Insert(0, Result);
  Queue('bim_project', JStr(Result, 'ref'), 0);
  Save;
end;

{ Un presupuesto en borrador: se rellena aquí y se envía con SendBimBudget. }
function TOdooStore.AddBimBudget(Project: TJSONObject;
  const Name: string): TJSONObject;
begin
  Result := TJSONObject.Create(['id', 0, 'ref', NewRef, 'code', '',
    'name', Trim(Name), 'project_id', JInt(Project, 'id'),
    'project_ref', JStr(Project, 'ref'), 'project', JStr(Project, 'name'),
    'date', NowStamp, 'amount', 0, 'pending', True, 'local', True,
    'queued', False]);
  Result.Add('concepts', TJSONArray.Create);
  List('bim_budgets').Insert(0, Result);
  Save;
end;

{ Añade un concepto dentro de ParentRef: los capítulos van arriba del todo,
  las partidas dentro de un capítulo y los recursos dentro de una partida
  (como pide BIM 2.0). Devuelve nil y el motivo en Err si no cabe ahí. }
function TOdooStore.AddConcept(B: TJSONObject; const ParentRef, AType, Code,
  Name: string; Qty, Price: Double; const Uom: string;
  out Err: string): TJSONObject;
var
  A: TJSONArray;
  P, At: Integer;
  PT: string;
begin
  Result := nil;
  Err := '';
  A := BimConcepts(B);
  P := BimIndex(A, ParentRef);
  if P >= 0 then PT := JStr(A.Objects[P], 'type') else PT := '';
  if (AType = 'chapter') and (PT <> '') then Err := SBimChapterTop
  else if (AType = 'departure') and (PT <> 'chapter') then Err := SBimNeedChapter
  else if BimIsResource(AType) and (PT <> 'departure') then Err := SBimNeedDeparture;
  if Err <> '' then Exit;
  if AType = 'chapter' then Qty := 1;
  Result := TJSONObject.Create(['ref', NewRef, 'id', 0, 'parent', ParentRef,
    'type', AType, 'code', Trim(Code), 'name', Trim(Name), 'qty', Qty,
    'price', Price, 'uom', Trim(Uom)]);
  if P >= 0 then At := BimEnd(A, P) + 1 else At := A.Count;
  A.Insert(At, Result);
  B.Floats['amount'] := BimSum(A);
  Save;
end;

procedure TOdooStore.SendBimBudget(B: TJSONObject);
begin
  B.Floats['amount'] := BimSum(BimConcepts(B));
  B.Booleans['queued'] := True;
  B.Booleans['pending'] := True;
  Queue('bim_budget', JStr(B, 'ref'), 0);
  Save;
end;

// ---- TOdooSync: subir y bajar de BIM 2.0

{ La moneda de la compañía (la pide el presupuesto). }
function TOdooSync.CompanyCurrency: Integer;
begin
  Result := JInt(Store.Settings, 'currency_id');
  if Result > 0 then Exit;
  LoadCurrency;
  Result := JInt(Store.Settings, 'currency_id');
end;

{ La unidad de medida por su nombre (m², m3, ud…), entre las de Odoo. }
function TOdooSync.BimUomId(const Name: string): Integer;
var
  A: TJSONArray;
  I: Integer;
begin
  Result := 0;
  if Trim(Name) = '' then Exit;
  A := Store.List('bim_uoms');
  for I := 0 to A.Count - 1 do
    if UTF8LowerCase(JStr(A.Objects[I], 'name')) = UTF8LowerCase(Trim(Name)) then
      Exit(JInt(A.Objects[I], 'id'));
end;

function NewId(R: TJSONData): Integer;
begin
  try
    if R is TJSONArray then Result := TJSONArray(R).Items[0].AsInteger
    else Result := R.AsInteger;
  finally
    R.Free;
  end;
end;

{ Crea la obra en Odoo (o la encuentra por su referencia, que va en las
  observaciones) y le pone su id y su código PRJ…. }
function TOdooSync.EnsureBimProject(P: TJSONObject): Integer;
var
  Vals, Q: TJSONObject;
  Args, Rows: TJSONArray;
  PartnerId, I: Integer;
  A: TJSONArray;
begin
  Result := JInt(P, 'id');
  if Result > 0 then Exit;
  if not Client.Exists('bim.project') then raise EOdoo.Make(oeServer, SBimMissing);
  PartnerId := JInt(P, 'partner_id');
  if (PartnerId = 0) and (JStr(P, 'partner_ref') <> '') then
  begin
    Q := Store.Find('partners', 0, JStr(P, 'partner_ref'));
    if Q <> nil then PartnerId := JInt(Q, 'id');
    if PartnerId = 0 then raise EOdoo.Make(oeServer, SPartnerNotSent);
  end;
  Rows := Client.SearchRead('bim.project', Domain1('notes', 'ilike',
    TJSONString.Create(JStr(P, 'ref'))), ['name'], 1, '');
  try
    if Rows.Count > 0 then
    begin
      Result := JInt(Rows.Objects[0], 'id');
      Log(Format(SBimFoundProject, [JStr(P, 'name')]));
    end;
  finally
    Rows.Free;
  end;
  if Result = 0 then
  begin
    Vals := TJSONObject.Create(['nombre', JStr(P, 'name'),
      'notes', Format(SBimRefNote, [JStr(P, 'ref')])]);
    if PartnerId > 0 then Vals.Add('customer_id', PartnerId);
    Args := TJSONArray.Create;
    Args.Add(Vals);
    Result := NewId(Client.Kw('bim.project', 'create', Args));
  end;
  Rows := Client.SearchRead('bim.project', Domain1('id', '=',
    TJSONIntegerNumber.Create(Result)), ['name'], 1, '');
  try
    if Rows.Count > 0 then P.Strings['code'] := JStr(Rows.Objects[0], 'name');
  finally
    Rows.Free;
  end;
  P.Integers['id'] := Result;
  P.Integers['partner_id'] := PartnerId;
  P.Booleans['pending'] := False;
  // Los presupuestos que esperaban a esta obra ya tienen su id.
  A := Store.List('bim_budgets');
  for I := 0 to A.Count - 1 do
    if (JInt(A.Objects[I], 'project_id') = 0) and
      (JStr(A.Objects[I], 'project_ref') = JStr(P, 'ref')) then
      A.Objects[I].Integers['project_id'] := Result;
  Log(Format(SBimSentProject, [JStr(P, 'name'), JStr(P, 'code')]));
end;

procedure TOdooSync.PushBimProject(Op: TJSONObject);
var
  P: TJSONObject;
begin
  P := Store.Find('bim_projects', 0, JStr(Op, 'ref'));
  if P <> nil then EnsureBimProject(P);
end;

{ El presupuesto: la obra (si aún no está), la cabecera (buscada por su
  «origin») y los conceptos en orden de árbol, los padres antes que los
  hijos; los que ya están (por su «id_import») no se vuelven a crear. Al
  final, UPD (update_amount): BIM recalcula los importes. }
procedure TOdooSync.PushBimBudget(Op: TJSONObject);
var
  B, P, C, Vals, Map: TJSONObject;
  A, Rows, Args: TJSONArray;
  Pid, Bid, I, Cur, Parent, UomId: Integer;
  T: string;
begin
  B := Store.Find('bim_budgets', 0, JStr(Op, 'ref'));
  if B = nil then Exit;
  if not Client.Exists('bim.budget') then raise EOdoo.Make(oeServer, SBimMissing);
  Pid := JInt(B, 'project_id');
  if Pid = 0 then
  begin
    P := Store.Find('bim_projects', 0, JStr(B, 'project_ref'));
    if P = nil then raise EOdoo.Make(oeServer, SBimNoProject);
    Pid := EnsureBimProject(P);
    B.Integers['project_id'] := Pid;
  end;
  Bid := Client.FindRef('bim.budget', 'origin', JStr(B, 'ref'));
  if Bid > 0 then Log(Format(SBimFoundBudget, [JStr(B, 'name')]))
  else
  begin
    Vals := TJSONObject.Create(['name', JStr(B, 'name'), 'project_id', Pid,
      'origin', JStr(B, 'ref')]);
    Cur := CompanyCurrency;
    if Cur > 0 then Vals.Add('currency_id', Cur);
    Args := TJSONArray.Create;
    Args.Add(Vals);
    Bid := NewId(Client.Kw('bim.budget', 'create', Args));
  end;
  A := BimConcepts(B);
  Map := TJSONObject.Create;
  try
    Rows := Client.SearchRead('bim.concepts', Domain1('budget_id', '=',
      TJSONIntegerNumber.Create(Bid)), ['id_import'], 0, '');
    try
      for I := 0 to Rows.Count - 1 do
        if JStr(Rows.Objects[I], 'id_import') <> '' then
          Map.Integers[JStr(Rows.Objects[I], 'id_import')] := JInt(Rows.Objects[I], 'id');
    finally
      Rows.Free;
    end;
    for I := 0 to A.Count - 1 do
    begin
      C := A.Objects[I];
      if Map.Find(JStr(C, 'ref')) <> nil then
      begin
        C.Integers['id'] := Map.Integers[JStr(C, 'ref')];
        Continue;
      end;
      Parent := 0;
      if JStr(C, 'parent') <> '' then
      begin
        if Map.Find(JStr(C, 'parent')) = nil then
          raise EOdoo.Make(oeServer, Format(SBimNoParent, [JStr(C, 'code')]));
        Parent := Map.Integers[JStr(C, 'parent')];
      end;
      T := JStr(C, 'type');
      Vals := TJSONObject.Create(['budget_id', Bid, 'code', JStr(C, 'code'),
        'name', JStr(C, 'name'), 'type', T, 'id_import', JStr(C, 'ref')]);
      if Parent > 0 then Vals.Add('parent_id', Parent);
      if T <> 'chapter' then Vals.Add('quantity', JNum(C, 'qty'));
      if BimIsResource(T) then Vals.Add('amount_fixed', JNum(C, 'price'))
      else if (T = 'departure') and not BimHasKids(A, I) then
      begin
        // Una partida sin recursos lleva su precio (manual).
        if Client.Has('bim.concepts', 'amount_type') then Vals.Add('amount_type', 'fixed');
        Vals.Add('amount_fixed', JNum(C, 'price'));
      end;
      UomId := BimUomId(JStr(C, 'uom'));
      if UomId > 0 then Vals.Add('uom_id', UomId);
      Args := TJSONArray.Create;
      Args.Add(Vals);
      C.Integers['id'] := NewId(Client.Kw('bim.concepts', 'create', Args));
      Map.Integers[JStr(C, 'ref')] := JInt(C, 'id');
      B.Integers['id'] := Bid; // por si se corta: ya está la cabecera
      Store.Save;
    end;
  finally
    Map.Free;
  end;
  try
    Args := TJSONArray.Create;
    Args.Add(TJSONArray.Create([Bid]));
    Client.Kw('bim.budget', 'update_amount', Args).Free;
  except
    on E: EOdoo do
      if E.Kind in [oeNetwork, oeSSL] then raise;
  end;
  Rows := Client.SearchRead('bim.budget', Domain1('id', '=',
    TJSONIntegerNumber.Create(Bid)), ['code', 'balance'], 1, '');
  try
    if Rows.Count > 0 then
    begin
      B.Strings['code'] := JStr(Rows.Objects[0], 'code');
      B.Floats['amount'] := JNum(Rows.Objects[0], 'balance');
    end;
  finally
    Rows.Free;
  end;
  B.Integers['id'] := Bid;
  B.Booleans['pending'] := False;
  Log(Format(SBimSentBudget, [JStr(B, 'code'), JStr(B, 'name'), A.Count,
    Money(JNum(B, 'amount'))]));
end;

{ Las obras, los presupuestos (sin sus conceptos: se piden al abrirlos) y las
  unidades de medida. Lo que espera para enviarse se queda. }
procedure TOdooSync.DownloadBim;
var
  Rows, Fresh, Old: TJSONArray;
  R, O, Keep: TJSONObject;
  I: Integer;
  Ref: string;
begin
  Fresh := TJSONArray.Create;
  Old := Store.List('bim_projects');
  for I := 0 to Old.Count - 1 do
    if JInt(Old.Objects[I], 'id') = 0 then Fresh.Add(Old.Objects[I].Clone);
  Rows := Client.SearchRead('bim.project', TJSONArray.Create, ['name', 'nombre',
    'customer_id', 'notes'], 1000, 'id desc');
  try
    for I := 0 to Rows.Count - 1 do
    begin
      R := Rows.Objects[I];
      Keep := Store.Find('bim_projects', JInt(R, 'id'), '');
      if Keep <> nil then Ref := JStr(Keep, 'ref') else Ref := '';
      O := TJSONObject.Create(['id', JInt(R, 'id'), 'ref', Ref,
        'code', JStr(R, 'name'), 'name', JStr(R, 'nombre'),
        'partner_id', M2OId(R, 'customer_id'), 'partner_ref', '',
        'partner', M2OName(R, 'customer_id'), 'pending', False]);
      if JStr(O, 'name') = '' then O.Strings['name'] := JStr(R, 'name');
      Fresh.Add(O);
    end;
  finally
    Rows.Free;
  end;
  Store.Data.Arrays['bim_projects'] := Fresh;

  Fresh := TJSONArray.Create;
  Old := Store.List('bim_budgets');
  for I := 0 to Old.Count - 1 do
    if (JInt(Old.Objects[I], 'id') = 0) or JBool(Old.Objects[I], 'pending') then
      Fresh.Add(Old.Objects[I].Clone);
  Rows := Client.SearchRead('bim.budget', TJSONArray.Create, ['code', 'name',
    'project_id', 'balance', 'date_start', 'origin'], 2000, 'id desc');
  try
    for I := 0 to Rows.Count - 1 do
    begin
      R := Rows.Objects[I];
      if Store.Find('bim_budgets', 0, JStr(R, 'origin')) <> nil then
        if JBool(Store.Find('bim_budgets', 0, JStr(R, 'origin')), 'pending') then
          Continue; // aún a medias: manda lo de aquí
      O := TJSONObject.Create(['id', JInt(R, 'id'), 'ref', '',
        'code', JStr(R, 'code'), 'name', JStr(R, 'name'),
        'project_id', M2OId(R, 'project_id'), 'project_ref', '',
        'project', M2OName(R, 'project_id'), 'date', JStr(R, 'date_start'),
        'amount', JNum(R, 'balance'), 'pending', False, 'local', False]);
      if Copy(JStr(R, 'origin'), 1, 4) = 'DMS-' then
      begin
        O.Strings['ref'] := JStr(R, 'origin');
        // El árbol que se hizo aquí se sigue viendo sin conexión.
        Keep := Store.Find('bim_budgets', 0, JStr(R, 'origin'));
        if (Keep <> nil) and (Keep.Find('concepts') is TJSONArray) then
          O.Add('concepts', Keep.Arrays['concepts'].Clone);
      end;
      Fresh.Add(O);
    end;
  finally
    Rows.Free;
  end;
  Store.Data.Arrays['bim_budgets'] := Fresh;

  Fresh := TJSONArray.Create;
  try
    Rows := Client.SearchRead('uom.uom', TJSONArray.Create, ['name'], 500, 'name');
    try
      for I := 0 to Rows.Count - 1 do
        Fresh.Add(TJSONObject.Create(['id', JInt(Rows.Objects[I], 'id'),
          'name', JStr(Rows.Objects[I], 'name')]));
    finally
      Rows.Free;
    end;
  except
    on E: EOdoo do
      if E.Kind in [oeNetwork, oeSSL] then raise;
  end;
  Store.Data.Arrays['bim_uoms'] := Fresh;
  Log(Format(SBimDownloaded, [Store.List('bim_projects').Count,
    Store.List('bim_budgets').Count]));
end;

{ Los conceptos de un presupuesto de Odoo, en orden de árbol, para verlo. }
procedure TOdooSync.LoadBimConcepts(B: TJSONObject);
var
  Rows, A: TJSONArray;
  Done: array of Boolean;

  procedure Walk(ParentId: Integer; const ParentRef: string; Depth: Integer);
  var
    I: Integer;
    R: TJSONObject;
    T: string;
  begin
    if Depth > 32 then Exit;
    for I := 0 to Rows.Count - 1 do
    begin
      R := Rows.Objects[I];
      if Done[I] or (M2OId(R, 'parent_id') <> ParentId) then Continue;
      Done[I] := True;
      T := JStr(R, 'type');
      if T = '' then T := 'material';
      if BimIsResource(T) then
        A.Add(TJSONObject.Create(['ref', '#' + IntToStr(JInt(R, 'id')),
          'id', JInt(R, 'id'), 'parent', ParentRef, 'type', T,
          'code', JStr(R, 'code'), 'name', JStr(R, 'name'),
          'qty', JNum(R, 'quantity'), 'price', JNum(R, 'amount_fixed'),
          'uom', M2OName(R, 'uom_id')]))
      else
        A.Add(TJSONObject.Create(['ref', '#' + IntToStr(JInt(R, 'id')),
          'id', JInt(R, 'id'), 'parent', ParentRef, 'type', T,
          'code', JStr(R, 'code'), 'name', JStr(R, 'name'),
          'qty', JNum(R, 'quantity'), 'price', JNum(R, 'amount_compute'),
          'uom', M2OName(R, 'uom_id')]));
      Walk(JInt(R, 'id'), '#' + IntToStr(JInt(R, 'id')), Depth + 1);
    end;
  end;

begin
  Rows := Client.SearchRead('bim.concepts', Domain1('budget_id', '=',
    TJSONIntegerNumber.Create(JInt(B, 'id'))), ['code', 'name', 'type',
    'quantity', 'amount_fixed', 'amount_compute', 'parent_id', 'uom_id'],
    5000, 'sequence, id');
  try
    SetLength(Done, Rows.Count);
    A := TJSONArray.Create;
    Walk(0, '', 0);
    B.Arrays['concepts'] := A;
  finally
    Rows.Free;
  end;
end;

// ---- TForm1: la página Obras BIM (como el árbol de conceptos de BIM 2.0)

const
  CBimTeal = $00847E01;    // #017e84
  CBimSelBg = $00F2F0DC;   // #dcf0f2
  CBimLine = $00EBE7E5;    // #e5e7eb
  CBimGreen = $00329A2C;   // #2c9a32
  CBimBrown = $0014698B;   // #8b6914
  CBimInk = $00292521;     // #212529

{ Obras BIM, detrás del punto de venta (que va detrás de Compras); sin BIM en Odoo (y sin nada de BIM
  aquí), el botón se oculta y los de abajo suben. }
procedure TForm1.LayoutNav;
var
  Vis: Boolean;
begin
  Vis := JBool(Store.Data, 'bim') or (Store.List('bim_projects').Count > 0);
  NavBim.Visible := Vis;
  if Vis then
  begin
    NavBim.Top := 84 + 6 * 44;
    NavSync.Top := 84 + 7 * 44;
    NavSettings.Top := 84 + 8 * 44;
  end
  else
  begin
    NavSync.Top := 84 + 6 * 44;
    NavSettings.Top := 84 + 7 * 44;
  end;
end;

procedure TForm1.NavBim_click;
begin
  ShowPage(7);
end;

function TForm1.CurBimProject: TJSONObject;
var
  A: TJSONArray;
  I: Integer;
begin
  Result := nil;
  A := Store.List('bim_projects');
  for I := 0 to A.Count - 1 do
    if BimKey(A.Objects[I]) = BimProjKey then Exit(A.Objects[I]);
end;

function TForm1.CurBimBudget: TJSONObject;
var
  A: TJSONArray;
  I: Integer;
begin
  Result := nil;
  A := Store.List('bim_budgets');
  for I := 0 to A.Count - 1 do
    if BimKey(A.Objects[I]) = BimBudKey then Exit(A.Objects[I]);
end;

{ Solo se cambia un borrador de este equipo que aún no se mandó. }
function TForm1.BimEditable(B: TJSONObject): Boolean;
begin
  Result := (B <> nil) and JBool(B, 'local') and not JBool(B, 'queued') and
    (JInt(B, 'id') = 0);
end;

function BimOfProject(B, P: TJSONObject): Boolean;
begin
  Result := (P <> nil) and (((JInt(P, 'id') > 0) and (JInt(B, 'project_id') = JInt(P, 'id'))) or
    ((JStr(P, 'ref') <> '') and (JStr(B, 'project_ref') = JStr(P, 'ref'))));
end;

{ 1.234,5678 y 1.234,56, con los separadores de aquí (como BIM). }
function BimNum(V: Double; const Mask: string): string;
var
  F: TFormatSettings;
begin
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  F.ThousandSeparator := Thousands;
  Result := FormatFloat(Mask, V, F);
end;

{ El icono de cada tipo, como en BIM: el capítulo, cuatro cuadros verdes; la
  partida, una lista; el material, una «m»; la mano de obra, una persona… }
procedure BimIcon(C: TCanvas; X, Y: Integer; const T: string);
begin
  C.Brush.Style := bsSolid;
  C.Pen.Style := psSolid;
  if T = 'chapter' then
  begin
    C.Brush.Color := CBimGreen;
    C.Pen.Color := CBimGreen;
    C.FillRect(Rect(X, Y + 1, X + 6, Y + 7));
    C.FillRect(Rect(X + 8, Y + 1, X + 14, Y + 7));
    C.FillRect(Rect(X, Y + 9, X + 6, Y + 15));
    C.FillRect(Rect(X + 8, Y + 9, X + 14, Y + 15));
  end
  else if T = 'departure' then
  begin
    C.Brush.Color := CBimBrown;
    C.FillRect(Rect(X, Y + 2, X + 3, Y + 5));
    C.FillRect(Rect(X + 5, Y + 2, X + 14, Y + 5));
    C.FillRect(Rect(X, Y + 7, X + 3, Y + 10));
    C.FillRect(Rect(X + 5, Y + 7, X + 14, Y + 10));
    C.FillRect(Rect(X, Y + 12, X + 3, Y + 15));
    C.FillRect(Rect(X + 5, Y + 12, X + 14, Y + 15));
  end
  else if T = 'labor' then
  begin
    C.Brush.Color := CBimGreen;
    C.Pen.Color := CBimGreen;
    C.Ellipse(X + 4, Y, X + 10, Y + 6);
    C.FillRect(Rect(X + 3, Y + 6, X + 11, Y + 11));
    C.FillRect(Rect(X + 4, Y + 11, X + 6, Y + 16));
    C.FillRect(Rect(X + 8, Y + 11, X + 10, Y + 16));
  end
  else if T = 'equip' then
  begin
    C.Brush.Color := $00555B60;
    C.Pen.Color := $00555B60;
    C.FillRect(Rect(X, Y + 4, X + 9, Y + 11));
    C.FillRect(Rect(X + 9, Y + 7, X + 14, Y + 11));
    C.Ellipse(X + 1, Y + 10, X + 6, Y + 15);
    C.Ellipse(X + 8, Y + 10, X + 13, Y + 15);
  end
  else if T = 'subcontract' then
  begin
    C.Brush.Color := $00C1426F;
    C.Pen.Color := $00C1426F;
    C.FillRect(Rect(X, Y + 5, X + 14, Y + 15));
    C.Brush.Style := bsClear;
    C.Rectangle(X + 4, Y + 2, X + 10, Y + 6);
  end
  else
  begin
    C.Brush.Style := bsClear;
    C.Font.Size := 11;
    C.Font.Style := [fsBold, fsItalic];
    if T = 'material' then C.Font.Color := CBimBrown else C.Font.Color := CGrey;
    if T = 'material' then C.TextOut(X + 1, Y - 2, 'm') else C.TextOut(X + 3, Y - 2, 'f');
  end;
  C.Brush.Style := bsClear;
end;

{ ⊞ o ⊟: un cuadrito con + o −. }
procedure BimToggle(C: TCanvas; X, Y: Integer; Open: Boolean);
begin
  C.Brush.Style := bsSolid;
  C.Brush.Color := clWhite;
  C.Pen.Color := $00707070;
  C.Rectangle(X, Y, X + 11, Y + 11);
  C.Line(X + 3, Y + 5, X + 8, Y + 5);
  if not Open then C.Line(X + 5, Y + 3, X + 5, Y + 8);
  C.Brush.Style := bsClear;
end;

{ ¿Está a la vista el concepto I (todos sus padres abiertos)? }
function TForm1.BimShown(A: TJSONArray; I: Integer): Boolean;
var
  N: Integer;
begin
  Result := True;
  N := 0;
  I := BimIndex(A, JStr(A.Objects[I], 'parent'));
  while (I >= 0) and (N < 64) do
  begin
    if BimOpen.IndexOf(JStr(A.Objects[I], 'ref')) < 0 then Exit(False);
    I := BimIndex(A, JStr(A.Objects[I], 'parent'));
    Inc(N);
  end;
end;

{ Abre los padres de R (para que se vea en el árbol). }
procedure TForm1.BimReveal(A: TJSONArray; const R: string);
var
  I, N: Integer;
begin
  N := 0;
  I := BimIndex(A, R);
  if I >= 0 then I := BimIndex(A, JStr(A.Objects[I], 'parent'));
  while (I >= 0) and (N < 64) do
  begin
    if BimOpen.IndexOf(JStr(A.Objects[I], 'ref')) < 0 then BimOpen.Add(JStr(A.Objects[I], 'ref'));
    I := BimIndex(A, JStr(A.Objects[I], 'parent'));
    Inc(N);
  end;
end;

procedure TForm1.RefreshBim;
var
  A: TJSONArray;
  P: TJSONObject;
  I: Integer;
begin
  A := Store.List('bim_projects');
  if (CurBimProject = nil) and (A.Count > 0) then BimProjKey := BimKey(A.Objects[0]);
  BimProject.Items.BeginUpdate;
  try
    BimProject.Items.Clear;
    for I := 0 to A.Count - 1 do
    begin
      P := A.Objects[I];
      if JStr(P, 'code') <> '' then
        BimProject.Items.Add('[' + JStr(P, 'code') + '] ' + JStr(P, 'name'))
      else
        BimProject.Items.Add(JStr(P, 'name') + ' (' + SPendingTag + ')');
      if BimKey(P) = BimProjKey then BimProject.ItemIndex := I;
    end;
  finally
    BimProject.Items.EndUpdate;
  end;
  RefreshBimBudgets;
end;

procedure TForm1.RefreshBimBudgets;
var
  A: TJSONArray;
  P, B: TJSONObject;
  I, N: Integer;
begin
  P := CurBimProject;
  A := Store.List('bim_budgets');
  N := 0;
  SetLength(BimBudRows, A.Count);
  for I := 0 to A.Count - 1 do
    if BimOfProject(A.Objects[I], P) then
    begin
      BimBudRows[N] := I;
      Inc(N);
    end;
  SetLength(BimBudRows, N);
  if (N > 0) and ((CurBimBudget = nil) or not BimOfProject(CurBimBudget, P)) then
  begin
    BimBudKey := BimKey(A.Objects[BimBudRows[0]]);
    BimSelRef := '';
  end;
  if N = 0 then BimBudKey := '';
  BimBudSel.Items.BeginUpdate;
  try
    BimBudSel.Items.Clear;
    for I := 0 to N - 1 do
    begin
      B := A.Objects[BimBudRows[I]];
      if JStr(B, 'code') <> '' then
        BimBudSel.Items.Add('[' + JStr(B, 'code') + '] ' + JStr(B, 'name'))
      else
        BimBudSel.Items.Add(JStr(B, 'name') + ' (' + SPendingTag + ')');
      if BimKey(B) = BimBudKey then BimBudSel.ItemIndex := I;
    end;
  finally
    BimBudSel.Items.EndUpdate;
  end;
  RefreshBimTree;
end;

{ El árbol (lo que está a la vista) y la tabla de lo elegido. }
procedure TForm1.RefreshBimTree;
var
  B: TJSONObject;
  A: TJSONArray;
  I, N, TopRow: Integer;
  Edit: Boolean;
begin
  B := CurBimBudget;
  TopRow := BimTree.TopIndex;
  SetLength(BimTreeRows, 0);
  N := 0;
  if B <> nil then
  begin
    A := BimConcepts(B);
    if BimIndex(A, BimSelRef) < 0 then BimSelRef := '';
    SetLength(BimTreeRows, A.Count);
    for I := 0 to A.Count - 1 do
      if BimShown(A, I) then
      begin
        BimTreeRows[N] := I;
        Inc(N);
      end;
    SetLength(BimTreeRows, N);
  end;
  BimTree.Items.BeginUpdate;
  try
    BimTree.Items.Clear;
    for I := 0 to N - 1 do
    begin
      BimTree.Items.Add('');
      if JStr(A.Objects[BimTreeRows[I]], 'ref') = BimSelRef then BimTree.ItemIndex := I;
    end;
    if (TopRow >= 0) and (TopRow < N) then BimTree.TopIndex := TopRow;
  finally
    BimTree.Items.EndUpdate;
  end;
  Edit := BimEditable(B);
  BimAdd.Enabled := Edit;
  BimDel.Enabled := Edit;
  BimChild.Enabled := Edit;
  BimSibling.Enabled := Edit;
  BimApply.Enabled := Edit;
  BimSend.Enabled := Edit;
  if B = nil then
  begin
    BimCrumb.Caption := '';
    BimCrumb2.Caption := SBimChooseBudget;
    BimInfo.Caption := '';
  end
  else
  begin
    if JStr(B, 'code') <> '' then
      BimCrumb.Caption := SBimCrumb + ' / [' + JStr(B, 'code') + '] ' + JStr(B, 'name')
    else BimCrumb.Caption := SBimCrumb + ' / ' + JStr(B, 'name');
    if Edit then BimInfo.Caption := SBimDraft + LineEnding + SBimKeys
    else if JBool(B, 'pending') then BimInfo.Caption := SBimWaiting
    else if (BimConcepts(B).Count = 0) and not Online then BimInfo.Caption := SBimLoad
    else BimInfo.Caption := SBimLocked;
  end;
  RefreshBimRows;
end;

{ La tabla: lo que hay dentro de lo elegido (de un recurso, lo que hay junto
  a él), con la ruta y los totales. }
procedure TForm1.RefreshBimRows;
var
  B: TJSONObject;
  A: TJSONArray;
  I, N, S: Integer;
  Holder, Path: string;
  SQ, SC, SB: Double;
begin
  B := CurBimBudget;
  SetLength(BimRowRows, 0);
  N := 0;
  SQ := 0;
  SC := 0;
  SB := 0;
  Path := '';
  if B <> nil then
  begin
    A := BimConcepts(B);
    S := BimIndex(A, BimSelRef);
    Holder := BimSelRef;
    if (S >= 0) and BimIsResource(JStr(A.Objects[S], 'type')) then
      Holder := JStr(A.Objects[S], 'parent');
    SetLength(BimRowRows, A.Count);
    for I := 0 to A.Count - 1 do
      if JStr(A.Objects[I], 'parent') = Holder then
      begin
        BimRowRows[N] := I;
        Inc(N);
        if JStr(A.Objects[I], 'type') = 'chapter' then SQ := SQ + 1
        else SQ := SQ + JNum(A.Objects[I], 'qty');
        SC := SC + BimUnit(A, I);
        SB := SB + BimAmount(A, I);
      end;
    SetLength(BimRowRows, N);
    // La ruta: Concepto › [01] … › [01.01] …
    I := BimIndex(A, Holder);
    while I >= 0 do
    begin
      Path := ' › [' + JStr(A.Objects[I], 'code') + '] ' + JStr(A.Objects[I], 'name') + Path;
      I := BimIndex(A, JStr(A.Objects[I], 'parent'));
    end;
  end;
  BimCrumb2.Caption := SBimConcept + Path;
  if B = nil then BimCrumb2.Caption := SBimChooseBudget;
  BimRows.Items.BeginUpdate;
  try
    BimRows.Items.Clear;
    for I := 0 to N - 1 do
    begin
      BimRows.Items.Add('');
      if JStr(A.Objects[BimRowRows[I]], 'ref') = BimRowRef then BimRows.ItemIndex := I;
    end;
  finally
    BimRows.Items.EndUpdate;
  end;
  if N > 0 then
  begin
    BimFootQty.Caption := BimNum(SQ, '#,##0.00');
    BimFootCost.Caption := BimNum(SC, '#,##0.00');
    BimFootBal.Caption := BimNum(SB, '#,##0.00');
  end
  else
  begin
    BimFootQty.Caption := '';
    BimFootCost.Caption := '';
    BimFootBal.Caption := '';
  end;
end;

procedure TForm1.BimProject_select;
var
  A: TJSONArray;
begin
  A := Store.List('bim_projects');
  if (BimProject.ItemIndex >= 0) and (BimProject.ItemIndex < A.Count) then
    BimProjKey := BimKey(A.Objects[BimProject.ItemIndex]);
  BimBudKey := '';
  BimSelRef := '';
  BimRowRef := '';
  RefreshBimBudgets;
  BimPrepare(False);
end;

{ La obra nueva: nombre y cliente, en un cuadro de diálogo. }
function TForm1.AskBimProject(out AName: string; out Partner: TJSONObject): Boolean;
var
  F: TForm;
  E: TEdit;
  Cb: TComboBox;
  L: TLabel;
  Ok, No: TButton;
  A: TJSONArray;
  Sorted: TStringList;
  I: Integer;
begin
  Result := False;
  AName := '';
  Partner := nil;
  A := Store.List('partners');
  Sorted := TStringList.Create;
  F := TForm.CreateNew(nil);
  try
    for I := 0 to A.Count - 1 do
      Sorted.AddObject(JStr(A.Objects[I], 'name'), TObject(PtrInt(I)));
    Sorted.CaseSensitive := False;
    Sorted.Sort;
    F.Caption := SBimNewProject;
    F.BorderStyle := bsDialog;
    F.Position := poMainFormCenter;
    F.ClientWidth := 400;
    F.ClientHeight := 176;
    L := TLabel.Create(F);
    L.Parent := F;
    L.SetBounds(16, 12, 368, 18);
    L.Caption := SBimHintProj;
    E := TEdit.Create(F);
    E.Parent := F;
    E.SetBounds(16, 32, 368, 28);
    L := TLabel.Create(F);
    L.Parent := F;
    L.SetBounds(16, 70, 368, 18);
    L.Caption := SBimCustomer;
    Cb := TComboBox.Create(F);
    Cb.Parent := F;
    Cb.Style := csDropDownList;
    Cb.SetBounds(16, 90, 368, 28);
    Cb.Items.Add(SBimNoCust);
    for I := 0 to Sorted.Count - 1 do Cb.Items.Add(Sorted[I]);
    Cb.ItemIndex := 0;
    No := TButton.Create(F);
    No.Parent := F;
    No.SetBounds(196, 134, 92, 30);
    No.Caption := SBimCancel;
    No.ModalResult := mrCancel;
    No.Cancel := True;
    Ok := TButton.Create(F);
    Ok.Parent := F;
    Ok.SetBounds(292, 134, 92, 30);
    Ok.Caption := SBimCreate;
    Ok.ModalResult := mrOk;
    Ok.Default := True;
    F.ActiveControl := E;
    if F.ShowModal <> mrOk then Exit;
    if Trim(E.Text) = '' then
    begin
      ShowMessage(SBimProjName);
      Exit;
    end;
    AName := Trim(E.Text);
    I := Cb.ItemIndex - 1;
    if (I >= 0) and (I < Sorted.Count) then Partner := A.Objects[PtrInt(Sorted.Objects[I])];
    Result := True;
  finally
    F.Free;
    Sorted.Free;
  end;
end;

procedure TForm1.BimProjAdd_click;
var
  P, Partner: TJSONObject;
  N: string;
begin
  if not AskBimProject(N, Partner) then Exit;
  P := Store.AddBimProject(N, Partner);
  BimProjKey := BimKey(P);
  BimBudKey := '';
  BimSelRef := '';
  LayoutNav;
  RefreshStatus;
  RefreshBim;
end;

procedure TForm1.BimBudSel_select;
var
  B: TJSONObject;
begin
  if (BimBudSel.ItemIndex < 0) or (BimBudSel.ItemIndex > High(BimBudRows)) then Exit;
  BimBudKey := BimKey(Store.List('bim_budgets').Objects[BimBudRows[BimBudSel.ItemIndex]]);
  BimSelRef := '';
  BimRowRef := '';
  BimOpen.Clear;
  B := CurBimBudget;
  // Uno de Odoo: sus conceptos se piden al abrirlo (si hay conexión).
  if (B <> nil) and (JInt(B, 'id') > 0) and (BimConcepts(B).Count = 0) and
    Online and not Busy and not SyncOffline.Checked then
  try
    Screen.Cursor := crHourGlass;
    try
      Sync.LoadBimConcepts(B);
      Store.Save;
    finally
      Screen.Cursor := crDefault;
    end;
  except
    on E: Exception do Fail(E, True);
  end;
  RefreshBimTree;
  BimPrepare(False);
end;

procedure TForm1.BimBudNew_click;
var
  P, B: TJSONObject;
  N: string;
begin
  P := CurBimProject;
  if P = nil then
  begin
    ShowMessage(SBimNoProject);
    Exit;
  end;
  N := Format(SBimNewBudget, [FormatDateTime('dd/mm/yyyy', Now)]);
  if not InputQuery(SBimNewBudgetTitle, SBimHintBud, N) then Exit;
  if Trim(N) = '' then Exit;
  B := Store.AddBimBudget(P, N);
  BimBudKey := BimKey(B);
  BimSelRef := '';
  BimRowRef := '';
  BimOpen.Clear;
  RefreshBimBudgets;
  BimPrepare(False);
end;

{ Dónde va un concepto nuevo de tipo T: como hijo de lo elegido o a su mismo
  nivel; el capítulo, arriba; la partida, en el capítulo más cercano; el
  recurso, en la partida más cercana. «?» si no hay dónde. }
function TForm1.BimParentFor(B: TJSONObject; const T: string): string;
var
  A: TJSONArray;
  I: Integer;
  ST: string;
begin
  if T = 'chapter' then Exit('');
  A := BimConcepts(B);
  I := BimIndex(A, BimSelRef);
  if BimSibMode and (I >= 0) then I := BimIndex(A, JStr(A.Objects[I], 'parent'));
  while I >= 0 do
  begin
    ST := JStr(A.Objects[I], 'type');
    if (T = 'departure') and (ST = 'chapter') then Exit(JStr(A.Objects[I], 'ref'));
    if BimIsResource(T) and (ST = 'departure') then Exit(JStr(A.Objects[I], 'ref'));
    I := BimIndex(A, JStr(A.Objects[I], 'parent'));
  end;
  Result := '?';
end;

{ Prepara el editor para un concepto nuevo: hijo de lo elegido (N) o a su
  mismo nivel (Mayús + N), con el tipo y el código que tocan. }
procedure TForm1.BimPrepare(Sibling: Boolean);
var
  B: TJSONObject;
  A: TJSONArray;
  S: Integer;
  ST: string;
begin
  B := CurBimBudget;
  BimSibMode := Sibling;
  BimRowRef := '';
  BimRows.ItemIndex := -1;
  if B = nil then Exit;
  A := BimConcepts(B);
  S := BimIndex(A, BimSelRef);
  if S >= 0 then ST := JStr(A.Objects[S], 'type') else ST := '';
  if Sibling then
  begin
    if ST = '' then BimType.ItemIndex := 0 else BimType.ItemIndex := BimTypeIndex(ST);
  end
  else if ST = '' then BimType.ItemIndex := 0
  else if ST = 'chapter' then BimType.ItemIndex := 1
  else if ST = 'departure' then BimType.ItemIndex := 2
  else BimType.ItemIndex := BimTypeIndex(ST);
  BimName.Text := '';
  BimUom.Text := '';
  BimQty.Text := '1';
  BimPrice.Text := '0';
  BimSuggestCode;
end;

procedure TForm1.BimSuggestCode;
var
  B: TJSONObject;
  T, Up: string;
begin
  B := CurBimBudget;
  if (B = nil) or (BimType.ItemIndex < 0) then Exit;
  T := BimTypeKeys[BimType.ItemIndex];
  BimQty.Enabled := T <> 'chapter';
  BimPrice.Enabled := T <> 'chapter';
  if BimRowRef <> '' then Exit; // se está cambiando uno que ya existe
  Up := BimParentFor(B, T);
  if Up = '?' then Up := '';
  BimCode.Text := BimNextCode(BimConcepts(B), T, Up);
end;

procedure TForm1.BimType_select;
begin
  BimSuggestCode;
end;

{ Clic en el árbol: el cuadrito ⊞/⊟ abre o cierra; el resto elige. }
procedure TForm1.BimTreeMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  B: TJSONObject;
  A: TJSONArray;
  R, I, Lv: Integer;
  Ref: string;
begin
  B := CurBimBudget;
  if (B = nil) or (Button <> mbLeft) then Exit;
  R := BimTree.ItemAtPos(Point(X, Y), True);
  if (R < 0) or (R > High(BimTreeRows)) then Exit;
  A := BimConcepts(B);
  I := BimTreeRows[R];
  Lv := BimLevel(A, I);
  if (X >= 6 + Lv * 18) and (X <= 20 + Lv * 18) and BimHasKids(A, I) then
  begin
    Ref := JStr(A.Objects[I], 'ref');
    if BimOpen.IndexOf(Ref) >= 0 then BimOpen.Delete(BimOpen.IndexOf(Ref))
    else BimOpen.Add(Ref);
    RefreshBimTree;
  end;
end;

procedure TForm1.BimTree_select;
var
  B: TJSONObject;
  A: TJSONArray;
begin
  B := CurBimBudget;
  if (B = nil) or (BimTree.ItemIndex < 0) or (BimTree.ItemIndex > High(BimTreeRows)) then Exit;
  A := BimConcepts(B);
  BimSelRef := JStr(A.Objects[BimTreeRows[BimTree.ItemIndex]], 'ref');
  BimRowRef := '';
  RefreshBimRows;
  BimPrepare(False);
end;

{ Elegir una fila de la tabla la carga en el editor (para cambiarla). }
procedure TForm1.BimRows_select;
var
  B, C: TJSONObject;
  A: TJSONArray;
  F: TFormatSettings;
begin
  B := CurBimBudget;
  if (B = nil) or (BimRows.ItemIndex < 0) or (BimRows.ItemIndex > High(BimRowRows)) then Exit;
  A := BimConcepts(B);
  C := A.Objects[BimRowRows[BimRows.ItemIndex]];
  BimRowRef := JStr(C, 'ref');
  F := DefaultFormatSettings;
  F.DecimalSeparator := Decimals;
  BimType.ItemIndex := BimTypeIndex(JStr(C, 'type'));
  BimCode.Text := JStr(C, 'code');
  BimName.Text := JStr(C, 'name');
  BimQty.Text := FormatFloat('0.####', JNum(C, 'qty'), F);
  BimPrice.Text := FormatFloat('0.00', JNum(C, 'price'), F);
  BimUom.Text := JStr(C, 'uom');
  BimQty.Enabled := JStr(C, 'type') <> 'chapter';
  BimPrice.Enabled := JStr(C, 'type') <> 'chapter';
end;

{ Abrir (doble clic, Intro o «Detalle»): entra en el concepto, como en BIM. }
procedure TForm1.BimOpenRow(R: Integer);
var
  B: TJSONObject;
  A: TJSONArray;
begin
  B := CurBimBudget;
  if (B = nil) or (R < 0) or (R > High(BimRowRows)) then Exit;
  A := BimConcepts(B);
  BimSelRef := JStr(A.Objects[BimRowRows[R]], 'ref');
  BimReveal(A, BimSelRef);
  if BimOpen.IndexOf(BimSelRef) < 0 then BimOpen.Add(BimSelRef);
  BimRowRef := '';
  RefreshBimTree;
  BimPrepare(False);
end;

procedure TForm1.BimRows_double;
begin
  BimOpenRow(BimRows.ItemIndex);
end;

procedure TForm1.BimRowsMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  R: Integer;
begin
  if Button <> mbLeft then Exit;
  R := BimRows.ItemAtPos(Point(X, Y), True);
  if (R >= 0) and (X >= 494) then BimOpenRow(R);
end;

procedure TForm1.BimHome_click;
begin
  BimSelRef := '';
  BimRowRef := '';
  BimTree.ItemIndex := -1;
  RefreshBimRows;
  BimPrepare(False);
end;

{ Los atajos del árbol de BIM: N añade un hijo, Mayús + N al mismo nivel,
  Supr elimina, Intro abre, U actualiza (envía) y E / Mayús + E abre o
  cierra todo. }
procedure TForm1.BimKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  B: TJSONObject;
  A: TJSONArray;
  I: Integer;
begin
  B := CurBimBudget;
  if B = nil then Exit;
  A := BimConcepts(B);
  case Key of
    VK_N:
      if BimEditable(B) then
      begin
        BimPrepare(ssShift in Shift);
        BimName.SetFocus;
        Key := 0;
      end;
    VK_DELETE, VK_BACK:
      begin
        BimDel_click;
        Key := 0;
      end;
    VK_RETURN:
      begin
        if Sender = BimRows then BimOpenRow(BimRows.ItemIndex);
        Key := 0;
      end;
    VK_U:
      begin
        BimSend_click;
        Key := 0;
      end;
    VK_E:
      begin
        BimOpen.Clear;
        if not (ssShift in Shift) then
          for I := 0 to A.Count - 1 do
            if not BimIsResource(JStr(A.Objects[I], 'type')) then
              BimOpen.Add(JStr(A.Objects[I], 'ref'));
        RefreshBimTree;
        Key := 0;
      end;
  end;
end;

{ Lee el editor; False (y avisa) si falta algo. }
function TForm1.BimRead(out T: string; out Q, Pr: Double): Boolean;
begin
  Result := False;
  if BimType.ItemIndex < 0 then BimType.ItemIndex := 0;
  T := BimTypeKeys[BimType.ItemIndex];
  if Trim(BimCode.Text) = '' then
  begin
    ShowMessage(SBimCodeRequired);
    BimCode.SetFocus;
    Exit;
  end;
  if Trim(BimName.Text) = '' then
  begin
    ShowMessage(SBimNameRequired);
    BimName.SetFocus;
    Exit;
  end;
  if T = 'chapter' then
  begin
    Q := 1;
    Pr := 0;
  end
  else if not ParseNum(BimQty.Text, Q) or (Q <= 0) or
    not ParseNum(BimPrice.Text, Pr) or (Pr < 0) then
  begin
    ShowMessage(SBimBadQty);
    BimQty.SetFocus;
    Exit;
  end;
  Result := True;
end;

{ Añade lo del editor: como hijo de lo elegido o a su mismo nivel. }
procedure TForm1.BimCommit;
var
  B, C: TJSONObject;
  T, Up, Err: string;
  Q, Pr: Double;
  A: TJSONArray;
begin
  B := CurBimBudget;
  if not BimEditable(B) then Exit;
  if not BimRead(T, Q, Pr) then Exit;
  Up := BimParentFor(B, T);
  if Up = '?' then
  begin
    if T = 'departure' then ShowMessage(SBimNeedChapter)
    else ShowMessage(SBimNeedDeparture);
    Exit;
  end;
  C := Store.AddConcept(B, Up, T, BimCode.Text, BimName.Text, Q, Pr, BimUom.Text, Err);
  if C = nil then
  begin
    ShowMessage(Err);
    Exit;
  end;
  A := BimConcepts(B);
  BimReveal(A, JStr(C, 'ref'));
  if (Up <> '') and (BimOpen.IndexOf(Up) < 0) then BimOpen.Add(Up);
  // Se queda elegido el padre: la tabla muestra lo que se va añadiendo.
  if Up <> '' then BimSelRef := Up else BimSelRef := '';
  BimRowRef := '';
  RefreshBimTree;
  BimPrepare(False);
  BimName.SetFocus;
end;

procedure TForm1.BimAdd_click;
begin
  BimSibMode := False;
  BimCommit;
end;

procedure TForm1.BimChild_click;
begin
  BimSibMode := False;
  BimCommit;
end;

procedure TForm1.BimSibling_click;
begin
  BimSibMode := True;
  BimCommit;
end;

{ Intro en el editor: cambia el elegido de la tabla o añade uno nuevo. }
procedure TForm1.BimEnter_key;
begin
  if BimRowRef <> '' then BimApply_click else BimCommit;
end;

procedure TForm1.BimApply_click;
var
  B, C: TJSONObject;
  A: TJSONArray;
  T: string;
  Q, Pr: Double;
  I: Integer;
begin
  B := CurBimBudget;
  if not BimEditable(B) then Exit;
  A := BimConcepts(B);
  I := BimIndex(A, BimRowRef);
  if I < 0 then
  begin
    ShowMessage(SBimChoose);
    Exit;
  end;
  C := A.Objects[I];
  if not BimRead(T, Q, Pr) then Exit;
  // Entre recursos se cambia el tipo; un capítulo o una partida, no.
  if (T <> JStr(C, 'type')) and not (BimIsResource(T) and BimIsResource(JStr(C, 'type'))) then
  begin
    ShowMessage(SBimTypeChange);
    Exit;
  end;
  C.Strings['type'] := T;
  C.Strings['code'] := Trim(BimCode.Text);
  C.Strings['name'] := Trim(BimName.Text);
  C.Floats['qty'] := Q;
  C.Floats['price'] := Pr;
  C.Strings['uom'] := Trim(BimUom.Text);
  B.Floats['amount'] := BimSum(A);
  Store.Save;
  RefreshBimTree;
end;

procedure TForm1.BimDel_click;
var
  B: TJSONObject;
  A: TJSONArray;
  I, Last: Integer;
  R: string;
begin
  B := CurBimBudget;
  if not BimEditable(B) then Exit;
  A := BimConcepts(B);
  // Lo elegido en la tabla o, si no, en el árbol.
  R := BimRowRef;
  if R = '' then R := BimSelRef;
  I := BimIndex(A, R);
  if I < 0 then
  begin
    ShowMessage(SBimChoose);
    Exit;
  end;
  if not Ask(Format(SBimDelAsk, [JStr(A.Objects[I], 'name')])) then Exit;
  if R = BimSelRef then BimSelRef := JStr(A.Objects[I], 'parent');
  Last := BimEnd(A, I);
  while Last >= I do
  begin
    A.Delete(Last);
    Dec(Last);
  end;
  B.Floats['amount'] := BimSum(A);
  Store.Save;
  BimRowRef := '';
  RefreshBimTree;
  BimPrepare(False);
end;

procedure TForm1.BimSend_click;
var
  B: TJSONObject;
  A: TJSONArray;
  I: Integer;
  Ok: Boolean;
begin
  B := CurBimBudget;
  if not BimEditable(B) then Exit;
  A := BimConcepts(B);
  Ok := False;
  for I := 0 to A.Count - 1 do
    if JStr(A.Objects[I], 'type') = 'departure' then Ok := True;
  if not Ok then
  begin
    ShowMessage(SBimEmpty);
    Exit;
  end;
  Store.SendBimBudget(B);
  RefreshAll;
  if Online and not SyncOffline.Checked then DoSync(True)
  else ShowMessage(SBimQueued);
end;

{ Una fila del árbol: ⊞/⊟, el icono del tipo y «[código] nombre». }
procedure TForm1.DrawBimNode(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  B, K: TJSONObject;
  A: TJSONArray;
  X, I, Lv: Integer;
  Sel: Boolean;
begin
  B := CurBimBudget;
  if (B = nil) or (Index < 0) or (Index > High(BimTreeRows)) then Exit;
  A := BimConcepts(B);
  I := BimTreeRows[Index];
  K := A.Objects[I];
  C := TListBox(Control).Canvas;
  Sel := JStr(K, 'ref') = BimSelRef;
  C.Brush.Style := bsSolid;
  if Sel then C.Brush.Color := CBimSelBg else C.Brush.Color := clWhite;
  C.FillRect(ARect);
  C.Pen.Color := CBimLine;
  C.Line(ARect.Left + 4, ARect.Bottom - 1, ARect.Right - 4, ARect.Bottom - 1);
  Lv := BimLevel(A, I);
  X := ARect.Left + 6 + Lv * 18;
  if BimHasKids(A, I) then
    BimToggle(C, X, ARect.Top + (ARect.Bottom - ARect.Top - 11) div 2,
      BimOpen.IndexOf(JStr(K, 'ref')) >= 0);
  BimIcon(C, X + 18, ARect.Top + (ARect.Bottom - ARect.Top - 16) div 2, JStr(K, 'type'));
  C.Brush.Style := bsClear;
  if Sel then
    Say(C, X + 38, ARect.Top + 9, '[' + JStr(K, 'code') + '] ' + JStr(K, 'name'),
      CBimTeal, 10, False, ARect.Right - X - 42)
  else
    Say(C, X + 38, ARect.Top + 9, '[' + JStr(K, 'code') + '] ' + JStr(K, 'name'),
      CBimInk, 10, False, ARect.Right - X - 42);
end;

{ Una fila de la tabla: Código, Nombre, Cantidad, Costo, Saldo y «Detalle»;
  los recursos, en cursiva (como en BIM). }
procedure TForm1.DrawBimRow(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
  B, K: TJSONObject;
  A: TJSONArray;
  I, Y, R: Integer;
  T: string;
  Res: Boolean;

  procedure Cell(Right: Integer; const S: string);
  begin
    C.Font.Size := 10;
    C.Font.Color := CBimInk;
    if Res then C.Font.Style := [fsItalic] else C.Font.Style := [];
    C.TextOut(ARect.Left + Right - C.TextWidth(S), Y, S);
  end;

begin
  B := CurBimBudget;
  if (B = nil) or (Index < 0) or (Index > High(BimRowRows)) then Exit;
  A := BimConcepts(B);
  I := BimRowRows[Index];
  K := A.Objects[I];
  T := JStr(K, 'type');
  Res := BimIsResource(T);
  C := TListBox(Control).Canvas;
  C.Brush.Style := bsSolid;
  if odSelected in State then C.Brush.Color := CBimSelBg else C.Brush.Color := clWhite;
  C.FillRect(ARect);
  C.Pen.Color := CBimLine;
  C.Line(ARect.Left, ARect.Bottom - 1, ARect.Right, ARect.Bottom - 1);
  // La casilla, como en la lista de Odoo.
  C.Brush.Color := clWhite;
  C.Pen.Color := $00C8C4C0;
  Y := ARect.Top + (ARect.Bottom - ARect.Top - 13) div 2;
  C.Rectangle(ARect.Left + 10, Y, ARect.Left + 23, Y + 13);
  C.Brush.Style := bsClear;
  Y := ARect.Top + 11;
  C.Font.Color := CBimInk;
  C.Font.Size := 10;
  if Res then C.Font.Style := [fsItalic] else C.Font.Style := [];
  C.TextOut(ARect.Left + 34, Y, Fit(C, JStr(K, 'code'), 64));
  R := 150;
  if JStr(K, 'uom') <> '' then
  begin
    C.TextOut(ARect.Left + 102, Y, Fit(C, JStr(K, 'name'), R - 34));
    C.Font.Color := CMuted;
    C.Font.Size := 9;
    C.TextOut(ARect.Left + 102 + R - 28, Y + 1, Fit(C, JStr(K, 'uom'), 30));
  end
  else C.TextOut(ARect.Left + 102, Y, Fit(C, JStr(K, 'name'), R));
  if T = 'chapter' then Cell(330, BimNum(1, '#,##0.0000'))
  else Cell(330, BimNum(JNum(K, 'qty'), '#,##0.0000'));
  Cell(410, BimNum(BimUnit(A, I), '#,##0.00'));
  Cell(488, BimNum(BimAmount(A, I), '#,##0.00'));
  // 👁 Detalle
  C.Pen.Color := CBimTeal;
  C.Brush.Style := bsClear;
  C.Ellipse(ARect.Left + 498, Y + 3, ARect.Left + 510, Y + 11);
  C.Brush.Style := bsSolid;
  C.Brush.Color := CBimTeal;
  C.Ellipse(ARect.Left + 502, Y + 5, ARect.Left + 506, Y + 9);
  C.Brush.Style := bsClear;
  C.Font.Color := CBimTeal;
  C.Font.Style := [];
  C.Font.Size := 10;
  C.TextOut(ARect.Left + 514, Y, SBimDetail);
end;

end.
''';
