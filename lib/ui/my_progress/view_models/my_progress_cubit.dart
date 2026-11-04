import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_invite_repository.dart';
import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/achievements/achievements_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';

/// "Seu progresso" (H-CON-03): o rating com a variação da última partida, as
/// partidas que contaram, as conquistas e, sem conta, o convite.
class MyProgressState {
  const MyProgressState({
    this.loaded = false,
    this.rating = 0,
    this.change,
    this.games = 0,
    this.medals = const [],
    this.unlocked = const {},
    this.characters = const [],
    this.invite = false,
  });

  /// Falso enquanto lê: a tela mostra o esqueleto.
  final bool loaded;
  final int rating;

  /// A variação da última partida; nulo antes da segunda.
  final int? change;

  /// As partidas que contaram para o rating (sem os bônus de speedrun).
  final int games;

  /// As medalhas da grade: as obtidas primeiro, até [maxMedals].
  final List<Achievement> medals;
  final Set<String> unlocked;

  /// Para as conquistas dizerem o nome do adversário.
  final List<Character> characters;

  /// O cartão "Salve seu progresso": sem conta e fora da suspensão.
  final bool invite;

  /// Duas fileiras de quatro, como no quadro.
  static const maxMedals = 8;

  MyProgressState copyWith({bool? invite}) => MyProgressState(
    loaded: loaded,
    rating: rating,
    change: change,
    games: games,
    medals: medals,
    unlocked: unlocked,
    characters: characters,
    invite: invite ?? this.invite,
  );
}

class MyProgressCubit extends Cubit<MyProgressState> {
  MyProgressCubit({
    required this._rating,
    required this._achievements,
    required this._invite,
    required this._accounts,
    this._characters,
  }) : super(const MyProgressState()) {
    // Entrou pela conta com a tela aberta: o cartão sai.
    _account = _accounts.changes.listen((account) {
      if (account != null && state.invite) emit(state.copyWith(invite: false));
    });
  }

  final RatingRepository _rating;
  final AchievementsRepository _achievements;
  final AccountInviteRepository _invite;
  final AccountRepository _accounts;
  final CharacterRepository? _characters;
  late final StreamSubscription<Object?> _account;

  Future<void> load() async {
    final current = await _rating.current();
    final history = await _rating.history();
    final all = await _achievements.all();
    final unlocked = (await _achievements.unlocked()).keys.toSet();
    final characters = await _characters?.characters() ?? const <Character>[];
    final invite = _accounts.current == null && await _invite.pending();
    if (isClosed) return;
    final medals = [
      ...all.where((a) => unlocked.contains(a.id)),
      ...all.where((a) => !unlocked.contains(a.id)),
    ].take(MyProgressState.maxMedals).toList();
    emit(
      MyProgressState(
        loaded: true,
        rating: current.rounded,
        change: history.length < 2
            ? null
            : history.last.rating.rounded -
                  history[history.length - 2].rating.rounded,
        games: history.where((entry) => !entry.isBonus).length,
        medals: medals,
        unlocked: unlocked,
        characters: characters,
        invite: invite,
      ),
    );
  }

  /// O X do cartão: some e suspende o convite por 7 dias (como o da partida).
  Future<void> closeInvite() async {
    if (!state.invite) return;
    emit(state.copyWith(invite: false));
    await _invite.markShown();
  }

  @override
  Future<void> close() async {
    await _account.cancel();
    return super.close();
  }
}
