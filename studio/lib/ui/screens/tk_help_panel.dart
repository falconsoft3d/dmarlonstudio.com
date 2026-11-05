import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../code/tk_help.dart';
import '../../i18n/i18n.dart';

/// Panel derecho de ayuda: los comandos de Python, JavaScript y C++ y lo del
/// estudio, con qué hacen, su forma y un ejemplo que se puede insertar.
class TkHelpPanel extends StatefulWidget {
  const TkHelpPanel({
    super.key,
    required this.lang,
    required this.query,
    required this.onClose,
    this.onInsert,
  });

  /// py, js o cpp: el del proyecto (se puede cambiar en el panel).
  final String lang;

  /// Lo que se busca (la palabra del clic derecho o de F1).
  final String query;
  final VoidCallback onClose;
  final ValueChanged<String>? onInsert;

  @override
  State<TkHelpPanel> createState() => _TkHelpPanelState();
}

class _TkHelpPanelState extends State<TkHelpPanel> {
  late String _lang = widget.lang;
  late final _search = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(TkHelpPanel old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _search.text = widget.query;
    if (old.lang != widget.lang) _lang = widget.lang;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final language = I18n.lang.value;
    final entries = tkHelpFind(_lang, _search.text);
    return Container(
      key: const ValueKey('tk-help'),
      width: 340,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: t.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                const Icon(LucideIcons.bookOpen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('Ayuda'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: tr('Cerrar'),
                  iconSize: 16,
                  icon: const Icon(LucideIcons.x),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              key: const ValueKey('tk-help-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                hintText: tr('Buscar un comando'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              children: [
                for (final (code, label) in [
                  ('py', 'Python'),
                  ('js', 'JavaScript'),
                  ('cpp', 'C++'),
                  ('pas', 'Pascal'),
                  ('dart', 'Dart'),
                ])
                  ChoiceChip(
                    key: ValueKey('tk-help-lang-$code'),
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: _lang == code,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _lang = code),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        tr('No hay ayuda para «{0}» en este lenguaje.', [
                          _search.text,
                        ]),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.hintColor, fontSize: 12.5),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [for (final e in entries) _entry(t, e, language)],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _entry(ThemeData t, TkHelpEntry e, String language) {
    final mono = TextStyle(
      fontFamily: 'Menlo',
      fontFamilyFallback: const ['Consolas', 'monospace'],
      fontSize: 12,
      color: t.colorScheme.onSurface,
    );
    return Container(
      key: ValueKey('tk-help-${e.lang}-${e.word}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: t.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.word,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (e.studio)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: t.colorScheme.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tr('Estudio'),
                    style: const TextStyle(fontSize: 10.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            e.signature,
            style: mono.copyWith(color: t.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Text(e.text(language), style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: t.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(e.example, style: mono),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: e.example)),
                  icon: const Icon(LucideIcons.copy, size: 14),
                  label: Text(tr('Copiar')),
                ),
                if (widget.onInsert != null)
                  TextButton.icon(
                    key: ValueKey('tk-help-insert-${e.word}'),
                    onPressed: () => widget.onInsert!(e.example),
                    icon: const Icon(LucideIcons.textCursorInput, size: 14),
                    label: Text(tr('Insertar')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
