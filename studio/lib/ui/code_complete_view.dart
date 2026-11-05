import 'dart:math';

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// La lista del autocompletado: ↑/↓ para elegir, Intro o clic para poner.
class CodeCompleteView extends StatelessWidget implements PreferredSizeWidget {
  const CodeCompleteView({
    super.key,
    required this.notifier,
    required this.onSelected,
  });

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  static const _row = 24.0;

  @override
  Size get preferredSize =>
      Size(300, min(notifier.value.prompts.length, 8) * _row + 8);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF252526) : Colors.white;
    final fg = dark ? const Color(0xFFD4D4D4) : const Color(0xFF1F1F1F);
    final dim = dark ? const Color(0xFF8C8C8C) : const Color(0xFF7A7A7A);
    const chosen = Color(0xFF094771);
    return Container(
      key: const ValueKey('code-complete'),
      width: preferredSize.width,
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: dark ? const Color(0xFF454545) : const Color(0xFFC8C8C8),
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: ValueListenableBuilder<CodeAutocompleteEditingValue>(
        valueListenable: notifier,
        builder: (context, value, _) => ListView.builder(
          itemCount: value.prompts.length,
          itemExtent: _row,
          controller: ScrollController(
            initialScrollOffset: max(0, value.index - 5) * _row,
          ),
          itemBuilder: (context, i) {
            final p = value.prompts[i];
            final on = i == value.index;
            final type = switch (p) {
              CodeFieldPrompt(:final type) => type,
              CodeFunctionPrompt(:final type) => type,
              _ => '',
            };
            return InkWell(
              onTap: () => onSelected(value.copyWith(index: i).autocomplete),
              child: Container(
                color: on ? chosen : null,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.word,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: on ? Colors.white : fg,
                          fontFamily: 'Menlo',
                          fontFamilyFallback: const ['Consolas', 'monospace'],
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Text(
                      type,
                      style: TextStyle(
                        color: on ? Colors.white70 : dim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
