import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun.dart';
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

/// O histórico de um speedrun (T67d): o recorde, as contagens, as tentativas
/// por mês e o "+N" só na primeira conclusão.
void main() {
  // O mate de dama, Iniciante, 3+2 (Blitz): três etapas.
  const id = 'ending.queen';
  const stages = 3;
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late FakeRatingRepository rating;
  late SpeedrunHistoryCubit cubit;

  setUp(() {
    now = FakeNow(DateTime(2026, 9, 28, 20, 30));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    rating = FakeRatingRepository(now: now)..speedrunOf = (_) => id;
    cubit = SpeedrunHistoryCubit(
      journey: FakeJourneyRepository(),
      speedruns: speedruns,
      rating: rating,
      now: now,
      characters: FakeCharacterRepository(),
    );
  });
  tearDown(() => cubit.close());

  Future<void> game(
    int attempt,
    int stage, {
    AttemptOutcome outcome = AttemptOutcome.win,
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

  Future<void> complete(DateTime at, {int seconds = 20}) async {
    final attempt = await start(at);
    for (var stage = 0; stage < stages; stage++) {
      await game(attempt, stage, seconds: seconds);
    }
  }

  // Perde, empata ou desiste na etapa [stage] (de 0): a tentativa acaba.
  Future<void> stop(DateTime at, int stage, AttemptOutcome? outcome) async {
    final attempt = await start(at);
    for (var index = 0; index < stage; index++) {
      await game(attempt, index);
    }
    if (outcome != null) await game(attempt, stage, outcome: outcome);
    await speedruns.abandon(attempt, now());
  }

  // Setembro: perdeu na etapa 2 e a 1ª conclusão (o bônus). Outubro: o
  // recorde, um empate na etapa 3, uma desistência na etapa 2 e uma
  // tentativa em andamento (fica fora).
  Future<void> history() async {
    await stop(DateTime(2026, 9, 28, 20, 30), 1, AttemptOutcome.loss);
    await complete(DateTime(2026, 9, 28, 20, 40), seconds: 30);
    await complete(DateTime(2026, 10, 3, 18, 10), seconds: 15);
    await stop(DateTime(2026, 10, 5, 19, 30), 2, AttemptOutcome.draw);
    await stop(DateTime(2026, 10, 11, 21, 20), 1, null);
    final ongoing = await start(DateTime(2026, 10, 12, 9));
    await game(ongoing, 0);
    now.value = DateTime(2026, 10, 13, 12);
  }

  group('o view model', () {
    test('as terminadas, da mais nova para a mais antiga, sem a em '
        'andamento', () async {
      await history();
      await cubit.load(id);
      final runs = cubit.state.runs;

      expect(
        [for (final run in runs) run.end],
        [
          SpeedrunRunEnd.abandoned,
          SpeedrunRunEnd.drawn,
          SpeedrunRunEnd.completed,
          SpeedrunRunEnd.completed,
          SpeedrunRunEnd.lost,
        ],
      );
      expect([for (final run in runs) run.stage], [2, 3, 4, 4, 2]);
      expect(cubit.state.finished, 2);
      expect(cubit.state.best, const Duration(seconds: 45));
      expect(cubit.state.bestAt, DateTime(2026, 10, 3, 18, 13));
      expect(
        [for (final run in runs) run.record],
        [false, false, true, false, false],
      );
      expect(cubit.state.year, 2026);
    });

    test('o bônus só na 1ª conclusão, pago em silêncio ao abrir', () async {
      await history();
      expect(await rating.speedrunBonuses(), isEmpty);
      await cubit.load(id);

      // R 1150, Iniciante, Blitz: 1150 × 10% × 0,625 = 71,9 → 70.
      expect(
        [for (final run in cubit.state.runs) run.bonus],
        [null, null, null, 70, null],
      );
      expect(await rating.speedrunBonuses(), hasLength(1));
      // Abrir de novo não paga outra vez.
      await cubit.load(id);
      expect(await rating.speedrunBonuses(), hasLength(1));
    });

    test('sem tentativa: lista vazia, sem recorde', () async {
      await cubit.load(id);
      expect(cubit.state.speedrun?.id, id);
      expect(cubit.state.runs, isEmpty);
      expect(cubit.state.best, isNull);
    });

    test('id que não existe: carregado e vazio', () async {
      await cubit.load('ending.nada');
      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.speedrun, isNull);
    });
  });

  // Até a T67f, a aba Maratona também abre este histórico (T67c).
  testWidgets('a Maratona abre o histórico dela', (tester) async {
    final marathon = SpeedrunHistoryCubit(
      journey: FakeJourneyRepository(
        speedruns: [...sampleSpeedruns, sampleMarathon],
      ),
      speedruns: speedruns,
      rating: rating,
      now: now,
      characters: FakeCharacterRepository(),
    );
    addTearDown(marathon.close);
    await tester.runAsync(() async {
      now.value = DateTime(2026, 9, 10, 9);
      final attempt = (await speedruns.start(sampleMarathon.id, now())).id;
      for (var stage = 0; stage < sampleMarathon.stages.length; stage++) {
        await game(attempt, stage);
      }
      await marathon.load(sampleMarathon.id);
    });
    expect(marathon.state.speedrun?.kind, SpeedrunKind.marathon);
    expect(marathon.state.runs.single.end, SpeedrunRunEnd.completed);
    await tester.pumpWidget(
      TestApp(
        child: BlocProvider.value(
          value: marathon,
          child: const SpeedrunHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(SpeedrunKeys.historyRun(0)), findsOneWidget);
  });

  group('a tela', () {
    Future<void> pump(
      WidgetTester tester, {
      Locale locale = const Locale('pt'),
      Size size = const Size(412, 917),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await history();
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

    testWidgets('meses do mais novo ao mais antigo, com maiúscula', (
      tester,
    ) async {
      await pump(tester);
      expect(textOf(tester, SpeedrunKeys.historyMonth(0)), 'Outubro de 2026');
      expect(textOf(tester, SpeedrunKeys.historyMonth(1)), 'Setembro de 2026');
      expect(find.byKey(SpeedrunKeys.historyMonth(2)), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(SpeedrunKeys.historyMonth(0))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(SpeedrunKeys.historyMonth(1))).dy,
        ),
      );
    });

    testWidgets('recorde com a data, contagens, e as linhas de cada fim', (
      tester,
    ) async {
      await pump(tester);
      expect(
        textOf(tester, SpeedrunKeys.historyRecord),
        allOf(contains('Seu recorde'), contains('Em 3 de outubro, às 18:13')),
      );
      expect(textOf(tester, SpeedrunKeys.historyAttempts), '5 | tentativas');
      expect(textOf(tester, SpeedrunKeys.historyFinished), '2 | concluídas');
      expect(
        textOf(tester, SpeedrunKeys.historyRun(0)),
        'Desistiu na etapa 2 de 3 | Dia 11, às 21:21',
      );
      expect(
        textOf(tester, SpeedrunKeys.historyRun(1)),
        startsWith('Empatou na etapa 3 de 3'),
      );
      expect(
        textOf(tester, SpeedrunKeys.historyRun(4)),
        startsWith('Perdeu na etapa 2 de 3'),
      );
      // O troféu só no recorde.
      final record = tester.widget<TimeDisplay>(
        find.descendant(
          of: find.byKey(SpeedrunKeys.historyRun(2)),
          matching: find.byType(TimeDisplay),
        ),
      );
      expect(record.type, TimeDisplayType.record);
      expect(record.value, '0:45.0');
      final plain = tester.widget<TimeDisplay>(
        find.descendant(
          of: find.byKey(SpeedrunKeys.historyRun(3)),
          matching: find.byType(TimeDisplay),
        ),
      );
      expect(plain.type, TimeDisplayType.stopwatch);
    });

    testWidgets('linha de cima da parada com 28 de altura, como o tempo', (
      tester,
    ) async {
      await pump(tester);
      final top = find
          .descendant(
            of: find.byKey(SpeedrunKeys.historyRun(0)),
            matching: find.byType(ConstrainedBox),
          )
          .evaluate()
          .map((e) => (e.widget as ConstrainedBox).constraints.minHeight);
      expect(top, contains(28.0));
    });

    testWidgets('o "+N" só na 1ª conclusão', (tester) async {
      await pump(tester);
      expect(find.byKey(SpeedrunKeys.historyBonus), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(SpeedrunKeys.historyRun(3)),
          matching: find.byKey(SpeedrunKeys.historyBonus),
        ),
        findsOneWidget,
      );
      expect(
        textOf(tester, SpeedrunKeys.historyBonus),
        '+70 de rating na primeira conclusão',
      );
    });

    testWidgets('tocar a linha abre o resumo da tentativa', (tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await history();
        await cubit.load(id);
      });
      final settings = SettingsCubit(
        FakeSettingsRepository(const AppSettings()),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await tester.runAsync(settings.load);
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
          GoRoute(
            path: '/speedruns/:speedrun/:attempt',
            builder: (context, state) => Text(
              'attempt ${state.pathParameters['attempt']}',
              key: const Key('opened'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          router: router,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SpeedrunKeys.historyRun(2)));
      await tester.pumpAndSettle();
      final attempt = cubit.state.runs[2].run.attempt.id;
      expect(find.text('attempt $attempt'), findsOneWidget);
    });

    for (final size in [const Size(360, 740), const Size(412, 917)]) {
      testWidgets('fonte 2,0 em ${size.width.toInt()} sem estouro', (
        tester,
      ) async {
        await pump(tester, size: size, textScale: 2);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byKey(SpeedrunKeys.historyRun(4)),
          300,
        );
        expect(tester.takeException(), isNull);
      });
    }

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
      expect(attempts.data, '5');
      expect(attempts.textDirection, TextDirection.ltr);
      final time = tester.widget<TimeDisplay>(
        find.descendant(
          of: find.byKey(SpeedrunKeys.historyRecord),
          matching: find.byType(TimeDisplay),
        ),
      );
      expect(time.value, '0:45.0');
      // A seta espelha sozinha: no RTL continua chevron_right.
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('chip do nível contornado e "+N de rating" em negrito', (
      tester,
    ) async {
      await pump(tester);
      final chip = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Iniciante'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = chip.decoration! as BoxDecoration;
      expect(decoration.color, isNull);
      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, BorderRadius.circular(8));
      final bonus = tester.widget<Text>(
        find.descendant(
          of: find.byKey(SpeedrunKeys.historyBonus),
          matching: find.byType(Text),
        ),
      );
      final spans = (bonus.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.text, '+70 de rating');
      expect(spans.first.style?.fontWeight, FontWeight.w700);
      expect(spans.last.style?.fontWeight, isNull);
    });
  });
}
