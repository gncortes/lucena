import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T73 (D14, 9.1): nenhuma cor fixa em `lib/ui` fora de `core/theme`. Cor de
/// marca vem de `AppColors`/`ColorScheme`; `Colors.transparent` é permitido.
void main() {
  // Exceções por regra: as duas paletas são dados de paleta, não cores de
  // tela. Os dois arquivos de lesson_script ficam até a frente do roteiro
  // migrar para AppColors.
  const allowed = <String>{
    'lib/ui/core/board/board_settings_ui.dart',
    'lib/ui/core/review/move_quality_ui.dart',
    'lib/ui/lesson_script/widgets/script_board.dart',
    'lib/ui/lesson_script/widgets/script_demo_controls.dart',
  };
  final raw = RegExp(r'(^|[^A-Za-z])Colors\.(?!transparent)|Color\(0x');

  test('lib/ui não tem cor fixa fora do tema e das exceções', () {
    final found = <String>[];
    for (final file in Directory('lib/ui').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/ui/core/theme/') || allowed.contains(path)) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (raw.hasMatch(lines[i])) found.add('$path:${i + 1}');
      }
    }
    expect(found, isEmpty, reason: 'Use AppColors ou o ColorScheme.');
  });
}
