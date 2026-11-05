import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../code/tk_cpp_run.dart';
import '../code/tk_console.dart';
import '../code/tk_pascal_run.dart';
import '../code/tk_debug.dart';
import '../code/tk_run.dart';
import '../core/errors.dart';
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
Future<TkRun?> launchTkApp(
  BuildContext context,
  String id, {
  bool debug = false,
  bool tests = false,
}) async {
  // Ya en marcha, su secreto sigue valiendo: basta con volver a la página.
  final live = TkRunner.runOf(id);
  if (!debug && !tests && live != null && live.running && live.url != null) {
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
  // C++: un compilador y FLTK (con «Instalar» si faltan).
  if (prepared.cpp) {
    if (tests) return null;
    for (final need in TkCppTools.needs()) {
      if (!context.mounted) return null;
      final go = await showTkInstall(context, const TkPython(help: ''), need);
      if (!go) return null;
    }
    if (!context.mounted) return null;
    return runAction(context, () => TkRunner.start(prepared, devtools: debug));
  }
  // Flutter, React Native y la web de React: el simulador (o el navegador)
  // se abre cuando la app está servida.
  if (prepared.flutter || prepared.reactNative || prepared.react) {
    if (tests) return null;
    final run = await runAction(context, () => TkRunner.start(prepared));
    if (run != null && !prepared.desktop) {
      void ready() {
        if (run.url == null) return;
        run.removeListener(ready);
        if (context.mounted) openTkWebApp(context, run);
      }

      run.addListener(ready);
    }
    return run;
  }
  // Consola: el compilador del lenguaje (Python ya está).
  if (prepared.console != null) {
    if (tests) return null;
    for (final need in TkConsole.needs(prepared.console!)) {
      if (!context.mounted) return null;
      final go = await showTkInstall(context, const TkPython(help: ''), need);
      if (!go) return null;
    }
    if (!context.mounted) return null;
    return runAction(context, () => TkRunner.start(prepared, devtools: debug));
  }
  // Pascal: Lazarus (con «Instalar» si falta).
  if (prepared.pascal) {
    if (tests) return null;
    for (final need in TkPascalTools.needs()) {
      if (!context.mounted) return null;
      final go = await showTkInstall(context, const TkPython(help: ''), need);
      if (!go) return null;
    }
    if (!context.mounted) return null;
    return runAction(context, () => TkRunner.start(prepared));
  }
  // Electron, Chrome y Next.js no usan Python: Node y el entorno compartido.
  if (prepared.electron || prepared.next) {
    if (tests) return null;
    await TkBreakpoints.load(id);
    if (!context.mounted) return null;
    final run = await runAction(
      context,
      () => TkRunner.start(prepared, devtools: debug),
    );
    if (run != null && prepared.next) {
      // El navegador se abre cuando Next.js está listo.
      void ready() {
        if (run.url == null) return;
        run.removeListener(ready);
        if (context.mounted) openTkWebApp(context, run);
      }

      run.addListener(ready);
    }
    return run;
  }
  final found = await TkRunner.detect();
  final py = prepared.web ? found.web : found;
  if (!context.mounted) return null;
  if (!py.ok) {
    await showTkPythonMissing(context, py, web: prepared.web);
    return null;
  }
  final needs = await TkRunner.needs(prepared, py);
  for (final need in needs) {
    if (!context.mounted) return null;
    final go = await showTkInstall(context, py, need);
    if (!go) return null;
  }
  if (!context.mounted) return null;
  final messenger = ScaffoldMessenger.maybeOf(context);
  TkDebugSession? session;
  if (debug || tests) {
    await TkBreakpoints.load(id);
    session = TkDebugSession(
      project: id,
      unitStart: prepared.unitStart,
      unitLines: prepared.unitLines,
      tests: tests,
      trace: debug,
      exceptionMode: TkDebugDefaults.exceptionMode,
    );
  }
  if (!context.mounted) return null;
  final run = await runAction(
    context,
    () => TkRunner.start(prepared, debug: session),
  );
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

  // Las pruebas que fallan ya se ven en su pestaña.
  if (!tests) run.addListener(ended);
  return run;
}

/// Le falta un paquete al Python de este equipo: lo instala con un botón
/// (o se copia la orden). Devuelve si se sigue con la ejecución: instalado,
/// o «Ejecutar sin él» si es opcional.
Future<bool> showTkInstall(
  BuildContext context,
  TkPython py,
  TkNeed need,
) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => _InstallDialog(py: py, need: need),
    ) ??
    false;

class _InstallDialog extends StatefulWidget {
  const _InstallDialog({required this.py, required this.need});

  final TkPython py;
  final TkNeed need;

  @override
  State<_InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends State<_InstallDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final own = widget.need.installer;
      if (own != null) {
        await own();
      } else {
        await TkRunner.install(widget.py, widget.need.packages);
      }
      if (mounted) Navigator.pop(context, true);
    } on UserError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final need = widget.need;
    final mono = const TextStyle(fontFamily: 'monospace', fontSize: 12);
    return AlertDialog(
      key: const ValueKey('tk-install'),
      title: Text(need.title),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(need.why),
              const SizedBox(height: 10),
              Text(tr('Se puede instalar ahora, o a mano con esta orden:')),
              const SizedBox(height: 6),
              SelectableText(need.command, style: mono),
              if (_busy) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('Instalando {0}…', [need.packages.join(', ')]),
                      ),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                SelectableText(
                  _error!,
                  key: const ValueKey('tk-install-error'),
                  style: mono.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () => Clipboard.setData(ClipboardData(text: need.command)),
          child: Text(tr('Copiar la orden')),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(tr('Cancelar')),
        ),
        if (need.optional)
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, true),
            child: Text(tr('Ejecutar sin él')),
          ),
        FilledButton(
          key: const ValueKey('tk-install-go'),
          onPressed: _busy ? null : _install,
          child: Text(tr('Instalar')),
        ),
      ],
    );
  }
}

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
