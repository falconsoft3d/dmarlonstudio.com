part of 'tk_examples.dart';

// ------------------------------------ Bajo la Sombra del Malecón (Pascal)
/// Una aventura gráfica de investigación en Object Pascal (Lazarus), con el
/// aspecto de los juegos VGA de MS-DOS: una pantalla virtual de 360×220
/// píxeles y 256 colores que se dibuja entera en código (escenas, retratos,
/// iconos y letras) y se amplía sin suavizar. Cuatro actos en La Habana de
/// 2026, pistas, objetos, una linterna que se gasta, el puerto vigilado, una
/// clave que descifrar antes de que se caiga la red y tres finales.
TkExample tkPascalMalecon(String Function(String) t) {
  final app = t(markTr('Bajo la Sombra del Malecón'));

  // ---- menús
  final mGame = t(markTr('Juego')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mGame);
  item('NEW', t(markTr('Nueva partida')), mGame);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mGame);
  lines.add(mHelp);
  item('HOWTO', t(markTr('Cómo se juega')), mHelp);
  item('ABOUT', t(markTr('Acerca de Bajo la Sombra del Malecón')), mHelp);

  // ---- los textos del juego (constantes tx_… de la unidad)
  final texts = <String, String>{
    'APP': app,
    'DEC': t(markTr(',')),
    ...paths,
    'L_HOWTO': t(markTr('Cómo se juega')),
    'L_ABOUT': t(markTr('Acerca de Bajo la Sombra del Malecón')),
    'HOWTO_TEXT': t(
      markTr(
        'Usted es Mikel, ex-perito judicial, investigando por su cuenta en La Habana de 2026.\n\nHABLAR: con quien esté en el lugar.\nEXAMINAR: el lugar (a oscuras gasta la linterna).\nVIAJAR: a otro lugar del acto.\nLIBRETA: sus objetos y sus pistas.\n\nHaga clic en las opciones de la lista o pulse 1–6. Clic o Intro hace avanzar los diálogos. Las teclas de los botones son su primera letra.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: una aventura de investigación hecha en Object Pascal con Lazarus. La ventana, el menú y el reloj se diseñaron en el Diseñador del estudio; las escenas, los retratos y las letras se dibujan píxel a píxel en el código de Form1.pas, con una paleta de 256 colores.',
      ),
    ),
    // Actos y lugares
    'ACT1': t(markTr('ACTO I · La llamada en el Malecón')),
    'ACT2': t(markTr('ACTO II · El registro del puerto')),
    'ACT3': t(markTr('ACTO III · Encriptación y conexiones')),
    'ACT4': t(markTr('ACTO IV · La confrontación en Miramar')),
    'LOC_MALECON': t(markTr('Malecón')),
    'LOC_PALADAR': t(markTr('Paladar El Quinqué')),
    'LOC_ALLEY': t(markTr('Callejón de San Lázaro')),
    'LOC_GATE': t(markTr('Puerta del puerto')),
    'LOC_CARGO': t(markTr('Zona de carga')),
    'LOC_BOX': t(markTr('Contenedor diplomático')),
    'LOC_SHOP': t(markTr('Taller de Yari')),
    'LOC_ROOF': t(markTr('Azotea del nodo')),
    'LOC_GARDEN': t(markTr('Jardín de la mansión')),
    'LOC_SERVERS': t(markTr('Sala de servidores')),
    'LOC_OFFICE': t(markTr('Oficina de Valdés')),
    // Interfaz
    'B_TALK': t(markTr('HABLAR')),
    'B_LOOK': t(markTr('EXAMINAR')),
    'B_GO': t(markTr('VIAJAR')),
    'B_NOTES': t(markTr('LIBRETA')),
    'H_GO': t(markTr('Ir a:')),
    'H_TALK': t(markTr('Hablar con:')),
    'H_CHOOSE': t(markTr('Elija:')),
    'H_NOTES': t(markTr('En la libreta:')),
    'NOBODY': t(markTr('(no hay nadie)')),
    'HIDE': t(markTr('Esperar en la sombra')),
    'CLUES': t(markTr('Pistas')),
    'NO_CLUES': t(markTr('Todavía no tengo ninguna pista.')),
    'BATTERY': t(markTr('Linterna')),
    'ALERT': t(markTr('Alerta')),
    'SIGNAL': t(markTr('Señal')),
    'HERE': t(markTr('aquí')),
    'MORE': t(markTr('Clic o Intro')),
    'END_STATS': t(markTr('Terminó a las {0} con {1} de {2} pistas.')),
    'END_AGAIN': t(markTr('Clic o Intro para jugar otra vez')),
    'THE_END': t(markTr('FIN')),
    // Personajes
    'P_MIKEL': 'Mikel',
    'P_YARI': 'Yari',
    'P_SOCIO': t(markTr('El Socio')),
    'P_VALDES': t(markTr('Inspector Valdés')),
    'P_FISHER': t(markTr('Pescador')),
    'P_GIRL': t(markTr('Muchacha del móvil')),
    'P_COOK': t(markTr('Doña Caridad')),
    'P_GUARD': t(markTr('Guardia')),
    'P_RAMIRO': t(markTr('Ramiro «el Gestor»')),
    'R_MIKEL': t(markTr('Investigador')),
    'R_YARI': t(markTr('La Ingeniera')),
    'R_SOCIO': t(markTr('Mercado negro')),
    'R_VALDES': t(markTr('Policía')),
    'R_FISHER': t(markTr('En el muro')),
    'R_GIRL': t(markTr('Cazando señal')),
    'R_COOK': t(markTr('La cocinera')),
    'R_GUARD': t(markTr('Turno de noche')),
    'R_RAMIRO': t(markTr('El mediador')),
    // Objetos
    'IT_CELL': t(markTr('Pila recargable')),
    'IT_LITHIUM': t(markTr('Batería de litio')),
    'IT_PASS': t(markTr('Pase del puerto')),
    'IT_USB': t(markTr('Memoria USB cifrada')),
    'IT_LIST': t(markTr('Listado en papel térmico')),
    'D_CELL': t(
      markTr(
        'Una pila recargable envuelta en nailon. Aquí vale más que el dinero.',
      ),
    ),
    'D_LITHIUM': t(
      markTr(
        'Una batería de litio de las buenas, de las que mueven una bicicleta eléctrica.',
      ),
    ),
    'D_PASS': t(
      markTr(
        'Un pase de estibador con un nombre que no es el mío. El Socio no hace preguntas.',
      ),
    ),
    'D_USB': t(
      markTr('Una memoria USB con candado. Sin la clave es un llavero.'),
    ),
    'D_LIST': t(
      markTr('Papel térmico casi borrado. Nombres en clave y coordenadas:'),
    ),
    // Pistas
    'CL_BOAT': t(
      markTr(
        'El pescador vio una lancha sin luces salir del muelle hacia Regla la noche del apagón.',
      ),
    ),
    'CL_DEBT': t(
      markTr(
        'El Gestor pagaba con baterías de litio: tenía acceso a un lote que no debía existir.',
      ),
    ),
    'CL_TERMINAL': t(
      markTr(
        'En el terminal del contenedor: «SINCRONIZACIÓN INTERRUMPIDA — NODO MIRAMAR».',
      ),
    ),
    'CL_BIRDS': t(
      markTr(
        'El Socio: los que reciben en la Habana Vieja firman con nombres de pájaros.',
      ),
    ),
    'CL_OLDTOWN': t(
      markTr('Yari: la Habana Vieja queda entre -82,36 y -82,34 de longitud.'),
    ),
    'CL_FRAUD': t(
      markTr(
        'Solenergía Caribe vendía dos veces los paneles «donados»: al Estado y al mercado negro.',
      ),
    ),
    'CL_MIRAMAR': t(
      markTr(
        'En Miramar hay luz toda la noche. Media Habana a oscuras y allí no se apaga nada.',
      ),
    ),
    // Introducción
    'N_INTRO1': t(
      markTr(
        'La Habana, 2026. Otro apagón se traga Centro Habana. En el puerto, un contenedor diplomático amaneció abierto: dentro no había mercancía, solo un terminal viejo encendido.',
      ),
    ),
    'N_INTRO2': t(
      markTr(
        'Y falta Ramiro «el Gestor» Quintana, el que lo resolvía todo en el mercado informal. Me llamo Mikel. Fui perito judicial; ahora investigo por mi cuenta.',
      ),
    ),
    'N_INTRO3': t(
      markTr(
        'Yari me espera en una paladar clandestina. Pero la noche empieza en el Malecón, con la linterna a medio cargar.',
      ),
    ),
    // Acto I
    'FISHER_1': t(
      markTr(
        'Aquí no pica ni el aire, asere. Pero anoche, con el apagón, vi una lancha sin luces salir del muelle del contenedor rumbo a Regla.',
      ),
    ),
    'FISHER_2': t(
      markTr(
        '¿Pilas? Mira entre las piedras del muro. Los muchachos esconden ahí lo que resuelven.',
      ),
    ),
    'GIRL_1': t(
      markTr(
        'Estoy cazando señal pa\' bajar el paquete, no me desconcentres. ¿La paladar? Dos cuadras pa\' dentro, la del quinqué en la ventana. Pregunta por Yari.',
      ),
    ),
    'VALDES_1': t(
      markTr(
        'Mikel. Esto es asunto de la policía. Vete a tu casa antes de que te pida el carné.',
      ),
    ),
    'VALDES_2': t(
      markTr(
        '…Aunque, entre tú y yo, al puerto no entra nadie sin pase. Ni yo, sin tres papeles firmados.',
      ),
    ),
    'COOK_1': t(
      markTr(
        'Aquí se cocina con carbón y con fe, mijo. El Gestor comía aquí los jueves. La última vez pagó con una batería de litio, ¿tú te crees eso?',
      ),
    ),
    'COOK_2': t(
      markTr(
        'Dejó una caja en la cocina. Sin corriente a mí no me sirve de nada; si la quieres, búscala.',
      ),
    ),
    'YARI_1': t(
      markTr(
        'Llegaste tarde, como siempre. El Gestor me pidió hace una semana que le revisara un terminal viejo… y ahora el terminal está en un contenedor del puerto y él, desaparecido.',
      ),
    ),
    'YARI_2': t(
      markTr(
        'Para entrar al puerto hace falta un pase. El Socio los vende, pero no acepta dinero: quiere baterías. Dos.',
      ),
    ),
    'SOCIO_1': t(
      markTr(
        'Mikel, mi hermano. Todo se resuelve, todo tiene su precio. ¿Un pase al puerto? Dos baterías: una pila recargable y una de litio.',
      ),
    ),
    'SOCIO_NO': t(markTr('Vuelve cuando tengas las dos. Aquí no se fía.')),
    'SOCIO_DEAL': t(
      markTr(
        'Trato hecho. Con esto entras por la puerta de carga como estibador. Y tú a mí no me conoces.',
      ),
    ),
    'SOCIO_CHARGE': t(
      markTr(
        'Dale, carga la linterna en mi panel. Esta va por la casa, pero no te acostumbres.',
      ),
    ),
    'SOCIO_BYE': t(markTr('Cuídate, que la noche está mala.')),
    'SOCIO_BIRDS': t(
      markTr(
        'Te regalo una: los que reciben en la Habana Vieja firman con nombres de pájaros. Lo demás tiene precio.',
      ),
    ),
    'C_TRADE': t(markTr('Dar las dos baterías por el pase')),
    'C_CHARGE': t(markTr('Cargar la linterna')),
    'C_BYE': t(markTr('Despedirse')),
    'LOOK_MALECON': t(
      markTr(
        'Entre las piedras del muro, envuelta en nailon: una pila recargable. Alguien la guardaba para venderla.',
      ),
    ),
    'LOOK_MALECON_2': t(
      markTr(
        'El mar golpea el muro y salpica la avenida. Nada más que la noche.',
      ),
    ),
    'LOOK_PALADAR': t(
      markTr(
        'En la cocina, la caja del Gestor: cables, un cargador roto y una batería de litio sin estrenar.',
      ),
    ),
    'LOOK_ALLEY': t(
      markTr(
        'Antenas caseras, cables que cruzan la calle y un panel solar amarrado a un balcón. Aquí todo se inventa.',
      ),
    ),
    'NOTHING': t(markTr('Nada más que ver aquí.')),
    'NO_BATTERY': t(
      markTr(
        'La linterna está muerta. A oscuras no se ve nada: hacen falta pilas o un panel.',
      ),
    ),
    'GO_PORT': t(
      markTr(
        'Con el pase en el bolsillo bajo hacia el puerto. Los guardias huelen el miedo, así que camino como si llevara diez años cargando sacos.',
      ),
    ),
    // Acto II
    'GUARD_1': t(
      markTr(
        'Pase de estibador… pasa. Turno de noche: no te pierdas, que los perros no saben leer papeles.',
      ),
    ),
    'GUARD_2': t(markTr('Muévete, que me haces quedar mal.')),
    'GUARD_STOP': t(
      markTr(
        'El guardia me corta el paso: «¿Y tú pa\' dónde vas? Enséñame el pase primero.»',
      ),
    ),
    'VALDES_GATE': t(
      markTr(
        'Mira quién vino. Yo no te vi. Pero si encuentras algo, me lo cuentas a mí primero.',
      ),
    ),
    'LOOK_GATE': t(
      markTr(
        'Grúas quietas por el apagón. Solo la garita tiene luz: una planta eléctrica que ronca como un camión.',
      ),
    ),
    'LOOK_CARGO': t(
      markTr(
        'Entre los sacos de café hay uno cosido distinto. Dentro, enterrada en el grano: una memoria USB con candado.',
      ),
    ),
    'LOOK_BOX_1': t(
      markTr(
        'El terminal sigue encendido con una batería de camión. En la pantalla parpadea: «SINCRONIZACIÓN INTERRUMPIDA — NODO MIRAMAR».',
      ),
    ),
    'LOOK_BOX_2': t(
      markTr(
        'Pegado bajo la mesa, un listado impreso en papel térmico: nombres en clave y coordenadas de la Habana.',
      ),
    ),
    'HIDE_DONE': t(
      markTr('Me quedo quieto detrás de una grúa hasta que pasa la ronda.'),
    ),
    'CAUGHT': t(
      markTr(
        'Una linterna me da en la cara. «¡Alto ahí!» Los guardias me llevan a la garita.',
      ),
    ),
    'VALDES_FREE': t(
      markTr(
        'Te soltaron porque di la cara por ti. La próxima vez te dejo dentro.',
      ),
    ),
    'GO_SHOP': t(
      markTr(
        'Tengo la memoria y el listado. A Centro Habana, al taller de Yari, antes de que corten la señal de la red.',
      ),
    ),
    // Acto III
    'YARI_SHOP_1': t(
      markTr(
        'Esta memoria tiene cifrado del bueno, no de los que se rompen con un tutorial. La clave es un nombre en clave del listado: el de quien recibe en la Habana Vieja.',
      ),
    ),
    'YARI_SHOP_2': t(
      markTr(
        'Mira las coordenadas: la Habana Vieja queda entre la bahía y el Prado, de -82,36 a -82,34 de longitud. Y apúrate, que el nodo se cae.',
      ),
    ),
    'YARI_SHOP_3': t(
      markTr(
        '¿Probamos otra clave? Cada intento fallido hace ruido en la red.',
      ),
    ),
    'C_DECRYPT': t(markTr('Probar una clave')),
    'C_LATER': t(markTr('Ahora no')),
    'WRONG': t(markTr('Clave incorrecta. La red se queja: perdemos señal.')),
    'SIGNAL_LOST': t(
      markTr(
        'Se cayó el nodo de la red local. Hay que reiniciarlo desde la azotea.',
      ),
    ),
    'RIGHT': t(markTr('¡Abierta! A ver qué escondía el Gestor…')),
    'TWIST_1': t(
      markTr(
        'Facturas de «Solenergía Caribe»: paneles solares y baterías donados para los apagones… y vendidos dos veces. Una al Estado, otra al mercado negro.',
      ),
    ),
    'TWIST_2': t(
      markTr(
        'Firmas de altos funcionarios. Y Ramiro lo descubrió todo: lo iba a soltar en la red. No lo secuestró ninguna banda, Mikel. Se escondió.',
      ),
    ),
    'TWIST_3': t(
      markTr(
        'La última conexión de su terminal viene de un nodo en Miramar: una mansión abandonada de la Quinta Avenida convertida en centro de servidores.',
      ),
    ),
    'LOOK_SHOP': t(
      markTr(
        'Monitores de tubo, un router reprogramado y un banco de baterías que Yari cuida como a un hijo.',
      ),
    ),
    'LOOK_ROOF': t(
      markTr(
        'Reinicio el nodo: la antena parpadea y vuelve la señal. La linterna sale perdiendo.',
      ),
    ),
    'LOOK_ROOF_OK': t(
      markTr(
        'El nodo funciona. Desde aquí se ve la ciudad a oscuras y, al oeste, Miramar con todas las luces encendidas.',
      ),
    ),
    // Acto IV
    'LOOK_GARDEN': t(
      markTr(
        'Paneles solares nuevos, de los «donados», alimentan la casa entera. Media Habana a oscuras y aquí no se apaga ni un bombillo.',
      ),
    ),
    'LOOK_SERVERS': t(
      markTr(
        'Racks llenos de luces. Por aquí pasan las cuentas de Solenergía Caribe y los correos de los que firman.',
      ),
    ),
    'RAMIRO_1': t(
      markTr(
        '¿Mikel? Pensé que eras de ellos. Tengo todo: contratos, firmas, cuentas. Si sale a la luz, me buscan a mí. Si no sale, siguen robando la luz de todos.',
      ),
    ),
    'RAMIRO_2': t(
      markTr(
        'Yo ya no puedo más. Toma la memoria con las copias. La decisión es tuya.',
      ),
    ),
    'C_LEAK': t(markTr('Filtrar los datos a las redes locales')),
    'C_DEAL': t(markTr('Negociar con los implicados')),
    'C_POLICE': t(markTr('Entregar las pruebas a Valdés')),
    'END_A_TITLE': t(markTr('Final A · La verdad pública')),
    'END_A_1': t(
      markTr(
        'Al amanecer, los datos corren de azotea en azotea por las redes independientes. Nadie puede apagar lo que ya está en todos los teléfonos.',
      ),
    ),
    'END_A_2': t(
      markTr(
        'Hay justicia, o algo que se le parece. Yo me quedo sin casa y sin nombre: desde hoy vivo en la clandestinidad.',
      ),
    ),
    'END_B_TITLE': t(markTr('Final B · El pacto')),
    'END_B_1': t(
      markTr(
        'Los implicados pagan mi silencio en paneles y baterías. Esa noche, por primera vez en meses, el barrio entero tiene luz.',
      ),
    ),
    'END_B_2': t(
      markTr(
        'Ramiro desaparece del todo. Yo sigo resolviendo, como todos. Pero cada bombillo encendido me recuerda el precio.',
      ),
    ),
    'END_C_TITLE': t(markTr('Final C · Justicia policial')),
    'END_C_1': t(
      markTr(
        'Le entrego todo a Valdés. Me mira un rato largo: «Hiciste lo correcto. Ahora reza para que sirva de algo.»',
      ),
    ),
    'END_C_2': t(
      markTr(
        'Tres semanas después, el caso pasa a «otras instancias». Valdés me invita a un café. No dice nada; no hace falta.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      '  tx_$key = ${_pasString(value)};',
  ].join('\n');

  // ---- la ventana: el menú, el reloj y el marco donde se dibuja la pantalla
  final design =
      TkDesign(
          width: 1080,
          height: 660,
          target: tkTargetPascal,
          props: {
            'title': app,
            'bg': '#000000',
            'position': 'center',
            'resizable': false,
          },
          events: {
            'create': 'form_create',
            'close': 'form_close',
            'key': 'form_key',
          },
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1020,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Diez veces por segundo: el texto que se escribe, el mar, las luces.
          _w(
            'Timer',
            'Tick',
            980,
            8,
            32,
            32,
            {'interval': 100},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Stage', 0, 0, 1080, 660, {'bg': '#000000'}),
          // Solo para el Diseñador: el juego la oculta al arrancar.
          _w('Label', 'StageHint', 140, 300, 800, 40, {
            'text': t(
              markTr(
                'La pantalla VGA del juego la dibuja el código de Form1.pas',
              ),
            ),
            'fg': '#8b95a3',
            'bg': '#000000',
            'font_size': 15,
          })..parent = 'Stage',
        ]);

  final code = _maleconCode
      .replaceFirst(
        '// @TITLE',
        '// ${t(markTr('Bajo la Sombra del Malecón: aventura de investigación en Pascal con Lazarus, con escenas en pixel art de 256 colores dibujadas en código.'))}',
      )
      .replaceFirst('  // @TEXTS', consts);
  return TkExample(
    'pascal_malecon',
    t(markTr('Bajo la Sombra del Malecón (Pascal)')),
    t(
      markTr(
        'Una aventura gráfica de investigación en La Habana de 2026, en Object Pascal con Lazarus: pixel art de 256 colores dibujado en código, cuatro actos, pistas y objetos, una linterna que se gasta, el puerto vigilado, una clave que descifrar y tres finales.',
      ),
    ),
    design,
    code,
  );
}

/// Una cadena de Pascal, partida en trozos (las constantes muy largas no
/// caben en una sola literal).
String _pasString(String v) {
  const max = 180;
  if (v.length <= max) return TkPascal.str(v);
  final parts = <String>[];
  for (var i = 0; i < v.length; i += max) {
    parts.add(TkPascal.str(v.substring(i, math.min(v.length, i + max))));
  }
  return parts.join(' +\n    ');
}
