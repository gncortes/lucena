import 'package:flutter/material.dart';

import '../../../domain/models/game_setup.dart';
import '../../../l10n/app_localizations.dart';

/// Como cada adversário aparece nas telas.
extension OpponentKindUi on OpponentKind {
  IconData get icon => switch (this) {
    OpponentKind.maia => Icons.psychology_alt_outlined,
    OpponentKind.stockfish => Icons.memory,
    OpponentKind.twoPlayers => Icons.people_outline,
  };

  /// O nome do adversário; o do Maia leva o nível (`Maia 1400`).
  String label(AppLocalizations l10n, {int? level}) => switch (this) {
    OpponentKind.maia =>
      level == null ? l10n.setupOpponentMaia : l10n.opponentMaiaLevel(level),
    OpponentKind.stockfish => l10n.setupOpponentStockfish,
    OpponentKind.twoPlayers => l10n.setupOpponentTwoPlayers,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    OpponentKind.maia => l10n.setupOpponentMaiaHint,
    OpponentKind.stockfish => l10n.setupOpponentStockfishHint,
    OpponentKind.twoPlayers => l10n.setupOpponentTwoPlayersHint,
  };
}
