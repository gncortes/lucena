import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A3: as cores do tabuleiro saem só da preferência do usuário
/// (`BoardSettings.colors` → `board_settings_ui.dart`). Nenhuma tela fixa um
/// esquema do chessground: assim a Escola, a Jornada e o Treinar finais
/// mostram o mesmo tabuleiro.
void main() {
  test('nenhuma tela fixa a cor do tabuleiro', () {
    const fonte = 'lib/ui/core/board/board_settings_ui.dart';
    final fixo = RegExp(r'ChessboardColorScheme\.\w+|ChessboardColorScheme\(');
    final achados = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      if (path.endsWith(fonte)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (fixo.hasMatch(lines[i])) achados.add('$path:${i + 1}');
      }
    }
    expect(achados, isEmpty);
  });
}
