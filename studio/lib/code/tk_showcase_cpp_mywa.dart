part of 'tk_examples.dart';

// ------------------------------------------------ MyWhatsapp (C++)
/// Lee los chats de WhatsApp Desktop (su base de datos en el Mac, solo
/// lectura) o un chat exportado, y propone tres respuestas con la IA de
/// Claude (Anthropic) o de ChatGPT (OpenAI) según la conversación; la elegida
/// pasa al borrador.
TkExample tkCppMywa(String Function(String) t) {
  final app = t(markTr('MyWhatsapp'));
  final mFile = t(markTr('Archivo')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('RELOAD', t(markTr('Actualizar los chats')), mFile);
  item('IMPORT', t(markTr('Importar un chat exportado…')), mFile);
  item('AI', t(markTr('Claves de la IA…')), mFile);
  lines.add('  -');
  item('CONNECT', t(markTr('Conectar WhatsApp para enviar…')), mFile);
  item('DISCONNECT', t(markTr('Desconectar WhatsApp')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  final mView = t(markTr('Ver'));
  lines.add(mView);
  item('LIGHT', t(markTr('Tema claro')), mView);
  item('DARK', t(markTr('Tema oscuro')), mView);
  item('SYSTEM', t(markTr('Como el sistema')), mView);
  lines.add('  -');
  item('TASKS', t(markTr('Tareas')), mView);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de MyWhatsapp')), mHelp);
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'MyWhatsapp lee sus chats de WhatsApp Desktop (en el Mac, sin cambiar nada; la primera vez, macOS le pedirá permiso) o un chat exportado con «Exportar chat», y le propone respuestas con IA.\n\nElija un chat, si quiere escriba qué quiere decir y el estilo, y pulse «Sugerir respuestas». Claude (Anthropic) o ChatGPT (OpenAI) leen los últimos mensajes de ese chat y proponen tres respuestas. «Enviar» la manda, «Usar» la pasa al borrador para retocarla y «Copiar» la copia.\n\nPara enviar: escriba en el borrador y pulse «Enviar ➤» o Enter (Mayúsculas+Enter para otra línea); «📎 Adjuntar» manda un archivo.\n\nEn la conversación: la rueda sube a los mensajes antiguos (se cargan solos); arrastre sobre el texto para seleccionarlo y Cmd+C para copiarlo (doble clic: el mensaje entero); «🔍 Buscar» o Cmd+F busca en todo el chat, con ▲ ▼ (o Enter) para ir de uno a otro. El clic derecho sobre un mensaje lo copia o lo convierte en tarea.\n\n«🌐 Traducir», en la cabecera, chatea en otro idioma: debajo de cada mensaje recibido sale su traducción y, al enviar, lo que escribe se traduce al idioma del otro (detectado o elegido: el idioma de cada contacto queda guardado); en su bocadillo ve lo enviado y su original.\n\nTareas: «+ Tarea» en la cabecera de un chat (o clic derecho sobre un mensaje) crea una tarea enlazada a ese chat; la fila «Tareas», arriba de la lista, las enseña para marcarlas como hechas, volver a su chat o borrarlas. La bolita de cada pendiente dice cuánto lleva: verde (menos de 24 h), naranja (más de 24 h) o roja (más de 72 h). La primera vez elija cómo conectar WhatsApp: con la API oficial de WhatsApp Business (un número de empresa de Meta) o como dispositivo vinculado con un código QR, igual que WhatsApp Web (no es oficial: WhatsApp puede bloquear la cuenta).\n\nLas claves se guardan en el Llavero de macOS. Solo se envían a la IA los mensajes del chat abierto, y solo cuando lo pide.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, la lista, el panel de la IA y sus campos se diseñaron en el Diseñador del estudio; la base de datos de WhatsApp Desktop se lee con el SQLite del sistema y la IA se llama por su API HTTP con curl.',
      ),
    ),
    'ME': t(markTr('Yo')),
    'P_CLAUDE': t(markTr('Claude (Anthropic)')),
    'P_OPENAI': t(markTr('ChatGPT (OpenAI)')),
    'TONE_NATURAL': t(markTr('Natural')),
    'TONE_FORMAL': t(markTr('Formal')),
    'TONE_SHORT': t(markTr('Breve')),
    'TONE_WARM': t(markTr('Cariñoso')),
    'TONE_BUSINESS': t(markTr('Profesional (negocio)')),
    'PROMPT_SYSTEM': t(
      markTr(
        'Eres el asistente de respuestas de MyWhatsapp. Lees una conversación de WhatsApp y propones respuestas para que el usuario («Yo») las envíe tal cual, en su nombre.\n\nEscribe exactamente tres respuestas distintas entre sí, separadas por una línea que solo tenga «---». Sin numerarlas, sin comillas y sin explicar nada. En el idioma de la conversación y con el estilo de un mensaje de WhatsApp (corto, natural, emojis solo si encajan). Tono: {0}. Responde a lo último que quedó pendiente y no inventes datos (horas, precios, direcciones) que no estén en la conversación o en lo que el usuario quiere decir.',
      ),
    ),
    'PROMPT_ABOUT': t(markTr('Sobre el usuario: {0}')),
    'PROMPT_USER': t(markTr('Conversación con {0}:\n\n{1}')),
    'PROMPT_INTENT': t(markTr('Lo que el usuario quiere decir: {0}')),
    'PICK_CHAT': t(markTr('Elija un chat')),
    'PICK_CHAT_HELP': t(
      markTr(
        'A la izquierda están sus chats de WhatsApp Desktop. Elija uno y pulse «Sugerir respuestas».',
      ),
    ),
    'NO_DESKTOP_HELP': t(
      markTr(
        'No encuentro WhatsApp Desktop en este equipo. Conecte WhatsApp (Archivo › Conectar WhatsApp para enviar…) para ver y enviar mensajes, o abra un chat exportado (Archivo › Importar un chat exportado…).',
      ),
    ),
    'PERMISSION_HELP': t(
      markTr(
        'macOS pide permiso para leer los datos de WhatsApp: acéptelo, o dé acceso en Ajustes del Sistema › Privacidad y seguridad. También puede importar un chat exportado.',
      ),
    ),
    'ERR_NO_DB': t(markTr('Aquí no se puede leer WhatsApp Desktop')),
    'ERR_NO_SQLITE': t(markTr('No encuentro SQLite en el sistema')),
    'ERR_OPEN_DB': t(markTr('No se pudo abrir la base de datos de WhatsApp')),
    'ERR_READ_DB': t(markTr('No se pudo leer la base de datos de WhatsApp')),
    'ERR_NO_CURL': t(markTr('No encuentro curl')),
    'ERR_AI_NETWORK': t(markTr('No hay conexión con la IA')),
    'ERR_AI_ANSWER': t(markTr('La IA no devolvió respuestas')),
    'ERR_AI_KEY': t(markTr('La clave de la IA no es válida (Archivo › Claves de la IA…)')),
    'ERR_AI_NO_KEY': t(markTr('Falta la clave de la IA (Archivo › Claves de la IA…)')),
    'ERR_AI_REFUSAL': t(markTr('La IA prefirió no proponer respuestas para esta conversación')),
    'SUGGESTIONS': t(markTr('RESPUESTAS PROPUESTAS')),
    'K_PHOTO': t(markTr('Foto')),
    'K_STICKER': t(markTr('Sticker')),
    'K_VIDEO': t(markTr('Vídeo')),
    'K_AUDIO': t(markTr('Nota de voz')),
    'K_DOC': t(markTr('Documento')),
    'NOT_DOWNLOADED': t(markTr('sin descargar en este equipo')),
    'GROUP': t(markTr('Grupo')),
    'DEMO_PHOTO_CAPTION': t(markTr('Así quedó, ¿te gusta?')),
    'DEMO_DOC': t(markTr('Presupuesto cocina.pdf')),
    'USE': t(markTr('Usar')),
    'COPY': t(markTr('Copiar')),
    'THINKING': t(markTr('✨ {0} está escribiendo tres respuestas…')),
    'COPIED': t(markTr('Copiada')),
    'PRIVACY': t(
      markTr(
        'Para proponer respuestas, los últimos mensajes de este chat se envían a {0}. Solo se hace al pulsar «Sugerir respuestas» y solo con el chat abierto. ¿Continuar?',
      ),
    ),
    'BTN_OK': t(markTr('Continuar')),
    'BTN_CANCEL': t(markTr('Cancelar')),
    'ASK_CLAUDE_KEY': t(
      markTr(
        'Clave de la API de Claude (Anthropic), de console.anthropic.com (déjela vacía para no cambiarla):',
      ),
    ),
    'ASK_OPENAI_KEY': t(
      markTr(
        'Clave de la API de OpenAI (ChatGPT), de platform.openai.com (déjela vacía para no cambiarla):',
      ),
    ),
    'ASK_OPENAI_MODEL': t(markTr('Modelo de OpenAI:')),
    'ASK_ABOUT': t(
      markTr(
        'Sobre usted, para que las respuestas encajen (opcional; por ejemplo: «Tengo una tienda de muebles en Madrid»):',
      ),
    ),
    'IMPORT_TITLE': t(markTr('Abrir un chat exportado de WhatsApp')),
    'IMPORT_EMPTY': t(markTr('Ese archivo no parece un chat exportado de WhatsApp')),
    'IMPORTED': t(markTr('Importado: {0} ({1} mensajes)')),
    'SOURCE_DESKTOP': t(markTr('WhatsApp Desktop')),
    'SOURCE_EXPORT': t(markTr('chats importados')),
    'STATUS': t(markTr('{0} chats de {1} · IA: {2} · Envío: {3}')),
    'SOURCE_LINKED': t(markTr('WhatsApp vinculado')),
    'MODE_NONE': t(markTr('sin conectar')),
    'MODE_CLOUD': t(markTr('API oficial')),
    'MODE_LINKED': t(markTr('vinculado (QR)')),
    'MODE_LINKING': t(markTr('conectando…')),
    'SEND': t(markTr('Enviar')),
    'SENDING': t(markTr('Enviando…')),
    'SENT': t(markTr('Enviado ✓')),
    'EMPTY_DRAFT': t(markTr('Escriba el mensaje en el borrador')),
    'ATTACH_TITLE': t(markTr('Elegir el archivo para enviar')),
    'ERR_SEND': t(markTr('No se pudo enviar el mensaje')),
    'ERR_SEND_WHY': t(markTr('No se pudo enviar: {0}')),
    'ERR_NO_JID': t(markTr('Este chat es importado: no tiene número al que enviar')),
    'ERR_CLOUD_GROUP': t(markTr('La API oficial no envía a grupos; use el modo vinculado (QR)')),
    'ERR_CLOUD_SETUP': t(markTr('Falta el número o el token de la API oficial (Archivo › Conectar WhatsApp para enviar…)')),
    'ERR_CLOUD_TOKEN': t(markTr('El token de la API de WhatsApp no es válido o caducó')),
    'ERR_SEND_NETWORK': t(markTr('No hay conexión con WhatsApp')),
    'ERR_NO_BRIDGE': t(markTr('Falta el puente de WhatsApp (wabridge) junto a la app')),
    'NOT_LINKED': t(markTr('WhatsApp aún no está vinculado: lea el código QR con el teléfono')),
    'CONNECTING': t(markTr('Conectando con WhatsApp…')),
    'LINKED': t(markTr('WhatsApp vinculado: ya puede enviar y recibir')),
    'LOGGED_OUT': t(markTr('WhatsApp desvinculado')),
    'BRIDGE_STOPPED': t(markTr('Se cerró la conexión con WhatsApp')),
    'CLOUD_READY': t(markTr('Listo: se envía con la API oficial de WhatsApp Business')),
    'CONNECT_ASK': t(
      markTr(
        '¿Cómo quiere conectar WhatsApp para enviar?\n\n• API oficial de WhatsApp Business: la de Meta, con un número de empresa (developers.facebook.com). Segura y permitida, pero solo para chats individuales y con las reglas de Meta.\n\n• Dispositivo vinculado (QR): su WhatsApp de siempre, como WhatsApp Web. Envía y recibe en todos los chats y grupos, pero no es oficial.',
      ),
    ),
    'CONNECT_CLOUD': t(markTr('API oficial')),
    'CONNECT_QR': t(markTr('Vincular con QR')),
    'QR_RISK': t(
      markTr(
        'Atención: el modo vinculado usa el protocolo de WhatsApp Web sin ser una app oficial. Va contra las condiciones de WhatsApp y la cuenta puede quedar bloqueada (temporal o definitivamente). Úselo bajo su responsabilidad y, si puede, con un número que no sea el principal.\n\nLa sesión se guarda solo en este equipo. ¿Vincular de todos modos?',
      ),
    ),
    'QR_ACCEPT': t(markTr('Entiendo el riesgo')),
    'QR_TITLE': t(markTr('Vincular WhatsApp')),
    'QR_HELP': t(
      markTr(
        'En el teléfono: WhatsApp › Ajustes › Dispositivos vinculados › Vincular un dispositivo, y apunte la cámara a este código.',
      ),
    ),
    'ASK_CLOUD_PHONE': t(
      markTr(
        'Identificador del número de teléfono (Phone number ID) de la API de WhatsApp Business, en developers.facebook.com › su app › WhatsApp › Configuración de la API:',
      ),
    ),
    'ASK_CLOUD_TOKEN': t(markTr('Token de acceso de la API de WhatsApp (déjelo vacío para no cambiarlo):')),
    'DISCONNECT_ASK': t(markTr('¿Desconectar WhatsApp de MyWhatsapp? Para volver a enviar tendrá que conectarlo otra vez.')),
    'BTN_DISCONNECT': t(markTr('Desconectar')),
    'TASKS_TITLE': t(markTr('Tareas')),
    'TASKS_PENDING': t(markTr('{0} pendientes')),
    'TASKS_DONE_N': t(markTr('hechas: {0}')),
    'TASKS_EMPTY': t(
      markTr(
        'No hay tareas. Cree una desde un chat con «+ Tarea» o con clic derecho sobre un mensaje.',
      ),
    ),
    'ADD_TASK': t(markTr('+ Tarea')),
    'NEW_TASK': t(markTr('+ Nueva tarea')),
    'ASK_TASK': t(markTr('La tarea:')),
    'TASK_ADDED': t(markTr('Tarea creada: {0}')),
    'TASK_FROM': t(markTr('de {0} · {1}')),
    'TASK_NO_CHAT': t(markTr('Ese chat ya no está en la lista')),
    'OPEN_CHAT': t(markTr('Abrir el chat')),
    'DELETE': t(markTr('Borrar')),
    'DEMO_T1': t(markTr('Confirmar a Laura la entrega del sábado')),
    'DEMO_T2': t(markTr('Mandar a Carlos el presupuesto de la cocina')),
    'DEMO_T3': t(markTr('Recoger a la abuela el domingo a las 13')),
    'DEMO_T4': t(markTr('Llevar el balón al partido del viernes')),
    'FIND': t(markTr('🔍 Buscar')),
    'LOCAL_TIME': t(markTr('{0} hora local')),
    'F_ALL': t(markTr('Todos')),
    'F_TASKS': t(markTr('Con tareas')),
    'F_TODO': t(markTr('Por responder (3 días)')),
    'F_WAITING': t(markTr('Sin respuesta')),
    'ARCHIVED': t(markTr('Archivados')),
    'DOWNLOAD': t(markTr('⬇ Descargar')),
    'OPEN_EXTERNAL': t(markTr('Abrir con su programa')),
    'NO_PREVIEW': t(markTr('No se puede enseñar esta imagen')),
    'DOWNLOAD_TITLE': t(markTr('Guardar una copia')),
    'DOWNLOADED': t(markTr('Guardada: {0}')),
    'DOWNLOAD_FAILED': t(markTr('No se pudo guardar la copia')),
    'TRANSLATE': t(markTr('🌐 Traducir')),
    'TRANS_OFF': t(markTr('No traducir')),
    'TRANS_AUTO': t(markTr('Detectar el idioma')),
    'TRANS_ORIGINAL': t(markTr('Original:')),
    'TRANSLATING': t(markTr('Traduciendo…')),
    'LANG_DETECTING': t(markTr('detectando…')),
    'LANG_DETECTED': t(markTr('{0} (detectado)')),
    'ERR_NO_LANG': t(markTr('Aún no sé en qué idioma escribe: elija el idioma en «🌐 Traducir»')),
    'PRIVACY_TRANSLATE': t(
      markTr(
        'Para traducir, los mensajes de este chat y lo que escriba en él se envían a {0}. ¿Continuar?',
      ),
    ),
    // El idioma de la app, para la IA (en inglés: «English»).
    'MY_LANGUAGE': t(markTr('el español')),
    'LANG_EN': t(markTr('inglés')),
    'LANG_ES': t(markTr('castellano')),
    'LANG_PT': t(markTr('portugués')),
    'LANG_FR': t(markTr('francés')),
    'LANG_IT': t(markTr('italiano')),
    'LANG_DE': t(markTr('alemán')),
    'LANG_ZH': t(markTr('chino')),
    'LANG_AR': t(markTr('árabe')),
    'LANG_RU': t(markTr('ruso')),
    'PROMPT_TRANSLATE': t(
      markTr(
        'Eres el traductor de MyWhatsapp. Te dan una lista JSON de mensajes de WhatsApp: tradúcelos al idioma de destino, con naturalidad y el mismo tono (los emojis, igual). Responde solo con JSON, sin nada más: {"language": "el nombre del idioma en que están escritos, dicho en el idioma de destino", "items": ["la traducción del primero", "…"]}, una traducción por mensaje y en el mismo orden. Si un mensaje ya está en el idioma de destino, déjalo igual. Idioma de destino: {0}.',
      ),
    ),
    'PROMPT_TRANSLATE_OUT': t(
      markTr(
        'Eres el traductor de MyWhatsapp. Traduce el mensaje que te dan al idioma de destino, con naturalidad, como lo escribiría en WhatsApp alguien que lo habla, con el mismo tono y los mismos emojis. Responde solo con la traducción, sin comillas ni explicaciones. Idioma de destino: {0}.',
      ),
    ),
    'DEMO_I1': t(markTr('¡Hola! He visto vuestra mesa de roble en la web. ¿Sigue disponible?')),
    'DEMO_I2': t(markTr('¡Sí, está disponible! Podemos enviarla a Roma en una semana.')),
    'DEMO_I3': t(markTr('Perfecto. ¿Cuánto cuesta el envío? 🙂')),
    'FIND_NONE': t(markTr('Sin resultados')),
    'FIND_COUNT': t(markTr('{0} de {1}')),
    'COPY_SELECTION': t(markTr('Copiar la selección')),
    'COPY_MESSAGE': t(markTr('Copiar el mensaje')),
    'MAKE_TASK': t(markTr('Convertir en tarea')),
    'DEMO_LAURA': t(markTr('Laura (Muebles Sol)')),
    'DEMO_L1': t(markTr('Hola! Ya tenemos la mesa de roble que pediste 😊')),
    'DEMO_L2': t(markTr('Genial, ¿cuándo me la podéis llevar?')),
    'DEMO_L3': t(markTr('Podemos el jueves por la mañana o el sábado de 10 a 14')),
    'DEMO_L4': t(markTr('¿Qué te viene mejor? Y confírmame la dirección, porfa')),
    'DEMO_GROUP': t(markTr('Familia 🏡')),
    'DEMO_ANA': t(markTr('Ana')),
    'DEMO_PEDRO': t(markTr('Pedro')),
    'DEMO_G1': t(markTr('¿Comemos el domingo en casa de los abuelos?')),
    'DEMO_G2': t(markTr('Yo llevo el postre 🍰')),
    'DEMO_G3': t(markTr('Me apunto!')),
    'DEMO_G4': t(markTr('¿Quién puede recoger a la abuela a las 13?')),
    'DEMO_CLIENT': t(markTr('Carlos · cliente')),
    'DEMO_C1': t(markTr('Buenas, ¿tenéis el presupuesto de la cocina?')),
    'DEMO_C2': t(markTr('Lo terminamos hoy y se lo envío')),
    'DEMO_C3': t(markTr('Perfecto, gracias. ¿Incluye la instalación?')),
    'DEMO_MOM': t(markTr('Mamá')),
    'DEMO_M1': t(markTr('¿Llegaste bien?')),
    'DEMO_M2': t(markTr('Sí! Ya en casa ❤️')),
    'DEMO_JAVI': t(markTr('Javi')),
    'DEMO_J1': t(markTr('¿Partido el viernes?')),
    'DEMO_J2': t(markTr('Hecho, a las 8 en el polideportivo')),
    'DEMO_INTENT': t(markTr('el sábado, y la dirección es calle Mayor 12')),
    'DEMO_S1': t(markTr('¡Qué bien! 😊 Mejor el sábado entre las 10 y las 14. La dirección es calle Mayor 12. ¡Gracias!')),
    'DEMO_S2': t(markTr('El sábado me va perfecto. Os espero en calle Mayor 12, de 10 a 14.')),
    'DEMO_S3': t(markTr('Sábado, por favor 🙌 Calle Mayor 12. Avisadme un poco antes de llegar.')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const panel = '#f0f2f5';
  TkWidget lbl(String name, int x, int y, int w, String text) =>
      _w('Label', name, x, y, w, 28, {
        'text': text,
        'bg': panel,
        'fg': '#41525d',
        'font_size': 13,
      })..parent = 'AiBar';
  final design =
      TkDesign(
          width: 1200,
          height: 760,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': panel,
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
          // Cada pocos segundos: los mensajes nuevos de WhatsApp Desktop.
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
          _w('Frame', 'Side', 0, 0, 360, 736, {'bg': '#ffffff'}),
          _w('Entry', 'Search', 12, 12, 336, 30, {'font_size': 14})
            ..parent = 'Side',
          _w('Label', 'ListHint', 20, 300, 320, 60, {
            'text': t(markTr('La lista de chats la dibuja el código')),
            'fg': '#667781',
            'bg': '#ffffff',
          })..parent = 'Side',
          _w('Frame', 'ChatArea', 360, 0, 840, 560, {'bg': '#efeae2'}),
          _w('Label', 'ChatHint', 120, 250, 600, 40, {
            'text': t(
              markTr(
                'La conversación y las respuestas de la IA las dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#667781',
            'bg': '#efeae2',
            'font_size': 14,
          })..parent = 'ChatArea',
          _w('Frame', 'AiBar', 360, 560, 840, 176, {'bg': panel}),
          lbl('LblProvider', 12, 12, 30, t(markTr('IA'))),
          _w(
            'Combobox',
            'Provider',
            44,
            12,
            190,
            28,
            {},
            {'select': 'Provider_select'},
          )..parent = 'AiBar',
          lbl('LblTone', 238, 12, 52, t(markTr('Estilo'))),
          _w('Combobox', 'Tone', 290, 12, 170, 28, {})..parent = 'AiBar',
          _w(
            'Button',
            'BtnSuggest',
            480,
            8,
            340,
            34,
            {
              'text': t(markTr('✨ Sugerir respuestas')),
              'bg': '#25d366',
              'fg': '#ffffff',
              'font_bold': true,
              'font_size': 15,
            },
            {'command': 'BtnSuggest_click'},
          )..parent = 'AiBar',
          lbl('LblIntent', 12, 52, 140, t(markTr('Qué quiere decir'))),
          _w(
            'Entry',
            'Intent',
            152,
            52,
            668,
            28,
            {'font_size': 13},
            {'enter_key': 'Intent_enter'},
          )..parent = 'AiBar',
          _w('Text', 'Draft', 12, 90, 686, 76, {'font_size': 14})
            ..parent = 'AiBar',
          // Enter en el borrador también envía (Mayúsculas+Enter: otra línea).
          _w(
            'Button',
            'BtnSend',
            708,
            90,
            120,
            40,
            {
              'text': t(markTr('Enviar ➤')),
              'bg': '#25d366',
              'fg': '#ffffff',
              'font_bold': true,
              'font_size': 15,
            },
            {'command': 'BtnSend_click'},
          )..parent = 'AiBar',
          _w(
            'Button',
            'BtnAttach',
            708,
            136,
            120,
            30,
            {'text': t(markTr('📎 Adjuntar')), 'font_size': 13},
            {'command': 'BtnAttach_click'},
          )..parent = 'AiBar',
          _w('StatusBar', 'Status', 0, 736, 1200, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('MyWhatsapp en C++ con FLTK: lee sus chats de WhatsApp y propone respuestas con la IA de Claude o de ChatGPT según la conversación.'))}
$_mywaIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_mywaCode''';
  return TkExample(
    'cpp_mywa',
    t(markTr('MyWhatsapp (C++)')),
    t(
      markTr(
        'Lee sus chats de WhatsApp Desktop (o uno exportado) y propone tres respuestas con la IA de Claude o de ChatGPT según la conversación y el estilo que elija.',
      ),
    ),
    design,
    code,
  );
}
