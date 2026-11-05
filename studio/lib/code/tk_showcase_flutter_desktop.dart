part of 'tk_examples.dart';

// Inventario: una app de escritorio con Flutter, con menú lateral (panel y
// productos), ficha de producto y alta.

TkExample _flutterInventory(String Function(String) t) {
  String q(String s) => t(s).replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  final code =
      '''// ${t(markTr('Inventario: productos, existencias y avisos de poco stock. Las pantallas lo usan como app.'))}
import 'package:flutter/material.dart';

class Producto {
  Producto(this.nombre, this.categoria, this.stock, this.precio, {this.minimo = 5});

  String nombre, categoria;
  int stock, minimo;
  double precio;

  bool get bajo => stock <= minimo;
}

class App extends ChangeNotifier {
  final productos = <Producto>[
    Producto('${q(markTr('Tornillos M6'))}', '${q(markTr('Ferretería'))}', 240, 0.08, minimo: 100),
    Producto('${q(markTr('Taladro'))}', '${q(markTr('Herramientas'))}', 4, 89.90),
    Producto('${q(markTr('Cinta métrica'))}', '${q(markTr('Herramientas'))}', 18, 7.50),
    Producto('${q(markTr('Guantes de trabajo'))}', '${q(markTr('Protección'))}', 3, 5.25),
    Producto('${q(markTr('Pintura blanca 5 L'))}', '${q(markTr('Pintura'))}', 12, 24.00),
  ];

  String busqueda = '';
  String nuevoNombre = '';
  String nuevaCategoria = '';
  String nuevoStock = '';
  String nuevoPrecio = '';

  Future<void> start() async {}

  List<Producto> get visibles => productos
      .where((p) => '\${p.nombre} \${p.categoria}'.toLowerCase().contains(busqueda.trim().toLowerCase()))
      .toList();

  List<Producto> get bajos => productos.where((p) => p.bajo).toList();

  int get unidades => productos.fold(0, (s, p) => s + p.stock);

  String get valor => euros(productos.fold(0.0, (s, p) => s + p.stock * p.precio));

  String euros(double v) => '\${v.toStringAsFixed(2).replaceAll('.', ',')} €';

  Color color(Producto p) => p.bajo ? Colors.orange : Colors.green;

  IconData icono(Producto p) => p.bajo ? Icons.warning : Icons.inventory_2_outlined;

  void sumar(Producto p, int n) {
    p.stock = (p.stock + n).clamp(0, 1000000);
    notifyListeners();
  }

  bool get puedeCrear =>
      nuevoNombre.trim().isNotEmpty && int.tryParse(nuevoStock.trim()) != null;

  void crear() {
    if (!puedeCrear) return;
    productos.add(Producto(
      nuevoNombre.trim(),
      nuevaCategoria.trim().isEmpty ? '${q(markTr('General'))}' : nuevaCategoria.trim(),
      int.parse(nuevoStock.trim()),
      double.tryParse(nuevoPrecio.replaceAll(',', '.')) ?? 0,
    ));
    nuevoNombre = nuevaCategoria = nuevoStock = nuevoPrecio = '';
    notifyListeners();
  }
}
''';
  FlNode kpi(String label, String value, String icon) => _n('Expanded', {}, [
    _n(
      'Card',
      {'padding': 16},
      [
        _n(
          'Column',
          {'cross': 'start', 'gap': 6},
          [
            _n('Icon', {'icon': icon, 'color': 'primary'}),
            _n('Text', {
              'text': value,
              'style': 'headlineMedium',
              'bold': true,
            }),
            _n('Text', {'text': label, 'style': 'labelLarge'}),
          ],
        ),
      ],
    ),
  ]);
  FlNode row() => _n('ListTile', {
    'icon': '=app.icono(p)',
    'leadingColor': '=app.color(p)',
    'title': r'${p.nombre}',
    'subtitle': r'${p.categoria} · ${app.euros(p.precio)}',
    'trailing': '\${p.stock} ${t(markTr('uds.'))}',
    'onTap': 'go:Producto(p)',
  });
  final app = FlApp(
    title: t(markTr('Inventario')),
    primary: '#00695C',
    nav: [
      'Panel|insights|${t(markTr('Panel'))}',
      'Productos|inventory_2_outlined|${t(markTr('Productos'))}',
    ].join('\n'),
    screens: [
      FlScreen(
        name: 'Panel',
        title: t(markTr('Panel')),
        body: _n(
          'Column',
          {'padding': 20, 'gap': 16},
          [
            _n(
              'Row',
              {'gap': 16},
              [
                kpi(
                  t(markTr('Productos')),
                  r'${app.productos.length}',
                  'inventory_2_outlined',
                ),
                kpi(t(markTr('Unidades')), r'${app.unidades}', 'all_inbox'),
                kpi(t(markTr('Valor del stock')), r'${app.valor}', 'payments'),
              ],
            ),
            _n('Text', {
              'text': t(markTr('Con poco stock')),
              'style': 'titleLarge',
            }),
            _n(
              'ListView',
              {
                'items': '=app.bajos',
                'as': 'p',
                'separated': true,
                'empty': t(
                  markTr('Todo en orden: nada por debajo del mínimo.'),
                ),
              },
              [row()],
            ),
          ],
        ),
      ),
      FlScreen(
        name: 'Productos',
        title: t(markTr('Productos')),
        fabIcon: 'add',
        fabAction: 'go:Nuevo',
        body: _n('Column', {}, [
          _n(
            'Padding',
            {'padding': 16},
            [
              _n('TextField', {
                'hint': t(markTr('Buscar por nombre o categoría')),
                'icon': 'search',
                'bind': 'app.busqueda',
              }),
            ],
          ),
          _n(
            'ListView',
            {
              'items': '=app.visibles',
              'as': 'p',
              'separated': true,
              'empty': t(markTr('No hay productos que coincidan.')),
            },
            [row()],
          ),
        ]),
      ),
      FlScreen(
        name: 'Producto',
        title: r'${arg.nombre}',
        arg: 'Producto',
        body: _n(
          'Column',
          {'padding': 24, 'gap': 16},
          [
            _n(
              'Row',
              {'gap': 16},
              [
                _n('Icon', {
                  'icon': '=app.icono(arg)',
                  'size': 48,
                  'color': '=app.color(arg)',
                }),
                _n('Expanded', {}, [
                  _n(
                    'Column',
                    {'cross': 'start', 'gap': 4},
                    [
                      _n('Text', {
                        'text': r'${arg.nombre}',
                        'style': 'headlineSmall',
                        'bold': true,
                      }),
                      _n('Text', {
                        'text': r'${arg.categoria} · ${app.euros(arg.precio)}',
                      }),
                    ],
                  ),
                ]),
              ],
            ),
            _n(
              'Card',
              {'padding': 20},
              [
                _n(
                  'Row',
                  {'main': 'spaceBetween'},
                  [
                    _n('Text', {
                      'text': t(markTr('Existencias')),
                      'style': 'titleMedium',
                    }),
                    _n('Text', {
                      'text': r'${arg.stock}',
                      'style': 'displaySmall',
                      'bold': true,
                    }),
                  ],
                ),
              ],
            ),
            _n('Text', {
              'text': t(
                markTr('Por debajo del mínimo ({0} uds.)'),
              ).replaceAll('{0}', r'${arg.minimo}'),
              'color': 'error',
              'visible': '=arg.bajo',
            }),
            _n(
              'Row',
              {'gap': 12},
              [
                _n('Button', {
                  'text': '-1',
                  'variant': 'outlined',
                  'icon': 'remove',
                  'onTap': 'app.sumar(arg, -1)',
                }),
                _n('Button', {
                  'text': '+1',
                  'variant': 'tonal',
                  'icon': 'add',
                  'onTap': 'app.sumar(arg, 1)',
                }),
                _n('Button', {
                  'text': '+10',
                  'icon': 'add',
                  'onTap': 'app.sumar(arg, 10)',
                }),
              ],
            ),
          ],
        ),
      ),
      FlScreen(
        name: 'Nuevo',
        title: t(markTr('Nuevo producto')),
        body: _n(
          'Column',
          {'padding': 24, 'gap': 14},
          [
            _n('TextField', {
              'label': t(markTr('Nombre')),
              'icon': 'inventory_2_outlined',
              'bind': 'app.nuevoNombre',
            }),
            _n('TextField', {
              'label': t(markTr('Categoría')),
              'icon': 'sell',
              'bind': 'app.nuevaCategoria',
            }),
            _n(
              'Row',
              {'gap': 12},
              [
                _n('Expanded', {}, [
                  _n('TextField', {
                    'label': t(markTr('Existencias')),
                    'keyboard': 'number',
                    'bind': 'app.nuevoStock',
                  }),
                ]),
                _n('Expanded', {}, [
                  _n('TextField', {
                    'label': t(markTr('Precio')),
                    'keyboard': 'number',
                    'bind': 'app.nuevoPrecio',
                  }),
                ]),
              ],
            ),
            _n(
              'Row',
              {'main': 'end', 'gap': 12},
              [
                _n('Button', {
                  'text': t(markTr('Cancelar')),
                  'variant': 'text',
                  'onTap': 'back',
                }),
                _n('Button', {
                  'text': t(markTr('Guardar')),
                  'icon': 'save',
                  'enabled': '=app.puedeCrear',
                  'onTap': 'app.crear(); back',
                }),
              ],
            ),
          ],
        ),
      ),
    ],
  );
  final d = TkDesign(
    target: tkTargetFlutterDesktop,
    props: {'title': app.title},
  );
  app.saveTo(d);
  return TkExample(
    'flutter_inventory',
    t(markTr('Inventario (Flutter escritorio)')),
    t(
      markTr(
        'Una app de escritorio con menú lateral: panel con cifras y avisos de poco stock, productos con búsqueda, ficha con existencias y alta.',
      ),
    ),
    d,
    code,
  );
}
