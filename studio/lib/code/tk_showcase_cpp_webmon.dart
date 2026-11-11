part of 'tk_examples.dart';

// ------------------------------------------------ monitor de sitios web (C++)
/// Un monitor de sitios web en C++17 con FLTK: se añaden direcciones, se
/// comprueban cada pocos minutos (2 por defecto, configurable) con curl y se
/// ven su estado, su tiempo de respuesta, la disponibilidad y el historial.
/// En macOS vive también en la barra de menús (un NSStatusItem hecho desde
/// C++ con el runtime de Objective-C), con un menú para seguir cada sitio.
TkExample tkCppWebmon(String Function(String) t) {
  final app = t(markTr('Monitor de sitios web'));
  final mFile = t(markTr('Archivo')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('ADD', t(markTr('Añadir un sitio')), mFile);
  item('CHECK', t(markTr('Comprobar todos ahora')), mFile);
  lines.add('  -');
  item('BAR', t(markTr('Minimizar a la barra de menús')), mFile);
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca del Monitor de sitios web')), mHelp);
  final texts = <String, String>{
    'APP': app,
    'DEC': t(markTr(',')),
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'Escriba la dirección de un sitio (y, si quiere, un nombre) y pulse Añadir. El monitor lo comprueba enseguida y después cada pocos minutos (2 por defecto; cámbielo en «Comprobar cada»).\n\nEn línea: contesta con un código 2xx o 3xx. Lento: tarda más de 2 segundos. Caído: contesta con un error o no contesta. Cuando un sitio se cae o vuelve, macOS le avisa.\n\n«Puertos» prueba los puertos habituales de su servidor y enseña los abiertos; en ámbar, los que no conviene abrir a internet. Escanee solo servidores suyos o con permiso.\n\nCerrar la ventana o «Minimizar a la barra» la esconde: el monitor sigue en la barra de menús, con un menú para abrir cada sitio, comprobarlo, pausarlo o volver a la ventana.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú, los campos y el reloj se diseñaron en el Diseñador del estudio; la lista de sitios se dibuja en código, las comprobaciones las hace curl en otros hilos y el icono de la barra de menús se hace desde C++ con el runtime de Objective-C.',
      ),
    ),
    'SPAN_S': t(markTr('{0} s')),
    'SPAN_MIN': t(markTr('{0} min')),
    'SPAN_H': t(markTr('{0} h')),
    'SPAN_D': t(markTr('{0} d')),
    'ERR_NO_CURL': t(markTr('No encuentro curl')),
    'ERR_NO_ANSWER': t(markTr('No contesta')),
    'PAUSED': t(markTr('En pausa')),
    'CHECKING': t(markTr('Comprobando…')),
    'NOT_YET': t(markTr('Sin comprobar')),
    'MS': t(markTr('{0} ms')),
    'NO_SITES': t(markTr('Sin sitios: añada uno en la ventana')),
    'HEAD': t(markTr('{0} sitios · {1} en línea')),
    'HEAD_DOWN': t(markTr('{0} sitios · {1} en línea · {2} con problemas')),
    'NEXT_CHECK': t(markTr('Próxima comprobación en {0}')),
    'OPEN': t(markTr('Abrir {0}')),
    'OPEN_SHORT': t(markTr('Abrir')),
    'CHECK_NOW': t(markTr('Comprobar ahora')),
    'PAUSE': t(markTr('Pausar')),
    'RESUME': t(markTr('Reanudar')),
    'REMOVE': t(markTr('Quitar')),
    'UPTIME': t(markTr('Disponibilidad: {0} %')),
    'UP_SINCE': t(markTr('En línea desde hace {0}')),
    'DOWN_SINCE': t(markTr('Caído desde hace {0}')),
    'UP_SINCE_SHORT': t(markTr('en línea hace {0}')),
    'DOWN_SINCE_SHORT': t(markTr('caído hace {0}')),
    'LAST_CHECK': t(markTr('Última comprobación: {0}')),
    'SHOW_IN_WINDOW': t(markTr('Ver en la ventana')),
    'CHECK_ALL': t(markTr('Comprobar todos ahora')),
    'EVERY_MENU': t(markTr('Comprobar cada')),
    'EVERY_ITEM': t(markTr('{0} min')),
    'EVERY_SET': t(markTr('Se comprobarán cada {0} min')),
    'TO_BAR': t(markTr('Minimizar a la barra de menús')),
    'MINIMIZE': t(markTr('Minimizar')),
    'OPEN_WINDOW': t(markTr('Abrir el monitor…')),
    'QUIT': t(markTr('Salir')),
    'EMPTY_TITLE': t(markTr('Todavía no vigila ningún sitio')),
    'EMPTY_HELP': t(
      markTr(
        'Escriba arriba la dirección de un sitio (por ejemplo, ejemplo.com) y pulse Añadir.',
      ),
    ),
    'COL_SITE': t(markTr('SITIO')),
    'COL_ANSWER': t(markTr('RESPUESTA')),
    'COL_UPTIME': t(markTr('DISPONIBILIDAD')),
    'COL_HISTORY': t(markTr('HISTORIAL')),
    'NOTIFY_UP': t(markTr('Ha vuelto')),
    'NOTIFY_DOWN': t(markTr('Se ha caído')),
    'BTN_NO': t(markTr('No')),
    'BTN_YES': t(markTr('Sí')),
    'ASK_REMOVE': t(markTr('¿Dejar de vigilar «{0}»?')),
    'BAD_URL': t(markTr('Esa dirección no vale: escriba algo como ejemplo.com')),
    'ALREADY': t(markTr('Ese sitio ya está en la lista')),
    'ADDED': t(markTr('Añadido: {0}')),
    'CHECKING_ALL': t(markTr('Comprobando todos los sitios…')),
    'PORTS': t(markTr('Puertos')),
    'SCAN_PORTS': t(markTr('Escanear puertos')),
    'RESCAN_PORTS': t(markTr('Volver a escanear')),
    'SCANNING': t(markTr('Escaneando puertos…')),
    'SCANNING_HOST': t(markTr('Probando {0} puertos de {1}…')),
    'SCAN_HEAD': t(markTr('{0} ({1}) · {2} abiertos de {3} · {4}')),
    'OPEN_PORTS': t(markTr('Puertos abiertos: {0}')),
    'NO_OPEN_PORTS': t(markTr('Ningún puerto abierto de los habituales')),
    'ERR_NO_HOST': t(markTr('no se encuentra el servidor')),
    'SCAN_DONE': t(markTr('Escaneo de puertos terminado')),
    'SCAN_NOTE': t(
      markTr(
        'Se prueban los puertos habituales (SSH, web, correo, bases de datos, Odoo…). Escanee solo servidores suyos o con permiso.',
      ),
    ),
    'RISKY_NOTE': t(
      markTr(
        'En ámbar, {0} que no conviene tener abiertos a internet: ciérrelos en el cortafuegos o limítelos a sus IP.',
      ),
    ),
    'DEMO_SHOP': t(markTr('Tienda online')),
    'DEMO_API': t(markTr('API de pedidos')),
    'DEMO_CLIENTS': t(markTr('Área de clientes')),
    'DEMO_BLOG': t(markTr('Blog')),
    'DEMO_DOCS': t(markTr('Documentación')),
    'DEMO_NEW': t(markTr('Web de la empresa')),
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
          width: 1100,
          height: 700,
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
            1040,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Cada segundo: la cuenta atrás y, cuando toca, otra ronda.
          _w(
            'Timer',
            'Tick',
            1000,
            8,
            32,
            32,
            {'interval': 1000},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Top', 0, 0, 1100, 104, {'bg': top}),
          lbl('LblUrl', 16, 16, 80, 30, t(markTr('Dirección'))),
          _w(
            'Entry',
            'Url',
            96,
            16,
            420,
            30,
            {'font_size': 14},
            {'enter_key': 'Url_enter'},
          )..parent = 'Top',
          lbl('LblName', 530, 16, 70, 30, t(markTr('Nombre'))),
          _w(
            'Entry',
            'SiteName',
            600,
            16,
            240,
            30,
            {'font_size': 14},
            {'enter_key': 'Url_enter'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnAdd',
            856,
            16,
            120,
            30,
            {
              'text': t(markTr('Añadir')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnAdd_click'},
          )..parent = 'Top',
          lbl('LblEvery', 16, 60, 120, 28, t(markTr('Comprobar cada'))),
          _w(
            'Combobox',
            'Every',
            136,
            60,
            110,
            28,
            {'items': '1 min\n2 min\n5 min\n10 min\n15 min\n30 min', 'text': '2 min'},
            {'select': 'Every_select'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnCheck',
            262,
            60,
            180,
            28,
            {'text': t(markTr('Comprobar todos ahora'))},
            {'command': 'BtnCheck_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnBar',
            452,
            60,
            230,
            28,
            {'text': t(markTr('Minimizar a la barra de menús'))},
            {'command': 'BtnBar_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 104, 1100, 572, {'bg': '#f4f6f9'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'BoardHint', 150, 300, 800, 40, {
            'text': t(
              markTr(
                'La lista de sitios con su historial la dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#f4f6f9',
            'font_size': 14,
          })..parent = 'Board',
          _w('StatusBar', 'Status', 0, 676, 1100, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Monitor de sitios web en C++ con FLTK: comprueba cada pocos minutos si los sitios contestan, guarda su historial y vive en la barra de menús.'))}
$_webmonIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_webmonCode''';
  return TkExample(
    'cpp_webmon',
    t(markTr('Monitor de sitios web (C++)')),
    t(
      markTr(
        'Un monitor de sitios web nativo en C++ con FLTK: añada direcciones y compruebe cada pocos minutos si contestan, con su tiempo de respuesta, la disponibilidad y el historial, y sígalos desde la barra de menús.',
      ),
    ),
    design,
    code,
  );
}
