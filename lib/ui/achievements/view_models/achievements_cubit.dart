import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/achievements/achievements_repository.dart';
import '../../../domain/models/achievement.dart';

/// As conquistas, com a data de cada uma já obtida.
class AchievementsState {
  const AchievementsState({this.all, this.unlocked = const {}});

  /// Nulo enquanto é lida.
  final List<Achievement>? all;
  final Map<String, DateTime> unlocked;
}

class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit(this._achievements) : super(const AchievementsState());

  final AchievementsRepository _achievements;

  Future<void> load() async {
    final all = await _achievements.all();
    final unlocked = await _achievements.unlocked();
    if (isClosed) return;
    emit(AchievementsState(all: all, unlocked: unlocked));
  }
}
