import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../../models/training/opening_track.dart';

String? openingProfileForLesson(String id) {
  final slot = id.split('.').last.replaceAll(RegExp(r'\d+$'), '');
  if (const {'london', 'caroKann', 'slav', 'others'}.contains(slot)) {
    return 'solido';
  }
  if (const {'e4White', 'dragon', 'kingsIndian', 'othersAggr'}.contains(slot)) {
    return 'agressivo';
  }
  return null;
}

/// One track per repertoire opening. Old lesson-specific tracks remain on disk.
Iterable<MapEntry<String, OpeningTrack>> activeOpeningTracks(
  TrainingState state,
  TrainingResources resources,
) sync* {
  final seen = <String>{};
  final ordered = state.openings.entries.toList()
    ..sort((a, b) {
      final ai = resources.lessons.indexWhere((l) => l.id == a.key),
          bi = resources.lessons.indexWhere((l) => l.id == b.key);
      if (ai < 0 && bi < 0) return 0;
      if (ai < 0) return 1;
      if (bi < 0) return -1;
      return ai.compareTo(bi);
    });
  for (final entry in ordered) {
    final part = resources.openings[entry.key]?.firstOrNull;
    if (part == null ||
        (part.profile != null && part.profile != state.openingProfile)) {
      continue;
    }
    if (!seen.add(part.openingId ?? entry.key)) continue;
    yield entry;
  }
}
