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
  final pageNames = [
    t(markTr('Panel')),
    t(markTr('Clientes')),
    t(markTr('Productos')),
    t(markTr('Ventas')),
    t(markTr('Punto de venta')),
    t(markTr('Sincronización')),
    t(markTr('Configuración')),
  ];
  const navNames = [
    'NavPanel',
    'NavCustomers',
    'NavProducts',
    'NavSales',
    'NavPos',
    'NavSync',
    'NavSettings',
  ];
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
                84 + i * 44,
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
            primary('CustSave', 16, 404, 140, 34, t(markTr('Guardar'))),
            'CustCard',
          ),
          inside(
            button('CustCancel', 168, 404, 140, 34, t(markTr('Cancelar'))),
            'CustCard',
          ),
          inside(
            text('CustInfo', 16, 452, 292, 140, '', fg: muted, size: 10),
            'CustCard',
          ),
          // Productos: lista con columnas.
          onPage(_w('Entry', 'ProdSearch', 20, oy + 16, 300, 28), 2),
          onPage(
            text(
              'ProdCount',
              336,
              oy + 16,
              544,
              28,
              '',
              fg: muted,
              anchor: 'e',
            ),
            2,
          ),
          onPage(box('ProdHeader', 20, oy + 56, 860, 28, '#e3e8ee'), 2),
          inside(
            text('LblPCode', 12, 2, 110, 24, t(markTr('Código')), fg: muted),
            'ProdHeader',
          ),
          inside(
            text('LblPName', 140, 2, 400, 24, t(markTr('Producto')), fg: muted),
            'ProdHeader',
          ),
          inside(
            text(
              'LblPPrice',
              560,
              2,
              130,
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
              700,
              2,
              130,
              24,
              t(markTr('Stock')),
              fg: muted,
              anchor: 'e',
            ),
            'ProdHeader',
          ),
          onPage(_w('Listbox', 'ProdList', 20, oy + 84, 860, 540), 2),
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
            _w('Listbox', 'SaleList', 20, oy + 56, 520, 540, const {}, {
              'double': 'SaleList_double',
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
                  'Los presupuestos necesitan el módulo Ventas en Odoo; con Inventario se ve también el stock.',
                ),
              ),
              fg: '#5c4813',
              size: 9,
            ),
            'HelpCard',
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
      Vat: string): TJSONObject;
    procedure EditPartner(P: TJSONObject; const Name, Email, Phone, Street,
      City, Vat: string);
    function AddOrder(Partner: TJSONObject; Lines: TJSONArray): TJSONObject;
    function AddPos(Partner: TJSONObject; Lines: TJSONArray;
      const Payment: string): TJSONObject;
    function CounterPartner: TJSONObject;
    function Pending: Integer;
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
    procedure Confirm(Id: Integer);
    function Deliver(Id: Integer): string;
    function Invoice(Id: Integer): string;
    procedure RunWizard(R: TJSONData);
    function Ids(const Model: string; Id: Integer; const Field: string): TJSONArray;
    procedure LoadCurrency;
  public
    Client: TOdooClient;
    Store: TOdooStore;
    OnLog: TOdooLog;
    SaleMissing: Boolean;
    constructor Create(AClient: TOdooClient; AStore: TOdooStore);
    procedure Log(const Line: string);
    procedure Connect;
    procedure Download;
    function Push: Integer;
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
    procedure ShowOrder(Index: Integer);
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
  if (S = 'draft') or (S = 'sent') then Result := 0
  else if S = 'cancel' then Result := 2
  else Result := 1;
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
  S: string;
