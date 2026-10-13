import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
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

/// T70 (pg. 3.1 e 4.x) na tela da lição: convite, prático com pontinhos,
/// Voltar desfaz, Continuar refaz e o fim do passo.
void main() {
  const id = 'test.t70';
  const start = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
  const course = Course(
    modules: [
      CourseModule(
        id: 'test',
        lessons: [
          Lesson(
            id: id,
            steps: [
              TalkStep(id: 'talk', fen: start),
              MoveStep(
                id: 'm',
                fen: start,
                line: [
                  MoveTurn(accept: {'e2e4'}, reply: 'e8d8'),
                  MoveTurn(accept: {'e4e5'}),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  const texts = LessonTexts({
    'test.t70.title': ['Teste'],
    'test.t70.talk': ['Explicação.'],
    'test.t70.m': ['Avance o peão.'],
    'test.t70.m.hint': ['Dica do Viktor.'],
    'test.t70.m.r1': ['Resposta ao primeiro lance.'],
    'test.t70.m.done': ['Feito.'],
  });

  Move mv(String uci) => Move.parse(uci)!;

  Future<LessonCubit> open(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(course: course, texts: texts),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
      holdDelay: Duration.zero,
      typingDelay: Duration.zero,
      practiceV2: true,
    );
    addTearDown(cubit.close);
    await cubit.load(id, 'pt');
    await cubit.next();
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
    return cubit;
  }

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets('$size: convite, lance, Voltar, Continuar e fim', (
      tester,
    ) async {
      final cubit = await open(tester, size);
      // Convite: Voltar | Vamos praticar, sem Dica nem folha.
      expect(cubit.state.practiceGate, isTrue);
      expect(find.byKey(LessonKeys.practiceInvite), findsOneWidget);
      expect(find.byKey(LessonKeys.practiceInviteBack), findsOneWidget);
      expect(find.byKey(LessonKeys.hintButton), findsNothing);
      expect(find.byKey(LessonKeys.viktorSheet), findsNothing);
      await tester.tap(find.byKey(LessonKeys.practiceButton));
      await tester.pumpAndSettle();
      // Primeira vez: Dica | Voltar, sem Continuar.
      expect(cubit.state.practiceGate, isFalse);
      expect(find.byKey(LessonKeys.hintButton), findsOneWidget);
      expect(find.byKey(LessonKeys.practiceBack), findsOneWidget);
      expect(find.byKey(LessonKeys.practiceContinue), findsNothing);
      expect(find.text('Avance o peão.'), findsOneWidget);
      // A Dica fala no balão, com o selo.
      await tester.tap(find.byKey(LessonKeys.hintButton));
      await tester.pumpAndSettle();
      expect(find.text('Dica do Viktor.'), findsOneWidget);
      // O lance: pontinhos enquanto a máquina responde, depois o comentário.
      await tester.runAsync(() async {
        final done = cubit.play(mv('e2e4'));
        await Future<void>.delayed(Duration.zero);
        await done;
      });
      await tester.pumpAndSettle();
      expect(cubit.state.turn, 1);
      expect(cubit.state.typing, isFalse);
      expect(find.byKey(LessonKeys.practiceTyping), findsNothing);
      expect(find.text('Resposta ao primeiro lance.'), findsOneWidget);
      expect(find.byKey(LessonKeys.practiceContinue), findsNothing);
      // Voltar desfaz o par e abre o Continuar.
      await tester.tap(find.byKey(LessonKeys.practiceBack));
      await tester.pumpAndSettle();
      expect(cubit.state.turn, 0);
      expect(cubit.state.canRedo, isTrue);
      expect(find.byKey(LessonKeys.practiceContinue), findsOneWidget);
      await tester.tap(find.byKey(LessonKeys.practiceContinue));
      await tester.pumpAndSettle();
      expect(cubit.state.turn, 1);
      expect(find.byKey(LessonKeys.practiceContinue), findsNothing);
      // Último lance: o passo cumprido leva à próxima parte.
      await tester.runAsync(() => cubit.play(mv('e4e5')));
      await tester.pumpAndSettle();
      expect(find.text('Feito.'), findsOneWidget);
      expect(find.byKey(LessonKeys.practiceContinue), findsOneWidget);
      await tester.tap(find.byKey(LessonKeys.practiceContinue));
      await tester.pumpAndSettle();
      expect(find.byKey(LessonKeys.finished), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Voltar do convite volta ao último passo de aprendizado', (
    tester,
  ) async {
    final cubit = await open(tester, const Size(360, 740));
    await tester.tap(find.byKey(LessonKeys.practiceInviteBack));
    await tester.pumpAndSettle();
    expect(cubit.state.step, 0);
    expect(find.byKey(LessonKeys.practiceInvite), findsNothing);
  });

  testWidgets('Voltar na vez inicial leva ao convite', (tester) async {
    final cubit = await open(tester, const Size(360, 740));
    await tester.tap(find.byKey(LessonKeys.practiceButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LessonKeys.practiceBack));
    await tester.pumpAndSettle();
    expect(cubit.state.practiceGate, isTrue);
    expect(find.byKey(LessonKeys.practiceInvite), findsOneWidget);
  });
}
