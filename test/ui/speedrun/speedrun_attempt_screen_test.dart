import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_attempt_screen.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';
import '../../../testing/fakes/fake_settings_repository.dart';

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
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const SpeedrunAttemptScreen(),
        ),
      ),
    );
  }

  // O tempo de um RunClock (os décimos ficam num pedaço menor).
  String clockText(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).textSpan!.toPlainText();

  testWidgets('abandonada: até onde foi, o tempo, as derrotas e nada de '
      'jogar', (tester) async {
    await cubit.load(speedrunId: 'rung.1000');
    final (_, id) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await game(id, 0, 20, won: false);
    await game(id, 0, 15);

    // Sem a etapa no tabuleiro, a tentativa pela metade é largada ao abrir.
    await pump(tester, id);

    expect(find.byKey(SpeedrunKeys.abandoned), findsOneWidget);
    expect(find.text('Gave up at stage 2 of 2'), findsOneWidget);
    expect(clockText(tester, SpeedrunKeys.total), '0:35.0');
    expect(clockText(tester, SpeedrunKeys.stageTime(0)), '0:35.0');
    // A etapa com a derrota diz quantas foram.
    await tester.scrollUntilVisible(find.text('1 loss'), 100);
    expect(find.text('1 loss'), findsOneWidget);
    // Só o resumo: sem jogar nem menu.
    expect(find.byKey(SpeedrunKeys.play), findsNothing);
    expect(find.byKey(SpeedrunKeys.menu), findsNothing);
    expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
  });

  testWidgets('a primeira concluída é recorde', (tester) async {
    await cubit.load(speedrunId: 'rung.1000');
    final (_, id) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await game(id, 0, 30);
    await game(id, 1, 40);

    await pump(tester, id);

    expect(find.byKey(SpeedrunKeys.newRecord), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.abandoned), findsNothing);
    expect(clockText(tester, SpeedrunKeys.total), '1:10.0');
  });

  testWidgets('mais lenta que o recorde: diferença em segundos', (
    tester,
  ) async {
    await cubit.load(speedrunId: 'rung.1000');
    final (_, first) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await game(first, 0, 30);
    await game(first, 1, 40);
    now.advance(const Duration(minutes: 5));
    final (_, second) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await game(second, 0, 33);
    await game(second, 1, 40);

    await pump(tester, second);

    expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
    expect(find.text('+3.0 s vs. record 1:10.0'), findsOneWidget);
  });
}
