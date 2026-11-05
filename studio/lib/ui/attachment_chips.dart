import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ai/attachments.dart';
import '../core/errors.dart';
import '../i18n/tr.dart';
import 'widgets.dart';

/// Adjuntos preparados para el próximo mensaje de un chat, con su botón
/// para quitar cada uno.
class AttachmentChips extends StatelessWidget {
  const AttachmentChips({
    super.key,
    required this.files,
    required this.onRemove,
  });
  final List<ChatAttachment> files;
  final void Function(ChatAttachment) onRemove;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final f in files)
            InputChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                f.isImage ? LucideIcons.image : LucideIcons.fileText,
                size: 14,
              ),
              label: Text(
                '${f.name} · ${f.size}',
                style: const TextStyle(fontSize: 11.5),
              ),
              onDeleted: () => onRemove(f),
              deleteButtonTooltipMessage: tr('Quitar'),
            ),
        ],
      ),
    );
  }
}

/// Elige adjuntos y los añade a [into]; explica si alguno no vale.
Future<void> pickAttachments(
  BuildContext context,
  List<ChatAttachment> into,
) async {
  try {
    into.addAll(await ChatAttachment.pick());
  } on UserError catch (e) {
    if (context.mounted) await showErrorDialog(context, e.message);
  }
}