begin
  if JBool(O, 'pos') then Exit(PosLabel(O));
  if JBool(O, 'pending') then Exit(SStPending);
  S := JStr(O, 'state');
  if S = 'draft' then Result := SStDraft
  else if S = 'sent' then Result := SStSent
  else if S = 'cancel' then Result := SStCancel
  else if S = 'done' then Result := SStDone
  else Result := SStSale;
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
  Result := KindColor(StateKind(O));
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
  if (K = 'order_create') or (K = 'pos_sale') then
  begin
    R := Store.Find('orders', 0, JStr(Op, 'ref'));
    if R = nil then Exit(SOpGone);
    if K = 'pos_sale' then
      Result := Format(SOpPos, [JStr(R, 'partner'), Money(JNum(R, 'amount'))])
    else
      Result := Format(SOpNewOrder, [JStr(R, 'partner'), Money(JNum(R, 'amount'))]);
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

function TOdooClient.Post(const Path, Body: string): string;
var
  C: TFPHTTPClient;
  Src, Res: TStringStream;
  I, P, Tries: Integer;
  H, V: string;
begin
  Result := '';
  if Base = '' then raise EOdoo.Make(oeConfig, SNoUrl);
  for Tries := 1 to 3 do
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
    Names := 'name,email,phone,mobile,street,city,vat,ref,is_company,customer,customer_rank,user_ids'
  else if Model = 'product.product' then
    Names := 'name,default_code,lst_price,list_price,qty_available,uom_id,sale_ok,categ_id'
  else if Model = 'sale.order' then
    Names := 'name,partner_id,date_order,amount_total,state,client_order_ref,' +
      'origin,picking_ids,invoice_ids'
  else if Model = 'sale.order.line' then
    Names := 'name,product_id,product_uom_qty,price_unit,product_uom,' +
      'product_uom_id,discount,qty_delivered,order_id'
  else if Model = 'stock.picking' then
    Names := 'name,state,move_ids,move_lines'
  else if Model = 'stock.move' then
    Names := 'product_uom_qty,quantity,quantity_done,picked,state'
  else if Model = 'sale.advance.payment.inv' then
    Names := 'advance_payment_method,sale_order_ids'
  else if (Model = 'account.invoice') or (Model = 'account.move') then
    Names := 'name,number,state'
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
  Vat: string): TJSONObject;
begin
  Result := TJSONObject.Create(['id', 0, 'ref', NewRef, 'name', Trim(Name),
    'email', Trim(Email), 'phone', Trim(Phone), 'street', Trim(Street),
    'city', Trim(City), 'vat', Trim(Vat), 'pending', True]);
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

procedure TOdooSync.Download;
const
  PosKeys: array[0..7] of string = ('pos', 'payment', 'step', 'picking',
    'invoice', 'error', 'lines', 'nostock');
var
  Rows, Fresh, Old: TJSONArray;
  R, O, Keep: TJSONObject;
  Dom: TJSONArray;
  I, J: Integer;
  Since: string;
