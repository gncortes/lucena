import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/coach/view_models/coach_exercise_cubit.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';
import '../../testing/fakes/fake_coach_repository.dart';
import '../../testing/coach_fixtures.dart';

/// O Treinador de partidas (T87): abas, partida, espera, exercícios e fim.
class CoachRobot {
  const CoachRobot(this.$);

  final PatrolIntegrationTester $;

  static const _wait = Duration(seconds: 20);

  /// Da tela inicial ao Treinador, pelo atalho "Análise".
  /// Com plano, o atalho abre a última partida por fazer por cima da lista
  /// (A10 G1): volta dela para chegar às abas.
  Future<void> openFromHome() async {
    await $(HomeKeys.analysisButton).scrollTo().tap();
    // A lista carrega (esqueleto) e só então decide: abas ou a partida.
    bool visibleArea(Key k) =>
        find.byKey(k).hitTestable().evaluate().isNotEmpty;
    for (var i = 0; i < 100; i++) {
      await $.pump(const Duration(milliseconds: 200));
      if (visibleArea(CoachKeys.back) || visibleArea(CoachKeys.tabGames)) {
        break;
      }
    }
    for (var i = 0; i < 5; i++) {
      await $.pump(const Duration(milliseconds: 200));
    }
    if (!visibleArea(CoachKeys.tabGames) && visibleArea(CoachKeys.back)) {
      await $.tester.tap(find.byKey(CoachKeys.back).hitTestable().first);
      await $.pumpAndSettle();
    }
    await $(CoachKeys.screen).waitUntilVisible(timeout: _wait);
  }

  Future<void> tab(Key tab) async {
    await $(tab).tap();
    await $.pumpAndSettle();
  }

  /// Liga a conta do [site] com o [username] e confirma.
  Future<void> link(Key site, String username) async {
    await $(CoachKeys.linkAccount).waitUntilVisible(timeout: _wait);
    await $(site).tap();
    await $(CoachKeys.username).enterText(username);
    await $(CoachKeys.confirmAccount).tap();
    await $.pumpAndSettle();
  }

  /// Abre a partida [id] pela lista da aba Partidas.
  Future<void> openGame(String id) async {
    await $(CoachKeys.game(id)).scrollTo().tap();
    await $(CoachKeys.back).waitUntilVisible(timeout: _wait);
    await $.pumpAndSettle();
  }

  /// A tela de espera tem um relógio de 1 s: avança em passos fixos.
  Future<void> waitLoading() async {
    await $(CoachKeys.loading).waitUntilVisible(timeout: _wait);
    await $.pump(const Duration(milliseconds: 500));
  }

  /// O servidor termina a análise de [id] com os exercícios da partida
  /// do Tiago, como o [FakeCoachRepository.analyzeCompletes] faz.
  void finish(FakeCoachRepository fake, String id) {
    final current = CoachFixtures.list().firstWhere((p) => p.id == id);
    fake.perGame(
      CoachGame.fromJson(id, {
        ...current.toJson(),
        ...CoachFixtures.tiagoJson(),
        'jogadaEm': current.moveAt.toIso8601String(),
        'adversario': current.opponent.toJson(),
        'resultado': current.result.wire,
      })!,
    );
  }

  CoachExerciseState get _exercise => $.tester
      .element(find.byKey(CoachKeys.exercise))
      .read<CoachExerciseCubit>()
      .state;

  int get index => _exercise.index;

  ExerciseStep get phase => _exercise.phase;

  Future<void> waitExercise() async {
    await $(CoachKeys.exerciseBoard).waitUntilVisible(timeout: _wait);
    await $.pumpAndSettle();
  }

  /// Joga a solução do exercício aberto.
  Future<void> solve() => _play(_exercise.exercise!.solution);

  /// Joga um lance legal que não é a solução.
  Future<void> miss() {
    final ex = _exercise.exercise!;
    final pos = Chess.fromSetup(Setup.parseFen(ex.fen));
    for (final MapEntry(key: from, value: tos) in pos.legalMoves.entries) {
      for (final to in tos.squares) {
        final uci = NormalMove(from: from, to: to).uci;
        if (uci != ex.solution &&
            !uci.startsWith(ex.solution.substring(0, 4))) {
          return _play(uci);
        }
      }
    }
    throw StateError('sem lance errado em ${ex.fen}');
  }

  Future<void> _play(String uci) async {
    final move = Move.parse(uci)! as NormalMove;
    final board = find.byKey(CoachKeys.exerciseBoard);
    final rect = $.tester.getRect(board);
    final side = $.tester.widget<Chessboard>(board).orientation;
    await $.tester.tapAt(squareCenter(rect, move.from.name, orientation: side));
    await $.pump();
    await $.tester.tapAt(squareCenter(rect, move.to.name, orientation: side));
    await $.pumpAndSettle();
  }

  /// Acerta e passa ao próximo (ou à pontuação, no último).
  Future<void> solveAndAdvance() async {
    await solve();
    await $(CoachKeys.next).waitUntilVisible(timeout: _wait);
    await $(CoachKeys.next).tap();
    await $.pumpAndSettle();
  }

  void wait(Key key) =>
      expect(find.byKey(key), findsWidgets, reason: 'faltou $key');

  void hasNot(Key key) =>
      expect(find.byKey(key), findsNothing, reason: 'sobrou $key');
}
