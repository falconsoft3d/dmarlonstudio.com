part of 'tk_examples.dart';

// ------------------------------------------------ DMarlonPass (C++)
/// Un gestor de contraseñas compatible con KeePass, en C++17 con FLTK y sin
/// bibliotecas: abre y guarda archivos .kdbx (KDBX 4; también abre KDBX 3.1)
/// con AES-256 o ChaCha20 y Argon2d, Argon2id o AES-KDF, como KeePass y
/// KeePassXC. Grupos, entradas con historial, papelera, generador, revisión
/// de seguridad, archivo de clave y bloqueo automático.
TkExample tkCppPass(String Function(String) t) {
  final app = t(markTr('DMarlonPass'));
  final mFile = t(markTr('Archivo')),
      mEntry = t(markTr('Contraseñas')),
      mTools = t(markTr('Herramientas')),
      mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('NEW', t(markTr('Nueva base de datos…')), mFile);
  item('OPEN', t(markTr('Abrir…')), mFile);
  item('SAVE', t(markTr('Guardar')), mFile);
  item('SAVE_AS', t(markTr('Guardar como…')), mFile);
  lines.add('  -');
  item('LOCK', t(markTr('Bloquear')), mFile);
  item('CLOSE', t(markTr('Cerrar la base de datos')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mEntry);
  item('NEW_ENTRY', t(markTr('Nueva entrada')), mEntry);
  item('NEW_GROUP', t(markTr('Nuevo grupo…')), mEntry);
  item('EDIT', t(markTr('Editar la entrada')), mEntry);
  item('DELETE', t(markTr('Borrar la entrada')), mEntry);
  lines.add('  -');
  item('COPY_USER', t(markTr('Copiar el usuario')), mEntry);
  item('COPY_PASS', t(markTr('Copiar la contraseña')), mEntry);
  item('OPEN_URL', t(markTr('Abrir la URL')), mEntry);
  lines.add(mTools);
  item('GENERATOR', t(markTr('Generador de contraseñas…')), mTools);
  item('AUDIT', t(markTr('Revisión de seguridad')), mTools);
  item('MASTER', t(markTr('Cambiar la clave maestra…')), mTools);
  item('SECURITY', t(markTr('Seguridad de la base de datos…')), mTools);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de DMarlonPass')), mHelp);
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'DMarlonPass guarda sus contraseñas en un archivo .kdbx cifrado, el mismo formato de KeePass y KeePassXC: puede abrir con DMarlonPass la base de datos que ya tiene y seguir usándola con esos programas.\n\nCree una base de datos con una contraseña maestra (y, si quiere, un archivo de clave) o abra una existente. A la izquierda están los grupos; en medio, las entradas del grupo; a la derecha, la elegida: copie el usuario o la contraseña con un clic (el portapapeles se vacía solo a los 20 segundos), vea la contraseña con 👁 o abra su web.\n\n«+ Entrada» propone una contraseña fuerte; el generador hace otras a su medida. La revisión de seguridad enseña las contraseñas vacías, débiles, repetidas o que llevan más de un año sin cambiar. Al editar, la versión anterior queda en el historial; lo que borra va a la papelera.\n\nAtajos: ⌘N nueva entrada, ⌘E editar, ⌘B copiar el usuario, ⌘C copiar la contraseña, ⌘F buscar, ⌘S guardar, ⌘L bloquear. Tras 5 minutos sin usarla, la base de datos se bloquea sola (guardando antes los cambios) y se borra de la memoria todo lo descifrado.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, el menú, la barra de arriba, el campo de la contraseña maestra y los diálogos de abrir y guardar se diseñaron en el Diseñador del estudio. La criptografía (AES-256, ChaCha20, Salsa20, SHA-256, SHA-512, HMAC, BLAKE2b y Argon2) y el formato KDBX están escritos en el propio código, sin bibliotecas, y se comprueban con los vectores oficiales y con archivos de KeePassXC y pykeepass. Compatible con KeePass, no es KeePass.',
      ),
    ),
    'WELCOME_SUB': t(markTr('Sus contraseñas, cifradas en un archivo que solo abre usted.')),
    'CREATE_DB': t(markTr('Crear una base de datos nueva')),
    'OPEN_DB': t(markTr('Abrir una existente (.kdbx)')),
    'COMPAT_NOTE': t(
      markTr(
        'Compatible con KeePass y KeePassXC: KDBX 4, AES-256 o ChaCha20, Argon2.',
      ),
    ),
    'MASTER_LABEL': t(markTr('Contraseña maestra')),
    'NO_KEY_FILE': t(markTr('Sin archivo de clave')),
    'CHOOSE_KEY_FILE': t(markTr('Usar un archivo de clave…')),
    'REMOVE_KEY_FILE': t(markTr('Quitar')),
    'OPENING': t(markTr('Abriendo…')),
    'OTHER_DB': t(markTr('Abrir otra…')),
    'NEW_DB_LINK': t(markTr('Crear una nueva…')),
    'GROUPS': t(markTr('GRUPOS')),
    'AUDIT': t(markTr('Revisión de seguridad')),
    'AUDIT_N': t(markTr('{0} por revisar')),
    'AUDIT_OK': t(markTr('Todo en orden')),
    'AUDIT_EMPTY': t(markTr('Ninguna contraseña débil, repetida ni vieja. ¡Bien hecho!')),
    'SEARCH_RESULTS': t(markTr('Resultados de la búsqueda')),
    'SEARCH_EMPTY': t(markTr('No hay entradas con ese texto')),
    'GROUP_EMPTY': t(markTr('Este grupo está vacío')),
    'ADD_ENTRY_BTN': t(markTr('+ Añadir una entrada')),
    'ENTRIES_ONE': t(markTr('1 entrada')),
    'ENTRIES_N': t(markTr('{0} entradas guardadas')),
    'NO_TITLE': t(markTr('(sin título)')),
    'PICK_ENTRY': t(markTr('Elija una entrada para ver sus datos')),
    'F_TITLE': t(markTr('TÍTULO')),
    'F_GROUP': t(markTr('GRUPO')),
    'F_USER': t(markTr('USUARIO')),
    'F_PASSWORD': t(markTr('CONTRASEÑA')),
    'F_URL': t(markTr('URL')),
    'F_NOTES': t(markTr('NOTAS')),
    'STRENGTH_T': t(markTr('{0} · {1} bits')),
    'S_VERY_WEAK': t(markTr('Muy débil')),
    'S_WEAK': t(markTr('Débil')),
    'S_FAIR': t(markTr('Aceptable')),
    'S_STRONG': t(markTr('Fuerte')),
    'S_VERY_STRONG': t(markTr('Muy fuerte')),
    'I_EMPTY_T': t(markTr('Sin contraseña')),
    'I_WEAK_T': t(markTr('Débil')),
    'I_REUSED_T': t(markTr('Repetida en {0} entradas')),
    'I_OLD_T': t(markTr('Más de un año sin cambiar')),
    'DATES': t(markTr('Creada: {0} · Cambiada: {1}')),
    'HISTORY_N': t(markTr('{0} versiones en el historial')),
    'EDIT_BTN': t(markTr('✏️ Editar')),
    'DELETE_BTN': t(markTr('🗑 Borrar')),
    'NEW_ENTRY_TITLE': t(markTr('Nueva entrada')),
    'EDIT_ENTRY_TITLE': t(markTr('Editar la entrada')),
    'CANCEL': t(markTr('Cancelar')),
    'ACCEPT': t(markTr('Aceptar')),
    'SAVE_BTN': t(markTr('Guardar')),
    'DONT_SAVE': t(markTr('No guardar')),
    'YES': t(markTr('Sí')),
    'NO': t(markTr('No')),
    'SAVE': t(markTr('💾 Guardar')),
    'SAVE_DIRTY': t(markTr('💾 Guardar *')),
    'GEN_TITLE': t(markTr('Generador de contraseñas')),
    'GEN_LENGTH': t(markTr('Longitud')),
    'GEN_AMBIGUOUS': t(markTr('Sin caracteres que se confunden (l, 1, O, 0…)')),
    'GEN_AGAIN': t(markTr('🔄 Otra')),
    'GEN_COPY': t(markTr('Copiar')),
    'GEN_USE': t(markTr('Usar')),
    'NEW_DB_TITLE': t(markTr('Base de datos nueva')),
    'MASTER_TITLE': t(markTr('Cambiar la clave maestra')),
    'SECURITY_TITLE': t(markTr('Seguridad de la base de datos')),
    'DB_NAME': t(markTr('NOMBRE')),
    'DB_PASS': t(markTr('CONTRASEÑA MAESTRA')),
    'DB_PASS2': t(markTr('REPITA LA CONTRASEÑA')),
    'DB_KEYFILE': t(markTr('Crear también un archivo de clave (hará falta para abrirla)')),
    'DB_SECURITY': t(markTr('CIFRADO')),
    'DB_CIPHER': t(markTr('Cifrado')),
    'DB_KDF': t(markTr('Derivación de la clave')),
    'DB_TIME': t(markTr('Tiempo para abrir')),
    'KDF_ARGON2D': t(markTr('Argon2d (como KeePassXC)')),
    'KDF_ARGON2ID': t(markTr('Argon2id')),
    'KDF_AES': t(markTr('AES-KDF (KeePass antiguo)')),
    'TIME_HALF': t(markTr('Medio segundo')),
    'TIME_ONE': t(markTr('Un segundo (recomendado)')),
    'TIME_TWO': t(markTr('Dos segundos (más seguro)')),
    'DEFAULT_DB_NAME': t(markTr('Mis contraseñas')),
    'G_GENERAL': t(markTr('General')),
    'G_EMAIL': t(markTr('Correo')),
    'G_BANKING': t(markTr('Bancos')),
    'G_WORK': t(markTr('Oficina')),
    'G_SOCIAL': t(markTr('Redes sociales')),
    'RECYCLE_BIN': t(markTr('Papelera')),
    'NEW_GROUP_Q': t(markTr('Nombre del grupo nuevo:')),
    'RENAME_Q': t(markTr('Nombre del grupo:')),
    'NEW_SUBGROUP': t(markTr('Nuevo subgrupo…')),
    'RENAME_GROUP': t(markTr('Cambiar el nombre…')),
    'DELETE_GROUP': t(markTr('Borrar el grupo')),
    'DELETE_GROUP_Q': t(markTr('¿Borrar el grupo «{0}» con todo lo que tiene? Irá a la papelera.')),
    'DELETE_Q': t(markTr('¿Llevar «{0}» a la papelera?')),
    'DELETE_FOREVER_Q': t(markTr('¿Borrar «{0}» para siempre? No se puede deshacer.')),
    'DELETED': t(markTr('A la papelera')),
    'DELETED_FOREVER': t(markTr('Borrada para siempre')),
    'COPY_USER': t(markTr('Copiar el usuario')),
    'COPY_PASS': t(markTr('Copiar la contraseña')),
    'OPEN_URL': t(markTr('Abrir la URL')),
    'MOVE_TO': t(markTr('Mover a…')),
    'COPIED': t(markTr('Copiado: el portapapeles se vacía en {0} s')),
    'COPIED_PASS': t(markTr('Contraseña copiada: el portapapeles se vacía en {0} s')),
    'CLIP_CLEARED': t(markTr('Portapapeles vaciado')),
    'ADDED': t(markTr('Entrada añadida (sin guardar)')),
    'SAVED': t(markTr('Guardado')),
    'CREATED': t(markTr('Base de datos creada y guardada')),
    'CREATED_KEYFILE': t(markTr('Creada. Guarde bien el archivo de clave: {0}')),
    'OPENED': t(markTr('Base de datos abierta')),
    'OPENED_V3': t(markTr('Abierta (KDBX 3.1): al guardar pasará a KDBX 4, que también abre KeePass 2.35 o posterior')),
    'AUTO_LOCKED': t(markTr('Bloqueada tras unos minutos sin uso')),
    'MASTER_CHANGED': t(markTr('Clave maestra cambiada')),
    'ASK_SAVE': t(markTr('Hay cambios sin guardar. ¿Guardarlos?')),
    'ERR_KEY': t(markTr('Contraseña o archivo de clave incorrectos')),
    'ERR_FORMAT': t(markTr('No es una base de datos de KeePass (.kdbx)')),
    'ERR_CORRUPT': t(markTr('El archivo está dañado o se ha modificado')),
    'ERR_CIPHER': t(markTr('Cifrado no soportado (por ejemplo, Twofish)')),
    'ERR_VERSION': t(markTr('Versión de KDBX no soportada')),
    'ERR_READ': t(markTr('No se pudo leer el archivo')),
    'ERR_KEYFILE': t(markTr('No se pudo leer el archivo de clave')),
    'ERR_WRITE': t(markTr('No se pudo guardar el archivo')),
    'ERR_NO_PASS': t(markTr('Ponga una contraseña maestra (o un archivo de clave)')),
    'ERR_PASS_MATCH': t(markTr('Las dos contraseñas no coinciden')),
    'STATUS_ENTRIES': t(markTr('{0} entradas guardadas')),
    'STATUS_SECURITY': t(markTr('{0} + {1}')),
    'STATUS_WELCOME': t(markTr('Cree una base de datos o abra un archivo .kdbx')),
    'DEMO_DB': t(markTr('Personal')),
    'DEMO_E1': t(markTr('Correo personal')),
    'DEMO_E2': t(markTr('Correo del trabajo')),
    'DEMO_E3': t(markTr('Banco')),
    'DEMO_E4': t(markTr('Tarjeta de crédito')),
    'DEMO_E5': t(markTr('VPN de la empresa')),
    'DEMO_E6': t(markTr('Intranet')),
    'DEMO_E7': t(markTr('Red social')),
    'DEMO_E8': t(markTr('Wifi de casa')),
    'DEMO_N1': t(markTr('Recuperación: el móvil acabado en 42')),
    'DEMO_N3': t(markTr('Firma electrónica: el código que llega por SMS.\nOficina: calle Mayor 12.')),
    'DEMO_N5': t(markTr('Servidor: vpn.empresa.ejemplo, puerto 443')),
    'DEMO_N8': t(markTr('Red: Casa-5G')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const side = '#1c2233';
  final filter = t(markTr('Bases de datos de KeePass (*.kdbx)|*.kdbx'));
  final design =
      TkDesign(
          width: 1100,
          height: 700,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': '#f5f6fa',
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
          _w('OpenDialog', 'DlgOpen', 960, 8, 32, 32, {
            'title': t(markTr('Abrir una base de datos de KeePass')),
            'filter': filter,
          }),
          _w('SaveDialog', 'DlgSave', 920, 8, 32, 32, {
            'title': t(markTr('Guardar la base de datos')),
            'filter': filter,
          }),
          _w('OpenDialog', 'DlgKey', 880, 8, 32, 32, {
            'title': t(markTr('Elegir el archivo de clave')),
          }),
          _w('Frame', 'Top', 0, 0, 1100, 56, {'bg': '#ffffff'}),
          _w('Label', 'LblApp', 16, 12, 220, 32, {
            'text': t(markTr('🛡 DMarlonPass')),
            'bg': '#ffffff',
            'fg': '#1d2233',
            'font_bold': true,
            'font_size': 17,
          })..parent = 'Top',
          _w('Entry', 'Search', 252, 12, 360, 32, {'font_size': 14})
            ..parent = 'Top',
          _w(
            'Button',
            'BtnAdd',
            624,
            12,
            110,
            32,
            {
              'text': t(markTr('+ Entrada')),
              'bg': '#3b6cf6',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnAdd_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnGen',
            742,
            12,
            124,
            32,
            {'text': t(markTr('🎲 Generador'))},
            {'command': 'BtnGen_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnLock',
            874,
            12,
            104,
            32,
            {'text': t(markTr('🔒 Bloquear'))},
            {'command': 'BtnLock_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnSave',
            986,
            12,
            100,
            32,
            {'text': t(markTr('💾 Guardar'))},
            {'command': 'BtnSave_click'},
          )..parent = 'Top',
          _w('Frame', 'Board', 0, 56, 1100, 620, {'bg': side}),
          _w('Label', 'BoardHint', 250, 60, 600, 40, {
            'text': t(
              markTr(
                'Los grupos, las entradas y el bloqueo los dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#8d95ab',
            'bg': side,
            'font_size': 14,
          })..parent = 'Board',
          _w(
            'Password',
            'Master',
            370,
            300,
            360,
            38,
            {'font_size': 16},
            {'enter_key': 'Master_enter'},
          )..parent = 'Board',
          _w(
            'Button',
            'BtnUnlock',
            370,
            350,
            360,
            42,
            {
              'text': t(markTr('🔓 Desbloquear')),
              'bg': '#3b6cf6',
              'fg': '#ffffff',
              'font_bold': true,
              'font_size': 15,
            },
            {'command': 'BtnUnlock_click'},
          )..parent = 'Board',
          _w('StatusBar', 'Status', 0, 676, 1100, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('DMarlonPass en C++ con FLTK: un gestor de contraseñas compatible con KeePass (KDBX 4: AES-256 o ChaCha20, Argon2 y HMAC-SHA-256), sin bibliotecas.'))}
$_passIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_passCode''';
  return TkExample(
    'cpp_pass',
    t(markTr('DMarlonPass (C++)')),
    t(
      markTr(
        'Un gestor de contraseñas compatible con KeePass, nativo en C++ con FLTK y sin bibliotecas: abre y guarda archivos .kdbx (KDBX 4) con AES-256 o ChaCha20 y Argon2, como KeePass y KeePassXC. Grupos, historial, papelera, generador, revisión de seguridad, archivo de clave y bloqueo automático.',
      ),
    ),
    design,
    code,
  );
}
