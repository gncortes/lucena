import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../testing/board_center.dart';

/// A8 (Gabriel, 08/11): o tabuleiro de ponta a ponta, com o centro no centro
/// da tela útil (entre a barra de status e a de navegação), em toda tela com
/// tabuleiro, menos a lição.
///
/// Este teste-guarda varre `lib/ui` atrás de todo uso de tabuleiro e exige
/// que cada arquivo esteja em [_telas]: o teste de geometria que o cobre
/// (com [testWidgetsA8] e [expectTabuleiroNoCentro]) ou o motivo da isenção.

/// Os widgets que desenham um tabuleiro (o do chessground e os nossos que o
/// embrulham).
final _tabuleiro = RegExp(
  r'\b(Chessboard|StaticChessboard|TabuleiroAnimado|ScriptBoard|ReviewBoard|'
  r'RaceFadingBoard|PositionBoard|BoardPreview)\(',
);

const _licao = 'isenta: lição';
const _componente = 'isenta: componente (coberto pelas telas que o usam)';
const _miniatura = 'isenta: miniatura em cartão, folha ou lista';
const _ilustracao = 'isenta: ilustração numa página que rola, sem jogo';

/// Arquivo em `lib/ui` → teste de geometria A8 que o cobre, ou a isenção.
const _telas = <String, String>{
  // Telas de jogo e de exercício: tabuleiro no centro útil.
  'blind/widgets/blind_game_screen.dart':
      'test/ui/blind/blind_game_screen_test.dart',
  'board_controls/widgets/board_controls_screen.dart':
      'test/ui/board_controls/board_controls_test.dart',
  'endgames/widgets/exercise_screen.dart':
      'test/ui/endgames/exercise_geometry_test.dart',
  'featured/widgets/find_move_screen.dart':
      'test/ui/featured/find_move_center_test.dart',
  'free_board/widgets/free_board_screen.dart':
      'test/ui/free_board/widgets/free_board_screen_test.dart',
  'game_details/widgets/game_details_screen.dart':
      'test/ui/game_details/game_details_screen_test.dart',
  'game_details/widgets/review_widgets.dart':
      'test/ui/game_details/game_details_screen_test.dart',
  'game_setup/widgets/game_setup_screen.dart':
      'test/ui/game_setup/widgets/game_setup_screen_test.dart',
  'journey/widgets/challenge_screen.dart':
      'test/ui/journey/challenge_screen_test.dart',
  'learning_analysis/widgets/learning_analysis_screen.dart':
      'test/ui/learning_analysis/learning_analysis_screen_test.dart',
  'placement/widgets/placement_screen.dart':
      'test/ui/placement/placement_screen_test.dart',
  'race/widgets/race_game_view.dart': 'test/ui/race/race_screen_test.dart',
  'race/widgets/race_review_view.dart': 'test/ui/race/race_screen_test.dart',
  'race/widgets/race_warm_up_screen.dart':
      'test/ui/race/race_warm_up_screen_test.dart',
  'school/widgets/star_challenge_screen.dart':
      'test/ui/school/star_challenge_screen_test.dart',
  'treinador/widgets/treinador_exercicio_screen.dart':
      'test/ui/treinador/treinador_exercicio_screen_test.dart',
  'training_exercise/widgets/training_exercise_screen.dart':
      'test/ui/training_exercise/training_exercise_screen_test.dart',
  'training_goal/widgets/training_test_screen.dart':
      'test/ui/training_goal/training_test_screen_test.dart',
  'training_opening/widgets/training_opening_screen.dart':
      'test/ui/training_opening/training_opening_screen_test.dart',
  // A lição (modo aula) desce o tabuleiro pelo balão do Viktor.
  'lesson_script/widgets/lesson_script_screen.dart': _licao,
  'lesson_script/widgets/script_board.dart': _licao,
  // Os próprios widgets de tabuleiro.
  'core/motion/tabuleiro_animado.dart': _componente,
  'core/widgets/position_board.dart': _componente,
  'core/board/board_appearance_widgets.dart': _componente,
  // Posição pequena, sem jogo.
  'board_settings/widgets/board_appearance_screen.dart': _miniatura,
  'campaign/widgets/link_lead_sheet.dart': _miniatura,
  'challenge/widgets/challenge_result_card.dart': _miniatura,
  'challenge/widgets/challenge_sheet.dart': _miniatura,
  'challenge/widgets/link_setup_screen.dart': _miniatura,
  'core/widgets/position_card.dart': _miniatura,
  'endgames/widgets/endgame_info_screen.dart': _miniatura,
  'featured/widgets/featured_card.dart': _miniatura,
  'free_board/widgets/saved_game_sheet.dart': _miniatura,
  'home/widgets/hero_card.dart': _miniatura,
  'journey/widgets/rung_screen.dart': _miniatura,
  'race/widgets/race_result_view.dart': _miniatura,
  'race/widgets/race_warm_up_sheet.dart': _miniatura,
  'training_progress/widgets/training_theme_screen.dart': _miniatura,
  // Posição grande numa página de leitura, sem lance.
  'challenge/widgets/challenge_link_screen.dart': _ilustracao,
  'conclusion/widgets/conclusion_screen.dart': _ilustracao,
  'daily/widgets/daily_game_actions.dart': _ilustracao,
  'featured/widgets/featured_endgame_screen.dart': _ilustracao,
  'tour/widgets/tour_screen.dart': _ilustracao,
  'training_profile/widgets/training_profile_why_screen.dart': _ilustracao,
};

