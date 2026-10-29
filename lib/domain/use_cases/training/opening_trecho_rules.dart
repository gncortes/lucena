import '../../models/training/opening_track.dart';
import '../../models/training/training_content.dart';
import '../now.dart';
import 'training_date.dart';

final class OpeningTrechoRules {
  const OpeningTrechoRules(this.now);
  final Now now;
  OpeningTrecho? next(OpeningTrack track, Iterable<OpeningTrecho> bank) {
    final date = trainingDate(now());
    if (track.doneTrechos.values.contains(date)) return null;
    final segments = bank.toList();
    final unseen = segments
        .where((t) => !track.doneTrechos.containsKey(t.id))
        .firstOrNull;
    if (unseen != null) return track.lastNewDate == date ? null : unseen;
    segments.sort((a, b) {
      final age = (track.doneTrechos[a.id] ?? '').compareTo(
        track.doneTrechos[b.id] ?? '',
      );
      return age != 0 ? age : a.id.compareTo(b.id);
    });
    return segments.firstOrNull;
  }

  OpeningTrack complete(
    OpeningTrack track,
    OpeningTrecho trecho,
    List<bool> firstTry,
  ) {
    final expected = (trecho.moves.length + (trecho.black ? 0 : 1)) ~/ 2;
    if (firstTry.length != expected) {
      throw ArgumentError('Missing first-try results');
    }
    final date = trainingDate(now());
    return OpeningTrack(
      lessonId: track.lessonId,
      startedOn: track.startedOn,
      lastNewDate: track.doneTrechos.containsKey(trecho.id)
          ? track.lastNewDate
          : date,
      doneTrechos: {...track.doneTrechos, trecho.id: date},
      firstTry: {
        ...track.firstTry,
        trecho.id: [
          for (var i = 0; i < firstTry.length; i++)
            firstTry[i] &&
                !(track.pendingMistakes[trecho.id]?.contains(i) ?? false),
        ],
      },
      pendingMistakes: {
        for (final entry in track.pendingMistakes.entries)
          if (entry.key != trecho.id) entry.key: entry.value,
      },
    );
  }
}
