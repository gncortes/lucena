import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/player_rating.dart';

/// Uma partida que mexeu no rating: como ele ficou, quanto mudou e a partida.
class RatedGame {
  const RatedGame({required this.entry, this.change, this.attempt});

  final RatingEntry entry;

  /// Quanto esta partida mudou o rating. Nulo na primeira (o ponto de
  /// partida não fica no histórico).
  final int? change;

  /// A partida em si. Nula se o histórico não foi pedido ou ela não existe
  /// mais.
  final Attempt? attempt;
}

/// O rating do jogador e o histórico dele.
class RatingState {
  const RatingState({
    this.current,
    this.history = const [],
    this.attempts = const {},
  });

  /// Nulo enquanto é lido.
  final PlayerRating? current;

  /// Da partida mais antiga para a mais recente.
  final List<RatingEntry> history;

  /// As partidas do histórico, pelo id.
  final Map<int, Attempt> attempts;

  /// Quanto a última partida mudou o rating. Nulo sem duas partidas.
  int? get lastChange => history.length < 2
      ? null
      : history.last.rating.rounded -
            history[history.length - 2].rating.rounded;

  /// Poucas partidas: o rating ainda não diz muito.
  bool get provisional => history.length < provisionalGames;

  /// As partidas que contaram, da mais recente para a mais antiga.
  List<RatedGame> get games => [
    for (var index = history.length - 1; index >= 0; index--)
      RatedGame(
        entry: history[index],
        change: index == 0
            ? null
            : history[index].rating.rounded - history[index - 1].rating.rounded,
        attempt: attempts[history[index].gameId],
      ),
  ];

  /// Até quantas partidas o rating é provisório.
  static const provisionalGames = 5;
}

class RatingCubit extends Cubit<RatingState> {
  RatingCubit(this._rating, {this._progress}) : super(const RatingState());

  final RatingRepository _rating;

  // Com ele, cada ponto do histórico vem com a partida (tela de detalhes).
  final ProgressRepository? _progress;

  Future<void> load() async {
    final current = await _rating.current();
    final history = await _rating.history();
    final attempts =
        await _progress?.attemptsById({
          for (final entry in history) ?entry.gameId,
        }) ??
        const <int, Attempt>{};
    if (isClosed) return;
    emit(RatingState(current: current, history: history, attempts: attempts));
  }
}
