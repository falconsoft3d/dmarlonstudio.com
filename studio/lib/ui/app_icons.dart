import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../code/tk_model.dart';
import '../core/errors.dart';
import '../i18n/tr.dart';
import 'app_icon_set.dart';

export 'app_icon_set.dart' show AppIconDef, appIconSet;

/// Los colores de los iconos: un degradado de claro (arriba) a oscuro.
const appIconColors = <(Color, Color)>[
  (Color(0xFF60A5FA), Color(0xFF1D4ED8)), // azul
  (Color(0xFF5AC8FA), Color(0xFF1F7FD6)), // celeste
  (Color(0xFF2DD4BF), Color(0xFF0B7F79)), // turquesa
  (Color(0xFF34D399), Color(0xFF0F8A5F)), // verde
  (Color(0xFFA3E635), Color(0xFF4D8C0B)), // lima
  (Color(0xFFFFC53D), Color(0xFFE08E0B)), // ámbar
  (Color(0xFFFF7A59), Color(0xFFE8433B)), // naranja
  (Color(0xFFFF6B6B), Color(0xFFC81E1E)), // rojo
  (Color(0xFFFF6B9D), Color(0xFFD6246E)), // rosa
  (Color(0xFFA78BFA), Color(0xFF6D3FD6)), // violeta
  (Color(0xFFA2708A), Color(0xFF5A3A52)), // ciruela
  (Color(0xFF4B5D7A), Color(0xFF1C2A44)), // pizarra
];

/// El icono que lleva o llevaría un proyecto: uno del catálogo y un color.
class AppIconPick {
  const AppIconPick(this.icon, this.color);
  final AppIconDef icon;
  final int color;

  /// Cómo se guarda en el proyecto (props['app_icon_auto']): nombre:color.
  String get key => '${icon.name}:$color';

  static AppIconPick? parse(String? key) {
    final parts = (key ?? '').split(':');
    if (parts.length != 2) return null;
    final icon = appIconSet.where((e) => e.name == parts[0]).firstOrNull;
    final color = int.tryParse(parts[1]);
    if (icon == null || color == null || color < 0) return null;
    return AppIconPick(icon, color % appIconColors.length);
  }
}

/// [s] en minúsculas y sin acentos.
String _plain(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = from.indexOf(c);
    b.write(i < 0 ? c : to[i]);
  }
  return b.toString();
}

/// Las palabras de [text], también de dos en dos (recursos-humanos) y sin
/// la s del plural.
List<String> _words(String text) {
  final w = _plain(
    text,
  ).split(RegExp(r'[^a-z0-9]+')).where((e) => e.length > 1).toList();
  return [
    for (var i = 0; i < w.length; i++) ...[
      w[i],
      if (i + 1 < w.length) '${w[i]}-${w[i + 1]}',
    ],
  ];
}

/// FNV-1a: el mismo número para el mismo texto en todas las versiones (el
/// hashCode de Dart no lo garantiza).
int _hash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Los que sirven para cualquier aplicación: cuando el nombre no dice nada.
const _generic = [
  'rocket',
  'star',
  'sparkles',
  'zap',
  'shapes',
  'layers',
  'gem',
  'compass',
  'blocks',
  'box',
  'boxes',
  'component',
  'puzzle',
  'lightbulb',
  'target',
  'atom',
  'orbit',
  'flame',
  'leaf',
  'sun',
  'moon-star',
  'crown',
  'diamond',
  'globe',
  'feather',
  'palette',
  'wand-sparkles',
  'workflow',
  'cpu',
  'heart',
];

