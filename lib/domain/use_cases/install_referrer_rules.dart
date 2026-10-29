import '../models/app_links.dart';
import '../models/challenge_link.dart';
import '../models/linked_lesson.dart';

/// Lê o link de campanha do `referrer` da Play Store (deferred deep link,
/// T84). O link de instalação leva o caminho do app, codificado uma vez:
/// `play.google.com/store/apps/details?id=com.gncortes.lucena&referrer=<x>`,
/// com `<x>` em uma destas formas (a Play devolve já decodificado):
/// - o caminho com a query: `/p/k7Qe2?fen=...&aula=rook.lucena&utm_source=instagram`;
/// - o endereço inteiro: `https://playlucena.com/aula/rook.lucena?utm_source=...`;
/// - `link=<endereço codificado>`, ao lado dos `utm_*` da própria Play.
abstract final class InstallReferrerRules {
  /// O link do app em [referrer], ou nulo (instalação orgânica, texto de
  /// outra origem, desafio inválido).
  static Uri? link(String? referrer) {
    final text = referrer?.trim();
    if (text == null || text.isEmpty) return null;
    try {
      if (text.startsWith('/')) {
        return _valid(Uri.parse('https://${AppLinks.finalHost}$text'));
      }
      if (text.startsWith('https://')) return _valid(Uri.parse(text));
      final nested = Uri.splitQueryString(text)['link'];
      if (nested != null && !nested.startsWith('link=')) return link(nested);
    } on FormatException {
      return null;
    }
    return null;
  }

  static Uri? _valid(Uri uri) {
    if (!AppLinks.isOwn(uri)) return null;
    if (LessonLink.tryParse(uri) != null) return uri;
    return ChallengeLink.tryParse(uri) == null ? null : uri;
  }
}
