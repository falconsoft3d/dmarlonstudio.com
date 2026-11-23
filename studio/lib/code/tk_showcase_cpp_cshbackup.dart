part of 'tk_examples.dart';

// ------------------------------------------- respaldos de community.sh (C++)
/// Baja a este equipo los respaldos de las instancias de Odoo de un panel de
/// community.sh, con la secuencia que se elija (cada hora, cada 2, 3, 4, 6 o
/// 12 horas, cada día o cada semana, a una hora), a la carpeta que se elija y
/// borrando los de más de N días (3 por defecto). Vive en la barra de menús de macOS y en el área de notificación
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
  item('SERVERS', t(markTr('Servidores SSH…')), mFile);
  item('LOG', t(markTr('Ver el historial')), mFile);
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
        'Escriba la dirección de su panel de community.sh y un token personal (en el panel: Configuración › API › Generar token) y pulse Conectar: aparecen sus instancias. Marque las que quiere respaldar.\n\nElija la carpeta donde guardarlos (cada instancia, en su subcarpeta), la frecuencia (cada hora, cada 2, 3, 4, 6 o 12 horas, cada día o cada semana), la hora (cada 2 horas desde las 03:00: 03:00, 05:00, 07:00…) y, si es semanal, el día. Si el equipo estaba apagado o dormido a esa hora, el respaldo se hace al volver.\n\nCon «Crear un respaldo nuevo», el panel hace uno en ese momento (con o sin los adjuntos) y se baja; sin marcarla, se baja el último que ya tenga el panel (un token de solo lectura basta). «Eliminar» quita los respaldos bajados hace más de los días elegidos (3 por defecto); siempre se queda el último de cada instancia y solo se borra lo que bajó esta app.\n\n«Servidores SSH…» añade servidores Linux (Ubuntu, Debian…) con PostgreSQL: se entra con una clave SSH o con una contraseña (que se guarda en el Llavero) y cada base de datos se vuelca con pg_dump a su carpeta, con la misma secuencia. Archivo › Ver el historial enseña lo que se bajó y lo que falló, y por qué.\n\nCerrar la ventana la esconde: sigue en la barra de menús (en Windows, junto al reloj), con el próximo respaldo, cada instancia y «Respaldar ahora».',
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
    'EMPTY_TITLE': t(markTr('Conecte su panel de community.sh o un servidor')),
    'EMPTY_HELP': t(
      markTr(
        'Escriba arriba la dirección del panel y un token personal (en el panel: Configuración › API › Generar token) y pulse Conectar. Para crear respaldos nuevos, el token no puede ser de solo lectura. Para las bases de datos de un servidor Linux por SSH, pulse «Servidores SSH…».',
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
    'BTN_NO': t(markTr('No')),
    'BTN_YES': t(markTr('Sí')),
    'NOTIFY_ERRORS_FIRST': t(markTr('{0} bajados · {1} con errores ({2})')),
    'LOG_START': t(markTr('Empieza el respaldo de {0}')),
    'LOG_OK': t(markTr('✓ {0}: {1} ({2})')),
    'LOG_ERR': t(markTr('✗ {0}: {1}')),
    'LOG_END': t(markTr('Fin: {0} bajados, {1} con errores')),
    'LOG_CONNECT_ERR': t(markTr('No se pudo conectar: {0}')),
    'LOG_EMPTY': t(markTr('Historial de los respaldos')),
    'CONNECTED_SSH': t(markTr('{0}: {1} bases de datos')),
    'SSH_SUB': t(markTr('PostgreSQL · {0} · {1}')),
    'SSH_CLOUD': t(markTr('Base de datos en el servidor')),
    'SSH_CLOUD_SIZE': t(markTr('{0} · se vuelca con pg_dump')),
    'E_NO_SSH': t(
      markTr(
        'No encuentro el programa ssh (en Windows: Configuración › Aplicaciones › Características opcionales › Cliente OpenSSH)',
      ),
    ),
    'E_SSH_KEY': t(
      markTr(
        'El servidor no acepta la clave SSH: revise el usuario y el archivo de clave',
      ),
    ),
    'E_SSH_PASSWORD': t(
      markTr('El servidor no acepta el usuario o la contraseña'),
    ),
    'E_SSH_HOSTKEY': t(
      markTr(
        'La huella del servidor ha cambiado (¿lo ha reinstalado?): quítelo y vuelva a añadirlo',
      ),
    ),
    'E_SSH_CONNECT': t(markTr('No se puede conectar con el servidor: {0}')),
    'E_SSH_SUDO': t(
      markTr(
        'El usuario {0} no puede usar PostgreSQL: entre como root o postgres, o dele sudo sin contraseña para postgres',
      ),
    ),
    'E_SSH_NO_PG': t(
      markTr('El servidor no tiene PostgreSQL (psql o pg_dump)'),
    ),
    'E_SSH_BAD_DUMP': t(
      markTr('El volcado de la base de datos llegó vacío o dañado'),
    ),
    'E_SSH_GONE': t(markTr('Ese servidor ya no está en la lista')),
    'E_SSH_NO_PASSWORD': t(
      markTr('Falta la contraseña del servidor: escríbala en Servidores SSH'),
    ),
    'E_SSH_EXIT': t(markTr('ssh terminó con el código {0}')),
    'SV_TITLE': t(markTr('Servidores SSH')),
    'SV_HELP': t(
      markTr(
        'Servidores Linux (Ubuntu, Debian…) con PostgreSQL: se entra por SSH y cada base de datos se vuelca con pg_dump a su carpeta de este equipo, con la misma secuencia. Entre como root o postgres, o con un usuario que tenga sudo sin contraseña para postgres.',
      ),
    ),
    'SV_NAME': t(markTr('Nombre')),
    'SV_HOST': t(markTr('Servidor')),
    'SV_PORT': t(markTr('Puerto')),
    'SV_USER': t(markTr('Usuario')),
    'SV_AUTH': t(markTr('Entrar con')),
    'SV_AUTH_KEY': t(markTr('Clave SSH (sin contraseña)')),
    'SV_AUTH_PW': t(markTr('Contraseña')),
    'SV_KEY': t(markTr('Archivo de clave')),
    'SV_KEY_HINT': t(markTr('Vacío: las claves de ~/.ssh')),
    'SV_PICK': t(markTr('Elegir…')),
    'SV_PASS': t(markTr('Contraseña')),
    'SV_PASS_KEEP': t(
      markTr('Deje la contraseña en blanco para mantener la guardada.'),
    ),
    'SV_NEW': t(markTr('Nuevo')),
    'SV_SAVE': t(markTr('Guardar')),
    'SV_DEL': t(markTr('Quitar')),
    'SV_TEST': t(markTr('Probar la conexión')),
    'SV_CLOSE': t(markTr('Cerrar')),
    'SV_SAVED': t(
      markTr('Guardado: {0}. Sus bases de datos aparecen en la lista.'),
    ),
    'SV_TESTING': t(markTr('Probando {0}…')),
    'SV_TEST_OK': t(markTr('Conectado: {0} bases de datos ({1})')),
    'SV_TEST_NONE': t(markTr('Conectado, pero no hay bases de datos')),
    'SV_ASK_DEL': t(
      markTr('¿Quitar el servidor «{0}»? Lo ya bajado se queda en la carpeta.'),
    ),
    'SV_ERR_HOST': t(markTr('Escriba la dirección del servidor')),
    'SV_ERR_PORT': t(markTr('El puerto va de 1 a 65535')),
    'SV_ERR_USER': t(markTr('Escriba el usuario')),
    'SV_ERR_PASS': t(markTr('Escriba la contraseña')),
    'SV_EMPTY': t(markTr('Sin servidores: rellene los datos y pulse Guardar.')),
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
            300,
            30,
            {'font_size': 14},
            {'enter_key': 'PanelUrl_enter'},
          )..parent = 'Top',
          lbl('LblToken', 418, 12, 56, 30, t(markTr('Token'))),
          _w(
            'Password',
            'Token',
            474,
            12,
            252,
            30,
            {'font_size': 14},
            {'enter_key': 'Token_enter'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnConnect',
            738,
            12,
            150,
            30,
            {
              'text': t(markTr('Conectar')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnConnect_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnServers',
            898,
            12,
            186,
            30,
            {'text': t(markTr('Servidores SSH…'))},
            {'command': 'BtnServers_click'},
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
                t(markTr('cada hora')),
                t(markTr('cada 2 horas')),
                t(markTr('cada 3 horas')),
                t(markTr('cada 4 horas')),
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
          lbl('LblKeep', 596, 92, 80, 30, t(markTr('Eliminar'))),
          _w(
            'Combobox',
            'Keep',
            676,
            92,
            150,
            30,
            {
              'items': [
                t(markTr('tras 1 día')),
                t(markTr('tras 2 días')),
                t(markTr('tras 3 días')),
                t(markTr('tras 7 días')),
                t(markTr('tras 14 días')),
                t(markTr('tras 30 días')),
                t(markTr('nunca')),
              ].join('\n'),
              'text': t(markTr('tras 3 días')),
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
        'Baja a su equipo los respaldos de las instancias de Odoo de su panel de community.sh: cada hora, cada pocas horas, cada día o cada semana, en la carpeta que elija y borrando los de más de unos días, desde la barra de menús de macOS o junto al reloj de Windows.',
      ),
    ),
    design,
    code,
  );
}