/// El icono que le toca a un proyecto por su nombre (y su descripción): el
/// del catálogo cuyas palabras más coinciden (las del nombre valen más) y,
/// si ninguna coincide, uno fijo para ese nombre. El color sale del nombre.
AppIconPick autoAppIcon(String name, [String? description]) {
  final title = _words(name);
  final more = _words(description ?? '');
  AppIconDef? best;
  var bestScore = 0;
  for (final icon in appIconSet) {
    final es = icon.es.split(' ').toSet();
    final en = icon.en.split(' ').toSet();
    int score(String w) {
      final singular = w.length > 3 && w.endsWith('s')
          ? w.substring(0, w.length - (w.endsWith('es') ? 2 : 1))
          : w;
      if (es.contains(w) || es.contains(singular)) return 6;
      if (en.contains(w) || en.contains(singular)) return 3;
      return 0;
    }

    var s = 0;
    for (final w in title) {
      s += score(w) * 2;
    }
    for (final w in more) {
      s += score(w);
    }
    if (s > bestScore) {
      best = icon;
      bestScore = s;
    }
  }
  final h = _hash(_plain(name.trim()));
  final generic = [
    for (final n in _generic) ...appIconSet.where((e) => e.name == n),
  ];
  return AppIconPick(
    best ?? generic[h % generic.length],
    (h >> 8) % appIconColors.length,
  );
}

/// [pick] como PNG de [size] × [size]: un cuadrado redondeado con el
/// degradado y el símbolo en blanco (con el margen de los iconos de macOS).
Future<List<int>> renderAppIcon(AppIconPick pick, {int size = 1024}) async {
  final s = size.toDouble();
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final body = Rect.fromLTWH(s * .098, s * .09, s * .804, s * .804);
  final shape = RRect.fromRectAndRadius(body, Radius.circular(s * .182));
  final (light, dark) = appIconColors[pick.color];
  // Sombra suave debajo.
  canvas.drawRRect(
    shape.shift(Offset(0, s * .016)),
    Paint()
      ..color = const Color(0x47000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .014),
  );
  canvas.drawRRect(
    shape,
    Paint()
      ..shader = ui.Gradient.linear(
        body.topCenter.translate(-body.width * .18, 0),
        body.bottomCenter.translate(body.width * .18, 0),
        [light, dark],
      ),
  );
  // Brillo arriba a la izquierda.
  canvas.save();
  canvas.clipRRect(shape);
  canvas.drawRect(
    body,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(body.left + body.width * .3, body.top),
        body.width * .75,
        [const Color(0x47FFFFFF), const Color(0x00FFFFFF)],
      ),
  );
  canvas.restore();
  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(pick.icon.icon.codePoint),
      style: TextStyle(
        fontFamily: pick.icon.icon.fontFamily,
        package: pick.icon.icon.fontPackage,
        fontSize: s * .5,
        color: Colors.white,
        shadows: [
          Shadow(
            color: const Color(0x38000000),
            offset: Offset(0, s * .01),
            blurRadius: s * .014,
          ),
        ],
      ),
    ),
  )..layout();
  glyph.paint(canvas, body.center - Offset(glyph.width / 2, glyph.height / 2));
  final image = await rec.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) throw UserError(tr('No se pudo dibujar el icono.'));
  return bytes.buffer.asUint8List();
}

/// Ruta del icono dentro del proyecto.
const appIconPath = 'images/app_icon.png';

/// Dibuja [pick] en [dir]/images/app_icon.png y lo pone como icono de [d].
/// [auto]: lo eligió el estudio (y lo cambia si cambia el nombre); si no,
/// lo eligió el usuario y se queda.
Future<void> writeAppIcon(
  String dir,
  TkDesign d,
  AppIconPick pick, {
  required bool auto,
}) async {
  final png = await renderAppIcon(pick);
  final file = File(
    '$dir${Platform.pathSeparator}${appIconPath.replaceAll('/', Platform.pathSeparator)}',
  );
  await file.parent.create(recursive: true);
  await file.writeAsBytes(png);
  d.appIcon = appIconPath;
  if (auto) {
    d.props['app_icon_auto'] = pick.key;
  } else {
    d.props.remove('app_icon_auto');
  }
}

/// ¿Lleva [d] un icono que el estudio puede poner o cambiar solo? Sí si no
/// tiene ninguno o el que tiene lo puso el estudio.
bool appIconIsAuto(TkDesign d) =>
    d.appIcon == null || d.props['app_icon_auto'] is String;

