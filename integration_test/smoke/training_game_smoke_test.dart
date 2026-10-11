import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/conclusion_robot.dart';
import '../robots/free_board_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

const _queenMate = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

/// Fumaça da partida de treino contra a máquina (desistir e resultado): tema
/// escuro, árabe e textos longos. Segundo plano e fechar o app estão em
/// background_machine_test.dart.
void main() {
  Future<void> start(FreeBoardRobot board) => board.openAt(
    _queenMate,
    opponent: 'stockfish',
    user: Side.white,
    goal: 'win',
    position: 'basic.queen.0001',
  );

  patrolTest('treino contra a máquina em tema escuro', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));
    await start(board);

    await board.move('c1', 'g5');
    await board.resign();

    await ConclusionRobot($).expectGoal('Goal not achieved');
    app.expectBrightness(Brightness.dark);
  });

  patrolTest('treino contra a máquina em árabe: nada cortado', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('ar'));
    await start(board);
    app.expectDirection(TextDirection.rtl);
    app.expectNoClippedText();

    await board.resign();

    await ConclusionRobot($).expectGoal('لم يتحقّق الهدف');
    app.expectNoClippedText();
  });

  patrolTest('pseudo-idioma longo: nada cortado no treino', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.backToHome();
    await HomeRobot($).expectVisible();

    await start(board);
    app.expectNoClippedText();
    await board.resign();
    await ConclusionRobot($).waitConclusion();
    app.expectNoClippedText();
  });
}
