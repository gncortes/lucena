import 'app_links.dart';

/// De que curso é a aula que um link de campanha aponta (T84).
enum LinkedLessonKind {
  /// Uma aula de finais (`/endgames/<id>`).
  endgame('aula'),

  /// Uma aula da Escola do Viktor, do iniciante (`/school/<id>/roteiro`).
  school('escola');

  const LinkedLessonKind(this.code);

  /// O nome do parâmetro no link do desafio e o começo do caminho do link
  /// só de aula (`<host>/aula/<id>`, `<host>/escola/<id>`).
  final String code;

  static LinkedLessonKind? fromCode(String? code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// A aula ligada a um link de campanha: a do desafio (`?aula=<id>`) ou a que
/// o link abre sozinho (`/aula/<id>`).
class LinkedLesson {
  const LinkedLesson(this.kind, this.id);

  const LinkedLesson.endgame(this.id) : kind = LinkedLessonKind.endgame;

  const LinkedLesson.school(this.id) : kind = LinkedLessonKind.school;

  final LinkedLessonKind kind;
  final String id;

  /// O `tipo_aula` do Analytics (`finais|escola`).
  String get analyticsKind =>
      kind == LinkedLessonKind.school ? 'escola' : 'finais';

  /// Lê a aula dos parâmetros de um desafio: `aula` vence `escola`. Nula sem
  /// nenhum dos dois ou com id vazio.
  static LinkedLesson? fromQuery(Map<String, String> query) {
    for (final kind in LinkedLessonKind.values) {
      final id = query[kind.code]?.trim();
      if (id != null && id.isNotEmpty) return LinkedLesson(kind, id);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is LinkedLesson && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'LinkedLesson(${kind.code}, $id)';
}

/// O link de campanha que abre direto numa aula, sem desafio
/// (`https://playlucena.com/aula/rook.lucena?utm_source=instagram&utm_campaign=lucena`).
class LessonLink {
  const LessonLink({required this.lesson, this.utm = const {}});

  final LinkedLesson lesson;

  /// Os `utm_*` do post, como no desafio.
  final Map<String, String> utm;

  static const _utmKeys = [
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
  ];

  /// Lê o link só de aula. Nulo se o caminho não for `/aula/<id>` ou
  /// `/escola/<id>`, ou se não for um endereço do app.
  static LessonLink? tryParse(Uri uri) {
    if (!AppLinks.isOwn(uri)) return null;
    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.length != 2) return null;
    final kind = LinkedLessonKind.fromCode(segments.first);
    if (kind == null) return null;
    final query = uri.queryParameters;
    return LessonLink(
      lesson: LinkedLesson(kind, segments[1]),
      utm: {
        for (final key in _utmKeys)
          if (query[key] != null) key: query[key]!,
      },
    );
  }
}

/// O que a folha da aula gratuita mostra da aula de um link (T84): o título,
/// o módulo (o rótulo da categoria) e a posição do tabuleirinho.
class LinkedLessonInfo {
  const LinkedLessonInfo({
    required this.kind,
    required this.title,
    this.module,
    this.fen,
  });

  final LinkedLessonKind kind;
  final String title;

  /// O título do módulo da trilha de finais ("Finais de torre"). Nulo na
  /// Escola.
  final String? module;

  /// A posição-base da aula. Nula: sem tabuleirinho.
  final String? fen;

  @override
  bool operator ==(Object other) =>
      other is LinkedLessonInfo &&
      other.kind == kind &&
      other.title == title &&
      other.module == module &&
      other.fen == fen;

  @override
  int get hashCode => Object.hash(kind, title, module, fen);
}
