part of 'tk_examples.dart';

// Apps de Flutter al estilo de FlutterFlow: una de envíos y otra de tareas.

/// Los ejemplos de Flutter.
List<TkExample> tkFlutterExamples(String Function(String) t) => [
  _flutterStore(t),
  _flutterCloudNotes(t),
  _flutterInventory(t),
  _webStore(t),
  _rnStore(t),
  _reactStore(t),
  _htmlStore(t),
  _vueStore(t),
  _htmlDomino(t),
  _goStore(t),
  _nextWorld(t),
  _flutterShipping(t),
  _flutterTodo(t),
  ...tkShopMobileExamples(t),
];

TkDesign _flutterDesign(FlApp app) {
  final d = TkDesign(target: tkTargetFlutter, props: {'title': app.title});
  app.saveTo(d);
  return d;
}

FlNode _n(String type, [Map<String, Object?>? p, List<FlNode>? c]) =>
    FlNode(type, p, c);

// ------------------------------------------------------------------ envíos
TkExample _flutterShipping(String Function(String) t) {
  String q(String s) => t(s).replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  final code =
      '''// ${t(markTr('Envíos: los datos y la lógica de la app. Las pantallas los usan como app.'))}
import 'package:flutter/material.dart';

enum Estado { pendiente, enCamino, entregado }

String _hora(DateTime d) =>
    '\${d.day}/\${d.month} \${d.hour.toString().padLeft(2, '0')}:\${d.minute.toString().padLeft(2, '0')}';

class Envio {
  Envio(this.codigo, this.cliente, this.direccion, {this.estado = Estado.pendiente})
    : historial = ['\${_hora(DateTime.now())}  ${q(markTr('Registrado'))}'];

  final String codigo, cliente, direccion;
  Estado estado;
  final List<String> historial;
}

class App extends ChangeNotifier {
  final envios = <Envio>[
    Envio('ENV-1001', 'Ana Torres', 'Calle Mayor 12, Madrid', estado: Estado.enCamino),
    Envio('ENV-1002', 'Luis Pérez', 'Av. Diagonal 400, Barcelona'),
    Envio('ENV-1003', 'Marta Gil', 'Plaza Nueva 3, Sevilla', estado: Estado.entregado),
    Envio('ENV-1004', 'Jorge Ruiz', 'Calle Colón 25, Valencia'),
  ];

  /// Filtro de la lista (null: todos).
  Estado? filtro;

  /// Lo que se escribe en la pantalla «Nuevo».
  String nuevoCliente = '';
  String nuevaDireccion = '';
  int _siguiente = 1005;

  Future<void> start() async {}

  List<Envio> get visibles =>
      filtro == null ? envios : envios.where((e) => e.estado == filtro).toList();

  int cuantos(Estado e) => envios.where((x) => x.estado == e).length;

  void filtrar(Estado e) {
    filtro = filtro == e ? null : e;
    notifyListeners();
  }

  String texto(Estado e) => switch (e) {
    Estado.pendiente => '${q(markTr('Pendiente'))}',
    Estado.enCamino => '${q(markTr('En camino'))}',
    Estado.entregado => '${q(markTr('Entregado'))}',
  };

  Color color(Estado e) => switch (e) {
    Estado.pendiente => Colors.orange,
    Estado.enCamino => Colors.blue,
    Estado.entregado => Colors.green,
  };

  IconData icono(Estado e) => switch (e) {
    Estado.pendiente => Icons.inventory_2_outlined,
    Estado.enCamino => Icons.local_shipping,
    Estado.entregado => Icons.check_circle,
  };

  /// Fondo de la tarjeta de un estado: marcado si filtra por él.
  Color? fondo(Estado e) => filtro == e ? color(e).withValues(alpha: .18) : null;

  bool get puedeCrear =>
      nuevoCliente.trim().isNotEmpty && nuevaDireccion.trim().isNotEmpty;

  void crear() {
    if (!puedeCrear) return;
    envios.insert(
      0,
      Envio('ENV-\${_siguiente++}', nuevoCliente.trim(), nuevaDireccion.trim()),
    );
    nuevoCliente = '';
    nuevaDireccion = '';
    filtro = null;
    notifyListeners();
  }

  Estado? _despues(Estado e) => switch (e) {
    Estado.pendiente => Estado.enCamino,
    Estado.enCamino => Estado.entregado,
    Estado.entregado => null,
  };

  String siguientePaso(Envio e) {
    final s = _despues(e.estado);
    return s == null ? '${q(markTr('Entregado'))}' : '${q(markTr('Marcar como'))} \${texto(s).toLowerCase()}';
  }

  void avanzar(Envio e) {
    final s = _despues(e.estado);
    if (s == null) return;
    e.estado = s;
    e.historial.add('\${_hora(DateTime.now())}  \${texto(s)}');
    notifyListeners();
  }
}
''';
  FlNode stateCard(String estado, String label) => _n('Expanded', {}, [
    _n(
      'Card',
      {
        'onTap': 'app.filtrar(Estado.$estado)',
        'color': '=app.fondo(Estado.$estado)',
        'padding': 10,
      },
      [
        _n(
          'Column',
          {'cross': 'center', 'gap': 4},
          [
            _n('Icon', {
              'icon': '=app.icono(Estado.$estado)',
              'color': '=app.color(Estado.$estado)',
            }),
            _n('Text', {
              'text': '\${app.cuantos(Estado.$estado)}',
              'style': 'headlineSmall',
              'bold': true,
            }),
            _n('Text', {'text': label, 'style': 'labelSmall'}),
          ],
        ),
      ],
    ),
  ]);
  final app = FlApp(
    title: t(markTr('Envíos')),
    primary: '#1565C0',
    screens: [
      FlScreen(
        name: 'Envios',
        title: t(markTr('Envíos')),
        fabIcon: 'add',
        fabAction: 'go:Nuevo',
        body: _n('Column', {}, [
          _n(
            'Padding',
            {'padding': 12},
            [
              _n(
                'Row',
                {'gap': 8},
                [
                  stateCard('pendiente', t(markTr('Pendientes'))),
                  stateCard('enCamino', t(markTr('En camino'))),
                  stateCard('entregado', t(markTr('Entregados'))),
                ],
              ),
            ],
          ),
          _n(
            'ListView',
            {
              'items': '=app.visibles',
              'separated': true,
              'empty': t(markTr('No hay envíos con este estado.')),
            },
            [
              _n('ListTile', {
                'icon': '=app.icono(item.estado)',
                'leadingColor': '=app.color(item.estado)',
                'title': '\${item.codigo} · \${item.cliente}',
                'subtitle': '\${item.direccion}',
                'trailing': '\${app.texto(item.estado)}',
                'onTap': 'go:Detalle(item)',
              }),
            ],
          ),
        ]),
      ),
      FlScreen(
        name: 'Detalle',
        title: r'${arg.codigo}',
        arg: 'Envio',
        body: _n(
          'Column',
          {'padding': 12, 'gap': 8},
          [
            _n(
              'Card',
              {'padding': 4},
              [
                _n('Column', {}, [
                  _n('ListTile', {
                    'icon': 'person',
                    'title': r'${arg.cliente}',
                    'subtitle': t(markTr('Cliente')),
                  }),
                  _n('ListTile', {
                    'icon': 'place',
                    'title': r'${arg.direccion}',
                    'subtitle': t(markTr('Dirección')),
                  }),
                  _n('ListTile', {
                    'icon': '=app.icono(arg.estado)',
                    'leadingColor': '=app.color(arg.estado)',
                    'title': r'${app.texto(arg.estado)}',
                    'subtitle': t(markTr('Estado')),
                  }),
                ]),
              ],
            ),
            _n('Text', {
              'text': t(markTr('Seguimiento')),
              'style': 'titleMedium',
            }),
            _n(
              'ListView',
              {'items': '=arg.historial', 'as': 'paso'},
              [
                _n('ListTile', {'icon': 'history', 'title': r'${paso}'}),
              ],
            ),
            _n('Button', {
              'text': r'${app.siguientePaso(arg)}',
              'icon': 'local_shipping',
              'visible': '=arg.estado != Estado.entregado',
              'onTap': 'app.avanzar(arg)',
            }),
          ],
        ),
      ),
      FlScreen(
        name: 'Nuevo',
        title: t(markTr('Nuevo envío')),
        body: _n(
          'Column',
          {'padding': 16, 'gap': 12},
          [
            _n('TextField', {
              'label': t(markTr('Cliente')),
              'icon': 'person',
              'bind': 'app.nuevoCliente',
            }),
            _n('TextField', {
              'label': t(markTr('Dirección')),
              'icon': 'place',
              'bind': 'app.nuevaDireccion',
            }),
            _n('Button', {
              'text': t(markTr('Crear envío')),
              'icon': 'add',
              'enabled': '=app.puedeCrear',
              'onTap': 'app.crear(); back',
            }),
          ],
        ),
      ),
    ],
  );
  return TkExample(
    'flutter_shipping',
    t(markTr('Envíos (Flutter)')),
    t(
      markTr(
        'Una app móvil de envíos: resumen por estado, lista con filtro, detalle con seguimiento y alta de envíos.',
      ),
    ),
    _flutterDesign(app),
    code,
  );
}

