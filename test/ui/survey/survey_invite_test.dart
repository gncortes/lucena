import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/endgames/visible_endgame_lesson_repository.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/survey_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';
import 'package:lucena/ui/survey/widgets/survey_invite_card.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_survey_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSurveyRepository surveys;

  setUp(() => surveys = FakeSurveyRepository());

  Future<void> pumpCard(
    WidgetTester tester,
    SurveyKind kind, {
    SurveyInviteSource source = SurveyInviteSource.pilaresLesson,
  }) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: surveys,
        child: Scaffold(
          body: SurveyInviteCard(key: UniqueKey(), kind: kind, source: source),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('o convite aparece sem resposta e some com ela, por tipo', (
    tester,
  ) async {
    await pumpCard(tester, SurveyKind.pilares);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.pilares)), findsOneWidget);
    // H-OPI-01: os textos do canvas no fim de lição do Pilares.
    expect(find.text('O que você achou das lições?'), findsOneWidget);
    expect(
      find.text(
        'Leva 1 minuto e ajuda a melhorar as próximas lições do Pilares.',
      ),
      findsOneWidget,
    );
    expect(find.text('Responder'), findsOneWidget);

    await surveys.saveResponse(
      SurveyKind.school,
      const SurveyAnswers(rating: 4),
    );
    await pumpCard(tester, SurveyKind.pilares);
    // Responder a Escola não esconde o do Pilares.
    expect(find.byKey(SurveyKeys.invite(SurveyKind.pilares)), findsOneWidget);

    await surveys.saveResponse(
      SurveyKind.pilares,
      const SurveyAnswers(rating: 4),
    );
    await pumpCard(tester, SurveyKind.pilares);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.pilares)), findsNothing);
  });

  testWidgets('fechar sem enviar mantém o convite; enviar o esconde', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => const Scaffold(
            body: SurveyInviteCard(
              kind: SurveyKind.pilares,
              source: SurveyInviteSource.pilaresLesson,
            ),
          ),
        ),
        GoRoute(
          path: '/survey/:kind',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('fechar'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: surveys,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SurveyKeys.inviteAction(SurveyKind.pilares)));
    await tester.pumpAndSettle();
    expect(find.text('fechar'), findsOneWidget);
    await tester.tap(find.text('fechar'));
    await tester.pumpAndSettle();
    expect(find.byKey(SurveyKeys.invite(SurveyKind.pilares)), findsOneWidget);

    await tester.tap(find.byKey(SurveyKeys.inviteAction(SurveyKind.pilares)));
    await tester.pumpAndSettle();
    await surveys.saveResponse(
      SurveyKind.pilares,
      const SurveyAnswers(rating: 5),
    );
    await tester.tap(find.text('fechar'));
    await tester.pumpAndSettle();
    expect(find.byKey(SurveyKeys.invite(SurveyKind.pilares)), findsNothing);
    expect(Routes.survey(SurveyKind.pilares), '/survey/pilares');
    expect(
      Routes.survey(SurveyKind.pilares, origin: 'diploma_pilares'),
      '/survey/pilares?origem=diploma_pilares',
    );
  });

  testWidgets('fim de lição da Escola: o texto da Escola (H-OPI-06)', (
    tester,
  ) async {
    await pumpCard(
      tester,
      SurveyKind.school,
      source: SurveyInviteSource.schoolLesson,
    );
    expect(find.byKey(SurveyKeys.invite(SurveyKind.school)), findsOneWidget);
    expect(
      find.text(
        'Você terminou uma lição da Escola. Leva 1 minuto e ajuda a '
        'melhorar esta e as próximas.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no diploma, uma linha com seta que abre a pesquisa '
      '(H-OPI-02)', (tester) async {
    await pumpCard(
      tester,
      SurveyKind.pilares,
      source: SurveyInviteSource.pilaresDiploma,
    );
    final row = find.byKey(SurveyKeys.inviteRow(SurveyKind.pilares));
    expect(row, findsOneWidget);
    expect(find.text('O que você achou do Pilares?'), findsOneWidget);
    expect(
      find.text('Leva 1 minuto e ajuda a melhorar as lições.'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.chevron_right)),
      findsOneWidget,
    );
    expect(find.text('Responder'), findsNothing);

    await pumpCard(
      tester,
      SurveyKind.school,
      source: SurveyInviteSource.schoolDiploma,
    );
    expect(find.text('O que você achou da Escola?'), findsOneWidget);
  });

  testWidgets('a trilha sintética: só as aulas visíveis, sem "em breve" nem '
      '"avise", e sem convite de pesquisa (fica no fim de lição e no '
      'diploma)', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final cubit = EndgamesCubit(
      lessons: VisibleEndgameLessonRepository(
        FakeEndgameLessonRepository(
          trail: EndgameTrail(
            modules: [
              EndgameModule(
                id: 'rook',
                lessons: [
                  EndgameLesson(
                    id: 'rook.lucena',
                    module: 'rook',
                    lesson: Lesson.parted(
                      id: 'rook.lucena',
                      parts: const [
                        LessonPart(
                          id: 'example',
                          steps: [],
                          script: 'synthetic.json',
                        ),
                      ],
                    ),
                    exercises: const [],
                    passScore: 0,
                    keyPositions: const [],
                    practice: FakeEndgameLessonRepository
                        .sample
                        .modules
                        .first
                        .lessons
                        .first
                        .practice,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await tester.runAsync(() => cubit.load('pt'));
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        surveyRepository: surveys,
        child: BlocProvider.value(value: cubit, child: const EndgamesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    final tiles = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'endgames.lesson.',
          ) &&
          !(widget.key! as ValueKey<String>).value.contains('.score'),
    );
    final ids = {
      for (final element in tiles.evaluate())
        (element.widget.key! as ValueKey<String>).value.substring(
          'endgames.lesson.'.length,
        ),
    };
    expect(ids, isNotEmpty);
    expect(VisibleLessons.endgameLessonIds.containsAll(ids), isTrue);
    expect(find.textContaining('em breve', findRichText: true), findsNothing);
    expect(find.textContaining('avise', findRichText: true), findsNothing);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.pilares)), findsNothing);
  });
}
