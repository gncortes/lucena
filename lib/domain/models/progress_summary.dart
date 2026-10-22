import 'endgame_lesson.dart';
import 'goal_preference.dart';
import 'level_source.dart';
import 'player_rating.dart';
import 'race.dart';
import 'user_profile.dart';

/// O progresso que sobe para a conta (E1.13): um documento só,
/// `users/{uid}/progress/summary`. As partidas vão uma por documento, à parte.
///
/// Só entra o que se junta sem conflito ([ProgressMerge]); o que é deste
/// aparelho (aula aberta, exercício pela metade, preferências) fica nele.
class ProgressSummary {
  const ProgressSummary({
    this.profile = const UserProfile(),
    this.rating,
    this.lessons = const {},
    this.school = const {},
    this.stars = const {},
    this.challenges = const {},
    this.positions = const {},
    this.startRung,
    this.speedruns = const {},
    this.race = const RaceRecord(),
    this.featured = const {},
  });

  /// O perfil. Sobe sem o token do Lichess, que nunca sai do aparelho.
  final UserProfile profile;

  /// O rating de finais. Nulo: nenhuma partida contou ainda.
  final PlayerRating? rating;

  /// As aulas de finais, sem o exercício pela metade.
  final Map<String, EndgameLessonProgress> lessons;

  /// As aulas da Escola concluídas.
  final Set<String> school;

  /// O melhor resultado de cada desafio de estrelas (`peça.nível`).
  final Map<String, int> stars;

  /// Os desafios da Jornada e as posições do catálogo cumpridos.
  final Set<String> challenges;
  final Set<String> positions;

  /// O degrau em que a Jornada começou (o nível do Maia, como `1100`).
  final int? startRung;

  /// O melhor tempo de cada speedrun concluído, em milissegundos.
  final Map<String, int> speedruns;

  final RaceRecord race;

  /// Os finais em destaque já jogados.
  final Set<String> featured;

  bool get isEmpty =>
      rating == null &&
      lessons.isEmpty &&
      school.isEmpty &&
      stars.isEmpty &&
      challenges.isEmpty &&
      positions.isEmpty &&
      speedruns.isEmpty &&
      race.isEmpty &&
      featured.isEmpty;

  Map<String, Object?> toJson() => {
    'profile': {
      'nickname': profile.nickname,
      'rating': profile.rating,
      'goal': ?profile.goal?.name,
      'levelSource': ?profile.levelSource?.name,
      'lichessUser': ?profile.lichessUser,
      'chessComUser': ?profile.chessComUser,
      'avatarColor': profile.avatarColor,
      'googlePhoto': profile.googlePhoto,
      'country': ?profile.country,
    },
    if (rating case final rating?)
      'rating': {
        'rating': rating.rating,
        'deviation': rating.deviation,
        'volatility': rating.volatility,
      },
    'lessons': {
      for (final MapEntry(:key, :value) in lessons.entries)
        key: value.copyWith(clearExercise: true).toJson(),
    },
    'school': school.toList()..sort(),
    'stars': stars,
    'challenges': challenges.toList()..sort(),
    'positions': positions.toList()..sort(),
    'startRung': ?startRung,
    'speedruns': speedruns,
    'race': race.toJson(),
    'featured': featured.toList()..sort(),
  };

  /// Lê o documento da nuvem. Campo que falta ou veio estranho fica vazio:
  /// um app mais antigo pode ter gravado menos coisa.
  static ProgressSummary fromJson(Map<String, Object?> json) {
    final profile = _map(json['profile']);
    final rating = _map(json['rating']);
    final race = _map(json['race']);
    return ProgressSummary(
      profile: UserProfile(
        nickname: profile['nickname'] as String? ?? '',
        rating: _int(profile['rating']) ?? UserProfile.defaultRating,
        goal: GoalPreference.fromCode(profile['goal'] as String?),
        levelSource: LevelSource.fromCode(profile['levelSource'] as String?),
        lichessUser: profile['lichessUser'] as String?,
        chessComUser: profile['chessComUser'] as String?,
        avatarColor: _int(profile['avatarColor']) ?? 0,
        googlePhoto: profile['googlePhoto'] == true,
        country: profile['country'] as String?,
      ),
      rating: rating['rating'] is num
          ? PlayerRating(
              rating: (rating['rating']! as num).toDouble(),
              deviation:
                  (rating['deviation'] as num?)?.toDouble() ??
                  PlayerRating.initialDeviation,
              volatility:
                  (rating['volatility'] as num?)?.toDouble() ??
                  PlayerRating.initialVolatility,
            )
          : null,
      lessons: {
        for (final MapEntry(:key, :value) in _map(json['lessons']).entries)
          key: EndgameLessonProgress.fromJson(_map(value)),
      },
      school: _strings(json['school']),
      stars: _ints(json['stars']),
      challenges: _strings(json['challenges']),
      positions: _strings(json['positions']),
      startRung: _int(json['startRung']),
      speedruns: _ints(json['speedruns']),
      race: RaceRecord(
        corrects: _int(race['corrects']) ?? 0,
        hardest: _int(race['hardest']) ?? 0,
      ),
      featured: _strings(json['featured']),
    );
  }

  static Map<String, dynamic> _map(Object? value) => value is Map
      ? {
          for (final MapEntry(:key, :value) in value.entries)
            if (key is String) key: value,
        }
      : const {};

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static Set<String> _strings(Object? value) => {
    if (value is List)
      for (final item in value)
        if (item is String) item,
  };

  static Map<String, int> _ints(Object? value) => {
    for (final MapEntry(:key, :value) in _map(value).entries) key: ?_int(value),
  };
}
