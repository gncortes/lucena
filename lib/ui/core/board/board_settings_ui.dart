import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/board_settings.dart';
import '../l10n/l10n.dart';
import '../theme/app_motion.dart';

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

/// Como cada jeito de mover as peças aparece nas telas e no `chessground`.
extension MoveMethodUi on MoveMethod {
  PieceShiftMethod get shiftMethod => switch (this) {
    MoveMethod.either => PieceShiftMethod.either,
    MoveMethod.drag => PieceShiftMethod.drag,
    MoveMethod.tap => PieceShiftMethod.tapTwoSquares,
  };

  String label(AppLocalizations l10n) => switch (this) {
    MoveMethod.either => l10n.boardMoveMethodEither,
    MoveMethod.drag => l10n.boardMoveMethodDrag,
    MoveMethod.tap => l10n.boardMoveMethodTap,
  };

  IconData get icon => switch (this) {
    MoveMethod.either => Icons.touch_app_outlined,
    MoveMethod.drag => Icons.pan_tool_alt_outlined,
    MoveMethod.tap => Icons.ads_click,
  };
}

extension MoveNotationUi on MoveNotation {
  String label(AppLocalizations l10n) => switch (this) {
    MoveNotation.figurine => l10n.boardNotationFigurine,
    MoveNotation.letters => l10n.boardNotationLetters,
  };

  /// A letra de cada peça nos lances (`K`, `Q`, `R`, `B`, `N` da notação
  /// algébrica) trocada pela do idioma. Nulo na notação com desenhos.
  Map<String, String>? pieceLetters(AppLocalizations l10n) => switch (this) {
    MoveNotation.figurine => null,
    MoveNotation.letters => {
      'K': l10n.pieceLetterKing,
      'Q': l10n.pieceLetterQueen,
      'R': l10n.pieceLetterRook,
      'B': l10n.pieceLetterBishop,
      'N': l10n.pieceLetterKnight,
    },
  };
}

/// As preferências do app no formato do `chessground`.
extension BoardSettingsUi on BoardSettings {
  static const _animationDuration = AppMotion.state;

  ChessboardSettings get chessground => ChessboardSettings(
    colorScheme: colors.scheme,
    pieceAssets: pieces.assets,
    enableCoordinates: coordinates,
    pieceShiftMethod: moveMethod.shiftMethod,
    showValidMoves: showLegalMoves,
    showLastMove: highlightLastMove,
    animationDuration: animation ? _animationDuration : Duration.zero,
    enablePremoves: premoves,
  );
}
