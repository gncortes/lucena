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
    'lib/ui/free_board/widgets/free_board_screen.dart': {
      'Timer.periodic(const Duration(milliseconds: 100)':
          'relógio da partida: tempo de jogo',
      'duration: const Duration(milliseconds: 1400)':
          'coreografia do cartão do resultado (sai na frente B)',
    },
    'lib/ui/free_board/widgets/character_bar.dart': {
      'perLetter = Duration(milliseconds: 28)': 'ritmo de leitura da fala',
    },
    'lib/ui/core/widgets/teacher_speech.dart': {
      'Duration(milliseconds: (_length': 'ritmo de leitura da fala',
    },
    'lib/ui/endgames/widgets/exercise_screen.dart': {
      'duration: const Duration(milliseconds: 1100)':
          'tempo para ler o lance errado em vermelho',
    },
    'lib/ui/home/widgets/home_screen.dart': {
      'duration: const Duration(milliseconds: 1400)':
          'coreografia da entrada da tela inicial',
    },
    'lib/ui/core/widgets/celebration.dart': {
      'duration = Duration(milliseconds: 1600)': 'coreografia do confete',
    },
    'lib/ui/core/widgets/versus_intro.dart': {
      'duration = Duration(milliseconds: 4600)':
          'coreografia do versus com a contagem',
      'shortDuration = Duration(milliseconds: 2000)':
          'coreografia do versus sem contagem',
    },
    'lib/ui/achievements/widgets/achievement_toast.dart': {
      'duration = Duration(milliseconds: 3800)':
          'tempo do aviso de conquista na tela',
    },
    'lib/ui/blind/widgets/blind_game_screen.dart': {
      'minHold = Duration(milliseconds: 350)':
          'toque longo do microfone: gesto, não animação',
    },
    'lib/ui/school/widgets/lesson_screen.dart': {
      'Timer.periodic(const Duration(milliseconds: 250)':
          'relógio do passo de pensar e ritmo da demonstração: tempo, não '
          'animação',
    },
    'lib/ui/core/widgets/skeleton.dart': {
      'sweep = Duration(milliseconds: 1400)': 'volta contínua do brilho',
    },
    'lib/ui/tour/widgets/tour_demos.dart': {
      'const Duration(milliseconds:': 'coreografia das demonstrações do tour',
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
