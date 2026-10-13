import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  const mateFen = '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1';
  const queenFen = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';
  const course = Course(
    modules: [
      CourseModule(
        id: 'mates',
        lessons: [
          Lesson(
            id: 'mates.rank',
            steps: [
              TalkStep(id: 'backrank', fen: mateFen),
              MoveStep(
                id: 'test',
                fen: mateFen,
                line: [
                  MoveTurn(accept: {'a1a8'}),
                ],
                mistakes: {
                  'a1a7': StepMistake(say: 'step.test.a7', review: 'backrank'),
                  'a1a6': StepMistake(),
                },
              ),
              PlayStep(
                id: 'play',
                fen: queenFen,
                mistakes: {
                  'h1h4': StepMistake(say: 'step.play.h4', review: 'nope'),
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
  final texts = LessonTexts.fromJson({
    'mates.rank.title': 'Back rank',
    'mates.rank.backrank': 'The pawns lock their own king.',
    'mates.rank.test': 'Mate in one.',
    'mates.rank.test.a7': 'The rook on a7 gives no check.',
    'mates.rank.play.h4': 'Qh4 lets the king out.',
    'coach.wrong': ['Not that one.'],
    'coach.retry': ['Again.'],
  });

  late LessonCubit lesson;
  Move move(String uci) => Move.parse(uci)!;

  setUp(() async {
    lesson = LessonCubit(
      lessons: FakeLessonRepository(course: course, texts: texts),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(lesson.close);
    await lesson.load('mates.rank', 'en');
    await lesson.next();
    expect(lesson.state.current?.id, 'test');
  });

  test(
    'lance errado previsto: explica, para o passo e oferece rever',
    () async {
      await lesson.play(move('a1a7'));
      final state = lesson.state;
      expect(state.phase, StepPhase.failed);
      expect(state.layout, LessonLayoutMode.explaining);
      expect(state.speech, 'The rook on a7 gives no check.');
      expect(state.genericMistake, isFalse);
      expect(state.reviewStep, 'backrank');
      expect(state.mistakes, 1);
      // A peça volta.
      expect(state.fen, mateFen);
    },
  );

  test('rever o ponto abre o passo e continuar volta ao teste', () async {
    await lesson.play(move('a1a7'));
    await lesson.reviewPoint();
    expect(lesson.state.current?.id, 'backrank');
    expect(lesson.state.returnTo, 1);
    expect(lesson.state.canContinue, isTrue);
    await lesson.next();
    expect(lesson.state.current?.id, 'test');
    expect(lesson.state.returnTo, isNull);
    expect(lesson.state.phase, StepPhase.active);
    await lesson.play(move('a1a8'));
    expect(lesson.state.phase, StepPhase.done);
  });

  test('tentar de novo volta a jogar da mesma posição', () async {
    await lesson.play(move('a1a7'));
    await lesson.retry();
    expect(lesson.state.phase, StepPhase.active);
    expect(lesson.state.reviewStep, isNull);
    // T65 §4: o passo recomeça como na abertura (a fala de abertura, não a
    // do "de novo"); o erro já contado fica.
    expect(lesson.state.speech, 'Mate in one.');
    expect(lesson.state.mistakes, 1);
    await lesson.play(move('a1a8'));
    expect(lesson.state.phase, StepPhase.done);
  });

  test(
    'previsto sem fala nem passo: a fala genérica e só tentar de novo',
    () async {
      await lesson.play(move('a1a6'));
      expect(lesson.state.phase, StepPhase.failed);
      expect(lesson.state.genericMistake, isTrue);
      expect(lesson.state.reviewStep, isNull);
    },
  );

  test(
    'lance errado sem nada previsto: a fala genérica, o passo segue',
    () async {
      await lesson.play(move('a1a5'));
      expect(lesson.state.phase, StepPhase.active);
      expect(lesson.state.genericMistake, isTrue);
      await lesson.play(move('a1a8'));
      expect(lesson.state.genericMistake, isFalse);
    },
  );

  test('passo de jogar: o lance previsto não é jogado; passo de rever que '
      'não existe fica de fora', () async {
    await lesson.play(move('a1a8'));
    await lesson.next();
    expect(lesson.state.current, isA<PlayStep>());
    await lesson.play(move('h1h4'));
    expect(lesson.state.phase, StepPhase.failed);
    expect(lesson.state.fen, queenFen);
    expect(lesson.state.speech, 'Qh4 lets the king out.');
    expect(lesson.state.reviewStep, isNull);
    await lesson.retry();
    expect(lesson.state.phase, StepPhase.active);
    expect(lesson.state.fen, queenFen);
  });

  test('o JSON da aula: linha errada, variantes citadas e erros previstos', () {
    final parsed = AssetLessonRepository.parseLesson({
      'id': 'x',
      'steps': [
        {
          'type': 'demo',
          'id': 'd',
          'fen': mateFen,
          'wrong': true,
          'line': [
            {'uci': 'a1a7'},
          ],
        },
        {
          'type': 'talk',
          'id': 't',
          'fen': mateFen,
          'lines': [
            {'uci': 'a1a7 g8h8', 'wrong': true},
            {
              'uci': ['a1a8'],
            },
          ],
        },
        {
          'type': 'move',
          'id': 'm',
          'fen': mateFen,
          'line': [
            {
              'accept': ['a1a8'],
            },
          ],
          'mistakes': {
            'a1a7': {'say': 'step.m.a7', 'review': 't'},
          },
        },
        {
          'type': 'think',
          'id': 'k',
          'fen': mateFen,
          'mistakes': {
            'a1a6': {'say': 'step.k.a6'},
          },
        },
      ],
    });
    final [demo, talk, test, think] = parsed.steps;
    expect((think as ThinkStep).mistakes['a1a6']?.say, 'step.k.a6');
    expect((demo as DemoStep).wrong, isTrue);
    expect(talk.lines, hasLength(2));
    expect(talk.wrongLine(['a1a7']), isTrue);
    expect(talk.wrongLine(['a1a7', 'g8h8', 'a7b7']), isTrue);
    expect(talk.wrongLine(['a1a8']), isFalse);
    expect(talk.wrongLine(['a1a6']), isFalse);
    final mistake = (test as MoveStep).mistakes['a1a7']!;
    expect(mistake.say, 'step.m.a7');
    expect(mistake.review, 't');
  });

  group('contextual review metadata', () {
    const initial = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    const line = MoveStep(
      id: 'line',
      fen: initial,
      line: [
        MoveTurn(accept: {'e2e4'}, reply: 'e7e5'),
        MoveTurn(accept: {'g1f3'}),
      ],
    );
    LessonCubit build(
      LessonStep step,
      _ReviewFeedback feedback,
      FakeSchoolProgressRepository progress,
    ) {
      final result = LessonCubit(
        lessons: FakeLessonRepository(
          course: Course(
            modules: [
              CourseModule(
                id: 'm',
                lessons: [
                  Lesson(
                    id: 'review',
                    steps: [
                      const TalkStep(id: 'intro', fen: initial),
                      step,
                      const TalkStep(id: 'later'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        progress: progress,
        feedback: feedback,
        characters: FakeCharacterRepository(),
        opponent: FakeOpponentRepository(),
        replyDelay: Duration.zero,
      );
      addTearDown(result.close);
      return result;
    }

    for (final target in <String?>[null, 'missing', 'line', 'later']) {
      test(
        'invalid/absent target $target preserves legacy MoveStep behavior',
        () async {
          final feedback = _ReviewFeedback()
            ..target = target
            ..origin = initial;
          final cubit = build(line, feedback, FakeSchoolProgressRepository());
          await cubit.load('review', 'en');
          await cubit.next();
          await cubit.play(move('a2a3'));
          expect(cubit.state.phase, StepPhase.active);
          expect(cubit.state.reviewStep, isNull);
          expect(cubit.state.fen, initial);
        },
      );
    }

    test(
      'accepted MoveStep equivalent overrides rejected contextual metadata',
      () async {
        final feedback = _ReviewFeedback()
          ..origin = initial
          ..uci = 'e2e4';
        final cubit = build(line, feedback, FakeSchoolProgressRepository());
        await cubit.load('review', 'en');
        await cubit.next();
        await cubit.play(move('e2e4'));
        expect(cubit.state.turn, 1);
        expect(cubit.state.mistakes, 0);
      },
    );

    test('PlayStep rejects verified root, reviews, retries and preserves played history', () async {
      final feedback = _ReviewFeedback()..kind = 'play';
      final progress = FakeSchoolProgressRepository();
      final cubit = build(
        const PlayStep(id: 'line', fen: initial),
        feedback,
        progress,
      );
      await cubit.load('review', 'en');
      await cubit.next();
      await cubit.play(move('e2e4')); // Unlisted move remains playable.
      final origin = cubit.state.fen;
      final history = cubit.state.moves;
      feedback.origin = origin;
      feedback.turn = 2;
      await cubit.play(move('a2a3'));
      expect(cubit.state.phase, StepPhase.failed);
      expect(cubit.state.explanation?.state, ExplanationState.incorrect);
      expect(cubit.state.moves, history);
      await cubit.reviewPoint();
      await cubit.next();
      expect(cubit.state.fen, origin);
      expect(cubit.state.moves, history);
      await cubit.play(move('a2a3'));
      await cubit.retry();
      expect(cubit.state.fen, origin);
      expect(cubit.state.moves, history);
      expect(cubit.state.phase, StepPhase.active);
    });

    for (final outcome in [
      VariationOutcome.accepted,
      VariationOutcome.losing,
    ]) {
      test(
        'PlayStep $outcome metadata is never reused at changed FEN',
        () async {
          final feedback = _ReviewFeedback()
            ..origin = initial
            ..kind = 'play'
            ..uci = 'e2e4'
            ..outcome = outcome;
          // A target is required before a rejected line can stop play.
          if (outcome == VariationOutcome.losing) feedback.target = null;
          final cubit = build(
            const PlayStep(id: 'line', fen: initial),
            feedback,
            FakeSchoolProgressRepository(),
          );
          await cubit.load('review', 'en');
          await cubit.next();
          await cubit.play(move('e2e4'));
          await Future<void>.delayed(Duration.zero);
          expect(cubit.state.moves, hasLength(2));
          expect(cubit.state.phase, StepPhase.active);
          expect(feedback.queries.last.fen, cubit.state.fen);
          expect(feedback.queries.last.turn, 2);
          expect(cubit.state.explanation, isNull);
        },
      );
    }
  });

  group('na tela', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
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
          child: BlocProvider.value(value: lesson, child: const LessonScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('o erro previsto mostra rever e tentar de novo; rever leva '
        'ao passo e o botão volta ao teste', (tester) async {
      await pump(tester);
      await tester.runAsync(() => lesson.play(move('a1a7')));
      await tester.pumpAndSettle();
      expect(find.byKey(LessonKeys.reviewPoint), findsOneWidget);
      expect(find.byKey(LessonKeys.retryButton), findsOneWidget);
      await tester.tap(find.byKey(LessonKeys.reviewPoint));
      await tester.pumpAndSettle();
      expect(lesson.state.current?.id, 'backrank');
      expect(find.text('Back to the test'), findsOneWidget);
    });

    testWidgets('lance errado sem fala: a genérica do app', (tester) async {
      await pump(tester);
      await tester.runAsync(() => lesson.play(move('a1a6')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(LessonKeys.reviewPoint))
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining(
          'what the lesson showed about “Back rank”',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('1.Ra6', findRichText: true), findsOneWidget);
    });
  });

  testWidgets('a variante marcada como errada no JSON mostra o selo junto ao '
      'tabuleiro e nos controles', (tester) async {
    const wrongCourse = Course(
      modules: [
        CourseModule(
          id: 'mates',
          lessons: [
            Lesson(
              id: 'mates.wrong',
              steps: [
                TalkStep(
                  id: 'talk',
                  fen: mateFen,
                  lines: [
                    CitedLine(uci: ['a1a7'], wrong: true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final wrong = LessonCubit(
      lessons: FakeLessonRepository(
        course: wrongCourse,
        texts: LessonTexts.fromJson({
          'mates.wrong.talk': 'After 1.Ra7? Kh8 2.Ra8+ Black is fine.',
        }),
      ),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(wrong.close);
    await tester.runAsync(() => wrong.load('mates.wrong', 'en'));
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await tester.runAsync(settings.load);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: wrong, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.wrongLine), findsNothing);
    expect(find.byKey(LessonKeys.variationShow), findsNothing);
    final action = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .expand(
          (w) =>
              w.properties.customSemanticsActions?.entries ??
              const <MapEntry<CustomSemanticsAction, VoidCallback>>[],
        )
        .singleWhere((entry) => entry.key.label?.contains('1.Ra7') ?? false);
    action.value.call();
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.wrongLine), findsOneWidget);
    expect(find.byKey(LessonKeys.wrongLineControls), findsOneWidget);
    await tester.tap(find.byKey(LessonKeys.variationExit));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.wrongLine), findsNothing);
  });
}

class _ReviewFeedback extends EmptyExerciseFeedbackRepository
    implements ExplanationRepository {
  String? target = 'intro', origin;
  String uci = 'a2a3', kind = 'move';
  int turn = 1;
  VariationOutcome outcome = VariationOutcome.doesNotMeetGoal;
  final queries = <({String fen, int turn})>[];

  @override
  Future<ExplanationPayload?> findPayload({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String language,
    required ExplanationState state,
    String? playedUci,
  }) async {
    queries.add((fen: fen, turn: turn));
    if (this.kind != kind || origin != fen || this.turn != turn) return null;
    return ExplanationPayload(
      positionId: '$kind/$exerciseId.$turn',
      reviewStepId: target,
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'root',
          kind: outcome == VariationOutcome.accepted
              ? ExplanationKind.mainSolution
              : ExplanationKind.failedAlternatives,
          texts: ['Authored explanation'],
          variations: [
            ExplanationVariation(
              id: 'v',
              label: 'Authored move',
              outcome: outcome,
              texts: ['Authored rejection'],
              originFen: fen,
              movesUci: [uci],
              movesSan: [uci],
              validated: true,
            ),
          ],
        ),
      ],
    ).forState(state, playedUci: playedUci);
  }
}
