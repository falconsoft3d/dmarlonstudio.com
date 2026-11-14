part of 'tk_examples.dart';

// ------------------------------------------------ Plan de viaje (Pascal)
/// Una app de Object Pascal (Lazarus) que, con un origen, un destino y unos
/// días, pide a Claude Code (la orden «claude -p», con un esquema JSON) un
/// plan de viaje por los lugares interesantes del destino y lo dibuja como
/// una imagen vertical (1080 × 1920, para el móvil) o como un dosier en PDF
/// de varias páginas.
TkExample tkPascalTravel(String Function(String) t) {
  final app = t(markTr('Plan de viaje'));
  // Con contexto (msgctxt «trip»): el origen y el presupuesto de un viaje.
  String tc(String id) {
    final k = contextKey('trip', id);
    final r = t(k);
    return r == k ? id : r;
  }

  final mFile = t(markTr('Archivo')),
      mView = t(markTr('Ver')),
      mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  final fmtImage = t(markTr('Imagen vertical')),
      fmtDossier = t(markTr('Dosier (PDF)'));
  lines.add(mFile);
  item('PLAN', t(markTr('Preparar el plan con Claude Code')), mFile);
  item('SAVE', t(markTr('Guardar la imagen o el dosier…')), mFile);
  lines.add('  -');
  item('OPEN_JSON', t(markTr('Abrir un plan…')), mFile);
  item('SAVE_JSON', t(markTr('Guardar el plan…')), mFile);
  item('SAMPLE', t(markTr('Ver el ejemplo')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mView);
  item('IMAGE', fmtImage, mView);
  item('DOSSIER', fmtDossier, mView);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Plan de viaje')), mHelp);

  final btnPlan = t(markTr('✨ Preparar el plan con Claude Code')),
      btnSave = t(markTr('Guardar…'));
  final lOrigin = tc(markTrc('trip', 'Origen')),
      lDest = tc(markTrc('trip', 'Destino')),
      lDays = t(markTr('Días')),
      lPace = t(markTr('Ritmo')),
      lBudget = tc(markTrc('trip', 'Presupuesto')),
      lLikes = t(markTr('Le interesa')),
      lFormat = t(markTr('Formato'));
  final pace = [t(markTr('Tranquilo')), t(markTr('Normal')), t(markTr('Intenso'))];
  final budget = [t(markTr('Económico')), t(markTr('Medio')), t(markTr('Alto'))];
  final likes = {
    'History': t(markTr('Historia y monumentos')),
    'Art': t(markTr('Arte y museos')),
    'Food': t(markTr('Gastronomía')),
    'Nature': t(markTr('Naturaleza')),
    'Night': t(markTr('Vida nocturna')),
    'Kids': t(markTr('Con niños')),
  };
  final sideNote = t(
    markTr(
      'Claude Code prepara el plan con lugares que existen de verdad. Revise horarios y precios antes de ir.',
    ),
  );

  final texts = <String, String>{
    'APP': app,
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'Escriba de dónde sale y adónde va, cuántos días tiene, su ritmo, su presupuesto y lo que le interesa, y pulse «Preparar el plan con Claude Code». La app le pide a Claude Code (la orden «claude» de su equipo) un plan con los lugares interesantes del destino, día a día y en un orden que tiene sentido, con la hora, una descripción, un consejo y dónde comer.\n\nEl plan se ve de dos formas (elíjala en «Formato»):\n• Imagen vertical: 1080 × 1920, para el móvil o las historias.\n• Dosier (PDF): una portada con cómo llegar, cuándo ir y el presupuesto, una página por día y los consejos.\n\n«Guardar…» guarda la imagen (PNG) o el dosier (PDF). En Archivo puede guardar el plan (JSON) para abrirlo otro día sin volver a pedirlo.\n\nHace falta tener Claude Code instalado y con la sesión iniciada. Mientras Claude prepara el plan (suele tardar entre medio minuto y dos minutos), el botón sirve para cancelarlo.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en Object Pascal con Lazarus. La ventana, su menú y los campos se diseñaron en el Diseñador del estudio; el código de Form1.pas llama a Claude Code («claude -p» con un esquema JSON) en otro hilo, lee el plan con fpjson, dibuja la imagen y las páginas en el lienzo y hace el PDF con fpPDF.',
      ),
    ),
    'PROMPT': t(
      markTr(
        'Eres un guía de viajes con mucha experiencia. Prepara un plan de viaje de {0} días a {1} para alguien que sale de {2}. Le interesa: {3}. Ritmo: {4}. Presupuesto: {5}.\nPara cada día, entre 3 y 5 lugares interesantes que existan de verdad, en un orden que tenga sentido para moverse, con la hora aproximada (HH:MM), una descripción de una o dos frases y un consejo práctico; y en «food», qué y dónde comer ese día (sin empezar por «Para comer»). El «title» de cada día, sin «Día 1». En «getting_there», cómo ir desde el origen (medio, duración aproximada y un consejo). En «best_time», la mejor época. En «budget», una estimación por persona y día. En «tips», 4 o 5 consejos útiles para ese destino. En «title», un título corto y en «subtitle», una frase que invite a ir. Escribe todo en español, con frases cortas y claras.',
      ),
    ),
    'SAMPLE': t(
      markTr(
        '{"title":"Lisboa en tres días","subtitle":"Tranvías, miradores y pastéis de nata en la ciudad de las siete colinas.","destination":"Lisboa","country":"Portugal","origin":"Madrid","getting_there":{"mode":"Avión","duration":"1 h 20 min","tip":"Hay muchos vuelos al día desde Madrid; el metro lleva del aeropuerto al centro en 25 minutos."},"best_time":"De marzo a junio y de septiembre a octubre: buen tiempo y menos gente que en verano.","budget":"Unos 90 a 120 € por persona y día sin el alojamiento: comida, transporte y entradas.","days":[{"title":"Baixa y Alfama","theme":"El corazón de la ciudad y su barrio más antiguo","food":"Bacalhau à Brás en una tasca de Alfama, y fado por la noche.","stops":[{"time":"09:30","name":"Praça do Comércio","kind":"monument","description":"La gran plaza junto al Tajo, abierta al río por el Arco da Rua Augusta.","tip":"Suba al mirador del arco para ver la Baixa desde arriba."},{"time":"11:00","name":"Sé de Lisboa","kind":"religious","description":"La catedral más antigua de la ciudad, del siglo XII, con aire de fortaleza.","tip":"El tranvía 28 pasa por la puerta: fotografíelo en la curva."},{"time":"12:30","name":"Miradouro de Santa Luzia","kind":"viewpoint","description":"Azulejos, buganvillas y los tejados de Alfama hasta el río.","tip":"Al lado está el de Portas do Sol, aún más amplio."},{"time":"16:00","name":"Castelo de São Jorge","kind":"monument","description":"El castillo en lo alto de la colina, con murallas y las mejores vistas al atardecer.","tip":"Compre la entrada en línea para no hacer cola."}]},{"title":"Belém","theme":"Los descubrimientos, el río y el dulce más famoso","food":"Pastéis de nata recién hechos y, para cenar, sardinas a la brasa.","stops":[{"time":"09:30","name":"Mosteiro dos Jerónimos","kind":"religious","description":"Un monasterio manuelino con un claustro de piedra labrada que deja sin palabras.","tip":"Llegue a la apertura: a media mañana hay mucha cola."},{"time":"11:30","name":"Pastéis de Belém","kind":"food","description":"La pastelería que hace los pastéis de nata desde 1837, con canela y azúcar.","tip":"Para llevar va más rápido; dentro hay salones grandes."},{"time":"12:30","name":"Torre de Belém","kind":"monument","description":"La torre que vigilaba la entrada del Tajo, símbolo de la época de los descubrimientos.","tip":"Pasee por la orilla hasta el Padrão dos Descobrimentos."},{"time":"15:00","name":"MAAT","kind":"museum","description":"El museo de arte, arquitectura y tecnología, con un tejado ondulado que se puede pisar.","tip":"La vista del puente 25 de Abril desde el tejado es gratis."}]},{"title":"Chiado, Bairro Alto y LX Factory","theme":"Librerías, mercados y la Lisboa creativa","food":"Un almuerzo en el Time Out Market y una ginjinha antes de cenar.","stops":[{"time":"10:00","name":"Livraria Bertrand","kind":"shopping","description":"La librería abierta más antigua del mundo, en la elegante Rua Garrett del Chiado.","tip":"Pida el sello del libro que compre: lo marcan como recuerdo."},{"time":"11:30","name":"Miradouro de São Pedro de Alcântara","kind":"viewpoint","description":"Un jardín mirador con el castillo enfrente y la Baixa a sus pies.","tip":"Baje al Chiado en el Elevador da Glória."},{"time":"13:00","name":"Time Out Market","kind":"market","description":"El antiguo mercado de la Ribeira, con puestos de los mejores cocineros de la ciudad.","tip":"Vaya antes de las 13:00 para encontrar mesa."},{"time":"16:30","name":"LX Factory","kind":"neighborhood","description":"Una antigua fábrica llena de tiendas, talleres, cafés y arte urbano.","tip":"El domingo hay mercado; no se pierda la librería Ler Devagar."}]}],"tips":["Compre una tarjeta Viva Viagem: vale para el metro, los tranvías y los elevadores.","Lleve calzado cómodo: Lisboa es de cuestas y de adoquines que resbalan.","El tranvía 28 se llena: cójalo a primera hora o en la parada de Martim Moniz.","Muchos museos cierran los lunes; revise los horarios antes de ir.","Pida el agua del grifo y pruebe el vino verde con el pescado."]}',
      ),
    ),
    'SAMPLE_HINT': t(
      markTr(
        'Un ejemplo: escriba su origen y su destino y pulse «Preparar el plan con Claude Code»',
      ),
    ),
    'YOUR_TRIP': t(markTr('Su viaje')),
    'L_ORIGIN': lOrigin,
    'L_DEST': lDest,
    'L_DAYS': lDays,
    'L_PACE': lPace,
    'L_BUDGET': lBudget,
    'L_LIKES': lLikes,
    'L_FORMAT': lFormat,
    'PACE_2': pace[1],
    'BUD_2': budget[1],
    'LIKE_HISTORY': likes['History']!,
    'LIKE_ART': likes['Art']!,
    'LIKE_FOOD': likes['Food']!,
    'LIKE_NATURE': likes['Nature']!,
    'LIKE_NIGHT': likes['Night']!,
    'LIKE_KIDS': likes['Kids']!,
    'LIKE_ALL': t(markTr('un poco de todo')),
    'FORMAT_IMAGE': fmtImage,
    'FORMAT_DOSSIER': fmtDossier,
    'BTN_PLAN': btnPlan,
    'BTN_STOP': t(markTr('■ Cancelar')),
    'BTN_SAVE': btnSave,
    'SIDE_NOTE': sideNote,
    'KICKER': t(markTr('Plan de viaje')),
    'FROM': t(markTr('desde {0}')),
    'ONE_DAY': t(markTr('1 día')),
    'N_DAYS': t(markTr('{0} días')),
    'DAY_N': t(markTr('Día {0}')),
    'GET_THERE': t(markTr('Cómo llegar: {0} · {1}')),
    'EAT': t(markTr('Para comer: {0}')),
    'TIP': t(markTr('Consejo:')),
    'MADE_WITH': t(markTr('Hecho con Plan de viaje · DMarlon Studio y Claude Code')),
    'PAGE': t(markTr('{0} / {1}')),
    'HOW_GET': t(markTr('Cómo llegar')),
    'WHEN': t(markTr('Cuándo ir')),
    'BUDGET_T': lBudget,
    'ITINERARY': t(markTr('El itinerario')),
    'FOOD_T': t(markTr('Para comer')),
    'TIPS_T': t(markTr('Consejos para el viaje')),
    'ABOUT_PLAN': t(markTr('Sobre este plan')),
    'PLAN_NOTE': t(
      markTr(
        'Lo ha preparado Claude Code con lugares que existen de verdad. Horarios, precios y aperturas cambian: compruébelos antes de ir.',
      ),
    ),
    'K_MONUMENT': t(markTr('Monumento')),
    'K_MUSEUM': t(markTr('Museo')),
    'K_NATURE': t(markTr('Naturaleza')),
    'K_VIEWPOINT': t(markTr('Mirador')),
    'K_FOOD': t(markTr('Comida')),
    'K_NEIGHBORHOOD': t(markTr('Barrio')),
    'K_BEACH': t(markTr('Playa')),
    'K_SHOPPING': t(markTr('Compras')),
    'K_NIGHT': t(markTr('Noche')),
    'K_RELIGIOUS': t(markTr('Templo')),
    'K_MARKET': t(markTr('Mercado')),
    'K_OTHER': t(markTr('Lugar')),
    'BUSY': t(markTr('Claude Code está preparando su viaje a {0}…')),
    'BUSY_TIME': t(markTr('{0} · suele tardar entre medio minuto y dos minutos')),
    'NEED_PLACES': t(markTr('Escriba el origen y el destino del viaje.')),
    'NO_CLAUDE': t(
      markTr(
        'No encuentro Claude Code en este equipo (la orden «claude»). ¿Abrir la página para instalarlo?',
      ),
    ),
    'ERR_ANSWER': t(
      markTr('Claude Code ha contestado algo que no es un plan. Pruebe otra vez.'),
    ),
    'ERR_CLAUDE': t(markTr('Claude Code no pudo hacerlo: {0}')),
    'CANCELLED': t(markTr('Cancelado')),
    'STATUS_DONE': t(markTr('Listo: {0}, {1} (en {2} s)')),
    'STATUS_READY': t(markTr('{0}, {1}')),
    'PAGES': t(markTr('{0} páginas')),
    'POSTER_SIZE': t(markTr('imagen de 1080 × 1920')),
    'FILTER_PDF': t(markTr('Dosier en PDF|*.pdf')),
    'FILTER_PNG': t(markTr('Imagen PNG|*.png')),
    'FILTER_JSON': t(markTr('Plan de viaje (JSON)|*.json')),
    'FILE_DOSSIER': t(markTr('Dosier {0}')),
    'FILE_IMAGE': t(markTr('Plan {0}')),
    'SAVED': t(markTr('Guardado en {0}')),
    'SAVE_FAILED': t(markTr('No se ha podido guardar: {0}')),
    'BAD_FILE': t(markTr('Ese archivo no es un plan de viaje.')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      '  tx_$key = ${_pasString(value)};',
  ].join('\n');

  const side = '#ffffff', stage = '#e3e8ef';
  TkWidget lbl(String name, int x, int y, int w, String text,
          {int size = 12, bool bold = true, int h = 18}) =>
      _w('Label', name, x, y, w, h, {
        'text': text,
        'bg': side,
        'fg': bold ? '#52606d' : '#7b8794',
        'font_size': size,
        'font_bold': bold,
      })..parent = 'Side';
  TkWidget combo(String name, int x, int y, int w, List<String> items, int index) =>
      _w('Combobox', name, x, y, w, 30, {
        'items': items.join('\n'),
        'text': items[index],
      })..parent = 'Side';
  TkWidget check(String name, int x, int y, String text, bool on) =>
      _w('Checkbutton', name, x, y, x < 100 ? 176 : 140, 24, {
        'text': text,
        'bg': side,
        'checked': on,
      })..parent = 'Side';
  TkWidget radio(String name, int x, int y, String text, bool on) =>
      _w('Radiobutton', name, x, y, x < 100 ? 176 : 140, 24, {
        'text': text,
        'bg': side,
        'checked': on,
      }, {'command': '${name}_click'})..parent = 'Side';

  final design =
      TkDesign(
          width: 1180,
          height: 760,
          target: tkTargetPascal,
          props: {
            'title': app,
            'bg': stage,
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
          // Mientras Claude Code trabaja: el tiempo que lleva.
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
          _w('Frame', 'Side', 0, 0, 360, 736, {'bg': side}),
          _w('Label', 'LblTrip', 24, 18, 300, 32, {
            'text': t(markTr('Su viaje')),
            'bg': side,
            'fg': '#1f2933',
            'font_size': 20,
            'font_bold': true,
          })..parent = 'Side',
          lbl('LblOrigin', 24, 66, 300, lOrigin),
          _w('Entry', 'Origin', 24, 86, 312, 30, {'font_size': 14})
            ..parent = 'Side',
          lbl('LblDest', 24, 128, 300, lDest),
          _w(
            'Entry',
            'Dest',
            24,
            148,
            312,
            30,
            {'font_size': 14},
            {'enter_key': 'Dest_enter'},
          )..parent = 'Side',
          lbl('LblDays', 24, 190, 90, lDays),
          combo('Days', 24, 210, 90, [for (var i = 1; i <= 14; i++) '$i'], 2),
          lbl('LblPace', 126, 190, 100, lPace),
          combo('Pace', 126, 210, 100, pace, 1),
          lbl('LblBudget', 238, 190, 100, lBudget),
          combo('Budget', 238, 210, 98, budget, 1),
          lbl('LblLikes', 24, 258, 300, lLikes),
          check('ChkHistory', 24, 280, likes['History']!, true),
          check('ChkArt', 204, 280, likes['Art']!, true),
          check('ChkFood', 24, 308, likes['Food']!, true),
          check('ChkNature', 204, 308, likes['Nature']!, false),
          check('ChkNight', 24, 336, likes['Night']!, false),
          check('ChkKids', 204, 336, likes['Kids']!, false),
          lbl('LblFormat', 24, 380, 300, lFormat),
          radio('RadImage', 24, 402, fmtImage, true),
          radio('RadDossier', 204, 402, fmtDossier, false),
          _w(
            'Button',
            'BtnPlan',
            24,
            450,
            312,
            44,
            {
              'text': btnPlan,
              'bg': '#d97757',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnPlan_click'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnSave',
            24,
            506,
            312,
            36,
            {'text': btnSave},
            {'command': 'BtnSave_click'},
          )..parent = 'Side',
          lbl('LblNote', 24, 560, 312, sideNote, bold: false, h: 60),
          _w('Frame', 'Stage', 360, 0, 820, 736, {'bg': stage}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'StageHint', 60, 340, 700, 40, {
            'text': t(
              markTr(
                'La imagen vertical y las páginas del dosier las dibuja el código de Form1.pas',
              ),
            ),
            'fg': '#52606d',
            'bg': stage,
            'font_size': 14,
          })..parent = 'Stage',
          _w('StatusBar', 'Status', 0, 736, 1180, 24, {'text': ''}),
        ]);

  final code = _travelCode
      .replaceFirst(
        '// @TITLE',
        '// ${t(markTr('Plan de viaje: con un origen, un destino y unos días, Claude Code prepara el plan por los lugares interesantes y la app lo dibuja como imagen vertical o dosier en PDF, en Pascal con Lazarus.'))}',
      )
      .replaceFirst('  // @TEXTS', consts);
  return TkExample(
    'pascal_travel',
    t(markTr('Plan de viaje (Pascal)')),
    t(
      markTr(
        'Un planificador de viajes en Object Pascal con Lazarus: con el origen, el destino y los días, Claude Code prepara un plan por los lugares interesantes del destino y la app lo dibuja como una imagen vertical para el móvil o un dosier en PDF.',
      ),
    ),
    design,
    code,
  );
}