/// Los destinos con ventana (o página) llevan icono; la consola y las apps
/// de Flutter por pantallas, no.
bool appIconApplies(TkDesign d) => !d.isConsole && !d.isScreens;

/// Pone el icono automático a un proyecto que no tiene (o que tiene el
/// automático de otro nombre). Devuelve true si lo cambió.
Future<bool> ensureAutoAppIcon(
  String dir,
  TkDesign d,
  String name, [
  String? description,
]) async {
  if (!appIconApplies(d) || !appIconIsAuto(d)) return false;
  final pick = autoAppIcon(name, description);
  final now = d.props['app_icon_auto'];
  final file = File(
    '$dir${Platform.pathSeparator}images${Platform.pathSeparator}app_icon.png',
  );
  if (now == pick.key && d.appIcon == appIconPath && file.existsSync()) {
    return false;
  }
  await writeAppIcon(dir, d, pick, auto: true);
  return true;
}

/// La vista de un icono del catálogo en la interfaz (sin pasar por PNG).
class AppIconTile extends StatelessWidget {
  const AppIconTile(this.pick, {super.key, this.size = 48});
  final AppIconPick pick;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (light, dark) = appIconColors[pick.color];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .226),
        gradient: LinearGradient(
          begin: const Alignment(-.36, -1),
          end: const Alignment(.36, 1),
          colors: [light, dark],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(pick.icon.icon, color: Colors.white, size: size * .6),
    );
  }
}

/// Galería con los 500 iconos y los colores: devuelve el elegido o null.
Future<AppIconPick?> showAppIconGallery(
  BuildContext context, {
  required AppIconPick initial,
}) => showDialog<AppIconPick>(
  context: context,
  builder: (_) => _Gallery(initial: initial),
);

class _Gallery extends StatefulWidget {
  const _Gallery({required this.initial});
  final AppIconPick initial;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _search = TextEditingController();
  late AppIconDef _icon = widget.initial.icon;
  late int _color = widget.initial.color;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppIconDef> get _shown {
    final q = _words(_search.text).where((w) => !w.contains('-')).toList();
    if (q.isEmpty) return appIconSet;
    return [
      for (final i in appIconSet)
        if (q.every(
          (w) => '${i.name} ${i.es} ${i.en}'
              .split(RegExp(r'[ -]'))
              .any((k) => k.startsWith(w)),
        ))
          i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final shown = _shown;
    return AlertDialog(
      key: const ValueKey('tk-icon-gallery'),
      title: Text(tr('Icono de la aplicación')),
      content: SizedBox(
        width: 560,
        height: 470,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIconTile(AppIconPick(_icon, _color), size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    key: const ValueKey('tk-icon-search'),
                    controller: _search,
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: tr('Buscar: tienda, música, calendar…'),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var c = 0; c < appIconColors.length; c++)
                  InkWell(
                    key: ValueKey('tk-icon-color-$c'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [appIconColors[c].$1, appIconColors[c].$2],
                        ),
                        border: Border.all(
                          width: 2.5,
                          color: c == _color
                              ? t.colorScheme.onSurface
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        tr('Ningún icono con esas palabras.'),
                        style: TextStyle(color: t.hintColor),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 54,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final icon = shown[i];
                        final on = icon.name == _icon.name;
                        return Tooltip(
                          message: icon.name,
                          waitDuration: const Duration(milliseconds: 500),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _icon = icon),
                            onDoubleTap: () => Navigator.pop(
                              context,
                              AppIconPick(icon, _color),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: on
                                    ? t.colorScheme.primary.withValues(
                                        alpha: .16,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                icon.icon,
                                size: 24,
                                color: on
                                    ? t.colorScheme.primary
                                    : t.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          key: const ValueKey('tk-icon-gallery-use'),
          onPressed: () => Navigator.pop(context, AppIconPick(_icon, _color)),
          child: Text(tr('Usar este icono')),
        ),
      ],
    );
  }
}
