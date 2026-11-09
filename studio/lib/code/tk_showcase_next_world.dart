part of 'tk_examples.dart';

// --------------------------------------- el mundo en directo (Next.js)
/// Una web de Next.js con servidor: un mapa del mundo (un Lienzo) con los
/// aviones (OpenSky Network o adsb.lol), los barcos (el AIS del mar Báltico
/// de Fintraffic) y los trenes (Renfe Cercanías y VR de Finlandia) en
/// directo. El navegador solo habla con su servidor (lo que va después de
/// `// @server`), que descarga las APIs públicas, las junta y las guarda un
/// rato en memoria.
TkExample _nextWorld(String Function(String) t) {
  String tc(String id) {
    final k = contextKey('world', id);
    final r = t(k);
    return r == k ? id : r;
  }

  final title = t(markTr('El mundo en directo'));
  final texts = <String, String>{
    'LOCALE': t(markTr('es-ES')),
    'PLANES': t(markTr('Aviones')),
    'SHIPS': t(markTr('Barcos')),
    'TRAINS': t(markTr('Trenes')),
    'PLANE': t(markTr('Avión')),
    'SHIP_FISHING': t(markTr('Pesquero')),
    'SHIP_TUG': t(markTr('Remolcador')),
    'SHIP_PLEASURE': t(markTr('Recreo o vela')),
    'SHIP_SERVICE': t(markTr('Servicio del puerto')),
    'SHIP_PASSENGER': t(markTr('Pasaje')),
    'SHIP_CARGO': t(markTr('Carga')),
    'SHIP_TANKER': t(markTr('Petrolero o cisterna')),
    'SHIP_OTHER': tc(markTrc('world', 'Otro')),
    'TO_DEST': t(markTr('Rumbo a {}')),
    'NO_DEST': t(markTr('Sin destino declarado')),
    'ON_GROUND': t(markTr('En tierra')),
    'KNOTS': t(markTr('nudos')),
    'ALTITUDE': t(markTr('Altitud: {} ({})')),
    'HEADING': t(markTr('Rumbo {}°')),
    'LINE': t(markTr('Línea {}')),
    'NO_SPEED': t(markTr('Sin dato de velocidad')),
    'SPAIN': t(markTr('Renfe Cercanías · España')),
    'FINLAND': t(markTr('VR · Finlandia')),
    'TRAIN_RENFE': t(markTr('Cercanías')),
    'TRAIN_VR': t(markTr('Tren')),
    'ERROR': t(markTr('No se pudieron leer los datos: {}')),
    'LOADING': t(markTr('Cargando los datos…')),
    'LOADING_MAP': t(markTr('Cargando el mapa…')),
    'UPDATING': t(markTr('Actualizando…')),
    'UPDATED': t(markTr('Actualizado hace {} s')),
    'PLANES_AT': t(markTr('aviones de {}')),
    'AGO_S': t(markTr('hace {} s')),
    'AGO_MIN': t(markTr('hace {} min')),
    'IN_VIEW': t(markTr('{} en la vista')),
    'FOUND': t(markTr('{} encontrados')),
    'SHOWING': t(markTr('Los primeros {} de {} en la vista')),
    'SOURCE_OK': t(markTr('{} · {} · {}')),
    'SOURCE_ERROR': t(markTr('No responde: {}')),
    'SOURCE_STALE': t(markTr('los últimos buenos ({})')),
    'SAMPLE': t(markTr('Datos de ejemplo')),
    'EMPTY_VIEW': t(
      markTr('Nada en esta vista del mapa. Aléjese o busque por nombre.'),
    ),
    'EMPTY_FOUND': t(
      markTr('No hay nada con ese nombre en las capas que se ven.'),
    ),
  };
  FlNode layer(String k, String icon, String label, String count) =>
      _n('Chip', {
        'icon': icon,
        'text': '$label · \${$count}',
        'selected': '=app.capas.$k',
        'onTap': "app.capa('$k')",
      });
  FlNode zone(String k, String label) => _n('Chip', {
    'text': label,
    'selected': "=app.region == '$k'",
    'onTap': "app.zona('$k')",
  });
  final app = FlApp(
    title: title,
    primary: '#4FC3F7',
    dark: true,
    nav: [
      'Mapa|public|${t(markTr('Mapa'))}',
      'Lista|list|${tc(markTrc('world', 'Lista'))}',
      'Fuentes|info|${t(markTr('Fuentes'))}',
    ].join('\n'),
    screens: [
      FlScreen(
        name: 'Mapa',
        title: title,
        bar: 'refresh|app.actualizar()',
        body: _n(
          'Column',
          {'gap': 10, 'padding': 12},
          [
            _n(
              'Row',
              {'wrap': true, 'gap': 8},
              [
                layer('plane', 'flight', t(markTr('Aviones')), 'app.nAviones'),
                layer(
                  'ship',
                  'directions_boat',
                  t(markTr('Barcos')),
                  'app.nBarcos',
                ),
                layer('train', 'train', t(markTr('Trenes')), 'app.nTrenes'),
              ],
            ),
            _n(
              'Row',
              {'wrap': true, 'gap': 6},
              [
                zone('world', t(markTr('Mundo'))),
                zone('europe', t(markTr('Europa'))),
                zone('namerica', t(markTr('Norteamérica'))),
                zone('samerica', t(markTr('Sudamérica'))),
                zone('asia', t(markTr('Asia'))),
                zone('baltic', t(markTr('Mar Báltico'))),
                zone('spain', t(markTr('España'))),
              ],
            ),
            _n('Canvas', {
              'paint': 'app.dibujar(ctx, w, h)',
              'onTap': 'app.tocar(x, y)',
              'aspect': 1.6,
            }),
            _n(
              'Row',
              {'gap': 4},
              [
                _n('Expanded', {}, [
                  _n('Text', {'text': r'${app.estado}', 'style': 'labelSmall'}),
                ]),
                _n('IconButton', {
                  'icon': 'zoom_out',
                  'tooltip': t(markTr('Alejar')),
                  'onTap': 'app.alejar()',
                }),
                _n('IconButton', {
                  'icon': 'zoom_in',
                  'tooltip': t(markTr('Acercar')),
                  'onTap': 'app.acercar()',
                }),
              ],
            ),
            _n(
              'Card',
              {'visible': '=app.sel != null', 'padding': 14},
              [
                _n(
                  'Column',
                  {'gap': 4},
                  [
                    _n(
                      'Row',
                      {'gap': 10},
                      [
                        _n('Icon', {
                          'icon': '=app.selIcono',
                          'color': '=app.selColor',
                        }),
                        _n('Expanded', {}, [
                          _n('Text', {
                            'text': r'${app.selTitulo}',
                            'style': 'titleMedium',
                          }),
                        ]),
                        _n('IconButton', {
                          'icon': '=app.seguir ? "gps_fixed" : "gps_not_fixed"',
                          'tooltip': t(markTr('Seguirlo en el mapa')),
                          'onTap': 'app.alternarSeguir()',
                        }),
                        _n('IconButton', {
                          'icon': 'close',
                          'tooltip': tc(markTrc('world', 'Cerrar')),
                          'onTap': 'app.cerrar()',
                        }),
                      ],
                    ),
                    for (var i = 0; i < 4; i++)
                      _n('Text', {
                        'text': '\${app.selLinea($i)}',
                        'style': i == 0 ? 'bodyMedium' : 'bodySmall',
                      }),
                  ],
                ),
              ],
            ),
            _n('Text', {
              'text': t(
                markTr(
                  'Toque un avión, un barco o un tren para ver sus datos; toque el mar o la tierra para centrar el mapa ahí.',
                ),
              ),
              'style': 'labelSmall',
            }),
          ],
        ),
      ),
      FlScreen(
        name: 'Lista',
        title: tc(markTrc('world', 'Lista')),
        body: _n(
          'Column',
          {'gap': 10, 'padding': 12},
          [
            _n('TextField', {
              'bind': 'app.busqueda',
              'hint': t(markTr('Buscar un vuelo, un barco o un tren')),
              'icon': 'search',
            }),
            _n('Text', {'text': r'${app.listaTitulo}', 'style': 'labelSmall'}),
            _n(
              'ListView',
              {
                'items': '=app.lista',
                'as': 'item',
                'separated': true,
                'empty': r'${app.vacio}',
              },
              [
                _n('ListTile', {
                  'icon': '=item.icon',
                  'leadingColor': '=item.color',
                  'title': r'${item.name}',
                  'subtitle': r'${item.sub}',
                  'trailing': r'${item.vel}',
                  'onTap': 'app.elegir(item); home:Mapa',
                }),
              ],
            ),
          ],
        ),
      ),
      FlScreen(
        name: 'Fuentes',
        title: t(markTr('Fuentes')),
        body: _n(
          'Column',
          {'gap': 12, 'padding': 12},
          [
            _n(
              'ListView',
              {'items': '=app.fuentes', 'as': 'f', 'separated': true},
              [
                _n('ListTile', {
                  'icon': '=f.icon',
                  'leadingColor': '=f.color',
                  'title': r'${f.name}',
                  'subtitle': r'${f.detail}',
                  'trailing': r'${f.n}',
                }),
              ],
            ),
            _n(
              'Card',
              {'padding': 16},
              [
                _n(
                  'Column',
                  {'gap': 8},
                  [
                    _n('Text', {
                      'text': t(markTr('Cómo funciona')),
                      'style': 'titleMedium',
                    }),
                    _n('Text', {
                      'text': t(
                        markTr(
                          'La web pide los datos a su propio servidor de Next.js cada 30 segundos. El servidor los descarga de las APIs públicas, los junta y los guarda un rato en memoria: el navegador no habla con ellas y no hacen falta claves.',
                        ),
                      ),
                      'style': 'bodyMedium',
                    }),
                    _n('Text', {
                      'text': t(
                        markTr(
                          'Aviones: OpenSky Network, el mundo entero (sin cuenta, cada 15 minutos; con OPENSKY_CLIENT_ID y OPENSKY_CLIENT_SECRET, cada 90 segundos) o adsb.lol. Entre una lectura y otra, cada avión avanza por su rumbo y su velocidad.',
                        ),
                      ),
                      'style': 'bodySmall',
                    }),
                    _n('Text', {
                      'text': t(
                        markTr(
                          'Barcos: el AIS del mar Báltico de Fintraffic (Digitraffic). Trenes: Renfe Cercanías (España) y VR (Finlandia). El mapa: Natural Earth.',
                        ),
                      ),
                      'style': 'bodySmall',
                    }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
  final design = TkDesign(target: tkTargetWebNext, props: {'title': title});
  app.saveTo(design);
  final code =
      '''// ${t(markTr('El mundo en directo: aviones, barcos y trenes de APIs públicas en un mapa. El servidor (después de // @server) descarga los datos; la app los dibuja.'))}
import { DmsApp, server } from "./dms";

// Los textos (los traduce el estudio con el resto del ejemplo).
const TX = ${const JsonEncoder.withIndent('  ').convert(texts)};
$_nextWorldCode''';
  return TkExample(
    'next_world',
    t(markTr('El mundo en directo (Next.js)')),
    t(
      markTr(
        'Una web de Next.js con servidor: un mapa del mundo con los aviones, los barcos y los trenes en directo de APIs públicas (OpenSky, Fintraffic, Renfe y VR). El servidor descarga y junta los datos; la web los dibuja en un Lienzo y se actualiza sola.',
      ),
    ),
    design,
    code,
  );
}
