import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../data/repositories/featured/featured_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/featured.dart';

/// Um final em destaque: o livrinho dele, o que o jogador já fez e o
/// adversário e o relógio que valem.
class FeaturedEndgameState {
  const FeaturedEndgameState({
    this.ready = false,
    this.endgame,
    this.tournament,
    this.siblings = const [],
    this.played = false,
    this.choice,
    this.characters = const [],
  });

  final bool ready;

  /// Nulo depois de pronto: o final não existe mais.
  final FeaturedEndgame? endgame;
  final FeaturedTournament? tournament;

  /// Os outros finais do mesmo torneio.
  final List<FeaturedEndgame> siblings;
  final bool played;

  /// O adversário e o relógio que valem: a escolha do jogador ou a sugestão.
  final FeaturedChoice? choice;

  /// Os personagens do Maia: o adversário aparece com o nome e o retrato que
  /// ele tem na partida.
  final List<Character> characters;

  /// O jogador pode trocar o adversário e o relógio: sempre quando o final é
  /// uma sugestão; senão, só depois da primeira tentativa.
  bool get canChange => (endgame?.playerCanChange ?? false) || played;

  FeaturedEndgameState copyWith({bool? played, FeaturedChoice? choice}) =>
      FeaturedEndgameState(
        ready: ready,
        endgame: endgame,
        tournament: tournament,
        siblings: siblings,
        played: played ?? this.played,
        choice: choice ?? this.choice,
        characters: characters,
      );
}

class FeaturedEndgameCubit extends Cubit<FeaturedEndgameState> {
  FeaturedEndgameCubit({
    required this.id,
    required this._featured,
    required this._progress,
    required this._characters,
  }) : super(const FeaturedEndgameState());

  final String id;
  final FeaturedRepository _featured;
  final FeaturedProgressRepository _progress;
  final CharacterRepository _characters;

  Future<void> load() async {
    final catalog = await _featured.catalog();
    final played = (await _progress.played()).contains(id);
    final saved = await _progress.choice(id);
    final characters = await _characters.characters();
    if (isClosed) return;
    final endgame = catalog.endgame(id);
    final tournamentId = endgame?.tournamentId;
    emit(
      FeaturedEndgameState(
        ready: true,
        endgame: endgame,
        tournament: catalog.tournament(tournamentId),
        siblings: [
          if (tournamentId != null)
            for (final each in catalog.finalsOf(tournamentId))
              if (each.id != id) each,
        ],
        played: played,
        characters: characters,
        // A escolha guardada só vale onde o jogador pode trocar.
        choice: endgame == null
            ? null
            : (played || endgame.playerCanChange ? saved : null) ??
                  endgame.suggested,
      ),
    );
  }

  /// O jogador escolheu outro adversário ou relógio.
  Future<void> choose(FeaturedChoice choice) async {
    if (!state.canChange || state.choice == choice) return;
    emit(state.copyWith(choice: choice));
    await _progress.saveChoice(id, choice);
  }

  /// A primeira tentativa começou: a partir daí o adversário pode ser trocado.
  Future<void> markPlayed() async {
    if (state.played) return;
    emit(state.copyWith(played: true));
    await _progress.markPlayed(id);
  }
}
