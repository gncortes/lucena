import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tamanho de ícone só pela escala de `AppIconSize` (D34): 16, 20, 24, 32 e
/// 48. Até o lote 2b da E1.08 trocar os literais, o teste só lista os casos
/// ([warnOnly]); depois, falha.
const warnOnly = false;

void main() {
  test('Icon(size:) só pela escala de AppIconSize', () {
    final literal = RegExp(r'\bsize:\s*\d');
    final problems = <String>[];
    final files = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (final (index, line) in lines.indexed) {
        if (!line.contains('Icon(') || !literal.hasMatch(line)) continue;
        problems.add('${file.path}:${index + 1}: ${line.trim()}');
      }
    }
    if (warnOnly) {
      // ignore: avoid_print
      print('Icon(size:) fora da escala: ${problems.length}');
      return;
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
