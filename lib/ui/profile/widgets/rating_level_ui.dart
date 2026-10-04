import 'package:dartchess/dartchess.dart';

import '../../../domain/models/rating_level.dart';
import '../../core/l10n/l10n.dart';

/// Como cada faixa de rating aparece nas telas.
extension RatingLevelUi on RatingLevel {
  String name(AppLocalizations l10n) => switch (this) {
    RatingLevel.beginner => l10n.profileLevelBeginner,
    RatingLevel.casual => l10n.profileLevelCasual,
    RatingLevel.intermediate => l10n.profileLevelIntermediate,
    RatingLevel.advanced => l10n.profileLevelAdvanced,
    RatingLevel.expert => l10n.profileLevelExpert,
    RatingLevel.master => l10n.profileLevelMaster,
  };

  /// A faixa por extenso: "Abaixo de 1000", "1300–1599", "2200 ou mais".
  String range(AppLocalizations l10n) {
    final min = this.min;
    final max = this.max;
    if (min == null) return l10n.profileLevelBelow(max! + 1);
    if (max == null) return l10n.profileLevelAbove(min);
    return l10n.profileLevelRange(min, max);
  }

  /// Uma peça por faixa, do peão ao rei.
  PieceKind get piece => switch (this) {
    RatingLevel.beginner => PieceKind.whitePawn,
    RatingLevel.casual => PieceKind.whiteKnight,
    RatingLevel.intermediate => PieceKind.whiteBishop,
    RatingLevel.advanced => PieceKind.whiteRook,
    RatingLevel.expert => PieceKind.whiteQueen,
    RatingLevel.master => PieceKind.whiteKing,
  };
}
