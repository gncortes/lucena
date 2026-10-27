import 'challenge_link.dart';
import 'linked_lesson.dart';

/// A campanha de quem chegou por um link de post (T84): os `utm_*`, o código
/// do desafio (nulo no link só de aula) e a aula ligada. Fica gravada para o
/// funil do Analytics atribuir a aula concluída dias depois.
class Campaign {
  const Campaign({this.utm = const {}, this.code, this.lesson});

  /// A campanha do desafio [link].
  factory Campaign.fromChallenge(ChallengeLink link) =>
      Campaign(utm: link.utm, code: link.code, lesson: link.lesson);

  /// A campanha do link só de aula [link].
  factory Campaign.fromLessonLink(LessonLink link) =>
      Campaign(utm: link.utm, lesson: link.lesson);

  final Map<String, String> utm;

  /// O código do desafio. Nulo: o link abriu direto a aula.
  final String? code;

  final LinkedLesson? lesson;

  /// `desafio|aula`: o tipo do link.
  String get kind => code == null ? 'aula' : 'desafio';

  Map<String, Object?> toJson() => {
    'utm': utm,
    'code': ?code,
    if (lesson != null) 'lesson': {'kind': lesson!.kind.code, 'id': lesson!.id},
  };

  /// Nula se [json] não for uma campanha gravada.
  static Campaign? fromJson(Object? json) {
    if (json is! Map) return null;
    final utm = json['utm'];
    final lesson = json['lesson'];
    LinkedLesson? linked;
    if (lesson is Map) {
      final kind = LinkedLessonKind.fromCode(lesson['kind'] as String?);
      final id = lesson['id'];
      if (kind != null && id is String && id.isNotEmpty) {
        linked = LinkedLesson(kind, id);
      }
    }
    return Campaign(
      utm: utm is Map
          ? {
              for (final entry in utm.entries)
                if (entry.key is String && entry.value is String)
                  entry.key as String: entry.value as String,
            }
          : const {},
      code: json['code'] as String?,
      lesson: linked,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Campaign &&
      other.code == code &&
      other.lesson == lesson &&
      other.utm.length == utm.length &&
      utm.entries.every((entry) => other.utm[entry.key] == entry.value);

  @override
  int get hashCode => Object.hash(code, lesson, utm.length);
}
