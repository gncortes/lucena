import 'package:dartchess/dartchess.dart';
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
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/sheet_settle.dart';
import '../../../testing/test_app.dart';

/// T65 §2 and §8: the board stays high in every lesson state (D15), solving
/// too: top 80 (app bar 56 + progress 8+8 + gutter 8), side 344 at 360×740
/// and 396 at 412×917, with Viktor's header in the sheet below it.
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

  Future<LessonCubit> pump(
    WidgetTester tester, {
    required Size size,
    required double scale,
    required ThemeMode theme,
    required Locale locale,
  }) async {
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
    await cubit.load('rook.lucena', locale.languageCode);
    await cubit.startStepClock();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        themeMode: theme,
        settingsCubit: settings,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              textScaler: TextScaler.linear(scale),
            ),
            child: BlocProvider.value(
              value: cubit,
              child: const LessonScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A folha abre sozinha com o texto novo e recolhe depois do tempo de
    // leitura: o teste parte dela recolhida.
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
    return cubit;
  }

  void expectHighBoard(WidgetTester tester, Size size, String state) {
    final board = tester.getRect(find.byKey(LessonKeys.board));
    final side = size.width - 16;
    expect(board.top, closeTo(80, 1), reason: '$state: board top');
    expect(board.width, closeTo(side, 1), reason: '$state: board side');
    expect(board.height, closeTo(side, 1), reason: '$state: board side');
    expect(board.left, closeTo(8, 1), reason: '$state: board start');
    final progress = tester.getRect(find.byKey(LessonKeys.progress));
    expect(progress.top, closeTo(56, 1), reason: '$state: progress top');
    expect(progress.height, closeTo(4, 1), reason: '$state: progress height');
    // Viktor (header and speech) lives in the sheet, below the board.
    final teacher = find.byWidgetPredicate(
      (widget) =>
          widget is TeacherSpeech && widget.part != TeacherSpeechPart.bubble,
    );
    expect(teacher, findsOneWidget, reason: '$state: one Viktor, in the sheet');
    expect(
      tester.getTopLeft(teacher).dy,
      greaterThan(board.bottom),
      reason: '$state: Viktor below the board',
    );
    expect(
      tester.getRect(find.byKey(LessonKeys.scroll)).top,
      closeTo(board.bottom + 8, 1),
      reason: '$state: sheet 8 below the board',
    );
    expect(tester.takeException(), isNull, reason: '$state: no overflow');
  }

  /// Every footer button reachable on screen has a 48 dp target.
  void expectFooterTargets(WidgetTester tester, String state) {
    final buttons = find.descendant(
      of: find.byKey(LessonKeys.footer),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ButtonStyleButton ||
            widget is IconButton ||
            widget is FloatingActionButton,
      ),
    );
    expect(buttons, findsWidgets, reason: '$state: footer buttons');
    for (final element in buttons.evaluate()) {
      final box = element.renderObject! as RenderBox;
      if (!box.hasSize) continue;
      expect(
        box.size.height,
        greaterThanOrEqualTo(48 - .5),
        reason: '$state: ${element.widget.runtimeType} height',
      );
      expect(
        box.size.width,
        greaterThanOrEqualTo(48 - .5),
        reason: '$state: ${element.widget.runtimeType} width',
      );
    }
  }

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    for (final scale in [1.0, 2.0]) {
      for (final theme in [ThemeMode.light, ThemeMode.dark]) {
        for (final locale in [const Locale('pt'), const Locale('ar')]) {
          final label =
              '${size.width.toInt()}x${size.height.toInt()} '
              '×$scale ${theme.name} ${locale.languageCode}';
          testWidgets('$label: board high in every lesson state', (
            tester,
          ) async {
            final cubit = await pump(
              tester,
              size: size,
              scale: scale,
              theme: theme,
              locale: locale,
            );
            // Pensar (solving, think step).
            expect(cubit.state.layout, LessonLayoutMode.solving);
            await settleSheet(tester);
            expectHighBoard(tester, size, 'Pensar');
            expectFooterTargets(tester, 'Pensar');
            // PensarDica.
            await cubit.moreHint();
            await tester.pumpAndSettle();
            await settleSheet(tester);
            expectHighBoard(tester, size, 'PensarDica');
            // Pratica (move step, solving).
            await cubit.next();
            await tester.pumpAndSettle();
            // A apresentação do passo (§8) termina antes do jogo.
            await cubit.startStepClock();
            await tester.pumpAndSettle();
            expect(cubit.state.current?.id, 'try');
            expect(cubit.state.layout, LessonLayoutMode.solving);
            await settleSheet(tester);
            expectHighBoard(tester, size, 'Pratica');
            expectFooterTargets(tester, 'Pratica');
            // LanceErrado (wrong move, not predicted).
            await cubit.play(Move.parse('c1c2')!);
            await tester.pumpAndSettle();
            await settleSheet(tester);
            expectHighBoard(tester, size, 'LanceErrado');
            // Errou (predicted wrong move: 2×2 footer).
            await cubit.play(Move.parse('c1c3')!);
            await tester.pumpAndSettle();
            expect(cubit.state.phase, StepPhase.failed);
            await settleSheet(tester);
            expectHighBoard(tester, size, 'Errou');
            expect(find.byKey(LessonKeys.retryButton), findsOneWidget);
            expectFooterTargets(tester, 'Errou');
            // LanceResposta (right move).
            await cubit.retry();
            await tester.pumpAndSettle();
            await cubit.play(Move.parse('c1c4')!);
            await tester.pumpAndSettle();
            expect(cubit.state.layout, LessonLayoutMode.explaining);
            await settleSheet(tester);
            expectHighBoard(tester, size, 'LanceResposta');
            expectFooterTargets(tester, 'LanceResposta');
          });
        }
      }
    }
  }
}
