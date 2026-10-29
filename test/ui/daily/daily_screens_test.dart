import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/crowd_stat.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:lucena/domain/models/maia_level.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/daily_keys.dart';
import 'package:lucena/ui/daily/view_models/daily_result_cubit.dart';
import 'package:lucena/ui/daily/view_models/daily_start_cubit.dart';
import 'package:lucena/ui/daily/widgets/daily_result_screen.dart';
import 'package:lucena/ui/daily/widgets/daily_share_screen.dart';
import 'package:lucena/ui/streak/view_models/streak_cubit.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_crowd_repository.dart';
import '../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_share_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  final now = FakeNow(DateTime(2026, 10, 22, 9));
  final day = DateTime(2026, 10, 22);
  final won = DailyRecord(
    date: day,
    positionId: samplePositions.first.id,
    outcome: DailyOutcome.won,
    fulfilled: true,
    squares: const [DailySquare.right, DailySquare.bad, DailySquare.right],
  );

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
  }

  Future<void> pumpDaily(
    WidgetTester tester,
    Widget screen, {
    DailyRecord? record,
    FakeShareRepository? share,
    String date = '2026-10-22',
    CrowdStat? crowd,
  }) async {
    phone(tester);
    final daily = FakeDailyFinalRepository(
      records: {DateTime.parse(date): ?record},
    );
    final result = DailyResultCubit(
      date: date,
      daily: daily,
      crowd: FakeCrowdRepository(days: {date: ?crowd}),
      now: now,
    );
    final streak = StreakCubit(
      activity: FakeActivityRepository(
        days: {
          for (final d in [20, 21, 22]) DateTime(2026, 10, d, 18),
        },
      ),
      now: now,
    );
    addTearDown(result.close);
    addTearDown(streak.close);
    await result.load();
    await streak.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        shareRepository: share,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: result),
            BlocProvider.value(value: streak),
          ],
          child: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'resultado: título, quadradinhos, sequência e quantos acertaram',
    (tester) async {
      await pumpDaily(tester, const DailyResultScreen(), record: won);

      expect(find.text('Você ganhou'), findsOneWidget);
      expect(find.text('22 de outubro · 3 lances'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(DailyKeys.square(i)), findsOneWidget);
      }
      expect(find.byKey(DailyKeys.streakCard), findsOneWidget);
      expect(find.text('3 dias seguidos'), findsOneWidget);
      expect(find.byKey(DailyKeys.crowdCard), findsOneWidget);
      expect(find.byKey(DailyKeys.share), findsOneWidget);
      expect(find.byKey(DailyKeys.continueButton), findsOneWidget);
    },
  );

  testWidgets('resultado de hoje: amanhã, mesmo com o número na nuvem', (
    tester,
  ) async {
    await pumpDaily(
      tester,
      const DailyResultScreen(),
      record: won,
      crowd: const CrowdStat(percent: 63, total: 4812),
    );

    expect(find.text('Final do dia'), findsOneWidget);
    expect(find.text('Quantos acertaram? Amanhã.'), findsOneWidget);
    expect(find.byKey(DailyKeys.crowdPercent), findsNothing);
  });

  group('resultado de ontem', () {
    final yesterday = DailyRecord(
      date: DateTime(2026, 10, 21),
      positionId: samplePositions.first.id,
      outcome: DailyOutcome.won,
      fulfilled: true,
      squares: const [DailySquare.right],
    );

    testWidgets('o número, a barra e "Você está entre eles."', (tester) async {
      await pumpDaily(
        tester,
        const DailyResultScreen(),
        record: yesterday,
        date: '2026-10-21',
        crowd: const CrowdStat(percent: 63, total: 4812),
      );

      expect(find.text('Final de ontem'), findsOneWidget);
      expect(find.text('Você ganhou ontem'), findsOneWidget);
      expect(find.text('63% acertaram'), findsOneWidget);
      expect(find.text('4.812 jogaram'), findsOneWidget);
      expect(find.byKey(DailyKeys.crowdBar), findsOneWidget);
      expect(find.byKey(DailyKeys.crowdYouAre), findsOneWidget);
    });

    testWidgets('perdeu: sem "Você está entre eles."', (tester) async {
      await pumpDaily(
        tester,
        const DailyResultScreen(),
        record: DailyRecord(
          date: yesterday.date,
          positionId: yesterday.positionId,
          outcome: DailyOutcome.lost,
          fulfilled: false,
          squares: const [DailySquare.bad],
        ),
        date: '2026-10-21',
        crowd: const CrowdStat(percent: 63, total: 4812),
      );

      expect(find.text('63% acertaram'), findsOneWidget);
      expect(find.byKey(DailyKeys.crowdYouAre), findsNothing);
    });

    testWidgets('menos de 30 pessoas: sem número', (tester) async {
      await pumpDaily(
        tester,
        const DailyResultScreen(),
        record: yesterday,
        date: '2026-10-21',
        crowd: const CrowdStat(percent: 50, total: 29),
      );

      expect(find.text('Poucas pessoas jogaram ontem'), findsOneWidget);
      expect(find.byKey(DailyKeys.crowdPercent), findsNothing);
    });

    testWidgets('o número não saiu: sem o cartão', (tester) async {
      await pumpDaily(
        tester,
        const DailyResultScreen(),
        record: yesterday,
        date: '2026-10-21',
      );

      expect(find.byKey(DailyKeys.crowdCard), findsNothing);
    });
  });

  testWidgets('resultado sem tentativa: sem o cartão e sem compartilhar', (
    tester,
  ) async {
    await pumpDaily(tester, const DailyResultScreen());

    expect(find.byKey(DailyKeys.resultTitle), findsNothing);
    expect(find.byKey(DailyKeys.share), findsNothing);
    expect(find.byKey(DailyKeys.continueButton), findsOneWidget);
  });

  testWidgets('compartilhar: a imagem e o texto com o link do dia', (
    tester,
  ) async {
    final share = FakeShareRepository();
    await pumpDaily(
      tester,
      const DailyShareScreen(),
      record: won,
      share: share,
    );

    expect(find.byKey(DailyKeys.shareImage), findsOneWidget);
    expect(find.text('Ganhei em 3 lances'), findsOneWidget);
    expect(
      find.text(
        'Final do dia do Lucena, 22 de outubro: ganhei em 3 lances e a '
        'sequência está em 3 dias. Você acha o lance? '
        'https://${AppLinks.host}/${AppLinks.dailySegment}',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DailyKeys.shareButton));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    final sent = share.shared.single;
    expect(sent.png.sublist(0, 4), [0x89, 0x50, 0x4e, 0x47]);
    expect(sent.name, 'lucena-final-do-dia.png');
    expect(sent.text, contains('ganhei em 3 lances'));
  });

  test('início: a partida de hoje no nível da pessoa', () async {
    final rating = FakeRatingRepository();
    final cubit = DailyStartCubit(
      daily: FakeDailyFinalRepository(),
      rating: rating,
      now: now,
    );
    addTearDown(cubit.close);
    await cubit.load();

    final level = MaiaLevels.nearest((await rating.current()).rounded);
    expect(
      cubit.state,
      isA<DailyStartReady>().having(
        (s) => s.location,
        'location',
        Routes.dailyGame(
          DailyFinal(date: day, position: samplePositions.first),
          level: level,
        ),
      ),
    );
  });

  test('início sem final hoje: a home', () async {
    final cubit = DailyStartCubit(
      daily: FakeDailyFinalRepository(none: true),
      rating: FakeRatingRepository(),
      now: now,
    );
    addTearDown(cubit.close);
    await cubit.load();

    expect(
      cubit.state,
      isA<DailyStartReady>().having((s) => s.location, 'location', Routes.home),
    );
  });
}
