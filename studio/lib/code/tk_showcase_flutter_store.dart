part of 'tk_examples.dart';

// Tienda: login, catálogo con búsqueda y categorías, ficha de producto,
// carrito y pago. Una app de Flutter al estilo de FlutterFlow.

TkExample _flutterStore(String Function(String) t) {
  String q(String s) => t(s).replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  final code =
      '''// ${t(markTr('Tienda: usuarios, productos, carrito y pedidos. Las pantallas lo usan como app.'))}
import 'package:flutter/material.dart';

class Producto {
  const Producto(this.nombre, this.categoria, this.precio, this.icono, this.color, this.descripcion);

  final String nombre, categoria, descripcion;
  final double precio;
  final IconData icono;
  final Color color;
}

class Linea {
  Linea(this.producto);

  final Producto producto;
  int cantidad = 1;

  double get total => producto.precio * cantidad;
}

class App extends ChangeNotifier {
  // ------------------------------------------------------------ usuarios
  /// Usuarios de prueba: correo → (contraseña, nombre).
  final _usuarios = {'demo@tienda.com': ('1234', 'Ana')};

  String email = '';
  String clave = '';
  String error = '';
  String? usuario;

  bool entrar() {
    final u = _usuarios[email.trim().toLowerCase()];
    if (u == null || u.\$1 != clave) {
      error = '${q(markTr('Correo o contraseña incorrectos.'))}';
      notifyListeners();
      return false;
    }
    usuario = u.\$2;
    error = '';
    clave = '';
    notifyListeners();
    return true;
  }

  void salir() {
    usuario = null;
    carrito.clear();
    notifyListeners();
  }

  // ------------------------------------------------------------ catálogo
  final productos = const [
    Producto('${q(markTr('Camiseta básica'))}', '${q(markTr('Ropa'))}', 12.90, Icons.checkroom, Color(0xFF26A69A), '${q(markTr('Algodón orgánico, corte recto. Tallas de la S a la XL.'))}'),
    Producto('${q(markTr('Sudadera con capucha'))}', '${q(markTr('Ropa'))}', 34.50, Icons.checkroom, Color(0xFF5C6BC0), '${q(markTr('Interior afelpado y bolsillo canguro.'))}'),
    Producto('${q(markTr('Lámpara de mesa'))}', '${q(markTr('Hogar'))}', 24.00, Icons.light, Color(0xFFFFA726), '${q(markTr('Luz cálida regulable, base de madera.'))}'),
    Producto('${q(markTr('Silla nórdica'))}', '${q(markTr('Hogar'))}', 59.00, Icons.chair, Color(0xFF8D6E63), '${q(markTr('Patas de haya y asiento acolchado.'))}'),
    Producto('${q(markTr('Auriculares'))}', '${q(markTr('Electrónica'))}', 79.99, Icons.headphones, Color(0xFF42A5F5), '${q(markTr('Inalámbricos, con cancelación de ruido y 30 h de batería.'))}'),
    Producto('${q(markTr('Reloj deportivo'))}', '${q(markTr('Electrónica'))}', 129.00, Icons.watch, Color(0xFFEF5350), '${q(markTr('GPS, pulso y resistente al agua.'))}'),
  ];

  String busqueda = '';
  String categoria = '';

  List<Producto> get visibles => productos
      .where((p) => categoria.isEmpty || p.categoria == categoria)
      .where((p) => p.nombre.toLowerCase().contains(busqueda.trim().toLowerCase()))
      .toList();

  void elegir(String c) {
    categoria = categoria == c ? '' : c;
    notifyListeners();
  }

  String precio(double v) => '\${v.toStringAsFixed(2).replaceAll('.', ',')} €';

  // ------------------------------------------------------------- carrito
  final carrito = <Linea>[];

  int get unidades => carrito.fold(0, (s, l) => s + l.cantidad);
  double get total => carrito.fold(0, (s, l) => s + l.total);

  void agregar(Producto p) {
    final l = carrito.where((l) => l.producto == p).firstOrNull;
    if (l == null) {
      carrito.add(Linea(p));
    } else {
      l.cantidad++;
    }
    notifyListeners();
  }

  void sumar(Linea l) {
    l.cantidad++;
    notifyListeners();
  }

  void quitar(Linea l) {
    if (--l.cantidad == 0) carrito.remove(l);
    notifyListeners();
  }

  // -------------------------------------------------------------- pedido
  int _numero = 1000;
  String ultimoPedido = '';

  void pagar() {
    if (carrito.isEmpty) return;
    ultimoPedido = 'PED-\${++_numero} · \${precio(total)}';
    carrito.clear();
    notifyListeners();
  }

  Future<void> start() async {}
}
''';
  FlNode cat(String c) => _n('Chip', {
    'text': c,
    'selected': "=app.categoria == '${c.replaceAll("'", r"\'")}'",
    'onTap': "app.elegir('${c.replaceAll("'", r"\'")}')",
  });
  final app = FlApp(
    title: t(markTr('Tienda')),
    primary: '#00897B',
    screens: [
      FlScreen(
        name: 'Login',
        appBar: false,
        body: _n('Center', {}, [
          _n(
            'Padding',
            {'padding': 28},
            [
              _n(
                'Column',
                {'main': 'center', 'gap': 14},
                [
                  _n('Icon', {
                    'icon': 'storefront',
                    'size': 72,
                    'color': 'primary',
                  }),
                  _n('Text', {
                    'text': t(markTr('Tienda')),
                    'style': 'headlineMedium',
                    'bold': true,
                    'align': 'center',
                  }),
                  _n('Text', {
                    'text': t(markTr('Entre para comprar')),
                    'align': 'center',
                    'style': 'bodyMedium',
                  }),
                  _n('TextField', {
                    'label': t(markTr('Correo')),
                    'icon': 'email',
                    'keyboard': 'email',
                    'bind': 'app.email',
                  }),
                  _n('TextField', {
                    'label': t(markTr('Contraseña')),
                    'icon': 'lock',
                    'obscure': true,
                    'bind': 'app.clave',
                    'onSubmit': 'if (app.entrar()) home:Catalogo',
                  }),
                  _n('Text', {
                    'text': r'${app.error}',
                    'color': 'error',
                    'visible': '=app.error.isNotEmpty',
                  }),
                  _n('Button', {
                    'text': t(markTr('Entrar')),
                    'icon': 'login',
                    'onTap': 'if (app.entrar()) home:Catalogo',
                  }),
                  _n('Text', {
                    'text': t(markTr('Pruebe con demo@tienda.com y 1234')),
                    'style': 'bodySmall',
                    'align': 'center',
                  }),
                ],
              ),
            ],
          ),
        ]),
      ),
      FlScreen(
        name: 'Catalogo',
        title: t(markTr('Hola, {0}')).replaceAll('{0}', r'${app.usuario}'),
        bar:
            'shopping_cart|go:Carrito|\${app.unidades}\n'
            'logout|app.salir(); home:Login',
        body: _n('Column', {}, [
          _n(
            'Padding',
            {'padding': 12},
            [
              _n('TextField', {
                'hint': t(markTr('Buscar productos')),
                'icon': 'search',
                'bind': 'app.busqueda',
              }),
            ],
          ),
          _n(
            'Padding',
            {'padding': 6},
            [
              _n(
                'Row',
                {'gap': 6, 'wrap': true},
                [
                  cat(t(markTr('Ropa'))),
                  cat(t(markTr('Hogar'))),
                  cat(t(markTr('Electrónica'))),
                ],
              ),
            ],
          ),
          _n(
            'ListView',
            {
              'items': '=app.visibles',
              'as': 'p',
              'padding': 8,
              'empty': t(markTr('No hay productos que coincidan.')),
            },
            [
              _n(
                'Card',
                {'padding': 10, 'onTap': 'go:Producto(p)'},
                [
                  _n(
                    'Row',
                    {'gap': 12},
                    [
                      _n(
                        'Container',
                        {
                          'width': 64,
                          'height': 64,
                          'radius': 14,
                          'color': '=p.color',
                        },
                        [
                          _n('Center', {}, [
                            _n('Icon', {
                              'icon': '=p.icono',
                              'size': 32,
                              'color': '#FFFFFF',
                            }),
                          ]),
                        ],
                      ),
                      _n('Expanded', {}, [
                        _n(
                          'Column',
                          {'cross': 'start', 'gap': 2},
                          [
                            _n('Text', {
                              'text': r'${p.nombre}',
                              'style': 'titleMedium',
                            }),
                            _n('Text', {
                              'text': r'${p.categoria}',
                              'style': 'bodySmall',
                            }),
                            _n('Text', {
                              'text': r'${app.precio(p.precio)}',
                              'bold': true,
                              'color': 'primary',
                            }),
                          ],
                        ),
                      ]),
                      _n('IconButton', {
                        'icon': 'add_shopping_cart',
                        'tooltip': t(markTr('Añadir al carrito')),
                        'onTap': 'app.agregar(p)',
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ]),
      ),
      FlScreen(
        name: 'Producto',
        title: r'${arg.nombre}',
        arg: 'Producto',
        bar: 'shopping_cart|go:Carrito|\${app.unidades}',
        body: _n(
          'Column',
          {'padding': 16, 'gap': 12},
          [
            _n(
              'Container',
              {'height': 220, 'radius': 24, 'color': '=arg.color'},
              [
                _n('Center', {}, [
                  _n('Icon', {
                    'icon': '=arg.icono',
                    'size': 110,
                    'color': '#FFFFFF',
                  }),
                ]),
              ],
            ),
            _n('Text', {
              'text': r'${arg.nombre}',
              'style': 'headlineSmall',
              'bold': true,
            }),
            _n('Chip', {'text': r'${arg.categoria}', 'icon': 'shopping_bag'}),
            _n('Text', {'text': r'${arg.descripcion}'}),
            _n('Text', {
              'text': r'${app.precio(arg.precio)}',
              'style': 'headlineMedium',
              'color': 'primary',
            }),
            _n('Spacer'),
            _n('Button', {
              'text': t(markTr('Añadir al carrito')),
              'icon': 'add_shopping_cart',
              'onTap': 'app.agregar(arg)',
            }),
            _n('Button', {
              'text': t(markTr('Ver el carrito')),
              'variant': 'outlined',
              'icon': 'shopping_cart',
              'onTap': 'go:Carrito',
            }),
          ],
        ),
      ),
      FlScreen(
        name: 'Carrito',
        title: t(markTr('Carrito')),
        body: _n('Column', {}, [
          _n(
            'ListView',
            {
              'items': '=app.carrito',
              'as': 'l',
              'separated': true,
              'empty': t(markTr('El carrito está vacío.')),
            },
            [
              _n('Row', {}, [
                _n('Expanded', {}, [
                  _n('ListTile', {
                    'title': r'${l.producto.nombre}',
                    'subtitle':
                        r'${l.cantidad} × ${app.precio(l.producto.precio)}',
                    'trailing': r'${app.precio(l.total)}',
                  }),
                ]),
                _n('IconButton', {
                  'icon': 'remove_circle_outline',
                  'onTap': 'app.quitar(l)',
                }),
                _n('IconButton', {
                  'icon': 'add_circle_outline',
                  'onTap': 'app.sumar(l)',
                }),
              ]),
            ],
          ),
          _n(
            'Padding',
            {'padding': 16},
            [
              _n(
                'Column',
                {'gap': 12},
                [
                  _n(
                    'Row',
                    {'main': 'spaceBetween'},
                    [
                      _n('Text', {
                        'text': t(markTr('Total')),
                        'style': 'titleLarge',
                      }),
                      _n('Text', {
                        'text': r'${app.precio(app.total)}',
                        'style': 'titleLarge',
                        'bold': true,
                      }),
                    ],
                  ),
                  _n('Button', {
                    'text': t(markTr('Pagar')),
                    'icon': 'payments',
                    'enabled': '=app.carrito.isNotEmpty',
                    'onTap': 'app.pagar(); go:Gracias',
                  }),
                ],
              ),
            ],
          ),
        ]),
      ),
      FlScreen(
        name: 'Gracias',
        appBar: false,
        body: _n('Center', {}, [
          _n(
            'Padding',
            {'padding': 28},
            [
              _n(
                'Column',
                {'main': 'center', 'cross': 'center', 'gap': 14},
                [
                  _n('Icon', {
                    'icon': 'check_circle',
                    'size': 96,
                    'color': 'primary',
                  }),
                  _n('Text', {
                    'text': t(
                      markTr('¡Gracias por su compra, {0}!'),
                    ).replaceAll('{0}', r'${app.usuario}'),
                    'style': 'headlineSmall',
                    'align': 'center',
                  }),
                  _n('Text', {
                    'text': r'${app.ultimoPedido}',
                    'align': 'center',
                  }),
                  _n('Button', {
                    'text': t(markTr('Seguir comprando')),
                    'icon': 'storefront',
                    'onTap': 'home:Catalogo',
                  }),
                ],
              ),
            ],
          ),
        ]),
      ),
    ],
  );
  return TkExample(
    'flutter_store',
    t(markTr('Tienda con login (Flutter)')),
    t(
      markTr(
        'Una app móvil de venta: login, catálogo con búsqueda y categorías, ficha de producto, carrito con cantidades y pago.',
      ),
    ),
    _flutterDesign(app),
    code,
  );
}