// ------------------------------------------------------------------ tareas
TkExample _flutterTodo(String Function(String) t) {
  String q(String s) => t(s).replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  final code =
      '''// ${t(markTr('Tareas: los datos y la lógica de la app. Se guardan en el teléfono con shared_preferences.'))}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tarea {
  Tarea(this.titulo, {this.hecha = false});

  String titulo;
  bool hecha;

  Map<String, Object> toJson() => {'titulo': titulo, 'hecha': hecha};

  static Tarea fromJson(Map j) =>
      Tarea('\${j['titulo']}', hecha: j['hecha'] == true);
}

class App extends ChangeNotifier {
  final tareas = <Tarea>[];

  /// Lo que se escribe en el campo de arriba.
  String nueva = '';

  /// todas, pendientes o hechas.
  String filtro = 'todas';

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final guardadas = prefs.getString('tareas');
    if (guardadas == null) {
      tareas.addAll([
        Tarea('${q(markTr('Comprar pan'))}'),
        Tarea('${q(markTr('Llamar al dentista'))}'),
        Tarea('${q(markTr('Probar DMarlon Studio'))}', hecha: true),
      ]);
    } else {
      for (final j in jsonDecode(guardadas) as List) {
        tareas.add(Tarea.fromJson(j as Map));
      }
    }
    notifyListeners();
  }

  List<Tarea> get visibles => switch (filtro) {
    'pendientes' => tareas.where((t) => !t.hecha).toList(),
    'hechas' => tareas.where((t) => t.hecha).toList(),
    _ => tareas,
  };

  int get pendientes => tareas.where((t) => !t.hecha).length;

  bool get hayHechas => tareas.any((t) => t.hecha);

  void agregar() {
    final titulo = nueva.trim();
    if (titulo.isEmpty) return;
    tareas.insert(0, Tarea(titulo));
    nueva = '';
    _guardar();
  }

  void alternar(Tarea t) {
    t.hecha = !t.hecha;
    _guardar();
  }

  void borrar(Tarea t) {
    tareas.remove(t);
    _guardar();
  }

  void limpiarHechas() {
    tareas.removeWhere((t) => t.hecha);
    _guardar();
  }

  void filtrar(String f) {
    filtro = f;
    notifyListeners();
  }

  Future<void> _guardar() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tareas',
      jsonEncode([for (final t in tareas) t.toJson()]),
    );
  }
}
''';
  FlNode chip(String value, String label) => _n('Chip', {
    'text': label,
    'selected': "=app.filtro == '$value'",
    'onTap': "app.filtrar('$value')",
  });
  final app = FlApp(
    title: t(markTr('Tareas')),
    primary: '#6A1B9A',
    packages: ['shared_preferences: ^2.3.0'],
    screens: [
      FlScreen(
        name: 'Tareas',
        title: t(markTr('Tareas')),
        body: _n('Column', {}, [
          _n(
            'Padding',
            {'padding': 12},
            [
              _n(
                'Row',
                {'gap': 8},
                [
                  _n('Expanded', {}, [
                    _n('TextField', {
                      'hint': t(markTr('Nueva tarea')),
                      'bind': 'app.nueva',
                      'onSubmit': 'app.agregar()',
                    }),
                  ]),
                  _n('Button', {
                    'text': t(markTr('Añadir')),
                    'icon': 'add',
                    'onTap': 'app.agregar()',
                  }),
                ],
              ),
            ],
          ),
          _n(
            'Padding',
            {'padding': 8},
            [
              _n(
                'Row',
                {'gap': 8, 'wrap': true},
                [
                  chip('todas', t(markTr('Todas'))),
                  chip('pendientes', t(markTr('Pendientes'))),
                  chip('hechas', t(markTr('Hechas'))),
                ],
              ),
            ],
          ),
          _n(
            'Padding',
            {'padding': 12},
            [
              _n('Text', {
                'text': '\${app.pendientes} ${t(markTr('pendientes'))}',
                'style': 'labelLarge',
                'color': 'primary',
              }),
            ],
          ),
          _n(
            'ListView',
            {
              'items': '=app.visibles',
              'separated': true,
              'empty': t(markTr('¡Nada por hacer!')),
            },
            [
              _n(
                'Padding',
                {'padding': 4},
                [
                  _n(
                    'Row',
                    {'gap': 4},
                    [
                      _n('Checkbox', {
                        'value': '=item.hecha',
                        'onChanged': 'app.alternar(item)',
                      }),
                      _n('Expanded', {}, [
                        _n('Text', {
                          'text': r'${item.titulo}',
                          'strike': '=item.hecha',
                        }),
                      ]),
                      _n('IconButton', {
                        'icon': 'delete_outline',
                        'tooltip': t(markTr('Borrar')),
                        'onTap': 'app.borrar(item)',
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
          _n(
            'Padding',
            {'padding': 8},
            [
              _n('Button', {
                'text': t(markTr('Borrar las hechas')),
                'variant': 'text',
                'icon': 'cleaning_services',
                'visible': '=app.hayHechas',
                'onTap': 'app.limpiarHechas()',
              }),
            ],
          ),
        ]),
      ),
    ],
  );
  return TkExample(
    'flutter_todo',
    t(markTr('Tareas (Flutter)')),
    t(
      markTr(
        'Una app móvil de tareas: añadir, marcar como hechas, filtrar y borrar, guardadas en el teléfono.',
      ),
    ),
    _flutterDesign(app),
    code,
  );
}
