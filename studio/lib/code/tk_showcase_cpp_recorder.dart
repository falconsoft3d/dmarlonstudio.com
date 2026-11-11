part of 'tk_examples.dart';

// ------------------------------------------------ grabador de pantalla (C++)
/// Un grabador de pantalla para hacer vídeos de YouTube, en C++17 con FLTK:
/// la pantalla entera o una zona de 16:9 (1080p, 720p) o vertical (Shorts),
/// con el cursor, los clics y el micrófono, cuenta atrás y límite de tiempo.
/// En macOS graba con screencapture; mientras graba, la ventana se esconde y
/// la barra de menús enseña el tiempo con «Detener y guardar».
TkExample tkCppRecorder(String Function(String) t) {
  final app = t(markTr('Grabador de pantalla'));
  final mFile = t(markTr('Archivo')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('RECORD', t(markTr('Grabar')), mFile);
  item('FOLDER', t(markTr('Abrir la carpeta de grabaciones')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca del Grabador de pantalla')), mHelp);
  final texts = <String, String>{
    'APP': app,
    'DEC': t(markTr(',')),
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'Elija qué grabar (la pantalla entera, una zona de 16:9 para YouTube o una vertical para Shorts), si quiere el sonido del micrófono, los clics y el cursor, la cuenta atrás y el límite de tiempo, y pulse Grabar.\n\nMientras graba, esta ventana se esconde para no salir en el vídeo: el tiempo va en la barra de menús, con «Detener y guardar». La primera vez, macOS le pedirá permiso para grabar la pantalla (y el micrófono).\n\nLas grabaciones quedan en la carpeta Películas › DMarlon Studio, listas para subir a YouTube.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, sus opciones y botones se diseñaron en el Diseñador del estudio; la grabación la hace screencapture (macOS) o ffmpeg (Windows y Linux), las miniaturas QuickLook y la barra de menús se hace desde C++ con el runtime de Objective-C.',
      ),
    ),
    'FILE_NAME': t(markTr('Grabación {0} a las {1}')),
    'AREA_FULL': t(markTr('Pantalla completa')),
    'AREA_1080': t(markTr('Zona 1920×1080 (16:9, YouTube)')),
    'AREA_720': t(markTr('Zona 1280×720 (16:9)')),
    'AREA_VERTICAL': t(markTr('Zona vertical 1080×1920 (Shorts)')),
    'CD_NONE': t(markTr('Sin cuenta atrás')),
    'CD_3': t(markTr('3 segundos')),
    'CD_5': t(markTr('5 segundos')),
    'CD_10': t(markTr('10 segundos')),
    'LIMIT_NONE': t(markTr('Sin límite')),
    'LIMIT_1': t(markTr('1 minuto (Shorts)')),
    'LIMIT_5': t(markTr('5 minutos')),
    'LIMIT_10': t(markTr('10 minutos')),
    'LIMIT_15': t(markTr('15 minutos')),
    'BAR_COUNTDOWN': t(markTr('🔴 Grabando en {0}…')),
    'BAR_STOP': t(markTr('Detener y guardar')),
    'BAR_CANCEL': t(markTr('Cancelar sin guardar')),
    'ERR_START': t(markTr('No se pudo empezar a grabar')),
    'ERR_NO_FFMPEG': t(
      markTr(
        'Para grabar en Windows y Linux hace falta ffmpeg: instálelo y vuelva a probar.',
      ),
    ),
    'SAVED': t(markTr('Guardada: {0}')),
    'CANCELLED': t(markTr('Grabación cancelada')),
    'DELETED': t(markTr('Movida a la Papelera')),
    'ASK_DELETE': t(markTr('¿Mover «{0}» a la Papelera?')),
    'BTN_NO': t(markTr('No')),
    'BTN_YES': t(markTr('Sí')),
    'FINDER': t(markTr('Mostrar')),
    'YOUTUBE': t(markTr('Subir a YouTube')),
    'DELETE': t(markTr('A la Papelera')),
    'YOUTUBE_HINT': t(
      markTr(
        'YouTube está abierto en el navegador: arrastre el vídeo desde el Finder a la página de subida.',
      ),
    ),
    'EMPTY_TITLE': t(markTr('Todavía no hay grabaciones')),
    'EMPTY_HELP': t(
      markTr(
        'Elija qué grabar arriba y pulse Grabar. Mientras graba, esta ventana se esconde y el tiempo va en la barra de menús.',
      ),
    ),
    'STATUS': t(markTr('{0} grabaciones en {1}')),
    'DESK_AREA': t(markTr('La zona que se graba (1920×1080)')),
    'DEMO_1': t(markTr('Curso de Python · lección 1.mov')),
    'DEMO_2': t(markTr('Cómo instalar DMarlon Studio.mov')),
    'DEMO_3': t(markTr('Truco del día (Short).mov')),
    'DEMO_4': t(markTr('Directo de los viernes.mov')),
    'DEMO_5': t(markTr('Presentación del proyecto.mov')),
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
  TkWidget check(String name, int x, int y, int w, String text) =>
      _w('Checkbutton', name, x, y, w, 28, {'text': text, 'bg': top})
        ..parent = 'Top';
  final design =
      TkDesign(
          width: 1000,
          height: 680,
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
          _w('Frame', 'Top', 0, 0, 1000, 104, {'bg': top}),
          lbl('LblArea', 16, 14, 90, 28, t(markTr('Qué grabar'))),
          _w('Combobox', 'AreaKind', 106, 14, 300, 28, {})..parent = 'Top',
          check('Mic', 424, 14, 190, t(markTr('Sonido del micrófono'))),
          check('Clicks', 616, 14, 160, t(markTr('Mostrar los clics'))),
          check('Cursor', 776, 14, 170, t(markTr('Mostrar el cursor'))),
          lbl('LblCountdown', 16, 58, 90, 28, t(markTr('Cuenta atrás'))),
          _w('Combobox', 'Countdown', 106, 58, 150, 28, {})..parent = 'Top',
          lbl('LblLimit', 272, 58, 60, 28, t(markTr('Límite'))),
          _w('Combobox', 'Limit', 330, 58, 160, 28, {})..parent = 'Top',
          _w(
            'Button',
            'BtnRecord',
            520,
            54,
            200,
            36,
            {
              'text': t(markTr('● Grabar')),
              'bg': '#dc2626',
              'fg': '#ffffff',
              'font_bold': true,
              'font_size': 15,
            },
            {'command': 'BtnRecord_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnFolder',
            734,
            58,
            220,
            28,
            {'text': t(markTr('Abrir la carpeta'))},
            {'command': 'BtnFolder_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 104, 1000, 552, {'bg': '#f4f6f9'}),
          _w('Label', 'BoardHint', 150, 280, 700, 40, {
            'text': t(
              markTr(
                'Las grabaciones con su miniatura las dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#f4f6f9',
            'font_size': 14,
          })..parent = 'Board',
          _w('StatusBar', 'Status', 0, 656, 1000, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Grabador de pantalla en C++ con FLTK: graba la pantalla o una zona para YouTube, con el micrófono y los clics, y guarda los vídeos con su miniatura.'))}
$_recorderIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_recorderCode''';
  return TkExample(
    'cpp_recorder',
    t(markTr('Grabador de pantalla (C++)')),
    t(
      markTr(
        'Un grabador de pantalla para vídeos de YouTube, nativo en C++ con FLTK: la pantalla entera o una zona de 16:9 o vertical, con el micrófono, los clics y el cursor, cuenta atrás, límite de tiempo y la lista de grabaciones con su miniatura.',
      ),
    ),
    design,
    code,
  );
}
