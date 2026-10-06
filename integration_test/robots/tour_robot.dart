import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// O tour da primeira abertura.
class TourRobot {
  const TourRobot(this.$);

  final PatrolIntegrationTester $;

  Future<void> expectStep(TourStep step) async {
    await $(TourKeys.step(step)).waitUntilVisible();
  }

  void expectNotOpen() => expect(find.byKey(TourKeys.screen), findsNothing);

  Future<void> next() async {
    await $(TourKeys.nextButton).tap();
    await $.pumpAndSettle();
  }

  /// No primeiro passo: escreve o nome do jogador.
  Future<void> enterName(String name) async {
    await $(TourKeys.nameField).scrollTo().enterText(name);
    await $.pumpAndSettle();
  }

  /// O nome que está no campo do primeiro passo.
  Future<void> expectName(String name) async {
    await $(TourKeys.nameField).scrollTo();
    expect(
      $.tester
          .widget<TextField>(find.byKey(TourKeys.nameField))
          .controller!
          .text,
      name,
    );
  }

  Future<void> back() async {
    await $(TourKeys.backButton).tap();
    await $.pumpAndSettle();
  }

  /// Avança até o passo do nível.
  Future<void> nextUntilLevel() async {
    while (find.byKey(TourKeys.step(TourStep.level)).evaluate().isEmpty) {
      await next();
    }
  }

  /// No passo do som: com som ou sem som.
  Future<void> chooseSound({required bool enabled}) =>
      _tap(TourKeys.sound(enabled: enabled));

  /// No passo do tema: claro, escuro ou o do aparelho.
  Future<void> chooseThemeMode(AppThemeMode mode) =>
      _tap(TourKeys.themeMode(mode));

  /// No passo do tema: a cor do app.
  Future<void> chooseAccent(AppAccent accent) => _tap(TourKeys.accent(accent));

  /// O nome da cor do app marcada no passo do tema.
  void expectAccentValue(String text) {
    expectText(
      $.tester.widget<Text>(find.byKey(TourKeys.accentValue)).data,
      text,
    );
  }

  /// No passo do tabuleiro: as cores e as peças.
  Future<void> chooseBoardColors(BoardColors colors) =>
      _tap(TourKeys.boardColors(colors));

  Future<void> chooseBoardPieces(PieceStyle pieces) =>
      _tap(TourKeys.boardPieces(pieces));

  /// O que o tabuleiro de amostra do passo do tabuleiro está mostrando.
  Future<void> expectBoardPreview({
    required BoardColors colors,
    required PieceStyle pieces,
  }) async {
    await $(TourKeys.boardPreview).scrollTo();
    final settings = $.tester
        .widget<StaticChessboard>(find.byKey(TourKeys.boardPreview))
        .settings;
    expect(settings.colorScheme, colors.scheme);
    expect(settings.pieceAssets, pieces.assets);
  }

  // As opções ficam numa lista que rola para baixo e em fileiras que rolam
  // para o lado: traz a opção para a tela antes de tocar.
  Future<void> _tap(Key key) async {
    await $(key).scrollTo();
    await $.tester.ensureVisible(find.byKey(key));
    await $.pumpAndSettle();
    await $(key).tap();
    await $.pumpAndSettle();
  }

  Future<void> chooseLevel(RatingLevel level) async {
    await $(TourKeys.level(level)).scrollTo().tap();
    await $.pumpAndSettle();
  }

  Future<void> start() async {
    await $(TourKeys.startButton).tap();
    await $.pumpAndSettle();
  }

  Future<void> skip() async {
    await $(TourKeys.skipButton).tap();
    await $.pumpAndSettle();
  }

  /// Em Configurações, "Rever o tour".
  Future<void> openFromSettings() async {
    await $(SettingsKeys.tourTile).scrollTo().tap();
    await $(TourKeys.screen).waitUntilVisible();
  }
}
