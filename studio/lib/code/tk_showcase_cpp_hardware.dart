part of 'tk_examples.dart';

// ------------------------------------------ inspector del equipo (C++)
/// Un inspector del equipo en C++17 con FLTK: lee el sistema, el procesador,
/// la memoria, el modelo y el firmware, los gráficos y las pantallas, el
/// almacenamiento, la red, la batería, el audio y los periféricos (en macOS
/// con sysctl y system_profiler; en Windows con la API de Win32 y
/// PowerShell), enseña el uso en directo cada segundo y guarda un informe en
/// PDF (o lo imprime, o lo guarda como texto).
TkExample tkCppHardware(String Function(String) t) {
  final app = t(markTr('Inspector del equipo'));
  // Con contexto (msgctxt «hardware»): palabras que en otros sitios
  // significan otra cosa («Modelo» del equipo, «Estado» de la batería…).
  String tc(String id) {
    final k = contextKey('hardware', id);
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
  lines.add(mFile);
  item('REFRESH', t(markTr('Analizar de nuevo')), mFile);
  sep();
  item('PDF', t(markTr('Guardar el informe en PDF…')), mFile);
  item('PRINT', t(markTr('Imprimir el informe…')), mFile);
  item('TXT', t(markTr('Guardar el informe como texto…')), mFile);
  item('COPY', t(markTr('Copiar el informe')), mFile);
  sep();
  item('QUIT', t(markTr('Salir')), mFile);
  lines.add(mView);
  item('SERIALS', t(markTr('Mostrar números de serie')), mView);
  item('LIVE', t(markTr('Lecturas en directo')), mView);
  lines.add(mHelp);
  item('HOW', t(markTr('Cómo funciona')), mHelp);
  item('ABOUT', t(markTr('Acerca de Inspector del equipo')), mHelp);

  // ---- las secciones (la lista de la izquierda y el informe)
  final sections = <String, String>{
    'S_SUMMARY': t(markTr('Resumen')),
    'S_OS': t(markTr('Sistema operativo')),
    'S_CPU': t(markTr('Procesador')),
    'S_MEMORY': t(markTr('Memoria')),
    'S_BOARD': t(markTr('Modelo y firmware')),
    'S_GRAPHICS': t(markTr('Gráficos y pantallas')),
    'S_STORAGE': t(markTr('Almacenamiento')),
    'S_NETWORK': t(markTr('Red')),
    'S_POWER': t(markTr('Batería y energía')),
    'S_AUDIO': t(markTr('Audio')),
    'S_DEVICES': t(markTr('Periféricos')),
  };

  // ---- los textos del código (namespace tx)
  final texts = <String, String>{
    'APP': app,
    ...paths,
    ...labels,
    ...sections,
    'LOCALE': t(markTr('es-ES')),
    'DEC': t(markTr(',')),
    'DATE_FMT': t(markTr('%d/%m/%Y %H:%M')),
    'PCT': t(markTr('{0} %')),
    'DUR_DH': t(markTr('{0} d {1} h')),
    'DUR_HM': t(markTr('{0} h {1} min')),
    'DUR_M': t(markTr('{0} min')),
    'YES': t(markTr('Sí')),
    'NO': t(markTr('No')),
    'GOOD': tc(markTrc('hardware', 'Buena')),
    'VERIFIED': t(markTr('Verificado')),
    'SERVICE': t(markTr('Revisión recomendada')),
    'BUILTIN': t(markTr('integrada')),
    'UNKNOWN': t(markTr('Desconocido')),
    'NEVER': t(markTr('Nunca')),
    'BOOT_NORMAL': t(markTr('Normal')),
    'BOOT_SAFE': t(markTr('Modo seguro')),
    'HIDDEN': '••••••••',
    'NONE': '—',
    'STARTUP_DISK': t(markTr('Disco de arranque')),
    'LOCAL_DISK': t(markTr('Disco local')),
    'REMOVABLE_DISK': t(markTr('Disco extraíble')),
    // Los grupos.
    'G_OVERVIEW': t(markTr('El equipo')),
    'G_NOW': t(markTr('En este momento')),
    'G_SYSTEM': t(markTr('Sistema')),
    'G_PROCESSOR': tc(markTrc('hardware', 'Procesador')),
    'G_CACHES': t(markTr('Cachés')),
    'G_MEMORY': tc(markTrc('hardware', 'Memoria')),
    'G_MODULES': t(markTr('Módulos de memoria')),
    'G_MODEL': tc(markTrc('hardware', 'Modelo')),
    'G_BOARD': t(markTr('Placa base')),
    'G_FIRMWARE': t(markTr('Firmware (BIOS/UEFI)')),
    'G_DISPLAY': t(markTr('Pantalla: {0}')),
    'G_DRIVES': t(markTr('Discos')),
    'G_INACTIVE': t(markTr('Otras interfaces (sin conexión)')),
    'G_BATTERY': t(markTr('Batería')),
    'G_POWER': t(markTr('Energía')),
    'G_CHARGER': t(markTr('Cargador')),
    'G_AUDIO_DEVICES': t(markTr('Dispositivos de audio')),
    'G_USB': 'USB',
    'G_BLUETOOTH': 'Bluetooth',
    'G_BT_CONNECTED': t(markTr('Bluetooth: conectados')),
    'G_BT_PAIRED': t(markTr('Bluetooth: emparejados, sin conectar')),
    'G_INPUT': t(markTr('Teclados, ratones y otros')),
    // Las filas.
    'K_COMPUTER': t(markTr('Nombre del equipo')),
    'K_MODEL': tc(markTrc('hardware', 'Modelo')),
    'K_OS': t(markTr('Sistema operativo')),
    'K_CPU': tc(markTrc('hardware', 'Procesador')),
    'K_MEMORY': tc(markTrc('hardware', 'Memoria')),
    'K_GPU': t(markTr('Gráficos')),
    'K_DISPLAYS': t(markTr('Pantallas')),
    'K_STORAGE': t(markTr('Almacenamiento')),
    'K_NETWORK': t(markTr('Red')),
    'K_BATTERY': t(markTr('Batería')),
    'K_BUILD': t(markTr('Compilación')),
    'K_KERNEL': t(markTr('Núcleo del sistema')),
    'K_ARCH': t(markTr('Arquitectura')),
    'K_BOOTED': t(markTr('Encendido el')),
    'K_UPTIME': t(markTr('Tiempo encendido')),
    'K_BOOT_VOLUME': t(markTr('Volumen de arranque')),
    'K_BOOT_MODE': t(markTr('Modo de arranque')),
    'K_USER': t(markTr('Usuario')),
    'K_SIP': t(markTr('Protección de la integridad del sistema')),
    'K_SECURE_VM': t(markTr('Memoria virtual segura')),
    'K_INSTALLED': t(markTr('Instalado el')),
    'K_OWNER': t(markTr('Propietario registrado')),
    'K_VENDOR': t(markTr('Fabricante')),
    'K_CORES': t(markTr('Núcleos')),
    'K_THREADS': t(markTr('Hilos')),
    'K_FREQ': t(markTr('Frecuencia')),
    'K_MAX_FREQ': t(markTr('Frecuencia máxima')),
    'K_SOCKET': t(markTr('Zócalo')),
    'K_VIRT': t(markTr('Virtualización')),
    'K_L1I': t(markTr('L1 (instrucciones)')),
    'K_L1D': t(markTr('L1 (datos)')),
    'K_L2': 'L2',
    'K_L2_P': t(markTr('L2 (núcleos de rendimiento)')),
    'K_L2_E': t(markTr('L2 (núcleos de eficiencia)')),
    'K_L3': 'L3',
    'K_LINE': t(markTr('Línea de caché')),
    'K_TOTAL': t(markTr('Total')),
    'K_MEM_TYPE': tc(markTrc('hardware', 'Tipo')),
    'K_MAKER': t(markTr('Fabricante')),
    'K_SIZE': t(markTr('Capacidad')),
    'K_SPEED': t(markTr('Velocidad')),
    'K_PART': t(markTr('Número de pieza')),
    'K_MODEL_NAME': t(markTr('Nombre del modelo')),
    'K_MODEL_ID': t(markTr('Identificador del modelo')),
    'K_MODEL_NUMBER': t(markTr('Número de modelo')),
    'K_CHIP': t(markTr('Chip')),
    'K_FIRMWARE': t(markTr('Versión del firmware')),
    'K_LOADER': t(markTr('Cargador del sistema')),
    'K_SERIAL': t(markTr('Número de serie')),
    'K_HW_UUID': t(markTr('UUID del hardware')),
    'K_ACTIVATION_LOCK': t(markTr('Bloqueo de activación')),
    'K_SYSTEM_TYPE': t(markTr('Tipo de sistema')),
    'K_PRODUCT': t(markTr('Producto')),
    'K_VERSION': t(markTr('Versión')),
    'K_DATE': t(markTr('Fecha')),
    'K_GPU_CORES': t(markTr('Núcleos de la GPU')),
    'K_VRAM': t(markTr('Memoria de vídeo')),
    'K_METAL': 'Metal',
    'K_BUS': t(markTr('Bus')),
    'K_DRIVER': t(markTr('Controlador')),
    'K_RESOLUTION': t(markTr('Resolución')),
    'K_LOOKS_LIKE': t(markTr('Se ve como')),
    'K_DISPLAY_TYPE': t(markTr('Tipo de pantalla')),
    'K_CONNECTION': t(markTr('Conexión')),
    'K_MAIN': t(markTr('Pantalla principal')),
    'K_MIRROR': t(markTr('Duplicada')),
    'K_ROTATION': t(markTr('Se puede girar')),
    'K_MADE': t(markTr('Fabricada')),
    'K_MOUNT': t(markTr('Punto de montaje')),
    'K_FS': t(markTr('Sistema de archivos')),
    'K_CAPACITY': t(markTr('Capacidad')),
    'K_FREE': t(markTr('Libre')),
    'K_DRIVE': t(markTr('Disco físico')),
    'K_MEDIUM': t(markTr('Tipo de disco')),
    'K_PROTOCOL': t(markTr('Conexión del disco')),
    'K_INTERNAL': t(markTr('Interno')),
    'K_SMART': 'S.M.A.R.T.',
    'K_HEALTH': tc(markTrc('hardware', 'Estado')),
    'K_WRITABLE': t(markTr('Se puede escribir')),
    'K_INTERFACE': t(markTr('Interfaz')),
    'K_KIND': tc(markTrc('hardware', 'Tipo')),
    'K_IPV4': t(markTr('Dirección IPv4')),
    'K_SUBNET': t(markTr('Máscara de subred')),
    'K_ROUTER': t(markTr('Router')),
    'K_DNS': 'DNS',
    'K_CONFIG': tc(markTrc('hardware', 'Configuración')),
    'K_MAC': t(markTr('Dirección MAC')),
    'K_LINK_SPEED': t(markTr('Velocidad del enlace')),
    'K_CHARGE': tc(markTrc('hardware', 'Carga')),
    'K_STATE': t(markTr('Situación')),
    'K_CYCLES': t(markTr('Ciclos de carga')),
    'K_MAX_CAPACITY': t(markTr('Capacidad máxima')),
    'K_BATTERY_MODEL': t(markTr('Modelo de la batería')),
    'K_SOURCE': tc(markTrc('hardware', 'Alimentación')),
    'K_LOW_POWER': t(markTr('Modo de bajo consumo')),
    'K_DISPLAY_SLEEP': t(markTr('Apagar la pantalla tras')),
    'K_SYSTEM_SLEEP': t(markTr('Reposo del equipo tras')),
    'K_CONNECTED': t(markTr('Conectado')),
    'K_WATTS': t(markTr('Potencia')),
    'K_NAME': t(markTr('Nombre')),
    'K_OUTPUT': t(markTr('Salida')),
    'K_INPUT': tc(markTrc('hardware', 'Entrada')),
    'K_SAMPLE_RATE': t(markTr('Frecuencia de muestreo')),
    'K_DEFAULT_OUT': t(markTr('Salida predeterminada')),
    'K_DEFAULT_IN': t(markTr('Entrada predeterminada')),
    'K_CHIPSET': t(markTr('Chipset')),
    'K_BT_ON': t(markTr('Encendido')),
    'K_TRANSPORT': tc(markTrc('hardware', 'Transporte')),
    'K_CPU_USE': t(markTr('Uso del procesador')),
    'K_MEM_USE': t(markTr('Memoria en uso')),
    'K_LOAD': t(markTr('Carga media (1, 5 y 15 min)')),
    // Los valores.
    'CORES_PE': t(markTr('{0} núcleos ({1} de rendimiento y {2} de eficiencia)')),
    'CORES_THREADS': t(markTr('{0} núcleos, {1} hilos')),
    'CORES_N': t(markTr('{0} núcleos')),
    'PER_CORE': t(markTr('{0} por núcleo')),
    'GPU_CORES_N': t(markTr('{0} núcleos de GPU')),
    'WEEK_YEAR': t(markTr('semana {0} de {1}')),
    'PLUS_N': t(markTr('(y {0} más)')),
    'CHANNELS_N': t(markTr('{0} canales')),
    'OF_TOTAL': t(markTr('{0} de {1}')),
    'FREE_N': t(markTr('{0} libres')),
    'DISK_SUMMARY': t(markTr('{0}: {1}, {2} libres')),
    'BATTERY_SUMMARY': t(markTr('{0} · {1} ciclos · capacidad máxima {2}')),
    'CYCLES_N': t(markTr('{0} ciclos')),
    'CHARGING': t(markTr('Cargando')),
    'CHARGED': t(markTr('Cargada')),
    'DISCHARGING': t(markTr('Con la batería')),
    'SRC_AC': t(markTr('Adaptador de corriente')),
    'SRC_BATTERY': t(markTr('Batería')),
    'NO_BATTERY': t(markTr('Este equipo no tiene batería')),
    'NO_DEVICES': t(markTr('Nada conectado')),
    'DHCP': 'DHCP',
    'MANUAL': t(markTr('Manual')),
    // La pantalla.
    'ANALYZING': t(markTr('Analizando el equipo…')),
    'ANALYZED_AT': t(markTr('Analizado a las {0} · {1}')),
    'NOTHING_HERE': t(markTr('No hay datos de esta parte en este equipo.')),
    'UP_FOR': t(markTr('Encendido desde hace {0}')),
    'SINCE_BOOT': t(markTr('desde el {0}')),
    'CPU_NOW': t(markTr('Uso del procesador ahora')),
    'CPU_LAST_MIN': t(markTr('El procesador en el último minuto')),
    'CPU_CORES': t(markTr('Cada núcleo')),
    'MEM_NOW': t(markTr('La memoria ahora')),
    'MEM_APP': t(markTr('Apps')),
    'MEM_WIRED': tc(markTrc('hardware', 'Fija')),
    'MEM_COMPRESSED': t(markTr('Comprimida')),
    'MEM_CACHED': t(markTr('Archivos en caché')),
    'MEM_FREE': t(markTr('Libre')),
    'MEM_SWAP': t(markTr('Intercambio: {0} de {1}')),
    'DISKS_NOW': t(markTr('Espacio en los discos')),
    'NET_NOW': t(markTr('Tráfico de red ahora')),
    'NET_DOWN': t(markTr('Bajada')),
    'NET_UP': t(markTr('Subida')),
    'BATTERY_NOW': t(markTr('La batería ahora')),
    'WAITING': t(markTr('Midiendo…')),
    'CLICK_TO_COPY': t(markTr('Clic: copiar')),
    'COPIED': t(markTr('Copiado: {0}')),
    'SECRET_HINT': t(markTr('Oculto (Ver → Mostrar números de serie)')),
    'STATUS': t(markTr('{0} · analizado a las {1}')),
    'STATUS_LIVE': t(markTr('lecturas en directo cada segundo')),
    'STATUS_PAUSED': t(markTr('lecturas en directo en pausa')),
    // El informe.
    'REPORT_TITLE': t(markTr('Informe del equipo')),
    'REPORT_FILE': t(markTr('Informe del equipo')),
    'GENERATED': t(markTr('Generado el {0} con Inspector del equipo (DMarlon Studio)')),
    'PAGE_N': t(markTr('Página {0}')),
    'SAVED_PDF': t(markTr('Informe guardado: {0}')),
    'SAVED_TXT': t(markTr('Texto guardado: {0}')),
    'COPIED_REPORT': t(markTr('El informe está en el portapapeles')),
    'ERR_PDF': t(markTr('No se pudo crear el PDF: {0}')),
    'ERR_SAVE': t(markTr('No se pudo guardar: {0}')),
    'ERR_PRINT': t(markTr('No se pudo imprimir: {0}')),
    'OPEN_PDF': t(markTr('¿Abrir el informe?')),
    'OPEN': t(markTr('Abrir')),
    'CLOSE': t(markTr('Cerrar')),
    'PDF_FILTER': t(markTr('Documento PDF')),
    'TXT_FILTER': t(markTr('Texto')),
    'HOW_TEXT': t(
      markTr(
        'Al abrirse, la app lee lo que el sistema sabe del equipo: en macOS con sysctl y system_profiler; en Windows con la API de Win32 y PowerShell (Get-CimInstance); en Linux, con /proc. Nada sale del equipo.\n\nA la izquierda elija una parte: el resumen, el sistema, el procesador, la memoria, el modelo y el firmware, los gráficos y las pantallas, el almacenamiento, la red, la batería, el audio o los periféricos. El uso del procesador (de cada núcleo), la memoria, la red, los discos y la batería se miden cada segundo (Ver → Lecturas en directo).\n\nHaga clic en un dato para copiarlo. «Guardar el informe en PDF» crea un documento con todo lo que ve, listo para imprimir o enviar; también puede imprimirlo o guardarlo como texto. Los números de serie, el UUID, las direcciones MAC y el usuario se ocultan en la pantalla y en el informe salvo que active Ver → Mostrar números de serie.',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: un inspector del equipo hecho en C++17 con FLTK {0}. La ventana, la barra lateral y el menú se diseñaron en el Diseñador del estudio; la lectura del equipo, las gráficas y el informe en PDF están en el código de Form1.cpp.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      'const char* const $key = ${jsonEncode(value)};',
  ].join('\n');

  // ---- la ventana: la barra lateral con las secciones y el panel
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
          // Cada segundo: las lecturas en directo.
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
          _w('Frame', 'Side', 0, 0, 240, 736, {'bg': side}),
          lbl('LblComputer', 16, 14, 208, 24, tc(markTrc('hardware', 'Mi equipo')), {
            'font_size': 15,
            'font_bold': true,
          }),
          lbl('LblModel', 16, 38, 208, 36, '', {
            'font_size': 11,
            'fg': '#6b7280',
          }),
          _w(
            'Listbox',
            'Sections',
            16,
            82,
            208,
            372,
            {'items': sections.values.join('\n'), 'font_size': 14},
            {'select': 'Sections_select'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnRefresh',
            16,
            466,
            208,
            30,
            {'text': t(markTr('Analizar de nuevo'))},
            {'command': 'BtnRefresh_click'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnPdf',
            16,
            506,
            208,
            36,
            {
              'text': t(markTr('Guardar en PDF')),
              'bg': '#2563eb',
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnPdf_click'},
          )..parent = 'Side',
          _w(
            'Button',
            'BtnPrint',
            16,
            552,
            208,
            30,
            {'text': t(markTr('Imprimir'))},
            {'command': 'BtnPrint_click'},
          )..parent = 'Side',
          lbl(
            'LblHint',
            16,
            596,
            208,
            120,
            t(
              markTr(
                'Haga clic en un dato para copiarlo. Los números de serie se ocultan en la pantalla y en el informe: Ver → Mostrar números de serie.',
              ),
            ),
            {'font_size': 11, 'fg': '#6b7280'},
          ),
          _w('Frame', 'Results', 240, 0, 940, 736, {'bg': '#ffffff'}),
          // Solo para el Diseñador: la app la oculta al arrancar.
          _w('Label', 'ResultsHint', 170, 340, 600, 40, {
            'text': t(
              markTr(
                'Las secciones, las gráficas en directo y el informe los dibuja el código de Form1.cpp',
              ),
            ),
            'fg': '#6b7280',
            'bg': '#ffffff',
            'font_size': 14,
          })..parent = 'Results',
          _w('StatusBar', 'Status', 0, 736, 1180, 24, {'text': ''}),
        ]);

  final code =
      '''// ${t(markTr('Inspector del equipo en C++ con FLTK: lee el hardware y el sistema, mide el uso en directo y guarda un informe en PDF.'))}
$_hardwareIncludes
// Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
namespace tx {
$consts
}  // namespace tx
$_hardwareCode''';
  return TkExample(
    'cpp_hardware',
    t(markTr('Inspector del equipo (C++)')),
    t(
      markTr(
        'Un inspector del equipo nativo en C++ con FLTK: el sistema, el procesador, la memoria, los gráficos y las pantallas, los discos, la red, la batería, el audio y los periféricos, con el uso en directo y un informe para guardar en PDF o imprimir.',
      ),
    ),
    design,
    code,
  );
}

const _hardwareIncludes = r'''#include <algorithm>
#include <chrono>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <deque>
#include <functional>
#include <map>
#include <string>
#include <thread>
#include <utility>
#include <vector>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_PDF_File_Surface.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Printer.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <sys/stat.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#include <unistd.h>
#endif
#ifdef __APPLE__
#include <ifaddrs.h>
#include <mach/mach.h>
#include <net/if.h>
#include <sys/mount.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <sys/time.h>
#elif !defined(_WIN32)
#include <sys/statvfs.h>
#endif
''';
