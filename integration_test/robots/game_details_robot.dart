import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';
import 'package:patrol/patrol.dart';

/// Os detalhes de uma partida, com a revisão pela engine.
class GameDetailsRobot {
  const GameDetailsRobot(this.$);

  final PatrolIntegrationTester $;

  /// Abre os detalhes da partida [id] a partir da tela inicial.
  Future<void> open(int id) async {
    await $(HomeKeys.screen).waitUntilVisible();
    GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
        .push(Routes.game(id));
    await $(GameDetailsKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  GameDetailsState get state => $.tester
      .element(find.byKey(GameDetailsKeys.screen))
      .read<GameDetailsCubit>()
      .state;

  Future<void> review() async {
    // A partida antiga abre sem análise (H-PAR-17): Analisar roda a rápida; a média vem depois pela folha.
    await $(GameDetailsKeys.oldAnalysisButton).tap();
    await _waitReview((s) => s.review != null);
    await $(GameDetailsKeys.levelDeepen).scrollTo().tap();
    await $(GameDetailsKeys.depthMedium).tap();
    await $(GameDetailsKeys.depthConfirm).tap();
    // Com a engine de verdade a revisão leva um tempo.
    await _waitReview((s) => (s.review?.depth ?? 0) >= 2);
    await $.pumpAndSettle();
  }

  Future<void> _waitReview(bool Function(GameDetailsState) done) async {
    final end = DateTime.now().add(const Duration(minutes: 3));
    while (!(done(state) && !state.reviewing) && DateTime.now().isBefore(end)) {
      await $.pump(const Duration(milliseconds: 200));
    }
    expect(done(state) && !state.reviewing, isTrue, reason: 'revisão');
  }

  Future<void> expectReviewed() async {
    // A revisão anda com o tabuleiro: o resumo pode ter ficado acima da tela
    // (o `scrollTo` só desce).
    await $(GameDetailsKeys.reviewSummary).waitUntilExists();
    await $.tester.ensureVisible(find.byKey(GameDetailsKeys.reviewSummary));
    await $.pumpAndSettle();
    expect(find.byKey(GameDetailsKeys.accuracyWhite), findsOneWidget);
    // A revisão feita fica no botão, marcada e desligada (T51).
  }

  // Os botões de lance ficam fixos embaixo, fora das abas.
  Future<void> _tap(Key key) async {
    await $(key).tap();
    await $.pumpAndSettle();
  }

  /// Abre uma das abas (Resumo, Lances ou Motor).
  Future<void> openTab(Key tab) async {
    await $(tab).tap();
    await $.pump(const Duration(milliseconds: 500));
  }

  Future<void> first() => _tap(GameDetailsKeys.first);
  Future<void> previous() => _tap(GameDetailsKeys.previous);
  Future<void> next() => _tap(GameDetailsKeys.next);
  Future<void> last() => _tap(GameDetailsKeys.last);

  Future<void> toggleEngine() async {
    await _tap(GameDetailsKeys.engineButton);
    await openTab(GameDetailsKeys.tabEngine);
    await $(GameDetailsKeys.engineLines).waitUntilExists();
    // Na posição final (mate ou empate) não há linhas: o painel diz isso.
    final position = state.shownPosition;
    if (position != null && !position.isGameOver) {
      await $(GameDetailsKeys.engineLine(0))
          .waitUntilExists(timeout: const Duration(minutes: 1));
    }
  }

  void expectShown(int index) => expect(state.shownIndex, index);
}
