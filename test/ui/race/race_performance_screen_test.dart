import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/race/view_models/race_performance_cubit.dart';
import 'package:lucena/ui/race/widgets/race_performance_screen.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeNow now;
  late FakeRaceRepository repository;
  final opened = <String>[];

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 23, 10));
    repository = FakeRaceRepository(now: now);
    opened.clear();
  });

  /// Grava uma Corrida com ([acertos], [erros]) em cada tipo de final.
  Future<void> race(Map<String, (int, int)> answers) async {
    var run = RaceRun(startedAt: now());
    for (final MapEntry(key: subcategory, value: (right, wrong))
        in answers.entries) {
      for (var i = 0; i < right + wrong; i++) {
        run = run.withAnswer(
          RaceAnswer(
            problemId: '$subcategory.$i',
            level: 400,
            move: 'a1a2',
            correct: i < right,
            subcategory: subcategory,
          ),
        );
      }
    }
    await repository.finish(run, RaceEnd.time);
  }

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    GoRoute stub(String path) => GoRoute(
      path: path,
      builder: (context, state) {
        opened.add(state.uri.toString());
        return const Scaffold();
      },
    );
    final router = GoRouter(
      initialLocation: Routes.racePerformance,
      routes: [
        GoRoute(
          path: Routes.racePerformance,
          builder: (context, state) => BlocProvider(
            create: (_) => RacePerformanceCubit(repository)..load(),
            child: const RacePerformanceScreen(),
          ),
        ),
        stub('/endgames/:id'),
        stub('/catalog/:category'),
      ],
    );
    await tester.pumpWidget(
      TestApp(router: router, child: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> history() async {
    await race({'queen': (5, 0), 'rook': (1, 4)});
    await race({'pawnVsKing': (2, 3)});
    await race({'knightBishopVsKing': (3, 2)});
  }

  for (final size in const [Size(360, 740), Size(412, 917)]) {
    testWidgets('${size.width.toInt()}: primeiro o que domina, depois onde '
        'melhorar do pior ao melhor, sem vermelho', (tester) async {
      await history();
      await pump(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Your performance'), findsOneWidget);
      expect(find.byKey(RaceKeys.performanceChip('queen')), findsOneWidget);
      final rows = [
        for (final id in ['rook', 'pawnVsKing', 'knightBishopVsKing'])
          tester.getTopLeft(find.byKey(RaceKeys.performanceRow(id))).dy,
      ];
      expect(rows, orderedEquals([...rows]..sort()));
      expect(find.text('1 of 5 correct'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(RaceKeys.performanceMastered)).dy,
        lessThan(
          tester.getTopLeft(find.byKey(RaceKeys.performanceToImprove)).dy,
        ),
      );
    });
  }

  testWidgets('próximos passos: só as aulas liberadas e o treino do mais '
      'fraco no catálogo', (tester) async {
    await history();
    await pump(tester, const Size(412, 917));
    // O mate de torre é da Escola, que está escondida: sem aula.
    expect(
      find.byKey(NextStepsKeys.option('lesson.technique.rookMate')),
      findsNothing,
    );
    expect(
      find.byKey(NextStepsKeys.option('lesson.pawns.keySquares')),
      findsOneWidget,
    );
    expect(
      find.byKey(NextStepsKeys.option('lesson.mates.bishopKnight.deletang')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(NextStepsKeys.option('practice')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Practice Rook mate'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Based on your Race history.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(NextStepsKeys.option('practice')));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.catalogCategory('basic'));
  });

  testWidgets('a aula de um final abre a aula', (tester) async {
    await history();
    await pump(tester, const Size(412, 917));
    final option = find.byKey(NextStepsKeys.option('lesson.pawns.keySquares'));
    await tester.scrollUntilVisible(
      option,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(opened.last, Routes.endgameLesson('pawns.keySquares'));
  });

  testWidgets('antes de 3 Corridas: quantas faltam', (tester) async {
    await race({'queen': (5, 0)});
    await pump(tester, const Size(412, 917));
    expect(find.byKey(RaceKeys.diagnosisProgress), findsOneWidget);
    expect(find.byKey(NextStepsKeys.block), findsNothing);
  });
}
