import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/free_board_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

// Falta só Dxf7 para o mate do pastor.
const _beforeMate =
    'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4';

/// Fumaça do tabuleiro livre: tema escuro, árabe, segundo plano e textos longos.
void main() {
  patrolTest('tabuleiro livre em tema escuro', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await board.open();
    await board.move('e2', 'e4');

    app.expectBrightness(Brightness.dark);
    await board.expectMoves(['e4']);
  });

  patrolTest('tabuleiro livre em árabe: a interface espelha, o tabuleiro não', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await board.open();
    app.expectDirection(TextDirection.rtl);
    board.expectTurn('الدور للأبيض');

    // e2-e4 só é legal se a coluna "a" continuar à esquerda.
    await board.move('e2', 'e4');
    await board.move('e7', 'e5');
    await board.move('g1', 'f3');

    await board.expectMoves(['e4', 'e5', 'Nf3']);
    app.expectNoClippedText();
  });

  patrolTest('tabuleiro livre volta do segundo plano com a mesma partida', (
    $,
  ) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await board.open();
    await board.move('e2', 'e4');
    await board.move('e7', 'e5');

    await app.sendToBackgroundAndReturn();

    await board.expectVisible();
    await board.expectMoves(['e4', 'e5']);
    board.expectFen(
      'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
    );
  });

  patrolTest('pseudo-idioma longo: nada cortado no tabuleiro nem no fim', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await home.openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.back();
    await settings.back();
    await home.expectVisible();
    app.expectNoClippedText();

    await board.openAt(_beforeMate);
    app.expectNoClippedText();

    await board.move('h5', 'f7');
    await board.expectEnd(
      reason: '[Çhéçkmåté one]',
      result: '[Whîté wîñš one]',
    );
    app.expectNoClippedText();
  });
}