begin
  // Clientes: customer = True hasta la 12; desde la 13, customer_rank > 0
  // (solo los que ya compraron) o los contactos que no son usuarios.
  if Client.Has('res.partner', 'customer_rank') and
    Client.Has('res.partner', 'user_ids') then
    Dom := TJSONArray(GetJSON('["|", ["customer_rank", ">", 0], ["user_ids", "=", false]]'))
  else if Client.Has('res.partner', 'customer_rank') then
    Dom := Domain1('customer_rank', '>', TJSONIntegerNumber.Create(0))
  else if Client.Has('res.partner', 'customer') then
    Dom := Domain1('customer', '=', TJSONBoolean.Create(True))
  else
    Dom := TJSONArray.Create;
  Rows := Client.SearchRead('res.partner', Dom, ['name', 'email', 'phone',
    'mobile', 'street', 'city', 'vat', 'ref', 'is_company'], 2000, 'name');
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
    'lst_price', 'list_price', 'qty_available', 'uom_id', 'categ_id'], 2000, 'name');
  Fresh := TJSONArray.Create;
  try
    for I := 0 to Rows.Count - 1 do
    begin
      R := Rows.Objects[I];
      O := TJSONObject.Create(['id', JInt(R, 'id'), 'name', JStr(R, 'name'),
        'code', JStr(R, 'default_code'), 'uom', M2OId(R, 'uom_id'),
        'categ', M2OName(R, 'categ_id')]);
      // «All / Saleable / Office» → «Office»
      while Pos(' / ', JStr(O, 'categ')) > 0 do
        O.Strings['categ'] := Copy(JStr(O, 'categ'), Pos(' / ', JStr(O, 'categ')) + 3, MaxInt);
      if R.Find('lst_price') <> nil then O.Floats['price'] := JNum(R, 'lst_price')
      else O.Floats['price'] := JNum(R, 'list_price');
      if R.Find('qty_available') <> nil then O.Floats['qty'] := JNum(R, 'qty_available');
      Fresh.Add(O);
    end;
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
      'amount_total', 'state', 'client_order_ref'], 3000, 'date_order desc');
    try
      for I := 0 to Rows.Count - 1 do
      begin
        R := Rows.Objects[I];
        O := TJSONObject.Create(['id', JInt(R, 'id'), 'name', JStr(R, 'name'),
          'partner_id', M2OId(R, 'partner_id'), 'partner', M2OName(R, 'partner_id'),
          'date', JStr(R, 'date_order'), 'amount', JNum(R, 'amount_total'),
          'state', JStr(R, 'state'), 'ref', JStr(R, 'client_order_ref'),
          'pending', False]);
        // Lo del punto de venta (pago, pasos, entrega, factura y líneas) solo
        // está aquí: se conserva.
        Keep := Store.Find('orders', JInt(R, 'id'), '');
        if (Keep <> nil) and JBool(Keep, 'pos') then
          for J := 0 to High(PosKeys) do
            if Keep.Find(PosKeys[J]) <> nil then
              O.Elements[PosKeys[J]] := Keep.Elements[PosKeys[J]].Clone;
        Fresh.Add(O);
      end;
    finally
      Rows.Free;
    end;
  end;
  Store.Data.Arrays['orders'] := Fresh;

  LoadCurrency;
  Store.Data.Strings['last_sync'] := NowStamp;
  Store.Data.Objects['server'] := TJSONObject.Create(['url', Client.Base,
    'db', Client.Db, 'version', Client.Version, 'major', Client.Major]);
  Store.Save;
  Log(Format(SDownloaded, [Store.List('partners').Count,
    Store.List('products').Count, Store.List('orders').Count]));
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
    if Client.Has('res.partner', 'customer_rank') then Result.Add('customer_rank', 1)
    else if Client.Has('res.partner', 'customer') then Result.Add('customer', True);
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
  // Los presupuestos que esperaban a este cliente ya tienen su id.
  for I := 0 to Store.List('orders').Count - 1 do
  begin
    O := Store.List('orders').Objects[I];
    if (JInt(O, 'partner_id') = 0) and (JStr(O, 'partner_ref') = Ref) then
      O.Integers['partner_id'] := Id;
  end;
end;

{ Crea en Odoo el pedido de O (o lo encuentra por su referencia DMS-…, si
  un envío anterior llegó) y pone en O su id, nombre, estado e importe. }
function TOdooSync.EnsureOrder(O: TJSONObject): Integer;
var
  P, L, Vals, LV: TJSONObject;
  Lines, Cmd, Args: TJSONArray;
  R: TJSONData;
  PartnerId, Id, I: Integer;
  Ref, UomField: string;
