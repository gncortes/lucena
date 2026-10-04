import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/board_appearance_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/settings_robot.dart';

void main() {
  patrolTest('trocar as peças: a amostra muda e a escolha volta ao reabrir', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    final appearance = BoardAppearanceRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await home.openSettings();
    await appearance.open();
    appearance.expectPreview(
      colors: BoardColors.blue,
      pieces: PieceStyle.cburnett,
      coordinates: true,
    );

    await appearance.choosePieces(PieceStyle.merida);
    appearance.expectPreview(
      colors: BoardColors.blue,
      pieces: PieceStyle.merida,
      coordinates: true,
    );

    await app.restart();
    await home.openSettings();
    await settings.expectBoardAppearanceValue('Blue · Merida');
    await appearance.open();
    appearance.expectPreview(
      colors: BoardColors.blue,
      pieces: PieceStyle.merida,
      coordinates: true,
    );
  });

  patrolTest('trocar as cores do tabuleiro: a escolha volta ao reabrir', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final appearance = BoardAppearanceRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await home.openSettings();
    await appearance.open();

    await appearance.chooseColors(BoardColors.green);
    appearance.expectPreview(
      colors: BoardColors.green,
      pieces: PieceStyle.cburnett,
      coordinates: true,
    );

    await app.restart();
    await board.open();
    board.expectAppearance(
      colors: BoardColors.green,
      pieces: PieceStyle.cburnett,
      coordinates: true,
    );
  });

  patrolTest('desligar as coordenadas: somem também do tabuleiro de jogo', (
    $,
  ) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    final appearance = BoardAppearanceRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await home.openSettings();
    await appearance.open();

    await appearance.toggleCoordinates();
    appearance.expectPreview(
      colors: BoardColors.blue,
      pieces: PieceStyle.cburnett,
      coordinates: false,
    );

    await settings.back();
    await settings.back();
    await board.open();
    board.expectAppearance(
      colors: BoardColors.blue,
      pieces: PieceStyle.cburnett,
      coordinates: false,
    );
  });

  patrolTest(
    'restaurar padrão: cores, peças e coordenadas voltam ao original',
    ($) async {
      final app = AppRobot($);
      final home = HomeRobot($);
      final settings = SettingsRobot($);
      final appearance = BoardAppearanceRobot($);
      await app.open(systemLocale: const Locale('en', 'US'));
      await home.openSettings();
      await appearance.open();
      await appearance.chooseColors(BoardColors.purple);
      await appearance.choosePieces(PieceStyle.pixel);
      await appearance.toggleCoordinates();
      appearance.expectPreview(
        colors: BoardColors.purple,
        pieces: PieceStyle.pixel,
        coordinates: false,
      );

      await appearance.restoreDefault();
      appearance.expectPreview(
        colors: BoardColors.blue,
        pieces: PieceStyle.cburnett,
        coordinates: true,
      );

      await app.restart();
      await home.openSettings();
      await settings.expectBoardAppearanceValue('Blue · Cburnett');
    },
  );
}
