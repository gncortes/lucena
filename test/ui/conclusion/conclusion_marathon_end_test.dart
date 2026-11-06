import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_dependencies.dart';

/// B4a (T85): a Maratona concluída, como o app a abre (`go`, sem tela por
/// baixo), tem a volta para a lista de Speedruns e nada fica atrás dos botões.
void main() {
  Future<void> openMarathonEnd(
    WidgetTester tester, {
    Size size = const Size(412, 700),
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final now = FakeNow(DateTime.utc(2026, 11, 2, 12));
    final progress = FakeProgressRepository();
    final speedruns = FakeSpeedrunRepository(progress);
    final template = sampleMarathon;
    final base = SpeedrunPaces.withTime(template, sampleSpeedrunTime);
    final attempt = await speedruns.start(base.id, now());
    final stages = template.stages.length;
    var last = 0;
    for (var stage = 0; stage < stages; stage++) {
      now.advance(const Duration(seconds: 5));
      last = await progress.addAttempt(
        Attempt(
          positionId: samplePositions[0].id,
          playedAt: now(),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          opponentLevel: 1000,
          userClock: const Duration(seconds: 20),
          userTime: base.time,
          startFen: samplePositions[0].fen,
          endReason: GameEndReason.checkmate,
          speedrunAttemptId: attempt.id,
          speedrunStage: stage,
        ),
      );
    }
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(
          now: now,
          progressRepository: progress,
          speedrunRepository: speedruns,
          journeyRepository: FakeJourneyRepository(speedruns: [template]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomeKeys.screen));
    GoRouter.of(context).go(Routes.conclusion(last));
    await tester.pumpAndSettle();
    expect(find.byKey(ConclusionKeys.screen), findsOneWidget);
    expect(find.byKey(ConclusionKeys.run), findsOneWidget);
  }

  testWidgets('Maratona concluída tem voltar e ele leva aos Speedruns', (
    tester,
  ) async {
    await openMarathonEnd(tester);
    expect(find.byKey(ConclusionKeys.back), findsOneWidget);
    await tester.tap(find.byKey(ConclusionKeys.back));
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.listScreen), findsOneWidget);
  });

  testWidgets('nada da rolagem fica atrás dos botões, nem em tela baixa', (
    tester,
  ) async {
    await openMarathonEnd(tester, size: const Size(360, 600));
    final bar = tester.getRect(
      find.byKey(ConclusionKeys.action(ConclusionAction.summary)),
    );
    final scroll = tester.getRect(find.byType(SingleChildScrollView).first);
    expect(scroll.bottom, lessThanOrEqualTo(bar.top));
    final retry = tester.getRect(
      find.byKey(ConclusionKeys.action(ConclusionAction.retry)),
    );
    expect(retry.bottom, lessThanOrEqualTo(600));
  });
}