begin
  if not Client.Exists('sale.order') then raise EOdoo.Make(oeServer, SSaleMissing);
  PartnerId := JInt(O, 'partner_id');
  if PartnerId = 0 then
  begin
    P := Store.Find('partners', 0, JStr(O, 'partner_ref'));
    if P <> nil then PartnerId := JInt(P, 'id');
  end;
  if PartnerId = 0 then raise EOdoo.Make(oeServer, SPartnerNotSent);
  Ref := JStr(O, 'ref');
  Id := Client.FindRef('sale.order', 'client_order_ref', Ref);
  if Id > 0 then Log(Format(SFoundOrder, [Ref]))
  else
  begin
    Vals := TJSONObject.Create(['partner_id', PartnerId, 'client_order_ref', Ref]);
    if Client.Has('sale.order', 'origin') then
      if JBool(O, 'pos') then
      begin
        if JStr(O, 'payment') = 'card' then Vals.Add('origin', 'TPV · ' + SCard)
        else Vals.Add('origin', 'TPV · ' + SCash);
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
    if Client.Has('sale.order.line', 'product_uom') then UomField := 'product_uom'
    else if Client.Has('sale.order.line', 'product_uom_id') then UomField := 'product_uom_id'
    else UomField := '';
    Lines := TJSONArray.Create;
    for I := 0 to O.Arrays['lines'].Count - 1 do
    begin
      L := O.Arrays['lines'].Objects[I];
      LV := TJSONObject.Create(['product_id', JInt(L, 'product_id'),
        'name', JStr(L, 'name'), 'product_uom_qty', JNum(L, 'qty'),
        'price_unit', JNum(L, 'price')]);
      if JNum(L, 'discount') <> 0 then LV.Add('discount', JNum(L, 'discount'));
      if (UomField <> '') and (JInt(L, 'uom') > 0) then LV.Add(UomField, JInt(L, 'uom'));
      Cmd := TJSONArray.Create([0, 0]);
      Cmd.Add(LV);
      Lines.Add(Cmd);
    end;
    Vals.Add('order_line', Lines);
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
  O.Booleans['pending'] := False;
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

procedure TOdooSync.PushOrder(Op: TJSONObject);
var
  O: TJSONObject;
begin
  O := Store.Find('orders', 0, JStr(Op, 'ref'));
  if O = nil then Exit;
  EnsureOrder(O);
  Log(Format(SSentOrder, [JStr(O, 'name'), JStr(O, 'partner')]));
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
  button_validate (do_new_transfer hasta la 10) y sus asistentes. }
function TOdooSync.Deliver(Id: Integer): string;
var
  Picks, Moves, Rows, Args: TJSONArray;
  P, M, Vals, K: TJSONObject;
  I, J: Integer;
  MoveField: string;
  R: TJSONData;
begin
  Result := '';
  Picks := Ids('sale.order', Id, 'picking_ids');
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
        if Client.Major <= 10 then R := Client.Kw('stock.picking', 'do_new_transfer', Args, K)
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
  (11-12) o la señal invoice_open del flujo (9-10). }
function TOdooSync.Invoice(Id: Integer): string;
var
  InvModel, Method, NameField: string;
  Invs, Rows, Args, Lines: TJSONArray;
  Ctx, Vals, K, L: TJSONObject;
  R: TJSONData;
  I, W, Live: Integer;

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
      Names := Deliver(Id);
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
      else if K = 'order_create' then PushOrder(Op)
      else if K = 'pos_sale' then PushPos(Op);
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
  StyleUi;
  LoadSettings;
  ShowPage(0);
  CustNew_click;
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
  Glyphs: array[0..6] of string = ('▦', '☺', '▣', '€', '▥', '↻', '⚙');
var
  I: Integer;
  Navs: array[0..6] of TDmsButton;
  Folder: string;
begin
  for I := 0 to ComponentCount - 1 do
    if (Components[I] is TPanel) and not (Components[I] is TDmsButton) then
      TPanel(Components[I]).BevelOuter := bvNone;
  Pages.ShowTabs := False;
  Navs[0] := NavPanel; Navs[1] := NavCustomers; Navs[2] := NavProducts;
  Navs[3] := NavSales; Navs[4] := NavPos; Navs[5] := NavSync;
  Navs[6] := NavSettings;
  for I := 0 to 6 do
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
  OwnerDraw(RecentList, 38, @DrawRecent);
  OwnerDraw(Outbox, 46, @DrawOutbox);
  OwnerDraw(PosLines, 40, @DrawPosLine);
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
  for I := 0 to 6 do
  begin
    case I of
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
  Total: Double;
begin
  A := Store.List('orders');
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
      CustCity.Text, CustVat.Text)
  else
  begin
    P := Editing;
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

