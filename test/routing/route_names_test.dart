import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T85-D0: toda tela tem rota com nome. Todo `GoRoute` (direto, pelo
/// `_route`/`appRoute` ou pelo `_levelPart`) em `lib/routing` passa `name:`,
/// e os nomes de `RouteNames` e os caminhos novos das frentes são únicos.
void main() {
  final files = Directory('lib/routing')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('todo GoRoute tem nome', () {
    final missing = <String>[];
    final call = RegExp(r'(?<![\w.])(GoRoute|_route|appRoute)\(');
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final m in call.allMatches(source)) {
        final before = source.substring(0, m.start);
        // A definição da função (`GoRoute _route({`) não é chamada.
        if (source.startsWith('{', m.end)) continue;
        final args = _arguments(source, m.end);
        if (!RegExp(r'(^|[\s,(])name:').hasMatch(args)) {
          final line = '\n'.allMatches(before).length + 1;
          missing.add('${file.path}:$line');
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('nomes e caminhos novos são únicos', () {
    final names = RegExp(r"static const (\w+) = '([^']+)';");
    final source = File('lib/routing/route_names.dart').readAsStringSync();
    final values = [for (final m in names.allMatches(source)) m.group(2)!];
    expect(values.toSet().length, values.length);
    for (final m in names.allMatches(source)) {
      expect(m.group(2), m.group(1), reason: 'nome = identificador');
    }
    final paths = [
      for (final f in Directory('lib/routing/frentes').listSync())
        if (f is File && RegExp(r'd\d_routes\.dart$').hasMatch(f.path))
          for (final m in names.allMatches(f.readAsStringSync())) m.group(2)!,
    ];
    expect(paths.toSet().length, paths.length, reason: paths.join('\n'));
  });
}

/// Os argumentos da chamada que abre em [from], até o `)` que a fecha.
String _arguments(String source, int from) {
  var depth = 0;
  for (var i = from; i < source.length; i++) {
    final c = source[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return _topLevel(source.substring(from, i));
      depth--;
    }
  }
  return '';
}

/// Só o nível de cima dos argumentos: o `name:` de uma rota filha não conta
/// para a mãe.
String _topLevel(String args) {
  final out = StringBuffer();
  var depth = 0;
  for (final c in args.split('')) {
    if (c == '(' || c == '[' || c == '{') depth++;
    if (depth == 0) out.write(c);
    if (c == ')' || c == ']' || c == '}') depth--;
  }
  return out.toString();
}
