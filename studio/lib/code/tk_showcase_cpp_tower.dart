part of 'tk_examples.dart';

// ------------------------------------------------ Torre de control (C++)
/// Todas las sesiones de Claude Code de este equipo (en VS Code, en la
/// terminal…) en C++17 con FLTK: lo que hace cada una ahora mismo, si
/// trabaja, espera o pregunta algo, sus tareas, sus subagentes y dónde prueba
/// la app. Lee lo que Claude Code deja en ~/.claude (sin configurar nada) y,
/// además, recibe los informes de avance de los agentes en un servidor local,
/// como la torre de control web. Vive en la barra de menús de macOS.
TkExample tkCppTower(String Function(String) t) {
  final app = t(markTr('Torre de control de Claude Code'));
  final mFile = t(markTr('Archivo')),
      mView = t(markTr('Ver')),
      mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  final fOpen = t(markTr('Solo las abiertas')),
      fDay = t(markTr('Abiertas y de las últimas 24 h')),
      fWeek = t(markTr('De los últimos 7 días'));
  final sActivity = t(markTr('Actividad reciente')),
      sState = t(markTr('Estado')),
      sProject = t(markTr('Proyecto'));
  lines.add(mFile);
  item('REFRESH', t(markTr('Actualizar ahora')), mFile);
  item('AGENTS', t(markTr('Instrucciones para los agentes…')), mFile);
  lines.add('  -');
  item('BAR', t(markTr('Minimizar a la barra de menús')), mFile);
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mView);
  item('OPEN', fOpen, mView);
  item('DAY', fDay, mView);
  item('WEEK', fWeek, mView);
  lines.add('  -');
  item('EXPAND', t(markTr('Abrir el detalle de todas')), mView);
  item('COLLAPSE', t(markTr('Cerrar el detalle de todas')), mView);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de la Torre de control')), mHelp);
  final stWork = t(markTr('Trabajando'));
  final texts = <String, String>{
    'APP': app,
    'DEC': t(markTr(',')),
    'THOUSANDS': t(markTr('.')),
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'La Torre de control enseña todas las sesiones de Claude Code abiertas en este equipo (en VS Code, en la terminal o en otros editores), una fila por sesión, con lo que hace cada una ahora mismo.\n\nNo hay que configurar nada: lee lo que Claude Code deja en su carpeta (~/.claude). En sessions/ está cada sesión abierta y si está ocupada o esperando; en projects/, la conversación de cada una: el título, la última orden, la herramienta que usa, las tareas, los subagentes, los tokens y los archivos que ha tocado.\n\nEstados: Trabajando (verde), Te pregunta (naranja: espera una respuesta o un permiso), Te espera (amarillo: terminó y espera su siguiente orden), En reposo (más de 30 minutos sin nada) y Cerrada.\n\nCon tareas, la barra enseña el avance y el robot va hacia la meta; sin ellas, la barra es la última hora de trabajo: cada raya, una herramienta. Pulse una fila para ver el detalle: los últimos pasos, los archivos, los subagentes, la orden y la respuesta, y los botones para abrir la carpeta en VS Code o copiar «claude --resume».\n\nAgentes: si les pasa las instrucciones (Archivo › Instrucciones para los agentes…), cada agente informa de su avance con un POST a un servidor local (solo en este equipo) y sale como otra fila, con sus tareas hechas y pendientes, como en la torre de control web.\n\nAl cerrar la ventana, la app se queda en la barra de menús con las sesiones que trabajan; si una termina o pregunta algo, avisa.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú, los combos, la casilla, los botones y el reloj se diseñaron en el Diseñador del estudio; las filas (el robot, la barra, los estados y el detalle) se dibujan en el código de Form1.cpp. Los registros se leen en otro hilo, el servidor de los agentes es un socket en 127.0.0.1 y el icono de la barra de menús se hace desde C++ con el runtime de Objective-C. No es una app de Anthropic.',
      ),
    ),
    'MONEY': t(markTr('{0} \$')),
    'TOK_K': t(markTr('{0} k')),
    'TOK_M': t(markTr('{0} M')),
    'TOK_B': t(markTr('{0} mil M')),
    'JUST_NOW': t(markTr('ahora mismo')),
    'AGO_S': t(markTr('hace {0} s')),
    'AGO_M': t(markTr('hace {0} min')),
    'AGO_H': t(markTr('hace {0} h')),
    'AGO_D': t(markTr('hace {0} días')),
    'SHORT_S': t(markTr('{0} s')),
    'SHORT_M': t(markTr('{0} min')),
    'SHORT_H': t(markTr('{0} h')),
    'SHORT_D': t(markTr('{0} d')),
    'N_TASKS': t(markTr('{0} tareas')),
    'DO_BASH': t(markTr('Ejecuta: {0}')),
    'DO_READ': t(markTr('Lee {0}')),
    'DO_EDIT': t(markTr('Edita {0}')),
    'DO_WRITE': t(markTr('Escribe {0}')),
    'DO_SEARCH': t(markTr('Busca {0}')),
    'DO_FETCH': t(markTr('Consulta {0}')),
    'DO_WEB': t(markTr('Busca en la web: {0}')),
    'DO_AGENT': t(markTr('Lanza un subagente: {0}')),
    'DO_ASK': t(markTr('Te pregunta: {0}')),
    'DO_TODO': t(markTr('Ordena sus tareas')),
    'DO_OTHER': t(markTr('{1}: {0}')),
    'PLAN_READY': t(markTr('Tiene un plan para que lo apruebes')),
    'ST_WORK': stWork,
    'ST_ASK': t(markTr('Te pregunta')),
    'ST_WAIT': t(markTr('Te espera')),
    'ST_IDLE': t(markTr('En reposo')),
    'ST_CLOSED': t(markTr('Cerrada')),
    'ST_ERROR': t(markTr('Error')),
    'ST_DONE': t(markTr('Terminado')),
    'ST_BLOCKED': t(markTr('Bloqueado')),
    'NO_SIGNAL': t(markTr('Sin señal')),
    'IN_VSCODE': t(markTr('VS Code')),
    'IN_TERMINAL': t(markTr('Terminal')),
    'IN_DESKTOP': t(markTr('App de escritorio')),
    'BRANCH': t(markTr('rama {0}')),
    'REPORTED': t(markTr('Agente que informa')),
    'L_NOW': t(markTr('AHORA')),
    'L_ASKS': t(markTr('TE PREGUNTA')),
    'L_ERROR': t(markTr('ERROR')),
    'L_FINISHED': t(markTr('TERMINÓ')),
    'L_LAST_PROMPT': t(markTr('ÚLTIMA ORDEN')),
    'L_PROMPT': t(markTr('ORDEN')),
    'L_SAID': t(markTr('RESPUESTA')),
    'THINKING': t(markTr('Pensando…')),
    'SUBS_WAIT_ONE': t(markTr('Espera a {0} subagente')),
    'SUBS_WAIT_N': t(markTr('Espera a {0} subagentes')),
    'ASKS_PERMISSION': t(markTr('Espera tu respuesta o un permiso')),
    'API_ERROR': t(markTr('La API de Claude ha dado un error')),
    'WAITING_YOU': t(markTr('Espera tu siguiente orden')),
    'F_PROMPTS_ONE': t(markTr('{0} orden')),
    'F_PROMPTS_N': t(markTr('{0} órdenes')),
    'F_TOOLS': t(markTr('{0} herramientas')),
    'F_ERRORS_ONE': t(markTr('{0} error')),
    'F_ERRORS_N': t(markTr('{0} errores')),
    'F_TOKENS': t(markTr('{0} tokens')),
    'F_COST': t(markTr('{0} con la API')),
    'F_CONTEXT': t(markTr('contexto {0} %')),
    'F_STARTED': t(markTr('desde las {0}')),
    'F_PID': t(markTr('proceso {0}')),
    'F_REPORT': t(markTr('Último informe a las {0} ({1})')),
    'TOWER_CAPS': t(markTr('TORRE DE CONTROL')),
    'THIS_COMPUTER': t(markTr('Este equipo')),
    'H_OPEN_ONE': t(markTr('{0} sesión abierta')),
    'H_OPEN_N': t(markTr('{0} sesiones abiertas')),
    'H_WORK': t(markTr('{0} trabajando')),
    'H_ASK_ONE': t(markTr('{0} te pregunta')),
    'H_ASK': t(markTr('{0} te preguntan')),
    'H_WAIT_ONE': t(markTr('{0} te espera')),
    'H_WAIT': t(markTr('{0} te esperan')),
    'H_SUBS_ONE': t(markTr('{0} subagente')),
    'H_SUBS_N': t(markTr('{0} subagentes')),
    'H_REPORTS_ONE': t(markTr('{0} agente informa')),
    'H_REPORTS_N': t(markTr('{0} agentes informan')),
    'H_TASKS': t(markTr('{0} de {1} tareas')),
    'H_TOKENS': t(markTr('{0} tokens hoy ({1})')),
    'RING_TASKS': t(markTr('tareas hechas')),
    'RING_WORKING': t(markTr('trabajando')),
    'CLOSED_HEADER': t(markTr('CERRADAS')),
    'HOUR_AGO': t(markTr('hace 1 h')),
    'NOW_CAPS': t(markTr('ahora')),
    'SUBS_RUN_ONE': t(markTr('{0} SUBAGENTE')),
    'SUBS_RUN_N': t(markTr('{0} SUBAGENTES')),
    'SUBS_DONE_ONE': t(markTr('{0} SUBAGENTE, TERMINADO')),
    'SUBS_DONE_N': t(markTr('{0} SUBAGENTES, TERMINADOS')),
    'TESTING_ON': t(markTr('PROBANDO EN')),
    'PORT_CHIP': t(markTr('Puerto {0}')),
    'SEE_MORE': t(markTr('Ver más')),
    'SEE_LESS': t(markTr('Ver menos')),
    'DONE_N': t(markTr('HECHAS {0}')),
    'TODO_N': t(markTr('POR REALIZAR {0}')),
    'LAST_STEPS': t(markTr('ÚLTIMOS PASOS')),
    'FILES_N': t(markTr('ARCHIVOS QUE HA TOCADO {0}')),
    'SUBAGENTS_N': t(markTr('SUBAGENTES {0}')),
    'SUB_FINISHED': t(markTr('Terminó')),
    'B_VSCODE': t(markTr('Abrir en VS Code')),
    'B_FOLDER': t(markTr('Abrir la carpeta')),
    'B_RESUME': t(markTr('Copiar «claude --resume»')),
    'B_URL': t(markTr('Abrir la app')),
    'B_REMOVE': t(markTr('Quitar')),
    'R_BAD_JSON': t(markTr('El cuerpo no es un objeto JSON')),
    'R_NO_AGENT': t(markTr('Falta «agente»: el nombre corto del agente')),
    'SRV_NO_SOCKET': t(markTr('No se ha podido abrir el servidor de los agentes')),
    'SRV_BUSY': t(
      markTr('El puerto {0} está ocupado: los agentes no pueden informar'),
    ),
    'F_OPEN': fOpen,
    'F_DAY': fDay,
    'F_WEEK': fWeek,
    'S_ACTIVITY': sActivity,
    'S_STATE': sState,
    'S_PROJECT': sProject,
    'EMPTY_T': t(markTr('No hay sesiones de Claude Code abiertas')),
    'EMPTY_H': t(
      markTr(
        'Abra Claude Code en VS Code o en la terminal y aparecerá aquí al momento. Para ver también las que se cerraron, elija «Abiertas y de las últimas 24 h» o «De los últimos 7 días».',
      ),
    ),
    'EMPTY_SEARCH_T': t(markTr('Ninguna sesión coincide con la búsqueda')),
    'EMPTY_SEARCH_H': t(
      markTr(
        'Se busca en el proyecto, el título, la rama, el modelo, la carpeta y lo que hace ahora.',
      ),
    ),
    'EMPTY_NO_CLAUDE_T': t(markTr('Claude Code no está en este equipo')),
    'EMPTY_NO_CLAUDE_H': t(
      markTr(
        'No existe la carpeta {0}. Instale Claude Code (o su extensión de VS Code) y abra una sesión.',
      ),
    ),
    'READING': t(markTr('Leyendo las sesiones de Claude Code…')),
    'READING_HELP': t(
      markTr(
        'La primera vez se leen enteras; después, solo lo nuevo, cada dos segundos.',
      ),
    ),
    'STATUS_LINE': t(markTr('{0} · actualizado a las {1} · {2}')),
    'STATUS_SERVER': t(markTr('los agentes informan en {0}')),
    'STATUS_NO_SERVER': t(markTr('sin servidor para los agentes')),
    'REFRESHING': t(markTr('Actualizando…')),
    'OPENING_VSCODE': t(markTr('Abriendo {0} en VS Code…')),
    'COPIED': t(markTr('Copiado: {0}')),
    'MINIMIZE': t(markTr('Minimizar')),
    'BAR_TITLE': t(markTr('{0}/{1}')),
    'BAR_ASK': t(markTr('{0}/{1} · {2} ?')),
    'NO_OPEN': t(markTr('No hay sesiones abiertas')),
    'OPEN_WINDOW': t(markTr('Abrir la ventana…')),
    'REFRESH_NOW': t(markTr('Actualizar ahora')),
    'NOTIFY_ME': t(markTr('Avisarme al terminar')),
    'QUIT': t(markTr('Salir')),
    'N_DONE': t(markTr('{0} terminó: {1}')),
    'N_ASKS': t(markTr('{0} te pregunta: {1}')),
    'AGENTS_TITLE': t(markTr('Instrucciones para los agentes')),
    'AGENTS_HEAD': t(markTr('Conecta a Claude')),
    'AGENTS_NOTE': t(
      markTr(
        'Pega este texto en Claude Code junto con tu encargo. Cada agente aparecerá como una fila en cuanto envíe su primer informe; no hay que crearlos antes. Las sesiones de Claude Code se ven solas, sin esto.',
      ),
    ),
    'AGENTS_TEXT': t(
      markTr(
        'Informa de tu avance a la Torre de control de este equipo. Al empezar, cada vez que acabes una tarea y al terminar, envía un informe así (desde la terminal):\n\ncurl -s -X POST {0} -H \'Content-Type: application/json\' --data-binary @- <<\'JSON\'\n{"agente":"Checkout","rol":"Arregla el pago de la tienda","estado":"trabajando","tarea":"Revisando el pago con PayPal","url":"http://localhost:3000","hechas":["Localizar el checkout"],"pendientes":["Revisar PayPal","Escribir las pruebas"]}\nJSON\n\n- agente: nombre corto y siempre el mismo. Identifica la fila.\n- rol: para qué sirve ese agente, en pocas palabras.\n- estado: trabajando, esperando, bloqueado, terminado o error.\n- tarea: qué estás haciendo ahora, en una frase.\n- url: dónde estás probando la app, con su puerto. Envíala en cuanto arranques un servidor y actualízala si cambia. Si solo conoces el puerto, envía "puerto":3000.\n- hechas y pendientes: las listas completas en cada informe. El progreso se calcula con ellas.\n- progreso (opcional): de 0 a 100, solo si no hay lista de tareas.\n\nSi lanzas subagentes, pasa estas instrucciones a cada uno con un nombre distinto.\nEl servidor solo escucha en este equipo (127.0.0.1). No escribas contraseñas, claves ni datos de clientes en los informes.\nSi un informe falla, sigue con tu trabajo.',
      ),
    ),
    'COPY_AGENTS': t(markTr('Copiar instrucciones para Claude')),
    'COPIED_AGENTS': t(markTr('Copiadas ✓')),
    'CLOSE': t(markTr('Cerrar')),
    // Los datos de ejemplo de las capturas.
    'DEMO_HOST': t(markTr('Estudio de Ana')),
    'DEMO_A_TITLE': t(markTr('Arreglar el pago con PayPal en el checkout')),
    'DEMO_A_PROMPT': t(
      markTr('El pago con PayPal falla en el checkout: arréglalo y añade pruebas'),
    ),
    'DEMO_A_SAID': t(
      markTr('He corregido la firma del webhook; ahora paso las pruebas.'),
    ),
    'DEMO_T1': t(markTr('Localizar el checkout')),
    'DEMO_T2': t(markTr('Reproducir el error de PayPal')),
    'DEMO_T3': t(markTr('Corregir la firma del webhook')),
    'DEMO_T4': t(markTr('Escribir las pruebas del pago')),
    'DEMO_T5': t(markTr('Probar en el navegador')),
    'DEMO_T6': t(markTr('Subir a la rama')),
    'DEMO_S1': t(markTr('Pasa las pruebas')),
    'DEMO_S2': t(markTr('Pasa las pruebas del pago')),
    'DEMO_B_TITLE': t(markTr('Migrar los módulos de Odoo 14 a Odoo 20')),
    'DEMO_B_PROMPT': t(
      markTr('Porta los módulos a Odoo 20 con un subagente por grupo'),
    ),
    'DEMO_B_SAID': t(markTr('Los tres subagentes están portando sus módulos.')),
    'DEMO_S3': t(markTr('Inventario de los módulos')),
    'DEMO_S4': t(markTr('Instala el módulo en la base de prueba')),
    'DEMO_SUB1': t(markTr('Portar el módulo BIM principal')),
    'DEMO_SUB2': t(markTr('Portar la cadena del SII')),
    'DEMO_SUB3': t(markTr('Recrear las personalizaciones de Studio')),
    'DEMO_C_TITLE': t(markTr('Nueva portada de la web')),
    'DEMO_C_PROMPT': t(markTr('Rehaz la portada con el nuevo eslogan')),
    'DEMO_C_ASK': t(markTr('¿Uso la foto del equipo o la ilustración?')),
    'DEMO_D_TITLE': t(markTr('Reembolsos parciales en la API')),
    'DEMO_D_PROMPT': t(markTr('Añade reembolsos parciales a la API de pagos')),
    'DEMO_D_SAID': t(
      markTr(
        'Listo: reembolsos parciales con sus pruebas, subido a main. ¿Quieres que lo despliegue?',
      ),
    ),
    'DEMO_S5': t(markTr('Pasa las pruebas de la API')),
    'DEMO_E_TITLE': t(markTr('Modo oscuro en la app')),
    'DEMO_E_PROMPT': t(markTr('Añade el modo oscuro a la app')),
    'DEMO_R_AGENT': t(markTr('Traducciones')),
    'DEMO_R_ROLE': t(markTr('Traduce la tienda al inglés y al portugués')),
    'DEMO_R_TASK': t(markTr('Traduciendo las fichas de producto')),
    'DEMO_R_D1': t(markTr('Extraer los textos')),
    'DEMO_R_D2': t(markTr('Traducir el menú y el pie')),
    'DEMO_R_P1': t(markTr('Traducir las fichas de producto')),
    'DEMO_R_P2': t(markTr('Revisar los precios en reales')),
    'DEMO_R_P3': t(markTr('Probar el cambio de idioma')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const top = '#111114', board = '#18181b', light = '#d4d4d8';
  TkWidget lbl(String name, int x, int w, String text) =>
      _w('Label', name, x, 14, w, 28, {
        'text': text,
        'bg': top,
        'fg': light,
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
          width: 1280,
          height: 860,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': board,
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1220,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Cada segundo: los relojes de las filas.
          _w(
            'Timer',
            'Tick',
            1180,
            8,
            32,
            32,
            {'interval': 1000},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Top', 0, 0, 1280, 56, {'bg': top}),
          lbl('LblFilter', 12, 64, t(markTr('Mostrar'))),
          combo('Filter', 76, 252, [fOpen, fDay, fWeek], 1, 'Filter_select'),
          lbl('LblSort', 336, 80, t(markTr('Ordenar por'))),
          combo('Sort', 416, 150, [sActivity, sState, sProject], 0,
              'Sort_select'),
          lbl('LblSearch', 572, 56, t(markTr('Buscar'))),
          _w(
            'Entry',
            'Search',
            628,
            14,
            170,
            28,
            {'font_size': 14},
            {'enter_key': 'Search_enter'},
          )..parent = 'Top',
          _w(
            'Checkbutton',
            'Notify',
            812,
            14,
            186,
            28,
            {
              'text': t(markTr('Avisarme al terminar')),
              'bg': top,
              'fg': light,
              'checked': true,
            },
            {'command': 'Notify_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnAgents',
            1004,
            14,
            100,
            28,
            {
              'text': t(markTr('Agentes…')),
              'bg': '#9cc9ec',
              'fg': '#0b2236',
              'font_bold': true,
            },
            {'command': 'BtnAgents_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnBar',
            1112,
            14,
            156,
            28,
            {'text': t(markTr('A la barra de menús'))},
            {'command': 'BtnBar_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 56, 1280, 780, {'bg': board}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'BoardHint', 240, 360, 800, 40, {
            'text': t(
              markTr(
                'Las filas de las sesiones (el robot, la barra, el estado y el detalle) las dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#a1a1aa',
            'bg': board,
            'font_size': 14,
          })..parent = 'Board',
          _w('StatusBar', 'Status', 0, 836, 1280, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Torre de control de Claude Code en C++ con FLTK: todas las sesiones de Claude Code de este equipo, lo que hace cada una, sus tareas y subagentes, los informes de los agentes y la barra de menús.'))}
$_towerIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_towerCode''';
  return TkExample(
    'cpp_tower',
    t(markTr('Torre de control (C++)')),
    t(
      markTr(
        'Todas las sesiones de Claude Code del equipo en una torre de control nativa en C++ con FLTK: qué hace cada una ahora, si trabaja, espera o pregunta, sus tareas, subagentes y dónde prueba la app, los informes de avance de los agentes y la barra de menús con avisos.',
      ),
    ),
    design,
    code,
  );
}
