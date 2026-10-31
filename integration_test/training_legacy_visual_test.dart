import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_character_repository.dart';
import '../testing/fakes/fake_endgame_repositories.dart';
import '../testing/fakes/fake_now.dart';
import '../testing/fakes/fake_settings_repository.dart';
import '../testing/test_app.dart';

/// Native component regression fixture, not a substitute for acceptance flows.
/// Run the identical fixture against .3 and .4 with LEGACY_PHASE=before|after.
void main() {
  patrolTest('T85 rodapé legado antes e depois', ($) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    addTearDown(settings.close);
    final cubit = ExerciseCubit(
      now: FakeNow(DateTime(2026, 10, 26, 12)),
      lessons: FakeEndgameLessonRepository(
        texts: LessonTexts.fromJson({'rook.lucena.title': 'Posição de Lucena'}),
      ),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'e01', 'pt');
    await $.pumpWidgetAndSettle(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    await $(ExerciseKeys.board).waitUntilVisible();
    Future<void> shot(String state) async {
      final view = $.tester.view;
      final size = view.physicalSize / view.devicePixelRatio;
      const phase = String.fromEnvironment(
        'LEGACY_PHASE',
        defaultValue: 'after',
      );
      final name =
          'legacy-$phase-$state-${size.width.round()}x${size.height.round()}';
      await $.tester.runAsync(() async {
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse('http://10.0.2.2:8792/shot/$name'),
          );
          final response = await request.close();
          if (response.statusCode != 200) {
            throw StateError('Native capture failed');
          }
          await response.drain<void>();
        } finally {
          client.close(force: true);
        }
      });
    }

    await shot('playing');
    await cubit.play(Move.parse('c1c4')!);
    await $.pumpAndSettle();
    await $(ExerciseKeys.nextButton).waitUntilVisible();
    await shot('result');
  });
}
