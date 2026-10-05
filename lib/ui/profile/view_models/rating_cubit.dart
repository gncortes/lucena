import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/rating/rating_repository.dart';
import '../../../domain/models/player_rating.dart';

/// O rating do jogador e o histórico dele.
class RatingState {
  const RatingState({this.current, this.history = const []});

  /// Nulo enquanto é lido.
  final PlayerRating? current;

  /// Da partida mais antiga para a mais recente.
  final List<RatingEntry> history;

  /// Quanto a última partida mudou o rating. Nulo sem duas partidas.
  int? get lastChange => history.length < 2
      ? null
      : history.last.rating.rounded -
            history[history.length - 2].rating.rounded;

  /// Poucas partidas: o rating ainda não diz muito.
  bool get provisional => history.length < provisionalGames;

  /// Até quantas partidas o rating é provisório.
  static const provisionalGames = 5;
}

class RatingCubit extends Cubit<RatingState> {
  RatingCubit(this._rating) : super(const RatingState());

  final RatingRepository _rating;

  Future<void> load() async {
    final current = await _rating.current();
    final history = await _rating.history();
    if (isClosed) return;
    emit(RatingState(current: current, history: history));
  }
}
