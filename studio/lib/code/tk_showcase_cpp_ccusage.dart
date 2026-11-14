part of 'tk_examples.dart';

// ------------------------------------------------ Uso de Claude Code (C++)
/// El uso de Claude Code en C++17 con FLTK: los tokens, lo que cuestan y las
/// sesiones de cada día en un mapa de calor como el de GitHub, con las
/// cifras de hoy, la semana, el mes y el año, por modelo y por proyecto. Lee
/// los registros que Claude Code guarda en el equipo (cualquier plan) o la
/// API de Claude Code Analytics (clave de administrador) y vive en la barra
/// de menús de macOS con lo gastado hoy.
TkExample tkCppCcUsage(String Function(String) t) {
  final app = t(markTr('Uso de Claude Code'));
  final mFile = t(markTr('Archivo')),
      mView = t(markTr('Ver')),
      mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('REFRESH', t(markTr('Actualizar ahora')), mFile);
  item('EXPORT', t(markTr('Exportar a CSV…')), mFile);
  item('SETTINGS', t(markTr('Ajustes…')), mFile);
  lines.add('  -');
  item('BAR', t(markTr('Minimizar a la barra de menús')), mFile);
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mView);
  item('COST', t(markTr('Coste')), mView);
  item('TOKENS', t(markTr('Tokens')), mView);
  item('SESSIONS', t(markTr('Sesiones')), mView);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('PRICES', t(markTr('Precios que se usan')), mHelp);
  item('ABOUT', t(markTr('Acerca de Uso de Claude Code')), mHelp);
  final srcLocal = t(markTr('Registros locales de Claude Code')),
      srcApi = t(markTr('API de administración (Admin API)'));
  final mCost = t(markTr('Coste')),
      mTokens = t(markTr('Tokens')),
      mSessions = t(markTr('Sesiones'));
  final perToday = t(markTr('Hoy')),
      perWeek = t(markTr('Últimos 7 días')),
      per30 = t(markTr('Últimos 30 días')),
      perMonth = t(markTr('Este mes')),
      perYear = t(markTr('Este año')),
      perAll = t(markTr('Todo'));
  final texts = <String, String>{
    'APP': app,
    'DEC': t(markTr(',')),
    'THOUSANDS': t(markTr('.')),
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'Uso de Claude Code le enseña cuánto usa Claude Code: los tokens, lo que cuestan y las sesiones de cada día, en un mapa de calor como el de GitHub (un cuadrado por día del último año: cuanto más oscuro, más uso), con las cifras de hoy, la semana, el mes y el año, y el reparto por modelo y por proyecto.\n\nLos datos salen de dos sitios (elíjalo en «Origen»):\n• Registros locales: lo que Claude Code guarda en su equipo (~/.claude/projects). Sirve con cualquier plan, también Pro y Max. El coste es lo que costarían esos tokens con la API, con el precio de cada modelo.\n• API de administración: la API de Claude Code Analytics de Anthropic, con una clave de administrador (sk-ant-admin…) de su organización de Claude Console. Da el coste estimado, las sesiones, las líneas, los commits y las PR de cada persona. No incluye el uso con planes Pro, Max, Team o Enterprise.\n\nSe actualiza solo cada 15 minutos (cámbielo en Ajustes). Pulse un día del mapa o una barra para ver su detalle. En Ajustes también puede poner un presupuesto mensual: la app le avisa al pasarlo.\n\nAl cerrar la ventana, la app se queda en la barra de menús con lo gastado hoy; su menú enseña la semana, el mes, los últimos 7 días y el gasto por modelo.',
      ),
    ),
    'PRICES_TEXT': t(
      markTr(
        'Dólares por millón de tokens: entrada · escritura en la caché (5 min / 1 h) · lectura de la caché · salida.\n\nFable 5.2: 8 · 10 / 16 · 0,20 · 40\nFable 5.1: 10 · 12,50 / 20 · 0,25 · 50\nOpus 5.5: 4 · 5 / 8 · 0,20 · 20\nOpus 5 y 4.5 a 4.8: 5 · 6,25 / 10 · 0,50 · 25\nSonnet 5.5: 2 · 2,50 / 4 · 0,10 · 10\nSonnet 5: 2 · 2,50 / 4 · 0,20 · 10\nSonnet 4.x: 3 · 3,75 / 6 · 0,30 · 15\nHaiku 5.5: 0,10 · 0,125 / 0,20 · 0,01 · 0,50 (con más de 100.000 tokens de entrada, cinco veces más)\nHaiku 4.5: 1 · 1,25 / 2 · 0,10 · 5\n\nEl modo rápido cuesta el doble. Son los precios de la API de Anthropic (noviembre de 2026). Con un plan Pro o Max no se paga así: es lo que costaría ese uso con la API.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú, los combos, los botones y el reloj se diseñaron en el Diseñador del estudio; el panel (las cifras, el mapa de calor, las barras y las tablas) se dibuja en el código de Form1.cpp. Los registros se leen en otro hilo, la API se llama con curl y el icono de la barra de menús se hace desde C++ con el runtime de Objective-C. No es una app de Anthropic.',
      ),
    ),
    'MONEY': t(markTr('{0} \$')),
    'TOK_K': t(markTr('{0} k')),
    'TOK_M': t(markTr('{0} M')),
    'TOK_B': t(markTr('{0} mil M')),
    'SIZE_KB': t(markTr('{0} kB')),
    'SIZE_MB': t(markTr('{0} MB')),
    'SIZE_GB': t(markTr('{0} GB')),
    'WD_1': t(markTr('lu')),
    'WD_2': t(markTr('ma')),
    'WD_3': t(markTr('mi')),
    'WD_4': t(markTr('ju')),
    'WD_5': t(markTr('vi')),
    'WD_6': t(markTr('sá')),
    'WD_7': t(markTr('do')),
    'WDL_1': t(markTr('lunes')),
    'WDL_2': t(markTr('martes')),
    'WDL_3': t(markTr('miércoles')),
    'WDL_4': t(markTr('jueves')),
    'WDL_5': t(markTr('viernes')),
    'WDL_6': t(markTr('sábado')),
    'WDL_7': t(markTr('domingo')),
    'MON_1': t(markTr('ene')),
    'MON_2': t(markTr('feb')),
    'MON_3': t(markTr('mar')),
    'MON_4': t(markTr('abr')),
    'MON_5': t(markTr('may')),
    'MON_6': t(markTr('jun')),
    'MON_7': t(markTr('jul')),
    'MON_8': t(markTr('ago')),
    'MON_9': t(markTr('sept')),
    'MON_10': t(markTr('oct')),
    'MON_11': t(markTr('nov')),
    'MON_12': t(markTr('dic')),
    'MONL_1': t(markTr('enero')),
    'MONL_2': t(markTr('febrero')),
    'MONL_3': t(markTr('marzo')),
    'MONL_4': t(markTr('abril')),
    'MONL_5': t(markTr('mayo')),
    'MONL_6': t(markTr('junio')),
    'MONL_7': t(markTr('julio')),
    'MONL_8': t(markTr('agosto')),
    'MONL_9': t(markTr('septiembre')),
    'MONL_10': t(markTr('octubre')),
    'MONL_11': t(markTr('noviembre')),
    'MONL_12': t(markTr('diciembre')),
    'DAY_SHORT': t(markTr('{0} {1} {2}')),
    'DAY_LONG': t(markTr('{0}, {1} de {2} de {3}')),
    'TODAY_CAP': perToday,
    'SESSIONS_ONE': t(markTr('{0} sesión')),
    'SESSIONS_N': t(markTr('{0} sesiones')),
    'TOKENS_N': t(markTr('{0} tokens')),
    'M_COST_L': mCost,
    'M_TOKENS_L': mTokens,
    'M_SESSIONS_L': mSessions,
    'K_TODAY': perToday,
    'K_WEEK': perWeek,
    'K_MONTH': perMonth,
    'K_YEAR': perYear,
    'K_STREAK': t(markTr('Racha')),
    'DAYS_ONE': t(markTr('{0} día')),
    'DAYS_N': t(markTr('{0} días')),
    'BEST_STREAK': t(markTr('Récord: {0} días seguidos')),
    'OF_BUDGET': t(markTr('{0} % del presupuesto de {1}')),
    'HEAT_TITLE': t(markTr('{0} del último año')),
    'HEAT_TOTAL': t(markTr('{0} · {1} días con uso')),
    'HEAT_HINT': t(markTr('Pulse un día para ver su detalle')),
    'LESS': t(markTr('Menos')),
    'MORE': t(markTr('Más')),
    'D_NONE': t(markTr('Sin uso este día')),
    'D_IN_OUT': t(markTr('Entrada {0} · salida {1}')),
    'D_CACHE': t(markTr('Caché: escritura {0} · lectura {1}')),
    'D_SESS_MSGS': t(markTr('{0} · {1} mensajes')),
    'D_SESS_LINES': t(markTr('{0} · +{1} −{2} líneas')),
    'BARS_TITLE': t(markTr('{0}, últimos 30 días')),
    'OTHERS': t(markTr('Otros')),
    'BY_MODEL': t(markTr('Por modelo')),
    'BY_PROJECT': t(markTr('Por proyecto')),
    'BY_USER': t(markTr('Por persona')),
    'PER_TODAY': perToday,
    'PER_WEEK': perWeek,
    'PER_30': per30,
    'PER_MONTH': perMonth,
    'PER_YEAR': perYear,
    'PER_ALL': perAll,
    'NO_DATA_PERIOD': t(markTr('Sin uso en este periodo')),
    'AND_MORE': t(markTr('y {0} más…')),
    'SRC_LOCAL': srcLocal,
    'SRC_API': srcApi,
    'NEED_KEY': t(
      markTr(
        'Para usar la API, ponga su clave de administrador en Archivo › Ajustes…',
      ),
    ),
    'STATUS_LINE': t(markTr('{0} · actualizado a las {1} · el próximo, en {2}')),
    'MINUTES': t(markTr('{0} min')),
    'READING': t(markTr('Leyendo los registros de Claude Code…')),
    'READING_N': t(markTr('Leyendo los registros de Claude Code: {0} de {1}…')),
    'READING_HELP': t(
      markTr(
        'La primera vez se leen todos (pueden ser varios gigas); después, solo lo nuevo.',
      ),
    ),
    'DOWNLOADING': t(markTr('Bajando de la API: día {0} de {1}…')),
    'DOWNLOADING_T': t(markTr('Bajando los datos de la API…')),
    'EMPTY_LOCAL_T': t(markTr('No hay registros de Claude Code en este equipo')),
    'EMPTY_LOCAL_H': t(
      markTr(
        'Se buscan en {0}. Si los tiene en otra carpeta, elíjala en Archivo › Ajustes…',
      ),
    ),
    'EMPTY_API_T': t(markTr('Falta la clave de administrador')),
    'EMPTY_API_H': t(
      markTr(
        'La API de Claude Code Analytics necesita una clave sk-ant-admin… de su organización de Claude Console. Póngala en Archivo › Ajustes…',
      ),
    ),
    'EMPTY_API_NONE_T': t(markTr('La API no tiene uso de Claude Code')),
    'EMPTY_API_NONE_H': t(
      markTr(
        'La API solo cuenta el uso con cuentas de la API de su organización, no el de los planes Pro o Max: para ese, use los registros locales.',
      ),
    ),
    'API_401': t(
      markTr(
        'La clave no vale (401): hace falta una clave de administrador (sk-ant-admin…)',
      ),
    ),
    'API_403': t(
      markTr(
        'La clave no tiene permiso (403): use una clave de administrador de la organización',
      ),
    ),
    'API_404': t(
      markTr('La API no está disponible para esta organización (404)'),
    ),
    'API_429': t(
      markTr(
        'Demasiadas peticiones (429): se volverá a intentar en la próxima actualización',
      ),
    ),
    'API_ERR': t(markTr('Error {0} de la API: {1}')),
    'ERR_NO_CURL': t(markTr('No encuentro curl')),
    'ERR_NO_ANSWER': t(markTr('La API no contesta')),
    'ERR_BAD_ANSWER': t(
      markTr('La API ha contestado algo que no se entiende'),
    ),
    'UNKNOWN': t(markTr('Sin nombre')),
    'NO_PROJECT': t(markTr('Sin proyecto')),
    'BAR_TODAY': t(markTr('Hoy: {0} · {1} tokens')),
    'BAR_WEEK': t(markTr('Últimos 7 días: {0} · {1} tokens')),
    'BAR_MONTH': t(markTr('Este mes: {0} · {1} tokens')),
    'BAR_MONTH_OF': t(markTr('Este mes: {0} de {1} ({2} %)')),
    'LAST_7': t(markTr('Día a día')),
    'BY_MODEL_MONTH': t(markTr('Por modelo, este mes')),
    'REFRESH_NOW': t(markTr('Actualizar ahora')),
    'SOURCE_MENU': t(markTr('Origen')),
    'SHOW_MENU': mView,
    'TO_BAR': t(markTr('Minimizar a la barra de menús')),
    'MINIMIZE': t(markTr('Minimizar')),
    'OPEN_WINDOW': t(markTr('Abrir la ventana…')),
    'SETTINGS_DOTS': t(markTr('Ajustes…')),
    'QUIT': t(markTr('Salir')),
    'REFRESHING': t(markTr('Actualizando…')),
    'EXPORTED': t(markTr('Exportado a {0}')),
    'EXPORT_FAILED': t(markTr('No se ha podido guardar el archivo')),
    'BUDGET_TITLE': t(markTr('Presupuesto de Claude Code')),
    'BUDGET_TEXT': t(
      markTr('Este mes lleva {0}: ha pasado su presupuesto de {1}'),
    ),
    'SETTINGS_TITLE': t(markTr('Ajustes')),
    'S_KEY': t(markTr('Clave de administrador de la API (opcional)')),
    'S_CREATE_KEY': t(markTr('Crear una clave…')),
    'S_KEY_NOTE': t(
      markTr(
        'Solo para el origen «API de administración». Se crea en Claude Console › Ajustes › Admin keys y empieza por sk-ant-admin. Se guarda en este equipo, solo para su usuario. No sirve para planes Pro o Max: para esos, use los registros locales.',
      ),
    ),
    'S_DAYS': t(markTr('Días que se bajan de la API')),
    'S_DAYS_ITEM': t(markTr('{0} días')),
    'S_EVERY': t(markTr('Actualizar cada')),
    'S_BUDGET': t(markTr('Presupuesto mensual (dólares)')),
    'S_LOGS': t(
      markTr('Carpeta de los registros de Claude Code (vacío: la de siempre)'),
    ),
    'S_PICK': t(markTr('Elegir…')),
    'S_LOGS_NOTE': t(markTr('Por defecto: {0}')),
    'CANCEL': t(markTr('Cancelar')),
    'SAVE': t(markTr('Guardar')),
    'S_BAD_BUDGET': t(
      markTr('El presupuesto debe ser un número, como 200 o 150,50'),
    ),
    'S_BAD_LOGS': t(markTr('No existe la carpeta {0}')),
    'S_NOT_ADMIN': t(
      markTr(
        'Guardado. Ojo: la clave no parece de administrador (sk-ant-admin…) y la API la rechazará',
      ),
    ),
    'S_SAVED': t(markTr('Ajustes guardados')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const top = '#f4f6f9';
  TkWidget lbl(String name, int x, int w, String text) =>
      _w('Label', name, x, 14, w, 28, {
        'text': text,
        'bg': top,
        'fg': '#374151',
        'font_size': 13,
      })..parent = 'Top';
  TkWidget combo(String name, int x, int w, List<String> items, int index,
          String handler) =>
      _w(
        'Combobox',
        name,
        x,
        14,
        w,
        28,
        {'items': items.join('\n'), 'text': items[index]},
        {'select': handler},
      )..parent = 'Top';
  final design =
      TkDesign(
          width: 1200,
          height: 820,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': top,
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1140,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Cada segundo: la barra de estado y, cuando toca, otra lectura.
          _w(
            'Timer',
            'Tick',
            1100,
            8,
            32,
            32,
            {'interval': 1000},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Top', 0, 0, 1200, 56, {'bg': top}),
          lbl('LblSource', 16, 56, t(markTr('Origen'))),
          combo('Source', 72, 250, [srcLocal, srcApi], 0, 'Source_select'),
          lbl('LblMetric', 336, 36, mView),
          combo('Metric', 372, 120, [mCost, mTokens, mSessions], 0,
              'Metric_select'),
          lbl('LblPeriod', 506, 64, t(markTr('Periodo'))),
          combo('Period', 570, 150,
              [perToday, perWeek, per30, perMonth, perYear, perAll], 2,
              'Period_select'),
          _w(
            'Button',
            'BtnRefresh',
            736,
            14,
            110,
            28,
            {
              'text': t(markTr('Actualizar')),
              'bg': '#d97757',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnRefresh_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnSettings',
            856,
            14,
            100,
            28,
            {'text': t(markTr('Ajustes…'))},
            {'command': 'BtnSettings_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnBar',
            966,
            14,
            218,
            28,
            {'text': t(markTr('Minimizar a la barra de menús'))},
            {'command': 'BtnBar_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 56, 1200, 740, {'bg': top}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'BoardHint', 200, 380, 800, 40, {
            'text': t(
              markTr(
                'El panel (cifras, mapa de calor, barras y tablas) lo dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': top,
            'font_size': 14,
          })..parent = 'Board',
          _w('StatusBar', 'Status', 0, 796, 1200, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Uso de Claude Code en C++ con FLTK: los tokens, el coste y las sesiones de cada día en un mapa de calor como el de GitHub, desde los registros de Claude Code o la API de administración, y en la barra de menús.'))}
$_ccUsageIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_ccUsageCode''';
  return TkExample(
    'cpp_ccusage',
    t(markTr('Uso de Claude Code (C++)')),
    t(
      markTr(
        'El uso de Claude Code nativo en C++ con FLTK: tokens, coste y sesiones de cada día en un mapa de calor como el de GitHub, por modelo y por proyecto, desde los registros del equipo o la API de administración, y en la barra de menús con lo gastado hoy.',
      ),
    ),
    design,
    code,
  );
}
