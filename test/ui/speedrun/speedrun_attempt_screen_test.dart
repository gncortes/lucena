import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_attempt_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

/// O resumo da tentativa do speedrun clássico (T67b): o fim da tentativa, o
/// recorde, o bônus de rating e o "Tentar novamente".
void main() {
  const base = 'ending.queen';
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late FakeRatingRepository rating;
  late SpeedrunCubit cubit;
  final started = <int, String>{};

  setUp(() {
    started.clear();
    now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    rating = FakeRatingRepository(now: now)..speedrunOf = (id) => started[id]!;
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: speedruns,
      games: FakeOngoingGameRepository(),
      now: now,
      characters: FakeCharacterRepository(),
      rating: rating,
    );
  });
  tearDown(() => cubit.close());

  Future<void> play(
    int attempt,
    int stage, {
    AttemptOutcome outcome = AttemptOutcome.win,
    GameEndReason? reason,
    int seconds = 10,
  }) => progress.addAttempt(
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

  Future<int> begin([TimeControl pace = SpeedrunPaces.standard]) async {
    await cubit.load(speedrunId: base);
    final (speedrun, attempt) = (await cubit.startWith(pace))!;
    started[attempt] = speedrun.id;
    return attempt;
  }

  /// Uma tentativa concluída, [seconds] por etapa.
  Future<int> finished(
    int seconds, [
    TimeControl pace = SpeedrunPaces.standard,
  ]) async {
    final attempt = await begin(pace);
    final total = cubit.state.selected!.speedrun.stages.length;
    for (var stage = 0; stage < total; stage++) {
      now.advance(const Duration(minutes: 1));
      await play(attempt, stage, seconds: seconds);
    }
    return attempt;
  }

  /// Uma tentativa que venceu a etapa 0 e acabou na 1 do jeito [outcome].
  Future<int> stopped(AttemptOutcome? outcome) async {
    final attempt = await begin();
    await play(attempt, 0, seconds: 10);
    if (outcome != null) {
      await play(
        attempt,
        1,
        outcome: outcome,
        reason: outcome == AttemptOutcome.draw
            ? GameEndReason.stalemate
            : GameEndReason.checkmate,
        seconds: 15,
      );
    }
    now.advance(const Duration(minutes: 1));
    await speedruns.abandon(attempt, now());
    return attempt;
  }

  Future<void> open(int attempt) =>
      cubit.load(speedrunId: started[attempt]!, attemptId: attempt);

  Future<void> pump(
    WidgetTester tester,
    int attempt, {
    Size size = const Size(400, 3000),
    double scale = 1,
    Locale locale = const Locale('en'),
    ThemeMode mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await open(attempt);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: mode,
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: BlocProvider.value(
            value: cubit,
            child: const SpeedrunAttemptScreen(),
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

  TimeDisplay heroOf(WidgetTester tester) => tester.widget<TimeDisplay>(
    find.ancestor(
      of: find.byKey(SpeedrunKeys.total),
      matching: find.byType(TimeDisplay),
    ),
  );

  group('concluída', () {
    testWidgets('a primeira vez: herói "Seu recorde", sem barras, com o '
        'bônus ganho', (tester) async {
      final attempt = await finished(10);

      await pump(tester, attempt);

      final hero = heroOf(tester);
      expect(hero.type, TimeDisplayType.record);
      expect(hero.size, TimeDisplaySize.block);
      expect(hero.state, TimeDisplayState.highlight);
      expect(hero.value, '0:30.0');
      expect(find.text('Your record'), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.recordBars), findsNothing);
      expect(find.byKey(SpeedrunKeys.recordDifference), findsNothing);
      expect(find.byKey(SpeedrunKeys.ratingBonusEarned), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.ratingAlreadyEarned), findsNothing);
      expect(cubit.state.bonus, isNotNull);
      expect(find.byKey(SpeedrunKeys.retry), findsNothing);
    });

    testWidgets('recorde novo: Antes/Agora e a diferença com uma casa', (
      tester,
    ) async {
      await finished(10);
      now.advance(const Duration(minutes: 5));
      final attempt = await finished(8);

      await pump(tester, attempt);

      expect(find.byKey(SpeedrunKeys.newRecord), findsOneWidget);
      expect(heroOf(tester).value, '0:24.0');
      expect(find.text('Your record'), findsNothing);
      expect(find.text('New personal record'), findsOneWidget);
      expect(
        textOf(tester, SpeedrunKeys.recordDifference),
        '6.0 s faster than the previous record',
      );
      expect(find.byKey(SpeedrunKeys.recordBars), findsOneWidget);
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.ratingAlreadyEarned), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.ratingBonusEarned), findsNothing);
    });

    testWidgets('um recorde antigo já batido vira herói normal, "Total '
        'time"', (tester) async {
      final old = await finished(10);
      now.advance(const Duration(minutes: 5));
      await finished(8);

      await pump(tester, old);

      final hero = heroOf(tester);
      expect(hero.state, TimeDisplayState.normal);
      expect(hero.type, TimeDisplayType.stopwatch);
      expect(find.text('Total time'), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
    });

    testWidgets('em árabe as barras enchem da esquerda', (tester) async {
      await finished(10);
      now.advance(const Duration(minutes: 5));
      final attempt = await finished(8);

      await pump(tester, attempt, locale: const Locale('ar'));

      final bars = find.descendant(
        of: find.byKey(SpeedrunKeys.recordBars),
        matching: find.byType(FractionallySizedBox),
      );
      final full = tester.getRect(
        find.ancestor(of: bars.first, matching: find.byType(Container)).first,
      );
      expect(tester.getRect(bars.last).left, closeTo(full.left, 1));
    });

    testWidgets('mais lenta: Recorde/Esta e "Faltaram"', (tester) async {
      await finished(10);
      now.advance(const Duration(minutes: 5));
      final attempt = await finished(12);

      await pump(tester, attempt);

      expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
      expect(heroOf(tester).type, TimeDisplayType.stopwatch);
      expect(heroOf(tester).value, '0:36.0');
      expect(
        textOf(tester, SpeedrunKeys.recordDifference),
        '6.0 s short of your record',
      );
      expect(find.text('Record'), findsOneWidget);
      expect(find.text('This one'), findsOneWidget);
    });

    testWidgets('tempo igual ao recorde: sem frase de diferença', (
      tester,
    ) async {
      await finished(10);
      now.advance(const Duration(minutes: 5));
      final attempt = await finished(10);

      await pump(tester, attempt);

      expect(find.byKey(SpeedrunKeys.recordDifference), findsNothing);
      expect(find.byKey(SpeedrunKeys.recordBars), findsOneWidget);
      // O empate não é recorde: herói normal, "Tempo total".
      expect(heroOf(tester).type, isNot(TimeDisplayType.record));
      expect(find.byKey(SpeedrunKeys.newRecord), findsNothing);
      expect(find.text('Total time'), findsOneWidget);
    });

    testWidgets('bônus já pago em outro ritmo do grupo, sem comparação: o '
        'aviso sozinho, com data e pontos', (tester) async {
      await finished(10);
      now.advance(const Duration(days: 1));
      final attempt = await finished(
        10,
        const TimeControl(initial: Duration(minutes: 3)),
      );

      await pump(tester, attempt);

      expect(find.byKey(SpeedrunKeys.recordBars), findsNothing);
      expect(find.byKey(SpeedrunKeys.ratingBonusEarned), findsNothing);
      final notice = textOf(tester, SpeedrunKeys.ratingAlreadyEarned);
      expect(notice, contains('You already earned'));
      expect(notice, contains('+'));
      expect(notice, contains('October 5'));
    });

    testWidgets('nenhuma "derrota" na tela', (tester) async {
      final attempt = await stopped(AttemptOutcome.loss);

      await pump(tester, attempt);

      expect(
        find.textContaining(RegExp('defeat', caseSensitive: false)),
        findsNothing,
      );
      expect(
        find.textContaining(RegExp('losses', caseSensitive: false)),
        findsNothing,
      );
    });
  });

  group('não concluída', () {
    final cases = {
      AttemptOutcome.loss: (
        'Lost at stage 2 of 3',
        'lost here',
        SpeedrunKeys.lostTitle,
        'Time until losing',
      ),
      AttemptOutcome.draw: (
        'Drew at stage 2 of 3',
        'drew here',
        SpeedrunKeys.drawnTitle,
        'Time until drawing',
      ),
    };
    for (final MapEntry(key: outcome, value: (hero, note, key, _))
        in cases.entries) {
      testWidgets('${outcome.name}: título, "Contra o", tempo e nota da '
          'etapa', (tester) async {
        final attempt = await stopped(outcome);

        await pump(tester, attempt);

        expect(textOf(tester, key), hero);
        expect(find.byKey(SpeedrunKeys.abandonedHero), findsOneWidget);
        expect(textOf(tester, SpeedrunKeys.abandonedHero), contains('Against'));
        // 10 s + 15 s: a soma dos relógios.
        expect(textOf(tester, SpeedrunKeys.timeUntil), contains('0:25.0'));
        expect(textOf(tester, SpeedrunKeys.stageNote(1)), endsWith(note));
        expect(find.byKey(SpeedrunKeys.retry), findsOneWidget);
      });
    }

    testWidgets('desistiu: título, tempo e nota; nunca concluiu mostra o '
        'aviso com a oferta', (tester) async {
      final attempt = await stopped(null);

      await pump(tester, attempt);

      expect(textOf(tester, SpeedrunKeys.abandoned), 'Gave up at stage 2 of 3');
      expect(textOf(tester, SpeedrunKeys.timeUntil), contains('0:10.0'));
      expect(
        textOf(tester, SpeedrunKeys.stageNote(1)),
        endsWith('gave up here'),
      );
      expect(find.byKey(SpeedrunKeys.notFinishedNotice), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.recordCard), findsNothing);
      expect(find.byKey(SpeedrunKeys.retry), findsOneWidget);
    });

    testWidgets('já concluiu antes: o cartão do recorde no lugar do aviso', (
      tester,
    ) async {
      await finished(10);
      now.advance(const Duration(minutes: 5));
      final attempt = await stopped(AttemptOutcome.loss);

      await pump(tester, attempt);

      expect(find.byKey(SpeedrunKeys.recordCard), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.notFinishedNotice), findsNothing);
    });

    testWidgets('Tentar novamente começa uma tentativa nova do mesmo '
        'speedrun', (tester) async {
      final attempt = await stopped(AttemptOutcome.loss);
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await open(attempt);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => BlocProvider.value(
              value: cubit,
              child: const SpeedrunAttemptScreen(),
            ),
          ),
          GoRoute(path: '/:page', builder: (_, _) => const Text('partida')),
        ],
      );
      await tester.pumpWidget(
        TestApp(router: router, child: const SizedBox.shrink()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(SpeedrunKeys.retry));
      await tester.pumpAndSettle();

      final all = await speedruns.attempts(started[attempt]!);
      expect(all, hasLength(2));
      expect(all.last.id, isNot(attempt));
      expect(find.text('partida'), findsOneWidget);
    });
  });

  group('tamanhos, fonte 2,0, escuro e árabe', () {
    for (final size in [const Size(360, 740), const Size(412, 917)]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final locale in [const Locale('en'), const Locale('ar')]) {
          for (final state in ['recorde novo', 'perdeu']) {
            testWidgets('$state ${size.width.toInt()}×${size.height.toInt()} '
                '${mode.name} ${locale.languageCode}, fonte 2,0', (
              tester,
            ) async {
              if (locale.languageCode == 'ar') await Goldens.loadFonts();
              final int attempt;
              if (state == 'perdeu') {
                attempt = await stopped(AttemptOutcome.loss);
              } else {
                await finished(10);
                now.advance(const Duration(minutes: 5));
                attempt = await finished(8);
              }

              await pump(
                tester,
                attempt,
                size: size,
                scale: 2,
                mode: mode,
                locale: locale,
              );

              expect(tester.takeException(), isNull);
              if (state == 'recorde novo') {
                final hero = tester.getRect(find.byKey(SpeedrunKeys.newRecord));
                expect(hero.left, greaterThanOrEqualTo(0));
                expect(hero.right, lessThanOrEqualTo(size.width));
                // Os números seguem da esquerda para a direita.
                expect(
                  tester
                      .widget<Text>(find.byKey(SpeedrunKeys.total))
                      .textDirection,
                  TextDirection.ltr,
                );
              } else {
                expect(
                  tester.getRect(find.byKey(SpeedrunKeys.retry)).height,
                  greaterThanOrEqualTo(48),
                );
              }
            });
          }
        }
      }
    }
  });
}
