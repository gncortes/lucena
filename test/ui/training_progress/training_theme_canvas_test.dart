import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart'
    show ChessgroundImages, StaticChessboard;
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/play_training_exercise.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_navigation_bar.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/training_progress/widgets/training_theme_screen.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  final reference = Platform.environment['T85_REFERENCE'] == '1';
  // Reference-only history thumbnails come from the actual artboard. These
  // mock records do not claim playable/approved content; the ordinary run below
  // keeps the legal bank and checks practice callbacks and absent old timings.
  final referenceFens = reference
      ? ((jsonDecode(
                  File('docs/qa/T85-integral/artboard-snapshots.json')
                      .readAsStringSync(),
                ) as List).cast<Map<String, dynamic>>().firstWhere(
                  (row) => row['id'] == 'ProgressoTema',
                )['imports']
                as List)
            .cast<Map<String, dynamic>>()
            .where((row) => row['name'] == 'CompTabuleiro')
            .map((row) => row['fen'] as String)
            .toList()
      : <String>[];
  // Existing exercise/line from training_canvas_states_test: this fixture checks
  // a real bank relationship and layout; it does not certify teaching content.
  final bank = [
    for (var i = 0; i < 7; i++)
      TrainingExercise(
        id: 'e$i',
        stars: [1, 1, 2, 1, 2, 3, 2][i],
        fen: reference
            ? referenceFens[i]
            : '5r1k/5Rb1/p2P2Pp/1p5n/2p5/P4B1P/1pP5/5R1K b - - 2 32',
        solution: reference ? const [] : const ['h5g3', 'h1g2', 'g3f1'],
        mock: reference,
      ),
  ];
  final days = [
    for (var i = 0; i < 7; i++)
      ThemeDay(
        date: '2026-10-${20 + i}',
        exerciseId: bank[i].id,
        stars: bank[i].stars,
        correct: i != 2 && i != 5,
        elapsedMs: !reference && i == 6
            ? null
            : [21, 34, 102, 28, 55, 130, 65][i] * 1000,
      ),
  ];
  for (final e in reference ? <TrainingExercise>[] : bank) {
    PlayTrainingExercise(e);
  }
  for (final size in [
    const Size(412, 917),
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    testWidgets('theme Canvas list, bank and practice actions $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 52, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 52, bottom: 24);
      addTearDown(tester.view.reset);
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      await settings.load();
      addTearDown(settings.close);
      final repo = FakeTrainingRepository(
        content: {
          TrainingCourse.pilares: TrainingResources(
            lessons: const [
              TrainingLesson(
                id: 'theme',
                kind: TrainingLessonKind.theme,
                title: 'Ataque duplo da dama e das outras peças',
              ),
            ],
            banks: {'theme': bank},
          ),
        },
        states: {
          TrainingCourse.pilares: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'theme-canvas',
            tab: CourseGuideTab.progress,
            cycles: {
              'theme': ThemeCycle(
                lessonId: 'theme',
                startedOn: '2026-10-20',
                phase: ThemePhase.reinforce,
                reinforcement: const ['r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7'],
                days: days,
              ),
            },
          ),
        },
      );
      addTearDown(repo.dispose);
      final cubit = CourseGuideCubit(
        repository: repo,
        config: TrainingCourseConfig.pilares,
        now: FakeNow(DateTime(2026, 10, 28)),
      );
      await cubit.load();
      addTearDown(cubit.close);
      TrainingExercise? selected;
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: BlocProvider.value(
            value: cubit,
            child: RepaintBoundary(
              child: Scaffold(
                appBar: LucenaAppBar(
                  title: const Text('Domínio do tema'),
                  toolbarHeight: 64,
                  leading: BackButton(onPressed: () {}),
                ),
                bottomNavigationBar: CourseNavigationBar(
                  selectedIndex: 2,
                  remaining: 4,
                  onDestinationSelected: (_) {},
                ),
                body: TrainingThemeScreen(
                  lessonId: 'theme',
                  onBack: () {},
                  embedded: true,
                  onExercise: (e) => selected = e,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => ChessgroundImages.instance.loadAll(
          PieceStyle.cburnett.assets,
          devicePixelRatio: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('47 %'), findsOneWidget);
      expect(find.text('Exercícios feitos'), findsOneWidget);
      final chart = tester.getRect(find.byKey(TrainingKeys.themeChart));
      expect(chart.height, 168);
      expect(chart.width, size.width - 64);
      final legend = tester.getRect(find.byKey(TrainingKeys.themeLegend));
      expect(legend.height, 38);
      final first = tester.widget<StaticChessboard>(
        find.byType(StaticChessboard).first,
      );
      expect(first.fen, bank.first.fen);
      expect(first.orientation, Side.white);
      expect(first.size, 56);
      expect(find.text('Acertou · 0:21'), findsOneWidget);
      await _capture(tester, size, 'top');
      await tester.tap(find.byKey(TrainingKeys.themeExercise(0)));
      expect(
        identical(selected, cubit.state.resources!.banks['theme']!.first),
        true,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(TrainingKeys.themeRedo(2))),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TrainingKeys.themeRedo(2)));
      expect(selected?.id, 'e2');
      await tester.scrollUntilVisible(
        find.byKey(TrainingKeys.themeResult(6)),
        120,
        scrollable: find.descendant(
          of: find.byKey(TrainingKeys.themeScroll),
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        tester.widget<Text>(find.byKey(TrainingKeys.themeResult(6))).data,
        reference ? 'Acertou · 1:05' : 'Acertou',
      );
      await tester.pumpAndSettle();
      await _capture(tester, size, 'history');
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _capture(WidgetTester tester, Size size, String state) async {
  if (Platform.environment['T85_CAPTURE'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '/tmp/t85-theme-png/${size.width.toInt()}x${size.height.toInt()}/$state.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
