part of 'tk_examples.dart';

// Notas en la nube: login y una tabla de FalconDatabase desde una app de
// Flutter. La conexión se pone en las propiedades de la app (Base de datos).

TkExample _flutterCloudNotes(String Function(String) t) {
  String q(String s) => t(s).replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  final code =
      '''// ${t(markTr('Notas en la nube: login y la tabla notas de FalconDatabase (con lib/db.dart).'))}
// ${t(markTr('En FalconDatabase: active el login, cree un usuario y una tabla notas con la columna texto y el acceso «authenticated». Después ponga la referencia del proyecto y la clave anon en las propiedades de la app.'))}
import 'package:flutter/material.dart';

import 'db.dart';

class App extends ChangeNotifier {
  String email = '';
  String clave = '';
  String error = '';
  String nueva = '';
  bool cargando = false;
  List<Map<String, dynamic>> notas = [];

  bool get configurada => db.configured;
  String get usuario => '\${db.user?['email'] ?? ''}';

  Future<void> start() async {}

  Future<bool> entrar() async {
    error = '';
    try {
      await db.signIn(email, clave);
      clave = '';
      await cargar();
      return true;
    } on DbError catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> cargar() async {
    cargando = true;
    notifyListeners();
    try {
      notas = await db.table('notas').list(order: 'id.desc');
      error = '';
    } on DbError catch (e) {
      error = e.message;
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> agregar() async {
    final texto = nueva.trim();
    if (texto.isEmpty) return;
    try {
      final nota = await db.table('notas').insert({'texto': texto});
      notas.insert(0, nota);
      nueva = '';
    } on DbError catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> borrar(Map<String, dynamic> nota) async {
    try {
      await db.table('notas').delete(nota['id']);
      notas.remove(nota);
    } on DbError catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  String fecha(Map<String, dynamic> nota) {
    final d = DateTime.tryParse('\${nota['created_at']}')?.toLocal();
    return d == null ? '' : '\${d.day}/\${d.month}/\${d.year} \${d.hour}:\${d.minute.toString().padLeft(2, '0')}';
  }

  void salir() {
    db.signOut();
    notas = [];
    notifyListeners();
  }

  String get aviso => configurada
      ? ''
      : '${q(markTr('Falta la conexión: ponga la referencia del proyecto y la clave anon de FalconDatabase en las propiedades de la app (Base de datos).'))}';
}
''';
  final app = FlApp(
    title: t(markTr('Notas en la nube')),
    primary: '#3949AB',
    backend: const FlBackend(kind: 'falcon'),
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
                  _n('Icon', {'icon': 'cloud', 'size': 72, 'color': 'primary'}),
                  _n('Text', {
                    'text': t(markTr('Notas en la nube')),
                    'style': 'headlineMedium',
                    'bold': true,
                    'align': 'center',
                  }),
                  _n('Text', {
                    'text': r'${app.aviso}',
                    'color': 'error',
                    'align': 'center',
                    'visible': '=!app.configurada',
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
                    'onSubmit': 'if (await app.entrar()) home:Notas',
                  }),
                  _n('Text', {
                    'text': r'${app.error}',
                    'color': 'error',
                    'visible': '=app.error.isNotEmpty',
                  }),
                  _n('Button', {
                    'text': t(markTr('Entrar')),
                    'icon': 'login',
                    'enabled': '=app.configurada',
                    'onTap': 'if (await app.entrar()) home:Notas',
                  }),
                ],
              ),
            ],
          ),
        ]),
      ),
      FlScreen(
        name: 'Notas',
        title: t(markTr('Mis notas')),
        bar: 'refresh|app.cargar()\nlogout|app.salir(); home:Login',
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
                      'hint': t(markTr('Escriba una nota')),
                      'bind': 'app.nueva',
                      'onSubmit': 'app.agregar()',
                    }),
                  ]),
                  _n('Button', {
                    'text': t(markTr('Guardar')),
                    'icon': 'send',
                    'onTap': 'app.agregar()',
                  }),
                ],
              ),
            ],
          ),
          _n('Progress', {'visible': '=app.cargando'}),
          _n('Text', {
            'text': r'${app.error}',
            'color': 'error',
            'visible': '=app.error.isNotEmpty',
          }),
          _n(
            'ListView',
            {
              'items': '=app.notas',
              'as': 'nota',
              'separated': true,
              'empty': t(markTr('Aún no hay notas.')),
            },
            [
              _n('Row', {}, [
                _n('Expanded', {}, [
                  _n('ListTile', {
                    'icon': 'sticky_note_2',
                    'title': r"${nota['texto']}",
                    'subtitle': r'${app.fecha(nota)}',
                  }),
                ]),
                _n('IconButton', {
                  'icon': 'delete_outline',
                  'tooltip': t(markTr('Borrar')),
                  'onTap': 'app.borrar(nota)',
                }),
              ]),
            ],
          ),
        ]),
      ),
    ],
  );
  return TkExample(
    'flutter_cloud_notes',
    t(markTr('Notas en la nube (Flutter + FalconDatabase)')),
    t(
      markTr(
        'Una app móvil con login y notas guardadas en FalconDatabase: ponga la conexión en las propiedades de la app.',
      ),
    ),
    _flutterDesign(app),
    code,
  );
}
