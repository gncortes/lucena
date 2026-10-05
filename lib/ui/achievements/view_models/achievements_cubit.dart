import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/achievements/achievements_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';

/// As conquistas, com a data de cada uma já obtida.
class AchievementsState {
  const AchievementsState({
    this.all,
    this.unlocked = const {},
    this.characters = const [],
  });

  /// Nulo enquanto é lida.
  final List<Achievement>? all;
  final Map<String, DateTime> unlocked;

  /// Os personagens, para as conquistas dizerem o nome do adversário.
  final List<Character> characters;
}

class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit(this._achievements, {this._characters})
    : super(const AchievementsState());

  final AchievementsRepository _achievements;
  final CharacterRepository? _characters;

  Future<void> load() async {
    final all = await _achievements.all();
    final unlocked = await _achievements.unlocked();
    final characters = await _characters?.characters() ?? const <Character>[];
    if (isClosed) return;
    emit(
      AchievementsState(all: all, unlocked: unlocked, characters: characters),
    );
  }
}
