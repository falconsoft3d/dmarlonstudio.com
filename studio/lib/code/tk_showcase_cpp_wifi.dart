part of 'tk_examples.dart';

// ------------------------------------------------ la wifi de casa (C++)
/// Un escáner de la wifi de casa en C++17 con FLTK: la red a la que está
/// conectado el equipo, las de alrededor (canal, banda, señal, seguridad y
/// estándar), los canales, el router (puertos abiertos, UPnP y la latencia)
/// y la contraseña (que se comprueba en el equipo y no se guarda), con un
/// diagnóstico y una nota de 0 a 100.
TkExample tkCppWifi(String Function(String) t) {
  final app = t(markTr('Wifi de casa'));
  String tc(String id) {
    final k = contextKey('wifi', id);
    final r = t(k);
    return r == k ? id : r;
  }

  // ---- menús: el texto del diseño y la ruta de cada opción para el código
  final mFile = t(markTr('Archivo')), mView = t(markTr('Ver'));
  final mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  final labels = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
    labels['L_$id'] = label;
  }

  void sep() => lines.add('  -');
  final sections = <String, String>{
    'S_DIAG': t(markTr('Diagnóstico')),
    'S_MINE': t(markTr('Mi red')),
    'S_NEARBY': t(markTr('Redes cercanas')),
    'S_CHANNELS': t(markTr('Canales')),
    'S_PASSWORD': tc(markTrc('wifi', 'Contraseña')),
    'S_ROUTER': t(markTr('Router')),
  };
  lines.add(mFile);
  item('SCAN', t(markTr('Analizar de nuevo')), mFile);
  item('PASSWORD', t(markTr('Comprobar la contraseña…')), mFile);
  sep();
  item('TXT', t(markTr('Guardar el informe como texto…')), mFile);
  item('COPY', t(markTr('Copiar el informe')), mFile);
  sep();
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mView);
  for (final s in sections.values) {
    lines.add('  $s');
  }
  sep();
  item('AUTO', t(markTr('Analizar cada minuto')), mView);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Wifi de casa')), mHelp);
  final texts = <String, String>{
    'APP': app,
    'M_VIEW': mView,
    ...paths,
    ...labels,
    ...sections,
    'DEC': t(markTr(',')),
    'DATE_FMT': t(markTr('%d/%m/%Y %H:%M')),
    'NONE': '—',
    'UNKNOWN': t(markTr('Desconocida')),
    'SEC_OPEN': t(markTr('Abierta (sin contraseña)')),
    'SEC_WPA2_MIXED': t(markTr('WPA/WPA2 (mixto)')),
    'SEC_ENTERPRISE': 'WPA Enterprise',
    'MY_NETWORK': t(markTr('Su red')),
    'NET_N': t(markTr('Red {0}')),
    'YOURS': t(markTr('la suya')),
    // El diagnóstico.
    'LV_OK': tc(markTrc('wifi', 'Bien')),
    'LV_TIP': tc(markTrc('wifi', 'Mejora')),
    'LV_WARN': tc(markTrc('wifi', 'Importante')),
    'LV_BAD': tc(markTrc('wifi', 'Grave')),
    'V_GOOD': t(markTr('Su wifi está bien')),
    'V_FAIR': t(markTr('Se puede mejorar')),
    'V_POOR': t(markTr('Tiene problemas')),
    'V_BAD': t(markTr('Es peligrosa')),
    'COUNTS': t(markTr('{0} graves · {1} importantes · {2} mejoras')),
    'CONNECTED_TO': t(markTr('Conectado a {0} · {1}')),
    'NAMES_HIDDEN': t(
      markTr(
        'macOS oculta los nombres de las redes a las apps sin permiso de ubicación.',
      ),
    ),
    'SCORE_LINE': t(markTr('Nota: {0} de 100 · {1}')),
    'F_NOT_CONNECTED': t(markTr('Este equipo no está conectado a una wifi')),
    'F_NOT_CONNECTED_D': t(
      markTr(
        'Conéctese a la red de su casa y pulse Analizar de nuevo. Con cable, la app solo ve las redes de alrededor.',
      ),
    ),
    'F_OPEN': t(markTr('Su wifi no tiene contraseña')),
    'F_OPEN_D': t(
      markTr(
        'Cualquiera cerca puede usar su conexión y ver lo que no vaya cifrado. Active WPA2 o WPA3 en el router con una contraseña larga.',
      ),
    ),
    'F_WEP': t(markTr('Su wifi usa WEP, que se rompe en minutos')),
    'F_WEP_D': t(
      markTr(
        'WEP está roto desde hace años. Cambie en el router a WPA2 (AES) o, mejor, a WPA3.',
      ),
    ),
    'F_WPA': t(markTr('Su wifi usa WPA, la primera versión')),
    'F_WPA_D': t(
      markTr(
        'WPA con TKIP tiene fallos conocidos. Cambie en el router a WPA2 (AES) o a WPA3.',
      ),
    ),
    'F_MIXED': t(markTr('Modo mixto WPA/WPA2 (con TKIP)')),
    'F_MIXED_D': t(
      markTr(
        'El router acepta también el cifrado antiguo (TKIP), más débil y más lento. Elija solo WPA2 con AES (CCMP), o WPA2/WPA3.',
      ),
    ),
    'F_WPA2': t(markTr('WPA2: segura con una buena contraseña')),
    'F_WPA2_D': t(
      markTr(
        'Si su router lo permite, active WPA2/WPA3 (transición): los equipos nuevos usarán WPA3 y los viejos seguirán entrando.',
      ),
    ),
    'F_WPA3T': t(markTr('WPA2/WPA3: muy bien')),
    'F_WPA3T_D': t(
      markTr(
        'Los equipos que pueden usan WPA3, que protege aunque alguien capture la conexión; los demás, WPA2.',
      ),
    ),
    'F_WPA3': t(markTr('WPA3: lo más seguro')),
    'F_WPA3_D': t(markTr('Su wifi usa el cifrado más moderno.')),
    'F_ENT': 'WPA Enterprise',
    'F_ENT_D': t(
      markTr(
        'Cada persona entra con su propia cuenta: lo habitual en empresas.',
      ),
    ),
    'F_SEC_UNKNOWN': t(markTr('No se sabe qué cifrado usa')),
    'F_SEC_UNKNOWN_D': t(
      markTr(
        'El sistema no ha dicho qué seguridad tiene la red. Compruébelo en la página del router.',
      ),
    ),
    'F_PW_ASK': t(markTr('Compruebe la contraseña de la wifi')),
    'F_PW_ASK_D': t(
      markTr(
        'Escríbala en la sección Contraseña: se comprueba en este equipo y no se guarda ni se envía.',
      ),
    ),
    'F_PW_BAD': t(markTr('La contraseña es muy débil')),
    'F_PW_WEAK': t(markTr('La contraseña es débil')),
    'F_PW_OK': t(markTr('La contraseña es aceptable')),
    'F_PW_STRONG': t(markTr('La contraseña es fuerte')),
    'F_PW_TIME': t(
      markTr(
        'Con la conexión capturada, cien tarjetas gráficas la adivinarían en {0}.',
      ),
    ),
    'F_SIGNAL_GOOD': t(markTr('Buena señal')),
    'F_SIGNAL_GOOD_D': t(markTr('{0}: la wifi llega con fuerza hasta aquí.')),
    'F_SIGNAL_FAIR': t(markTr('Señal justa')),
    'F_SIGNAL_FAIR_D': t(
      markTr(
        '{0}: va bien para navegar, pero el vídeo y las videollamadas pueden cortarse. Acérquese al router o súbalo a un sitio alto y despejado.',
      ),
    ),
    'F_SIGNAL_WEAK': t(markTr('Señal débil')),
    'F_SIGNAL_WEAK_D': t(
      markTr(
        '{0}: la wifi llega con poca fuerza. Ponga el router en un sitio más central y sin obstáculos (paredes, muebles, el microondas) o añada un repetidor o una red mallada.',
      ),
    ),
    'F_NOISE': t(markTr('Hay mucho ruido')),
    'F_NOISE_D': t(
      markTr(
        'La señal está solo {0} dB por encima del ruido (lo bueno son más de 25). Aleje el router de microondas, teléfonos inalámbricos y otros aparatos.',
      ),
    ),
    'F_BAND24': t(markTr('Está en la banda de 2,4 GHz')),
    'F_BAND24_D': t(
      markTr(
        'Su equipo admite 5 GHz, más rápida y menos llena. Si el router la tiene, conéctese a ella (a veces es la red que acaba en «5G»).',
      ),
    ),
    'F_BAND24_D2': t(
      markTr(
        'La banda de 2,4 GHz llega más lejos, pero es más lenta y está más llena. Si su router tiene 5 GHz, úsela cerca de él.',
      ),
    ),
    'F_WIDE24': t(markTr('Ancho de 40 MHz en 2,4 GHz')),
    'F_WIDE24_D': t(
      markTr(
        'Con tantas redes alrededor, 40 MHz en 2,4 GHz pisa a los vecinos y empeora a todos. Ponga 20 MHz en el router.',
      ),
    ),
    'F_NARROW5': t(markTr('Ancho de 20 MHz en 5 GHz')),
    'F_NARROW5_D': t(
      markTr(
        'En 5 GHz hay sitio: con 80 MHz la wifi puede ir hasta cuatro veces más rápida.',
      ),
    ),
    'F_CROWDED': t(markTr('El canal {0} está lleno')),
    'F_CROWDED_D': t(
      markTr(
        'Lo comparten redes vecinas (ocupación {0}). En el router, cambie al canal {1}, el más libre ahora mismo.',
      ),
    ),
    'F_CHANNEL_OK': t(markTr('El canal {0} está bien')),
    'F_CHANNEL_OK_D': t(markTr('Las redes de alrededor apenas lo pisan.')),
    'F_OLD': t(markTr('Un estándar antiguo')),
    'F_OLD_D': t(
      markTr(
        'La conexión es {0}. Un router con Wi-Fi 5 (ac) o Wi-Fi 6 (ax) iría bastante más rápido.',
      ),
    ),
    'F_SLOW_LINK': t(markTr('La conexión con el router es lenta')),
    'F_SLOW_LINK_D': t(
      markTr(
        '{0} Mbps entre este equipo y el router: quizá menos de lo que da su internet. Acérquese o use 5 GHz.',
      ),
    ),
    'F_TELNET': t(markTr('El router tiene Telnet abierto')),
    'F_TELNET_D': t(
      markTr(
        'Telnet deja entrar al router sin cifrar. Desactívelo en su configuración o pida al operador que lo cierre.',
      ),
    ),
    'F_FTP': t(markTr('El router tiene FTP abierto')),
    'F_FTP_D': t(
      markTr('Comparte archivos sin cifrar. Si no lo usa, desactívelo.'),
    ),
    'F_HTTP': t(markTr('La página del router va sin cifrar')),
    'F_HTTP_D': t(
      markTr(
        'La configuración (http://{0}) no usa HTTPS: la contraseña de administrador viaja en claro por la wifi. Cámbiela por una propia y no la use desde redes de otros.',
      ),
    ),
    'F_UPNP': t(markTr('UPnP está activado')),
    'F_UPNP_D': t(
      markTr(
        'Deja que cualquier programa de la casa abra puertos hacia internet sin preguntar. Si no lo necesita (consolas, algunos juegos), desactívelo.',
      ),
    ),
    'F_LOSS': t(markTr('Se pierden paquetes')),
    'F_LOSS_D': t(
      markTr(
        'Un {0} % de los paquetes al router no llega: hay interferencias o la señal es débil.',
      ),
    ),
    'F_LATENCY': t(markTr('El router tarda en responder')),
    'F_LATENCY_D': t(
      markTr(
        '{0} ms hasta el router (lo normal son menos de 10): la wifi está saturada o la señal es débil.',
      ),
    ),
    'F_ROUTER_OK': t(markTr('El router no abre servicios peligrosos')),
    'F_ROUTER_OK_D': t(markTr('Ni Telnet ni FTP, y no anuncia UPnP.')),
    'F_OPEN_NEAR': t(markTr('{0} redes abiertas o con WEP cerca')),
    'F_OPEN_NEAR_D': t(
      markTr(
        'No se conecte a ellas sin una VPN: lo que no vaya cifrado se puede ver.',
      ),
    ),
    // Las filas.
    'K_NAME': t(markTr('Nombre')),
    'K_SECURITY': t(markTr('Seguridad')),
    'K_CHANNEL': t(markTr('Canal')),
    'K_BAND': t(markTr('Banda')),
    'K_WIDTH': t(markTr('Ancho')),
    'K_SIGNAL': t(markTr('Señal')),
    'K_STANDARD': t(markTr('Estándar')),
    'K_NOISE': t(markTr('Ruido')),
    'K_RATE': t(markTr('Velocidad de la conexión')),
    'K_COUNTRY': t(markTr('País de la wifi')),
    'K_IP': t(markTr('Dirección IP')),
    'K_ROUTER': t(markTr('Router')),
    'K_ADAPTER': t(markTr('Adaptador')),
    'K_PING': t(markTr('Tiempo hasta el router')),
    'K_LOSS': t(markTr('Paquetes perdidos')),
    'SNR': t(markTr('señal/ruido {0} dB')),
    'SIG_GOOD': t(markTr('Buena: llega con fuerza')),
    'SIG_FAIR': t(markTr('Justa: el vídeo puede cortarse')),
    'SIG_WEAK': t(markTr('Débil: acérquese al router')),
    'NEARBY_INTRO': t(
      markTr(
        'Se oyen {0} redes más desde aquí, de la más fuerte a la más débil.',
      ),
    ),
    'NEARBY_N': t(markTr('Redes cercanas: {0}')),
    'CHANNELS_INTRO': t(
      markTr(
        'Cada red es una montaña: su ancho es el de su canal y su altura, la señal que llega aquí. Las que se tocan se estorban. La suya va en azul y, si hay un canal mejor, sale en verde.',
      ),
    ),
    'BEST_HERE': t(markTr('mejor: {0}')),
    'NO_NETWORKS_BAND': t(markTr('Ninguna red en esta banda.')),
    // La contraseña.
    'PW_INTRO': t(
      markTr(
        'Escriba la contraseña de su wifi y la app le dirá lo fuerte que es y cuánto tardaría alguien en adivinarla. Se comprueba aquí: no se guarda, no se envía y no sale en el informe.',
      ),
    ),
    'PW_CHECK': t(markTr('Comprobar la contraseña…')),
    'PW_AGAIN': t(markTr('Comprobar otra contraseña…')),
    'PW_ASK': t(
      markTr(
        'La contraseña de la wifi (se comprueba en este equipo y no se guarda):',
      ),
    ),
    'PW_L0': tc(markTrc('wifi', 'Fuerte')),
    'PW_L1': tc(markTrc('wifi', 'Aceptable')),
    'PW_L2': tc(markTrc('wifi', 'Débil')),
    'PW_L3': tc(markTrc('wifi', 'Muy débil')),
    'PW_LENGTH': t(markTr('Caracteres')),
    'PW_KINDS': t(markTr('Tipos de caracteres')),
    'PW_KINDS_N': t(
      markTr('{0} de 4 (minúsculas, mayúsculas, números y símbolos)'),
    ),
    'PW_BITS': t(markTr('Fuerza estimada')),
    'PW_GPU': t(markTr('Con una tarjeta gráfica')),
    'PW_FARM': t(markTr('Con cien tarjetas gráficas')),
    'PW_COMMON': t(
      markTr(
        'Es una de las contraseñas más usadas: es lo primero que se prueba.',
      ),
    ),
    'PW_TOO_SHORT': t(markTr('Tiene menos de 8 caracteres: WPA no la acepta.')),
    'PW_SHORT': t(
      markTr('Tiene menos de 12 caracteres: mejor 14 o más, o una frase.'),
    ),
    'PW_REPEATS': t(markTr('Repite caracteres seguidos.')),
    'PW_DOUBLED': t(markTr('Es la misma mitad dos veces.')),
    'PW_SEQUENCE': t(
      markTr(
        'Lleva una secuencia del teclado o del abecedario ({0} seguidos).',
      ),
    ),
    'PW_YEAR': t(
      markTr('Lleva un año: las fechas son de lo primero que se prueba.'),
    ),
    'PW_SSID': t(markTr('Lleva el nombre de la red.')),
    'PW_WORD': t(
      markTr('Es una palabra conocida con números: se adivina enseguida.'),
    ),
    'PW_DIGITS': t(markTr('Solo tiene números.')),
    'PW_ONE_KIND': t(markTr('Solo usa un tipo de carácter.')),
    'PW_GOOD': t(
      markTr(
        'Bien: larga y sin patrones. Guárdela en un gestor de contraseñas.',
      ),
    ),
    'PW_PRIVACY': t(
      markTr(
        'La contraseña se olvida al comprobarla. El tiempo supone que alguien ha capturado la conexión de un equipo a su wifi (el saludo de WPA2) y prueba contraseñas: unos 2,5 millones por segundo con una tarjeta gráfica actual.',
      ),
    ),
    'PW_SUMMARY': t(
      markTr(
        '{0} caracteres · {1} bits · {2} con una tarjeta gráfica · {3} con cien',
      ),
    ),
    'T_INSTANT': t(markTr('menos de un segundo')),
    'T_SECOND': t(markTr('{0} segundo')),
    'T_SECONDS': t(markTr('{0} segundos')),
    'T_MINUTE': t(markTr('{0} minuto')),
    'T_MINUTES': t(markTr('{0} minutos')),
    'T_HOUR': t(markTr('{0} hora')),
    'T_HOURS': t(markTr('{0} horas')),
    'T_DAY': t(markTr('{0} día')),
    'T_DAYS': t(markTr('{0} días')),
    'T_MONTH': t(markTr('{0} mes')),
    'T_MONTHS': t(markTr('{0} meses')),
    'T_YEAR': t(markTr('{0} año')),
    'T_YEARS': t(markTr('{0} años')),
    'T_CENTURY': t(markTr('{0} siglo')),
    'T_CENTURIES': t(markTr('{0} siglos')),
    'T_MILLENNIA': t(markTr('más de cien mil años')),
    'T_UNIVERSE': t(markTr('más que la edad del universo')),
    // El router.
    'ROUTER_NONE': t(
      markTr(
        'No se ha podido revisar el router (sin conexión o sin su dirección).',
      ),
    ),
    'UPNP_ON': t(markTr('Activado')),
    'UPNP_OFF': t(markTr('No responde')),
    'PORTS_TITLE': t(markTr('Lo que el router deja abierto en la red de casa')),
    'PORT_OPEN': tc(markTrc('wifi', 'Abierto')),
    'PORT_CLOSED': tc(markTrc('wifi', 'Cerrado')),
    'PN_FTP': t(markTr('Archivos sin cifrar')),
    'PN_SSH': t(markTr('Acceso remoto cifrado')),
    'PN_TELNET': t(markTr('Acceso remoto sin cifrar: ciérrelo')),
    'PN_HTTP': t(markTr('La página de configuración, sin cifrar')),
    'PN_HTTPS': t(markTr('La página de configuración, cifrada')),
    'PN_TR069': t(markTr('La gestión remota del operador')),
    'ROUTER_HINT': t(
      markTr(
        'Solo se prueba el router de esta red, desde dentro de casa. Para lo que se ve desde internet, revise en la página del router el acceso remoto y la redirección de puertos.',
      ),
    ),
    // La ventana.
    'SCANNING': t(markTr('Analizando la wifi…')),
    'WAITING': t(markTr('Pulse Analizar de nuevo.')),
    'NOT_CONNECTED': t(markTr('Sin wifi')),
    'SIDE_INFO': t(markTr('{0} GHz · canal {1} · {2} dBm')),
    'SIDE_SCORE': t(markTr('Nota {0} · {1}')),
    'STATUS': t(markTr('Analizada a las {0} · {1}')),
    'STATUS_AUTO': t(markTr('se repite cada minuto')),
    'STATUS_MANUAL': t(markTr('análisis automático en pausa')),
    'ERR_SCAN': t(markTr('No se pudo leer la wifi de este equipo.')),
    'ERR_SAVE': t(markTr('No se pudo guardar: {0}')),
    'SAVED_TXT': t(markTr('Texto guardado: {0}')),
    'COPIED_REPORT': t(markTr('El informe está en el portapapeles')),
    'REPORT_FILE': t(markTr('Informe de la wifi')),
    'TXT_FILTER': t(markTr('Texto')),
    'HOW_TEXT': t(
      markTr(
        'Al abrirse, y cada minuto, la app lee la wifi de este equipo: en macOS con system_profiler e ipconfig, en Windows con netsh wlan y en Linux con nmcli. Ve la red a la que está conectado, las de alrededor (canal, banda, ancho, señal, seguridad y estándar) y prueba desde dentro de casa qué deja abierto el router (Telnet, FTP, la página de configuración, UPnP) y cuánto tarda en responder.\n\nCon todo eso hace un diagnóstico con una nota de 0 a 100: lo grave, lo importante y lo que se puede mejorar, con qué hacer en cada caso (por ejemplo, a qué canal cambiar). Haga clic en cada punto para ver el detalle.\n\nEn Contraseña puede escribir la de su wifi: se comprueba en este equipo (lo larga que es, si es de las más usadas, si lleva el nombre de la red, años o secuencias del teclado) y se estima cuánto tardarían en adivinarla. No se guarda, no se envía y no sale en el informe.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: un escáner de la wifi de casa hecho en C++17 con FLTK {0}. La ventana, la barra lateral y el menú se diseñaron en el Diseñador del estudio; el análisis, el diagnóstico y los dibujos están en el código de Form1.cpp.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const side = '#f4f6fb';
  TkWidget lbl(
    String name,
    int x,
    int y,
    int w,
    int h,
    String text, [
    Map<String, Object?> extra = const {},
  ]) => _w('Label', name, x, y, w, h, {
    'text': text,
    'bg': side,
    'fg': '#1f2937',
    'anchor': 'w',
    ...extra,
  })..parent = 'Side';
  final design =
      TkDesign(
          width: 1180,
          height: 760,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': '#ffffff',
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
          // Cada segundo: el mensaje de la barra y, cada minuto, otro análisis.
          _w(
            'Timer',
            'Tick',
            1080,
            8,
            32,
            32,
            {'interval': 1000},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Side', 0, 0, 260, 736, {'bg': side}),
          lbl('LblNet', 16, 14, 228, 26, t(markTr('Mi wifi')), {
            'font_size': 16,
            'font_bold': true,
          }),
          lbl('LblInfo', 16, 42, 228, 40, '', {
            'font_size': 11,
            'fg': '#6b7280',
          }),
          _w(
            'Listbox',
            'Sections',
            16,
            90,
            228,
            200,
            {'items': sections.values.join('\n'), 'font_size': 14},
            {'select': 'Sections_select'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnScan',
            16,
            304,
            228,
            30,
            {'text': t(markTr('Analizar de nuevo'))},
            {'command': 'BtnScan_click'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnPassword',
            16,
            342,
            228,
            36,
            {
              'text': t(markTr('Comprobar la contraseña…')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnPassword_click'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnCopy',
            16,
            388,
            228,
            30,
            {'text': t(markTr('Copiar el informe'))},
            {'command': 'BtnCopy_click'},
          )..parent = 'Side',
          lbl(
            'LblHint',
            16,
            432,
            228,
            120,
            t(
              markTr(
                'Analiza la red a la que está conectado, las de alrededor y el router. La contraseña se comprueba en este equipo y no se guarda.',
              ),
            ),
            {'font_size': 11, 'fg': '#6b7280'},
          ),
          _w('Frame', 'Results', 260, 0, 920, 736, {'bg': '#ffffff'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'ResultsHint', 160, 340, 600, 40, {
            'text': t(
              markTr(
                'El diagnóstico, las redes, los canales y el router los dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#ffffff',
            'font_size': 14,
          })..parent = 'Results',
          _w('StatusBar', 'Status', 0, 736, 1180, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Wifi de casa en C++ con FLTK: analiza la red, las de alrededor, los canales y el router, comprueba la contraseña y da un diagnóstico.'))}
$_wifiIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_wifiCode''';
  return TkExample(
    'cpp_wifi',
    t(markTr('Wifi de casa (C++)')),
    t(
      markTr(
        'Un escáner de la wifi de casa nativo en C++ con FLTK: su red, las de alrededor, los canales, el router y la contraseña, con un diagnóstico de lo que falla y lo que se puede mejorar.',
      ),
    ),
    design,
    code,
  );
}

const _wifiIncludes = r'''#include <algorithm>
#include <chrono>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <functional>
#include <string>
#include <thread>
#include <utility>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#else
#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
''';
