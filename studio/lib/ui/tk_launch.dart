import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../code/tk_run.dart';
import '../core/project_store.dart';
import '../i18n/i18n.dart';
import 'widgets.dart';

/// Abre la dirección de una aplicación web (las pruebas no abren nada).
Future<bool> Function(String url) tkOpenBrowser = (url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Abre [run] en el navegador; si no se puede, lo dice.
Future<void> openTkWebApp(BuildContext context, TkRun run) async {
  final url = run.url;
  if (url == null) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  var opened = false;
  try {
    opened = await tkOpenBrowser(url);
  } on Object {
    opened = false;
  }
  if (!opened) {
    messenger?.showSnackBar(
      SnackBar(content: Text(tr('No se pudo abrir el navegador.'))),
    );
  }
}

/// Ejecuta el proyecto de la carpeta [id] tal como está guardado: genera su
/// Python en `build/`, comprueba el Python del equipo (y Flask, si es web),
/// lo lanza y, si es web, abre el navegador.
Future<TkRun?> launchTkApp(BuildContext context, String id) async {
  // Ya en marcha, su secreto sigue valiendo: basta con volver a la página.
  final live = TkRunner.runOf(id);
  if (live != null && live.running && live.url != null) {
    await openTkWebApp(context, live);
    return live;
  }
  if (!TkRunner.supported) {
    final py = await TkRunner.detect();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(py.help)));
    }
    return null;
  }
  final prepared = await runAction(context, () => ProjectStore.prepareRun(id));
  if (prepared == null || !context.mounted) return null;
  final found = await TkRunner.detect();
  final py = prepared.web ? found.web : found;
  if (!context.mounted) return null;
  if (!py.ok) {
    await showTkPythonMissing(context, py, web: prepared.web);
    return null;
  }
  if (prepared.web) {
    final install = await TkRunner.missingFlask(py);
    if (!context.mounted) return null;
    if (install != null) {
      await showTkFlaskMissing(context, install);
      return null;
    }
  }
  if (prepared.tray) {
    final install = await TkRunner.missingTray(py);
    if (!context.mounted) return null;
    if (install != null && !await showTkTrayMissing(context, install)) {
      return null;
    }
    if (!context.mounted) return null;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  final run = await runAction(context, () => TkRunner.start(prepared));
  if (run == null) return null;
  if (run.url != null && context.mounted) await openTkWebApp(context, run);
  // Sin el panel de salida a la vista (desde la galería), si falla se avisa.
  void ended() {
    if (run.running) return;
    run.removeListener(ended);
    if (run.exitCode == 0 || run.stopped) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          tr('«{0}» terminó con un error: {1}', [
            run.name,
            run.lines.lastOrNull ?? run.exitCode,
          ]),
        ),
      ),
    );
  }

  run.addListener(ended);
  return run;
}

/// Falta Flask en el Python de este equipo: la orden exacta para instalarlo.
Future<void> showTkFlaskMissing(
  BuildContext context,
  String install,
) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    key: const ValueKey('tk-flask-missing'),
    title: Text(tr('Falta Flask')),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              'Las aplicaciones web necesitan Flask en el Python de este equipo. Instálelo con esta orden:',
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            install,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(tr('Después, vuelva a intentarlo.')),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Cerrar'))),
    ],
  ),
);

/// Faltan pystray y Pillow para el icono de bandeja: la orden para
/// instalarlos. Se puede ejecutar igualmente (sin icono). Devuelve si se
/// ejecuta.
Future<bool> showTkTrayMissing(BuildContext context, String install) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('tk-tray-missing'),
        title: Text(tr('Faltan pystray y Pillow')),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  'El icono de bandeja necesita pystray y Pillow en el Python de este equipo. Instálelos con esta orden:',
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                install,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(tr('Sin ellos, la ventana funciona pero sin el icono.')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(tr('Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('Ejecutar sin icono')),
          ),
        ],
      ),
    ) ??
    false;

/// Falta Python o le falta tkinter: qué instalar.
Future<void> showTkPythonMissing(
  BuildContext context,
  TkPython py, {
  bool web = false,
}) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    key: const ValueKey('tk-python-missing'),
    title: Text(web ? tr('Falta Python') : tr('Falta Python con tkinter')),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (py.withoutTk != null) ...[
            Text(tr('Se encontró {0}, pero no trae tkinter.', [py.withoutTk])),
            const SizedBox(height: 8),
          ],
          SelectableText(py.help),
          const SizedBox(height: 8),
          Text(tr('Después, vuelva a intentarlo.')),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          TkRunner.forgetPython();
          Navigator.pop(c);
        },
        child: Text(tr('Cerrar')),
      ),
    ],
  ),
);
