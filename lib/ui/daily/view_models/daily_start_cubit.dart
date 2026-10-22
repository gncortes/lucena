import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/daily/daily_final_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/use_cases/now.dart';
import '../../../routing/routes.dart';

/// Para onde vai o `/daily` (o toque da home e do lembrete): a partida do
/// final de hoje, com o Maia no nível do rating da pessoa. Sem final hoje,
/// volta à home.
sealed class DailyStartState {
  const DailyStartState();
}

class DailyStartLoading extends DailyStartState {
  const DailyStartLoading();
}

class DailyStartReady extends DailyStartState {
  const DailyStartReady(this.location);

  final String location;
}

class DailyStartCubit extends Cubit<DailyStartState> {
  DailyStartCubit({
    required this._daily,
    required this._rating,
    required this._now,
  }) : super(const DailyStartLoading());

  final DailyFinalRepository _daily;
  final RatingRepository _rating;
  final Now _now;

  Future<void> load() async {
    final daily = await _daily.of(_now());
    final rating = await _rating.current();
    if (isClosed) return;
    emit(
      DailyStartReady(
        daily == null
            ? Routes.home
            : Routes.dailyGame(
                daily,
                level: MaiaLevels.nearest(rating.rounded),
              ),
      ),
    );
  }
}
