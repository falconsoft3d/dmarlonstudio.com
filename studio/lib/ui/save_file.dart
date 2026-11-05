import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// Pide dónde guardar y escribe el archivo. Devuelve la ruta o null.
Future<String?> saveBytes(
  Uint8List bytes, {
  required String suggestedName,
  required String typeLabel,
  required String extension,
}) async {
  final loc = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: [
      XTypeGroup(label: typeLabel, extensions: [extension]),
    ],
  );
  if (loc == null) return null;
  final path =
      extension.isEmpty ||
          loc.path.toLowerCase().endsWith('.${extension.toLowerCase()}')
      ? loc.path
      : '${loc.path}.$extension';
  await File(path).writeAsBytes(bytes);
  return path;
}
