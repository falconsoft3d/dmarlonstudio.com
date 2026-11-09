part of 'tk_examples.dart';

// ------------------------------------------ buscador de vuelos (C++)
/// Un buscador de vuelos en C++17 con FLTK que vigila rutas: con el origen,
/// el destino y las fechas, analiza los precios de todas las aerolíneas
/// (la Data API de Travelpayouts, la de Aviasales) al abrirse y cada 30
/// minutos mientras está abierto, dice el mejor precio de cada aerolínea y
/// dónde comprarlo, el día más barato del mes y cómo cambia el precio, y
/// avisa cuando baja. Las consultas van con el programa curl del sistema.
TkExample tkCppFlights(String Function(String) t) {
  final app = t(markTr('Buscador de vuelos'));
  // Con contexto (msgctxt «flight»): «Origen» del vuelo, no de un archivo.
  String tc(String id) {
    final k = contextKey('flight', id);
    final r = t(k);
    return r == k ? id : r;
  }

  // ---- menús: el texto del diseño y la ruta de cada opción para el código
  final mFile = t(markTr('Archivo')), mSettings = t(markTr('Ajustes'));
  final mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  final labels = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
    labels['L_$id'] = label;
  }

  void sep() => lines.add('  -');
  lines.add(mFile);
  item('NOW', t(markTr('Analizar ahora')), mFile);
  item('ALL', t(markTr('Analizar todas las rutas')), mFile);
  sep();
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mSettings);
  item('TOKEN', t(markTr('Token de Travelpayouts…')), mSettings);
  item('MARKER', t(markTr('Marcador de afiliado…')), mSettings);
  sep();
  item('AUTO', t(markTr('Analizar cada 30 minutos')), mSettings);
  item('NOTIFY', t(markTr('Avisar cuando baje el precio')), mSettings);
  lines.add(mHelp);
  item('GET_TOKEN', t(markTr('Conseguir un token gratis')), mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Buscador de vuelos')), mHelp);

  // ---- los textos del código (namespace tx)
  final texts = <String, String>{
    'APP': app,
    ...paths,
    ...labels,
    'LOCALE': t(markTr('es-ES')),
    'DEC': t(markTr(',')),
    'MONTHS': t(
      markTr(
        'enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre',
      ),
    ),
    'MONTHS_SHORT': t(
      markTr('ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic'),
    ),
    'MONTH_YEAR': t(markTr('{0} de {1}')),
    'DURATION': t(markTr('{0} h {1} min')),
    'SUB_OUT': t(markTr('Ida: {0}')),
    'SUB_BACK': t(markTr('vuelta: {0}')),
    'ONE_WAY': t(markTr('solo ida')),
    'DIRECT_ONLY': t(markTr('solo directos')),
    'SAMPLE_BANNER': t(
      markTr(
        'Datos de ejemplo. Para ver precios reales, ponga su token gratuito de Travelpayouts en Ajustes → Token de Travelpayouts.',
      ),
    ),
    'ANALYZING': t(markTr('Analizando los precios…')),
    'NO_PRICES': t(
      markTr(
        'No hay precios para estas fechas: pruebe con el mes entero o sin «solo directos».',
      ),
    ),
    'CARD_BEST': t(markTr('Mejor precio')),
    'CARD_MEDIAN': t(markTr('Precio medio')),
    'OFFERS_AIRLINES': t(markTr('{0} ofertas · {1} aerolíneas')),
    'CARD_CHANGE': t(markTr('Desde el análisis anterior')),
    'SAME': t(markTr('Igual')),
    'FIRST_ANALYSIS': t(markTr('Primer análisis')),
    'SINCE': t(markTr('frente al de las {0}')),
    'CARD_TARGET': t(markTr('Objetivo: {0}')),
    'TARGET_HIT': t(markTr('¡Conseguido!')),
    'TARGET_HIT_SMALL': t(markTr('Ya está por debajo')),
    'TARGET_LEFT': t(markTr('faltan para el objetivo')),
    'CARD_RANGE': t(markTr('Lo más barato visto')),
    'RANGE_SMALL': t(markTr('lo más caro, {0} · {1} análisis')),
    'BY_AIRLINE': t(markTr('Mejor precio por aerolínea')),
    'BY_AIRLINE_HINT': t(
      markTr(
        '«Comprar» abre ese vuelo en Aviasales, que compara las agencias y la web de la aerolínea',
      ),
    ),
    'COL_AIRLINE': t(markTr('Aerolínea')),
    'COL_PRICE': t(markTr('Precio')),
    'COL_OUT': t(markTr('Ida')),
    'COL_BACK': t(markTr('Vuelta')),
    'COL_STOPS': t(markTr('Escalas')),
    'COL_DURATION': t(markTr('Duración')),
    'N_OFFERS': t(markTr('{0} ofertas')),
    'DIRECT': t(markTr('directo')),
    'ONE_STOP': t(markTr('1 escala')),
    'N_STOPS': t(markTr('{0} escalas')),
    'BUY': t(markTr('Comprar')),
    'BUY_TIP': t(
      markTr(
        'Abrir en Aviasales: las agencias y la aerolínea, con sus precios',
      ),
    ),
    'BY_DAY': t(markTr('El precio de cada día')),
    'BY_DAY_HINT': t(
      markTr('en verde, el día más barato; haga clic en un día para comprar'),
    ),
    'CHEAPEST_DAY': t(markTr('El día más barato: {0}')),
    'CLICK_TO_BUY': t(markTr('Clic: ver y comprar')),
    'HISTORY': t(markTr('Cómo cambia el mejor precio')),
    'HISTORY_HINT': t(
      markTr(
        'un punto por análisis (cada 30 minutos mientras la app está abierta)',
      ),
    ),
    'SOURCE_NOTE': t(
      markTr(
        'Precios de Travelpayouts (Aviasales): lo más barato que encontraron los buscadores en las últimas horas, por adulto en turista. Al comprar, compruebe el precio final.',
      ),
    ),
    'EMPTY_TITLE': t(markTr('Añada una ruta para vigilarla')),
    'EMPTY_TEXT': t(
      markTr(
        'Escriba el origen, el destino y las fechas a la izquierda y pulse «Añadir y analizar».',
      ),
    ),
    'ERR_BAD_ANSWER': t(markTr('La respuesta de Travelpayouts no se entiende')),
    'ERR_HTTP': t(markTr('Travelpayouts respondió con un error ({0})')),
    'ERR_LIMIT': t(markTr('Demasiadas consultas: se reintenta en 5 minutos')),
    'ERR_NETWORK': t(
      markTr('Sin conexión a internet: se reintenta en 5 minutos'),
    ),
    'ERR_NO_CURL': t(
      markTr(
        'No se encuentra el programa curl (viene con macOS y con Windows 10 o posterior)',
      ),
    ),
    'ERR_PLACE': t(
      markTr(
        'No se encuentra «{0}»: pruebe con el código IATA de la ciudad (por ejemplo, MAD)',
      ),
    ),
    'ERR_TOKEN': t(
      markTr('El token de Travelpayouts no es válido: revíselo en Ajustes'),
    ),
    'ERR_NO_PLACES': t(markTr('Escriba el origen y el destino')),
    'ERR_SAME': t(markTr('El origen y el destino son el mismo')),
    'ERR_DEPART': t(
      markTr('La ida debe ser un mes (2026-12) o un día (2026-12-20)'),
    ),
    'ERR_PAST': t(markTr('La fecha de ida ya pasó')),
    'ERR_RETURN': t(
      markTr('La vuelta debe ser un mes o un día (o quedar vacía)'),
    ),
    'ERR_RETURN_BEFORE': t(markTr('La vuelta es antes que la ida')),
    'ERR_TARGET': t(markTr('El precio para avisar debe ser un número')),
    'ALERT_DOWN': t(markTr('¡Ha bajado!')),
    'ALERT_TARGET': t(markTr('¡Por debajo de {0}!')),
    'ANALYZING_ROUTE': t(markTr('Analizando {0}…')),
    'AUTO_OFF': t(
      markTr('El análisis cada 30 minutos está desactivado (menú Ajustes)'),
    ),
    'NEXT_IN': t(
      markTr(
        'Próximo análisis en {0} · cada 30 minutos mientras la app está abierta',
      ),
    ),
    'STATUS': t(markTr('{0} rutas vigiladas · {1}')),
    'MODE_SAMPLE': t(markTr('datos de ejemplo (sin token)')),
    'MODE_REAL': t(markTr('precios de Travelpayouts (Aviasales)')),
    'ASK_REMOVE': t(markTr('¿Quitar la ruta {0}?')),
    'REMOVE': t(markTr('Quitar')),
    'CANCEL': t(markTr('Cancelar')),
    'TOKEN_ASK': t(
      markTr(
        'Su token de la API de Travelpayouts (gratis: travelpayouts.com → Perfil → API token). Se guarda solo en este ordenador.',
      ),
    ),
    'MARKER_ASK': t(
      markTr(
        'Su marcador de afiliado de Travelpayouts (opcional, solo cifras): los enlaces para comprar lo llevarán.',
      ),
    ),
    'HOW_TEXT': t(
      markTr(
        'Cada ruta vigilada se analiza al abrir la app y después cada 30 minutos mientras está abierta. Los precios vienen de Travelpayouts (la API de Aviasales): lo más barato que encontraron los buscadores, de todas las aerolíneas y agencias, en las últimas horas.\n\nDe cada ruta verá el mejor precio, el precio medio, lo que ha cambiado desde el análisis anterior, lo más barato de cada aerolínea con su botón «Comprar» (abre el vuelo en Aviasales, que compara las agencias y la web de la aerolínea), el precio de cada día del mes y cómo ha ido cambiando.\n\nSi escribe un precio en «Avisar bajo», la app le avisa cuando el mejor precio baja de esa cantidad; también cuando baja respecto al análisis anterior.\n\nPara precios reales hace falta un token gratuito de Travelpayouts: regístrese en travelpayouts.com, únase al programa de Aviasales y copie su token (Perfil → API token) en Ajustes. Sin token, la app enseña datos de ejemplo.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: un buscador de vuelos hecho en C++17 con FLTK {0}. La ventana, la barra lateral y el menú se diseñaron en el Diseñador del estudio; el análisis, las gráficas y las consultas a Travelpayouts (con curl) están en el código de Form1.cpp.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');

  // ---- la ventana: la barra lateral con las rutas, el análisis y el reloj
  const side = '#f4f6fb';
  TkWidget lbl(
    String name,
    int x,
    int y,
    int w,
    int h,
    String text, [
    Map<String, Object?> extra = const {},
  ]) => _w('Label', name, x, y, w, h, {
    'text': text,
    'bg': side,
    'fg': '#1f2937',
    'anchor': 'w',
    ...extra,
  })..parent = 'Side';
  TkWidget field(String kind, String name, int y, Map<String, Object?> props) =>
      _w(kind, name, 104, y, 180, 26, props)..parent = 'Side';

  final design =
      TkDesign(
          width: 1180,
          height: 760,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': '#ffffff',
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1120,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Cada segundo: la cuenta atrás y las rutas que toca analizar.
          _w(
            'Timer',
            'Tick',
            1080,
            8,
            32,
            32,
            {'interval': 1000},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Side', 0, 0, 300, 736, {'bg': side}),
          lbl('LblRoutes', 16, 14, 268, 24, t(markTr('Rutas vigiladas')), {
            'font_size': 15,
            'font_bold': true,
          }),
          _w(
            'Listbox',
            'RouteList',
            16,
            42,
            268,
            232,
            {'font_size': 13},
            {'select': 'RouteList_select'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnRemove',
            16,
            282,
            268,
            30,
            {'text': t(markTr('Quitar la ruta'))},
            {'command': 'BtnRemove_click'},
          )..parent = 'Side',
          lbl('LblNew', 16, 330, 268, 24, t(markTr('Nueva ruta')), {
            'font_size': 15,
            'font_bold': true,
          }),
          lbl('LblOrigin', 16, 362, 84, 26, tc(markTrc('flight', 'Origen'))),
          field('Entry', 'Origin', 362, {'text': t(markTr('Madrid'))}),
          lbl('LblDest', 16, 396, 84, 26, tc(markTrc('flight', 'Destino'))),
          field('Entry', 'Destination', 396, {'text': t(markTr('Cancún'))}),
          lbl('LblDepart', 16, 430, 84, 26, t(markTr('Ida'))),
          field('Entry', 'DepartDate', 430, {}),
          lbl('LblReturn', 16, 464, 84, 26, t(markTr('Vuelta'))),
          field('Entry', 'ReturnDate', 464, {}),
          lbl('LblCurrency', 16, 498, 84, 26, t(markTr('Moneda'))),
          field('Combobox', 'Currency', 498, {
            'items': 'EUR\nUSD\nGBP\nMXN\nCOP\nARS',
            'text': 'EUR',
          }),
          lbl('LblTarget', 16, 532, 84, 26, t(markTr('Avisar bajo'))),
          field('Entry', 'Target', 532, {}),
          _w('Checkbutton', 'Direct', 16, 566, 268, 26, {
            'text': t(markTr('Solo vuelos directos')),
            'bg': side,
          })..parent = 'Side',
          lbl(
            'LblHint',
            16,
            596,
            268,
            64,
            t(
              markTr(
                'Ida: un mes (2026-12) o un día (2026-12-20). Vuelta vacía: solo ida. Ciudades o códigos IATA (MAD, HAV).',
              ),
            ),
            {'font_size': 11, 'fg': '#6b7280'},
          ),
          _w(
            'Button',
            'BtnAdd',
            16,
            668,
            268,
            36,
            {
              'text': t(markTr('Añadir y analizar')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnAdd_click'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnNow',
            316,
            12,
            170,
            32,
            {'text': t(markTr('Analizar ahora'))},
            {'command': 'BtnNow_click'},
          ),
          _w('Label', 'LblNext', 500, 12, 660, 32, {
            'text': '',
            'fg': '#6b7280',
            'bg': '#ffffff',
            'anchor': 'w',
          }),
          _w('Frame', 'Results', 316, 56, 848, 676, {'bg': '#ffffff'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'ResultsHint', 124, 320, 600, 40, {
            'text': t(
              markTr(
                'El análisis, las tablas y las gráficas los dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#ffffff',
            'font_size': 14,
          })..parent = 'Results',
          _w('StatusBar', 'Status', 0, 736, 1180, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Buscador de vuelos en C++ con FLTK: vigila rutas, analiza los precios de todas las aerolíneas cada 30 minutos y dice dónde comprar.'))}
$_flightsIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_flightsCode''';
  return TkExample(
    'cpp_flights',
    t(markTr('Buscador de vuelos (C++)')),
    t(
      markTr(
        'Un buscador de vuelos nativo en C++ con FLTK que vigila sus rutas: analiza los precios de todas las aerolíneas al abrirse y cada 30 minutos, dice el mejor precio de cada una y dónde comprarlo, el día más barato del mes y cómo cambia el precio, y avisa cuando baja.',
      ),
    ),
    design,
    code,
  );
}

const _flightsIncludes = r'''#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <deque>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <thread>
#include <utility>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <sys/stat.h>
#include <sys/wait.h>
#endif
''';
