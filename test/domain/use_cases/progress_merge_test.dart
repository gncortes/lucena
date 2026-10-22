import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/models/progress_summary.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/progress_merge.dart';

void main() {
  const local = ProgressSummary(
    profile: UserProfile(nickname: 'Ana', goal: GoalPreference.train),
    rating: PlayerRating(rating: 1500, deviation: 80),
    lessons: {
      'lucena': EndgameLessonProgress(parts: {'a'}, stars: {'e1': 2}),
      'philidor': EndgameLessonProgress(lessonDone: true),
    },
    school: {'peao'},
    stars: {'rook.easy': 3},
    challenges: {'c1'},
    positions: {'p1'},
    startRung: 1100,
    speedruns: {'s1': 90000},
    race: RaceRecord(corrects: 12, hardest: 5),
    featured: {'f1'},
  );
  const remote = ProgressSummary(
    profile: UserProfile(
      nickname: 'Outro',
      rating: 1712,
      levelSource: LevelSource.lichess,
      lichessUser: 'ana_xadrez',
      country: 'BR',
    ),
    rating: PlayerRating(rating: 1620, deviation: 60),
    lessons: {
      'lucena': EndgameLessonProgress(parts: {'b'}, stars: {'e1': 3, 'e2': 1}),
      'vancura': EndgameLessonProgress(approved: true),
    },
    school: {'torre'},
    stars: {'rook.easy': 2, 'queen.easy': 4},
    challenges: {'c2'},
    positions: {'p1', 'p2'},
    startRung: 1300,
    speedruns: {'s1': 120000, 's2': 60000},
    race: RaceRecord(corrects: 9, hardest: 7),
    featured: {'f2'},
  );

  test('vale o maior em cada item', () {
    final merged = ProgressMerge.merge(local, remote);

    expect(merged.rating, remote.rating);
    final lucena = merged.lessons['lucena']!;
    expect(lucena.parts, {'a', 'b'});
    expect(lucena.stars, {'e1': 3, 'e2': 1});
    expect(merged.lessons['philidor']!.lessonDone, isTrue);
    expect(merged.lessons['vancura']!.approved, isTrue);
    expect(merged.school, {'peao', 'torre'});
    expect(merged.stars, {'rook.easy': 3, 'queen.easy': 4});
    expect(merged.challenges, {'c1', 'c2'});
    expect(merged.positions, {'p1', 'p2'});
    expect(merged.startRung, 1300);
    expect(merged.race.corrects, 12);
    expect(merged.race.hardest, 7);
    expect(merged.featured, {'f1', 'f2'});
  });

  test('no speedrun vale o menor tempo, que é o recorde', () {
    expect(ProgressMerge.merge(local, remote).speedruns, {
      's1': 90000,
      's2': 60000,
    });
  });

  test('o perfil é o do aparelho; a conta preenche o que falta', () {
    final profile = ProgressMerge.merge(local, remote).profile;

    expect(profile.nickname, 'Ana');
    expect(profile.goal, GoalPreference.train);
    // O aparelho não tinha nível escolhido: vem o da conta.
    expect(profile.rating, 1712);
    expect(profile.levelSource, LevelSource.lichess);
    expect(profile.lichessUser, 'ana_xadrez');
    expect(profile.country, 'BR');
  });

  test('só no aparelho ou só na conta: fica o que existe', () {
    const empty = ProgressSummary();
    expect(
      ProgressMerge.merge(local, empty).toJson(),
      local.toJson(),
    );
    final restored = ProgressMerge.merge(empty, remote);
    expect(restored.rating, remote.rating);
    expect(restored.challenges, {'c2'});
    expect(restored.profile.nickname, 'Outro');
  });

  test('o resumo vai e volta pelo JSON, sem o exercício pela metade', () {
    const withExercise = ProgressSummary(
      lessons: {
        'lucena': EndgameLessonProgress(
          parts: {'a'},
          exercise: ExerciseCheckpoint(exerciseId: 'e1'),
        ),
      },
    );
    final back = ProgressSummary.fromJson(withExercise.toJson());
    expect(back.lessons['lucena']!.exercise, isNull);
    expect(back.lessons['lucena']!.parts, {'a'});

    expect(ProgressSummary.fromJson(remote.toJson()).toJson(), remote.toJson());
    expect(ProgressSummary.fromJson(const {}).isEmpty, isTrue);
  });
}
