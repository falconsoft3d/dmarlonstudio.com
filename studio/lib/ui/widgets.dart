import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'theme.dart';

// ------------------------------------------------------------------ formato
class Fmt {
  Fmt._();

  static String date(Object? v) {
    if (v == null || v.toString().isEmpty) return '';
    final d = DateTime.tryParse(v.toString());
    return d == null ? v.toString() : DateFormat('dd/MM/yyyy').format(d);
  }

  static String dateTime(Object? v) {
    if (v == null) return '';
    final d = DateTime.tryParse(v.toString());
    return d == null ? v.toString() : DateFormat('dd/MM/yyyy HH:mm').format(d);
  }
}

// ------------------------------------------------------------------ errores
/// Muestra un error. Los técnicos (no [UserError]) se pueden copiar.
Future<void> showErrorDialog(
  BuildContext context,
  String message, {
  bool technical = false,
}) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(technical ? tr('Error inesperado') : tr('No se pudo hacer')),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(child: SelectableText(message)),
    ),
    actions: [
      if (technical)
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: message)),
          child: Text(tr('Copiar')),
        ),
      FilledButton(
        onPressed: () => Navigator.pop(c),
        child: Text(tr('Aceptar')),
      ),
    ],
  ),
);

/// Ejecuta [action] y, si falla, lo explica en un diálogo (devuelve null).
Future<T?> runAction<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? success,
}) async {
  try {
    final r = await action();
    if (success != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    }
    return r;
  } on UserError catch (e) {
    if (context.mounted) await showErrorDialog(context, e.message);
  } catch (e) {
    if (context.mounted) {
      await showErrorDialog(context, e.toString(), technical: true);
    }
  }
  return null;
}

// ------------------------------------------------------------------ diálogos
/// Pide un texto en un diálogo (null si se cancela).
Future<String?> promptText(
  BuildContext context,
  String title,
  String initial, {
  String? ok,
}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 380,
        child: TextField(
          controller: c,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, c.text),
          child: Text(ok ?? tr('Aceptar')),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String message, {
  String? ok,
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok ?? tr('Aceptar')),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ------------------------------------------------------- panel de control
class Crumb {
  const Crumb(this.label, [this.onTap]);
  final String label;
  final VoidCallback? onTap;
}

/// Barra superior de una pantalla: migas de pan, botones y búsqueda.
class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
    required this.crumbs,
    this.actions = const [],
    this.search,
    this.trailing = const [],
  });
  final List<Crumb> crumbs;
  final List<Widget> actions;
  final Widget? search;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.surface,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.dividerColor)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...actions.expand((w) => [w, const SizedBox(width: 6)]),
                if (actions.isNotEmpty) const SizedBox(width: 6),
                for (var i = 0; i < crumbs.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('/', style: TextStyle(color: t.hintColor)),
                    ),
                  Flexible(
                    child: InkWell(
                      onTap: crumbs[i].onTap,
                      child: Text(
                        crumbs[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: i == crumbs.length - 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: crumbs[i].onTap != null
                              ? t.colorScheme.secondary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (search != null) SizedBox(width: 340, child: search),
                ...trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.onChanged, this.hint});
  final ValueChanged<String> onChanged;
  final String? hint;
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint ?? tr('Buscar...'),
      prefixIcon: const Icon(Icons.search, size: 18),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    ),
  );
}

// ----------------------------------------------------------------- chats
/// Atajos de la caja de un chat: Intro envía y Mayús+Intro salta de línea
/// (⌘Intro y Ctrl+Intro también envían). Mientras se compone un carácter
/// (acentos, chino…), Intro lo confirma y no envía.
Map<ShortcutActivator, VoidCallback> chatSendKeys(
  TextEditingController c,
  VoidCallback send,
) {
  void go() {
    if (c.value.composing.isValid) return;
    send();
  }

  return {
    const SingleActivator(LogicalKeyboardKey.enter): go,
    const SingleActivator(LogicalKeyboardKey.numpadEnter): go,
    const SingleActivator(LogicalKeyboardKey.enter, meta: true): go,
    const SingleActivator(LogicalKeyboardKey.enter, control: true): go,
  };
}
