part of 'tk_examples.dart';

// ------------------------------------------ editor de imágenes (C++)
/// Un editor de imágenes por capas en C++17 con FLTK, al estilo de los
/// programas de retoque: herramientas (mover, marco, recortar, pincel,
/// borrador, bote, degradado, formas, texto, cuentagotas, mano y zoom),
/// capas con opacidad y modos de fusión, historial, ajustes (niveles, tono y
/// saturación…), filtros, cambiar el tamaño, girar y voltear, y abrir y
/// guardar PNG, JPEG, BMP y un proyecto con capas (.dmi). Los paneles se
/// dibujan en código y los codificadores JPEG y BMP son propios.
TkExample tkCppImageEditor(String Function(String) t) {
  final app = t(markTr('Editor de imágenes'));
  // Con contexto (msgctxt «image»): los nombres que en otros sitios
  // significan otra cosa («Mano» es la herramienta, no la del dominó).
  String tc(String id) {
    final k = contextKey('image', id);
    final r = t(k);
    return r == k ? id : r;
  }

  // ---- menús: el texto del diseño y la ruta de cada opción para el código
  final mFile = t(markTr('Archivo')), mEdit = t(markTr('Edición'));
  final mImage = t(markTr('Imagen')), mLayer = t(markTr('Capa'));
  final mFilter = t(markTr('Filtro')), mView = t(markTr('Ver'));
  final mHelp = t(markTr('Ayuda'));
  final mRotate = t(markTr('Girar y voltear'));
  final mAdjust = t(markTr('Ajustes'));
  final lines = <String>[];
  final paths = <String, String>{};
  final labels = <String, String>{};
  void menu(String label) => lines.add(label);
  void item(String id, String label, String prefix, [int depth = 1]) {
    lines.add('${'  ' * depth}$label');
    paths['MP_$id'] = '$prefix/$label';
    labels['L_$id'] = label;
  }

  void sep([int depth = 1]) => lines.add('${'  ' * depth}-');
  menu(mFile);
  item('NEW', t(markTr('Nuevo…')), mFile);
  item('OPEN', t(markTr('Abrir…')), mFile);
  item('PLACE', t(markTr('Abrir como capa…')), mFile);
  sep();
  item('SAVE', t(markTr('Guardar')), mFile);
  item('SAVE_AS', t(markTr('Guardar como…')), mFile);
  sep();
  item('SAMPLE', t(markTr('Imagen de ejemplo')), mFile);
  sep();
  item('QUIT', t(markTr('Salir')), mFile);
  menu(mEdit);
  item('UNDO', t(markTr('Deshacer')), mEdit);
  item('REDO', t(markTr('Rehacer')), mEdit);
  sep();
  item('CUT', t(markTr('Cortar')), mEdit);
  item('COPY', t(markTr('Copiar')), mEdit);
  item('PASTE', t(markTr('Pegar')), mEdit);
  item('CLEAR', t(markTr('Borrar la selección')), mEdit);
  item('FILL', t(markTr('Rellenar con el color frontal')), mEdit);
  sep();
  item('SELECT_ALL', t(markTr('Seleccionar todo')), mEdit);
  item('DESELECT', t(markTr('Deseleccionar')), mEdit);
  menu(mImage);
  item('IMAGE_SIZE', t(markTr('Tamaño de imagen…')), mImage);
  item('CANVAS_SIZE', t(markTr('Tamaño de lienzo…')), mImage);
  item('CROP_SEL', t(markTr('Recortar a la selección')), mImage);
  sep();
  lines.add('  $mRotate');
  final rot = '$mImage/$mRotate';
  item('ROT_CW', t(markTr('Girar 90° a la derecha')), rot, 2);
  item('ROT_CCW', t(markTr('Girar 90° a la izquierda')), rot, 2);
  item('ROT_180', t(markTr('Girar 180°')), rot, 2);
  item('ROT_ANY', t(markTr('Girar un ángulo…')), rot, 2);
  sep(2);
  item('FLIP_H', t(markTr('Voltear en horizontal')), rot, 2);
  item('FLIP_V', t(markTr('Voltear en vertical')), rot, 2);
  lines.add('  $mAdjust');
  final adj = '$mImage/$mAdjust';
  item('BRIGHT', t(markTr('Brillo y contraste…')), adj, 2);
  item('HUESAT', t(markTr('Tono y saturación…')), adj, 2);
  item('LEVELS', t(markTr('Niveles…')), adj, 2);
  sep(2);
  item('GRAY', t(markTr('Blanco y negro')), adj, 2);
  item('SEPIA', t(markTr('Sepia')), adj, 2);
  item('INVERT', t(markTr('Invertir')), adj, 2);
  item('THRESHOLD', t(markTr('Umbral…')), adj, 2);
  item('POSTERIZE', t(markTr('Posterizar…')), adj, 2);
  menu(mLayer);
  item('LAYER_NEW', t(markTr('Nueva capa')), mLayer);
  item('LAYER_DUP', t(markTr('Duplicar capa')), mLayer);
  item('LAYER_DEL', t(markTr('Eliminar capa')), mLayer);
  sep();
  item('LAYER_UP', t(markTr('Subir capa')), mLayer);
  item('LAYER_DOWN', t(markTr('Bajar capa')), mLayer);
  sep();
  item('MERGE', t(markTr('Combinar hacia abajo')), mLayer);
  item('FLATTEN', t(markTr('Acoplar imagen')), mLayer);
  sep();
  item('LAYER_PROPS', t(markTr('Propiedades de capa…')), mLayer);
  menu(mFilter);
  item('BLUR', t(markTr('Desenfoque gaussiano…')), mFilter);
  item('SHARPEN', t(markTr('Máscara de enfoque…')), mFilter);
  item('NOISE', t(markTr('Añadir ruido…')), mFilter);
  item('PIXELATE', t(markTr('Pixelar…')), mFilter);
  sep();
  item('EDGES', t(markTr('Hallar bordes')), mFilter);
  item('EMBOSS', t(markTr('Relieve')), mFilter);
  item('VIGNETTE', t(markTr('Viñeta…')), mFilter);
  menu(mView);
  item('ZOOM_IN', t(markTr('Acercar')), mView);
  item('ZOOM_OUT', t(markTr('Alejar')), mView);
  item('FIT', t(markTr('Encajar en la ventana')), mView);
  item('ACTUAL', t(markTr('Tamaño real (100 %)')), mView);
  sep();
  item('GRID', t(markTr('Cuadrícula de píxeles')), mView);
  item('FULLSCREEN', t(markTr('Pantalla completa')), mView);
  menu(mHelp);
  item('KEYS', t(markTr('Atajos de teclado')), mHelp);
  item('ABOUT', t(markTr('Acerca de Editor de imágenes')), mHelp);

  // ---- los textos del código (namespace tx)
  final texts = <String, String>{
    'APP': app,
    ...paths,
    ...labels,
    'DEC': t(markTr(',')),
    'OK': t(markTr('Aceptar')),
    'CANCEL': t(markTr('Cancelar')),
    'SAVE': t(markTr('Guardar')),
    'DISCARD': t(markTr('Descartar')),
    'ASK_DISCARD': t(markTr('Hay cambios sin guardar. ¿Descartarlos?')),
    'ALPHA': t(markTr('Alfa')),
    'BACKGROUND': t(markTr('Fondo')),
    'LAYER_1': t(markTr('Capa 1')),
    'LAYER_N': t(markTr('Capa {0}')),
    'LAYER_N_PREFIX': t(markTr('Capa ')),
    'LAYER_COPY': t(markTr('{0} copia')),
    'UNTITLED': t(markTr('Sin título-{0}')),
    'SAMPLE_NAME': t(markTr('Atardecer en el Malecón')),
    'SAMPLE_PALM': t(markTr('Palmera')),
    'SAMPLE_STARS': t(markTr('Estrellas')),
    'SAMPLE_TEXT': t(markTr('La Habana')),
    'TEXT_DEFAULT': t(markTr('Escriba su texto')),
    // Modos de fusión
    'B_NORMAL': t(markTr('Normal')),
    'B_MULTIPLY': t(markTr('Multiplicar')),
    'B_SCREEN': tc(markTrc('image', 'Trama')),
    'B_OVERLAY': t(markTr('Superponer')),
    'B_DARKEN': tc(markTrc('image', 'Oscurecer')),
    'B_LIGHTEN': tc(markTrc('image', 'Aclarar')),
    'B_DIFFERENCE': t(markTr('Diferencia')),
    'B_ADD': t(markTr('Sobreexponer lineal (añadir)')),
    // Herramientas y lo que hacen
    'T_MOVE': t(markTr('Mover')),
    'T_MARQUEE': t(markTr('Marco rectangular')),
    'T_CROP': tc(markTrc('image', 'Recortar')),
    'T_BRUSH': t(markTr('Pincel')),
    'T_ERASER': tc(markTrc('image', 'Borrador')),
    'T_FILL': t(markTr('Bote de pintura')),
    'T_GRADIENT': t(markTr('Degradado')),
    'T_SHAPE': t(markTr('Formas')),
    'T_TEXT': t(markTr('Texto')),
    'T_PICKER': t(markTr('Cuentagotas')),
    'T_HAND': tc(markTrc('image', 'Mano')),
    'T_ZOOM': t(markTr('Zoom')),
    'H_MOVE': t(
      markTr(
        'Arrastre para mover la capa activa · flechas: 1 px (Mayús: 10 px) · V',
      ),
    ),
    'H_MARQUEE': t(
      markTr(
        'Arrastre para seleccionar (Mayús: un cuadrado); dentro de la selección, para moverla · M',
      ),
    ),
    'H_CROP': t(
      markTr(
        'Ajuste el marco y pulse Intro (o doble clic) para recortar · Esc cancela · C',
      ),
    ),
    'H_BRUSH': t(
      markTr(
        'Pinta con el color frontal · [ y ] cambian el tamaño · Mayús+clic: línea recta · B',
      ),
    ),
    'H_ERASER': t(
      markTr(
        'Borra a transparente en la capa activa · [ y ] cambian el tamaño · E',
      ),
    ),
    'H_FILL': t(
      markTr('Rellena con el color frontal el área de color parecido · G'),
    ),
    'H_GRADIENT': t(
      markTr('Arrastre del color frontal al de fondo (Mayús: cada 45°) · R'),
    ),
    'H_SHAPE': t(
      markTr(
        'Arrastre para dibujar la forma en una capa nueva (Mayús: proporcional) · U',
      ),
    ),
    'H_TEXT': t(markTr('Haga clic donde empieza el texto · T')),
    'H_PICKER': t(markTr('Clic: color frontal · Alt+clic: color de fondo · I')),
    'H_HAND': t(
      markTr(
        'Arrastre para mover la vista (o mantenga pulsada la barra espaciadora) · H',
      ),
    ),
    'H_ZOOM': t(
      markTr(
        'Clic: acercar · Alt+clic: alejar · Ctrl+rueda con cualquier herramienta · Z',
      ),
    ),
    // La barra de opciones
    'O_SIZE': t(markTr('Tamaño')),
    'O_HARDNESS': t(markTr('Dureza')),
    'O_OPACITY': t(markTr('Opacidad')),
    'O_TOLERANCE': t(markTr('Tolerancia')),
    'O_CONTIGUOUS': t(markTr('Contiguo')),
    'O_LINEAR': t(markTr('Lineal')),
    'O_RADIAL': t(markTr('Radial')),
    'O_GRAD_HINT': t(markTr('Del color frontal al de fondo')),
    'O_RECT': t(markTr('Rectángulo')),
    'O_ROUNDED': t(markTr('Redondeado')),
    'O_ELLIPSE': t(markTr('Elipse')),
    'O_SHAPE_HINT': t(markTr('Con el color frontal, en una capa nueva')),
    'O_BOLD': t(markTr('Negrita')),
    'O_RATIO': tc(markTrc('image', 'Proporción')),
    'O_FREE': t(markTr('Libre')),
    'O_ORIGINAL': t(markTr('Original')),
    'O_APPLY': t(markTr('Aplicar')),
    'O_SEL_SIZE': t(markTr('Selección: {0} × {1} px')),
    'O_LAYER_POS': t(markTr('Capa «{0}» en {1}, {2}')),
    'O_SAMPLE': tc(markTrc('image', 'Muestra')),
    'O_CUR_LAYER': t(markTr('Capa actual')),
    'O_ALL_LAYERS': t(markTr('Todas las capas')),
    'O_FIT': t(markTr('Encajar')),
    // Los paneles
    'P_COLOR': t(markTr('Color')),
    'P_LAYERS': t(markTr('Capas')),
    'P_HISTORY': t(markTr('Historial')),
    // Los cuadros de diálogo
    'NEW_TITLE': t(markTr('Nuevo documento')),
    'OPEN_TITLE': t(markTr('Abrir imagen')),
    'PLACE_TITLE': t(markTr('Abrir como capa')),
    'SAVE_TITLE': t(markTr('Guardar como')),
    'JPEG_TITLE': t(markTr('Guardar como JPEG')),
    'TEXT_TITLE': t(markTr('Texto')),
    'LAYER_TITLE': t(markTr('Propiedades de capa')),
    'HEX_TITLE': t(markTr('Color')),
    'F_IMAGES': t(markTr('Imágenes')),
    'F_ALL_FILES': t(markTr('Todos los archivos')),
    'F_PROJECT': t(markTr('Proyecto con capas')),
    'F_WIDTH': t(markTr('Ancho')),
    'F_HEIGHT': tc(markTrc('image', 'Alto')),
    'F_NOW': t(markTr('Ahora: {0} × {1} px')),
    'F_KEEP': t(markTr('Mantener las proporciones')),
    'F_RESAMPLE': t(markTr('Remuestreo')),
    'RS_NEAREST': t(markTr('Vecino más próximo (píxeles nítidos)')),
    'RS_BILINEAR': t(markTr('Bilineal')),
    'RS_BICUBIC': t(markTr('Bicúbica (más suave)')),
    'F_ANCHOR': t(markTr('Ancla')),
    'F_ANGLE': t(markTr('Ángulo')),
    'F_BACKGROUND': t(markTr('Fondo')),
    'BG_WHITE': t(markTr('Blanco')),
    'BG_TRANSPARENT': t(markTr('Transparente')),
    'BG_COLOR': t(markTr('Color de fondo')),
    'F_BRIGHTNESS': t(markTr('Brillo')),
    'F_CONTRAST': t(markTr('Contraste')),
    'F_HUE': t(markTr('Tono')),
    'F_SATURATION': t(markTr('Saturación')),
    'F_LIGHTNESS': t(markTr('Luminosidad')),
    'F_IN_BLACK': t(markTr('Negro de entrada')),
    'F_GAMMA': t(markTr('Gamma')),
    'F_IN_WHITE': t(markTr('Blanco de entrada')),
    'F_OUT_BLACK': t(markTr('Negro de salida')),
    'F_OUT_WHITE': t(markTr('Blanco de salida')),
    'F_LEVEL': tc(markTrc('image', 'Nivel')),
    'F_LEVELS': tc(markTrc('image', 'Niveles')),
    'F_RADIUS': t(markTr('Radio')),
    'F_AMOUNT': t(markTr('Cantidad')),
    'F_THRESHOLD': t(markTr('Umbral')),
    'F_MONO': t(markTr('Monocromático')),
    'F_CELL': t(markTr('Tamaño de celda')),
    'F_SIZE': t(markTr('Tamaño')),
    'F_QUALITY': t(markTr('Calidad')),
    'F_EST_SIZE': t(markTr('Tamaño aproximado: {0} KB')),
    'F_TEXT': t(markTr('Texto')),
    'F_FONT': t(markTr('Fuente')),
    'F_NAME': t(markTr('Nombre')),
    'F_MODE': t(markTr('Modo de fusión')),
    'F_HEX': t(markTr('Código (hex.)')),
    'F_HEX_HINT': t(markTr('Seis cifras hexadecimales, por ejemplo FF8800')),
    // Los pasos del historial
    'S_SAMPLE': t(markTr('Imagen de ejemplo')),
    'S_OPEN': t(markTr('Abrir')),
    'S_NEW': t(markTr('Nuevo')),
    'S_PLACE': t(markTr('Abrir como capa')),
    'S_MOVE': t(markTr('Mover')),
    'S_BRUSH': t(markTr('Pincel')),
    'S_ERASER': tc(markTrc('image', 'Borrador')),
    'S_FILL': t(markTr('Rellenar')),
    'S_GRADIENT': t(markTr('Degradado')),
    'S_SHAPE': t(markTr('Forma')),
    'S_TEXT': t(markTr('Texto')),
    'S_CROP': tc(markTrc('image', 'Recortar')),
    'S_CUT': t(markTr('Cortar')),
    'S_PASTE': t(markTr('Pegar')),
    'S_CLEAR': t(markTr('Borrar la selección')),
    'S_SHOW': t(markTr('Mostrar capa')),
    'S_HIDE': t(markTr('Ocultar capa')),
    'S_OPACITY': t(markTr('Opacidad de capa')),
    'S_BLEND': t(markTr('Modo de fusión')),
    'S_LAYER_NEW': t(markTr('Nueva capa')),
    'S_LAYER_DUP': t(markTr('Duplicar capa')),
    'S_LAYER_DEL': t(markTr('Eliminar capa')),
    'S_LAYER_UP': t(markTr('Subir capa')),
    'S_LAYER_DOWN': t(markTr('Bajar capa')),
    'S_MERGE': t(markTr('Combinar hacia abajo')),
    'S_FLATTEN': t(markTr('Acoplar imagen')),
    'S_LAYER_PROPS': t(markTr('Propiedades de capa')),
    // Avisos
    'MSG_OPENED': t(markTr('{0} · {1} × {2} px')),
    'MSG_SAVED': t(markTr('Guardado: {0}')),
    'MSG_FLAT': t(markTr('las capas van combinadas en el archivo')),
    'MSG_COPIED': t(markTr('Copiado (también en el portapapeles del sistema)')),
    'MSG_EMPTY_CLIP': t(markTr('No hay ninguna imagen que pegar')),
    'MSG_HIDDEN': t(
      markTr('La capa activa está oculta: muéstrela para pintar en ella'),
    ),
    'MSG_LAST_LAYER': t(markTr('La imagen debe tener al menos una capa')),
    'MSG_NOTHING': t(markTr('No hay nada que copiar en la capa activa')),
    'MSG_NO_SEL': t(
      markTr('Primero seleccione un área con el marco rectangular (M)'),
    ),
    'ERR_OPEN': t(markTr('No se pudo abrir {0}: {1}')),
    'ERR_SAVE': t(markTr('No se pudo guardar {0}: {1}')),
    'ERR_READ': t(markTr('no se puede leer')),
    'ERR_WRITE': t(markTr('no se puede escribir')),
    'ERR_FORMAT': t(
      markTr('el formato no se reconoce o el archivo está dañado'),
    ),
    'KEYS_TEXT': t(
      markTr(
        'Herramientas: V mover, M marco, C recortar, B pincel, E borrador, G bote de pintura, R degradado, U formas, T texto, I cuentagotas, H mano, Z zoom.\n\nColores: D pone el frontal negro y el fondo blanco; X los intercambia.\nPincel y borrador: [ y ] cambian el tamaño; Mayús+clic traza una línea recta.\nVista: Ctrl+rueda, Ctrl+= y Ctrl+- para el zoom; Ctrl+0 encaja la imagen; Ctrl+1, tamaño real; la barra espaciadora y arrastrar mueven la vista.\nSelección: Ctrl+A todo, Ctrl+D nada; Supr borra lo seleccionado.\nRecortar: Intro aplica y Esc cancela.\nDeshacer y rehacer: Ctrl+Z y Mayús+Ctrl+Z, o un clic en el panel Historial.\n\nEn macOS, Ctrl es la tecla Comando. Arrastre una imagen a la ventana para abrirla.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: un editor de imágenes por capas hecho en C++17 con FLTK {0}. La ventana y el menú se diseñaron en el Diseñador del estudio; las herramientas, los paneles, los filtros y los codificadores JPEG y BMP están en el código de Form1.cpp, sin más bibliotecas. Guarde en .dmi para conservar las capas.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');

  // ---- la ventana: el menú, el reloj de las hormigas y el área de trabajo
  final design =
      TkDesign(
          width: 1200,
          height: 780,
          target: tkTargetCpp,
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
            1140,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // La selección parpadea («hormigas») y los avisos se apagan solos.
          _w(
            'Timer',
            'Tick',
            1100,
            8,
            32,
            32,
            {'interval': 120},
            {'command': 'Tick_timer'},
          ),
          _w('Frame', 'Workspace', 0, 0, 1200, 780, {'bg': '#1e1e1e'}),
          // Solo para el Diseñador: el editor la oculta al arrancar.
          _w('Label', 'WorkspaceHint', 150, 370, 900, 40, {
            'text': t(
              markTr(
                'Las herramientas, el lienzo y los paneles los dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#8f8f8f',
            'bg': '#1e1e1e',
            'font_size': 15,
          })..parent = 'Workspace',
        ]);

  final code =
      '''// ${t(markTr('Editor de imágenes en C++ con FLTK: capas con modos de fusión, pincel, recortar, cambiar el tamaño, girar, ajustes, filtros y PNG, JPEG y BMP.'))}
$_imageEditorIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_imageEditorCode''';
  return TkExample(
    'cpp_image_editor',
    t(markTr('Editor de imágenes (C++)')),
    t(
      markTr(
        'Un editor de imágenes nativo en C++ con FLTK, al estilo de los programas de retoque: capas con opacidad y modos de fusión, pincel, borrador, bote, degradado, formas y texto, recortar, cambiar el tamaño, girar y voltear, niveles, tono y saturación, filtros, historial y PNG, JPEG y BMP.',
      ),
    ),
    design,
    code,
  );
}

const _imageEditorIncludes = r'''#include <algorithm>
#include <array>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>
#include <FL/Fl_Copy_Surface.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Menu_Item.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Pixmap.H>
#include <FL/Fl_Shared_Image.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef __APPLE__
#include <FL/platform.H>
#endif
''';
