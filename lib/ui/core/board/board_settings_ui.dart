import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../domain/models/board_settings.dart';
import '../l10n/l10n.dart';

/// Os nomes das cores do tabuleiro nas telas.
extension BoardColorsUi on BoardColors {
  String label(AppLocalizations l10n) => switch (this) {
    BoardColors.blue => l10n.boardColorsBlue,
    BoardColors.green => l10n.boardColorsGreen,
    BoardColors.brown => l10n.boardColorsBrown,
    BoardColors.gray => l10n.boardColorsGray,
    BoardColors.purple => l10n.boardColorsPurple,
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
  /// Cores, peças e coordenadas, no formato que o `PositionBoard` lê.
  BoardAppearance get appearance =>
      BoardAppearance(colors: colors, pieces: pieces, coordinates: coordinates);

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

/// [san] (letras inglesas, com número e `?`/`!` se houver) com as letras das
/// peças do idioma (`Ke3` vira `Re3` em português).
String localizedSan(AppLocalizations l10n, String san) {
  final letters = MoveNotation.letters.pieceLetters(l10n)!;
  return san.replaceAllMapped(
    RegExp('[KQRBN]'),
    (match) => letters[match[0]] ?? match[0]!,
  );
}
