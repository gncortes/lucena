import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';

/// O rating que Configurações e Perfil mostram. A fonte é a mesma do Início:
/// [RatingRepository.current] (o das partidas; sem partida, o do nível
/// informado). O `rating` do perfil é só o ponto de partida e nunca é
/// mostrado direto. Nulo enquanto é lido.
class CurrentRatingCubit extends Cubit<int?> {
  CurrentRatingCubit(this._rating) : super(null);

  final RatingRepository _rating;

  Future<void> load() async {
    try {
      final current = await _rating.current();
      if (!isClosed) emit(current.rounded);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
  }
}
