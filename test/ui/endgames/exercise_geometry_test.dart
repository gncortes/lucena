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

import '../../../testing/board_center.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// Retângulos do exercício no canvas aprovado (variante A): balão, tabuleiro,
/// lâmpada e cronômetro, em fonte 1,0 e tema claro.
void main() {
  Future<void> pump(WidgetTester tester, {String language = 'en'}) async {
    final cubit = ExerciseCubit(
      now: FakeNow(DateTime.utc(2026, 10, 11)),
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(const EndgameProgress()),
      characters: FakeCharacterRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'e03', language);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: Locale(language),
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  // A8: hoje 68,75 dp abaixo do centro útil. O exercício usa a ScriptPage da
  // lição (área do balão do Viktor + faixa colados em cima do tabuleiro,
  // Gabriel 14/10/2026): centrar muda o componente da lição. Aguarda decisão.
  testWidgetsA8('A8: tabuleiro no centro útil e de ponta a ponta', (
    tester,
  ) async {
    setCentroAparelho(tester);
    await pump(tester, language: 'pt');
    debugPrint('A8 exercise fora do centro: ${foraDoCentro(tester)}');
    expectTabuleiroNoCentro(tester);
  });

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
  Size(360, 740): '0.0,190.0,360.0,360.0 | 12.0,91.0,336.0,57.0 | 16.0,668.0,56.0,56.0 | 251.6,682.0,92.4,28.0',
  Size(412, 917): '0.0,252.5,412.0,412.0 | 12.0,148.5,388.0,57.0 | 16.0,845.0,56.0,56.0 | 303.6,859.0,92.4,28.0',
};
