import 'package:flutter_test/flutter_test.dart';

import 'lint_baseline.dart';

/// Lote 10, "reaproveitar primeiro": componente de papel genérico nasce em
/// `lib/ui/core`. Fora dele, cartão à mão (`cardSurface` + `cardOutline`) e
/// classe `*Chip|*Pill|*Badge|*Footer|*Header|*Dialog|*Empty` só com a linha
/// `// reuso: <Componente> não serve porque <motivo>` logo acima da classe.
/// Ache o componente pelo papel com `python3 tools/achar_componente.py <papel>`.
void main() {
  bool outsideCore(String path) => !path.startsWith('lib/ui/core/');

  test('cartão feito à mão fora do core só no baseline', () {
    final found = <String, int>{};
    for (final (path, lines) in dartFiles('lib/ui')) {
      if (!outsideCore(path)) continue;
      final code = lines.where((l) => !isComment(l)).join('\n');
      if (code.contains('cardSurface') && code.contains('cardOutline')) {
        found[path] = 1;
      }
    }
    checkBaseline(
      'card_by_hand',
      found,
      'Use LucenaCard (ou acrescente uma variante a ele).',
    );
  });

  test('componente genérico fora do core só com "// reuso:"', () {
    final generic = RegExp(
      r'^class (\w*(?:Chip|Pill|Badge|Footer|Header|Dialog|Empty))\b',
    );
    final found = <String, int>{};
    for (final (path, lines) in dartFiles('lib/ui')) {
      if (!outsideCore(path)) continue;
      var n = 0;
      for (var i = 0; i < lines.length; i++) {
        if (!generic.hasMatch(lines[i])) continue;
        final above = lines.sublist(i < 3 ? 0 : i - 3, i);
        if (!above.any((l) => l.contains('// reuso:'))) n++;
      }
      if (n > 0) found[path] = n;
    }
    checkBaseline(
      'generic_outside_core',
      found,
      'Crie em lib/ui/core ou escreva "// reuso: <Componente> não serve '
          'porque <motivo>" acima da classe.',
    );
  });
}
