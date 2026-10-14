import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T70 lote 4: o `ExerciseFrame` extraído não mexe um pixel na tela de
/// exercício. Os retângulos abaixo foram medidos ANTES da extração.
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
    testWidgets('geometria $size: tabuleiro, meta e dica', (tester) async {
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
        r(ExerciseKeys.goal),
        r(ExerciseKeys.hintButton),
        r(ExerciseKeys.timer),
      ].join(' | ');
      expect(got, _expected[size]);
    });
  }
}

final _expected = <Size, String>{
  Size(360, 740): '8.0,198.0,344.0,344.0 | 16.0,550.0,328.0,48.0 | 16.0,676.0,227.4,48.0 | 255.4,688.0,88.6,24.0',
  Size(412, 917): '8.0,260.5,396.0,396.0 | 16.0,664.5,380.0,24.0 | 16.0,853.0,279.4,48.0 | 307.4,865.0,88.6,24.0',
};
