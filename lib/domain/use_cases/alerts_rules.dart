import '../models/alert_settings.dart';

/// Quais tópicos do FCM o aparelho segue, pelas chaves de Avisos e pela
/// região (E1.21, 3.13).
abstract final class AlertsRules {
  /// Os tópicos de [settings]: o de todos sempre; os de torneio do [country]
  /// (e do [state], se houver) com "Finais de torneios"; um global para
  /// "Novidades" e outro para "Aulas novas". Sem país, sem torneio.
  static Set<String> topics(
    AlertSettings settings, {
    String? country,
    String? state,
  }) {
    final code = country?.toUpperCase();
    final uf = state?.toUpperCase();
    return {
      AlertTopics.everyone,
      if (settings.tournaments && code != null && code.isNotEmpty) ...[
        AlertTopics.tournament(code),
        if (uf != null && uf.isNotEmpty) AlertTopics.tournament(code, uf),
      ],
      if (settings.news) AlertTopics.news,
      if (settings.lessons) AlertTopics.lessons,
    };
  }

  /// O que mudar para ir de [followed] a [wanted]: em quais entrar e de
  /// quais sair.
  static ({Set<String> subscribe, Set<String> unsubscribe}) changes(
    Set<String> followed,
    Set<String> wanted,
  ) => (
    subscribe: wanted.difference(followed),
    unsubscribe: followed.difference(wanted),
  );
}
