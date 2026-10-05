import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/test_dependencies.dart';

/// O caminho de uma tentativa pelo app: as telas de cima mostram o resultado
/// novo ao voltar, mesmo com a tentativa reaberta pelo fim de cada etapa.
void main() {
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
    await tester.ensureVisible(find.byKey(HomeKeys.speedrunButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeKeys.speedrunButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.item('rung.1000')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.start));
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.attemptScreen), findsOneWidget);

    // Cada etapa termina no tabuleiro, que volta para a tentativa com `go`.
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
      final context = tester.element(find.byKey(SpeedrunKeys.attemptScreen));
      GoRouter.of(context).go(
        Routes.speedrunAttempt(
          'rung.1000',
          1,
          game: now().millisecondsSinceEpoch,
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(find.byKey(SpeedrunKeys.newRecord), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(SpeedrunKeys.best)).data, '0:12.0');
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(SpeedrunKeys.itemBest('rung.1000'))).data,
      '0:12.0',
    );
  });
}
