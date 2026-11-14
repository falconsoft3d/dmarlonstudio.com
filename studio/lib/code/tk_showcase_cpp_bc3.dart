part of 'tk_examples.dart';

// ------------------------------------------------ Visor BC3 (C++)
/// Un visor de presupuestos en FIEBDC-3 (.bc3), en C++17 con FLTK: lee los
/// registros ~V, ~K, ~C, ~D, ~Y, ~T, ~M y ~L en los juegos de caracteres 850,
/// 437 y ANSI, recalcula los precios (porcentajes con máscara, auxiliares,
/// costes indirectos) y enseña el árbol con capítulos, partidas y
/// descompuestos, las mediciones, los textos y el resumen del presupuesto.
TkExample tkCppBc3(String Function(String) t) {
  final app = t(markTr('Visor BC3'));
  // Con contexto (msgctxt «bc3»): el presupuesto de obra y el resumen de un concepto.
  String tc(String id) {
    final k = contextKey('bc3', id);
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

  lines.add(mFile);
  item('OPEN', t(markTr('Abrir un presupuesto…')), mFile);
  item('SAMPLE', t(markTr('Abrir el ejemplo')), mFile);
  item('EXPORT', t(markTr('Exportar a CSV…')), mFile);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mView);
  item('FIND', t(markTr('Buscar')), mView);
  item('EXPAND', t(markTr('Abrir todos los capítulos')), mView);
  item('COLLAPSE', t(markTr('Cerrar los capítulos')), mView);
  item('SUMMARY', t(markTr('Resumen del presupuesto')), mView);
  lines.add(mHelp);
  item('ABOUT', t(markTr('Acerca del Visor BC3')), mHelp);
  final texts = <String, String>{
    'APP': app,
    'THOUSANDS': t(markTr('.')),
    'DECIMAL': t(markTr(',')),
    ...paths,
    'ABOUT_TEXT': t(
      markTr(
        'Visor BC3 es una demo de DMarlon Studio hecha en C++ con FLTK. Abre presupuestos en el formato de intercambio FIEBDC-3 (.bc3) que exportan Presto, Arquímedes, Menfis, TCQ y la mayoría de programas de mediciones: capítulos, partidas, descompuestos, mediciones, textos y pliegos. Recalcula los precios a partir de las descomposiciones (con los porcentajes y los costes indirectos) y avisa si no cuadran con el archivo. Solo lee: no cambia nada.',
      ),
    ),
    'KB_ROOT': t(markTr('PRES')),
    'KB_CHAPTER': t(markTr('CAP')),
    'KB_UNIT': t(markTr('PART')),
    'KB_AUX': t(markTr('AUX')),
    'KB_LABOR': tc(markTrc('bc3', 'MO')),
    'KB_MACHINE': t(markTr('MAQ')),
    'KB_MATERIAL': t(markTr('MAT')),
    'KB_PERCENT': t(markTr('%')),
    'KB_WASTE': t(markTr('RES')),
    'KB_OTHER': t(markTr('—')),
    'KN_ROOT': tc(markTrc('bc3', 'Presupuesto')),
    'KN_CHAPTER': t(markTr('Capítulo')),
    'KN_UNIT': t(markTr('Partida')),
    'KN_AUX': t(markTr('Partida auxiliar')),
    'KN_LABOR': t(markTr('Mano de obra')),
    'KN_MACHINE': t(markTr('Maquinaria')),
    'KN_MATERIAL': t(markTr('Material')),
    'KN_PERCENT': t(markTr('Porcentaje')),
    'KN_WASTE': t(markTr('Residuo')),
    'KN_OTHER': t(markTr('Sin clasificar')),
    'COL_CODE': t(markTr('Código')),
    'COL_KIND': t(markTr('Tipo')),
    'COL_UNIT': tc(markTrc('bc3', 'Ud')),
    'COL_SUMMARY': tc(markTrc('bc3', 'Resumen')),
    'COL_QTY': t(markTr('Cantidad')),
    'COL_PRICE': t(markTr('Precio')),
    'COL_AMOUNT': t(markTr('Importe')),
    'COL_COMMENT': t(markTr('Comentario')),
    'COL_N': t(markTr('Uds')),
    'COL_L': t(markTr('Longitud')),
    'COL_W': t(markTr('Anchura')),
    'COL_H': t(markTr('Altura')),
    'COL_PARTIAL': t(markTr('Parcial')),
    'CSV_LEVEL': t(markTr('Nivel')),
    'TAB_DECOMP': t(markTr('Descomposición')),
    'TAB_MEAS': t(markTr('Mediciones')),
    'TAB_TEXT': t(markTr('Texto y pliego')),
    'TAB_SUMMARY': tc(markTrc('bc3', 'Resumen del presupuesto')),
    'LBL_UNIT': t(markTr('UNIDAD')),
    'LBL_QTY': t(markTr('CANTIDAD')),
    'LBL_PRICE': t(markTr('PRECIO')),
    'LBL_AMOUNT': t(markTr('IMPORTE')),
    'BUDGET': tc(markTrc('bc3', 'Presupuesto')),
    'TOTAL': t(markTr('Total')),
    'PRICE_DIFF': t(markTr('El archivo dice {0}; calculado: {1}')),
    'PCT_HINT': t(
      markTr(
        'Un porcentaje se aplica a las líneas anteriores de la descomposición cuyo código empieza como el suyo antes del %.',
      ),
    ),
    'NO_DECOMP': t(
      markTr('Este concepto no tiene descomposición: su precio viene del archivo.'),
    ),
    'NO_MEAS': t(markTr('Este concepto no tiene líneas de medición.')),
    'NO_TEXT': t(markTr('Este concepto no tiene texto descriptivo.')),
    'MEAS_TOTAL': t(markTr('Total medición')),
    'MEAS_FILE': t(markTr('El archivo indica un total de {0}')),
    'MT_PARTIAL': t(markTr('Subtotal parcial')),
    'MT_ACCUM': t(markTr('Subtotal acumulado')),
    'EMPTY_TITLE': t(markTr('Ningún presupuesto abierto')),
    'EMPTY_HINT': t(
      markTr(
        'Abra un archivo .bc3 (FIEBDC-3) con «Abrir», arrástrelo sobre el árbol o pruebe el ejemplo: una reforma de vivienda con capítulos, partidas, descompuestos y mediciones.',
      ),
    ),
    'SAMPLE_NAME': t(markTr('ejemplo-reforma.bc3')),
    'SEARCH_HINT': t(
      markTr('Busque por código o por texto; Intro pasa al siguiente resultado'),
    ),
    'NOT_FOUND': t(markTr('No se encontró «{0}»')),
    'FOUND': t(markTr('Resultado {0} de {1} (Intro: el siguiente)')),
    'ERR_READ': t(markTr('No se pudo leer o escribir el archivo {0}')),
    'ERR_EMPTY': t(
      markTr('El archivo no tiene conceptos de FIEBDC-3 (registros ~C).'),
    ),
    'EXPORTED': t(markTr('Presupuesto exportado a {0}')),
    'ST_EMPTY': t(markTr('Abra un presupuesto .bc3 o el ejemplo')),
    'S_FILE': t(markTr('ARCHIVO')),
    'S_NAME': t(markTr('Nombre')),
    'S_VERSION': t(markTr('Formato')),
    'S_PROGRAM': t(markTr('Programa')),
    'S_OWNER': t(markTr('Propietario')),
    'S_CHARSET': t(markTr('Juego de caracteres')),
    'S_CONTENT': t(markTr('Contenido')),
    'S_COUNTS': t(markTr('{0} conceptos · {1} capítulos · {2} partidas')),
    'S_TOTALS': t(markTr('TOTALES')),
    'S_PEM': t(markTr('Ejecución material')),
    'S_GG': t(markTr('Gastos generales ({0} %)')),
    'S_BI': t(markTr('Beneficio industrial ({0} %)')),
    'S_PEC': t(markTr('Ejecución por contrata')),
    'S_IVA': t(markTr('IVA ({0} %)')),
    'S_TOTAL': t(markTr('Total con IVA')),
    'S_CI_IN': t(
      markTr(
        'Los costes indirectos del archivo ({0} %) se suman al precio de cada partida: así cuadra con sus totales.',
      ),
    ),
    'S_CI_OUT': t(
      markTr(
        'El archivo declara costes indirectos del {0} %, ya incluidos en los precios.',
      ),
    ),
    'S_NATURE': t(markTr('¿EN QUÉ SE VA EL DINERO?')),
    'S_TOP': t(markTr('LAS PARTIDAS DE MAYOR IMPORTE')),
    'CAT_LABOR': t(markTr('Mano de obra')),
    'CAT_MACHINE': t(markTr('Maquinaria')),
    'CAT_MATERIAL': t(markTr('Materiales')),
    'CAT_WASTE': t(markTr('Residuos')),
    'CAT_PCT': t(markTr('Medios auxiliares y porcentajes')),
    'CAT_CI': t(markTr('Costes indirectos')),
    'CAT_UNDEC': t(markTr('Partidas sin descomponer')),
    'CAT_OTHER': t(markTr('Sin clasificar')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const bg = '#f3f5f9';
  final filter = t(markTr('Presupuestos FIEBDC-3|*.bc3;*.BC3'));
  final design =
      TkDesign(
          width: 1220,
          height: 800,
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
            1160,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          _w('OpenDialog', 'DlgOpen', 1120, 8, 32, 32, {
            'title': t(markTr('Abrir un presupuesto BC3')),
            'filter': filter,
          }),
          _w('SaveDialog', 'DlgSave', 1080, 8, 32, 32, {
            'title': t(markTr('Exportar el presupuesto a CSV')),
            'filter': 'CSV|*.csv',
          }),
          _w('Frame', 'Top', 0, 0, 1220, 52, {'bg': '#ffffff'}),
          _w('Label', 'LblApp', 16, 10, 180, 32, {
            'text': app,
            'bg': '#ffffff',
            'fg': '#0f172a',
            'font_bold': true,
            'font_size': 17,
          })..parent = 'Top',
          _w(
            'Entry',
            'Search',
            230,
            10,
            420,
            32,
            {'font_size': 14},
            {'enter_key': 'Search_enter'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnOpen',
            820,
            10,
            110,
            32,
            {
              'text': t(markTr('Abrir')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnOpen_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnSample',
            940,
            10,
            110,
            32,
            {'text': t(markTr('Ejemplo'))},
            {'command': 'BtnSample_click'},
          )..parent = 'Top',
          _w(
            'Button',
            'BtnExport',
            1060,
            10,
            146,
            32,
            {'text': t(markTr('Exportar CSV'))},
            {'command': 'BtnExport_click'},
          )..parent = 'Top',
          _w('Frame', 'TreeHost', 0, 52, 470, 724, {'bg': '#ffffff'}),
          _w('Frame', 'DetailHost', 470, 52, 750, 724, {'bg': bg}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'BoardHint', 500, 300, 690, 40, {
            'text': t(
              markTr(
                'El árbol, la cabecera, las tablas y el resumen los crea el código de Form1.cpp',
              ),
            ),
            'fg': '#64748b',
            'bg': bg,
            'font_size': 14,
          })..parent = 'DetailHost',
          _w('StatusBar', 'Status', 0, 776, 1220, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Visor BC3 en C++ con FLTK: abre presupuestos FIEBDC-3 con sus capítulos, partidas, descompuestos, mediciones y textos, y recalcula los precios.'))}
$_bc3Includes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_bc3Code''';
  return TkExample(
    'cpp_bc3',
    t(markTr('Visor BC3 (C++)')),
    t(
      markTr(
        'Un visor nativo en C++ con FLTK de presupuestos FIEBDC-3 (.bc3): árbol de capítulos, partidas y descompuestos, mediciones, textos, totales recalculados, desglose por naturaleza y exportación a CSV.',
      ),
    ),
    design,
    code,
  );
}
