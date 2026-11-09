part of 'tk_examples.dart';

// ------------------------------------------------------ la consola (C++)
/// Una consola en C++17 con FLTK inspirada en iTerm: pestañas, cada una con
/// su shell en un pseudoterminal; una cola de órdenes que se mandan de una en
/// una cuando la anterior termina (la shell avisa al volver al prompt) y diez
/// apariencias.
TkExample tkCppConsole(String Function(String) t) {
  final app = t(markTr('Consola'));
  String tc(String id) {
    final k = contextKey('console', id);
    final r = t(k);
    return r == k ? id : r;
  }

  // ---- menús: el texto del diseño y la ruta de cada opción para el código
  final mShell = 'Shell', mEdit = t(markTr('Edición'));
  final mView = t(markTr('Ver')), mQueue = tc(markTrc('console', 'Órdenes'));
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
  final skins = <String, String>{
    'SK_CLASSIC': tc(markTrc('console', 'Clásica')),
    'SK_SOLAR_DARK': t(markTr('Solarized oscura')),
    'SK_SOLAR_LIGHT': t(markTr('Solarized clara')),
    'SK_PHOSPHOR': t(markTr('Fósforo verde')),
    'SK_AMBER': t(markTr('Ámbar')),
    'SK_PAPER': t(markTr('Papel')),
  };
  // En el orden de SKINS (el código): las seis de arriba y cuatro con nombre propio.
  final skinMenu = [
    skins['SK_CLASSIC']!,
    skins['SK_SOLAR_DARK']!,
    skins['SK_SOLAR_LIGHT']!,
    'Dracula',
    'Nord',
    'Gruvbox',
    'Monokai',
    skins['SK_PHOSPHOR']!,
    skins['SK_AMBER']!,
    skins['SK_PAPER']!,
  ];
  lines.add(mShell);
  item('NEW', t(markTr('Nueva pestaña')), mShell);
  item('CLOSE', t(markTr('Cerrar la pestaña')), mShell);
  item('NEXT', t(markTr('Pestaña siguiente')), mShell);
  item('PREV', t(markTr('Pestaña anterior')), mShell);
  sep();
  item('CLEAR', t(markTr('Limpiar la pantalla')), mShell);
  sep();
  item('QUIT', t(markTr('Salir')), mShell);
  lines.add(mEdit);
  item('COPY', t(markTr('Copiar')), mEdit);
  item('PASTE', t(markTr('Pegar')), mEdit);
  lines.add(mView);
  item('BIGGER', t(markTr('Letra más grande')), mView);
  item('SMALLER', t(markTr('Letra más pequeña')), mView);
  item('QUEUE_PANEL', t(markTr('Mostrar la cola')), mView);
  sep();
  for (final s in skinMenu) {
    lines.add('  $s');
  }
  lines.add(mQueue);
  item('ADD', t(markTr('Añadir una orden a la cola')), mQueue);
  item('RUN', t(markTr('Ejecutar la cola')), mQueue);
  item('STOP', t(markTr('Detener la cola')), mQueue);
  item('EMPTY', t(markTr('Vaciar la cola')), mQueue);
  sep();
  item('SAVE', t(markTr('Guardar una orden…')), mQueue);
  item('COMPLETE', t(markTr('Órdenes guardadas (Ctrl+Espacio)')), mQueue);
  item('HISTORY', t(markTr('Historial (history)')), mQueue);
  item('SHORTCUTS', t(markTr('Atajos…')), mQueue);
  sep();
  item('STOP_FAIL', t(markTr('Parar si una falla')), mQueue);
  lines.add(mHelp);
  item('HELPCMD', t(markTr('Órdenes y teclas (ayuda)')), mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Consola')), mHelp);
  final texts = <String, String>{
    'APP': app,
    'M_VIEW': mView,
    ...paths,
    ...labels,
    ...skins,
    'DEC': t(markTr(',')),
    'POSIX_LOCALE': t(markTr('es_ES.UTF-8')),
    'ENDED': t(
      markTr('[La shell ha terminado: cierre la pestaña o abra otra]'),
    ),
    'ERR_SHELL': t(markTr('No se pudo abrir la shell ({0}).')),
    'Q_EMPTY': t(
      markTr(
        'La cola está vacía.\nEscriba una orden abajo y pulse Añadir:\nse ejecutarán de una en una, cada una\ncuando termine la anterior.',
      ),
    ),
    'Q_WAITING': t(markTr('en espera')),
    'Q_RUNNING': t(markTr('en marcha · {0}')),
    'Q_OK': t(markTr('terminó bien · {0}')),
    'Q_FAILED': t(markTr('falló (código {0}) · {1}')),
    'Q_SKIPPED': t(markTr('saltada')),
    'Q_DONE': t(markTr('La cola ha terminado.')),
    'Q_NOTHING': t(markTr('No hay órdenes en espera en la cola.')),
    'Q_STOPPED_FAIL': t(
      markTr('La cola se ha parado: «{0}» falló con el código {1}.'),
    ),
    'Q_NO_MARKS': t(
      markTr(
        'Esta shell no avisa cuando termina cada orden: la cola funciona con zsh, bash, fish o PowerShell.',
      ),
    ),
    'STATUS': t(markTr('{0} · {1} · {2}×{3}')),
    'SAVE_ASK': t(markTr('La orden que quiere guardar:')),
    'SAVED_OK': t(markTr('Guardada: {0}')),
    'FORGOT': t(markTr('Quitada de las guardadas: {0}')),
    'C_TITLE': t(markTr('Órdenes guardadas')),
    'C_FILTER': t(markTr('con «{0}»')),
    'C_SAVE': t(markTr('Guardar «{0}»')),
    'C_EMPTY': t(markTr('Ninguna encaja: siga escribiendo o guárdela.')),
    'HELP_WORD': t(markTr('help')),
    'KEY_SHIFT': t(markTr('Mayús')),
    'KEY_CTRL_SPACE': t(markTr('Ctrl+Espacio')),
    'HELP_TITLE': t(markTr('Consola · ayuda')),
    'HELP_BUILTIN': t(markTr('Órdenes de la consola')),
    'HELP_KEYS': t(markTr('Teclas')),
    'HELP_QUEUE_T': t(markTr('La cola')),
    'HELP_QUEUE': t(
      markTr(
        'Ver → Mostrar la cola: escriba órdenes, pulse Añadir y después Ejecutar la cola. Van de una en una, cada una cuando termina la anterior.',
      ),
    ),
    'HELP_SHORTCUTS': t(markTr('Sus atajos')),
    'HELP_NONE': t(markTr('Ninguno todavía: Órdenes → Atajos…')),
    'HD_HELP': t(markTr('esta ayuda')),
    'HD_HISTORY': t(markTr('las 10 últimas órdenes, para elegir una')),
    'HD_COMPLETE': t(markTr('órdenes guardadas y atajos')),
    'HD_TABS': t(markTr('abrir y cerrar pestañas')),
    'HD_NEXT': t(markTr('pestaña anterior y siguiente')),
    'HD_CLEAR': t(markTr('limpiar la pantalla')),
    'HD_SAVE': t(markTr('guardar una orden')),
    'HD_SHORTCUTS': t(markTr('los atajos')),
    'HD_HISTKEY': t(markTr('el historial')),
    'HD_RUN': t(markTr('ejecutar la cola')),
    'HD_FONT': t(markTr('letra más grande y más pequeña')),
    'H_TITLE': t(markTr('Últimas órdenes')),
    'H_EMPTY': t(markTr('Aún no hay órdenes en el historial.')),
    'S_TITLE': t(markTr('Atajos')),
    'S_HINT': t(
      markTr(
        'Un atajo es un nombre que ejecuta órdenes: escriba el nombre en la terminal y pulse Intro. Puede llevar varias, una por línea, que se ejecutan una detrás de otra; puede llamar a otro atajo (publicar → actualizar, npm test, desplegar), y lo que escriba después del nombre llega como \$1, \$2…',
      ),
    ),
    'S_NAME': t(markTr('Nombre')),
    'S_CMD': tc(markTrc('console', 'Orden')),
    'S_SAVE': t(markTr('Guardar el atajo')),
    'S_REMOVE': t(markTr('Quitar')),
    'S_CLOSE': t(markTr('Cerrar')),
    'S_LIST_EMPTY': t(
      markTr('Aún no hay atajos: escriba un nombre y su orden.'),
    ),
    'S_BAD_NAME': t(
      markTr(
        'El nombre solo puede llevar letras, números, guiones, puntos y guiones bajos, sin espacios (por ejemplo, conectar-servidor).',
      ),
    ),
    'S_NO_CMD': t(markTr('Escriba la orden que ejecuta el atajo.')),
    'S_SAVED': t(markTr('Atajo guardado: {0}')),
    'S_REMOVED': t(markTr('Atajo quitado: {0}')),
    'C_HINT': t(
      markTr('↑ ↓ elegir · Intro escribirla · Supr quitarla · Esc cerrar'),
    ),
    'STATUS_QUEUE': t(markTr('cola: {0} en espera de {1}')),
    'HOW_TEXT': t(
      markTr(
        'Cada pestaña es su shell (zsh, bash o fish en macOS y Linux; PowerShell en Windows) en su propio pseudoterminal, con su configuración, sus alias y su prompt. Pestañas: ⌘T (Ctrl+Mayús+T) abre una, ⌘W la cierra y ⌘[ ⌘] pasan de una a otra; también con el ratón.\n\nMientras escribe, la orden sale en verde si existe y en rojo si no (en zsh; fish lo hace solo).\n\nLa cola (Ver → Mostrar la cola, ⌘B): escriba órdenes y pulse Añadir; con Ejecutar la cola se mandan de una en una a la pestaña, cada una cuando la anterior ha terminado (la shell avisa al volver al prompt), con su código de salida y lo que ha tardado. Con «Parar si una falla», una que falle detiene las demás; Detener la cola manda Ctrl+C a la que está en marcha.\n\nÓrdenes guardadas: pulse Ctrl+Espacio (o ⌘;) en la terminal y sale la lista, filtrada por lo que lleve escrito en la línea; Intro la escribe en la línea sin ejecutarla, Supr la quita y, si lo escrito no está guardado, la última fila lo guarda. También con Órdenes → Guardar una orden… (⌘S). Las que usa suben arriba.\n\nAtajos (Órdenes → Atajos…, ⌘J): un nombre, como conectar-servidor, que ejecuta sus órdenes al escribirlo (varias, una por línea); uno puede llamar a otro y lo que escriba después llega como \$1, \$2… Salen también en la lista de Ctrl+Espacio.\n\nHistorial: escriba history y pulse Intro (o ⌘Y): salen las 10 últimas órdenes para elegir una.\n\nAyuda: escriba ayuda y pulse Intro: la consola escribe en la terminal sus órdenes, sus teclas y sus atajos.\n\nVer cambia la apariencia (diez, de Clásica a Papel) y el tamaño de la letra (⌘+ y ⌘−). Los programas a pantalla completa (vim, top) se ven de forma básica.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: una consola hecha en C++17 con FLTK {0} (Fl_Terminal) y un pseudoterminal. La ventana, el panel de la cola y el menú se diseñaron en el Diseñador del estudio; las pestañas, la cola y las apariencias están en el código de Form1.cpp.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const panel = '#0d0d0d', fg = '#c7c7c7', dim = '#7a7a7a';
  TkWidget side(
    String kind,
    String name,
    int x,
    int y,
    int w,
    int h, [
    Map<String, Object?> props = const {},
    Map<String, String> events = const {},
  ]) =>
      // Las coordenadas de lo que va dentro de un marco son relativas a él.
      _w(kind, name, x - 880, y, w, h, props, events)..parent = 'Side';
  final design =
      TkDesign(
          width: 1180,
          height: 740,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': '#000000',
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
          // Cada medio segundo: el tiempo de la orden en marcha y la barra.
          _w(
            'Timer',
            'Tick',
            1080,
            8,
            32,
            32,
            {'interval': 500},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Tabs', 0, 0, 880, 34, {'bg': '#141414'}),
          _w('Frame', 'Term', 0, 34, 880, 682, {'bg': '#000000'}),
          // Solo para el Diseñador: la app lo oculta al arrancar.
          _w('Label', 'TermHint', 140, 330, 600, 40, {
            'text': t(
              markTr(
                'Las pestañas y la terminal (Fl_Terminal con un pseudoterminal) las crea el código de Form1.cpp',
              ),
            ),
            'fg': dim,
            'bg': '#000000',
            'font_size': 14,
          })..parent = 'Term',
          _w('Frame', 'Side', 880, 0, 300, 716, {'bg': panel}),
          side('Label', 'LblQueue', 896, 10, 268, 24, {
            'text': t(markTr('Cola de órdenes')),
            'fg': fg,
            'bg': panel,
            'anchor': 'w',
            'font_size': 15,
            'font_bold': true,
          }),
          side('Label', 'LblQueueHint', 896, 34, 268, 40, {
            'text': t(
              markTr('Se ejecutan de una en una en la pestaña elegida.'),
            ),
            'fg': dim,
            'bg': panel,
            'anchor': 'w',
            'font_size': 11,
          }),
          side('Frame', 'QueueBox', 896, 80, 268, 446, {'bg': panel}),
          side('Entry', 'CmdEntry', 896, 536, 268, 28, {}, {
            'enter_key': 'CmdEntry_return',
          }),
          side(
            'Button',
            'BtnAdd',
            896,
            570,
            130,
            28,
            {'text': t(markTr('Añadir'))},
            {'command': 'BtnAdd_click'},
          ),
          side(
            'Button',
            'BtnClear',
            1034,
            570,
            130,
            28,
            {'text': t(markTr('Vaciar'))},
            {'command': 'BtnClear_click'},
          ),
          side(
            'Button',
            'BtnRun',
            896,
            606,
            268,
            32,
            {
              'text': t(markTr('Ejecutar la cola')),
              'bg': '#2f5fe0',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnRun_click'},
          ),
          side(
            'Button',
            'BtnStop',
            896,
            644,
            268,
            28,
            {'text': t(markTr('Detener'))},
            {'command': 'BtnStop_click'},
          ),
          side(
            'Checkbutton',
            'ChkStop',
            896,
            680,
            268,
            26,
            {'text': t(markTr('Parar si una falla')), 'fg': dim, 'bg': panel},
            {'command': 'ChkStop_click'},
          ),
          _w('StatusBar', 'Status', 0, 716, 1180, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Consola en C++ con FLTK, inspirada en iTerm: pestañas con su shell, una cola de órdenes que esperan a la anterior y diez apariencias.'))}
$_consoleIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_consoleCode''';
  return TkExample(
    'cpp_console',
    t(markTr('Consola (C++)')),
    t(
      markTr(
        'Una consola nativa en C++ con FLTK, inspirada en iTerm: pestañas con su propia shell, una cola de órdenes que se ejecutan de una en una cuando termina la anterior y diez apariencias.',
      ),
    ),
    design,
    code,
  );
}

const _consoleIncludes = r'''#include <algorithm>
#include <cerrno>
#include <chrono>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <string>
#include <thread>
#include <utility>
#include <vector>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Hold_Browser.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Terminal.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <fcntl.h>
#include <pwd.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>
#endif
''';
