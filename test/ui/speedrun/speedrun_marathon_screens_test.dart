import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/history/widgets/history_labels.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';
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

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(360, 740),
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
        find.descendant(of: find.byKey(key), matching: find.byType(Text)),
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
      expect(text(tester, SpeedrunKeys.ratingBonusOffer), contains(HistoryLabels.ltr('+110')));
      final card = tester.getRect(find.byKey(SpeedrunKeys.ratingBonusOffer));
      final firstStage = tester.getRect(find.byKey(SpeedrunKeys.stageCard(0)));
      final badge = tester.getRect(find.byKey(SpeedrunKeys.paceBadge));
      expect(card.top, greaterThan(badge.bottom));
      expect(card.bottom, lessThan(firstStage.top));
      // 16 de cada lado.
      expect(card.left, closeTo(16, 1));
      expect(card.right, closeTo(360 - 16, 1));
    });

    testWidgets('clássico: a oferta é a cheia', (tester) async {
      await cubit.load(speedrunId: endingId);
      await pump(tester, const SpeedrunScreen());

      expect(text(tester, SpeedrunKeys.ratingBonusOffer), contains(HistoryLabels.ltr('+70')));
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
        for (final mode in ThemeMode.values.take(2)) {
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
}
