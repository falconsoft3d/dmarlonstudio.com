import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../i18n/tr.dart';

/// Archivo adjunto a un mensaje de un chat de IA: una imagen (captura,
/// boceto) o un archivo de texto o código.
class ChatAttachment {
  ChatAttachment._(this.path, this.bytes, this.mime);

  final String path;
  final Uint8List bytes;

  /// Tipo de una imagen (`image/png`…); null para texto.
  final String? mime;

  String get name => p.basename(path);
  bool get isImage => mime != null;

  /// Tamaño legible.
  String get size => bytes.length < 1024
      ? '${bytes.length} B'
      : bytes.length < 1024 * 1024
      ? '${(bytes.length / 1024).toStringAsFixed(0)} KB'
      : '${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB';

  /// Límite de una imagen (la API de Anthropic admite hasta 5 MB).
  static const maxImage = 5 * 1024 * 1024;

  /// Límite de un archivo de texto (va dentro del mensaje).
  static const maxText = 300 * 1024;

  static const _images = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
  };

  /// Lee [path] y comprueba que se pueda adjuntar.
  static Future<ChatAttachment> load(String path) async {
    final f = File(path);
    final bytes = await f.readAsBytes();
    final mime = _images[p.extension(path).toLowerCase()];
    if (mime != null) {
      if (bytes.length > maxImage) {
        throw UserError(
          tr('«{0}» pesa más de 5 MB: redúzcala para adjuntarla.', [
            p.basename(path),
          ]),
        );
      }
      return ChatAttachment._(path, bytes, mime);
    }
    if (bytes.length > maxText) {
      throw UserError(
        tr(
          '«{0}» es demasiado grande para adjuntarlo (máximo 300 KB de texto).',
          [p.basename(path)],
        ),
      );
    }
    try {
      utf8.decode(bytes);
    } on FormatException {
      throw UserError(
        tr('«{0}» no es una imagen ni un archivo de texto.', [
          p.basename(path),
        ]),
      );
    }
    return ChatAttachment._(path, bytes, null);
  }

  /// Elige archivos con el diálogo del sistema.
  static Future<List<ChatAttachment>> pick() async {
    final files = await openFiles(confirmButtonText: tr('Adjuntar'));
    return [for (final f in files) await load(f.path)];
  }

  String get text => utf8.decode(bytes, allowMalformed: true);

  String get dataUrl => 'data:$mime;base64,${base64Encode(bytes)}';

  /// Texto de un adjunto de texto, listo para el mensaje.
  String get inline {
    final ext = p.extension(path).replaceFirst('.', '');
    return '\n\n${tr('Archivo adjunto')}: $name\n```$ext\n$text\n```';
  }

  /// Contenido de un mensaje de formato OpenAI con [text] y los adjuntos
  /// (las imágenes, como `image_url`; el texto, dentro del mensaje).
  static Object openAiContent(String text, List<ChatAttachment> files) {
    if (files.isEmpty) return text;
    final body =
        text + files.where((f) => !f.isImage).map((f) => f.inline).join();
    final images = files.where((f) => f.isImage).toList();
    if (images.isEmpty) return body;
    return [
      {'type': 'text', 'text': body},
      for (final f in images)
        {
          'type': 'image_url',
          'image_url': {'url': f.dataUrl},
        },
    ];
  }

  /// Bloques de la API de Anthropic con [text] y los adjuntos.
  static List<Map<String, Object?>> anthropicBlocks(
    String text,
    List<ChatAttachment> files,
  ) => [
    for (final f in files)
      if (f.isImage)
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': f.mime,
            'data': base64Encode(f.bytes),
          },
        },
    {
      'type': 'text',
      'text': text + files.where((f) => !f.isImage).map((f) => f.inline).join(),
    },
  ];
}
