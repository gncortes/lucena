import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // LICOES-V2 §2: o rótulo "Continuação:" não existe mais no texto; os
  // lances entram no fim do parágrafo anterior (tools/explanations/
  // juntar_continuacao.py).
  final label = RegExp(r'^(Continuação|Continuation|المتابعة):\s*');

  void walk(Object? node, String path, List<String> found) {
    if (node is String) {
      if (label.hasMatch(node)) found.add('$path: $node');
    } else if (node is Map) {
      node.forEach((k, v) => walk(v, '$path/$k', found));
    } else if (node is List) {
      for (final (i, v) in node.indexed) {
        walk(v, '$path[$i]', found);
      }
    }
  }

  test('nenhum texto de assets/lessons/feedback começa com "Continuação:"', () {
    final files = Directory('assets/lessons/feedback')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));
    expect(files, isNotEmpty);
    for (final file in files) {
      final found = <String>[];
      walk(_decode(file.readAsStringSync()), file.path, found);
      expect(found, isEmpty, reason: found.take(3).join('\n'));
    }
  });
}

Object? _decode(String source) => jsonDecode(source);
