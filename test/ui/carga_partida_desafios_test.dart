import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// H-ANI-07 em Desafios e Partida: toda primeira carga passa pelo
/// `ShimmerConteudo`, que dissolve o esqueleto e sobe o conteúdo. Um esqueleto
/// trocado à mão (`carregando ? SkeletonList() : conteúdo`) pisca: este teste
/// acha o esqueleto que não está no `esqueleto:` do `ShimmerConteudo`.
void main() {
  const telas = [
    'blind/widgets/blind_game_screen.dart',
    'catalog/widgets/catalog_screen.dart',
    'catalog/widgets/category_screen.dart',
    'challenge/widgets/challenge_link_screen.dart',
    // O resultado (S3b) usa a `CascaComAtraso`: casca só após 0,3 s.
    'featured/widgets/featured_list_screen.dart',
    'journey/widgets/challenge_screen.dart',
    'journey/widgets/journey_screen.dart',
    'journey/widgets/rung_screen.dart',
    'custom_position/widgets/custom_position_screen.dart',
    'free_board/widgets/free_board_screen.dart',
    'game_details/widgets/game_details_screen.dart',
    'game_setup/widgets/game_setup_screen.dart',
    'history/widgets/history_screen.dart',
    'race/widgets/race_performance_screen.dart',
    'race/widgets/race_screen.dart',
    'race/widgets/race_warm_up_screen.dart',
    'school/widgets/star_challenge_screen.dart',
    'school/widgets/star_challenges_screen.dart',
    'speedrun/widgets/speedrun_attempt_screen.dart',
    'speedrun/widgets/speedrun_history_screen.dart',
    'speedrun/widgets/speedrun_list_screen.dart',
    'speedrun/widgets/speedrun_screen.dart',
  ];
  final esqueleto = RegExp(
    r'SkeletonList\(|HistoryLoading\(|_DetailsLoading\(|_SetupLoading\(',
  );

  for (final tela in telas) {
    test('$tela: o esqueleto só dentro do ShimmerConteudo', () {
      final codigo = File('lib/ui/$tela').readAsStringSync();
      expect(codigo, contains('ShimmerConteudo('), reason: tela);
      final soltos = <String>[];
      // O widget do esqueleto em si (`class _DetailsLoading`) não conta.
      final classes = RegExp(
        r'\nclass \w*Loading extends[\s\S]*?(?=\nclass |$)',
      ).allMatches(codigo).toList();
      for (final m in esqueleto.allMatches(codigo)) {
        if (classes.any((c) => c.start <= m.start && m.start < c.end)) {
          continue;
        }
        // A declaração do construtor (`const _DetailsLoading();`) não conta.
        if (codigo.startsWith(');', m.end)) continue;
        final antes = codigo.substring(
          (m.start - 80).clamp(0, m.start),
          m.start,
        );
        if (!antes.contains('esqueleto:')) {
          final linha = '\n'.allMatches(codigo.substring(0, m.start)).length;
          soltos.add('$tela:${linha + 1}');
        }
      }
      expect(soltos, isEmpty, reason: soltos.join('\n'));
    });
  }
}
