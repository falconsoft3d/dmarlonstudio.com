part of 'tk_examples.dart';

// ------------------------------------------------ MyWhatsapp (C++)
/// Lee los chats de WhatsApp Desktop (su base de datos en el Mac, solo
/// lectura) o un chat exportado, y propone tres respuestas con la IA de
/// Claude (Anthropic) o de ChatGPT (OpenAI) según la conversación; la elegida
/// se abre en WhatsApp ya escrita, para revisarla y enviarla.
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
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de MyWhatsapp')), mHelp);
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'MyWhatsapp lee sus chats de WhatsApp Desktop (en el Mac, sin cambiar nada; la primera vez, macOS le pedirá permiso) o un chat exportado con «Exportar chat», y le propone respuestas con IA.\n\nElija un chat, si quiere escriba qué quiere decir y el tono, y pulse «Sugerir respuestas». Claude (Anthropic) o ChatGPT (OpenAI) leen los últimos mensajes de ese chat y proponen tres respuestas. «Usar» la pasa al borrador; «Abrir en WhatsApp» abre WhatsApp con el texto escrito: lo revisa y lo envía usted.\n\nLas claves de la IA se guardan en el Llavero de macOS. Solo se envían a la IA los mensajes del chat abierto, y solo cuando lo pide.',
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
        'No encuentro WhatsApp Desktop en este equipo. Abra un chat exportado (Archivo › Importar un chat exportado…): en el teléfono, en el chat, «Exportar chat» sin archivos.',
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
    'USE': t(markTr('Usar')),
    'COPY': t(markTr('Copiar')),
    'SEND_WA': t(markTr('Abrir en WhatsApp')),
    'THINKING': t(markTr('✨ {0} está escribiendo tres respuestas…')),
    'COPIED': t(markTr('Copiada')),
    'GROUP_COPIED': t(
      markTr(
        'Es un grupo: la respuesta está copiada; péguela en WhatsApp',
      ),
    ),
    'OPENED_WA': t(markTr('WhatsApp abierto con la respuesta: revísela y envíela')),
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
    'STATUS': t(markTr('{0} chats de {1} · IA: {2}')),
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
          _w('Text', 'Draft', 12, 90, 640, 76, {'font_size': 14})
            ..parent = 'AiBar',
          _w(
            'Button',
            'BtnSend',
            664,
            90,
            156,
            34,
            {
              'text': t(markTr('Abrir en WhatsApp')),
              'bg': '#ffffff',
              'fg': '#0a7c45',
              'font_bold': true,
            },
            {'command': 'BtnSend_click'},
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
        'Lee sus chats de WhatsApp Desktop (o uno exportado) y propone tres respuestas con la IA de Claude o de ChatGPT según la conversación y el tono que elija; la elegida se abre en WhatsApp ya escrita, para revisarla y enviarla.',
      ),
    ),
    design,
    code,
  );
}
