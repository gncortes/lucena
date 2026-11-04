import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/lesson_end.dart';
import 'package:lucena/ui/core/keys/lesson_end_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/widgets/diploma_card.dart';
import 'package:lucena/ui/lesson_end/widgets/course_completed_screen.dart';
import 'package:lucena/ui/lesson_end/widgets/day_goal_screen.dart';
import 'package:lucena/ui/lesson_end/widgets/demo_offer_screen.dart';
import 'package:lucena/ui/lesson_end/widgets/lesson_soon_screen.dart';
import 'package:lucena/ui/lesson_end/widgets/week_review_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_survey_repository.dart';
import '../../../testing/test_app.dart';

/// H-LIC-50 a 58: telas do fim da lição e do curso, com os textos do canvas.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: FakeSurveyRepository(),
        child: child,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  DayGoalSummary summary({bool testPending = true}) => DayGoalSummary(
    week: 2,
    weekCount: 6,
    daysLeft: 3,
    currentChapter: 'Capítulo 8 · Recursos defensivos',
    lessonsDone: 3,
    lessonsTotal: 4,
    testPending: testPending,
    chapterProgress: const [1, 1, 0.5, 0, 0, 0],
    chaptersDone: 2,
  );

  testWidgets('B19: meta do dia com o teste pendente', (tester) async {
    var back = 0, test = 0;
    await pump(
      tester,
      DayGoalScreen(
        summary: summary(),
        onBack: () => back++,
        onTest: () => test++,
      ),
    );
    expect(find.text('Meta de hoje cumprida'), findsOneWidget);
    expect(find.text('Semana 2 de 6 · faltam 3 dias'), findsOneWidget);
    expect(find.text('3 de 4 lições · falta o teste'), findsOneWidget);
    expect(find.text('2 de 6 capítulos concluídos'), findsOneWidget);
    await tester.tap(find.byKey(LessonEndKeys.dayGoalTest));
    await tester.tap(find.byKey(LessonEndKeys.dayGoalBack));
    expect(test, 1);
    expect(back, 1);
  });

  testWidgets('B19: sem teste pendente, o botão do teste some', (tester) async {
    await pump(
      tester,
      DayGoalScreen(
        summary: summary(testPending: false),
        onBack: () {},
        onTest: () {},
      ),
    );
    expect(find.byKey(LessonEndKeys.dayGoalTest), findsNothing);
    expect(find.text('3 de 4 lições'), findsOneWidget);
  });

  testWidgets('H-ANI-13: as barras dos capítulos enchem de 0 na entrada', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: FakeSurveyRepository(),
        child: DayGoalScreen(summary: summary(), onBack: () {}),
      ),
    );
    final bars = find.descendant(
      of: find.byKey(MotionKeys.barraQueEnche),
      matching: find.byType(LinearProgressIndicator),
    );
    expect(bars, findsNWidgets(6));
    double first() => tester.widget<LinearProgressIndicator>(bars.first).value!;
    expect(first(), 0);
    await tester.pump(const Duration(milliseconds: 350));
    expect(first(), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(first(), 1);
  });

  testWidgets('H-ANI-13: com movimento reduzido, a barra já está cheia', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: FakeSurveyRepository(),
        mediaBuilder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        child: DayGoalScreen(summary: summary(), onBack: () {}),
      ),
    );
    final bars = find.descendant(
      of: find.byKey(MotionKeys.barraQueEnche),
      matching: find.byType(LinearProgressIndicator),
    );
    expect(tester.widget<LinearProgressIndicator>(bars.at(2)).value, .5);
  });

  testWidgets('B20: oferta da demonstração', (tester) async {
    var see = 0, notNow = 0;
    await pump(
      tester,
      DemoOfferScreen(
        chapterNumber: 1,
        exerciseTitle: 'Lista de exercícios',
        correct: 10,
        total: 12,
        teacher: FakeCharacterRepository.viktor,
        onSeeCourse: () => see++,
        onNotNow: () => notNow++,
      ),
    );
    expect(find.text('Capítulo 1 concluído'), findsOneWidget);
    expect(find.text('Lista de exercícios · 10 de 12 acertos'), findsOneWidget);
    await tester.tap(find.byKey(LessonEndKeys.offerAction));
    await tester.tap(find.byKey(LessonEndKeys.offerNotNow));
    expect(see, 1);
    expect(notNow, 1);
  });

  WeekReview review({int daysLeft = 5, bool warmups = false}) => WeekReview(
    week: 6,
    weekCount: 6,
    periodLabel: '1 a 7 de dezembro',
    items: const [
      WeekReviewItem(
        chapter: 'Capítulo 8 · Recursos defensivos',
        correct: 7,
        total: 15,
        path: '/t/1',
      ),
    ],
    tournament: TournamentInfo(
      name: 'Aberto de Curitiba',
      dateLabel: '7 de dezembro',
      daysLeft: daysLeft,
    ),
    warmups: warmups
        ? const [
            TournamentWarmup(
              fen: 'x',
              chapter: 'Capítulo 1',
              side: 'Brancas',
              path: '/w/1',
            ),
          ]
        : const [],
  );

  testWidgets('B22: revisão da semana abre o teste do capítulo', (
    tester,
  ) async {
    final opened = <String>[];
    await pump(
      tester,
      WeekReviewScreen(
        review: review(),
        teacher: FakeCharacterRepository.viktor,
        onOpen: opened.add,
        onStart: () => opened.add('start'),
        onBack: () {},
      ),
    );
    expect(find.text('Revisão'), findsOneWidget);
    expect(find.text('Faltam 5 dias'), findsOneWidget);
    expect(find.text('Teste do capítulo · 7 de 15'), findsOneWidget);
    expect(find.text('Começar a revisão'), findsOneWidget);
    await tester.tap(find.text('Teste do capítulo · 7 de 15'));
    expect(opened, ['/t/1']);
  });

  testWidgets('B22: no dia do torneio vira Dia do torneio', (tester) async {
    await pump(
      tester,
      WeekReviewScreen(
        review: review(daysLeft: 0, warmups: true),
        teacher: FakeCharacterRepository.viktor,
        onOpen: (_) {},
        onStart: () {},
        onBack: () {},
      ),
    );
    expect(find.byKey(LessonEndKeys.tournament), findsOneWidget);
    expect(find.text('Dia do torneio'), findsOneWidget);
    expect(find.text('Três posições para aquecer'), findsOneWidget);
    expect(find.text('Aquecer'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);
  });

  testWidgets('B23: curso concluído com diploma, metas e catálogo', (
    tester,
  ) async {
    var goals = 0;
    await pump(
      tester,
      CourseCompletedScreen(
        completion: const CourseCompletion(
          courseName: 'Pilares',
          chapters: 12,
          lessons: 48,
          studentName: 'Ana Souza',
          dateLabel: '4 de novembro de 2026',
          teacherName: 'Viktor',
        ),
        teacher: FakeCharacterRepository.viktor,
        onGoals: () => goals++,
        onCatalog: () {},
        onClose: () {},
      ),
    );
    expect(find.text('Você concluiu o Pilares'), findsOneWidget);
    expect(find.byKey(LessonEndKeys.completedDiploma), findsOneWidget);
    // H-LIC-53: o mesmo diploma da Escola (componente único) e o
    // "Compartilhar conquista" do quadro, sempre na app bar.
    expect(
      find.descendant(
        of: find.byKey(LessonEndKeys.completedDiploma),
        matching: find.byType(DiplomaCard),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(LessonEndKeys.completedShare),
        matching: find.byIcon(Icons.share_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Ver o catálogo'), findsOneWidget);
    expect(find.byKey(LessonEndKeys.completedShare), findsOneWidget);
    await tester.tap(find.byKey(LessonEndKeys.completedGoals));
    expect(goals, 1);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('H-LIC-58: lição em breve com X e Voltar', (tester) async {
    var back = 0;
    await pump(tester, LessonSoonScreen(onBack: () => back++));
    expect(find.text('A próxima lição chega em breve'), findsOneWidget);
    await tester.tap(find.byKey(LessonEndKeys.soonClose));
    await tester.tap(find.byKey(LessonEndKeys.soonBack));
    expect(back, 2);
  });
}
