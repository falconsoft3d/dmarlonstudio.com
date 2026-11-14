part of 'tk_examples.dart';

// ------------------------------------------------ Mesa de radio (C++)
/// Una mesa de radio en C++17 con FLTK: seis canales con su emisora de
/// internet, su fader, ▶ y silencio (se pueden mezclar varias a la vez),
/// pads de colores que buscan emisoras por género en Radio Browser, una
/// pantalla con lo que suena (metadatos ICY), REC que graba la emisora y
/// mandos de volumen, fundido y apagado automático. En macOS suena con
/// AVPlayer (AVFoundation desde C++); en Windows y Linux, con ffplay.
TkExample tkCppRadio(String Function(String) t) {
  final app = t(markTr('Mesa de radio'));
  final mFile = t(markTr('Archivo')),
      mChannels = t(markTr('Canales')),
      mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('REC', t(markTr('Grabar o parar la grabación')), mFile);
  item('REC_DIR', t(markTr('Abrir la carpeta de grabaciones')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mChannels);
  item('PLAY', t(markTr('Sonar o pausar el canal')), mChannels);
  item('MUTE', t(markTr('Silenciar el canal')), mChannels);
  item('CLEAR', t(markTr('Vaciar el canal')), mChannels);
  lines.add('  -');
  item('STOP_ALL', t(markTr('Parar todo')), mChannels);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Mesa de radio')), mHelp);
  final countries = [
    t(markTr('Todos los países')),
    t(markTr('España')),
    t(markTr('México')),
    t(markTr('Argentina')),
    t(markTr('Colombia')),
    t(markTr('Cuba')),
    t(markTr('Estados Unidos')),
    t(markTr('Reino Unido')),
    t(markTr('Francia')),
    t(markTr('Alemania')),
    t(markTr('Italia')),
  ];
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'Mesa de radio pone emisoras de internet en seis canales, como una mesa de mezclas: cada canal tiene su emisora, su fader (el volumen), ▶ para que suene y M para silenciarlo. Pueden sonar varias a la vez, cada una a su volumen.\n\nPara llenar un canal: elíjalo con su pad de color, pulse un pad de género (Jazz, Rock, Noticias…; con ‹ › hay otro banco) o busque por nombre arriba, y en la pantalla pulse dos veces una emisora (o gire la rueda verde y púlsela). Las emisoras vienen de Radio Browser, una base de datos abierta de radios de todo el mundo; el país se elige arriba.\n\nLa pantalla enseña lo que suena en cada canal (si la emisora lo manda) y el tiempo en el aire. Los mandos: el volumen general, el fundido al cambiar de emisora y el apagado automático (de 5 a 120 minutos). REC graba la emisora del canal elegido, tal como llega, en la carpeta Música.\n\nEn macOS suena con el sistema; en Windows y Linux hace falta ffplay (de FFmpeg).',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú, la búsqueda y el reloj se diseñaron en el Diseñador del estudio; la mesa (la pantalla, los mandos, los faders y los pads) se dibuja en el código de Form1.cpp. Las emisoras son de Radio Browser (radio-browser.info), se buscan con curl y suenan con AVPlayer en macOS (desde C++ con el runtime de Objective-C) o con ffplay.',
      ),
    ),
    'REC_FOLDER': t(markTr('Mesa de radio')),
    'BRAND': t(markTr('MESA DE RADIO')),
    'BRAND_SUB': 'DMarlon Studio',
    'BRAND_LINE': t(markTr('6 canales · emisoras de todo el mundo')),
    'REC': 'REC',
    'REC_HINT': t(markTr('grabar')),
    'TAB_CHANNELS': t(markTr('CANALES')),
    'TAB_RESULTS': t(markTr('EMISORAS')),
    'EMPTY_CH': t(markTr('Canal vacío')),
    'EMPTY_HINT': t(
      markTr('Canal vacío: pulse un pad de género y elija una emisora'),
    ),
    'ST_FAILED': t(markTr('No se puede oír: pruebe otra emisora')),
    'ST_LOADING': t(markTr('Conectando…')),
    'ST_CHANNEL': t(markTr('Canal {0}')),
    'SEARCHING': t(markTr('Buscando emisoras…')),
    'NO_RESULTS': t(markTr('Sin emisoras: pulse un pad o busque arriba')),
    'RESULTS_TITLE': t(
      markTr('{0} · {1} emisoras · doble clic para el canal {2}'),
    ),
    'K_VOLUME': t(markTr('VOLUMEN')),
    'K_FADE': t(markTr('FUNDIDO')),
    'K_SLEEP': t(markTr('APAGADO')),
    'DIAL': t(markTr('SINTONIZAR')),
    'OFF': t(markTr('no')),
    'SECONDS': t(markTr('{0} s')),
    'MINUTES': t(markTr('{0} min')),
    'SLEEP_LEFT': t(markTr('se apaga en {0}')),
    'BANK': t(markTr('banco {0}')),
    'G_NEWS': t(markTr('Noticias')),
    'G_POP': 'Pop',
    'G_ROCK': 'Rock',
    'G_JAZZ': 'Jazz',
    'G_CLASSICAL': t(markTr('Clásica')),
    'G_ELECTRONIC': t(markTr('Electrónica')),
    'G_LATIN': t(markTr('Latina')),
    'G_LOFI': 'Lo-fi',
    'G_CHILL': 'Chill',
    'G_REGGAE': 'Reggae',
    'G_HIPHOP': 'Hip hop',
    'G_BLUES': 'Blues',
    'G_COUNTRY': 'Country',
    'G_FLAMENCO': 'Flamenco',
    'G_SALSA': 'Salsa',
    'G_SOUNDTRACK': t(markTr('Bandas sonoras')),
    'C_ALL': countries[0],
    'C_ES': countries[1],
    'C_MX': countries[2],
    'C_AR': countries[3],
    'C_CO': countries[4],
    'C_CU': countries[5],
    'C_US': countries[6],
    'C_GB': countries[7],
    'C_FR': countries[8],
    'C_DE': countries[9],
    'C_IT': countries[10],
    'ERR_NO_NET': t(markTr('No se puede llegar a Radio Browser: ¿hay internet?')),
    'ERR_HTTP': t(markTr('Radio Browser ha contestado con un error ({0})')),
    'HELLO': t(
      markTr('Elija un canal, pulse un pad de género y elija una emisora'),
    ),
    'NO_PLAYER': t(
      markTr(
        'Para oír las emisoras en este sistema hace falta ffplay (de FFmpeg)',
      ),
    ),
    'LOADED': t(markTr('{0}, en el canal {1}')),
    'TYPE_SOMETHING': t(markTr('Escriba el nombre de una emisora')),
    'RECORDING_TO': t(markTr('grabando en {0}')),
    'REC_SAVED': t(markTr('Grabación guardada en {0}')),
    'REC_STOPPED': t(markTr('La grabación se ha parado: {0}')),
    'REC_FAILED': t(markTr('No se ha podido empezar a grabar (¿falta curl?)')),
    'SLEPT': t(markTr('Apagado automático: buenas noches')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const top = '#15171b';
  final design =
      TkDesign(
          width: 1240,
          height: 800,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': top,
            'position': 'center',
            'resizable': false,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1180,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Diez veces por segundo: los fundidos, los medidores y la hora.
          _w(
            'Timer',
            'Tick',
            1140,
            8,
            32,
            32,
            {'interval': 100},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Top', 0, 0, 1240, 48, {'bg': top}),
          _w('Label', 'LblSearch', 20, 10, 70, 28, {
            'text': t(markTr('Buscar')),
            'bg': top,
            'fg': '#9aa4b2',
            'font_size': 13,
          })..parent = 'Top',
          _w(
            'Entry',
            'Search',
            90,
            10,
            360,
            28,
            {'font_size': 14},
            {'enter_key': 'Search_enter'},
          )..parent = 'Top',
          _w(
            'Combobox',
            'Country',
            462,
            10,
            190,
            28,
            {'items': countries.join('\n'), 'text': countries[0]},
            {'select': 'Country_select'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnSearch',
            664,
            10,
            120,
            28,
            {
              'text': t(markTr('Buscar emisoras')),
              'bg': '#2f6fea',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnSearch_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 48, 1240, 728, {'bg': top}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'BoardHint', 220, 380, 800, 40, {
            'text': t(
              markTr(
                'La mesa (pantalla, mandos, faders y pads) la dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#9aa4b2',
            'bg': top,
            'font_size': 14,
          })..parent = 'Board',
          _w('StatusBar', 'Status', 0, 776, 1240, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Mesa de radio en C++ con FLTK: emisoras de internet en seis canales con faders, pads de géneros, lo que suena y grabación.'))}
$_radioIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_radioCode''';
  return TkExample(
    'cpp_radio',
    t(markTr('Mesa de radio (C++)')),
    t(
      markTr(
        'Una mesa de radio nativa en C++ con FLTK: seis canales con emisoras de internet de todo el mundo, faders para mezclarlas, pads de colores por género, lo que suena en cada una, grabación y apagado automático.',
      ),
    ),
    design,
    code,
  );
}
