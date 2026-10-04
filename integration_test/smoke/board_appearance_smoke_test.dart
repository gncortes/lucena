import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/board_appearance_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

/// Fumaça da aparência do tabuleiro: tema escuro, árabe, segundo plano e
/// textos longos.
void main() {
  patrolTest('aparência do tabuleiro em tema escuro', ($) async {
    final app = AppRobot($);
    final appearance = BoardAppearanceRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await HomeRobot($).openSettings();
    await appearance.open();

    app.expectBrightness(Brightness.dark);
    await appearance.choosePieces(PieceStyle.chessnut);
    appearance.expectPreview(
      colors: BoardColors.blue,
      pieces: PieceStyle.chessnut,
      coordinates: true,
    );
  });

  patrolTest('aparência do tabuleiro em árabe: a amostra não espelha', (
    $,
  ) async {
    final app = AppRobot($);
    final appearance = BoardAppearanceRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await HomeRobot($).openSettings();
    await appearance.open();

    app.expectDirection(TextDirection.rtl);
    appearance.expectPreviewNotMirrored();
    app.expectNoClippedText();
  });

  patrolTest('aparência do tabuleiro volta do segundo plano com a escolha', (
    $,
  ) async {
    final app = AppRobot($);
    final appearance = BoardAppearanceRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await appearance.open();
    await appearance.chooseColors(BoardColors.brown);

    await app.sendToBackgroundAndReturn();

    await appearance.expectVisible();
    appearance.expectPreview(
      colors: BoardColors.brown,
      pieces: PieceStyle.cburnett,
      coordinates: true,
    );
  });

  patrolTest('pseudo-idioma longo: nada cortado na aparência do tabuleiro', (
    $,
  ) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    final appearance = BoardAppearanceRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.back();
    app.expectNoClippedText();

    await appearance.open();
    app.expectNoClippedText();
  });
}
