part of 'tk_examples.dart';

// ------------------------------------------------ Bloques Neón (C++)
/// Un juego de bloques que caen, en C++17 con FLTK: las siete piezas de
/// cuatro bloques, la siguiente, la reserva, la pieza fantasma, combos,
/// niveles que aceleran y una ciudad de neón de fondo, todo dibujado en
/// código, con chispas al limpiar filas y sonidos del sistema en macOS.
TkExample tkCppBlocks(String Function(String) t) {
  final app = t(markTr('Bloques Neón'));
  final mGame = t(markTr('Juego')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mGame);
  item('NEW', t(markTr('Nueva partida')), mGame);
  item('PAUSE', t(markTr('Pausa')), mGame);
  lines.add('  -');
  item('SOUND', t(markTr('Sonido sí / no')), mGame);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mGame);
  lines.add(mHelp);
  item('CONTROLS', t(markTr('Controles')), mHelp);
  item('ABOUT', t(markTr('Acerca de Bloques Neón')), mHelp);
  final texts = <String, String>{
    'APP': app,
    'THOUSANDS': t(markTr('.')),
    ...paths,
    'CONTROLS': t(
      markTr(
        '← →  mover   ·   ↓  bajar más deprisa\n↑ o X  girar   ·   Z  girar al otro lado\nEspacio  dejarla caer   ·   C  guardarla\nEsc o P  pausa   ·   R  empezar otra vez',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Bloques Neón es una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú y el reloj (60 veces por segundo) se diseñaron en el Diseñador del estudio; el juego, la ciudad de neón, los bloques de cristal, las chispas y los textos se dibujan en el código de Form1.cpp. Llene filas enteras para que desaparezcan: cuantas más a la vez y más seguidas, más puntos. Cada 10 filas sube el nivel.',
      ),
    ),
    'TITLE_1': t(markTr('BLOQUES')),
    'TITLE_2': t(markTr('NEÓN')),
    'PRESS_START': t(markTr('Pulse Enter para jugar')),
    'HOLD': t(markTr('RESERVA')),
    'NEXT': t(markTr('SIGUIENTES')),
    'LEVEL': t(markTr('NIVEL')),
    'SCORE': t(markTr('PUNTOS')),
    'GOAL': t(markTr('META')),
    'GOAL_N': t(markTr('{0}/10')),
    'BEST': t(markTr('RÉCORD')),
    'LINES': t(markTr('FILAS')),
    'L1': t(markTr('¡UNA FILA!')),
    'L2': t(markTr('¡DOBLE!')),
    'L3': t(markTr('¡TRIPLE!')),
    'L4': t(markTr('¡CUATRO FILAS!')),
    'COMBO': t(markTr('COMBO x{0}')),
    'B2B': t(markTr('SEGUIDAS')),
    'LEVEL_UP': t(markTr('¡NIVEL {0}!')),
    'PAUSED': t(markTr('PAUSA')),
    'PAUSED_HINT': t(markTr('Esc o P para seguir')),
    'GAME_OVER': t(markTr('FIN DE LA PARTIDA')),
    'OVER_SCORE': t(markTr('{0} puntos')),
    'NEW_BEST': t(markTr('¡Nuevo récord!')),
    'SIGN_1': t(markTr('NEÓN')),
    'SIGN_2': t(markTr('NOCHE')),
    'SIGN_3': t(markTr('CAFÉ')),
    'SIGN_4': t(markTr('CIUDAD')),
    'SIGN_5': t(markTr('24H')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const bg = '#070a18';
  final design =
      TkDesign(
          width: 1100,
          height: 760,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': bg,
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1040,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // 60 fotogramas por segundo: la caída, los efectos y el dibujo.
          _w(
            'Timer',
            'Tick',
            1000,
            8,
            32,
            32,
            {'interval': 16},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Board', 0, 0, 1100, 760, {'bg': bg}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'BoardHint', 150, 360, 800, 40, {
            'text': t(
              markTr(
                'El juego, la ciudad y los efectos los dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#a5b4fc',
            'bg': bg,
            'font_size': 14,
          })..parent = 'Board',
        ]);

  final code =
      '''// ${t(markTr('Bloques Neón en C++ con FLTK: piezas que caen, filas que se limpian, combos y una ciudad de neón, todo dibujado en código.'))}
$_blocksIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_blocksCode''';
  return TkExample(
    'cpp_blocks',
    t(markTr('Bloques Neón (C++)')),
    t(
      markTr(
        'Un juego de bloques que caen nativo en C++ con FLTK: siete piezas, siguiente y reserva, pieza fantasma, combos, niveles que aceleran y efectos de neón en una ciudad de noche.',
      ),
    ),
    design,
    code,
  );
}
