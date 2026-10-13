import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/clock_format.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/history/widgets/history_labels.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_attempt_screen.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';

/// A Maratona e o clássico do mesmo final: o detalhe com a oferta de rating
/// e, no fim da tentativa, o resumo (T67f).
void main() {
  final marathonId = SpeedrunPaces.idFor(sampleMarathon.id, sampleSpeedrunTime);
  final endingId = SpeedrunPaces.idFor(
    sampleSpeedruns[1].id,
    sampleSpeedrunTime,
  );
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late FakeRatingRepository rating;
  late SpeedrunCubit cubit;
  final started = <int, String>{};

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    rating = FakeRatingRepository(now: now)..speedrunOf = (id) => started[id]!;
    cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(
        speedruns: [...sampleSpeedruns, sampleMarathon],
      ),
      speedruns: speedruns,
      games: FakeOngoingGameRepository(),
      now: now,
      characters: FakeCharacterRepository(),
      rating: rating,
    );
  });
  tearDown(() => cubit.close());

  Future<int> complete(String speedrunId, int stages) async {
    final attempt = await speedruns.start(speedrunId, now());
    started[attempt.id] = speedrunId;
    for (var stage = 0; stage < stages; stage++) {
      await progress.addAttempt(
        Attempt(
          positionId: 'basic.queen.0001',
          playedAt: now(),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          userClock: const Duration(seconds: 10),
          speedrunAttemptId: attempt.id,
          speedrunStage: stage,
        ),
      );
    }
    return attempt.id;
  }

  // Alta por padrão: o ListView só monta o que cabe, e os testes de
  // conteúdo conferem as etapas todas.
  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(400, 3000),
    double scale = 1,
    Locale locale = const Locale('en'),
    ThemeMode mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: mode,
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: BlocProvider.value(value: cubit, child: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, Key key) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(Text),
          matchRoot: true,
        ),
      )
      .map((t) => t.data)
      .join(' | ');

  group('detalhe com a oferta', () {
    testWidgets('Maratona: oferta ×1,5, entre o cabeçalho e as etapas', (
      tester,
    ) async {
      await cubit.load(speedrunId: marathonId);
      await pump(tester, const SpeedrunScreen());

      expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsOneWidget);
      expect(
        text(tester, SpeedrunKeys.ratingBonusOffer),
        contains(HistoryLabels.ltr('+110')),
      );
      final card = tester.getRect(find.byKey(SpeedrunKeys.ratingBonusOffer));
      final firstStage = tester.getRect(find.byKey(SpeedrunKeys.stageCard(0)));
      final badge = tester.getRect(find.byKey(SpeedrunKeys.paceBadge));
      expect(card.top, greaterThan(badge.bottom));
      expect(card.bottom, lessThan(firstStage.top));
      // 16 de cada lado.
      expect(card.left, closeTo(16, 1));
      expect(card.right, closeTo(400 - 16, 1));
    });

    testWidgets('clássico: a oferta é a cheia', (tester) async {
      await cubit.load(speedrunId: endingId);
      await pump(tester, const SpeedrunScreen());

      expect(
        text(tester, SpeedrunKeys.ratingBonusOffer),
        contains(HistoryLabels.ltr('+70')),
      );
    });

    testWidgets('já pago no grupo: o cartão some', (tester) async {
      final id = await complete(marathonId, sampleMarathon.stages.length);
      await cubit.load(speedrunId: marathonId, attemptId: id);
      await cubit.load(speedrunId: marathonId);
      await pump(tester, const SpeedrunScreen());

      expect(find.byKey(SpeedrunKeys.ratingBonusOffer), findsNothing);
    });

    for (final size in [const Size(360, 740), const Size(412, 917)]) {
      for (final scale in [1.0, 2.0]) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          for (final locale in [const Locale('en'), const Locale('ar')]) {
            testWidgets('${size.width.toInt()}x${size.height.toInt()} '
                'fonte $scale ${mode.name} ${locale.languageCode}: '
                'sem overflow, cartão inteiro', (tester) async {
              await cubit.load(speedrunId: marathonId);
              await pump(
                tester,
                const SpeedrunScreen(),
                size: size,
                scale: scale,
                mode: mode,
                locale: locale,
              );

              expect(tester.takeException(), isNull);
              final card = tester.getRect(
                find.byKey(SpeedrunKeys.ratingBonusOffer),
              );
              expect(card.left, greaterThanOrEqualTo(0));
              expect(card.right, lessThanOrEqualTo(size.width));
              // O botão de começar continua à vista.
              expect(
                tester.getRect(find.byKey(SpeedrunKeys.start)).height,
                greaterThanOrEqualTo(48),
              );
            });
          }
        }
      }
    }
  });

  group('fim da tentativa', () {
    // Joga a etapa [stage] da tentativa [attempt].
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

    // Uma tentativa que venceu a etapa 0 e acabou na 1 do jeito [end].
    Future<int> stopped(SpeedrunRunEnd end) async {
      final attempt = await speedruns.start(marathonId, now());
      started[attempt.id] = marathonId;
      await play(attempt.id, 0, seconds: 30);
      switch (end) {
        case SpeedrunRunEnd.lost:
          await play(
            attempt.id,
            1,
            outcome: AttemptOutcome.loss,
            reason: GameEndReason.checkmate,
            seconds: 41,
          );
        case SpeedrunRunEnd.drawn:
          await play(
            attempt.id,
            1,
            outcome: AttemptOutcome.draw,
            reason: GameEndReason.stalemate,
            seconds: 41,
          );
        case SpeedrunRunEnd.timeout:
          await play(
            attempt.id,
            1,
            outcome: AttemptOutcome.loss,
            reason: GameEndReason.timeout,
            seconds: 150,
          );
        default:
      }
      now.advance(const Duration(minutes: 1));
      await speedruns.abandon(attempt.id, now());
      return attempt.id;
    }

    Future<void> open(int attempt) =>
        cubit.load(speedrunId: marathonId, attemptId: attempt);

    final failures = {
      SpeedrunRunEnd.lost: ('Lost at stage 2 of', 'lost here'),
      SpeedrunRunEnd.drawn: ('Drew at stage 2 of', 'drew here'),
      SpeedrunRunEnd.timeout: ('Out of time at stage 2 of', 'time ran out'),
      SpeedrunRunEnd.abandoned: ('Gave up at stage 2 of', 'gave up here'),
    };

    for (final MapEntry(key: end, value: (hero, note)) in failures.entries) {
      testWidgets('${end.name}: herói, nota na etapa, aviso e "Try again"', (
        tester,
      ) async {
        await open(await stopped(end));
        await pump(tester, const SpeedrunAttemptScreen());

        expect(tester.takeException(), isNull);
        expect(text(tester, SpeedrunKeys.marathonEndHero), startsWith(hero));
        expect(text(tester, SpeedrunKeys.stageNote(1)), contains(note));
        expect(find.byKey(SpeedrunKeys.stageNote(0)).evaluate().length, 1);
        expect(text(tester, SpeedrunKeys.stageNote(0)), isNot(contains(note)));
        expect(find.byKey(SpeedrunKeys.marathonNotFinished), findsOneWidget);
        expect(find.byKey(SpeedrunKeys.retry), findsOneWidget);
        expect(find.byKey(SpeedrunKeys.ratingBonusEarned), findsNothing);
        // O "sem tempo" não repete o banco (zero); os outros dizem quanto
        // sobrou.
        expect(
          find.byKey(SpeedrunKeys.marathonEndLeft),
          end == SpeedrunRunEnd.timeout ? findsNothing : findsOneWidget,
        );
      });
    }

    testWidgets('perdeu: 1:49.0 sobrou, contra o adversário da etapa e '
        '+110 ao concluir', (tester) async {
      await open(await stopped(SpeedrunRunEnd.lost));
      await pump(tester, const SpeedrunAttemptScreen());

      // 3:00 - 0:30 - 0:41.
      expect(text(tester, SpeedrunKeys.marathonEndLeft), contains('1:49.0'));
      expect(
        find.descendant(
          of: find.byKey(SpeedrunKeys.marathonNotFinished),
          matching: find.textContaining(
            HistoryLabels.ltr('+110 rating'),
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        text(tester, SpeedrunKeys.marathonNotFinished),
        contains('stage 2 of'),
      );
    });

    testWidgets('sem oferta (já pago no grupo): some a linha do +N', (
      tester,
    ) async {
      final done = await complete(marathonId, sampleMarathon.stages.length);
      await open(done);
      await open(await stopped(SpeedrunRunEnd.lost));
      await pump(tester, const SpeedrunAttemptScreen());

      // Já concluiu: o recorde no lugar do aviso, sem oferta.
      expect(find.byKey(SpeedrunKeys.marathonNotFinished), findsNothing);
      expect(find.byKey(SpeedrunKeys.marathonRecord), findsOneWidget);
      expect(find.textContaining('rating on finishing'), findsNothing);
    });

    testWidgets('maratona já concluída: cartão do recorde, tempo que sobrou', (
      tester,
    ) async {
      final done = await complete(marathonId, sampleMarathon.stages.length);
      await open(done);
      await open(await stopped(SpeedrunRunEnd.drawn));
      await pump(tester, const SpeedrunAttemptScreen());

      expect(find.text('Most time left'), findsOneWidget);
      final total = sampleMarathon.stages.length;
      expect(
        text(tester, SpeedrunKeys.marathonRecord),
        // 3:00 menos 10 s por etapa.
        contains(RunTimeFormat.clock(Duration(seconds: 180 - total * 10))),
      );
    });

    testWidgets('sem oferta e sem recorde (só da Jornada não chega aqui): '
        'sem a linha do +N', (tester) async {
      final other = await stopped(SpeedrunRunEnd.lost);
      await open(other);
      // O rating já subiu em outra conclusão do grupo.
      final second = await complete(
        SpeedrunPaces.idFor(sampleMarathon.id, sampleSpeedrunTime),
        sampleMarathon.stages.length,
      );
      await open(second);
      await open(other);
      await pump(tester, const SpeedrunAttemptScreen());

      expect(find.byKey(SpeedrunKeys.marathonNotFinished), findsNothing);
    });

    testWidgets('concluída com bônus: tempo em destaque e "antes → depois"', (
      tester,
    ) async {
      final done = await complete(marathonId, sampleMarathon.stages.length);
      await open(done);
      await pump(tester, const SpeedrunAttemptScreen());

      final total = sampleMarathon.stages.length;
      expect(
        text(tester, SpeedrunKeys.total),
        contains(RunTimeFormat.clock(Duration(seconds: 180 - total * 10))),
      );
      expect(
        text(tester, SpeedrunKeys.ratingBonusEarned),
        contains(HistoryLabels.ltr('1150 → 1260')),
      );
      expect(find.byKey(SpeedrunKeys.retry), findsNothing);
      expect(find.byKey(SpeedrunKeys.marathonEndHero), findsNothing);
    });

    testWidgets('concluída sem bônus (já pago): sem o cartão', (tester) async {
      await open(await complete(marathonId, sampleMarathon.stages.length));
      now.advance(const Duration(days: 1));
      final again = await complete(marathonId, sampleMarathon.stages.length);
      await open(again);
      await pump(tester, const SpeedrunAttemptScreen());

      expect(find.byKey(SpeedrunKeys.total), findsOneWidget);
      expect(find.byKey(SpeedrunKeys.ratingBonusEarned), findsNothing);
    });

    testWidgets('Tentar novamente começa outra tentativa, da etapa 1', (
      tester,
    ) async {
      final attempt = await stopped(SpeedrunRunEnd.lost);
      await open(attempt);
      tester.view.physicalSize = const Size(720, 1480);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
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

      final all = await speedruns.attempts(marathonId);
      expect(all, hasLength(2));
      expect(all.last.id, isNot(attempt));
      expect(find.text('partida'), findsOneWidget);
    });

    final matrix = {
      'perdeu': SpeedrunRunEnd.lost,
      'empatou': SpeedrunRunEnd.drawn,
      'sem tempo': SpeedrunRunEnd.timeout,
      'desistiu': SpeedrunRunEnd.abandoned,
    };
    for (final MapEntry(key: name, value: end) in matrix.entries) {
      for (final size in [const Size(360, 740), const Size(412, 917)]) {
        for (final scale in [1.0, 2.0]) {
          for (final (mode, locale) in [
            (ThemeMode.light, const Locale('en')),
            (ThemeMode.dark, const Locale('en')),
            (ThemeMode.light, const Locale('ar')),
          ]) {
            testWidgets('$name ${size.width.toInt()}x${size.height.toInt()} '
                'fonte $scale ${mode.name} ${locale.languageCode}: sem '
                'overflow, cartões e rodapé à vista', (tester) async {
              await open(await stopped(end));
              await pump(
                tester,
                const SpeedrunAttemptScreen(),
                size: size,
                scale: scale,
                mode: mode,
                locale: locale,
              );

              expect(tester.takeException(), isNull);
              for (final key in [
                SpeedrunKeys.marathonEndHero,
                SpeedrunKeys.marathonNotFinished,
              ]) {
                final rect = tester.getRect(find.byKey(key));
                expect(rect.left, greaterThanOrEqualTo(0), reason: '$key');
                expect(rect.right, lessThanOrEqualTo(size.width));
              }
              // A nota "· … aqui" da etapa que parou não encosta no nome da
              // seguinte, nem em fonte 2,0 (a linha cresce com o texto).
              await tester.scrollUntilVisible(
                find.byKey(SpeedrunKeys.stage(2)),
                100,
              );
              final note = tester.getRect(
                find.byKey(SpeedrunKeys.stageNote(1)),
              );
              expect(note.left, greaterThanOrEqualTo(0));
              expect(note.right, lessThanOrEqualTo(size.width));
              final next = tester.getRect(find.byKey(SpeedrunKeys.stage(2)));
              expect(next.top, greaterThanOrEqualTo(note.bottom));
              final title = tester.widget<AppBar>(find.byType(AppBar));
              expect(title.centerTitle, isTrue);
              final retry = tester.getRect(find.byKey(SpeedrunKeys.retry));
              expect(retry.height, greaterThanOrEqualTo(48));
              expect(retry.bottom, lessThanOrEqualTo(size.height));
            });
          }
        }
      }
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('concluída 360 fonte $scale árabe: sem overflow, "+N" e '
          '"antes → depois" LTR', (tester) async {
        final done = await complete(marathonId, sampleMarathon.stages.length);
        await open(done);
        await pump(
          tester,
          const SpeedrunAttemptScreen(),
          size: const Size(360, 3000),
          scale: scale,
          locale: const Locale('ar'),
        );

        expect(tester.takeException(), isNull);
        final card = text(tester, SpeedrunKeys.ratingBonusEarned);
        expect(card, contains(HistoryLabels.ltr('+110')));
        expect(card, contains(HistoryLabels.ltr('1150 → 1260')));
      });
    }
  });
}
