import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_history_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_history_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';

/// O ramo da Maratona do histórico de um speedrun (T67f, lote 4): chip,
/// "Mais tempo sobrando", linhas por fim e a aba que abre a rota.
void main() {
  final id = SpeedrunPaces.idFor(sampleMarathon.id, sampleSpeedrunTime);
  final stages = sampleMarathon.stages.length;
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late FakeRatingRepository rating;
  late SpeedrunHistoryCubit cubit;

  setUp(() {
    now = FakeNow(DateTime(2026, 10, 13, 12));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    rating = FakeRatingRepository(now: now)..speedrunOf = (_) => id;
    cubit = SpeedrunHistoryCubit(
      journey: FakeJourneyRepository(
        speedruns: [...sampleSpeedruns, sampleMarathon],
      ),
      speedruns: speedruns,
      rating: rating,
      now: now,
      characters: FakeCharacterRepository(),
    );
  });
  tearDown(() => cubit.close());

  Future<void> play(
    int attempt,
    int stage, {
    AttemptOutcome outcome = AttemptOutcome.win,
    GameEndReason? reason,
    int seconds = 20,
  }) async {
    now.advance(const Duration(minutes: 1));
    await progress.addAttempt(
      Attempt(
        positionId: 'basic.queen.0001',
        playedAt: now(),
        outcome: outcome,
        fulfilled: outcome == AttemptOutcome.win,
        opponent: OpponentKind.maia,
        endReason: reason,
        userClock: Duration(seconds: seconds),
        speedrunAttemptId: attempt,
        speedrunStage: stage,
      ),
    );
  }

  Future<int> start(DateTime at) async {
    now.value = at;
    return (await speedruns.start(id, at)).id;
  }

  Future<void> complete(DateTime at, int seconds) async {
    final attempt = await start(at);
    for (var stage = 0; stage < stages; stage++) {
      await play(attempt, stage, seconds: seconds);
    }
  }

  // Vence a etapa 1 e acaba na 2 do jeito [end].
  Future<void> stop(DateTime at, SpeedrunRunEnd end) async {
    final attempt = await start(at);
    await play(attempt, 0, seconds: 30);
    switch (end) {
      case SpeedrunRunEnd.lost:
        await play(
          attempt,
          1,
          outcome: AttemptOutcome.loss,
          reason: GameEndReason.checkmate,
        );
      case SpeedrunRunEnd.drawn:
        await play(
          attempt,
          1,
          outcome: AttemptOutcome.draw,
          reason: GameEndReason.stalemate,
        );
      case SpeedrunRunEnd.timeout:
        await play(
          attempt,
          1,
          outcome: AttemptOutcome.loss,
          reason: GameEndReason.timeout,
          seconds: 150,
        );
      default:
    }
    await speedruns.abandon(attempt, now());
  }

  // Outubro: o recorde (mais tempo sobrando), outra conclusão e um fim de
  // cada tipo. As linhas vão da mais nova para a mais antiga.
  Future<void> history() async {
    await complete(DateTime(2026, 10, 1, 20), 60);
    await complete(DateTime(2026, 10, 2, 20), 40);
    await stop(DateTime(2026, 10, 3, 20), SpeedrunRunEnd.lost);
    await stop(DateTime(2026, 10, 4, 20), SpeedrunRunEnd.drawn);
    await stop(DateTime(2026, 10, 5, 20), SpeedrunRunEnd.timeout);
    await stop(DateTime(2026, 10, 6, 20), SpeedrunRunEnd.abandoned);
    now.value = DateTime(2026, 10, 13, 12);
  }

  String textOf(WidgetTester tester, Key key) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(Text),
          matchRoot: true,
        ),
      )
      .map((text) => text.data ?? text.textSpan?.toPlainText())
      .join(' | ');

  Future<void> pump(
    WidgetTester tester, {
    bool seed = true,
    Locale locale = const Locale('pt'),
    Size size = const Size(412, 917),
    double textScale = 1,
    bool dark = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      if (seed) await history();
      await cubit.load(id);
    });
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await tester.runAsync(settings.load);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: BlocProvider.value(
              value: cubit,
              child: const SpeedrunHistoryScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('o view model', () {
    test('a classificação do fim é a da Maratona (inclui sem tempo)', () async {
      await history();
      await cubit.load(id);
      expect(
        [for (final run in cubit.state.runs) run.end],
        [
          SpeedrunRunEnd.abandoned,
          SpeedrunRunEnd.timeout,
          SpeedrunRunEnd.drawn,
          SpeedrunRunEnd.lost,
          SpeedrunRunEnd.completed,
          SpeedrunRunEnd.completed,
        ],
      );
    });
  });

  group('a tela', () {
    testWidgets('com recorde: chip, "Mais tempo sobrando" e contagens', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Maratona'), findsOneWidget);
      expect(
        textOf(tester, SpeedrunKeys.historyRecord),
        allOf(contains('Mais tempo sobrando'), isNot(contains('Seu recorde'))),
      );
      expect(textOf(tester, SpeedrunKeys.historyAttempts), '6 | tentativas');
      expect(textOf(tester, SpeedrunKeys.historyFinished), '2 | concluídas');
      expect(find.byKey(SpeedrunKeys.historyNotFinished), findsNothing);
      final record = tester.widget<TimeDisplay>(
        find.descendant(
          of: find.byKey(SpeedrunKeys.historyRecord),
          matching: find.byType(TimeDisplay),
        ),
      );
      // 3 minutos menos 3 etapas de 40 s: sobra 1:00.
      expect(record.value, '1:00.0');
      expect(cubit.state.runs[4].record, isTrue);
    });

    testWidgets('linhas: recorde, regressivo "sobrou" e cada fim', (
      tester,
    ) async {
      await pump(tester);
      // Mais novo primeiro: desistiu, sem tempo, empate, perdeu, 2 conclusões.
      expect(
        textOf(tester, SpeedrunKeys.historyRun(0)),
        'Desistiu na etapa 2 de 3 | Dia 6, às 20:01',
      );
      expect(
        textOf(tester, SpeedrunKeys.historyRun(1)),
        startsWith('Sem tempo na etapa 2 de 3'),
      );
      expect(
        textOf(tester, SpeedrunKeys.historyRun(2)),
        startsWith('Empatou na etapa 2 de 3'),
      );
      expect(
        textOf(tester, SpeedrunKeys.historyRun(3)),
        startsWith('Perdeu na etapa 2 de 3'),
      );
      expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
      TimeDisplay display(int row) => tester.widget<TimeDisplay>(
        find.descendant(
          of: find.byKey(SpeedrunKeys.historyRun(row)),
          matching: find.byType(TimeDisplay),
        ),
      );
      expect(display(4).type, TimeDisplayType.record);
      expect(display(5).type, TimeDisplayType.countdown);
      expect(display(5).value, '0:00.0');
      for (final row in [4, 5]) {
        expect(
          textOf(tester, SpeedrunKeys.historyRun(row)),
          contains('sobrou'),
        );
      }
    });

    testWidgets('nunca concluída: o aviso no lugar do recorde', (tester) async {
      await tester.runAsync(
        () => stop(DateTime(2026, 10, 3, 20), SpeedrunRunEnd.lost),
      );
      await pump(tester, seed: false);
      expect(
        textOf(tester, SpeedrunKeys.historyNotFinished),
        'Você ainda não concluiu esta maratona',
      );
      expect(find.byKey(SpeedrunKeys.historyRecord), findsNothing);
      expect(textOf(tester, SpeedrunKeys.historyFinished), '0 | concluídas');
    });

    for (final size in [const Size(360, 740), const Size(412, 917)]) {
      for (final dark in [false, true]) {
        testWidgets('fonte 2,0 em ${size.width.toInt()}'
            '${dark ? ' escuro' : ''} sem estouro, alvos >= 48', (
          tester,
        ) async {
          await pump(tester, size: size, textScale: 2, dark: dark);
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(SpeedrunKeys.historyRun(5)),
            300,
          );
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byKey(SpeedrunKeys.historyRun(5))).height,
            greaterThanOrEqualTo(56),
          );
        });
      }
    }

    testWidgets('1,0 em 360: sem estouro e linhas >= 56', (tester) async {
      await pump(tester, size: const Size(360, 740));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(SpeedrunKeys.historyRun(0))).height,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('no árabe, os números ficam LTR', (tester) async {
      await pump(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      final attempts = tester.widget<Text>(
        find
            .descendant(
              of: find.byKey(SpeedrunKeys.historyAttempts),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(attempts.data, '6');
      expect(attempts.textDirection, TextDirection.ltr);
    });

    testWidgets('a rota do histórico abre pela linha da aba (id da Maratona)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await history();
        await cubit.load(id);
      });
      final router = GoRouter(
        initialLocation: Routes.speedrunHistory(id),
        routes: [
          GoRoute(
            path: '/speedruns/:speedrun/history',
            builder: (context, state) => BlocProvider.value(
              value: cubit,
              child: const SpeedrunHistoryScreen(),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          router: router,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SpeedrunKeys.historyScreen), findsOneWidget);
      expect(find.text('Maratona'), findsOneWidget);
    });
  });
}
