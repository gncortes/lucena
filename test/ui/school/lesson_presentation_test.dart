import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T65 §8: the step presentation. Fits under the board (A): the panel stays
/// put and the clock runs. Does not fit (B): a modal sheet covers the board,
/// the footer hides and the clock waits for the X.
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  final lesson = Lesson.parted(
    id: 'rook.lucena',
    parts: const [
      LessonPart(
        id: 'bridge',
        steps: [
          ThinkStep(id: 'think', fen: fen, hints: 2),
          MoveStep(
            id: 'try',
            fen: fen,
            line: [
              MoveTurn(accept: {'c1c4'}),
            ],
            mistakes: {'c1c3': StepMistake(say: 'step.try.c3')},
          ),
          TalkStep(id: 'end', fen: fen),
        ],
      ),
    ],
  );
  final trail = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: lesson,
            exercises: const [],
            passScore: 0,
            keyPositions: const [],
            practice: const Practice(fen: fen, goal: PositionGoal.win),
          ),
        ],
      ),
    ],
  );
  final texts = LessonTexts.fromJson({
    'rook.lucena.think': 'Where should the rook go? Think about 1.Rc4.',
    'rook.lucena.think.hint1': 'Think about a bridge.',
    'rook.lucena.think.hint2': 'The rook goes to the fourth rank.',
    'rook.lucena.try': 'Now you: build the bridge.',
    'rook.lucena.try.done': 'Perfect, that is the bridge with 1.Rc4.',
    'rook.lucena.try.hint': 'Not yet: the rook must reach the fourth rank.',
    'rook.lucena.try.c3': 'With 1.Rc3? the rook is one rank short.',
    'rook.lucena.end': 'That is all.',
    'coach.wrong': ['Not that one.'],
  });

  Future<LessonCubit> pump(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail, texts: texts),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      now: FakeNow(DateTime.utc(2026, 10, 12, 20)),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('en'),
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return cubit;
  }

  testWidgets('caso A (412x917): o painel fica parado e o relógio corre', (
    tester,
  ) async {
    final cubit = await pump(tester, const Size(412, 917));
    expect(cubit.state.presenting, isFalse);
    expect(find.byKey(LessonKeys.footer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caso B (360x640): a folha cobre o tabuleiro até o X', (
    tester,
  ) async {
    final cubit = await pump(tester, const Size(360, 640));
    expect(cubit.state.presenting, isTrue);
    expect(cubit.stepElapsed, Duration.zero);
    final board = tester.getRect(find.byKey(LessonKeys.board));
    final sheet = tester.getRect(find.byKey(LessonKeys.scroll));
    expect(sheet.top, lessThan(board.bottom), reason: 'cobre o tabuleiro');
    expect(find.byKey(LessonKeys.closeSheet), findsOneWidget);
    await tester.tap(find.byKey(LessonKeys.closeSheet));
    await tester.pumpAndSettle();
    expect(cubit.state.presenting, isFalse);
    final after = tester.getRect(find.byKey(LessonKeys.scroll));
    expect(after.top, greaterThanOrEqualTo(board.bottom));
    expect(tester.takeException(), isNull);
  });
}
