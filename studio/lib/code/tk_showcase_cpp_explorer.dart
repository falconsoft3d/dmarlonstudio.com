part of 'tk_examples.dart';

// ------------------------------------------ explorador de archivos (C++)
/// Un explorador de archivos nativo en C++17 con FLTK, con el aspecto claro
/// y azulado de los exploradores de la época de Aero: árbol de carpetas que
/// se carga al abrirlo, vista de iconos grandes, lista y detalles (con
/// columnas que ordenan), pestañas, historial, barra de direcciones con
/// migas, marcadores (con su diálogo, su menú y su barra), copiar, cortar,
/// pegar, cambiar el nombre, eliminar (a la Papelera y siempre preguntando),
/// propiedades con el tamaño calculado en otro hilo, abrir con la aplicación
/// del sistema, archivos ocultos, filtro y barra de estado. Los iconos se
/// dibujan en código: no hay archivos de imagen.
TkExample tkCppExplorer(String Function(String) t) {
  final app = t(markTr('Explorador de archivos'));
  // Con contexto (msgctxt «explorer»): «Equipo» es el ordenador y
  // «Acciones», lo que se hace, no las de bolsa.
  String tc(String id) {
    final k = contextKey('explorer', id);
    final r = t(k);
    return r == k ? id : r;
  }

  // ---- menús: el texto del diseño y la ruta de cada opción para el código
  final mFile = t(markTr('Archivo')), mEdit = t(markTr('Edición'));
  final mView = t(markTr('Ver')),
      mActions = tc(markTrc('explorer', 'Acciones'));
  final mMarks = t(markTr('Marcadores')), mTools = t(markTr('Herramientas'));
  final mHelp = t(markTr('Ayuda')), mSort = t(markTr('Ordenar por'));
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
  item('OPEN', t(markTr('Abrir')), mFile);
  item('OPEN_TAB', t(markTr('Abrir en una pestaña nueva')), mFile);
  sep();
  item('NEW_TAB', t(markTr('Nueva pestaña')), mFile);
  item('CLOSE_TAB', t(markTr('Cerrar la pestaña')), mFile);
  sep();
  item('NEW_FOLDER', t(markTr('Nueva carpeta')), mFile);
  item('RENAME', t(markTr('Cambiar nombre')), mFile);
  item('DELETE', t(markTr('Eliminar')), mFile);
  item('DELETE_NOW', t(markTr('Eliminar definitivamente')), mFile);
  sep();
  item('PROPS', t(markTr('Propiedades')), mFile);
  sep();
  item('QUIT', t(markTr('Cerrar')), mFile);
  menu(mEdit);
  item('CUT', t(markTr('Cortar')), mEdit);
  item('COPY', t(markTr('Copiar')), mEdit);
  item('PASTE', t(markTr('Pegar')), mEdit);
  sep();
  item('COPY_PATH', t(markTr('Copiar la ruta')), mEdit);
  sep();
  item('SELECT_ALL', t(markTr('Seleccionar todo')), mEdit);
  item('INVERT', t(markTr('Invertir la selección')), mEdit);
  menu(mView);
  item('VIEW_ICONS', t(markTr('Iconos grandes')), mView);
  item('VIEW_LIST', t(markTr('Lista')), mView);
  item('VIEW_DETAILS', t(markTr('Detalles')), mView);
  sep();
  lines.add('  $mSort');
  final sort = '$mView/$mSort';
  item('SORT_NAME', t(markTr('Nombre')), sort, 2);
  item('SORT_DATE', t(markTr('Fecha de modificación')), sort, 2);
  item('SORT_TYPE', t(markTr('Tipo')), sort, 2);
  item('SORT_SIZE', t(markTr('Tamaño')), sort, 2);
  sep(2);
  item('SORT_DESC', t(markTr('Descendente')), sort, 2);
  sep();
  item('SHOW_TREE', t(markTr('Panel de carpetas')), mView);
  item('SHOW_MARKS', t(markTr('Barra de marcadores')), mView);
  item('SHOW_DETAILS', t(markTr('Panel de detalles')), mView);
  sep();
  final mTheme = t(markTr('Tema'));
  lines.add('  $mTheme');
  final theme = '$mView/$mTheme';
  item('THEME_LIGHT', t(markTr('Claro')), theme, 2);
  item('THEME_DARK', t(markTr('Oscuro')), theme, 2);
  item('THEME_SYSTEM', t(markTr('Del sistema')), theme, 2);
  sep();
  item('SHOW_HIDDEN', t(markTr('Archivos ocultos')), mView);
  sep();
  item('REFRESH', t(markTr('Actualizar')), mView);
  menu(mActions);
  item('BACK', t(markTr('Atrás')), mActions);
  item('FORWARD', t(markTr('Adelante')), mActions);
  item('UP', t(markTr('Subir un nivel')), mActions);
  sep();
  item('HOME', t(markTr('Carpeta personal')), mActions);
  item('DESKTOP', t(markTr('Escritorio')), mActions);
  item('COMPUTER', tc(markTrc('explorer', 'Equipo')), mActions);
  sep();
  item('GOTO', t(markTr('Ir a la dirección…')), mActions);
  item('FIND', t(markTr('Buscar')), mActions);
  menu(mMarks);
  item('ADD_MARK', t(markTr('Añadir marcador…')), mMarks);
  item('ORGANIZE', t(markTr('Organizar marcadores…')), mMarks);
  sep();
  menu(mTools);
  item('TERMINAL', t(markTr('Abrir un terminal aquí')), mTools);
  item(
    'REVEAL',
    t(markTr('Mostrar en el gestor de archivos del sistema')),
    mTools,
  );
  menu(mHelp);
  item('KEYS', t(markTr('Atajos de teclado')), mHelp);
  item('ABOUT', t(markTr('Acerca del Explorador de archivos')), mHelp);

  // ---- los textos del código (namespace tx)
  final texts = <String, String>{
    'APP': app,
    'DECIMAL': t(markTr(',')),
    'DATE_FMT': t(markTr('%d/%m/%Y %H:%M')),
    'M_MARKS': mMarks,
    'M_VIEW': mView,
    'M_SORT': mSort,
    ...paths,
    ...labels,
    'BYTES': t(markTr('{0} bytes')),
    'TYPE_FOLDER': t(markTr('Carpeta de archivos')),
    'TYPE_TEXT': t(markTr('Documento de texto')),
    'TYPE_IMAGE': t(markTr('Imagen {0}')),
    'TYPE_AUDIO': t(markTr('Audio {0}')),
    'TYPE_VIDEO': t(markTr('Vídeo {0}')),
    'TYPE_ARCHIVE': t(markTr('Archivo comprimido {0}')),
    'TYPE_PDF': t(markTr('Documento PDF')),
    'TYPE_CODE': t(markTr('Código fuente {0}')),
    'TYPE_WEB': t(markTr('Página web {0}')),
    'TYPE_APP': t(markTr('Aplicación')),
    'TYPE_SHEET': t(markTr('Hoja de cálculo {0}')),
    'TYPE_SLIDES': t(markTr('Presentación {0}')),
    'TYPE_DOC': t(markTr('Documento {0}')),
    'TYPE_FONT': t(markTr('Fuente {0}')),
    'TYPE_DISK': t(markTr('Imagen de disco {0}')),
    'TYPE_FILE': t(markTr('Archivo {0}')),
    'TYPE_NOEXT': t(markTr('Archivo')),
    'TYPE_LINK': t(markTr('{0} (enlace)')),
    'TYPE_DRIVE': t(markTr('Disco local')),
    'TYPE_REMOVABLE': t(markTr('Unidad extraíble')),
    'TYPE_NETDRIVE': t(markTr('Unidad de red')),
    'TYPE_CD': t(markTr('Unidad de CD o DVD')),
    'COMPUTER': tc(markTrc('explorer', 'Equipo')),
    'QUICK': t(markTr('Acceso rápido')),
    'DESKTOP': t(markTr('Escritorio')),
    'DOWNLOADS': t(markTr('Descargas')),
    'DOCUMENTS': t(markTr('Documentos')),
    'PICTURES': t(markTr('Imágenes')),
    'MUSIC': t(markTr('Música')),
    'VIDEOS': t(markTr('Vídeos')),
    'TRASH': t(markTr('Papelera')),
    'COL_NAME': t(markTr('Nombre')),
    'COL_DATE': t(markTr('Fecha de modificación')),
    'COL_TYPE': t(markTr('Tipo')),
    'COL_SIZE': t(markTr('Tamaño')),
    'COL_FREE': t(markTr('Espacio disponible')),
    'COL_TOTAL': t(markTr('Tamaño total')),
    'EMPTY': t(markTr('Esta carpeta está vacía.')),
    'NO_MATCH': t(markTr('Ningún elemento coincide con la búsqueda.')),
    'ERR_DENIED': t(
      markTr('No tiene permiso para ver el contenido de esta carpeta.'),
    ),
    'ERR_LIST': t(markTr('No se puede abrir esta carpeta: {0}')),
    'N_ITEMS': tc(markTrc('explorer', '{0} elementos')),
    'ONE_ITEM': t(markTr('1 elemento')),
    'N_SELECTED': t(markTr('{0} elementos seleccionados')),
    'ONE_SELECTED': t(markTr('1 elemento seleccionado')),
    'FREE_SPACE': t(markTr('Espacio libre: {0}')),
    'FILTERED': t(markTr('Se muestran {0} de {1}')),
    'FREE_OF': t(markTr('{0} libres de {1}')),
    'D_MODIFIED': t(markTr('Fecha de modificación: {0}')),
    'D_SIZE': t(markTr('Tamaño: {0}')),
    'D_FREE': t(markTr('Espacio disponible: {0}')),
    'D_TOTAL': t(markTr('Tamaño total: {0}')),
    'SEARCH_IN': t(markTr('Buscar en {0}')),
    'TAB_NEW': t(markTr('Nueva pestaña')),
    'TAB_CLOSE': t(markTr('Cerrar la pestaña')),
    'TAB_OTHERS': t(markTr('Cerrar las demás pestañas')),
    'MARKS_HINT': t(
      markTr(
        'Para tener aquí una carpeta, pulse {0} y marque «Mostrar en la barra de marcadores».',
      ),
    ),
    'NO_MARKS': t(markTr('(Sin marcadores)')),
    'ADD_MARK_TITLE': t(markTr('Añadir marcador')),
    'EDIT_MARK_TITLE': t(markTr('Editar marcador')),
    'F_NAME': t(markTr('Nombre:')),
    'F_CREATE_IN': t(markTr('Crear en:')),
    'F_NEW_FOLDER': t(markTr('Nueva carpeta…')),
    'F_LOCATION': t(markTr('Ubicación:')),
    'F_DESC': t(markTr('Descripción:')),
    'F_ON_BAR': t(markTr('Mostrar en la barra de marcadores')),
    'OK': t(markTr('Aceptar')),
    'CANCEL': t(markTr('Cancelar')),
    'ASK_MARK_FOLDER': t(markTr('Nombre de la carpeta nueva de marcadores:')),
    'ERR_MARK_NAME': t(markTr('Escriba un nombre para el marcador.')),
    'ERR_MARK_PATH': t(markTr('La ubicación no existe: {0}')),
    'ORGANIZE_TITLE': t(markTr('Organizar marcadores')),
    'B_OPEN': t(markTr('Abrir')),
    'B_EDIT': t(markTr('Editar…')),
    'B_DELETE': t(markTr('Eliminar')),
    'B_UP': t(markTr('Subir')),
    'B_DOWN': t(markTr('Bajar')),
    'B_CLOSE': t(markTr('Cerrar')),
    'ASK_DELETE_MARK': t(markTr('¿Eliminar el marcador «{0}»?')),
    'MARK_DELETE_NOTE': t(
      markTr('La carpeta no se toca: solo se quita el marcador.'),
    ),
    'DEL_ONE': t(markTr('¿Seguro que desea mover «{0}» a la Papelera?')),
    'DEL_MANY': t(
      markTr('¿Seguro que desea mover estos {0} elementos a la Papelera?'),
    ),
    'DEL_NOW_ONE': t(
      markTr('¿Seguro que desea eliminar «{0}» definitivamente?'),
    ),
    'DEL_NOW_MANY': t(
      markTr('¿Seguro que desea eliminar estos {0} elementos definitivamente?'),
    ),
    'DEL_NOW_NOTE': t(markTr('No se podrán recuperar.')),
    'DEL_NOTE': t(markTr('Podrá recuperarlos desde la Papelera.')),
    'B_TRASH': t(markTr('Mover a la Papelera')),
    'B_DELETE_NOW': t(markTr('Eliminar definitivamente')),
    'TRASH_FAILED': t(markTr('No se pudo mover a la Papelera:')),
    'TRASH_FAILED_ASK': t(
      markTr('¿Desea eliminarlo definitivamente? No se podrá recuperar.'),
    ),
    'ERR_RENAME': t(markTr('No se pudo cambiar el nombre: {0}')),
    'ERR_BAD_NAME': t(
      markTr('El nombre no puede contener ninguno de estos caracteres: {0}'),
    ),
    'ERR_EXISTS': t(
      markTr('Ya existe un elemento llamado «{0}» en esta carpeta.'),
    ),
    'ASK_EXT': t(
      markTr(
        'Si cambia la extensión, puede que el archivo deje de abrirse. ¿Desea cambiarla?',
      ),
    ),
    'B_YES': t(markTr('Sí')),
    'B_NO': t(markTr('No')),
    'NEW_FOLDER_NAME': t(markTr('Nueva carpeta')),
    'ERR_NEW_FOLDER': t(markTr('No se pudo crear la carpeta: {0}')),
    'COPY_SUFFIX': t(markTr(' - copia')),
    'JOB_COPY': t(markTr('Copiando {0} elementos a «{1}»')),
    'JOB_MOVE': t(markTr('Moviendo {0} elementos a «{1}»')),
    'JOB_DELETE': t(markTr('Eliminando {0} elementos')),
    'JOB_COUNTING': t(markTr('Calculando…')),
    'JOB_FILES': t(markTr('{0} de {1} archivos')),
    'JOB_ERRORS': t(markTr('No se pudieron completar algunas operaciones:')),
    'ERR_INTO_ITSELF': t(
      markTr('No se puede copiar ni mover «{0}» dentro de sí misma.'),
    ),
    'CONFLICT_TEXT': t(markTr('Ya hay un elemento llamado «{0}» en «{1}».')),
    'CONFLICT_ASK': t(markTr('¿Qué desea hacer?')),
    'B_REPLACE': t(markTr('Reemplazar')),
    'B_KEEP_BOTH': t(markTr('Conservar ambos')),
    'B_SKIP': t(markTr('Omitir')),
    'CONFLICT_ALL': t(markTr('Hacer lo mismo con los demás conflictos')),
    'ERR_OPEN': t(markTr('No se pudo abrir «{0}».')),
    'ERR_NOT_FOUND': t(
      markTr(
        'No se encuentra «{0}». Compruebe la ortografía e inténtelo de nuevo.',
      ),
    ),
    'ERR_TERMINAL': t(markTr('No se pudo abrir el terminal.')),
    'PROPS_TITLE': t(markTr('Propiedades de {0}')),
    'P_TYPE': t(markTr('Tipo:')),
    'P_LOCATION': t(markTr('Ubicación:')),
    'P_SIZE': t(markTr('Tamaño:')),
    'P_CONTAINS': t(markTr('Contiene:')),
    'P_CREATED': t(markTr('Creado:')),
    'P_MODIFIED': t(markTr('Modificado:')),
    'P_ACCESSED': t(markTr('Último acceso:')),
    'P_ATTRS': t(markTr('Atributos:')),
    'P_READONLY': t(markTr('Solo lectura')),
    'P_HIDDEN': t(markTr('Oculto')),
    'P_COUNTING': t(markTr('Calculando…')),
    'P_CONTAINS_FMT': t(markTr('{0} archivos, {1} carpetas')),
    'P_SIZE_FMT': t(markTr('{0} ({1} bytes)')),
    'P_VARIOUS': t(markTr('Varios tipos')),
    'P_TARGET': t(markTr('Destino:')),
    'P_FREE': t(markTr('Espacio libre:')),
    'P_TOTAL': t(markTr('Capacidad:')),
    'KEYS_EXTRA': t(
      markTr(
        'Escriba las primeras letras de un nombre para ir a él. Doble clic o Intro abre; Retroceso vuelve atrás; Esc cancela el cambio de nombre o borra la búsqueda.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: un explorador de archivos nativo hecho en C++17 con FLTK {0}. La ventana se diseñó en el Diseñador del estudio; el resto es el código de Form1.cpp.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');

  // ---- la ventana: cada banda es un marco; el código dibuja lo de dentro
  TkWidget inside(TkWidget w, String frame) => w..parent = frame;
  TkWidget tool(String name, int x, int y, int w, int h, String text) => _w(
    'Button',
    name,
    x,
    y,
    w,
    h,
    {'text': text},
    {'command': '${name}_click'},
  );
  TkWidget label(
    String name,
    int x,
    int y,
    int w,
    int h,
    String text, {
    bool bold = false,
    String fg = '#5a6779',
  }) => _w('Label', name, x, y, w, h, {
    'text': text,
    'anchor': 'w',
    'fg': fg,
    if (bold) 'font_bold': true,
  });
  final design =
      TkDesign(
          width: 1100,
          height: 680,
          target: tkTargetCpp,
          props: {
            'title': app,
            'bg': '#e9eef6',
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
            'Watch',
            1000,
            8,
            32,
            32,
            {'interval': 2000},
            {'command': 'Watch_timer'},
          ),
          // ---- navegación: atrás, adelante, dirección y búsqueda
          _w('Frame', 'NavBar', 0, 0, 1100, 40, {'bg': '#d8e5f4'}),
          inside(tool('Back', 8, 6, 28, 28, t(markTr('Atrás'))), 'NavBar'),
          inside(
            tool('Forward', 38, 6, 28, 28, t(markTr('Adelante'))),
            'NavBar',
          ),
          inside(
            _w('Entry', 'Address', 74, 8, 694, 24, {}, {
              'enter_key': 'Address_enter',
            }),
            'NavBar',
          ),
          inside(
            tool('Refresh', 768, 8, 26, 24, t(markTr('Actualizar'))),
            'NavBar',
          ),
          inside(
            _w('Entry', 'Search', 806, 8, 286, 24, {}, {
              'enter_key': 'Search_enter',
            }),
            'NavBar',
          ),
          // ---- barra de órdenes
          _w('Frame', 'CommandBar', 0, 40, 1100, 32, {'bg': '#edf3fa'}),
          inside(
            tool('Up', 6, 3, 30, 26, t(markTr('Subir un nivel'))),
            'CommandBar',
          ),
          inside(
            tool('Folders', 40, 3, 96, 26, t(markTr('Carpetas'))),
            'CommandBar',
          ),
          inside(
            tool('NewFolder', 146, 3, 30, 26, t(markTr('Nueva carpeta'))),
            'CommandBar',
          ),
          inside(
            tool('Cut', 186, 3, 30, 26, t(markTr('Cortar'))),
            'CommandBar',
          ),
          inside(
            tool('Copy', 218, 3, 30, 26, t(markTr('Copiar'))),
            'CommandBar',
          ),
          inside(
            tool('Paste', 250, 3, 30, 26, t(markTr('Pegar'))),
            'CommandBar',
          ),
          inside(
            tool('Delete', 290, 3, 30, 26, t(markTr('Eliminar'))),
            'CommandBar',
          ),
          inside(
            tool('Properties', 322, 3, 30, 26, t(markTr('Propiedades'))),
            'CommandBar',
          ),
          inside(
            tool(
              'Hidden',
              980,
              3,
              30,
              26,
              t(markTr('Mostrar los archivos ocultos')),
            ),
            'CommandBar',
          ),
          inside(
            tool('ViewIcons', 1012, 3, 28, 26, t(markTr('Iconos grandes'))),
            'CommandBar',
          ),
          inside(
            tool('ViewList', 1040, 3, 28, 26, t(markTr('Lista'))),
            'CommandBar',
          ),
          inside(
            tool('ViewDetails', 1068, 3, 28, 26, t(markTr('Detalles'))),
            'CommandBar',
          ),
          // ---- marcadores, pestañas, árbol y vista (los rellena el código)
          _w('Frame', 'BookmarkBar', 0, 72, 1100, 26, {'bg': '#f1f5fb'}),
          _w('Frame', 'TabBar', 0, 98, 1100, 28, {'bg': '#e3ebf6'}),
          _w('Frame', 'TreeHost', 0, 126, 240, 466, {'bg': '#ffffff'}),
          _w('Frame', 'ViewHost', 245, 126, 855, 466, {'bg': '#ffffff'}),
          // ---- panel de detalles y barra de estado
          _w('Frame', 'DetailsPane', 0, 592, 1100, 64, {'bg': '#eef3f9'}),
          inside(
            label(
              'DetailName',
              76,
              10,
              420,
              20,
              app,
              bold: true,
              fg: '#1e395b',
            ),
            'DetailsPane',
          ),
          inside(
            label(
              'DetailType',
              76,
              32,
              420,
              18,
              t(markTr('Carpeta de archivos')),
            ),
            'DetailsPane',
          ),
          inside(label('DetailInfo', 520, 10, 560, 18, ''), 'DetailsPane'),
          inside(label('DetailMore', 520, 32, 560, 18, ''), 'DetailsPane'),
          _w('StatusBar', 'Status', 0, 656, 1100, 24, {
            'text': t(markTr('Listo')),
          }),
        ]);

  final code =
      '''// ${t(markTr('Explorador de archivos en C++ con FLTK: árbol de carpetas, vistas de iconos, lista y detalles, pestañas, marcadores, copiar y pegar, Papelera y propiedades.'))}
$_explorerIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_explorerCode''';
  return TkExample(
    'cpp_explorer',
    t(markTr('Explorador de archivos (C++)')),
    t(
      markTr(
        'Un explorador de archivos nativo en C++ con FLTK, con el aspecto azulado de Aero: árbol de carpetas, iconos grandes, lista y detalles, pestañas, marcadores, copiar y pegar, Papelera, propiedades y filtro.',
      ),
    ),
    design,
    code,
  );
}

const _explorerIncludes = r'''#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <thread>
#include <FL/Fl_Hold_Browser.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Menu_Item.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_Scrollbar.H>
#include <FL/Fl_Tooltip.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <FL/x.H>
#else
#include <pwd.h>
#include <spawn.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
extern char** environ;
#endif
#ifdef __APPLE__
#include <mach-o/dyld.h>
#include <objc/message.h>
#include <objc/runtime.h>
#endif
''';
