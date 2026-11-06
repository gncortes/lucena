import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// H-ESC-10: o app é de celular, o texto da Escola diz "toque", nunca
/// "clique". Vale para as falas das lições da Escola e para o roteiro
/// do iniciante; o tour (Abertura) e o roteiro genérico (Pilares e
/// finais) não entram.
void main() {
  if (!Directory('assets/lessons/pt/iniciante').existsSync()) {
    test('private content required for Escola texts', () {}, skip: true);
    return;
  }
  final click = RegExp(r'\b(cliqu\w*|clic\w*)\b', caseSensitive: false);

  Iterable<MapEntry<String, String>> texts(String path) {
    final json = jsonDecode(File(path).readAsStringSync());
    return (json as Map<String, dynamic>).entries.map(
      (e) => MapEntry(e.key, '${e.value}'.replaceAll(RegExp(r'\{[^}]*\}'), '')),
    );
  }

  test('falas das lições da Escola não dizem clique', () {
    final files = Directory('assets/lessons/pt/iniciante')
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .toList();
    expect(files, isNotEmpty);
    final found = <String>[
      for (final f in files)
        for (final e in texts(f))
          if (click.hasMatch(e.value)) '$f ${e.key}',
    ];
    expect(found, isEmpty);
  });

  test('roteiro do iniciante e textos das lições da Escola dizem toque', () {
    final found = <String>[
      for (final e in texts('assets/lessons/pt/roteiro_iniciante.json'))
        if (click.hasMatch(e.value)) 'roteiro_iniciante ${e.key}',
      for (final e in texts('assets/lessons/pt/lessons.json'))
        if (!e.key.startsWith('tour.') && click.hasMatch(e.value))
          'lessons ${e.key}',
    ];
    expect(found, isEmpty);
  });
}
