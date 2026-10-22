import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../domain/models/challenge_link.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/maia_level.dart';
import '../../../routing/routes.dart';

part 'challenge_link_cubit.freezed.dart';

@freezed
abstract class ChallengeLinkState with _$ChallengeLinkState {
  const factory ChallengeLinkState({
    required ChallengeLink link,

    /// O nível do Maia que vale: o do link ou, sem ele, o do rating de quem
    /// abriu.
    required int level,
    @Default(<Character>[]) List<Character> characters,
    @Default(false) bool ready,
  }) = _ChallengeLinkState;

  const ChallengeLinkState._();

  /// O adversário: o personagem do nível do Maia ou o do Stockfish.
  Character? get opponent => link.opponent == OpponentKind.stockfish
      ? Character.stockfish
      : characters.forLevel(level);

  /// Onde a partida do desafio abre.
  String get gameRoute => Routes.linkGame(link, level: level);
}

/// O desafio aberto por link, com a configuração travada: o adversário, o
/// relógio e o modo são os de quem mandou.
class ChallengeLinkCubit extends Cubit<ChallengeLinkState> {
  ChallengeLinkCubit(
    this._characters,
    this._profile,
    this._rating, {
    required ChallengeLink link,
  }) : super(
         ChallengeLinkState(link: link, level: link.level ?? MaiaLevels.min),
       );

  final CharacterRepository _characters;
  final ProfileRepository _profile;
  final RatingRepository _rating;

  Future<void> load() async {
    final characters = await _characters.characters();
    final profile = await _profile.load();
    final history = await _rating.history();
    final rating = history.isEmpty ? null : history.last.rating.rounded;
    if (isClosed) return;
    emit(
      state.copyWith(
        level: state.link.level ?? MaiaLevels.nearest(rating ?? profile.rating),
        characters: characters,
        ready: true,
      ),
    );
  }
}
