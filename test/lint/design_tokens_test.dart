import 'package:flutter_test/flutter_test.dart';

import 'lint_baseline.dart';

/// Lote 10: tamanho de fonte, peso e espaçamento saem dos tokens do tema
/// (`AppText`, `AppSpacing`), não de número solto na tela. O que já existia
/// fica no baseline; código novo não entra.
void main() {
  const scale = {0, 4, 8, 12, 16, 24, 32};
  final fontSize = RegExp(r'fontSize:\s*\d');
  final fontWeight = RegExp(r'FontWeight\.w\d00');
  final edgeInsets = RegExp(
    r'EdgeInsets(?:Directional)?\.(?:all|symmetric|only|fromLTRB|fromSTEB)\(([^)]*)\)',
  );
  final gap = RegExp(r'SizedBox\(\s*(?:width|height):\s*(\d+(?:\.\d+)?)\s*\)');
  final number = RegExp(r'(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])');

  bool offScale(String value) {
    final n = double.parse(value);
    return n != n.roundToDouble() || !scale.contains(n.toInt());
  }

  Map<String, int> count(bool Function(String line) hit) {
    final found = <String, int>{};
    for (final (path, lines) in dartFiles('lib/ui')) {
      if (path.startsWith('lib/ui/core/theme/')) continue;
      final n = lines.where((l) => !isComment(l) && hit(l)).length;
      if (n > 0) found[path] = n;
    }
    return found;
  }

  test('fontSize numérico só no baseline', () {
    checkBaseline(
      'font_size',
      count(fontSize.hasMatch),
      'Use um estilo de AppText (context.text...), não fontSize solto.',
    );
  });

  test('FontWeight.wNNN só no AppText e no baseline', () {
    checkBaseline(
      'font_weight',
      count(fontWeight.hasMatch),
      'O peso vem do estilo de AppText.',
    );
  });

  test('EdgeInsets e SizedBox de espaço na escala 0/4/8/12/16/24/32', () {
    checkBaseline(
      'spacing',
      count((line) {
        for (final m in edgeInsets.allMatches(line)) {
          if (number
              .allMatches(m.group(1)!)
              .any((n) => offScale(n.group(1)!))) {
            return true;
          }
        }
        return gap.allMatches(line).any((m) {
          final n = double.parse(m.group(1)!);
          return n <= 32 && offScale(m.group(1)!);
        });
      }),
      'Use AppSpacing (escala 0/4/8/12/16/24/32).',
    );
  });
}
