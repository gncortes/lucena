import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// Retângulos do exercício no canvas aprovado (variante A): balão, tabuleiro,
/// lâmpada e cronômetro, em fonte 1,0 e tema claro.
void main() {
  Future<void> pump(WidgetTester tester) async {
    final cubit = ExerciseCubit(
      now: FakeNow(DateTime.utc(2026, 10, 11)),
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(const EndgameProgress()),
      characters: FakeCharacterRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'e03', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  const sizes = <Size>[Size(360, 740), Size(412, 917)];
  for (final size in sizes) {
    testWidgets('geometria $size: balão, tabuleiro, dica e cronômetro', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester);
      String r(Key key) {
        final rect = tester.getRect(find.byKey(key));
        return '${rect.left.toStringAsFixed(1)},${rect.top.toStringAsFixed(1)},'
            '${rect.width.toStringAsFixed(1)},${rect.height.toStringAsFixed(1)}';
      }

      final got = [
        r(ExerciseKeys.board),
        r(LessonScriptKeys.speech),
        r(ExerciseKeys.hintButton),
        r(ExerciseKeys.timer),
      ].join(' | ');
      expect(got, _expected[size]);
    });
  }
}

final _expected = <Size, String>{
  Size(360, 740): '0.0,254.8,360.0,360.0 | 12.0,150.8,336.0,57.0 | 16.0,668.0,56.0,56.0 | 251.6,682.0,92.4,28.0',
  Size(412, 917): '0.0,317.3,412.0,412.0 | 12.0,213.3,388.0,57.0 | 16.0,845.0,56.0,56.0 | 303.6,859.0,92.4,28.0',
};
