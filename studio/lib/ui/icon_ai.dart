import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ai/assistant.dart';
import '../core/errors.dart';
import '../i18n/tr.dart';
import 'widgets.dart';

/// Lo que se le pide a la IA para dibujar un icono.
const _system =
    'You design application icons. Reply with ONE complete SVG document and '
    'nothing else: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" '
    'width="512" height="512">…</svg>. Modern, flat, clean and recognisable at '
    '32 px: a rounded-square background filling the canvas, one bold central '
    'symbol, at most 4 colours, good contrast. No text or letters unless the '
    'request asks for them. No external references, images, fonts, scripts or '
    'filters.';

/// El SVG de la respuesta (null: no hay uno usable).
String? svgOf(String reply) {
  final m = RegExp(
    r'<svg[\s\S]*?</svg>',
    caseSensitive: false,
  ).firstMatch(reply);
  if (m == null) return null;
  final svg = m[0]!;
  // Nada que cargue o ejecute algo de fuera.
  if (RegExp(
    r'<script|href\s*=\s*"(?!#)|<foreignObject',
    caseSensitive: false,
  ).hasMatch(svg)) {
    return null;
  }
  return svg;
}

/// [svg] como PNG de [size] × [size].
Future<List<int>> svgToPng(String svg, {int size = 512}) async {
  final info = await vg.loadPicture(SvgStringLoader(svg), null);
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final w = info.size.width <= 0 ? size.toDouble() : info.size.width;
  final h = info.size.height <= 0 ? size.toDouble() : info.size.height;
  canvas.scale(size / w, size / h);
  canvas.drawPicture(info.picture);
  final image = await rec.endRecording().toImage(size, size);
  info.picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) throw UserError(tr('No se pudo dibujar el icono.'));
  return bytes.buffer.asUint8List();
}

/// Pide a la IA un icono a partir de [prompt] y devuelve el SVG.
Future<String> generateIconSvg(String prompt) async {
  final config = await AiConfig.load();
  final reply = await Assistant(config: config).chat([
    {'role': 'system', 'content': _system},
    {'role': 'user', 'content': 'Icon for: $prompt'},
  ]);
  final svg = svgOf(reply);
  if (svg == null) {
    throw UserError(tr('La IA no devolvió un icono válido. Pruebe otra vez.'));
  }
  return svg;
}

/// Diálogo «Generar con IA»: describe el icono, lo dibuja la IA y se ve
/// antes de usarlo. Devuelve el PNG (y el SVG) en [dir]/images, o null.
Future<String?> showAiIconDialog(
  BuildContext context, {
  required String dir,
  required String suggestion,
}) => showDialog<String>(
  context: context,
  builder: (_) => _IconDialog(dir: dir, suggestion: suggestion),
);

class _IconDialog extends StatefulWidget {
  const _IconDialog({required this.dir, required this.suggestion});
  final String dir;
  final String suggestion;

  @override
  State<_IconDialog> createState() => _IconDialogState();
}

class _IconDialogState extends State<_IconDialog> {
  late final _prompt = TextEditingController(text: widget.suggestion);
  String? _svg;
  bool _busy = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _prompt.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    final svg = await runAction(context, () => generateIconSvg(text));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (svg != null) _svg = svg;
    });
  }

  Future<void> _use() async {
    final svg = _svg;
    if (svg == null) return;
    final rel = await runAction(context, () async {
      final png = await svgToPng(svg);
      final images = Directory('${widget.dir}${Platform.pathSeparator}images');
      await images.create(recursive: true);
      await File(
        '${images.path}${Platform.pathSeparator}app_icon.png',
      ).writeAsBytes(png);
      await File(
        '${images.path}${Platform.pathSeparator}app_icon.svg',
      ).writeAsString(svg);
      return 'images/app_icon.png';
    });
    if (rel != null && mounted) Navigator.pop(context, rel);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AlertDialog(
      key: const ValueKey('tk-icon-ai'),
      title: Text(tr('Generar el icono con IA')),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('tk-icon-prompt'),
              controller: _prompt,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: tr('Describa el icono'),
                hintText: tr('Por ejemplo: una calculadora azul, estilo plano'),
              ),
              onSubmitted: (_) => _generate(),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: t.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: _busy
                    ? const CircularProgressIndicator()
                    : _svg == null
                    ? Text(
                        tr('Aquí se verá el icono.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.hintColor, fontSize: 12),
                      )
                    : SvgPicture.string(_svg!, width: 160, height: 160),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Lo dibuja la IA de Ajustes en SVG; se guarda como PNG de 512 × 512 en images/app_icon.png.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: t.hintColor, fontSize: 11.5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancelar')),
        ),
        TextButton(
          key: const ValueKey('tk-icon-generate'),
          onPressed: _busy ? null : _generate,
          child: Text(_svg == null ? tr('Generar') : tr('Otra versión')),
        ),
        FilledButton(
          key: const ValueKey('tk-icon-use'),
          onPressed: _busy || _svg == null ? null : _use,
          child: Text(tr('Usar este icono')),
        ),
      ],
    );
  }
}
