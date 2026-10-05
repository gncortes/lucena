import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/test_dependencies.dart';

/// O caminho de uma tentativa pelo app: as telas de cima mostram o resultado
/// novo ao voltar, mesmo com a tentativa reaberta pelo fim de cada etapa.
void main() {
  // O texto na key, simples ou com partes (o RunClock escreve os décimos
  // menores).
  String runClock(WidgetTester tester, Key key) {
    final text = tester.widget<Text>(find.byKey(key));
    return text.data ?? text.textSpan!.toPlainText();
  }

  Future<void> openSpeedrun(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(HomeKeys.speedrunButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeKeys.speedrunButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.item('rung.1000')));
    await tester.pumpAndSettle();
  }

  testWidgets('ao voltar da tentativa concluída, o recorde aparece', (
    tester,
  ) async {
    final now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    final progress = FakeProgressRepository();
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(now: now, progressRepository: progress),
      ),
    );
    await tester.pumpAndSettle();
    await openSpeedrun(tester);
    // "Começar" abre a primeira etapa direto, no ritmo da lista.
    await tester.tap(find.byKey(SpeedrunKeys.start));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);

    // Cada etapa termina no tabuleiro; depois da última, a partida abre o
    // resumo da tentativa com `go`.
    for (final stage in [0, 1]) {
      now.advance(const Duration(minutes: 1));
      await progress.addAttempt(
        Attempt(
          positionId: 'basic.queen.0001',
          playedAt: now(),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          userClock: const Duration(seconds: 6),
          speedrunAttemptId: 1,
          speedrunStage: stage,
        ),
      );
    }
    final context = tester.element(find.byKey(FreeBoardKeys.screen));
    GoRouter.of(context).go(
      Routes.speedrunAttempt(
        'rung.1000',
        1,
        game: now().millisecondsSinceEpoch,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.newRecord), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(runClock(tester, SpeedrunKeys.best), '0:12.0');
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(runClock(tester, SpeedrunKeys.itemBest('rung.1000')), '0:12.0');
  });

  testWidgets('sair da etapa no meio pede confirmação e encerra a tentativa', (
    tester,
  ) async {
    final now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    final games = FakeOngoingGameRepository();
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(now: now, ongoingGameRepository: games),
      ),
    );
    await tester.pumpAndSettle();
    await openSpeedrun(tester);
    await tester.tap(find.byKey(SpeedrunKeys.start));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);

    // Voltar pergunta antes; desistir de sair continua a partida.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.speedrunQuitConfirm), findsOneWidget);
    await tester.tap(find.byKey(FreeBoardKeys.speedrunQuitConfirm));
    await tester.pumpAndSettle();

    // De volta ao speedrun: a tentativa está no histórico, como abandonada,
    // e nenhuma etapa ficou guardada para depois.
    expect(find.byKey(SpeedrunKeys.screen), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.run(0)), findsOneWidget);
    expect(find.text('Gave up at stage 1 of 2'), findsOneWidget);
    expect(games.snapshot, isNull);
  });
}
