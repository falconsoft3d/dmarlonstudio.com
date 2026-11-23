part of 'tk_examples.dart';

// ------------------------------------------- respaldos de community.sh (C++)
/// Baja a este equipo los respaldos de las instancias de Odoo de un panel de
/// community.sh, con la secuencia que se elija (cada 6 o 12 horas, cada día
/// o cada semana, a una hora), a la carpeta que se elija y conservando los N
/// últimos. Vive en la barra de menús de macOS y en el área de notificación
/// de Windows. En C++17 con FLTK; las peticiones a la API del panel, con curl.
TkExample tkCppCshBackup(String Function(String) t) {
  final app = t(markTr('Respaldos de community.sh'));
  final mFile = t(markTr('Archivo')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('RUN', t(markTr('Respaldar ahora')), mFile);
  item('FOLDER', t(markTr('Abrir la carpeta de respaldos')), mFile);
  lines.add('  -');
  item('BAR', t(markTr('Minimizar a la barra')), mFile);
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Respaldos de community.sh')), mHelp);
  final texts = <String, String>{
    'APP': app,
    'DEC': t(markTr(',')),
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'Escriba la dirección de su panel de community.sh y un token personal (en el panel: Ajustes › API › Crear token) y pulse Conectar: aparecen sus instancias. Marque las que quiere respaldar.\n\nElija la carpeta donde guardarlos (cada instancia, en su subcarpeta), la frecuencia (cada 6 o 12 horas, cada día o cada semana), la hora y, si es semanal, el día. Si el equipo estaba apagado o dormido a esa hora, el respaldo se hace al volver.\n\nCon «Crear un respaldo nuevo», el panel hace uno en ese momento (con o sin los adjuntos) y se baja; sin marcarla, se baja el último que ya tenga el panel (un token de solo lectura basta). «Conservar» borra los más antiguos de cada instancia, solo los que bajó esta app.\n\nCerrar la ventana la esconde: sigue en la barra de menús (en Windows, junto al reloj), con el próximo respaldo, cada instancia y «Respaldar ahora».',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú, los campos y el reloj se diseñaron en el Diseñador del estudio; la lista se dibuja en código, la API del panel se llama con curl en otro hilo y el icono de la barra se hace con el runtime de Objective-C en macOS y con Shell_NotifyIcon en Windows.',
      ),
    ),
    'WDAYS': t(markTr('lunes,martes,miércoles,jueves,viernes,sábado,domingo')),
    'WD_SHORT': t(markTr('lun,mar,mié,jue,vie,sáb,dom')),
    'TODAY': t(markTr('hoy {0}')),
    'TOMORROW': t(markTr('mañana {0}')),
    'YESTERDAY': t(markTr('ayer {0}')),
    'NEVER': t(markTr('nunca')),
    'DEFAULT_FOLDER': t(markTr('Respaldos community.sh')),
    'ST_QUEUED': t(markTr('En cola')),
    'ST_CREATING': t(markTr('El panel está haciendo un respaldo nuevo…')),
    'ST_CREATING_SHORT': t(markTr('respaldando en el panel')),
    'ST_LISTING': t(markTr('Buscando el último respaldo…')),
    'ST_LISTING_SHORT': t(markTr('buscando')),
    'ST_DOWNLOADING': t(markTr('{0} % · {1} de {2}')),
    'ST_DOWNLOADING_NOSIZE': t(markTr('{0} bajados')),
    'ST_OK': t(markTr('Bajado {0} · {1}')),
    'ST_SKIPPED': t(markTr('Ya estaba bajado · {0} · {1}')),
    'ST_NEVER': t(markTr('Todavía no se ha bajado')),
    'ST_NEVER_SHORT': t(markTr('sin bajar')),
    'ST_ERROR_SHORT': t(markTr('No se ha podido bajar')),
    'WITH_FILES': t(markTr('con adjuntos')),
    'STATE_SUB': t(markTr('Odoo {0} · {1}')),
    'COL_INSTANCE': t(markTr('INSTANCIA')),
    'COL_CLOUD': t(markTr('ÚLTIMO RESPALDO EN EL PANEL')),
    'COL_LOCAL': t(markTr('EN ESTE EQUIPO')),
    'BTN_GET': t(markTr('Descargar')),
    'BTN_FOLDER': t(markTr('Carpeta')),
    'EMPTY_TITLE': t(markTr('Conecte su panel de community.sh')),
    'EMPTY_HELP': t(
      markTr(
        'Escriba arriba la dirección del panel y un token personal (en el panel: Ajustes › API › Crear token) y pulse Conectar. Para crear respaldos nuevos, el token no puede ser de solo lectura.',
      ),
    ),
    'EMPTY_NO_INST_TITLE': t(markTr('Sin instancias')),
    'EMPTY_NO_INST': t(
      markTr('El panel no tiene instancias que este token pueda respaldar.'),
    ),
    'CONNECTING': t(markTr('Conectando con el panel…')),
    'CONNECTED': t(markTr('Conectado: {0} instancias')),
    'E_NO_CURL': t(markTr('No encuentro curl')),
    'E_CONNECT': t(markTr('No se puede conectar con el panel: {0}')),
    'E_TOKEN': t(
      markTr(
        'El panel no acepta el token: puede estar mal escrito, haber caducado o faltarle la verificación en dos pasos',
      ),
    ),
    'E_READONLY': t(
      markTr(
        'El token es de solo lectura y no puede crear respaldos: desmarque «Crear un respaldo nuevo» o use otro token',
      ),
    ),
    'E_FORBIDDEN': t(
      markTr('El token no tiene permiso para los respaldos de esta instancia'),
    ),
    'E_NOT_FOUND': t(
      markTr('El panel no lo encuentra (¿es correcta la dirección?)'),
    ),
    'E_RATE': t(markTr('El panel pide esperar un poco: demasiadas peticiones')),
    'E_HTTP': t(markTr('El panel contestó {0}')),
    'E_BAD_ANSWER': t(markTr('El panel contestó algo que no entiendo')),
    'E_TASK_FAILED': t(markTr('El respaldo falló en el panel: {0}')),
    'E_TIMEOUT': t(markTr('El respaldo tarda demasiado en el panel')),
    'E_NO_BACKUPS': t(markTr('El panel no tiene respaldos de esta instancia')),
    'E_FOLDER': t(markTr('No puedo escribir en la carpeta {0}')),
    'E_SIZE': t(markTr('El archivo llegó incompleto ({0} de {1})')),
    'E_RENAME': t(markTr('No puedo guardar el archivo en {0}')),
    'BAD_URL': t(
      markTr('Esa dirección no vale: escriba algo como communitysh.xyz'),
    ),
    'NEED_TOKEN': t(
      markTr('Falta el token: escríbalo arriba y pulse Conectar'),
    ),
    'NEED_FOLDER': t(markTr('Elija la carpeta donde guardar los respaldos')),
    'NONE_SELECTED': t(markTr('Marque al menos una instancia')),
    'ALREADY_RUNNING_JOB': t(markTr('Ya hay un respaldo en curso')),
    'NO_CONFIG': t(markTr('Sin conectar: escriba arriba el panel y su token')),
    'RUNNING': t(markTr('Respaldando {0} de {1}…')),
    'HEAD': t(markTr('{0} instancias · {1} marcadas')),
    'NEXT': t(markTr('Próximo respaldo: {0}')),
    'LAST': t(markTr('Último: {0}')),
    'SCHEDULE_SET': t(markTr('Próximo respaldo: {0}')),
    'FOLDER_SET': t(markTr('Los respaldos se guardarán en {0}')),
    'CHOOSE_FOLDER': t(markTr('Carpeta para los respaldos')),
    'LOGIN_ON': t(markTr('Se abrirá al iniciar sesión, ya en la barra')),
    'LOGIN_OFF': t(markTr('Ya no se abrirá al iniciar sesión')),
    'LOGIN_FAIL': t(markTr('No he podido cambiar el inicio de sesión')),
    'ALREADY_OPEN': t(
      markTr(
        'Respaldos de community.sh ya está abierta: búsquela en la barra de menús (en Windows, junto al reloj).',
      ),
    ),
    'NOTIFY_TITLE': t(markTr('Respaldos de community.sh')),
    'NOTIFY_DONE': t(markTr('{0} respaldos bajados')),
    'NOTIFY_ERRORS': t(markTr('{0} bajados · {1} con errores')),
    'BAR_NEXT': t(markTr('Próximo respaldo: {0}')),
    'BAR_LAST': t(markTr('Último: {0}')),
    'BAR_RUN': t(markTr('Respaldar ahora')),
    'BAR_RUNNING': t(markTr('Respaldando… {0} de {1}')),
    'BAR_GET': t(markTr('Bajar ahora')),
    'BAR_OPEN_FOLDER': t(markTr('Abrir su carpeta')),
    'BAR_FOLDER': t(markTr('Abrir la carpeta de respaldos')),
    'BAR_WINDOW': t(markTr('Abrir la ventana…')),
    'BAR_QUIT': t(markTr('Salir')),
    'MINIMIZE': t(markTr('Minimizar')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const top = '#f6f7fb';
  TkWidget lbl(String name, int x, int y, int w, int h, String text) => _w(
    'Label',
    name,
    x,
    y,
    w,
    h,
    {'text': text, 'bg': top, 'fg': '#374151', 'font_size': 13, 'anchor': 'w'},
  )..parent = 'Top';
  final design =
      TkDesign(
          width: 1100,
          height: 720,
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
          // Cada segundo: el progreso, la cuenta atrás y, cuando toca, el respaldo.
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
          _w('Frame', 'Top', 0, 0, 1100, 172, {'bg': top}),
          // El panel y su token.
          lbl('LblPanel', 16, 12, 90, 30, t(markTr('Dirección'))),
          _w(
            'Entry',
            'PanelUrl',
            106,
            12,
            340,
            30,
            {'font_size': 14},
            {'enter_key': 'PanelUrl_enter'},
          )..parent = 'Top',
          lbl('LblToken', 462, 12, 60, 30, t(markTr('Token'))),
          _w(
            'Password',
            'Token',
            522,
            12,
            370,
            30,
            {'font_size': 14},
            {'enter_key': 'Token_enter'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnConnect',
            904,
            12,
            180,
            30,
            {
              'text': t(markTr('Conectar')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnConnect_click'},
          )..parent = 'Top',
          // Dónde se guardan.
          lbl('LblFolder', 16, 52, 90, 30, t(markTr('Guardar en'))),
          _w(
            'Entry',
            'Folder',
            106,
            52,
            620,
            30,
            {'font_size': 14},
            {'enter_key': 'Folder_enter'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnFolder',
            738,
            52,
            150,
            30,
            {'text': t(markTr('Elegir carpeta…'))},
            {'command': 'BtnFolder_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnOpen',
            898,
            52,
            186,
            30,
            {'text': t(markTr('Abrir la carpeta'))},
            {'command': 'BtnOpen_click'},
          )..parent = 'Top',
          // La secuencia.
          lbl('LblEvery', 16, 92, 90, 30, t(markTr('Respaldar'))),
          _w(
            'Combobox',
            'Every',
            106,
            92,
            150,
            30,
            {
              'items': [
                t(markTr('cada 6 horas')),
                t(markTr('cada 12 horas')),
                t(markTr('cada día')),
                t(markTr('cada semana')),
              ].join('\n'),
              'text': t(markTr('cada día')),
            },
            {'select': 'Every_select'},
          )..parent = 'Top',
          lbl('LblAt', 266, 92, 50, 30, t(markTr('a las'))),
          _w(
            'Combobox',
            'At',
            316,
            92,
            90,
            30,
            {'items': '00:00\n03:00\n12:00', 'text': '03:00'},
            {'select': 'At_select'},
          )..parent = 'Top',
          lbl('LblDay', 416, 92, 30, 30, t(markTr('el'))),
          _w(
            'Combobox',
            'Day',
            446,
            92,
            130,
            30,
            {
              'items': [t(markTr('lunes')), t(markTr('domingo'))].join('\n'),
              'text': t(markTr('lunes')),
            },
            {'select': 'Day_select'},
          )..parent = 'Top',
          lbl('LblKeep', 596, 92, 80, 30, t(markTr('Conservar'))),
          _w(
            'Combobox',
            'Keep',
            676,
            92,
            150,
            30,
            {
              'items': [
                t(markTr('los 3 últimos')),
                t(markTr('los 7 últimos')),
                t(markTr('los 14 últimos')),
                t(markTr('los 30 últimos')),
                t(markTr('todos')),
              ].join('\n'),
              'text': t(markTr('los 7 últimos')),
            },
            {'select': 'Keep_select'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnRun',
            898,
            92,
            186,
            30,
            {
              'text': t(markTr('Respaldar ahora')),
              'bg': '#16a34a',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnRun_click'},
          )..parent = 'Top',
          // Las opciones.
          _w(
            'Checkbutton',
            'Fresh',
            16,
            132,
            330,
            30,
            {
              'text': t(markTr('Crear un respaldo nuevo antes de bajarlo')),
              'bg': top,
            },
            {'command': 'Fresh_click'},
          )..parent = 'Top',
          _w(
            'Checkbutton',
            'Filestore',
            352,
            132,
            250,
            30,
            {'text': t(markTr('con los adjuntos (filestore)')), 'bg': top},
            {'command': 'Filestore_click'},
          )..parent = 'Top',
          _w(
            'Checkbutton',
            'Login',
            610,
            132,
            270,
            30,
            {'text': t(markTr('Abrir al iniciar sesión')), 'bg': top},
            {'command': 'Login_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnBar',
            898,
            132,
            186,
            30,
            {'text': t(markTr('Minimizar a la barra'))},
            {'command': 'BtnBar_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 172, 1100, 524, {'bg': '#f4f6f9'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'BoardHint', 150, 300, 800, 40, {
            'text': t(
              markTr(
                'La lista de instancias y sus respaldos la dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#f4f6f9',
            'font_size': 14,
          })..parent = 'Board',
          _w('StatusBar', 'Status', 0, 696, 1100, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Respaldos de community.sh en C++ con FLTK: baja los respaldos de las instancias del panel con la secuencia elegida, a la carpeta elegida, y vive en la barra de menús o junto al reloj de Windows.'))}
$_cshbkIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_cshbkCode''';
  return TkExample(
    'cpp_cshbackup',
    t(markTr('Respaldos de community.sh (C++)')),
    t(
      markTr(
        'Baja a su equipo los respaldos de las instancias de Odoo de su panel de community.sh: cada 6 o 12 horas, cada día o cada semana a la hora que elija, en la carpeta que elija y conservando los últimos, desde la barra de menús de macOS o junto al reloj de Windows.',
      ),
    ),
    design,
    code,
  );
}
