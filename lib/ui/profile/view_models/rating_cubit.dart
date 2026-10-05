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

  /// Poucas partidas: o rating ainda pode mudar muito.
  bool get provisional =>
      (current?.deviation ?? PlayerRating.initialDeviation) > 110;
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
