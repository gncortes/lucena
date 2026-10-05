import '../../../domain/models/journey.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';

/// O nome de um adversário de desafio ou degrau (`Maia 1000`, `Stockfish`).
String opponentRefLabel(AppLocalizations l10n, OpponentRef opponent) =>
    opponent.kind.label(l10n, level: opponent.level);
