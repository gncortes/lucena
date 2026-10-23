import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toda animação de `lib/ui/` usa os tokens de `AppMotion` (T51, G2) e todo
/// raio de borda os de `AppShape` (G3): nada de duração, curva, "remover
/// animações" ou raio escritos à mão. O que sobra aqui é tempo que não é
/// animação, com o motivo ao lado.
void main() {
  final forbidden = [
    'Duration(milliseconds:',
    'Curves.',
    'disableAnimationsOf',
    // Raio com número: só pelos tokens (raio proporcional ao tamanho, como
    // o das casas do tabuleiro, pode).
    RegExp(r'Radius\.circular\(\d'),
  ];

  // Arquivo → trechos permitidos, cada um com o motivo.
  const exceptions = <String, Map<String, String>>{
    'lib/ui/core/theme/app_motion.dart': {'': 'os próprios tokens'},
    'lib/ui/level/widgets/level_chess_screen.dart': {
      '_pause = Duration(': 'pausa da digitação antes de buscar o usuário',
    },
  };

  test('durações, curvas e "remover animações" só pelos tokens', () {
    final problems = <String>[];
    final files = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      // Os view models só guardam tempo de lógica (resposta da máquina,
      // tique do relógio), não animação.
      if (path.contains('/view_models/')) continue;
      final allowed = exceptions[path] ?? const {};
      for (final (index, line) in file.readAsLinesSync().indexed) {
        if (!forbidden.any((pattern) => line.contains(pattern))) continue;
        if (allowed.keys.any(line.contains)) continue;
        problems.add('$path:${index + 1}: ${line.trim()}');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
