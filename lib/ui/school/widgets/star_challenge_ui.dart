import 'package:flutter/material.dart';

import '../../../domain/models/star_challenge.dart';
import '../../../domain/use_cases/star_challenge_rules.dart';
import '../../core/l10n/l10n.dart';

/// O nome da peça no idioma.
String pieceName(AppLocalizations l10n, ChallengePiece piece) =>
    switch (piece) {
      ChallengePiece.rook => l10n.pieceRook,
      ChallengePiece.bishop => l10n.pieceBishop,
      ChallengePiece.knight => l10n.pieceKnight,
      ChallengePiece.queen => l10n.pieceQueen,
      ChallengePiece.king => l10n.pieceKing,
      ChallengePiece.pawn => l10n.piecePawn,
    };

/// O nome do nível no idioma.
String levelName(AppLocalizations l10n, ChallengeLevel level) =>
    switch (level) {
      ChallengeLevel.easy => l10n.challengeLevelEasy,
      ChallengeLevel.medium => l10n.challengeLevelMedium,
      ChallengeLevel.hard => l10n.challengeLevelHard,
    };

/// A nota (0 a 3) de uma marca.
int earnedOf(ChallengeLevel level, int collected) =>
    StarChallengeRules.earned(level, collected);

/// "0:45".
String clockText(Duration left) {
  final seconds = (left.inMilliseconds / 1000).ceil();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

extension ChallengePieceLetter on ChallengePiece {
  /// A letra da notação, para o figurino.
  String get letter => switch (this) {
    ChallengePiece.rook => 'R',
    ChallengePiece.bishop => 'B',
    ChallengePiece.knight => 'N',
    ChallengePiece.queen => 'Q',
    ChallengePiece.king => 'K',
    ChallengePiece.pawn => 'P',
  };
}

/// A cor de cada tipo de estrela.
Color starColor(StarKind kind) => switch (kind) {
  StarKind.gold => const Color(0xfff2b705),
  StarKind.silver => const Color(0xffb0b8c1),
  StarKind.bronze => const Color(0xffcd7f32),
};
