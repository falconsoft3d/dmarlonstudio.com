import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:re_editor/re_editor.dart';

import '../i18n/tr.dart';

/// Buscar (y reemplazar) en un editor de código: ⌘F / Ctrl+F lo abre, Intro
/// y las flechas van de un resultado a otro, Esc lo cierra. En un editor de
/// solo lectura no hay reemplazar.
class CodeFindPanel extends StatelessWidget implements PreferredSizeWidget {
  const CodeFindPanel({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  final CodeFindController controller;
  final bool readOnly;

  @override
  Size get preferredSize => Size.fromHeight(
    controller.value == null
        ? 0
        : (controller.value!.replaceMode && !readOnly ? 76 : 40),
  );

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    if (v == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
    final dim = dark ? const Color(0xFF8C8C8C) : const Color(0xFF8A8A8A);
    final side = dark ? const Color(0xFF252526) : const Color(0xFFF3F3F3);
    const accent = Color(0xFF007ACC);
    final r = v.result;
    Widget field(
      TextEditingController c,
      FocusNode f,
      String hint, {
      Key? key,
    }) => SizedBox(
      width: 240,
      height: 28,
      child: TextField(
        key: key,
        controller: c,
        focusNode: f,
        style: TextStyle(color: text, fontSize: 13),
        cursorColor: text,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: dim),
          filled: true,
          fillColor: dark ? const Color(0xFF3C3C3C) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: accent),
          ),
        ),
      ),
    );
    Widget btn(
      IconData i,
      String tip,
      VoidCallback onTap, {
      bool on = false,
      Key? key,
    }) => IconButton(
      key: key,
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      iconSize: 15,
      color: on ? Colors.white : text,
      style: on ? IconButton.styleFrom(backgroundColor: accent) : null,
      onPressed: onTap,
      icon: Icon(i),
    );
    // Esc cierra el buscador (también desde sus campos).
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): controller.close,
      },
      child: _panel(context, v, side, text, dim, accent, r, field, btn),
    );
  }

  Widget _panel(
    BuildContext context,
    CodeFindValue v,
    Color side,
    Color text,
    Color dim,
    Color accent,
    CodeFindResult? r,
    Widget Function(TextEditingController, FocusNode, String, {Key? key}) field,
    Widget Function(IconData, String, VoidCallback, {bool on, Key? key}) btn,
  ) {
    return Container(
      color: side,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      alignment: Alignment.topRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(
                controller.findInputController,
                controller.findInputFocusNode,
                tr('Buscar'),
                key: const ValueKey('code-find'),
              ),
              btn(
                LucideIcons.caseSensitive,
                tr('Distinguir mayúsculas'),
                controller.toggleCaseSensitive,
                on: v.option.caseSensitive,
              ),
              btn(
                LucideIcons.regex,
                tr('Expresión regular'),
                controller.toggleRegex,
                on: v.option.regex,
              ),
              SizedBox(
                width: 80,
                child: Text(
                  r == null || r.matches.isEmpty
                      ? tr('Sin resultados')
                      : '${r.index + 1} / ${r.matches.length}',
                  key: const ValueKey('code-find-count'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: text, fontSize: 12),
                ),
              ),
              btn(
                LucideIcons.arrowUp,
                tr('Anterior'),
                controller.previousMatch,
              ),
              btn(
                LucideIcons.arrowDown,
                tr('Siguiente'),
                controller.nextMatch,
                key: const ValueKey('code-find-next'),
              ),
              if (!readOnly)
                btn(
                  LucideIcons.replace,
                  tr('Reemplazar'),
                  controller.toggleMode,
                  on: v.replaceMode,
                ),
              btn(LucideIcons.x, tr('Cerrar'), controller.close),
            ],
          ),
          if (v.replaceMode && !readOnly)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field(
                    controller.replaceInputController,
                    controller.replaceInputFocusNode,
                    tr('Reemplazar'),
                  ),
                  btn(
                    LucideIcons.replace,
                    tr('Reemplazar'),
                    controller.replaceMatch,
                  ),
                  btn(
                    LucideIcons.replaceAll,
                    tr('Reemplazar todo'),
                    controller.replaceAllMatches,
                  ),
                  const SizedBox(width: 206),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
