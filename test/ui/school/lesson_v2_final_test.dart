import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T65 Lições V2, QA final da Frente A: fim da demo.
void main() {
  const fen = '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1';
  const course = Course(
    modules: [
      CourseModule(
        id: 'mates',
        lessons: [
          Lesson(
            id: 'mates.rank',
            steps: [
              TalkStep(id: 'intro', fen: fen),
              DemoStep(
                id: 'demo',
                fen: fen,
                line: [DemoMove(uci: 'a1a8')],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  final texts = LessonTexts.fromJson({
    'mates.rank.title': 'Back rank',
    'mates.rank.intro': 'Intro text.',
    'mates.rank.demo.m1': '1.Ra8#. The rook mates.',
  });

  Future<LessonCubit> open() async {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(course: course, texts: texts),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('mates.rank', 'en');
    await cubit.next();
    return cubit;
  }

  Future<void> show(WidgetTester tester, LessonCubit cubit, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets('$size: demo end shows only the move speech and Continue '
        'sits 16 dp from the edge', (tester) async {
      final cubit = await open();
      await show(tester, cubit, size);
      await tester.runAsync(cubit.demoForward);
      await tester.pumpAndSettle();
      expect(cubit.state.phase, StepPhase.done);
      expect(find.text('POSITION AND GOAL'), findsNothing);
      expect(find.text('THE POSITION AND THE GOAL'), findsNothing);
      expect(
        find.textContaining('The rook mates', findRichText: true),
        findsOneWidget,
      );
      final right = tester.getTopRight(find.byKey(LessonKeys.nextButton)).dx;
      expect(right, closeTo(size.width - 16, 1));
      // The speech ends above the footer (bottom padding).
      final footerTop = tester.getTopLeft(find.byKey(LessonKeys.footer)).dy;
      final speech = tester.getBottomLeft(
        find.textContaining('The rook mates', findRichText: true),
      );
      expect(speech.dy, lessThanOrEqualTo(footerTop + 1));
      expect(tester.takeException(), isNull);
    });
  }

  test('demoSheetPayload drops the fixed context section at the demo end', () {
    final payload = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'c',
          kind: ExplanationKind.context,
          title: 'A posição e o objetivo',
          texts: ['Fixed.'],
        ),
        ExplanationBlock(
          id: 'm',
          kind: ExplanationKind.mainSolution,
          texts: ['3.Rg5. Move speech.'],
        ),
      ],
    );
    expect(
      demoSheetPayload(payload, inDemo: true).explanations.map((b) => b.id),
      ['m'],
    );
    expect(demoSheetPayload(payload, inDemo: false), same(payload));
    final only = ExplanationPayload.context(['Only context.']);
    expect(demoSheetPayload(only, inDemo: true), same(only));
  });

  test('demoSheetPayload keeps only the move speech: no section title, '
      'no variation lines', () {
    final line = ExplanationVariation(
      id: 'A',
      label: '1.Re4',
      outcome: VariationOutcome.accepted,
      texts: ['Esta continuação conserva a vitória.', 'Continuação: 1.Re4'],
      originFen: fen,
      movesUci: ['a1a8'],
      movesSan: ['1.Ra8'],
      validated: true,
    );
    final payload = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'c',
          kind: ExplanationKind.context,
          title: 'Fixed',
          texts: ['Fixed.'],
        ),
        ExplanationBlock(
          id: 'm',
          kind: ExplanationKind.mainSolution,
          title: 'A ideia principal',
          texts: ['3.Rg5. Move speech.'],
          variations: [line],
        ),
      ],
    );
    final shown = demoSheetPayload(payload, inDemo: true).explanations.single;
    expect(shown.texts, ['3.Rg5. Move speech.']);
    expect(shown.variations, isEmpty);
    expect(shown.title, isEmpty);
    expect(shown.kind, ExplanationKind.context);
  });

  test('wrongMoveSheetPayload: WRONG MOVE, CORRECT MOVE, DO NOT WORK, '
      'without the position section', () {
    ExplanationBlock block(String id, ExplanationKind kind, [String t = '']) =>
        ExplanationBlock(id: id, kind: kind, title: t, texts: [id]);
    final payload = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.incorrect,
      explanations: [
        block('played', ExplanationKind.playedIncorrect),
        block('ctx', ExplanationKind.context, 'A posição e o objetivo'),
        block('main', ExplanationKind.mainSolution, 'A ideia principal'),
        block('fail', ExplanationKind.failedAlternatives),
      ],
    );
    final out = wrongMoveSheetPayload(payload, correctMoveTitle: 'Lance certo');
    expect(out.explanations.map((b) => b.id), ['played', 'main', 'fail']);
    expect(out.explanations[1].title, 'Lance certo');
    final correct = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.correct,
      explanations: payload.explanations,
    );
    expect(
      wrongMoveSheetPayload(correct, correctMoveTitle: 'x'),
      same(correct),
    );
  });
}
