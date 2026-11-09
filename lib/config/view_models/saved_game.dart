import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../../domain/models/character.dart';
import '../../domain/models/game_setup.dart';
import '../../domain/models/saved_game.dart';
import '../../domain/use_cases/game_rules.dart';

/// A partida guardada lida dos repositórios do [context]. Sem eles (telas
/// testadas sozinhas), não há partida.
Future<SavedGame?> readSavedGame(BuildContext context) async {
  final OngoingGameRepository games;
  final CharacterRepository characters;
  try {
    games = context.read<OngoingGameRepository>();
    characters = context.read<CharacterRepository>();
  } on ProviderNotFoundException {
    return null;
  }
  return loadSavedGame(games, characters);
}

/// A partida guardada, se houver algo a perder nela; nulo se não houver.
Future<SavedGame?> loadSavedGame(
  OngoingGameRepository games,
  CharacterRepository characters,
) async {
  final snapshot = await games.load();
  if (snapshot == null) return null;
  if (snapshot.moves.isEmpty && snapshot.clock == null) return null;
  var position = GameRules.fromFen(snapshot.startFen);
  if (position == null) return null;
  Move? lastMove;
  for (final uci in snapshot.moves) {
    final move = Move.parse(uci);
    final played = move == null ? null : GameRules.play(position!, move);
    if (played == null) return null;
    position = played.position;
    lastMove = move;
  }
  final mode = snapshot.mode;
  final character = switch (mode.opponent) {
    OpponentKind.maia => (await characters.characters()).forLevel(mode.level),
    OpponentKind.stockfish => Character.stockfish,
    OpponentKind.twoPlayers => null,
  };
  return (
    snapshot: snapshot,
    position: position!,
    lastMove: lastMove,
    character: character,
  );
}
