import 'dart:io';

import 'package:dmarlon_studio/ai/attachments.dart';
import 'package:dmarlon_studio/core/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('adj_'));
  tearDown(() => dir.delete(recursive: true));

  test('imágenes y texto en los formatos de OpenAI y Anthropic', () async {
    final png = File(p.join(dir.path, 'boceto.png'))
      ..writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);
    final py = File(p.join(dir.path, 'main.py'))
      ..writeAsStringSync('print("hola")\n');
    final img = await ChatAttachment.load(png.path);
    final code = await ChatAttachment.load(py.path);
    expect(img.isImage, isTrue);
    expect(code.isImage, isFalse);

    final openai =
        ChatAttachment.openAiContent('Haz esto', [img, code]) as List;
    expect((openai.first as Map)['text'], contains('print("hola")'));
    expect(
      ((openai.last as Map)['image_url'] as Map)['url'],
      startsWith('data:image/png;base64,'),
    );
    expect(ChatAttachment.openAiContent('Solo texto', [code]), isA<String>());

    final blocks = ChatAttachment.anthropicBlocks('Haz esto', [img, code]);
    expect(blocks.first['type'], 'image');
    expect((blocks.first['source'] as Map)['media_type'], 'image/png');
    expect(blocks.last['text'], contains('main.py'));
  });

  test('rechaza binarios que no son imágenes', () async {
    final bin = File(p.join(dir.path, 'datos.bin'))
      ..writeAsBytesSync([0xff, 0xfe, 0x00, 0xc3, 0x28]);
    expect(() => ChatAttachment.load(bin.path), throwsA(isA<UserError>()));
  });
}
