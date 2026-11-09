part of 'tk_examples.dart';

// ------------------------------------------ carrera de motos (C++)
/// Un juego de carreras de motos en C++17 con FLTK, en pseudo-3D (la
/// carretera por segmentos proyectados, como en los arcades): curvas y
/// cuestas, la moto que se inclina, siete rivales con su pilotaje, semáforo
/// de salida, vueltas, clasificación con diferencias, minimapa, cuadro de
/// mandos con marcha, velocidad y neumáticos, caídas y récord de vuelta. Todo
/// se dibuja en código: no hay archivos de imagen.
TkExample tkCppRacing(String Function(String) t) {
  final app = t(markTr('Carrera de motos'));
  // Con contexto (msgctxt «racing»): «Tiempo» es el del cronómetro, no el
  // meteorológico, y «Clasificación», la de la carrera.
  String tc(String id) {
    final k = contextKey('racing', id);
    final r = t(k);
    return r == k ? id : r;
  }

  // ---- menús: el texto del diseño y la ruta de cada opción para el código
  final mGame = t(markTr('Juego')), mView = t(markTr('Ver'));
  final mHelp = t(markTr('Ayuda'));
  final mLaps = t(markTr('Vueltas')), mLevel = t(markTr('Dificultad'));
  final lines = <String>[];
  final paths = <String, String>{};
  final labels = <String, String>{};
  void menu(String label) => lines.add(label);
  void item(String id, String label, String prefix, [int depth = 1]) {
    lines.add('${'  ' * depth}$label');
    paths['MP_$id'] = '$prefix/$label';
    labels['L_$id'] = label;
  }

  void sep([int depth = 1]) => lines.add('${'  ' * depth}-');
  menu(mGame);
  item('NEW', t(markTr('Nueva carrera')), mGame);
  item('PAUSE', t(markTr('Pausa')), mGame);
  sep();
  lines.add('  $mLaps');
  item('LAPS1', t(markTr('1 vuelta')), '$mGame/$mLaps', 2);
  item('LAPS3', t(markTr('3 vueltas')), '$mGame/$mLaps', 2);
  item('LAPS5', t(markTr('5 vueltas')), '$mGame/$mLaps', 2);
  lines.add('  $mLevel');
  item('EASY', t(markTr('Fácil')), '$mGame/$mLevel', 2);
  item('NORMAL', t(markTr('Normal')), '$mGame/$mLevel', 2);
  item('HARD', t(markTr('Difícil')), '$mGame/$mLevel', 2);
  sep();
  item('QUIT', t(markTr('Salir')), mGame);
  menu(mView);
  item('FULLSCREEN', t(markTr('Pantalla completa')), mView);
  sep();
  item('TOWER', tc(markTrc('racing', 'Clasificación')), mView);
  item('MAP', t(markTr('Minimapa')), mView);
  item('TAGS', t(markTr('Nombres de los pilotos')), mView);
  menu(mHelp);
  item('KEYS', t(markTr('Controles')), mHelp);
  item('ABOUT', t(markTr('Acerca de Carrera de motos')), mHelp);

  // ---- los textos del código (namespace tx)
  final texts = <String, String>{
    'APP': app,
    ...paths,
    ...labels,
    'CIRCUIT': t(markTr('Circuito de la Sierra')),
    'YOU': t(markTr('Usted')),
    'LAP': t(markTr('VUELTA')),
    'GAP': t(markTr('DIF.')),
    'BEST': t(markTr('Mejor vuelta')),
    'LAST': t(markTr('Última vuelta')),
    'RECORD': t(markTr('Récord')),
    'NEW_RECORD': t(markTr('¡Nuevo récord de vuelta!')),
    'FRONT': t(markTr('DEL.')),
    'REAR': t(markTr('TRAS.')),
    'GO': t(markTr('¡YA!')),
    'GET_READY': t(
      markTr('Prepárese: acelere cuando se apaguen los semáforos'),
    ),
    'CRASH': t(markTr('¡Caída!')),
    'OFF_TRACK': t(markTr('Fuera de pista')),
    'FINAL_LAP': t(markTr('ÚLTIMA VUELTA')),
    'FINISH': t(markTr('Bandera a cuadros')),
    'RESULTS': t(markTr('Clasificación final')),
    'COL_POS': t(markTr('Pos.')),
    'COL_RIDER': t(markTr('Piloto')),
    'COL_TIME': tc(markTrc('racing', 'Tiempo')),
    'COL_BEST': t(markTr('Mejor vuelta')),
    'RUNNING': t(markTr('en carrera')),
    'WON': t(markTr('¡Ha ganado la carrera!')),
    'FINAL_POS': t(markTr('Posición final: {0} de {1}')),
    'AGAIN': t(markTr('Pulse Intro para correr otra vez')),
    'PAUSED': t(markTr('PAUSA')),
    'RESUME': t(markTr('Pulse P o Esc para seguir')),
    'LEVEL_EASY': t(markTr('Fácil')),
    'LEVEL_NORMAL': t(markTr('Normal')),
    'LEVEL_HARD': t(markTr('Difícil')),
    'KEYS_TEXT': t(
      markTr(
        '↑ o W: acelerar\n↓ o S: frenar\n← → o A D: girar\nP o Esc: pausa\nIntro: nueva carrera al terminar\nF2: nueva carrera\nF11: pantalla completa\n\nFrene antes de las curvas cerradas: si entra demasiado rápido, la moto se abre hacia la hierba. Fuera de la pista se pierde velocidad, y contra un árbol o una grada se cae.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: un juego de carreras de motos hecho en C++17 con FLTK {0}. La ventana y el menú se diseñaron en el Diseñador del estudio; la pista, las motos y el resto se dibujan en el código de Form1.cpp, sin imágenes.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');

  // ---- la ventana: el menú, el reloj del juego y el marco de la pista
  final design =
      TkDesign(
          width: 1120,
          height: 630,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': '#10151c',
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1060,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // 60 veces por segundo: mueve la carrera y vuelve a dibujar.
          _w(
            'Timer',
            'Tick',
            1020,
            8,
            32,
            32,
            {'interval': 16},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Track', 0, 0, 1120, 630, {'bg': '#10151c'}),
          // Solo para el Diseñador: el juego la oculta al arrancar.
          _w('Label', 'TrackHint', 160, 290, 800, 40, {
            'text': t(
              markTr('La pista y las motos las dibuja el código de Form1.cpp'),
            ),
            'fg': '#8b95a3',
            'bg': '#10151c',
            'font_size': 15,
          })..parent = 'Track',
        ]);

  final code =
      '''// ${t(markTr('Carrera de motos en C++ con FLTK: pista en pseudo-3D con curvas y cuestas, siete rivales, vueltas, clasificación, minimapa y cuadro de mandos.'))}
$_racingIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_racingCode''';
  return TkExample(
    'cpp_racing',
    t(markTr('Carrera de motos (C++)')),
    t(
      markTr(
        'Un juego de carreras de motos nativo en C++ con FLTK: pista en pseudo-3D con curvas y cuestas, la moto que se inclina, siete rivales, semáforo de salida, vueltas, clasificación con diferencias, minimapa y cuadro de mandos.',
      ),
    ),
    design,
    code,
  );
}

const _racingIncludes = r'''#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#include <functional>
''';