/// Dívida da A8: telas que ainda não cabem em 360x740 com o tabuleiro no
/// centro (o conteúdo de cima ou de baixo pede mais que a sobra) e rodam o
/// teste A8 só nos outros aparelhos (`pendente360x740: true`). A lista só
/// diminui: tela nova entra já cabendo.
const _pendentes360x740 = {
  'test/ui/board_controls/board_controls_test.dart',
  'test/ui/featured/find_move_center_test.dart',
  'test/ui/free_board/widgets/free_board_screen_test.dart',
  'test/ui/game_details/game_details_screen_test.dart',
  'test/ui/game_setup/widgets/game_setup_screen_test.dart',
  'test/ui/journey/challenge_screen_test.dart',
  'test/ui/learning_analysis/learning_analysis_screen_test.dart',
  'test/ui/race/race_screen_test.dart',
  'test/ui/race/race_warm_up_screen_test.dart',
  'test/ui/school/star_challenge_screen_test.dart',
};

/// Os trechos `testWidgetsA8(...)` do arquivo, com os parênteses casados
/// (ignora parênteses dentro de texto entre aspas).
List<String> _chamadasA8(String source) {
  final calls = <String>[];
  var from = 0;
  while (true) {
    final start = source.indexOf('testWidgetsA8(', from);
    if (start < 0) return calls;
    var depth = 0;
    String? quote;
    var i = start + 'testWidgetsA8'.length;
    for (; i < source.length; i++) {
      final c = source[i];
      if (quote != null) {
        if (c == r'\') {
          i++;
        } else if (c == quote) {
          quote = null;
        }
      } else if (c == "'" || c == '"') {
        quote = c;
      } else if (c == '(') {
        depth++;
      } else if (c == ')' && --depth == 0) {
        break;
      }
    }
    calls.add(source.substring(start, i + 1));
    from = i + 1;
  }
}

void main() {
  final usos = <String>{
    for (final file in Directory('lib/ui').listSync(recursive: true))
      if (file is File &&
          file.path.endsWith('.dart') &&
          _tabuleiro.hasMatch(file.readAsStringSync()))
        file.path.substring('lib/ui/'.length),
  };

  test('A8: todo arquivo de lib/ui com tabuleiro está na tabela do centro', () {
    final faltando = usos.difference(_telas.keys.toSet()).toList()..sort();
    expect(
      faltando,
      isEmpty,
      reason:
          'Tela nova com tabuleiro: o centro dele fica no centro útil (A8). '
          'Escreva o teste de centro (testWidgetsA8 + '
          'expectTabuleiroNoCentro, de testing/board_center.dart) e ponha a '
          'tela em _telas, em test/ui/core/board/centro_em_toda_tela_test.dart '
          '(ou a isenção, com o motivo).',
    );
    final sobrando = _telas.keys.toSet().difference(usos).toList()..sort();
    expect(
      sobrando,
      isEmpty,
      reason: 'Arquivo sem tabuleiro (ou apagado): tire-o de _telas.',
    );
  });

  final testes = _telas.values.where((v) => !v.startsWith('isenta')).toSet();
  for (final path in testes) {
    test('A8: $path checa o centro útil em todo aparelho', () {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path não existe');
      final source = file.readAsStringSync();
      expect(source, contains("testing/board_center.dart'"));
      final chamadas = _chamadasA8(source);
      expect(chamadas, isNotEmpty, reason: '$path sem testWidgetsA8');
      for (final chamada in chamadas) {
        expect(chamada, isNot(contains('skip')), reason: chamada);
        expect(chamada, contains('expectTabuleiroNoCentro('), reason: chamada);
      }
      final pendente = chamadas.any((c) => c.contains('pendente360x740'));
      expect(
        pendente,
        _pendentes360x740.contains(path),
        reason: pendente
            ? '$path pulou 360x740 sem estar na dívida: a tela nova tem de '
                  'caber em 360x740.'
            : '$path já cabe em 360x740: tire-o de _pendentes360x740.',
      );
    });
  }

  test('A8: os testes rodam em 360x740, 393x873 e 412x915, barras 24/32', () {
    for (final size in const [Size(360, 740), Size(393, 873), Size(412, 915)]) {
      expect(
        aparelhosA8.where(
          (a) => a.size == size && a.status == 24 && a.nav == 32,
        ),
        hasLength(1),
        reason: '$size com barra de status 24 e de navegação 32',
      );
    }
    expect(_pendentes360x740.difference(testes), isEmpty);
  });
}
