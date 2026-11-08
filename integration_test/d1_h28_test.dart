import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/training_capture_robot.dart';

/// H-28 da frente T85-D1: vídeo da Sequência com hoje cumprido. Os ✓ dos
/// dias anteriores saem em onda, o anel de hoje fecha, o ✓ de hoje salta e
/// o contador sobe de 3 para 4.
void main() {
  patrolTest('H-28: a meta de hoje fecha na faixa da semana', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    // Quatro dias seguidos até hoje (pelo relógio do cenário), gravados como
    // o app grava.
    final hoje = e2eNow();
    final dias = [
      for (var i = 3; i >= 0; i--)
        DateTime(hoje.year, hoje.month, hoje.day - i),
    ];
    String dia(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    await $.tester.runAsync(
      () => PreferencesService().setString(
        'activity.days',
        jsonEncode([for (final d in dias) dia(d)]),
      ),
    );
    await app.restart();
    await $(HomeKeys.screen).waitUntilVisible();

    final capture = TrainingCaptureRobot($);
    await capture.begin('h28-sequencia');
    GoRouter.of($.tester.element(find.byKey(HomeKeys.screen)))
        .go(Routes.streak);
    await $(StreakKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
    await $.tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await capture.end('h28-sequencia', ready: StreakKeys.screen);
    await capture.shot('h28-sequencia', ready: StreakKeys.screen);
  }, tags: ['d1-h28']);
}
