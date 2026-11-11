part of 'tk_examples.dart';

// ------------------------------------------------ relojes del mundo (C++)
/// La hora de varios países en la barra de menús, en C++17 con FLTK: por
/// defecto España, Argentina, Venezuela, República Dominicana y Cuba. Las
/// reglas del horario de verano van en el código (funciona igual en macOS,
/// Windows y Linux) y la ventana enseña cada reloj con su esfera.
TkExample tkCppClocks(String Function(String) t) {
  final app = t(markTr('Relojes del mundo'));
  final mFile = t(markTr('Archivo')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('BAR', t(markTr('Minimizar a la barra de menús')), mFile);
  item('HERE', t(markTr('Mostrar mi hora en la barra')), mFile);
  item('RESET', t(markTr('Volver a los relojes de siempre')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Relojes del mundo')), mHelp);
  // Los países, en el orden de ZONES del código.
  final zones = [
    t(markTr('España · Madrid')),
    t(markTr('España · Canarias')),
    t(markTr('Argentina · Buenos Aires')),
    t(markTr('Venezuela · Caracas')),
    t(markTr('República Dominicana · Santo Domingo')),
    t(markTr('Cuba · La Habana')),
    t(markTr('México · Ciudad de México')),
    t(markTr('Colombia · Bogotá')),
    t(markTr('Perú · Lima')),
    t(markTr('Ecuador · Guayaquil')),
    t(markTr('Chile · Santiago')),
    t(markTr('Uruguay · Montevideo')),
    t(markTr('Paraguay · Asunción')),
    t(markTr('Bolivia · La Paz')),
    t(markTr('Brasil · São Paulo')),
    t(markTr('Panamá · Panamá')),
    t(markTr('Costa Rica · San José')),
    t(markTr('Guatemala · Guatemala')),
    t(markTr('El Salvador · San Salvador')),
    t(markTr('Honduras · Tegucigalpa')),
    t(markTr('Nicaragua · Managua')),
    t(markTr('Puerto Rico · San Juan')),
    t(markTr('Estados Unidos · Nueva York')),
    t(markTr('Estados Unidos · Miami')),
    t(markTr('Estados Unidos · Chicago')),
    t(markTr('Estados Unidos · Los Ángeles')),
    t(markTr('Canadá · Toronto')),
    t(markTr('Reino Unido · Londres')),
    t(markTr('Portugal · Lisboa')),
    t(markTr('Francia · París')),
    t(markTr('Italia · Roma')),
    t(markTr('Alemania · Berlín')),
    t(markTr('Emiratos Árabes · Dubái')),
    t(markTr('India · Bombay')),
    t(markTr('China · Pekín')),
    t(markTr('Japón · Tokio')),
    t(markTr('Australia · Sídney')),
    t(markTr('Nueva Zelanda · Auckland')),
    t(markTr('UTC · Hora universal')),
  ];
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'ZONE_NAMES': zones.join('|'),
    'HOW_TEXT': t(
      markTr(
        'Cada tarjeta es la hora de un país, con su esfera (oscura de noche), la fecha y la diferencia con su hora. Añada países con la lista de arriba, ordénelos con las flechas y quite los que no quiera.\n\nLa barra de menús enseña su hora (📍) y, al lado, la de los países que marque con «En la barra» o con un clic en el menú del icono, que enseña todas. Los cambios de horario de verano (Europa, Estados Unidos, Cuba, Chile, Australia y Nueva Zelanda) se calculan solos.\n\nCerrar la ventana la esconde: los relojes siguen en la barra hasta que elija Salir.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú, la lista de países, los botones y el reloj se diseñaron en el Diseñador del estudio; las esferas se dibujan en código, las reglas del horario de verano van en el código y la barra de menús se hace desde C++ con el runtime de Objective-C.',
      ),
    ),
    'WEEKDAYS': t(markTr('dom,lun,mar,mié,jue,vie,sáb')),
    'MONTHS': t(markTr('ene,feb,mar,abr,may,jun,jul,ago,sep,oct,nov,dic')),
    'DATE': t(markTr('{0} {1} {2}')),
    'AM': t(markTr('a. m.')),
    'PM': t(markTr('p. m.')),
    'SAME_TIME': t(markTr('misma hora')),
    'TOMORROW': t(markTr('mañana')),
    'YESTERDAY': t(markTr('ayer')),
    'DAY': t(markTr('☀ De día')),
    'NIGHT': t(markTr('☾ De noche')),
    'HERE': t(markTr('Aquí: {0} · {1}')),
    'FORMAT_24': t(markTr('Formato de 24 horas')),
    'SHOW_HERE': t(markTr('Mostrar mi hora en la barra')),
    'FMT_24': t(markTr('24 horas')),
    'FMT_12': t(markTr('12 horas (a. m./p. m.)')),
    'TO_BAR': t(markTr('Minimizar a la barra de menús')),
    'MINIMIZE': t(markTr('Minimizar')),
    'OPEN_WINDOW': t(markTr('Abrir los relojes…')),
    'QUIT': t(markTr('Salir')),
    'IN_BAR_ON': t(markTr('✓ En la barra')),
    'IN_BAR_OFF': t(markTr('En la barra')),
    'REMOVE': t(markTr('Quitar')),
    'EMPTY': t(markTr('Añada un país con la lista de arriba.')),
    'STATUS': t(markTr('Aquí son las {0} · {1} relojes')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const top = '#f6f7fb';
  TkWidget lbl(String name, int x, int y, int w, int h, String text) =>
      _w('Label', name, x, y, w, h, {
        'text': text,
        'bg': top,
        'fg': '#374151',
        'font_size': 13,
      })..parent = 'Top';
  final design =
      TkDesign(
          width: 1000,
          height: 660,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': '#f4f6f9',
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            940,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Cada segundo: las agujas, la barra y el menú.
          _w(
            'Timer',
            'Tick',
            900,
            8,
            32,
            32,
            {'interval': 1000},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Top', 0, 0, 1000, 60, {'bg': top}),
          lbl('LblZone', 16, 15, 60, 30, t(markTr('País'))),
          _w(
            'Combobox',
            'Zone',
            72,
            15,
            300,
            30,
            {'items': zones.join('\n')},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnAdd',
            384,
            15,
            110,
            30,
            {
              'text': t(markTr('Añadir')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnAdd_click'},
          )..parent = 'Top',
          lbl('LblFormat', 520, 15, 70, 30, t(markTr('Formato'))),
          _w(
            'Combobox',
            'Format',
            588,
            15,
            170,
            30,
            {'items': '24 h\n12 h'},
            {'select': 'Format_select'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnBar',
            772,
            15,
            212,
            30,
            {'text': t(markTr('Minimizar a la barra de menús'))},
            {'command': 'BtnBar_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 60, 1000, 576, {'bg': '#f4f6f9'}),
          _w('Label', 'BoardHint', 150, 300, 700, 40, {
            'text': t(
              markTr(
                'Las esferas y las horas de cada país las dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#f4f6f9',
            'font_size': 14,
          })..parent = 'Board',
          _w('StatusBar', 'Status', 0, 636, 1000, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Relojes del mundo en C++ con FLTK: la hora de varios países en la barra de menús, con el horario de verano de cada uno.'))}
$_clocksIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_clocksCode''';
  return TkExample(
    'cpp_clocks',
    t(markTr('Relojes del mundo (C++)')),
    t(
      markTr(
        'La hora de varios países en la barra de menús, nativa en C++ con FLTK: por defecto España, Argentina, Venezuela, República Dominicana y Cuba, con su esfera, la fecha, la diferencia horaria y el horario de verano de cada país.',
      ),
    ),
    design,
    code,
  );
}
