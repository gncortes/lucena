import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_attempt_screen.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeNow now;
  late FakeProgressRepository progress;
  late SpeedrunCubit cubit;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    progress = FakeProgressRepository();
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: FakeSpeedrunRepository(progress),
      games: FakeOngoingGameRepository(),
      now: now,
    );
  });
  tearDown(() => cubit.close());

  Future<void> game(int attempt, int stage, int seconds, {bool won = true}) =>
      progress.addAttempt(
        Attempt(
          positionId: 'basic.queen.0001',
          playedAt: now(),
          outcome: won ? AttemptOutcome.win : AttemptOutcome.loss,
          fulfilled: won,
          opponent: OpponentKind.maia,
          userClock: Duration(seconds: seconds),
          speedrunAttemptId: attempt,
          speedrunStage: stage,
        ),
      );

  Future<void> pump(WidgetTester tester, int attempt) async {
    await cubit.load(speedrunId: 'rung.1000', attemptId: attempt);
    await tester.pumpWidget(
      TestApp(
        child: BlocProvider.value(
          value: cubit,
          child: const SpeedrunAttemptScreen(),
        ),
      ),
    );
  }

  testWidgets('em andamento: parciais, derrotas e a etapa da vez', (
    tester,
  ) async {
    await cubit.load(speedrunId: 'rung.1000');
    final id = (await cubit.start())!;
    await game(id, 0, 20, won: false);
    await game(id, 0, 15);

    await pump(tester, id);

    expect(find.text('0:35.0'), findsWidgets);
    expect(find.text('1 loss'), findsOneWidget);
    expect(find.text('Play stage 2'), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
  });

  testWidgets('a primeira concluída é recorde', (tester) async {
    await cubit.load(speedrunId: 'rung.1000');
    final id = (await cubit.start())!;
    await game(id, 0, 30);
    await game(id, 1, 40);

    await pump(tester, id);

    expect(find.byKey(SpeedrunKeys.newRecord), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.play), findsNothing);
    expect(tester.widget<Text>(find.byKey(SpeedrunKeys.total)).data, '1:10.0');
  });

  testWidgets('mais lenta que o recorde: diferença em segundos', (
    tester,
  ) async {
    await cubit.load(speedrunId: 'rung.1000');
    final first = (await cubit.start())!;
    await game(first, 0, 30);
    await game(first, 1, 40);
    now.advance(const Duration(minutes: 5));
    final second = (await cubit.start())!;
    await game(second, 0, 33);
    await game(second, 1, 40);

    await pump(tester, second);

    expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
    expect(find.text('+3.0 s vs. record 1:10.0'), findsOneWidget);
  });
}
