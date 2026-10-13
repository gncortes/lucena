import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/lesson_v2_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T65 D13–D16 (QA final): the wrong move of a move step opens the sheet
/// (WRONG MOVE + CORRECT MOVE + free board invite); the think mistake titles
/// its explanation; the cited move takes the error colour; Continue keeps its
/// 16 dp margin.
void main() {
  const mateFen = '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1';
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
              ),
              ThinkStep(id: 'think', fen: mateFen, accept: {'a1a8'}),
              TalkStep(id: 'after', fen: mateFen),
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
    'mates.rank.test.hint': 'Look at the back rank.',
    'mates.rank.think': 'Where does the rook go?',
    'mates.rank.after': 'The rook mates on a8.',
    'coach.wrong': ['Not that one.'],
  });

  Move move(String uci) => Move.parse(uci)!;

  Future<LessonCubit> open(int step) async {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(course: course, texts: texts),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('mates.rank', 'en');
    for (var i = 0; i < step; i++) {
      if (cubit.state.current is MoveStep) await cubit.play(move('a1a8'));
      await cubit.next();
    }
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
    // A folha abre sozinha com o texto novo e recolhe depois do tempo de
    // leitura: o teste parte dela recolhida.
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets('$size: a wrong move opens the WRONG MOVE sheet', (
      tester,
    ) async {
      final cubit = await open(1);
      await show(tester, cubit, size);
      await tester.runAsync(() => cubit.play(move('a1a5')));
      await tester.pumpAndSettle();
      expect(cubit.state.wrongMove, isTrue);
      expect(find.text('INCORRECT MOVE'), findsOneWidget);
      expect(find.text('CORRECT MOVE'), findsOneWidget);
      expect(find.byKey(LessonV2Keys.freeBoardInvite), findsOneWidget);
      expect(find.textContaining('1.Ra5?', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The next correct move closes the sheet.
      await tester.runAsync(() => cubit.play(move('a1a8')));
      await tester.pumpAndSettle();
      expect(cubit.state.wrongMove, isFalse);
    });
  }

  testWidgets('a wrong move without a planned mistake shows Back | See '
      'solution | Continue, and See solution works', (tester) async {
    final cubit = await open(1);
    await show(tester, cubit, const Size(360, 740));
    await tester.runAsync(() => cubit.play(move('a1a5')));
    await tester.pumpAndSettle();
    expect(cubit.state.wrongMove, isTrue);
    expect(find.byKey(LessonKeys.seeSolution), findsOneWidget);
    expect(find.byKey(LessonKeys.backButton), findsOneWidget);
    expect(find.byKey(LessonKeys.nextButton), findsOneWidget);
    await tester.tap(find.byKey(LessonKeys.seeSolution));
    await tester.pumpAndSettle();
    expect(cubit.state.solutionSeen, isTrue);
    expect(find.byKey(LessonKeys.solutionFooter), findsOneWidget);
    expect(find.byKey(LessonKeys.retryButton), findsOneWidget);
  });

  testWidgets('think mistake: the explanation is titled CORRECT MOVE and the '
      'move is in the primary colour (no result colour)', (tester) async {
    final cubit = await open(2);
    await show(tester, cubit, const Size(360, 740));
    await tester.runAsync(() => cubit.play(move('a1b1')));
    await tester.pumpAndSettle();
    expect(find.text('CORRECT MOVE'), findsOneWidget);
    // LICOES-V2 §2: o lance é sempre primary; o resultado não tem cor.
    final error = Theme.of(tester.element(find.byType(LessonScreen)))
        .colorScheme
        .primary;
    var found = false;
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      rich.text.visitChildren((span) {
        if (span is TextSpan &&
            (span.text ?? '').contains('1.Rb1') &&
            span.style?.color == error) {
          found = true;
        }
        return true;
      });
    }
    expect(found, isTrue);
  });

  testWidgets('Continue keeps 16 dp from the right edge', (tester) async {
    final cubit = await open(0);
    await show(tester, cubit, const Size(360, 740));
    final right = tester.getTopRight(find.byKey(LessonKeys.nextButton)).dx;
    expect(right, closeTo(360 - 16, 1));
  });

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets('$size: the error footer keeps its three '
        'buttons inside the solid box', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final cubit = await open(1);
      await show(tester, cubit, size);
      await tester.runAsync(() => cubit.play(move('a1a5')));
      await tester.pumpAndSettle();
      expect(cubit.state.wrongMove, isTrue);
      // O rodapé de erro (Voltar | Ver solução | Continuar) é a caixa sólida
      // do painel, sem a faixa que esmaece.
      final footer = tester.getRect(find.byKey(LessonKeys.footer));
      var buttons = 0;
      for (final key in [
        LessonKeys.backButton,
        LessonKeys.seeSolution,
        LessonKeys.nextButton,
      ]) {
        buttons++;
        final r = tester.getRect(find.byKey(key));
        expect(r.top, greaterThanOrEqualTo(footer.top));
        expect(r.bottom, lessThanOrEqualTo(footer.bottom));
      }
      expect(buttons, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
