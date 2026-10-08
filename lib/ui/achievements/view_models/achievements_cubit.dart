import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/achievements/achievements_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/achievement.dart';
import '../../../domain/models/character.dart';
import '../../../domain/use_cases/achievement_rules.dart';
import '../../../domain/use_cases/now.dart';
import 'achievement_facts_loader.dart';

/// O que a lista mostra: todas (por grupo), só as conquistadas, só as que
/// faltam ou o histórico (as conquistadas pela data, a mais recente
/// primeiro).
enum AchievementsFilter { all, unlocked, locked, history }

/// As conquistas, com a data e a origem de cada uma já obtida e o progresso
/// das que faltam.
class AchievementsState {
  const AchievementsState({
    this.all,
    this.unlocked = const {},
    this.characters = const [],
    this.progress = const {},
    this.speedrunOfAttempt = const {},
    this.now,
    this.filter = AchievementsFilter.all,
  });

  /// Nulo enquanto é lida.
  final List<Achievement>? all;
  final Map<String, UnlockedAchievement> unlocked;

  /// Os personagens, para as conquistas dizerem o nome do adversário.
  final List<Character> characters;

  /// O progresso das que dão para medir, pelo id.
  final Map<String, AchievementProgress> progress;

  /// O speedrun de cada tentativa que desbloqueou uma conquista, para abrir
  /// a tentativa.
  final Map<int, String> speedrunOfAttempt;

  /// O instante da leitura, para a data relativa ("ontem").
  final DateTime? now;
  final AchievementsFilter filter;

  /// Quantas de [all] já foram obtidas.
  int get unlockedCount =>
      all?.where((a) => unlocked.containsKey(a.id)).length ?? 0;

  /// As que o filtro deixa ver, na ordem da lista; no histórico, pela data,
  /// a mais recente primeiro.
  List<Achievement> get visible {
    final list = all ?? const <Achievement>[];
    return switch (filter) {
      AchievementsFilter.all => list,
      AchievementsFilter.unlocked => [
        for (final a in list)
          if (unlocked.containsKey(a.id)) a,
      ],
      AchievementsFilter.locked => [
        for (final a in list)
          if (!unlocked.containsKey(a.id)) a,
      ],
      AchievementsFilter.history => [
        for (final a in list)
          if (unlocked.containsKey(a.id)) a,
      ]..sort((a, b) => unlocked[b.id]!.at.compareTo(unlocked[a.id]!.at)),
    };
  }

  AchievementsState copyWith({AchievementsFilter? filter}) => AchievementsState(
    all: all,
    unlocked: unlocked,
    characters: characters,
    progress: progress,
    speedrunOfAttempt: speedrunOfAttempt,
    now: now,
    filter: filter ?? this.filter,
  );
}

class AchievementsCubit extends Cubit<AchievementsState> {
  AchievementsCubit(
    this._achievements, {
    required this._now,
    this._characters,
    this._facts,
    this._speedruns,
  }) : super(const AchievementsState());

  final AchievementsRepository _achievements;
  final Now _now;
  final CharacterRepository? _characters;

  /// Sem ele, a lista não mostra o progresso das que faltam.
  final AchievementFactsLoader? _facts;

  /// Sem ele, a conquista de speedrun não abre a tentativa.
  final SpeedrunRepository? _speedruns;

  Future<void> load() async {
    final all = await _achievements.all();
    final unlocked = await _achievements.unlocked();
    final characters = await _characters?.characters() ?? const <Character>[];
    final facts = await _facts?.load();
    final progress = <String, AchievementProgress>{
      if (facts != null)
        for (final achievement in all)
          if (!unlocked.containsKey(achievement.id))
            achievement.id: ?AchievementRules.progress(achievement, facts),
    };
    final speedrunOfAttempt = <int, String>{};
    for (final item in unlocked.values) {
      final attemptId = item.speedrunAttemptId;
      if (attemptId == null || speedrunOfAttempt.containsKey(attemptId)) {
        continue;
      }
      final attempt = await _speedruns?.attempt(attemptId);
      if (attempt != null) speedrunOfAttempt[attemptId] = attempt.speedrunId;
    }
    if (isClosed) return;
    emit(
      AchievementsState(
        all: all,
        unlocked: unlocked,
        characters: characters,
        progress: progress,
        speedrunOfAttempt: speedrunOfAttempt,
        now: _now(),
        filter: state.filter,
      ),
    );
  }

  void filter(AchievementsFilter filter) {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter));
  }
}