procedure TForm1.ShowOrder(Index: Integer);
var
  O, L: TJSONObject;
  S: string;
  I: Integer;
begin
  O := Store.List('orders').Objects[Index];
  if JBool(O, 'pos') then
  begin
    ShowMessage(Receipt(O));
    Exit;
  end;
  S := Format(SOrderInfo, [OrderTitle(O), JStr(O, 'partner'),
    ShortDate(JStr(O, 'date')), Money(JNum(O, 'amount')), StateLabel(O)]);
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
    ShowOrder(SaleRows[SaleList.ItemIndex]);
end;

procedure TForm1.RecentList_double;
begin
  if (RecentList.ItemIndex >= 0) and (RecentList.ItemIndex <= High(RecentRows)) then
    ShowOrder(RecentRows[RecentList.ItemIndex]);
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
    if JInt(Draft.Objects[I], 'product_id') = JInt(P, 'id') then
    begin
      L := Draft.Objects[I];
      L.Floats['qty'] := JNum(L, 'qty') + Q;
      RefreshDraft;
      Exit;
    end;
  Draft.Add(TJSONObject.Create(['product_id', JInt(P, 'id'), 'name',
    JStr(P, 'name'), 'qty', Q, 'price', JNum(P, 'price'), 'uom', JInt(P, 'uom')]));
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
  RefreshAll;
  if Online and not SyncOffline.Checked then DoSync(True);
  ShowMessage(SQuoteSaved);
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
begin
  if Outbox.ItemIndex < 0 then
  begin
    ShowMessage(SChooseOp);
    Exit;
  end;
  if not Ask(SDiscardAsk) then Exit;
  Op := Store.List('outbox').Objects[Outbox.ItemIndex];
  K := JStr(Op, 'op');
  if (K = 'order_create') or (K = 'pos_sale') then
  begin
    // Lo que ya está en Odoo se queda en la lista; lo que no, se borra.
    A := Store.List('orders');
    R := Store.Find('orders', 0, JStr(Op, 'ref'));
    if (R <> nil) and (JInt(R, 'id') = 0) then A.Remove(R);
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
  Store.List('outbox').Delete(Outbox.ItemIndex);
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
begin
  if (Index < 0) or (Index > High(ProdRows)) then Exit;
  C := TListBox(Control).Canvas;
  P := Store.List('products').Objects[ProdRows[Index]];
  Row(C, ARect, odSelected in State);
  Say(C, ARect.Left + 12, ARect.Top + 6, JStr(P, 'code'), CMuted, 9, False, 116);
  Say(C, ARect.Left + 140, ARect.Top + 6, JStr(P, 'name'), CInk, 10, False, 410);
  TextRight(C, ARect.Left + 690, ARect.Top + 6, Money(JNum(P, 'price')), CInk, 10, True);
  if P.Find('qty') <> nil then
  begin
    F := DefaultFormatSettings;
    F.DecimalSeparator := Decimals;
    F.ThousandSeparator := Thousands;
    Stock := FormatFloat('#,##0.##', JNum(P, 'qty'), F);
  end
  else Stock := SNoStock;
  if JNum(P, 'qty') < 0 then
    TextRight(C, ARect.Left + 830, ARect.Top + 6, Stock, clRed, 10, False)
  else
    TextRight(C, ARect.Left + 830, ARect.Top + 6, Stock, CMuted, 10, False);
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
    if (JInt(L, 'product_id') = JInt(P, 'id')) and (JNum(L, 'discount') = 0) then
    begin
      L.Floats['qty'] := JNum(L, 'qty') + 1;
      RefreshCart;
      PosLines.ItemIndex := I;
      PosLines_select;
      Exit;
    end;
  end;
  Cart.Add(TJSONObject.Create(['product_id', JInt(P, 'id'), 'name', JStr(P, 'name'),
    'qty', 1, 'price', JNum(P, 'price'), 'discount', 0, 'uom', JInt(P, 'uom')]));
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

end.
''';
