part of 'tk_examples.dart';

// --------------------------------------- buscador de vuelos (Next.js)
/// El buscador de vuelos de C++ como web de Next.js con servidor: las rutas
/// se guardan en el navegador y se analizan al abrir y cada 30 minutos; el
/// servidor (después de `// @server`) consulta Travelpayouts con el token,
/// que nunca llega al navegador, o inventa datos de ejemplo sin él.
TkExample _nextFlights(String Function(String) t) {
  String tc(String ctx, String id) {
    final k = contextKey(ctx, id);
    final r = t(k);
    return r == k ? id : r;
  }

  final title = t(markTr('Buscador de vuelos'));
  final texts = <String, String>{
    'APP': title,
    'LOCALE': t(markTr('es-ES')),
    'MONTHS': t(
      markTr(
        'enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre',
      ),
    ),
    'MONTH_YEAR': t(markTr('{0} de {1}')),
    'DURATION': t(markTr('{0} h {1} min')),
    'DIRECT': t(markTr('directo')),
    'ONE_STOP': t(markTr('1 escala')),
    'STOPS': t(markTr('{0} escalas')),
    'ONE_WAY': t(markTr('solo ida')),
    'DIRECT_ONLY': t(markTr('solo directos')),
    'RETURN_ON': t(markTr('vuelta: {0}')),
    'OFFERS': t(markTr('{0} ofertas')),
    'MODE_SAMPLE': t(markTr('datos de ejemplo (sin token)')),
    'MODE_REAL': t(markTr('precios de Travelpayouts (Aviasales)')),
    'SAMPLE': t(markTr('ejemplo')),
    'ANALYZING': t(markTr('Analizando…')),
    'ANALYZED_AT': t(markTr('Analizada a las {} · la siguiente, a las {}')),
    'EVERY_30': t(markTr('Se analizan al abrir y cada 30 minutos')),
    'NEXT_IN': t(markTr('Próximo análisis en {} min')),
    'NO_PRICES': t(markTr('Sin precios para esas fechas')),
    'NO_DAYS': t(markTr('Sin precios por día')),
    'HISTORY_SOON': t(
      markTr('La evolución sale a partir del segundo análisis'),
    ),
    'BEST': t(markTr('Desde {} con {} · {} · {}')),
    'MEDIAN': t(markTr('precio medio {}')),
    'SAME': t(markTr('igual que antes')),
    'DOWN': t(markTr('▼ {} menos')),
    'UP': t(markTr('▲ {} más')),
    'LOWEST_SEEN': t(markTr('Lo más barato visto: {} ({}, {})')),
    'ALERT_BELOW': t(markTr('aviso por debajo de {}')),
    'ALERT_TARGET': t(markTr('{}: {}, por debajo de su precio')),
    'ALERT_DOWN': t(markTr('{}: ha bajado a {} ({} menos)')),
    'ERROR': t(markTr('No se pudo analizar: {}')),
    'ERR_PLACES': t(markTr('Escriba el origen y el destino')),
    'ERR_DEPART': t(
      markTr('La ida debe ser un mes (2026-12) o un día (2026-12-20)'),
    ),
    'ERR_RETURN': t(
      markTr(
        'La vuelta debe ser un mes o un día, y no antes de la ida (o déjela vacía)',
      ),
    ),
    'ERR_TARGET': t(markTr('El precio para avisar debe ser un número')),
    'ERR_PLACE': t(
      markTr(
        'No se encuentra «{0}»: pruebe con el código IATA de la ciudad (por ejemplo, MAD)',
      ),
    ),
    'ERR_TOKEN': t(
      markTr('El token de Travelpayouts del servidor no es válido'),
    ),
    'ERR_LIMIT': t(
      markTr('Demasiadas consultas: se reintenta en el próximo análisis'),
    ),
  };
  FlNode field(String bind, String label, String hint, {String kb = 'text'}) =>
      _n('TextField', {
        'bind': bind,
        'label': label,
        'hint': hint,
        'keyboard': kb,
      });
  FlNode money(String c) => _n('Chip', {
    'text': c,
    'selected': "=app.f.moneda == '$c'",
    'onTap': "app.moneda('$c')",
  });
  final app = FlApp(
    title: title,
    primary: '#2B5FD9',
    screens: [
      FlScreen(
        name: 'Rutas',
        title: title,
        bar: 'add|go:Nueva\nrefresh|app.analizarTodas()',
        body: _n(
          'Column',
          {'gap': 10, 'padding': 16},
          [
            _n(
              'Card',
              {
                'visible': '=app.aviso',
                'color': 'primaryContainer',
                'padding': 12,
              },
              [
                _n(
                  'Row',
                  {'gap': 10},
                  [
                    _n('Icon', {'icon': 'notifications'}),
                    _n('Expanded', {}, [
                      _n('Text', {'text': r'${app.aviso}', 'bold': true}),
                    ]),
                    _n('IconButton', {
                      'icon': 'close',
                      'tooltip': tc('flight', markTrc('flight', 'Cerrar')),
                      'onTap': 'app.cerrarAviso()',
                    }),
                  ],
                ),
              ],
            ),
            _n('Text', {
              'text': r'${app.modo} · ${app.proximo}',
              'style': 'labelSmall',
            }),
            _n(
              'ListView',
              {
                'items': '=app.rutas',
                'as': 'r',
                'separated': true,
                'empty': t(
                  markTr(
                    'Añada una ruta con el botón + para vigilar sus precios.',
                  ),
                ),
              },
              [
                _n('ListTile', {
                  'icon': 'flight',
                  'leadingColor': 'primary',
                  'title': r'${r.corto}',
                  'subtitle': r'${r.sub}',
                  'trailing': r'${r.precioTexto}',
                  'onTap': 'go:Ruta(r)',
                }),
              ],
            ),
            _n('Text', {
              'text': t(
                markTr(
                  'Las rutas se guardan en este navegador. El servidor consulta los precios de todas las aerolíneas y agencias de Aviasales con su token, que nunca llega aquí.',
                ),
              ),
              'style': 'labelSmall',
            }),
          ],
        ),
      ),
      FlScreen(
        name: 'Nueva',
        title: t(markTr('Nueva ruta')),
        body: _n(
          'Column',
          {'gap': 12, 'padding': 16},
          [
            field(
              'app.f.origen',
              tc('flight', markTrc('flight', 'Origen')),
              t(markTr('Madrid o MAD')),
            ),
            field(
              'app.f.destino',
              tc('flight', markTrc('flight', 'Destino')),
              t(markTr('La Habana o HAV')),
            ),
            _n(
              'Row',
              {'gap': 12},
              [
                _n('Expanded', {}, [
                  field(
                    'app.f.ida',
                    t(markTr('Ida')),
                    t(markTr('2026-12 o 2026-12-20')),
                  ),
                ]),
                _n('Expanded', {}, [
                  field(
                    'app.f.vuelta',
                    t(markTr('Vuelta')),
                    t(markTr('Vacía: solo ida')),
                  ),
                ]),
              ],
            ),
            field(
              'app.f.aviso',
              t(markTr('Avisar si baja de')),
              t(markTr('Opcional, en la moneda elegida')),
              kb: 'number',
            ),
            _n(
              'Row',
              {'wrap': true, 'gap': 8},
              [
                for (final c in ['EUR', 'USD', 'GBP', 'MXN']) money(c),
                _n('Chip', {
                  'icon': 'flight_takeoff',
                  'text': t(markTr('Solo directos')),
                  'selected': '=app.f.directo',
                  'onTap': 'app.alternarDirecto()',
                }),
              ],
            ),
            _n('Text', {
              'text': r'${app.error}',
              'color': '#C2453B',
              'visible': '=app.error',
            }),
            _n('Button', {
              'text': t(markTr('Añadir y analizar')),
              'icon': 'search',
              'onTap': 'if (await app.anadir()) back',
            }),
          ],
        ),
      ),
      FlScreen(
        name: 'Ruta',
        title: r'${arg.corto}',
        arg: 'r',
        bar: 'refresh|app.analizar(arg)',
        body: _n(
          'Column',
          {'gap': 12, 'padding': 16},
          [
            _n(
              'Card',
              {'padding': 14},
              [
                _n(
                  'Column',
                  {'gap': 4},
                  [
                    _n('Text', {
                      'text': r'${arg.titulo}',
                      'style': 'titleMedium',
                    }),
                    _n('Text', {
                      'text': r'${arg.periodo}',
                      'style': 'bodySmall',
                    }),
                    _n('Text', {
                      'text': r'${arg.resumen}',
                      'style': 'titleLarge',
                      'color': 'primary',
                    }),
                    _n('Text', {
                      'text': r'${arg.detalle}',
                      'style': 'bodyMedium',
                    }),
                    _n('Text', {
                      'text': r'${arg.minimo}',
                      'style': 'bodySmall',
                    }),
                    _n('Text', {
                      'text': r'${arg.cuando}',
                      'style': 'labelSmall',
                    }),
                  ],
                ),
              ],
            ),
            _n('Text', {
              'text': t(
                markTr('El precio de cada día (toque un día para comprarlo)'),
              ),
              'style': 'titleSmall',
            }),
            _n('Canvas', {
              'paint': 'app.dibujarDias(ctx, w, h, arg)',
              'onTap': 'app.tocarDia(x, y, arg)',
              'aspect': 3.2,
            }),
            _n('Text', {
              'text': t(markTr('Lo más barato de cada aerolínea')),
              'style': 'titleSmall',
            }),
            _n(
              'Card',
              {'padding': 4},
              [
                _n(
                  'ListView',
                  {
                    'items': '=arg.mejores',
                    'as': 'b',
                    'separated': true,
                    'empty': t(markTr('Sin precios para esas fechas')),
                  },
                  [
                    _n('ListTile', {
                      'icon': 'flight_takeoff',
                      'title': r'${b.nombre}',
                      'subtitle': r'${b.detalle}',
                      'trailing': r'${b.precio}',
                      'onTap': 'app.comprar(b.url)',
                    }),
                  ],
                ),
              ],
            ),
            _n('Text', {
              'text': t(markTr('Cómo cambia el mejor precio')),
              'style': 'titleSmall',
            }),
            _n('Canvas', {
              'paint': 'app.dibujarHistoria(ctx, w, h, arg)',
              'aspect': 4,
            }),
            _n('Button', {
              'text': t(markTr('Quitar la ruta')),
              'icon': 'delete',
              'variant': 'outlined',
              'onTap': 'app.quitar(arg); back',
            }),
          ],
        ),
      ),
    ],
  );
  final design = TkDesign(target: tkTargetWebNext, props: {'title': title});
  app.saveTo(design);
  final code =
      '''// ${t(markTr('Buscador de vuelos: vigila rutas cada 30 minutos con los precios de Travelpayouts. El servidor (después de // @server) guarda el token y hace las consultas.'))}
import { DmsApp, server } from "./dms";

// Los textos (los traduce el estudio con el resto del ejemplo).
const TX = ${const JsonEncoder.withIndent('  ').convert(texts)};
$_nextFlightsCode''';
  return TkExample(
    'next_flights',
    t(markTr('Buscador de vuelos (Next.js)')),
    t(
      markTr(
        'El buscador de vuelos como web de Next.js con servidor: vigila rutas cada 30 minutos con los precios de todas las aerolíneas (Travelpayouts), lo más barato de cada una y de cada día, la evolución y avisos. El token se queda en el servidor; sin él, datos de ejemplo.',
      ),
    ),
    design,
    code,
  );
}
