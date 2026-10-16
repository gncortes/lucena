import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:patrol/patrol.dart';

import 'home_robot.dart';

/// A Escola do Viktor: a trilha e as aulas (todas na tela roteirizada).
class SchoolRobot {
  const SchoolRobot(this.$);

  final PatrolIntegrationTester $;

  /// Da tela inicial, pelo botão das aulas.
  Future<void> openFromHome() async {
    await tapHomePath($, HomeKeys.schoolButton);
    await expectTrail();
  }

  Future<void> expectTrail() async {
    await $(SchoolKeys.screen).waitUntilVisible();
  }

  /// Abre uma aula do curso: a rota leva à tela roteirizada (T70/T71).
  Future<void> openScriptLesson(String id) async {
    await _tapLesson(id);
    await $(LessonScriptKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> _tapLesson(String id) async {
    // A trilha é longa: a aula vai para o meio da tela, longe do botão fixo
    // de baixo, antes do toque.
    final lesson = find.byKey(SchoolKeys.lesson(id));
    await $.scrollUntilExists(finder: lesson, maxScrolls: 80);
    await Scrollable.ensureVisible($.tester.element(lesson), alignment: 0.5);
    await $.pumpAndSettle();
    await $(lesson).tap();
  }

  /// O balão do Viktor na tela roteirizada: sem ✕ nele; o toque abre a fala
  /// inteira numa folha (T72), que fecha pelo ✕ dela.
  Future<void> expectScriptSpeechSheet() async {
    final balloon = find.byKey(LessonScriptKeys.speech);
    await $(balloon).waitUntilVisible();
    expect(
      find.descendant(of: balloon, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    await $.tester.tap(balloon);
    await $.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
    await $(LessonScriptKeys.speechSheetClose).tap();
    await $.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
  }

  /// "Continuar" da tela roteirizada.
  Future<void> scriptContinue() async {
    await $(LessonScriptKeys.primary).tap();
    await $.pumpAndSettle();
  }
}
