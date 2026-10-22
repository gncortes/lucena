import 'dart:math';

import '../models/endgame_lesson.dart';
import '../models/progress_summary.dart';
import '../models/race.dart';
import '../models/user_profile.dart';

/// Junta o progresso do aparelho com o da conta (E1.13, regra 13): em cada
/// item vale o maior. Aula feita, posição cumprida e recorde de um lado
/// valem nos dois; o speedrun guarda o menor tempo, que é o recorde.
abstract final class ProgressMerge {
  static ProgressSummary merge(ProgressSummary local, ProgressSummary remote) {
    final localRating = local.rating;
    final remoteRating = remote.rating;
    return ProgressSummary(
      profile: _profile(local.profile, remote.profile),
      rating: localRating == null
          ? remoteRating
          : remoteRating == null || localRating.rating >= remoteRating.rating
          ? localRating
          : remoteRating,
      lessons: {
        for (final id in {...local.lessons.keys, ...remote.lessons.keys})
          id: _lesson(local.lessons[id], remote.lessons[id]),
      },
      school: {...local.school, ...remote.school},
      stars: _larger(local.stars, remote.stars),
      challenges: {...local.challenges, ...remote.challenges},
      positions: {...local.positions, ...remote.positions},
      startRung: switch ((local.startRung, remote.startRung)) {
        (final a?, final b?) => max(a, b),
        (final a, final b) => a ?? b,
      },
      speedruns: {
        for (final id in {...local.speedruns.keys, ...remote.speedruns.keys})
          id: min(
            local.speedruns[id] ?? remote.speedruns[id]!,
            remote.speedruns[id] ?? local.speedruns[id]!,
          ),
      },
      race: RaceRecord(
        corrects: max(local.race.corrects, remote.race.corrects),
        hardest: max(local.race.hardest, remote.race.hardest),
      ),
      featured: {...local.featured, ...remote.featured},
    );
  }

  // O perfil não tem "maior": vale o do aparelho, e a conta preenche o que
  // ele ainda não tem (num celular novo, quase tudo).
  static UserProfile _profile(UserProfile local, UserProfile remote) {
    final fromRemote = local.levelSource == null && remote.levelSource != null;
    final country = local.country ?? remote.country;
    final sameCountry = country == remote.country;
    return local.copyWith(
      nickname: local.nickname.isEmpty ? remote.nickname : local.nickname,
      rating: fromRemote ? remote.rating : local.rating,
      levelSource: fromRemote ? remote.levelSource : local.levelSource,
      goal: local.goal ?? remote.goal,
      lichessUser: local.lichessUser ?? remote.lichessUser,
      chessComUser: local.chessComUser ?? remote.chessComUser,
      country: country,
      // Estado e cidade da conta só valem para o mesmo país.
      state: local.state ?? (sameCountry ? remote.state : null),
      city: local.city ?? (sameCountry ? remote.city : null),
    );
  }

  static EndgameLessonProgress _lesson(
    EndgameLessonProgress? local,
    EndgameLessonProgress? remote,
  ) {
    if (local == null) return remote!.copyWith(clearExercise: true);
    if (remote == null) return local;
    return local.copyWith(
      lessonDone: local.lessonDone || remote.lessonDone,
      approved: local.approved || remote.approved,
      parts: {...local.parts, ...remote.parts},
      stars: _larger(local.stars, remote.stars),
    );
  }

  static Map<String, int> _larger(Map<String, int> a, Map<String, int> b) => {
    for (final key in {...a.keys, ...b.keys})
      key: max(a[key] ?? b[key]!, b[key] ?? a[key]!),
  };
}
