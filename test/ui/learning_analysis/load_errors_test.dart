import 'package:flutter/material.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analysis/learning_analysis_repository.dart';
import 'package:lucena/domain/models/learning_analysis.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/learning_analysis/view_models/learning_analysis_cubit.dart';
import 'package:lucena/ui/learning_analysis/widgets/learning_analysis_screen.dart';

import '../../../testing/test_app.dart';
import 'analysis_test_support.dart';

class FailingReadPreferences extends AnalysisMemoryPreferences {
  bool readFails = true;
  @override
  Future<String?> getString(String key) async {
    if (readFails) throw StateError('read failed');
    return super.getString(key);
  }
}

void main() {
  testWidgets('analysis load failure offers retry before using the board', (
    tester,
  ) async {
    initializeAnalysisPreferences();
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    addTearDown(settings.close);
    final disk = FailingReadPreferences();
    final cubit = LearningAnalysisCubit(
      launch: const LearningAnalysisLaunch(
        fen: '8/8/8/8/8/4k3/8/4K3 w - - 0 1',
      ),
      repository: LearningAnalysisRepository(disk),
      engine: ControlledAnalysisEngine(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: const LearningAnalysisScreen(),
        ),
      ),
    );
    expect(find.byType(LoadErrorScreen), findsOneWidget);
    disk.readFails = false;
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pumpAndSettle();
    expect(cubit.state.ready, isTrue);
    expect(find.byType(LoadErrorScreen), findsNothing);
  });
}
