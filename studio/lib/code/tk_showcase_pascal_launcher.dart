part of 'tk_examples.dart';

// ------------------------------------ Lanzador de apps (Pascal)
/// Una app de Object Pascal (Lazarus) que vive en la barra de menús de macOS
/// (en Windows, en el área de notificación): su icono abre un menú con las
/// aplicaciones de la carpeta donde está el lanzador, con sus iconos, y las
/// favoritas y las recientes arriba. La ventana del diseño es un
/// panel con un buscador y las apps en teselas.
TkExample tkPascalLauncher(String Function(String) t) {
  final app = t(markTr('Lanzador de apps'));

  // ---- el menú de la ventana (el panel)
  final mFile = t(markTr('Archivo')), mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('RESCAN', t(markTr('Actualizar la lista')), mFile);
  lines.add('  -');
  item('HIDE', t(markTr('Cerrar la ventana')), mFile);
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mHelp);
  item('HOWTO', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca del Lanzador de apps')), mHelp);

  // ---- los textos (constantes tx_… de la unidad)
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'L_HOWTO': t(markTr('Cómo funciona')),
    'HOWTO_TEXT': t(
      markTr(
        'El icono de la barra de menús abre las aplicaciones que están en la misma carpeta que el lanzador (y en sus subcarpetas), con sus iconos. Arriba van las favoritas y las que abrió hace poco.\n\n«Buscar…» abre el panel: escriba parte del nombre (sin preocuparse de los acentos), elija con las flechas y pulse Intro. La estrella de cada app la marca como favorita.\n\nSi copia o borra una app de esa carpeta, la lista se pone al día sola en medio minuto. Cerrar la ventana no cierra la app: sigue en la barra de menús hasta que elija Salir.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en Object Pascal con Lazarus: lanza las aplicaciones de su propia carpeta. La ventana, su menú, el buscador y el reloj se diseñaron en el Diseñador del estudio; el icono de la barra (TTrayIcon), su menú con los iconos de cada app y las teselas del panel se hacen en el código de Form1.pas.',
      ),
    ),
    'HEAD': t(markTr('{0} aplicaciones')),
    'SEARCH': t(markTr('Buscar…')),
    'SEARCH_HINT': t(markTr('Buscar una aplicación')),
    'FAVORITES': t(markTr('Favoritas')),
    'RECENT': t(markTr('Recientes')),
    'NO_APPS': t(markTr('No encuentro aplicaciones')),
    'RESCAN': t(markTr('Actualizar la lista')),
    'ABOUT': t(markTr('Acerca de…')),
    'QUIT': t(markTr('Salir')),
    'SEC_FAV': t(markTr('FAVORITAS · {0}')),
    'SEC_ALL': t(markTr('TODAS · {0}')),
    'SEC_FOUND': t(markTr('{0} PARA «{1}»')),
    'NONE_FOUND': t(markTr('Ninguna aplicación se llama así.')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      '  tx_$key = ${_pasString(value)};',
  ].join('\n');

  final design =
      TkDesign(
          width: 960,
          height: 640,
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
          // Cada medio minuto, la lista de apps otra vez.
          _w(
            'Timer',
            'Tick',
            860,
            8,
            32,
            32,
            {'interval': 30000},
            {'command': 'Tick_timer'},
          ),
          _w(
            'Entry',
            'Search',
            20,
            16,
            920,
            36,
            {'font_size': 15},
            {'enter_key': 'Search_enter'},
          ),
          _w('Frame', 'Stage', 0, 64, 960, 576, {'bg': '#f4f6f9'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'StageHint', 120, 260, 720, 40, {
            'text': t(
              markTr(
                'El icono de la barra de menús y las teselas de las apps los hace el código de Form1.pas',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#f4f6f9',
            'font_size': 14,
          })..parent = 'Stage',
        ]);

  final code = _launcherCode
      .replaceFirst(
        '// @TITLE',
        '// ${t(markTr('Lanzador de apps: las aplicaciones de su carpeta en un icono de la barra de menús, con favoritas, recientes y un buscador, en Pascal con Lazarus.'))}',
      )
      .replaceFirst('  // @TEXTS', consts);
  return TkExample(
    'pascal_launcher',
    t(markTr('Lanzador de apps (Pascal)')),
    t(
      markTr(
        'Una app de la barra de menús en Object Pascal con Lazarus: su icono abre las aplicaciones de la carpeta donde está el lanzador, con sus iconos, las favoritas y las recientes arriba, y un panel con buscador para abrirlas con el teclado.',
      ),
    ),
    design,
    code,
  );
}
