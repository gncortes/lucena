import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
import 'package:chessground/chessground.dart' show ChessgroundImages;
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_exercise.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_exercise/widgets/training_exercise_screen.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';
import 'package:lucena/ui/training_opening/widgets/training_opening_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';
import 'training_exercise_screen_test.dart' show expectCanvasBlock;

/// Explicit static fixtures, with Canvas copy injected only through preview.
/// These PNGs do not certify any transition, scoring, authored teaching or engine.
void main() {
  setUpAll(Goldens.loadFonts);
  final fixtures = (jsonDecode(
    File('test/ui/training_exercise/fixtures/t85_canvas_states.json')
        .readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  final teacher = FakeCharacterRepository.viktor;
  const original = '5r1k/5Rb1/p2P2Pp/1p5n/2p5/P4B1P/1pP5/5R1K b - - 2 32';
  const retry = '6rk/7p/1p1pN2P/3P1P2/p1Q1P3/Pn4q1/1PB5/1K5R b - - 0 35';
  const line = ['h5g3', 'h1g2', 'g3f1'];
  const retryLine = ['b3d2', 'b1a2', 'd2c4'];
  final openingParts = [
    for (var i = 1; i <= 5; i++)
      OpeningTrecho(
        id: 'part$i',
        title: 'Sistema London',
        lines: const [
          [
            'd2d4',
            'd7d5',
            'c1f4',
            'g8f6',
            'e2e3',
            'e7e6',
            'g1f3',
            'f8e7',
            'f1d3',
            'b7b6',
            'b1d2',
            'c8b7',
            'e1g1',
          ],
        ],
      ),
  ];
  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
    const Size(412, 917),
  ]) {
    for (final id in [
      ...fixtures.map((f) => f['id'] as String),
      'AberturaParteInicio',
      'AberturaParteErrou',
      'AberturaTrecho',
      'AberturaTrechoRevendo',
      'AberturaParteFim',
      'AberturaTreinoConcluido',
      'FimSegue',
      'FimReforco',
      'FimRefazer',
      'FimRefazerReforco',
    ]) {
      testWidgets('static Canvas fixture $id $size', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 52, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 52, bottom: 24);
        addTearDown(tester.view.reset);
        final shadows = debugDisableShadows;
        debugDisableShadows = false;
        try {
          final voice = SpeechCubit(
            FakeVoiceRepository(settings: const VoiceSettings(enabled: true)),
          );
          await voice.load();
          addTearDown(voice.close);
          final settings = SettingsCubit(
            FakeSettingsRepository(),
            languages: AppLanguage.selectable,
          );
          await settings.load();
          addTearDown(settings.close);
          final repo = FakeTrainingRepository()
            ..beforeResources = Completer<void>().future;
          addTearDown(repo.dispose);
          final now = FakeNow(DateTime(2026, 10, 29, 12));
          late Widget screen;
          final opening = id.startsWith('Abertura');
          final ended = id.startsWith('Fim');
          if (ended) {
            final firm = id == 'FimSegue';
            final reinforce = id == 'FimReforco';
            final after = id == 'FimRefazerReforco';
            final correct = firm
                ? [true, true, true, true, false, true, true]
                : reinforce
                ? [true, true, false, true, true, false, true]
                : [true, false, true, true, false, true, false];
            final stars = firm
                ? [1, 1, 2, 2, 3, 2, 3]
                : reinforce
                ? [1, 1, 2, 1, 2, 2, 2]
                : [1, 1, 1, 1, 1, 1, 1];
            final cycle = ThemeCycle(
              lessonId: 'fixture',
              startedOn: '2026-10-23',
              phase: firm
                  ? ThemePhase.firm
                  : reinforce
                  ? ThemePhase.reinforce
                  : ThemePhase.redo,
              reinforcement: [for (var i = 0; i < 7; i++) 'remaining$i'],
              days: [
                for (var i = 0; i < 7; i++)
                  ThemeDay(
                    date: '2026-10-${23 + i}',
                    exerciseId: 'e$i',
                    stars: stars[i],
                    correct: correct[i],
                    phase: after ? ThemePhase.reinforce : ThemePhase.cycle,
                  ),
              ],
            );
            screen = TrainingExerciseScreen(
              repository: repo,
              config: TrainingCourseConfig.pilares,
              now: now,
              goalKey: 'fixture',
              title: firm ? 'Peça solta' : 'Ataque duplo',
              teacher: teacher,
              onNextGoal: () {},
              onRedoLesson: (_) {},
              preview: TrainingExerciseState(
                phase: TrainingExercisePhase.end,
                goal: TrainingGoal(
                  kind: after ? GoalKind.reinforce : GoalKind.exercise,
                  ref: 'fixture',
                  itemId: 'fixture',
                ),
                cycle: cycle,
                reinforcement: after,
              ),
            );
          } else if (!opening) {
            final f = fixtures.singleWhere((f) => f['id'] == id);
            final board = f['board'] as Map<String, dynamic>;
            final second = [
              'ExercicioLance2',
              'ExercicioErrouLance2',
              'SolucaoSegue',
            ].contains(id);
            final done = [
              'ExercicioAcertouDica',
              'Acertou',
              'SolucaoFim',
            ].contains(id);
            final wrong = ['ExercicioErrouLance2', 'Errou'].contains(id);
            final alternate = [
              'ExercicioRetry',
              'Errou',
              'Solucao',
              'SolucaoSegue',
              'SolucaoFim',
            ].contains(id);
            final exercise = TrainingExercise(
              id: id,
              stars: 2,
              fen: alternate ? retry : original,
              solution: alternate ? retryLine : line,
            );
            PlayTrainingExercise(
              exercise,
            ); // Validate the supplied line mechanically.
            expect(GameRules.fromFen(board['fen'] as String), isNotNull);
            screen = TrainingExerciseScreen(
              repository: repo,
              config: TrainingCourseConfig.pilares,
              now: now,
              goalKey: 'fixture',
              title: 'Garfo de cavalo',
              teacher: teacher,
              onNextGoal: () {},
              onRedoLesson: (_) {},
              previewSpeech: f['speech'] as String,
              preview: TrainingExerciseState(
                phase: done || wrong
                    ? TrainingExercisePhase.result
                    : TrainingExercisePhase.playing,
                exercise: exercise,
                goal: TrainingGoal(
                  kind: GoalKind.exercise,
                  ref: 'fixture',
                  itemId: id,
                ),
                cycle: ThemeCycle(lessonId: 'fixture', startedOn: '2026-10-28'),
                fen: board['fen'] as String,
                lastMove: board['last-move'] as String?,
                cursor: done
                    ? 3
                    : second
                    ? 2
                    : 0,
                correct: done,
                hint: ['ExercicioDica', 'ExercicioAcertouDica'].contains(id),
                practicing: id.startsWith('Solucao') || id == 'ExercicioRetry',
                practiceCorrect: done,
                solving: id.startsWith('Solucao'),
                errorSnapshot: !(wrong || id == 'ExercicioRetry')
                    ? null
                    : TrainingExerciseError(
                        fen: alternate ? retry : '5r1k/5Rb1/p2P2Pp/1p6/2p5/P4BnP/1pP3K1/5R2 b - - 4 33',
                        cursor: second ? 2 : 0,
                        wrongMove: alternate ? 'g3g2' : 'f8f7',
                      ),
              ),
            );
          } else {
            final finalPart = id == 'AberturaTreinoConcluido';
            final complete = finalPart || id == 'AberturaParteFim';
            final beginning = id == 'AberturaParteInicio';
            final reviewing = id == 'AberturaTrechoRevendo';
            final part = openingParts[finalPart ? 4 : 1];
            final progress = OpeningTrack(
              lessonId: 'london',
              startedOn: '2026-10-28',
              doneTrechos: {
                if (complete) part.id: '2026-10-29',
                if (finalPart)
                  for (final p in openingParts) p.id: '2026-10-29',
              },
            );
            screen = TrainingOpeningScreen(
              repository: repo,
              config: TrainingCourseConfig.pilares,
              now: now,
              lessonId: 'london',
              teacher: teacher,
              onNextGoal: () {},
              onProgress: () {},
              preview: TrainingOpeningState(
                phase: complete
                    ? TrainingOpeningPhase.complete
                    : TrainingOpeningPhase.playing,
                lessonId: 'london',
                line: PlayTrainingOpening(part),
                cursor: beginning
                    ? 0
                    : complete
                    ? 13
                    : 12,
                shown: beginning
                    ? 0
                    : reviewing
                    ? 5
                    : complete
                    ? 13
                    : 12,
                wrong: id == 'AberturaParteErrou',
                firstTry: beginning ? const [] : const [true],
                saved: TrainingState(
                  course: TrainingCourse.pilares,
                  installSeed: 'fixture',
                  openings: {'london': progress},
                ),
                resources: TrainingResources(
                  openings: {'london': openingParts},
                ),
              ),
            );
          }
          await tester.pumpWidget(
            RepaintBoundary(
              child: TestApp(
                locale: const Locale('pt'),
                settingsCubit: settings,
                speechCubit: voice,
                child: screen,
              ),
            ),
          );
          await tester.pump();
          await tester.runAsync(() async {
            await ChessgroundImages.instance.loadAll(
              PieceStyle.cburnett.assets,
              devicePixelRatio: 1,
            );
            await precacheImage(
              AssetImage(teacher.imageFor(null)),
              tester.element(
                find.byKey(
                  opening
                      ? TrainingKeys.openingScreen
                      : ended
                      ? TrainingKeys.exerciseEnd
                      : TrainingKeys.exerciseScreen,
                ),
              ),
            );
          });
          await tester.pump(const Duration(seconds: 1));

          final boardKey = opening
              ? TrainingKeys.openingBoard
              : TrainingKeys.exerciseBoard;
          if (ended) {
            expect(find.byKey(TrainingKeys.exerciseEnd), findsOneWidget);
          } else {
            expect(find.byKey(boardKey), findsOneWidget);
            expectCanvasBlock(tester, size, boardKey);
          }
          expect(tester.takeException(), isNull);
          Future<void> saveMetrics(String name) async {
            if (Platform.environment['T85_METRICS'] != '1') return;
            final records = <Map<String, Object?>>[];
            for (final element in tester.elementList(find.byType(RichText))) {
              final rich = element.widget as RichText;
              final box = tester.getRect(find.byWidget(rich));
              final style = rich.text.style;
              records.add({
                'text': rich.text.toPlainText(),
                'rect': [box.left, box.top, box.width, box.height],
                'font': style?.fontFamily,
                'size': style?.fontSize,
                'line': style?.height,
                'spacing': style?.letterSpacing,
                'leading': style?.leadingDistribution?.name,
                'heightBehavior': rich.textHeightBehavior?.toString(),
                'strut': rich.strutStyle?.toString(),
              });
            }
            await tester.runAsync(() async {
              final output = File(
                '/tmp/t85-app-metrics/${name}_${size.width.toInt()}x${size.height.toInt()}.json',
              );
              await output.parent.create(recursive: true);
              await output.writeAsString(jsonEncode(records));
            });
          }

          await saveMetrics(id);
          Future<void> capture(String name) async {
            if (Platform.environment['T85_CAPTURE'] != '1') return;
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byType(RepaintBoundary).first,
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '/tmp/t85-treino-png/${size.width.toInt()}x${size.height.toInt()}/$name.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }

          await capture(id);
          if (id == 'Errou') {
            // Static preview intentionally blocks input until repository load.
            // Invoke its real sheet callback; this is visual evidence only.
            tester
                .widget<SpeechBalloon>(find.byKey(LessonScriptKeys.speech))
                .onTap!();
            await tester.pumpAndSettle();
            expect(
              find.byKey(LessonScriptKeys.speechSheetClose),
              findsOneWidget,
            );
            await capture('ErrouExpandido');
            await saveMetrics('ErrouExpandido');
            await tester.tap(find.byKey(LessonScriptKeys.speechSheetClose));
            await tester.pumpAndSettle();
          }
          await tester.pumpWidget(const SizedBox());
        } finally {
          debugDisableShadows = shadows;
        }
      });
    }
  }
}
