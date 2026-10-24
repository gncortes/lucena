import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/lesson_finished_keys.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/core/keys/survey_keys.dart';
import 'package:lucena/ui/lesson_finished/view_models/lesson_finished_cubit.dart';
import 'package:lucena/ui/lesson_finished/widgets/lesson_finished_screen.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_race_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_survey_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSurveyRepository surveys;
  final opened = <String>[];

  setUp(() {
    surveys = FakeSurveyRepository();
    opened.clear();
  });

  Future<void> pump(
    WidgetTester tester,
    SurveyKind kind,
    String id, {
    String? next,
    List<RaceProblem> problems = raceTestProblems,
  }) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = LessonFinishedCubit(
      kind: kind,
      lessonId: id,
      nextId: next,
      school: FakeLessonRepository(),
      endgames: FakeEndgameLessonRepository(),
      race: FakeRaceRepository(
        now: FakeNow(DateTime.utc(2026, 1, 1)),
        problems: problems,
      ),
    );
    addTearDown(cubit.close);
    await cubit.load('en');
    GoRoute stub(String path) => GoRoute(
      path: path,
      builder: (context, state) {
        opened.add(state.uri.toString());
        return const Scaffold();
      },
    );
    final router = GoRouter(
      initialLocation: '/finished',
      routes: [
        GoRoute(
          path: '/finished',
          builder: (context, _) => BlocProvider.value(
            value: cubit,
            child: LessonFinishedScreen(kind: kind),
          ),
        ),
        stub('/survey/:kind'),
        stub(Routes.school),
        stub(Routes.endgames),
        stub('/endgames/:id/roteiro'),
        stub(Routes.race),
        stub('/setup'),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        surveyRepository: surveys,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('finais: título, convite acima dos botões e a próxima aula', (
    tester,
  ) async {
    await pump(
      tester,
      SurveyKind.endgames,
      'rook.lucena',
      next: 'rook.philidor',
    );
    expect(find.text('Lucena: done!'), findsNothing);
    expect(find.textContaining(': done!'), findsOneWidget);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsOneWidget);
    expect(find.textContaining('Next: '), findsOneWidget);
    expect(find.text('Back to lessons'), findsOneWidget);
    final invite = tester.getBottomLeft(
      find.byKey(SurveyKeys.invite(SurveyKind.endgames)),
    );
    final next = tester.getTopLeft(find.byKey(LessonFinishedKeys.next));
    expect(invite.dy, lessThan(next.dy));
    await tester.ensureVisible(find.byKey(LessonFinishedKeys.back));
    await tester.tap(find.byKey(LessonFinishedKeys.back));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.endgames);
  });

  testWidgets('sem próxima aula só há o botão de voltar', (tester) async {
    await pump(tester, SurveyKind.endgames, 'rook.philidor');
    expect(find.byKey(LessonFinishedKeys.next), findsNothing);
    expect(find.byKey(LessonFinishedKeys.back), findsOneWidget);
  });

  testWidgets('Escola: o convite abre o questionário da Escola', (
    tester,
  ) async {
    await pump(tester, SurveyKind.school, 'pieces.rook');
    expect(find.byKey(SurveyKeys.invite(SurveyKind.school)), findsOneWidget);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsNothing);
    expect(find.text('Back to school'), findsOneWidget);
    await tester.tap(find.byKey(SurveyKeys.inviteAction(SurveyKind.school)));
    await tester.pumpAndSettle();
    expect(opened.last, '/survey/school?from=lesson');
  });

  testWidgets('com a resposta enviada o convite não aparece', (tester) async {
    await surveys.saveResponse(
      SurveyKind.endgames,
      const SurveyAnswers(rating: 4),
    );
    await pump(tester, SurveyKind.endgames, 'rook.lucena');
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsNothing);
  });

  testWidgets('finais: "Próximos passos" com a Corrida e o treino do final', (
    tester,
  ) async {
    const lucena = RaceProblem(
      id: 'race.1500.01',
      fen: '2K5/1P1k4/8/8/8/8/r7/2R5 w - - 0 1',
      tree: RaceNode(distance: 1, moves: {'c1d1': RaceBranch()}),
      category: 'rookPawn',
      subcategory: 'rookPawnVsRook',
      level: 1500,
    );
    await pump(
      tester,
      SurveyKind.endgames,
      'rook.lucena',
      problems: [...raceTestProblems, lucena],
    );
    expect(find.byKey(NextStepsKeys.block), findsOneWidget);
    expect(find.byKey(NextStepsKeys.resultsInfo), findsOneWidget);
    expect(find.text('Next steps'), findsOneWidget);
    // Sem selo nesta tela.
    expect(find.text('Recommended'), findsNothing);
    expect(find.text('Rook and pawn against rook Race'), findsOneWidget);
    expect(find.text('Practice Rook and pawn against rook'), findsOneWidget);
    // O bloco vem antes do convite e dos botões.
    expect(
      tester.getTopLeft(find.byKey(NextStepsKeys.block)).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(SurveyKeys.invite(SurveyKind.endgames)))
            .dy,
      ),
    );
    await tester.tap(find.byKey(NextStepsKeys.option('raceOnly')));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.raceOnly(subcategory: 'rookPawnVsRook'));
  });

  testWidgets('finais sem o tipo na Corrida: só o treino e o teste', (
    tester,
  ) async {
    await pump(tester, SurveyKind.endgames, 'rook.lucena');
    expect(find.byKey(NextStepsKeys.option('raceOnly')), findsNothing);
    expect(find.byKey(NextStepsKeys.option('train')), findsOneWidget);
    expect(find.text('Practice this endgame'), findsOneWidget);
  });

  testWidgets('Escola: sem os "Próximos passos"', (tester) async {
    await pump(tester, SurveyKind.school, 'pieces.rook');
    expect(find.byKey(NextStepsKeys.block), findsNothing);
  });
}
