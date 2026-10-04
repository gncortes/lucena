import 'package:chessground/chessground.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/board_settings_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

/// Tela de aparência do tabuleiro (cores, peças, coordenadas).
class BoardAppearanceRobot {
  const BoardAppearanceRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir de Configurações.
  Future<void> open() async {
    await $(SettingsKeys.boardAppearanceTile).scrollTo().tap();
    await expectVisible();
  }

  Future<void> expectVisible() async {
    await $(BoardSettingsKeys.appearanceScreen).waitUntilVisible();
    await $(BoardSettingsKeys.preview).waitUntilVisible();
  }

  Future<void> chooseColors(BoardColors colors) =>
      _tap(BoardSettingsKeys.colorsOption(colors));

  Future<void> choosePieces(PieceStyle pieces) =>
      _tap(BoardSettingsKeys.piecesOption(pieces));

  Future<void> toggleCoordinates() => _tap(BoardSettingsKeys.coordinatesSwitch);

  Future<void> restoreDefault() => _tap(BoardSettingsKeys.resetButton);

  /// O que o tabuleiro de amostra está mostrando.
  void expectPreview({
    required BoardColors colors,
    required PieceStyle pieces,
    required bool coordinates,
  }) {
    final settings = _preview.settings;
    expect(settings.colorScheme, colors.scheme);
    expect(settings.pieceAssets, pieces.assets);
    expect(settings.enableCoordinates, coordinates);
  }

  /// A amostra não espelha em idiomas da direita para a esquerda.
  void expectPreviewNotMirrored() {
    final context = $.tester.element(find.byKey(BoardSettingsKeys.preview));
    expect(Directionality.of(context), TextDirection.ltr);
  }

  StaticChessboard get _preview =>
      $.tester.widget<StaticChessboard>(find.byKey(BoardSettingsKeys.preview));

  // As opções ficam em fileiras que rolam para o lado e numa lista que rola
  // para baixo: traz a opção para a tela antes de tocar.
  Future<void> _tap(Key key) async {
    await $.tester.ensureVisible(find.byKey(key));
    await $.pumpAndSettle();
    await $(key).tap();
    await $.pumpAndSettle();
  }
}
