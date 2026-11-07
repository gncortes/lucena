import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T85-D0 (memória app-bar-sem-subtitulo, decidido em 04/11/2026): a app bar
/// leva só o título, mais voltar e ações. Nenhum título de `AppBar` ou
/// `LucenaAppBar` em `lib/ui` empilha um segundo texto (`Column`).
void main() {
  test('nenhuma app bar com subtítulo', () {
    final offenders = <String>[];
    final bar = RegExp(r'\b(?:Lucena)?AppBar\(');
    for (final file in Directory('lib/ui').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final m in bar.allMatches(source)) {
        final title = _titleExpression(source, m.end);
        if (title == null) continue;
        if (title.contains('Column(')) {
          final line = '\n'.allMatches(source.substring(0, m.start)).length;
          offenders.add('${file.path}:${line + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

/// O texto do argumento `title:` da chamada que abre em [from], até o
/// próximo argumento no mesmo nível de parênteses.
String? _titleExpression(String source, int from) {
  var depth = 0;
  for (var i = from; i < source.length; i++) {
    final c = source[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return null;
      depth--;
    }
    if (depth == 0 && source.startsWith('title:', i)) {
      final start = i + 'title:'.length;
      var d = 0;
      for (var j = start; j < source.length; j++) {
        final k = source[j];
        if (k == '(' || k == '[' || k == '{') d++;
        if (k == ')' || k == ']' || k == '}') {
          if (d == 0) return source.substring(start, j);
          d--;
        }
        if (d == 0 && k == ',') return source.substring(start, j);
      }
    }
  }
  return null;
}
