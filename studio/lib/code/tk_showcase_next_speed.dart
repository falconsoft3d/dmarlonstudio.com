part of 'tk_examples.dart';

// --------------------------------------- velocidad de internet (Next.js)
/// Una web de Next.js con servidor que mide la conexión con su propio
/// servidor: el ping y el jitter, la bajada (cuatro descargas a la vez) y la
/// subida. El servidor (después de `// @server`) responde al eco, envía
/// bytes al azar y cuenta los que recibe.
TkExample _nextSpeed(String Function(String) t) {
  String tc(String id) {
    final k = contextKey('speed', id);
    final r = t(k);
    return r == k ? id : r;
  }

  final title = t(markTr('Velocidad de internet'));
  final texts = <String, String>{
    'LOCALE': t(markTr('es-ES')),
    'START': t(markTr('Empezar')),
    'STOP': tc(markTrc('speed', 'Parar')),
    'AGAIN': t(markTr('Medir otra vez')),
    'ERROR': t(markTr('No se pudo medir: {}')),
    'PHASE_IDLE': t(
      markTr(
        'Pulse Empezar: mide el ping, la bajada y la subida en unos 20 segundos.',
      ),
    ),
    'PHASE_PING': t(markTr('Midiendo el ping…')),
    'PHASE_DOWN': t(markTr('Midiendo la bajada…')),
    'PHASE_UP': t(markTr('Midiendo la subida…')),
    'PHASE_DONE': t(markTr('Listo. Se ha guardado en el historial.')),
    'JITTER': t(markTr('jitter {} ms')),
    'JITTER_NONE': t(markTr('jitter —')),
    'PING_MS': t(markTr('{} ms')),
    'ROW_TITLE': t(markTr('↓ {} · ↑ {} Mbps')),
    'NO_HISTORY': t(markTr('Aún no hay mediciones.')),
    'HISTORY_AVG': t(
      markTr('{} mediciones · de media ↓ {} · ↑ {} Mbps · {} ms'),
    ),
    'SERVER': t(markTr('Servidor: {} ({})')),
    'SERVER_UNKNOWN': t(markTr('Buscando el servidor…')),
    'YOUR_IP': t(markTr('su IP: {}')),
    'NEEDS': t(markTr('Necesita ↓ {} y ↑ {} Mbps')),
    'USE_WEB': t(markTr('Navegar y correo')),
    'USE_MUSIC': t(markTr('Música en streaming')),
    'USE_CALL': t(markTr('Videollamadas en HD')),
    'USE_HD': t(markTr('Vídeo en Full HD')),
    'USE_4K': t(markTr('Vídeo en 4K')),
    'USE_GAMES': t(markTr('Juegos en línea (ping bajo)')),
    'USE_HOME': t(markTr('Una casa con varias personas a la vez')),
    'USE_UPLOAD': t(markTr('Subir vídeos y copias a la nube')),
  };
  FlNode stat(String icon, String label, String value, String unit) =>
      _n('Expanded', {}, [
        _n(
          'Card',
          {'padding': 14},
          [
            _n(
              'Column',
              {'gap': 4, 'cross': 'start'},
              [
                _n(
                  'Row',
                  {'gap': 6},
                  [
                    _n('Icon', {'icon': icon, 'size': 18, 'color': 'primary'}),
                    _n('Text', {'text': label, 'style': 'labelLarge'}),
                  ],
                ),
                _n('Text', {
                  'text': value,
                  'style': 'headlineSmall',
                  'bold': true,
                }),
                _n('Text', {'text': unit, 'style': 'labelSmall'}),
              ],
            ),
          ],
        ),
      ]);
  final app = FlApp(
    title: title,
    primary: '#1FA2FF',
    dark: true,
    nav: [
      'Prueba|speed|${tc(markTrc('speed', 'Prueba'))}',
      'Historial|history|${t(markTr('Historial'))}',
    ].join('\n'),
    screens: [
      FlScreen(
        name: 'Prueba',
        title: title,
        body: _n(
          'Column',
          {'gap': 12, 'padding': 16},
          [
            _n('Canvas', {'paint': 'app.dibujar(ctx, w, h)', 'aspect': 1.7}),
            _n('Text', {
              'text': r'${app.estado}',
              'style': 'bodyMedium',
              'align': 'center',
            }),
            _n(
              'Row',
              {'gap': 10, 'cross': 'start'},
              [
                stat(
                  'timer',
                  t(markTr('Ping')),
                  r'${app.pingTexto}',
                  r'ms · ${app.jitterTexto}',
                ),
                stat(
                  'download',
                  t(markTr('Bajada')),
                  r'${app.bajadaTexto}',
                  'Mbps',
                ),
                stat(
                  'upload',
                  t(markTr('Subida')),
                  r'${app.subidaTexto}',
                  'Mbps',
                ),
              ],
            ),
            _n('Button', {
              'text': r'${app.boton}',
              'icon': '=app.botonIcono',
              'onTap': 'app.alternar()',
            }),
            _n(
              'Card',
              {'visible': '=app.hayUsos', 'padding': 14},
              [
                _n(
                  'Column',
                  {'gap': 6},
                  [
                    _n('Text', {
                      'text': t(markTr('Para qué le alcanza')),
                      'style': 'titleMedium',
                    }),
                    _n(
                      'ListView',
                      {'items': '=app.usos', 'as': 'u'},
                      [
                        _n('ListTile', {
                          'icon': '=u.icon',
                          'leadingColor': '=u.color',
                          'title': r'${u.what}',
                          'subtitle': r'${u.need}',
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            _n('Text', {'text': r'${app.servidor}', 'style': 'labelSmall'}),
            _n('Text', {
              'text': t(
                markTr(
                  'La medida es entre su navegador y el servidor de esta web: depende también de la wifi, del resto de la casa y de dónde esté el servidor.',
                ),
              ),
              'style': 'labelSmall',
            }),
          ],
        ),
      ),
      FlScreen(
        name: 'Historial',
        title: t(markTr('Historial')),
        body: _n(
          'Column',
          {'gap': 12, 'padding': 16},
          [
            _n('Text', {
              'text': r'${app.resumenHistorial}',
              'style': 'bodyMedium',
            }),
            _n(
              'ListView',
              {
                'items': '=app.filas',
                'as': 'f',
                'separated': true,
                'empty': t(
                  markTr('Las mediciones se guardan en este navegador.'),
                ),
              },
              [
                _n('ListTile', {
                  'icon': 'speed',
                  'title': r'${f.title}',
                  'subtitle': r'${f.sub}',
                  'trailing': r'${f.ping}',
                }),
              ],
            ),
            _n('Button', {
              'text': t(markTr('Borrar el historial')),
              'icon': 'delete',
              'variant': 'outlined',
              'onTap': 'app.borrar()',
            }),
          ],
        ),
      ),
    ],
  );
  final design = TkDesign(target: tkTargetWebNext, props: {'title': title});
  app.saveTo(design);
  final code =
      '''// ${t(markTr('Velocidad de internet: el ping, la bajada y la subida medidos con el servidor de la web (después de // @server).'))}
import { DmsApp, server, serverUrl } from "./dms";

// Los textos (los traduce el estudio con el resto del ejemplo).
const TX = ${const JsonEncoder.withIndent('  ').convert(texts)};
$_nextSpeedCode''';
  return TkExample(
    'next_speed',
    t(markTr('Velocidad de internet (Next.js)')),
    t(
      markTr(
        'Una web de Next.js con servidor que mide su conexión: el ping y el jitter, la bajada y la subida, con un indicador dibujado en un Lienzo, para qué le alcanza y el historial. El servidor envía y recibe los datos de la prueba.',
      ),
    ),
    design,
    code,
  );
}
