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
    // A rápida começa sozinha ao abrir (T65): a média só depois dela.
    await _waitReview((s) => s.review != null);
    await $(GameDetailsKeys.reviewButton).scrollTo().tap();
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

  // Os botões de lance ficam fixos embaixo do tabuleiro: se a folha está
  // aberta por cima deles, o "x" a desce antes.
  Future<void> _tap(Key key) async {
    final close = find.byKey(GameDetailsKeys.closeSheet).hitTestable();
    if (close.evaluate().isNotEmpty) {
      await $.tester.tap(close);
      await $.pumpAndSettle();
    }
    await $(key).tap();
    await $.pumpAndSettle();
  }

  Future<void> first() => _tap(GameDetailsKeys.first);
  Future<void> previous() => _tap(GameDetailsKeys.previous);
  Future<void> next() => _tap(GameDetailsKeys.next);
  Future<void> last() => _tap(GameDetailsKeys.last);

  Future<void> toggleEngine() async {
    await _tap(GameDetailsKeys.engineButton);
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
