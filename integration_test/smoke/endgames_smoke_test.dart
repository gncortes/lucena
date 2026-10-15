import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/endgames_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

const _lessonId = 'mates.bishopKnight.w';

/// Fumaça das aulas de finais: tema escuro, árabe, pseudo-idioma longo e
/// segundo plano.
final _hidden = !VisibleLessons.endgameLessonIds.contains(_lessonId);

void main() {
  Future<void> walkThrough(PatrolIntegrationTester $, AppRobot app) async {
    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    app.expectNoClippedText();
    await endgames.openLesson(_lessonId);
    app.expectNoClippedText();
    await endgames.openInfo();
    app.expectNoClippedText();
    await endgames.back();
    final lesson = await endgames.lesson(_lessonId);
    await endgames.startExercises(_lessonId, lesson.exercises.first.id);
    app.expectNoClippedText();
    await endgames.back();
    await endgames.openSteps();
    app.expectNoClippedText();
  }

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('aulas de finais em tema escuro', ($) async {
    final app = AppRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    app.expectBrightness(Brightness.dark);
    await endgames.openLesson(_lessonId);
    app.expectBrightness(Brightness.dark);
  }, skip: _hidden);

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('aulas de finais em árabe, sem texto cortado', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await walkThrough($, app);
    app.expectDirection(TextDirection.rtl);
  }, skip: _hidden);

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('aulas de finais no pseudo-idioma longo', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.backToHome();

    await walkThrough($, app);
  }, skip: _hidden);

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('exercício e lição voltam do segundo plano onde estavam', (
    $,
  ) async {
    final app = AppRobot($);
    final endgames = EndgamesRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);
    final first = (await endgames.lesson(_lessonId)).exercises.first;
    await endgames.startExercises(_lessonId, first.id);
    await endgames.exerciseMove(first.line.first.accept.first);

    await app.sendToBackgroundAndReturn();
    await endgames.expectExercise(_lessonId, first.id);
    endgames.expectExerciseBoard('k1N5/2K5/8/8/8/8/8/5B2 w - - 2 2');

    await endgames.back();
    await endgames.openSteps();
    await endgames.nextStep();
    await app.sendToBackgroundAndReturn();
    // O passo de pensar e, com "Ver explicação", a explicação dele.
    await endgames.expectStep(_lessonId, 'corner');
  }, skip: _hidden);
}
