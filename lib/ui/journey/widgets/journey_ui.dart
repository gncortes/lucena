import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';

/// O nome de um adversário de desafio ou degrau (`Maia 1000`, `Stockfish`).
String opponentRefLabel(AppLocalizations l10n, OpponentRef opponent) =>
    opponent.kind.label(l10n, level: opponent.level);

/// O personagem de um adversário da Jornada: o do nível do Maia ou o logo do
/// Stockfish. Nulo se o personagem do nível não foi lido.
Character? opponentCharacter(
  List<Character> characters,
  OpponentRef opponent,
) => opponent.kind == OpponentKind.stockfish
    ? Character.stockfish
    : characters.forLevel(opponent.level);

/// O nome do adversário para o jogador: o do personagem (`Coco`) ou, sem ele,
/// o do motor (`Maia 1000`).
String opponentName(
  AppLocalizations l10n,
  List<Character> characters,
  OpponentRef opponent,
) =>
    opponentCharacter(characters, opponent)?.name ??
    opponentRefLabel(l10n, opponent);
