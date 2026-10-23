import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena_ui/lucena_ui.dart';

/// D6 (T73): botão de largura total = 52, compacto ou em cartão = 48, só pelas
/// constantes do tema. Nenhum `minimumSize` em `lib/ui` escreve altura de
/// botão (46 ou mais) como número.
void main() {
  test('as alturas do tema são 52 e 48', () {
    expect(kButtonHeight, 52);
    expect(kButtonHeightCompact, 48);
  });

  test('nenhum minimumSize com altura de botão em número solto', () {
    final heightLiteral = RegExp(
      r'minimumSize:.*?(?:fromHeight\(\s*(\d+)|Size\(\s*(?:0|\d{3})\s*,\s*(\d+))',
    );
    final offenders = <String>[];
    for (final file in Directory('lib/ui').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('/core/theme/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final m = heightLiteral.firstMatch(lines[i]);
        if (m == null) continue;
        final n = int.parse(m.group(1) ?? m.group(2)!);
        // 44 e abaixo é alvo de toque mínimo (ícone), não botão de texto.
        if (n >= 46) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
