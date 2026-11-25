part of 'tk_examples.dart';

// --------------------------------------------------- captura y prompt (C++)
/// Una cámara en la barra de menús de macOS (y junto al reloj de Windows):
/// captura un área, una ventana o la pantalla, la marca con flechas,
/// rectángulos, texto, números de paso, resaltador o pixelado, y la junta con
/// otras en un PDF comentado (cada captura con su comentario, que se puede
/// seguir editando en el PDF) o en un prompt para pegar en un asistente.
/// En C++17 con FLTK; el PDF se escribe a mano, sin bibliotecas.
TkExample tkCppCapture(String Function(String) t) {
  final app = t(markTr('Captura y prompt'));
  final mFile = t(markTr('Archivo')),
      mEdit = t(markTr('Edición')),
      mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mFile);
  item('AREA', t(markTr('Capturar un área')), mFile);
  item('WINDOW', t(markTr('Capturar una ventana')), mFile);
  item('SCREEN', t(markTr('Capturar la pantalla')), mFile);
  item('OPEN', t(markTr('Abrir una imagen…')), mFile);
  lines.add('  -');
  item('SAVE', t(markTr('Guardar la imagen marcada')), mFile);
  item('SAVE_AS', t(markTr('Guardar como…')), mFile);
  item('COPY', t(markTr('Copiar la imagen')), mFile);
  lines.add('  -');
  item('PDF', t(markTr('Exportar el PDF…')), mFile);
  item('PROMPT', t(markTr('Copiar el prompt')), mFile);
  item('FOLDER', t(markTr('Abrir la carpeta de capturas')), mFile);
  item('CLEAR', t(markTr('Vaciar la sesión')), mFile);
  lines.add('  -');
  item('BAR', t(markTr('Minimizar a la barra')), mFile);
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mEdit);
  item('UNDO', t(markTr('Deshacer')), mEdit);
  item('REDO', t(markTr('Rehacer')), mEdit);
  item('WIPE', t(markTr('Borrar las marcas')), mEdit);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Captura y prompt')), mHelp);
  final texts = <String, String>{
    'APP': app,
    ...paths,
    'HOW_TEXT': t(
      markTr(
        'Capture con los botones Área, Ventana o Pantalla, desde el icono de la cámara de la barra de menús (en Windows, junto al reloj) o con ⌃⌥⌘4, ⌃⌥⌘5 y ⌃⌥⌘3 (en Windows, Ctrl+Alt+Mayús+4, 5 y 3). En macOS, en un área, la barra espaciadora cambia a ventana; Esc cancela.\n\nLa captura se abre aquí para marcarla: lápiz (P), resaltador (H), flecha (A), línea (L), rectángulo (R), óvalo (O), texto (T), números de paso (N), pixelar datos (B) y recortar (C). Con Mayúsculas, las líneas van a 45° y los rectángulos son cuadrados. «Vista Previa» la abre con las herramientas de marcado de macOS.\n\nEscriba qué quiere en «Comentario» y pulse «Añadir al PDF». Arriba, el prompt general. «Exportar el PDF…» hace una portada con el prompt y una página por captura con su comentario (si marca «Comentarios editables», se pueden reescribir en el PDF). «Copiar el prompt» copia el texto con la ruta de cada imagen, listo para pegar en un asistente.\n\nCerrar la ventana la esconde en la barra: la cámara sigue ahí.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio hecha en C++ con FLTK. La ventana, su menú, la barra de herramientas y el panel se diseñaron en el Diseñador del estudio; el lienzo de marcas se dibuja en código, el PDF se escribe a mano (sin bibliotecas) y el icono de la barra se hace con el runtime de Objective-C en macOS y con Shell_NotifyIcon en Windows.',
      ),
    ),
    'DEFAULT_FOLDER': t(markTr('Captura y prompt')),
    'CAPTURE_NAME': t(markTr('Captura {0}')),
    'MARKED_SUFFIX': t(markTr('-marcada')),
    'PDF_NAME': t(markTr('Capturas {0}')),
    'EMPTY_TITLE': t(markTr('Capture la pantalla para empezar')),
    'EMPTY_HELP': t(
      markTr(
        'Pulse Área, Ventana o Pantalla, o use ⌃⌥⌘4 desde cualquier app. También puede soltar aquí una imagen.',
      ),
    ),
    'ADD': t(markTr('Añadir al PDF')),
    'UPDATE': t(markTr('Actualizar en el PDF')),
    'NO_COMMENT': t(markTr('(sin comentario)')),
    'COVER_SUB': t(markTr('{0} capturas · {1}')),
    'COVER_LABEL': t(markTr('Prompt / instrucciones generales')),
    'PAGE_TITLE': t(markTr('Captura {0}')),
    'PAGE_LABEL': t(markTr('Comentario / prompt')),
    'PROMPT_IMAGE': t(markTr('Imagen: {0}')),
    'MISSING_IMAGE': t(markTr('No se encuentra la imagen:')),
    'TITLE_DEFAULT': t(markTr('Capturas para el prompt')),
    'ST_READY': t(markTr('Lista. {0} capturas en el PDF.')),
    'ST_CAPTURED': t(markTr('Captura guardada en {0}')),
    'ST_SAVED': t(markTr('Imagen marcada guardada en {0}')),
    'ST_ADDED': t(markTr('Añadida al PDF como captura {0}.')),
    'ST_UPDATED': t(markTr('Actualizada la captura {0} del PDF.')),
    'ST_COPIED': t(markTr('Imagen copiada al portapapeles.')),
    'ST_PROMPT': t(markTr('Prompt copiado al portapapeles ({0} capturas).')),
    'ST_PDF': t(markTr('PDF creado: {0}')),
    'ST_PREVIEW': t(
      markTr(
        'Abierta en Vista Previa: ⇧⌘A muestra sus herramientas de marcado. Lo que guarde allí entra en el PDF.',
      ),
    ),
    'ST_CANCEL': t(markTr('Captura cancelada.')),
    'ST_NOTHING': t(markTr('Todavía no hay nada que exportar.')),
    'E_CAPTURE': t(
      markTr(
        'No se pudo capturar la pantalla. En macOS, dé permiso en Ajustes del Sistema › Privacidad y seguridad › Grabación de pantalla.',
      ),
    ),
    'E_SAVE': t(markTr('No se pudo guardar {0}')),
    'E_OPEN': t(markTr('No se pudo abrir la imagen {0}')),
    'E_PDF': t(markTr('No se pudo escribir el PDF {0}')),
    'ASK_CLEAR': t(
      markTr(
        '¿Vaciar la sesión? Se quitan las capturas y los comentarios del PDF; las imágenes siguen en su carpeta.',
      ),
    ),
    'ASK_YES': t(markTr('Vaciar')),
    'ASK_NO': t(markTr('Cancelar')),
    'ALREADY_OPEN': t(
      markTr(
        'Captura y prompt ya está abierta: búsquela en la barra de menús (en Windows, junto al reloj).',
      ),
    ),
    'BAR_AREA': t(markTr('Capturar un área')),
    'BAR_WINDOW': t(markTr('Capturar una ventana')),
    'BAR_SCREEN': t(markTr('Capturar la pantalla')),
    'BAR_SHOW': t(markTr('Abrir la ventana')),
    'BAR_COUNT': t(markTr('{0} capturas en el PDF')),
    'BAR_PDF': t(markTr('Exportar el PDF…')),
    'BAR_PROMPT': t(markTr('Copiar el prompt')),
    'BAR_FOLDER': t(markTr('Abrir la carpeta de capturas')),
    'BAR_QUIT': t(markTr('Salir')),
    'KEY_WIN': t(markTr('Ctrl+Alt+Mayús+{0}')),
    'OVERLAY_AREA': t(
      markTr('Arrastre para elegir el área · Esc para cancelar'),
    ),
    'OVERLAY_WINDOW': t(
      markTr('Pulse sobre una ventana · Esc para cancelar'),
    ),
    'FILTER_IMAGES': t(markTr('Imágenes')),
    'SAMPLE_APP': t(markTr('Inventario')),
    'SAMPLE_MENU': t(markTr('Productos   Operaciones   Informes   Configuración')),
    'SAMPLE_TITLE': t(markTr('Limpiador industrial 5 L')),
    'SAMPLE_FIELDS': t(
      markTr(
        'Tipo de producto|Bienes\nPrecio de venta|18,50 €\nImpuesto de venta|21 %\nCoste|9,20 €\nCategoría|Químicos / Limpieza\nReferencia|LIM-005\nCódigo de barras|8437000000057',
      ),
    ),
    'SAMPLE_NOTE': t(markTr('Precio sin impuestos')),
    'SAMPLE_PROMPT': t(
      markTr(
        'Corrige el formulario de producto de mi ERP según las capturas. Mantén el estilo de la interfaz.',
      ),
    ),
    'SAMPLE_C1': t(
      markTr(
        'El precio de venta debe mostrarse con impuestos incluidos (22,39 €).',
      ),
    ),
    'SAMPLE_C2': t(
      markTr('El código de barras no debe verse en esta vista: ocúltalo.'),
    ),
    'SAMPLE_C3': t(markTr('Añade el stock disponible junto al coste.')),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');
  const bar = '#f6f7fb', side = '#f4f6f9';
  TkWidget tool(String name, int x, String text) => _w(
    'Button',
    name,
    x,
    10,
    58,
    36,
    {'text': text, 'font_size': 12},
    {'command': '${name}_click'},
  )..parent = 'Tools';
  TkWidget swatch(String name, int x, String color) => _w(
    'Button',
    name,
    x,
    18,
    20,
    20,
    {'text': '', 'bg': color},
    {'command': '${name}_click'},
  )..parent = 'Tools';
  TkWidget lbl(String name, int y, String text) => _w(
    'Label',
    name,
    12,
    y,
    356,
    22,
    {
      'text': text,
      'bg': side,
      'fg': '#374151',
      'font_size': 12,
      'font_bold': true,
      'anchor': 'w',
    },
  )..parent = 'Side';
  TkWidget btn(
    String name,
    int x,
    int y,
    int w,
    int h,
    String text, [
    String? bg,
  ]) => _w(
    'Button',
    name,
    x,
    y,
    w,
    h,
    {
      'text': text,
      if (bg != null) ...{'bg': bg, 'fg': '#ffffff', 'font_bold': true},
    },
    {'command': '${name}_click'},
  )..parent = 'Side';
  final design =
      TkDesign(
          width: 1280,
          height: 780,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': side,
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1230,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // La barra de herramientas: capturar, las herramientas, deshacer,
          // los colores y el grosor.
          _w('Frame', 'Tools', 0, 0, 1280, 56, {'bg': bar}),
          _w(
            'Button',
            'BtnArea',
            10,
            10,
            92,
            36,
            {
              'text': t(markTr('Área')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnArea_click'},
          )..parent = 'Tools',
          _w(
            'Button',
            'BtnWindow',
            106,
            10,
            92,
            36,
            {'text': t(markTr('Ventana'))},
            {'command': 'BtnWindow_click'},
          )..parent = 'Tools',
          _w(
            'Button',
            'BtnScreen',
            202,
            10,
            92,
            36,
            {'text': t(markTr('Pantalla'))},
            {'command': 'BtnScreen_click'},
          )..parent = 'Tools',
          tool('ToolPen', 306, t(markTr('Lápiz'))),
          tool('ToolMark', 364, t(markTr('Resaltar'))),
          tool('ToolArrow', 422, t(markTr('Flecha'))),
          tool('ToolLine', 480, t(markTr('Línea'))),
          tool('ToolRect', 538, t(markTr('Rect.'))),
          tool('ToolOval', 596, t(markTr('Óvalo'))),
          tool('ToolText', 654, t(markTr('Texto'))),
          tool('ToolNum', 712, t(markTr('Nº'))),
          tool('ToolBlur', 770, t(markTr('Pixelar'))),
          tool('ToolCrop', 828, t(markTr('Recorte'))),
          _w(
            'Button',
            'BtnUndo',
            896,
            10,
            50,
            36,
            {'text': t(markTr('Deshacer')), 'font_size': 11},
            {'command': 'BtnUndo_click'},
          )..parent = 'Tools',
          _w(
            'Button',
            'BtnRedo',
            948,
            10,
            50,
            36,
            {'text': t(markTr('Rehacer')), 'font_size': 11},
            {'command': 'BtnRedo_click'},
          )..parent = 'Tools',
          swatch('Color1', 1010, '#f23333'),
          swatch('Color2', 1034, '#ff9500'),
          swatch('Color3', 1058, '#ffd60a'),
          swatch('Color4', 1082, '#34c759'),
          swatch('Color5', 1106, '#0a84ff'),
          swatch('Color6', 1130, '#1d1d1f'),
          _w(
            'Combobox',
            'Size',
            1160,
            12,
            110,
            32,
            {
              'items': [
                t(markTr('Fino')),
                t(markTr('Medio')),
                t(markTr('Grueso')),
              ].join('\n'),
              'text': t(markTr('Medio')),
            },
            {'select': 'Size_select'},
          )..parent = 'Tools',
          // El lienzo: lo dibuja el código (Form1.cpp).
          _w('Frame', 'Board', 0, 56, 900, 700, {'bg': '#2a2c31'}),
          _w('Label', 'BoardHint', 150, 380, 600, 40, {
            'text': t(
              markTr('El lienzo de marcas lo dibuja el código de Form1.cpp'),
            ),
            'fg': '#cbd5e1',
            'bg': '#2a2c31',
            'font_size': 14,
          })..parent = 'Board',
          // El panel: el prompt general, las capturas del PDF y el comentario.
          _w('Frame', 'Side', 900, 56, 380, 700, {'bg': side}),
          lbl('LblPrompt', 8, t(markTr('Prompt general (portada del PDF)'))),
          _w('Text', 'Prompt', 12, 32, 356, 96, {
            'font_size': 13,
          })..parent = 'Side',
          lbl('LblShots', 136, t(markTr('Capturas del PDF'))),
          _w(
            'Listbox',
            'Shots',
            12,
            160,
            356,
            190,
            {},
            {'select': 'Shots_select'},
          )..parent = 'Side',
          btn('BtnUp', 12, 356, 84, 30, t(markTr('Subir'))),
          btn('BtnDown', 102, 356, 84, 30, t(markTr('Bajar'))),
          btn('BtnRemove', 192, 356, 176, 30, t(markTr('Quitar del PDF'))),
          lbl('LblComment', 396, t(markTr('Comentario / prompt de esta captura'))),
          _w('Text', 'Comment', 12, 420, 356, 120, {
            'font_size': 13,
          })..parent = 'Side',
          btn('BtnAdd', 12, 548, 356, 36, t(markTr('Añadir al PDF')), '#16a34a'),
          btn('BtnSave', 12, 590, 116, 32, t(markTr('Guardar'))),
          btn('BtnCopy', 132, 590, 116, 32, t(markTr('Copiar'))),
          btn('BtnPreview', 252, 590, 116, 32, t(markTr('Vista Previa'))),
          _w(
            'Checkbutton',
            'Editable',
            12,
            628,
            356,
            24,
            {
              'text': t(markTr('Comentarios editables en el PDF')),
              'bg': side,
              'checked': true,
            },
            {'command': 'Editable_click'},
          )..parent = 'Side',
          btn('BtnPdf', 12, 656, 176, 36, t(markTr('Exportar el PDF…')), '#2563eb'),
          btn('BtnPrompt', 192, 656, 176, 36, t(markTr('Copiar el prompt'))),
          _w('StatusBar', 'Status', 0, 756, 1280, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Captura y prompt en C++ con FLTK: una cámara en la barra de menús que captura la pantalla, la marca y la junta en un PDF comentado o en un prompt.'))}
$_captureIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_captureCode''';
  return TkExample(
    'cpp_capture',
    t(markTr('Captura y prompt (C++)')),
    t(
      markTr(
        'Una cámara en la barra de menús: captura un área, una ventana o la pantalla, la marca con flechas, rectángulos, texto, números o pixelado y la junta con su comentario en un PDF o en un prompt para pegar en un asistente.',
      ),
    ),
    design,
    code,
  );
}
