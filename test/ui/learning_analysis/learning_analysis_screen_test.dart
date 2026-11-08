import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analysis/learning_analysis_repository.dart';
import 'package:lucena/domain/models/learning_analysis.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/core/keys/learning_analysis_keys.dart';
import 'package:lucena/ui/learning_analysis/view_models/learning_analysis_cubit.dart';
import 'package:lucena/ui/learning_analysis/widgets/learning_analysis_screen.dart';

import '../../../testing/test_app.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import 'analysis_test_support.dart';

const analysisRoot = '6rk/7p/1p1pN2P/3P1P2/p1Q1P3/Pn4q1/1PB5/1K5R b - - 0 35';
const analysisMoves = ['b3d2', 'b1a2', 'd2c4'];

void main() {
  setUp(initializeAnalysisPreferences);
  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    testWidgets(
      'analysis controls and legal board at $size with three engine lines',
      (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size
          ..padding = const FakeViewPadding(top: 32, bottom: 24)
          ..viewPadding = const FakeViewPadding(top: 32, bottom: 24);
        addTearDown(tester.view.reset);
        final cubit = LearningAnalysisCubit(
          launch: const LearningAnalysisLaunch(
            fen: analysisRoot,
            moves: analysisMoves,
          ),
          repository: LearningAnalysisRepository(AnalysisMemoryPreferences()),
          engine: ControlledAnalysisEngine(),
        );
        await cubit.load();
        await cubit.confirmSettings(const LearningAnalysisSettings(lines: 3));
        addTearDown(cubit.close);
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            settingsCubit: settings,
            child: BlocProvider.value(
              value: cubit,
              child: const LearningAnalysisScreen(),
            ),
          ),
        );
        await tester.pump();
        final board = tester.getRect(find.byKey(LearningAnalysisKeys.board));
        expect(board.width, size.width);
        expect(board.height, size.width);
        expect(
          tester.getRect(find.byKey(LearningAnalysisKeys.first)).bottom,
          lessThanOrEqualTo(size.height - 24),
        );
        await tester.tap(find.byKey(LearningAnalysisKeys.first));
        await tester.pump();
        expect(cubit.state.session.selected, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'cancelled settings do not apply; confirm persists engine visibility and line count',
    (tester) async {
      final repository = LearningAnalysisRepository(
        AnalysisMemoryPreferences(),
      );
      final cubit = LearningAnalysisCubit(
        launch: const LearningAnalysisLaunch(
          fen: analysisRoot,
          moves: analysisMoves,
        ),
        repository: repository,
        engine: ControlledAnalysisEngine(),
      );
      await cubit.load();
      addTearDown(cubit.close);
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      await settings.load();
      addTearDown(settings.close);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: BlocProvider.value(
            value: cubit,
            child: const LearningAnalysisScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(LearningAnalysisKeys.board), findsOneWidget);
      await tester.tap(find.byKey(LearningAnalysisKeys.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LearningAnalysisKeys.showEngine));
      await tester.tap(find.text('3'));
      await tester.tap(find.byKey(LearningAnalysisKeys.close));
      await tester.pumpAndSettle();
      expect(cubit.state.settings.showEngine, isTrue);
      expect(cubit.state.settings.lines, 2);
      await tester.tap(find.byKey(LearningAnalysisKeys.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LearningAnalysisKeys.showEngine));
      await tester.tap(find.text('3'));
      await tester.tap(find.byKey(LearningAnalysisKeys.confirm));
      await tester.pumpAndSettle();
      expect(find.byKey(LearningAnalysisKeys.engine), findsNothing);
      expect(find.byKey(LearningAnalysisKeys.evaluation), findsNothing);
      expect(cubit.state.settings.showEngine, isFalse);
      expect((await repository.settings()).lines, 3);
      await tester.tap(find.byKey(LearningAnalysisKeys.first));
      await tester.pump();
      expect(cubit.state.session.selected, 0);
      await tester.tap(find.byKey(LearningAnalysisKeys.last));
      await tester.pump();
      expect(cubit.state.session.selected, 3);
      expect(tester.takeException(), isNull);
    },
  );
}
