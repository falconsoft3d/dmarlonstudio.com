part of 'tk_examples.dart';

// ------------------------------------------------------- OpenD++ (Pascal)
/// Un editor de diseño de interfaces en Object Pascal (Lazarus), inspirado en
/// las herramientas de diseño colaborativo pero con otra distribución: las
/// herramientas en una columna a la izquierda, el inspector a su lado, las
/// capas, los componentes y los comentarios a la derecha y las páginas como
/// pestañas arriba. Marcos con tamaños de dispositivo, formas, pluma, texto,
/// imágenes, grupos, componentes con instancias, diseño automático, guías
/// inteligentes, prototipos que se presentan, el código CSS y Flutter de cada
/// capa y exportar a PNG y SVG. Todo se dibuja con un rasterizador propio.
TkExample tkPascalOpenD(String Function(String) t) {
  const app = 'OpenD++';

  // ---- el menú de la ventana
  final mFile = t(markTr('Archivo')),
      mEdit = t(markTr('Editar')),
      mObject = t(markTr('Objeto')),
      mView = t(markTr('Ver')),
      mAi = t(markTr('IA')),
      mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  void sep() => lines.add('  -');

  lines.add(mFile);
  item('NEW', t(markTr('Nuevo')), mFile);
  item('OPEN', t(markTr('Abrir…')), mFile);
  item('SAMPLE', t(markTr('Abrir el ejemplo')), mFile);
  sep();
  item('SAVE', t(markTr('Guardar')), mFile);
  item('SAVE_AS', t(markTr('Guardar como…')), mFile);
  sep();
  item('IMPORT', t(markTr('Colocar una imagen…')), mFile);
  item('EXPORT', t(markTr('Exportar la selección…')), mFile);
  sep();
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mEdit);
  item('UNDO', t(markTr('Deshacer')), mEdit);
  item('REDO', t(markTr('Rehacer')), mEdit);
  sep();
  item('CUT', t(markTr('Cortar')), mEdit);
  item('COPY', t(markTr('Copiar')), mEdit);
  item('PASTE', t(markTr('Pegar')), mEdit);
  item('DUP', t(markTr('Duplicar')), mEdit);
  item('DEL', t(markTr('Eliminar')), mEdit);
  sep();
  item('ALL', t(markTr('Seleccionar todo')), mEdit);
  lines.add(mObject);
  item('GROUP', t(markTr('Agrupar')), mObject);
  item('UNGROUP', t(markTr('Desagrupar')), mObject);
  item('FRAME_SEL', t(markTr('Enmarcar la selección')), mObject);
  item('AUTO', t(markTr('Diseño automático')), mObject);
  sep();
  item('COMP', t(markTr('Crear un componente')), mObject);
  item('DETACH', t(markTr('Separar la instancia')), mObject);
  sep();
  item('FRONT', t(markTr('Traer al frente')), mObject);
  item('FWD', t(markTr('Traer adelante')), mObject);
  item('BACK', t(markTr('Enviar atrás')), mObject);
  item('BOTTOM', t(markTr('Enviar al fondo')), mObject);
  sep();
  item('HIDE', t(markTr('Mostrar u ocultar')), mObject);
  item('LOCK', t(markTr('Bloquear o desbloquear')), mObject);
  lines.add(mView);
  item('ZOOM_IN', t(markTr('Acercar')), mView);
  item('ZOOM_OUT', t(markTr('Alejar')), mView);
  item('ZOOM_100', t(markTr('Tamaño real (100 %)')), mView);
  item('ZOOM_ALL', t(markTr('Ver todo')), mView);
  item('ZOOM_SEL', t(markTr('Ver la selección')), mView);
  sep();
  item('RULERS', t(markTr('Reglas')), mView);
  item('PIXGRID', t(markTr('Cuadrícula de píxeles')), mView);
  item('SNAP', t(markTr('Imán (guías inteligentes)')), mView);
  item('THEME', t(markTr('Tema claro u oscuro')), mView);
  sep();
  item('MODE_D', t(markTr('Modo diseño')), mView);
  item('MODE_P', t(markTr('Modo prototipo')), mView);
  item('MODE_C', t(markTr('Modo código')), mView);
  item('PLAY', t(markTr('Presentar')), mView);
  lines.add(mAi);
  item('AI_SCHEMA', t(markTr('Copiar la plantilla JSON para la IA')), mAi);
  item('AI_SAVE', t(markTr('Guardar la plantilla JSON…')), mAi);
  sep();
  item('AI_PASTE', t(markTr('Pegar un diseño JSON')), mAi);
  item('AI_IMPORT', t(markTr('Importar un diseño JSON…')), mAi);
  sep();
  item('AI_EXPORT', t(markTr('Copiar la selección como JSON')), mAi);
  lines.add(mHelp);
  item('KEYS', t(markTr('Atajos del teclado')), mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de OpenD++')), mHelp);

  // ---- los textos (constantes tx_… de la unidad)
  final texts = <String, String>{
    ...paths,
    // @@TEXTS@@
    'UNTITLED': t(
      markTr('Sin título'),
    ),
    'DRAFT': t(
      markTr('BORRADOR'),
    ),
    'PAGE': t(
      markTr('Página'),
    ),
    'EXPORT': t(
      markTr('Exportar'),
    ),
    'PRESENT': t(
      markTr('Presentar'),
    ),
    'MODE_DESIGN': t(
      markTr('Diseño'),
    ),
    'MODE_PROTO': t(
      markTr('Prototipo'),
    ),
    'MODE_CODE': t(
      markTr('Código'),
    ),
    'LAYERS': t(
      markTr('Capas'),
    ),
    'LAYERS_LC': t(
      markTr('capas'),
    ),
    'ASSETS': t(
      markTr('Biblioteca'),
    ),
    'COMMENTS': t(
      markTr('Comentarios'),
    ),
    'COMPONENTS': t(
      markTr('COMPONENTES'),
    ),
    'NO_LAYERS': t(
      markTr('La página está vacía. Elija un marco (F) en la columna de herramientas y arrástrelo en el lienzo, o pegue un diseño JSON de la IA.'),
    ),
    'NO_COMPONENTS': t(
      markTr('Aún no hay componentes. Elija unas capas y use Objeto › Crear un componente (⌥⌘K).'),
    ),
    'ASSETS_HINT': t(
      markTr('Pulse un componente para poner una instancia: si cambia el principal, cambian todas.'),
    ),
    'NO_COMMENTS': t(
      markTr('No hay comentarios abiertos. Use la herramienta Comentario (C) y pulse en el lienzo.'),
    ),
    'YOU': t(
      markTr('Usted'),
    ),
    'RESOLVE': t(
      markTr('Resolver'),
    ),
    'RESOLVED': t(
      markTr('Comentario resuelto'),
    ),
    'DELETE': t(
      markTr('Borrar'),
    ),
    'T_MOVE': t(
      markTr('Mover'),
    ),
    'T_HAND': t(
      markTr('Mano'),
    ),
    'T_FRAME': t(
      markTr('Marco'),
    ),
    'T_RECT': t(
      markTr('Rectángulo'),
    ),
    'T_ELLIPSE': t(
      markTr('Elipse'),
    ),
    'T_LINE': t(
      markTr('Línea'),
    ),
    'T_ARROW': t(
      markTr('Flecha'),
    ),
    'T_POLYGON': t(
      markTr('Polígono'),
    ),
    'T_STAR': t(
      markTr('Estrella'),
    ),
    'T_PEN': t(
      markTr('Pluma'),
    ),
    'T_TEXT': t(
      markTr('Texto'),
    ),
    'T_IMAGE': t(
      markTr('Imagen'),
    ),
    'T_COMMENT': t(
      markTr('Comentario'),
    ),
    'K_FRAME': t(
      markTr('Marco'),
    ),
    'K_GROUP': t(
      markTr('Grupo'),
    ),
    'K_RECT': t(
      markTr('Rectángulo'),
    ),
    'K_ELLIPSE': t(
      markTr('Elipse'),
    ),
    'K_LINE': t(
      markTr('Línea'),
    ),
    'K_ARROW': t(
      markTr('Flecha'),
    ),
    'K_POLYGON': t(
      markTr('Polígono'),
    ),
    'K_STAR': t(
      markTr('Estrella'),
    ),
    'K_PATH': t(
      markTr('Trazado'),
    ),
    'K_TEXT': t(
      markTr('Texto'),
    ),
    'K_COMPONENT': t(
      markTr('Componente'),
    ),
    'K_INSTANCE': t(
      markTr('Instancia'),
    ),
    'THEME_TIP': t(
      markTr('Tema claro u oscuro'),
    ),
    'RULERS': t(
      markTr('Reglas'),
    ),
    'AI_TIP': t(
      markTr('Diseñar con IA (JSON)'),
    ),
    'H_MOVE': t(
      markTr('Pulse para elegir, arrastre para mover · doble clic entra en grupos y textos · ⌘ elige lo de dentro · ⌥ mide distancias'),
    ),
    'H_HAND': t(
      markTr('Arrastre para moverse por el lienzo (también con la barra espaciadora)'),
    ),
    'H_FRAME': t(
      markTr('Arrastre para dibujar un marco o elija un tamaño de dispositivo a la izquierda'),
    ),
    'H_SHAPE': t(
      markTr('Arrastre para dibujar · Mayús: proporcionado · ⌥: desde el centro'),
    ),
    'H_LINE': t(
      markTr('Arrastre para dibujar · Mayús: en ángulos de 45°'),
    ),
    'H_PEN': t(
      markTr('Pulse para poner puntos, arrastre para curvas · pulse el primero para cerrar · Intro termina'),
    ),
    'H_PENON': t(
      markTr('Siga poniendo puntos · Intro o Esc terminan · el primer punto cierra la forma'),
    ),
    'H_TEXT': t(
      markTr('Pulse para escribir (ancho automático) o arrastre para una caja de texto'),
    ),
    'H_IMAGE': t(
      markTr('Elija una imagen para colocarla'),
    ),
    'H_COMMENT': t(
      markTr('Pulse en el lienzo para dejar un comentario'),
    ),
    'H_PROTO': t(
      markTr('Elija una capa y arrastre su círculo hasta otro marco para conectarlos'),
    ),
    'H_CODE': t(
      markTr('Elija una capa para ver su CSS o su Flutter · pase el ratón sobre otra para medir'),
    ),
    'H_TEXTEDIT': t(
      markTr('Escribiendo · Esc termina · ⌘A elige todo'),
    ),
    'H_VERTEX': t(
      markTr('Editando los puntos · doble clic en un punto: curva o esquina · Esc termina'),
    ),
    'UNDONE': t(
      markTr('Deshecho'),
    ),
    'REDONE': t(
      markTr('Rehecho'),
    ),
    'COLOR': t(
      markTr('Color'),
    ),
    'DOC_COLORS': t(
      markTr('COLORES DEL DOCUMENTO'),
    ),
    'POSITION': t(
      markTr('Posición'),
    ),
    'POINTS': t(
      markTr('Puntas'),
    ),
    'RATIO': t(
      markTr('Radio'),
    ),
    'SIDES': t(
      markTr('Lados'),
    ),
    'CLIP': t(
      markTr('Recortar el contenido'),
    ),
    'AUTOLAYOUT': t(
      markTr('Diseño automático'),
    ),
    'GAP': t(
      markTr('Hueco'),
    ),
    'PADDING': t(
      markTr('Margen'),
    ),
    'HUG': t(
      markTr('Abrazar el contenido'),
    ),
    'LAYER': t(
      markTr('Capa'),
    ),
    'TYPOGRAPHY': t(
      markTr('Texto'),
    ),
    'AUTO': t(
      markTr('Auto'),
    ),
    'AUTOWIDTH': t(
      markTr('Ancho automático'),
    ),
    'FILL': t(
      markTr('Relleno'),
    ),
    'FIT': t(
      markTr('Encajar la imagen entera'),
    ),
    'STROKE': t(
      markTr('Trazo'),
    ),
    'INSIDE': t(
      markTr('Dentro'),
    ),
    'OUTSIDE': t(
      markTr('Fuera'),
    ),
    'CENTER': t(
      markTr('Centro'),
    ),
    'SHADOW': t(
      markTr('Sombra'),
    ),
    'EXPORT_SEC': t(
      markTr('Exportar'),
    ),
    'AI_COPY_SEL': t(
      markTr('Copiar como JSON para la IA'),
    ),
    'INSTANCE_OF': t(
      markTr('Instancia de «%s»'),
    ),
    'DETACH': t(
      markTr('Separar'),
    ),
    'MAIN_COMPONENT': t(
      markTr('Componente principal: sus instancias lo siguen'),
    ),
    'PICK_IMAGE': t(
      markTr('Elegir una imagen…'),
    ),
    'PAGE_SEC': t(
      markTr('Página'),
    ),
    'BG': t(
      markTr('Fondo'),
    ),
    'STYLES': t(
      markTr('Estilos de color'),
    ),
    'STYLES_NONE': t(
      markTr('Sin estilos todavía. Cree uno con + o desde el relleno de una capa.'),
    ),
    'STYLE': t(
      markTr('Color'),
    ),
    'STYLE_NEW': t(
      markTr('Crear un estilo con este color'),
    ),
    'TIPS': t(
      markTr('Para empezar'),
    ),
    'TIPS_TEXT': t(
      markTr('Elija un marco de móvil o de escritorio (F), dibuje formas (R, O, L, P) y escriba (T). Con Mayús+A ponga diseño automático, con ⌥⌘K haga un componente y en Prototipo conecte las pantallas para presentarlas. ¿Prefiere que lo haga una IA? Menú IA › Copiar la plantilla JSON.'),
    ),
    'PRESET_PHONE': t(
      markTr('Teléfono'),
    ),
    'PRESET_TABLET': t(
      markTr('Tableta'),
    ),
    'PRESET_DESKTOP': t(
      markTr('Escritorio'),
    ),
    'PRESET_SOCIAL': t(
      markTr('Redes y presentaciones'),
    ),
    'ANIM_INSTANT': t(
      markTr('Instantánea'),
    ),
    'ANIM_DISSOLVE': t(
      markTr('Disolver'),
    ),
    'ANIM_LEFT': t(
      markTr('Deslizar a la izquierda'),
    ),
    'ANIM_RIGHT': t(
      markTr('Deslizar a la derecha'),
    ),
    'ANIM_UP': t(
      markTr('Deslizar hacia arriba'),
    ),
    'ANIM_PUSH': t(
      markTr('Empujar'),
    ),
    'PROTOTYPE': t(
      markTr('Prototipo'),
    ),
    'START_FRAME': t(
      markTr('PANTALLA INICIAL'),
    ),
    'NONE': t(
      markTr('Ninguno'),
    ),
    'PROTO_HINT': t(
      markTr('Elija una capa y arrastre el círculo azul hasta la pantalla a la que debe llevar. Después, Presentar.'),
    ),
    'INTERACTION': t(
      markTr('Interacción'),
    ),
    'ON_CLICK': t(
      markTr('AL HACER CLIC'),
    ),
    'NAVIGATE_TO': t(
      markTr('Ir a'),
    ),
    'ANIMATION': t(
      markTr('ANIMACIÓN'),
    ),
    'DURATION': t(
      markTr('Duración'),
    ),
    'UNLINK': t(
      markTr('Quitar la conexión'),
    ),
    'IS_START': t(
      markTr('Pantalla inicial'),
    ),
    'PROTO_DRAG': t(
      markTr('Consejo: arrastre el círculo + de la capa hasta otro marco para conectarlos.'),
    ),
    'CODE_HINT': t(
      markTr('Elija una capa para ver su código. Pase el ratón por encima de otra para ver las distancias.'),
    ),
    'COPY_CODE': t(
      markTr('Copiar el código'),
    ),
    'COPY_CSS': t(
      markTr('Copiar como CSS'),
    ),
    'CODE_COPIED': t(
      markTr('Código copiado'),
    ),
    'START': t(
      markTr('Comienzo'),
    ),
    'COPIED': t(
      markTr('Copiado'),
    ),
    'SAVED': t(
      markTr('Guardado'),
    ),
    'EXPORTED': t(
      markTr('Exportado: %s'),
    ),
    'LINKED': t(
      markTr('Conectado con «%s»'),
    ),
    'COMP_MADE': t(
      markTr('Componente creado: está en la Biblioteca'),
    ),
    'SELECT_FIRST': t(
      markTr('Elija antes alguna capa'),
    ),
    'NO_FRAMES': t(
      markTr('No hay ningún marco que presentar en esta página'),
    ),
    'ERR_IMAGE': t(
      markTr('No se pudo abrir la imagen'),
    ),
    'ERR_OPEN': t(
      markTr('No es un diseño de OpenD++'),
    ),
    'ERR_SAVE': t(
      markTr('No se pudo guardar'),
    ),
    'ASK_DISCARD': t(
      markTr('Hay cambios sin guardar. ¿Descartarlos?'),
    ),
    'SOLID': t(
      markTr('Sólido'),
    ),
    'LINEAR': t(
      markTr('Degradado lineal'),
    ),
    'IMAGE_FILL': t(
      markTr('Imagen'),
    ),
    'BACK_TO_EDITOR': t(
      markTr('Volver al editor'),
    ),
    'RESTART': t(
      markTr('Reiniciar'),
    ),
    'GO_BACK': t(
      markTr('Atrás'),
    ),
    'PLAY_HINT': t(
      markTr('Pulse en las zonas activas para navegar · pulse fuera para verlas · Esc vuelve al editor'),
    ),
    'AI_PROMPT': t(
      markTr('Eres un diseñador de interfaces. Crea el diseño que te pido y responde SOLO con un JSON con esta misma estructura (pages › frames › children), sin explicaciones. Usa medidas en píxeles: móvil 390×844, escritorio 1440×1024. Las coordenadas x e y de cada capa son relativas a su marco. Usa componentes para lo que se repite (botones, tarjetas) e instancias con overrides para cambiar sus textos. Conecta las pantallas con link para el prototipo. Sustituye el ejemplo por tu diseño. Lo que quiero:'),
    ),
    'AI_EDIT_PROMPT': t(
      markTr('Este es un diseño de OpenD++. Cámbialo como te pido y responde SOLO con el JSON con la misma estructura.'),
    ),
    'AI_COPIED': t(
      markTr('Plantilla JSON copiada'),
    ),
    'AI_HOWTO': t(
      markTr('La plantilla JSON para la IA está en el portapapeles.\n\n1. Péguela en ChatGPT, Claude u otra IA y añada al final lo que quiere (por ejemplo: «una app de reservas de pádel con 4 pantallas»).\n2. Copie el JSON que le responda.\n3. Vuelva aquí y use IA › Pegar un diseño JSON (o ⌘V en el lienzo).\n\nOpenD++ crea las páginas, los marcos, los componentes y las conexiones del prototipo.'),
    ),
    'AI_DONE': t(
      markTr('Diseño importado: %d capas de primer nivel'),
    ),
    'AI_BAD': t(
      markTr('No encuentro un diseño JSON válido. Copie solo la respuesta de la IA (el JSON).'),
    ),
    'AI_EMPTY': t(
      markTr('El JSON no trae ninguna pantalla'),
    ),
    'AI_SEL_COPIED': t(
      markTr('La selección está en el portapapeles como JSON para la IA'),
    ),
    'AIX_PAGE': t(
      markTr('App móvil'),
    ),
    'AIX_BUTTON': t(
      markTr('Botón'),
    ),
    'AIX_LOGIN': t(
      markTr('Iniciar sesión'),
    ),
    'AIX_WELCOME': t(
      markTr('Bienvenido'),
    ),
    'AIX_ENTER': t(
      markTr('Entrar'),
    ),
    'AIX_HOME': t(
      markTr('Inicio'),
    ),
    'AIX_HELLO': t(
      markTr('Hola, Ana'),
    ),
    'KEYS_TEXT': t(
      markTr('Herramientas: V mover · H mano · F marco · R rectángulo · O elipse · L línea · Mayús+L flecha · P pluma · T texto · C comentario.\n\nCapas: ⌘G agrupar · ⇧⌘G desagrupar · ⌥⌘G enmarcar · Mayús+A diseño automático · ⌥⌘K componente · ⌘D duplicar · ⌘] y ⌘[ orden · ⇧⌘H ocultar · ⇧⌘L bloquear · flechas mover (Mayús: 10).\n\nVer: ⌘+ y ⌘− zoom · Mayús+0 100 % · Mayús+1 todo · Mayús+2 la selección · espacio + arrastrar para moverse · ⌘ + rueda para el zoom.\n\nElegir: clic · Mayús+clic añade · ⌘+clic dentro de grupos · doble clic entra · Intro elige los hijos · Esc el padre · Tab el siguiente · ⌥ medir distancias.'),
    ),
    'HOW_TEXT': t(
      markTr('OpenD++ es un editor de diseño de interfaces. A la izquierda están las herramientas y, a su lado, el inspector con las propiedades de lo elegido; a la derecha, las capas, los componentes y los comentarios; arriba, las páginas, el modo (diseño, prototipo o código) y Presentar.\n\nDibuje un marco con un tamaño de dispositivo, añada formas, texto e imágenes, agrúpelas, haga componentes y ponga diseño automático. En Prototipo conecte las pantallas y pulse Presentar para probarlas. En Código verá el CSS y el Flutter de cada capa. Exporte a PNG y SVG.\n\nEl menú IA copia una plantilla JSON para pedirle un diseño a una IA y luego importarlo aquí.'),
    ),
    'ABOUT_TEXT': t(
      markTr('OpenD++ · una demo de DMarlon Studio hecha en Object Pascal con Lazarus.\n\nEl menú, el reloj y los diálogos de abrir, guardar e importar se diseñaron en el Diseñador del estudio. Todo lo demás (el lienzo, las herramientas, el inspector y las capas) lo dibuja el código de Form1.pas con su propio rasterizador: suavizado, transparencias, degradados, sombras, texto e imágenes.'),
    ),
    'S_PAGE1': t(
      markTr('App móvil'),
    ),
    'S_PAGE2': t(
      markTr('Ideas'),
    ),
    'S_GREEN': t(
      markTr('Verde marca'),
    ),
    'S_INK': t(
      markTr('Tinta'),
    ),
    'S_GREY': t(
      markTr('Gris'),
    ),
    'S_BG': t(
      markTr('Fondo'),
    ),
    'S_BUTTON': t(
      markTr('Botón principal'),
    ),
    'S_BUTTON_T': t(
      markTr('Botón'),
    ),
    'S_LABEL': t(
      markTr('Texto'),
    ),
    'S_LOGIN': t(
      markTr('Iniciar sesión'),
    ),
    'S_LOGO': t(
      markTr('Logo'),
    ),
    'S_WELCOME': t(
      markTr('Bienvenido de nuevo'),
    ),
    'S_WELCOME_SUB': t(
      markTr('Marque su entrada y su salida en un toque, esté donde esté.'),
    ),
    'S_EMAIL': t(
      markTr('Correo'),
    ),
    'S_PASSWORD': t(
      markTr('Contraseña'),
    ),
    'S_ENTER': t(
      markTr('Entrar'),
    ),
    'S_FORGOT': t(
      markTr('¿Olvidó su contraseña?'),
    ),
    'S_NO_ACCOUNT': t(
      markTr('¿No tiene cuenta? Pídala a su empresa'),
    ),
    'S_HOME': t(
      markTr('Panel'),
    ),
    'S_HELLO': t(
      markTr('Hola, Ana'),
    ),
    'S_DATE': t(
      markTr('Jueves, 12 de noviembre'),
    ),
    'S_TODAY': t(
      markTr('Hoy'),
    ),
    'S_CHECKIN': t(
      markTr('ENTRADA'),
    ),
    'S_OFFICE': t(
      markTr('En la oficina · Madrid'),
    ),
    'S_BADGE': t(
      markTr('Insignia'),
    ),
    'S_WEEK': t(
      markTr('Esta semana'),
    ),
    'S_DAYS': t(
      markTr('Días'),
    ),
    'S_D1': t(
      markTr('Lun'),
    ),
    'S_D2': t(
      markTr('Mar'),
    ),
    'S_D3': t(
      markTr('Mié'),
    ),
    'S_D4': t(
      markTr('Jue'),
    ),
    'S_D5': t(
      markTr('Vie'),
    ),
    'S_TEAM': t(
      markTr('El equipo hoy'),
    ),
    'S_R1': t(
      markTr('Diseño · desde las 08:41'),
    ),
    'S_R2': t(
      markTr('Desarrollo · desde las 09:02'),
    ),
    'S_R3': t(
      markTr('Ventas · llega 10 min tarde'),
    ),
    'S_IN': t(
      markTr('Dentro'),
    ),
    'S_LATE': t(
      markTr('Tarde'),
    ),
    'S_CHECKOUT': t(
      markTr('Marcar la salida'),
    ),
    'S_COMMENT': t(
      markTr('¿Probamos el botón con más contraste?'),
    ),
    'S_MOOD_SUB': t(
      markTr('Formas, degradados, trazados y sombras para la nueva marca'),
    ),
    'S_GRADIENT': t(
      markTr('Degradado'),
    ),
    'S_SUN': t(
      markTr('Sol'),
    ),
    'S_DASHED': t(
      markTr('Discontinuo'),
    ),
    'S_ROTATED': t(
      markTr('Girado'),
    ),
    'S_WAVE': t(
      markTr('Onda'),
    ),
    // @@END@@
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      '  tx_$key = ${_pasString(value)};',
  ].join('\n');

  final docFilter = t(markTr('Diseños de OpenD++ (*.opend)|*.opend'));
  final design =
      TkDesign(
          width: 1360,
          height: 840,
          target: tkTargetPascal,
          props: {
            'title': app,
            'bg': '#1e1e1e',
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1300,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Treinta veces por segundo: el cursor del texto y las animaciones
          // del prototipo (sin nada que mover, no dibuja).
          _w(
            'Timer',
            'Tick',
            1260,
            8,
            32,
            32,
            {'interval': 33},
            {'command': 'Tick_timer'},
          ),
          _w('OpenDialog', 'DlgOpen', 1220, 8, 32, 32, {
            'title': t(markTr('Abrir un diseño')),
            'filter': docFilter,
          }),
          _w('SaveDialog', 'DlgSave', 1180, 8, 32, 32, {
            'title': t(markTr('Guardar el diseño')),
            'filter': docFilter,
          }),
          _w('OpenDialog', 'DlgImage', 1140, 8, 32, 32, {
            'title': t(markTr('Colocar una imagen')),
            'filter': t(
              markTr('Imágenes (*.png, *.jpg, *.jpeg, *.bmp)|*.png;*.jpg;*.jpeg;*.bmp'),
            ),
          }),
          _w('SaveDialog', 'DlgExport', 1100, 8, 32, 32, {
            'title': t(markTr('Exportar la selección')),
            'filter': t(markTr('Imagen PNG (*.png)|*.png\nDibujo SVG (*.svg)|*.svg')),
          }),
          _w('OpenDialog', 'DlgJson', 1060, 8, 32, 32, {
            'title': t(markTr('Importar un diseño JSON')),
            'filter': t(markTr('Diseño JSON (*.json)|*.json')),
          }),
          _w('SaveDialog', 'DlgJsonSave', 1020, 8, 32, 32, {
            'title': t(markTr('Guardar la plantilla JSON')),
            'filter': t(markTr('Diseño JSON (*.json)|*.json')),
            'filename': 'opend-plantilla.json',
          }),
          _w('Frame', 'Stage', 0, 0, 1360, 840, {'bg': '#1e1e1e'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'StageHint', 180, 400, 1000, 40, {
            'text': t(
              markTr(
                'El editor (lienzo, herramientas, inspector y capas) lo dibuja el código de Form1.pas',
              ),
            ),
            'fg': '#9ca3af',
            'bg': '#1e1e1e',
            'font_size': 15,
          })..parent = 'Stage',
        ]);

  final code = _openDCode
      .replaceFirst(
        '// @TITLE',
        '// ${t(markTr('OpenD++: un editor de diseño de interfaces en Pascal con Lazarus, con su propio motor de dibujo, componentes, prototipos y exportar a PNG y SVG.'))}',
      )
      .replaceFirst('  // @TEXTS', consts);
  return TkExample(
    'pascal_opend',
    t(markTr('OpenD++ (Pascal)')),
    t(
      markTr(
        'Un editor de diseño de interfaces en Object Pascal con Lazarus: marcos de móvil y escritorio, formas, pluma, texto e imágenes, capas, componentes con instancias, diseño automático, guías inteligentes, prototipos que se presentan, el código CSS y Flutter de cada capa y exportar a PNG y SVG, con las herramientas en otro sitio.',
      ),
    ),
    design,
    code,
  );
}
