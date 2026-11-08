import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A7: o Percival (snob) é o pedante do Aberto do Bairro e fala no registro
/// culto, como o Viktor: sem pra/pro/tá/tô/tava/num/numa.
void main() {
  test('falas do Percival em pt sem contração informal', () {
    final raw =
        jsonDecode(File('assets/lines/pt/snob.json').readAsStringSync())
            as Map<String, dynamic>;
    final informal = RegExp(
      r'(^|[^\p{L}])(pra|pras|pro|pros|tá|tô|tava|num|numa|nuns|numas)'
      r'(?![\p{L}])',
      caseSensitive: false,
      unicode: true,
    );
    final achados = <String>[
      for (final l in raw['lines'] as List)
        if (informal.hasMatch((l as Map<String, dynamic>)['text'] as String))
          '${l['id']}: ${l['text']}',
    ];
    expect(achados, isEmpty);
  });
}
