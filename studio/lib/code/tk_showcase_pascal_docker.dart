part of 'tk_examples.dart';

// ------------------------------------ Docker en la barra de menús (Pascal)
/// Una app de Object Pascal (Lazarus) que vive en la barra de menús de macOS
/// (en Windows, en el área de notificación): su icono abre un menú con los
/// contenedores de Docker en marcha, agrupados por proyecto de Compose, y
/// desde ahí se abren sus direcciones o se paran. La ventana del diseño es
/// un panel con la lista, que se abre desde el menú.
TkExample tkPascalDocker(String Function(String) t) {
  final app = t(markTr('Docker en la barra de menús'));

  // ---- el menú de la ventana (el panel)
  final mFile = t(markTr('Archivo')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('REFRESH', t(markTr('Actualizar')), mFile);
  item('STOPALL', t(markTr('Parar todos…')), mFile);
  lines.add('  -');
  item('HIDE', t(markTr('Cerrar la ventana')), mFile);
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mHelp);
  item('HOWTO', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Docker en la barra de menús')), mHelp);

  // ---- los textos (constantes tx_… de la unidad)
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'L_HOWTO': t(markTr('Cómo funciona')),
    'HOWTO_TEXT': t(
      markTr(
        'El icono de la barra de menús muestra sus contenedores de Docker: los que están en marcha, agrupados por proyecto de Compose, y los parados.\n\nEn cada contenedor: abrir sus direcciones (los puertos publicados), pararlo, reiniciarlo o copiar la orden para entrar en él. «Abrir el panel…» muestra la misma lista en una ventana.\n\nLa lista se actualiza cada tres segundos con «docker ps». Cerrar la ventana no cierra la app: sigue en la barra de menús hasta que elija Salir.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en Object Pascal con Lazarus. La ventana, su menú y el reloj se diseñaron en el Diseñador del estudio; el icono de la barra (TTrayIcon), su menú y el panel se hacen en el código de Form1.pas, que habla con Docker a través de su orden «docker».',
      ),
    ),
    'SEARCHING': t(markTr('Buscando Docker…')),
    'MISSING': t(markTr('No encuentro Docker')),
    'MISSING_HELP': t(
      markTr(
        'Instale Docker Desktop (o Colima, OrbStack o Rancher Desktop) y la app lo encontrará sola.',
      ),
    ),
    'GET_DOCKER': t(markTr('Descargar Docker Desktop…')),
    'DOWN': t(markTr('Docker no está en marcha')),
    'DOWN_HELP': t(
      markTr(
        'Abra Docker Desktop: en cuanto arranque el motor, sus contenedores aparecerán aquí.',
      ),
    ),
    'OPEN_DESKTOP': t(markTr('Abrir Docker Desktop')),
    'HEAD': t(markTr('{0} en marcha · {1} parados')),
    'NONE_RUNNING': t(markTr('No hay contenedores en marcha')),
    'EMPTY': t(
      markTr(
        'Cree uno con «docker run» o «docker compose up» y aparecerá aquí.',
      ),
    ),
    'STOPPED_MENU': t(markTr('Parados ({0})')),
    'OPEN': t(markTr('Abrir {0}')),
    'NO_PORTS': t(markTr('Sin puertos publicados')),
    'STOP': t(markTr('Parar')),
    'START': t(markTr('Iniciar')),
    'RESTART': t(markTr('Reiniciar')),
    'COPY_ID': t(markTr('Copiar el ID')),
    'COPY_EXEC': t(markTr('Copiar la orden para entrar')),
    'PANEL': t(markTr('Abrir el panel…')),
    'REFRESH': t(markTr('Actualizar')),
    'STOPALL': t(markTr('Parar todos…')),
    'ABOUT': t(markTr('Acerca de…')),
    'QUIT': t(markTr('Salir')),
    'STOPPING': t(markTr('parando…')),
    'STARTING': t(markTr('iniciando…')),
    'RESTARTING': t(markTr('reiniciando…')),
    'ASK_STOPALL': t(markTr('¿Parar los {0} contenedores en marcha?')),
    'FAILED': t(markTr('Docker no pudo hacerlo:')),
    'TITLE': t(markTr('Contenedores')),
    'SEC_RUN': t(markTr('EN MARCHA · {0}')),
    'SEC_STOP': t(markTr('PARADOS · {0}')),
    'UPDATED': t(markTr('actualizado a las {0}')),
    'VERSION': t(markTr('Docker {0}')),
    'HINT': t(markTr('Docker · {0} en marcha')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      '  tx_$key = ${_pasString(value)};',
  ].join('\n');

  // ---- la ventana: el panel con la lista (se abre desde el menú del icono)
  final design =
      TkDesign(
          width: 960,
          height: 620,
          target: tkTargetPascal,
          props: {
            'title': app,
            'bg': '#f4f6f9',
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            900,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Cada tres segundos, «docker ps» (en segundo plano).
          _w(
            'Timer',
            'Tick',
            860,
            8,
            32,
            32,
            {'interval': 3000},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Stage', 0, 0, 960, 620, {'bg': '#f4f6f9'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'StageHint', 120, 290, 720, 40, {
            'text': t(
              markTr(
                'El icono de la barra de menús y la lista de contenedores los hace el código de Form1.pas',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#f4f6f9',
            'font_size': 14,
          })..parent = 'Stage',
        ]);

  final code = _dockerBarCode
      .replaceFirst(
        '// @TITLE',
        '// ${t(markTr('Docker en la barra de menús: los contenedores en marcha en un icono de la barra, con sus direcciones y el botón de parar, en Pascal con Lazarus.'))}',
      )
      .replaceFirst('  // @TEXTS', consts);
  return TkExample(
    'pascal_docker',
    t(markTr('Docker en la barra de menús (Pascal)')),
    t(
      markTr(
        'Una app de la barra de menús en Object Pascal con Lazarus: su icono muestra los contenedores de Docker en marcha, agrupados por proyecto de Compose, y desde ahí se abren sus direcciones, se paran, se reinician o se inician los parados.',
      ),
    ),
    design,
    code,
  );
}
