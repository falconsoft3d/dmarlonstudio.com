part of 'tk_examples.dart';

// ------------------------------------------------ MiniLang (C++)
/// Aprender idiomas con juegos cortos, en C++17 con FLTK: elegir la
/// traducción, ordenar las palabras, unir parejas, escribir y escuchar, con
/// vidas, experiencia, meta diaria, racha y repaso espaciado. Los idiomas son
/// paquetes (.json) que se instalan; el curso de inglés va de A1 a C1. Vive
/// en la barra de menús de macOS con la racha y la lección siguiente.
TkExample tkCppMiniLang(String Function(String) t) {
  final app = t(markTr('MiniLang'));
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
  item('LESSON', t(markTr('Lección siguiente')), mFile);
  item('REVIEW', t(markTr('Repaso')), mFile);
  item('TEST', t(markTr('Prueba de nivel…')), mFile);
  lines.add('  -');
  item('PACKS', t(markTr('Idiomas…')), mFile);
  item('IMPORT', t(markTr('Importar un paquete…')), mFile);
  lines.add('  -');
  item('BAR', t(markTr('Esconder en la barra de menús')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mView);
  item('GOAL_10', t(markTr('Meta diaria: 10 XP (tranquila)')), mView);
  item('GOAL_20', t(markTr('Meta diaria: 20 XP (normal)')), mView);
  item('GOAL_30', t(markTr('Meta diaria: 30 XP (seria)')), mView);
  item('GOAL_50', t(markTr('Meta diaria: 50 XP (intensa)')), mView);
  lines.add('  -');
  item('VOICE', t(markTr('Leer las frases en voz alta')), mView);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de MiniLang')), mHelp);
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'MiniLang te enseña un idioma con juegos de unos minutos. Cada unidad tiene tres lecciones de diez juegos: elegir la traducción (también con las teclas 1 a 4), ordenar las palabras, unir parejas, escribir la frase y escuchar y escribir (con la voz del Mac). Enter comprueba y sigue.\n\nSi fallas, pierdes una vida y ese juego vuelve al final de la lección; las vidas vuelven solas (una cada media hora) y el repaso te devuelve una. Cada lección da 10 XP (15 sin fallos) y suma a tu meta del día y a tu racha de días seguidos. Lo que aprendes se repasa cuando toca: cuanto mejor te lo sabes, más tarda en volver.\n\nEl curso de inglés va de A1 (principiante) a C1 (avanzado); la prueba de nivel te deja saltar las unidades que ya sabes. Los idiomas son paquetes: en Archivo › Idiomas… instala francés, italiano, alemán o portugués, o importa un paquete .json hecho por otros.\n\nAl cerrar la ventana, MiniLang se queda en la barra de menús con tu racha y lo que te falta para la meta; su menú abre la lección siguiente o un repaso rápido.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, el menú, el campo para escribir y el botón de comprobar se diseñaron en el Diseñador del estudio; los juegos, el progreso y los paquetes de idiomas están en el código de Form1.cpp. La voz es la del sistema (say, en macOS).',
      ),
    ),
    'L_EN': t(markTr('Inglés')),
    'L_ES': t(markTr('Español')),
    'L_FR': t(markTr('Francés')),
    'L_IT': t(markTr('Italiano')),
    'L_DE': t(markTr('Alemán')),
    'L_PT': t(markTr('Portugués')),
    'SEC_A1': t(markTr('Principiante')),
    'SEC_A2': t(markTr('Elemental')),
    'SEC_B1': t(markTr('Intermedio')),
    'SEC_B2': t(markTr('Intermedio alto')),
    'SEC_C1': t(markTr('Avanzado')),
    'UNIT_N': t(markTr('Unidad {0}')),
    'UNIT_TITLE': t(markTr('{0}. {1}')),
    'UNITS_RANGE': t(markTr('Unidades {0}–{1}')),
    'UNIT_DONE': t(markTr('Completada · {0} frases')),
    'UNIT_LESSON': t(markTr('Lección {0} de {1}')),
    'UNIT_LOCKED': t(markTr('Termina la unidad anterior para abrirla')),
    'START': t(markTr('Empezar')),
    'CONTINUE_UNIT': t(markTr('Continuar')),
    'PRACTICE': t(markTr('Practicar')),
    'BACK': t(markTr('← Volver')),
    'DAILY_GOAL': t(markTr('Meta diaria')),
    'GOAL_LEFT': t(markTr('Te faltan {0} XP para la meta de hoy')),
    'GOAL_DONE': t(markTr('¡Meta de hoy cumplida! Vuelve mañana para seguir la racha')),
    'GOAL_SET': t(markTr('Meta diaria: {0} XP')),
    'STREAK_ONE': t(markTr('🔥 Racha: 1 día')),
    'STREAK_N': t(markTr('🔥 Racha: {0} días')),
    'WD_1': t(markTr('L')),
    'WD_2': t(markTr('M')),
    'WD_3': t(markTr('X')),
    'WD_4': t(markTr('J')),
    'WD_5': t(markTr('V')),
    'WD_6': t(markTr('S')),
    'WD_7': t(markTr('D')),
    'REVIEW_TITLE': t(markTr('Repaso')),
    'REVIEW_NONE': t(markTr('Haz tu primera lección y aquí tendrás tu repaso')),
    'REVIEW_DUE': t(markTr('{0} frases por repasar hoy')),
    'REVIEW_OK': t(markTr('Al día: repasa igual para reforzar')),
    'REVIEW_BTN': t(markTr('Repasar')),
    'YOUR_LEVEL': t(markTr('Tu nivel')),
    'TEST_BTN': t(markTr('Prueba de nivel')),
    'TEST_Q': t(
      markTr(
        'La prueba de nivel te pregunta dos frases de cada unidad, de la más fácil a la más difícil, y se para en el primer fallo: las unidades que superes quedan hechas. ¿Empezar?',
      ),
    ),
    'TOTALS': t(markTr('XP total: {0} · {1} frases aprendidas')),
    'I_CHOOSE': t(markTr('Elige la traducción correcta')),
    'I_CHOOSE_REV': t(markTr('¿Qué significa esta frase?')),
    'I_BUILD': t(markTr('Traduce esta frase')),
    'I_MATCH': t(markTr('Une las parejas')),
    'I_TYPE': t(markTr('Escribe la traducción')),
    'I_LISTEN': t(markTr('Escucha y escribe lo que oyes')),
    'LISTEN_BTN': t(markTr('🔊 Escuchar')),
    'SLOW_BTN': t(markTr('🐢 Más despacio')),
    'TYPE_HINT': t(markTr('Escribe la respuesta en {0} y pulsa Enter')),
    'RETRY_TAG': t(markTr('↻ Otra vez: lo fallaste antes')),
    'TAG_REVIEW': t(markTr('🔁 Repaso')),
    'TAG_TEST': t(markTr('🎯 Prueba de nivel')),
    'CHECK': t(markTr('Comprobar')),
    'CONTINUE': t(markTr('Continuar')),
    'PICK_ONE': t(markTr('Elige una respuesta')),
    'PICK_WORDS': t(markTr('Toca las palabras en orden')),
    'TYPE_SOMETHING': t(markTr('Escribe tu respuesta')),
    'FB_GOOD': t(markTr('¡Muy bien!')),
    'FB_OTHER': t(markTr('También se dice: {0}')),
    'FB_TYPO': t(markTr('¡Casi! Fíjate en cómo se escribe:')),
    'FB_ACCENT': t(markTr('¡Bien! Ojo con los acentos:')),
    'FB_WRONG': t(markTr('Solución correcta:')),
    'FB_MATCH_ERR': t(markTr('¡Hecho! Con algún fallo, pero hecho')),
    'QUIT_Q': t(markTr('¿Salir de la lección? Perderás lo que llevas.')),
    'NO_HEARTS': t(
      markTr(
        'Te has quedado sin vidas: vuelve una en {0} min. Mientras, haz un repaso (no gasta vidas y te devuelve una).',
      ),
    ),
    'R_LESSON': t(markTr('¡Lección completada!')),
    'R_LESSON_SUB': t(markTr('{0} · lección {1} de {2}')),
    'R_REVIEW': t(markTr('¡Repaso hecho!')),
    'R_REVIEW_SUB': t(markTr('Has reforzado lo aprendido y recuperado una vida')),
    'R_TEST': t(markTr('Prueba de nivel terminada')),
    'R_TEST_SUB': t(markTr('Empiezas en la unidad {0}: {1} ({2})')),
    'R_TEST_ALL': t(markTr('¡Lo sabes todo! Has superado todas las unidades')),
    'R_NO_HEARTS': t(markTr('Te has quedado sin vidas')),
    'R_NO_HEARTS_SUB': t(markTr('Vuelve una en {0} min; un repaso te devuelve una ya')),
    'R_XP': t(markTr('XP')),
    'R_ACCURACY': t(markTr('Precisión')),
    'R_TIME': t(markTr('Tiempo')),
    'R_GOAL': t(markTr('⭐ ¡Meta diaria cumplida!')),
    'PACKS_TITLE': t(markTr('Idiomas')),
    'PACKS_HELP': t(
      markTr(
        'Cada idioma es un paquete: instálalo y elige cuál estudiar. Tu progreso se guarda aparte en cada uno.',
      ),
    ),
    'IMPORT_BTN': t(markTr('Importar un paquete…')),
    'IMPORT_TITLE': t(markTr('Importar un paquete de MiniLang')),
    'PACK_FULL': t(markTr('Curso completo, de A1 a C1: {0} unidades, {1} frases')),
    'PACK_STARTER': t(markTr('Primeros pasos: {0} unidades, {1} frases')),
    'PACK_IMPORTED': t(markTr('Importado: {0} unidades, {1} frases')),
    'STUDYING': t(markTr('✓ Estudiando')),
    'STUDY_BTN': t(markTr('Estudiar')),
    'INSTALL_BTN': t(markTr('⬇ Instalar')),
    'REMOVE_BTN': t(markTr('Quitar')),
    'INSTALLED': t(markTr('{0}: instalado')),
    'NOW_STUDYING': t(markTr('Ahora estudias: {0}')),
    'KEEP_ONE': t(markTr('Deja al menos un idioma instalado')),
    'REMOVE_Q': t(markTr('¿Quitar «{0}»? Tu progreso se guarda por si lo vuelves a instalar.')),
    'REMOVED': t(markTr('Idioma quitado')),
    'REPLACE_Q': t(markTr('Ya tienes «{0}». ¿Cambiarlo por este paquete?')),
    'IMPORTED': t(markTr('{0}: importado, con {1} frases')),
    'IMPORT_ERR': t(markTr('No se pudo importar: {0}')),
    'ERR_PACK_FORMAT': t(markTr('el archivo no es un paquete de MiniLang')),
    'ERR_PACK_LANG': t(markTr('los idiomas del paquete no son válidos')),
    'ERR_PACK_EMPTY': t(markTr('el paquete no tiene unidades con al menos tres frases')),
    'STATUS_UNIT': t(markTr('Unidad {0} de {1}: {2}')),
    'STATUS_DONE': t(markTr('Curso terminado')),
    'BAR_CONTINUE': t(markTr('▶ Seguir: {0}')),
    'BAR_ALL_DONE': t(markTr('Curso terminado')),
    'BAR_REVIEW': t(markTr('🔁 Repaso rápido')),
    'BAR_REVIEW_N': t(markTr('🔁 Repaso rápido ({0} por repasar)')),
    'BAR_STATUS': t(markTr('Racha: {0} días · hoy {1}/{2} XP')),
    'BAR_HEARTS': t(markTr('Vidas: {0} de 5')),
    'BAR_OPEN': t(markTr('Abrir MiniLang')),
    'BAR_QUIT': t(markTr('Salir')),
    'VOICE_ON': t(markTr('Las frases se leerán en voz alta')),
    'VOICE_OFF': t(markTr('Sin voz: los juegos de escuchar pasan a escribir')),
    'VOICE_NONE': t(markTr('Este equipo no tiene voz del sistema: los juegos de escuchar pasan a escribir')),
    'BTN_NO': t(markTr('No')),
    'BTN_YES': t(markTr('Sí')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const bg = '#f6f7fb';
  final design =
      TkDesign(
          width: 1000,
          height: 680,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': bg,
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
          _w('Frame', 'Board', 0, 0, 1000, 656, {'bg': bg}),
          _w('Label', 'BoardHint', 150, 140, 700, 60, {
            'text': t(
              markTr(
                'Las unidades, los juegos y los resultados los dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7285',
            'bg': bg,
            'font_size': 14,
          })..parent = 'Board',
          _w(
            'Entry',
            'Answer',
            110,
            260,
            780,
            60,
            {'font_size': 20},
            {'enter_key': 'Answer_enter'},
          )..parent = 'Board',
          _w(
            'Button',
            'BtnCheck',
            690,
            574,
            200,
            54,
            {
              'text': t(markTr('Comprobar')),
              'bg': '#4f6bff',
              'fg': '#ffffff',
              'font_bold': true,
              'font_size': 17,
            },
            {'command': 'BtnCheck_click'},
          )..parent = 'Board',
          _w('StatusBar', 'Status', 0, 656, 1000, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('MiniLang en C++ con FLTK: aprende idiomas con juegos cortos (elegir, ordenar, unir parejas, escribir y escuchar), con racha, meta diaria y paquetes de idiomas que se instalan.'))}
$_miniLangIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_miniLangCode''';
  return TkExample(
    'cpp_minilang',
    t(markTr('MiniLang (C++)')),
    t(
      markTr(
        'Aprender idiomas con juegos cortos, nativo en C++ con FLTK: elegir la traducción, ordenar las palabras, unir parejas, escribir y escuchar, con vidas, meta diaria, racha y repaso. El curso de inglés va de A1 a C1 y los demás idiomas son paquetes que se instalan. Vive en la barra de menús.',
      ),
    ),
    design,
    code,
  );
}
