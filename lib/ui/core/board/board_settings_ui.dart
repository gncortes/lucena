import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/models/board_settings.dart';
import '../l10n/l10n.dart';

/// Como as cores do tabuleiro aparecem na tela e no `chessground`.
extension BoardColorsUi on BoardColors {
  ChessboardColorScheme get scheme => switch (this) {
    BoardColors.blue => ChessboardColorScheme.blue,
    BoardColors.green => ChessboardColorScheme.green,
    BoardColors.brown => ChessboardColorScheme.brown,
    BoardColors.gray => _gray,
    BoardColors.purple => _purple,
  };

  String label(AppLocalizations l10n) => switch (this) {
    BoardColors.blue => l10n.boardColorsBlue,
    BoardColors.green => l10n.boardColorsGreen,
    BoardColors.brown => l10n.boardColorsBrown,
    BoardColors.gray => l10n.boardColorsGray,
    BoardColors.purple => l10n.boardColorsPurple,
  };

  // Esquemas próprios, de cor lisa (sem imagem de terceiros).
  static const _gray = ChessboardColorScheme(
    lightSquare: _grayLight,
    darkSquare: _grayDark,
    background: SolidColorChessboardBackground(
      lightSquare: _grayLight,
      darkSquare: _grayDark,
    ),
    whiteCoordBackground: SolidColorChessboardBackground(
      lightSquare: _grayLight,
      darkSquare: _grayDark,
      coordinates: true,
    ),
    blackCoordBackground: SolidColorChessboardBackground(
      lightSquare: _grayLight,
      darkSquare: _grayDark,
      coordinates: true,
      orientation: Side.black,
    ),
    lastMove: HighlightDetails(solidColor: Color(0x809bc700)),
    selected: HighlightDetails(solidColor: Color(0x6014551e)),
    validMoves: Color(0x4014551e),
    validPremoves: Color(0x40203085),
  );
  static const _grayLight = Color(0xffe3e3e3);
  static const _grayDark = Color(0xff9a9a9a);

  static const _purple = ChessboardColorScheme(
    lightSquare: _purpleLight,
    darkSquare: _purpleDark,
    background: SolidColorChessboardBackground(
      lightSquare: _purpleLight,
      darkSquare: _purpleDark,
    ),
    whiteCoordBackground: SolidColorChessboardBackground(
      lightSquare: _purpleLight,
      darkSquare: _purpleDark,
      coordinates: true,
    ),
    blackCoordBackground: SolidColorChessboardBackground(
      lightSquare: _purpleLight,
      darkSquare: _purpleDark,
      coordinates: true,
      orientation: Side.black,
    ),
    lastMove: HighlightDetails(solidColor: Color(0x809bc700)),
    selected: HighlightDetails(solidColor: Color(0x6014551e)),
    validMoves: Color(0x4014551e),
    validPremoves: Color(0x40203085),
  );
  static const _purpleLight = Color(0xffe7dff0);
  static const _purpleDark = Color(0xff9079b0);
}

/// As imagens de cada conjunto de peças.
extension PieceStyleUi on PieceStyle {
  PieceAssets get assets => switch (this) {
    PieceStyle.cburnett => PieceSet.cburnettAssets,
    PieceStyle.merida => PieceSet.meridaAssets,
    PieceStyle.chessnut => PieceSet.chessnutAssets,
    PieceStyle.pirouetti => PieceSet.pirouettiAssets,
    PieceStyle.mpchess => PieceSet.mpchessAssets,
    PieceStyle.firi => PieceSet.firiAssets,
    PieceStyle.rhosgfx => PieceSet.rhosgfxAssets,
    PieceStyle.fantasy => PieceSet.fantasyAssets,
    PieceStyle.celtic => PieceSet.celticAssets,
    PieceStyle.spatial => PieceSet.spatialAssets,
    PieceStyle.pixel => PieceSet.pixelAssets,
    PieceStyle.letter => PieceSet.letterAssets,
  };
}

/// As preferências do app no formato do `chessground`.
extension BoardSettingsUi on BoardSettings {
  ChessboardSettings get chessground => ChessboardSettings(
    colorScheme: colors.scheme,
    pieceAssets: pieces.assets,
    enableCoordinates: coordinates,
    // O jogador faz os dois lados: não há lance antecipado.
    enablePremoves: false,
  );
}
