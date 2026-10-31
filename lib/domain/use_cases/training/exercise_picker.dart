import 'dart:math';

import '../../models/training/theme_cycle.dart';
import '../../models/training/training_content.dart';

/// Stable across processes (unlike String.hashCode); input ordering is irrelevant.
int trainingSeed(String value) {
  var hash = 2166136261;
  for (final code in value.codeUnits) {
    hash = ((hash ^ code) * 16777619) & 0x7fffffff;
  }
  return hash;
}

final class ExercisePicker {
  const ExercisePicker();
  List<TrainingExercise> ordered(Iterable<TrainingExercise> bank, String seed) {
    final sorted = bank.toList()..sort((a, b) => a.id.compareTo(b.id));
    return [
      for (var stars = 1; stars <= 3; stars++)
        ...(sorted.where((e) => e.stars == stars).toList()
          ..shuffle(Random(trainingSeed('$seed:$stars')))),
    ];
  }

  TrainingExercise? call({
    required Iterable<TrainingExercise> bank,
    required ThemeCycle cycle,
    required String installSeed,
  }) {
    final candidates = ordered(
      bank,
      '${cycle.lessonId}:$installSeed',
    ).where((e) => e.stars == cycle.level).toList();
    final unseen = candidates
        .where((e) => !cycle.seen.contains(e.id))
        .firstOrNull;
    if (unseen != null) return unseen;
    final latest = <String, ThemeDay>{
      for (final d in cycle.days) d.exerciseId: d,
    };
    candidates.sort((a, b) {
      final ad = latest[a.id], bd = latest[b.id];
      final failed = (ad?.earned == true ? 1 : 0).compareTo(
        bd?.earned == true ? 1 : 0,
      );
      if (failed != 0) return failed;
      final date = (ad?.date ?? '').compareTo(bd?.date ?? '');
      return date != 0 ? date : a.id.compareTo(b.id);
    });
    return candidates.firstOrNull;
  }

  List<String> reinforcement(
    Iterable<TrainingExercise> bank,
    ThemeCycle cycle,
    String seed,
  ) => ordered(bank, '${cycle.lessonId}:$seed:reinforce')
      .where((e) => !cycle.seen.contains(e.id))
      .map((e) => e.id)
      .toList(growable: false);
}
