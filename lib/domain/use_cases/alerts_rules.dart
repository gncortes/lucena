import '../models/alert_settings.dart';

/// Quais tópicos do FCM o aparelho segue, pelas chaves de Avisos e pela
/// região (E1.21, 3.13; push segmentado da E1.19, 3.8).
abstract final class AlertsRules {
  static final _code = RegExp(r'^[A-Z]{2}$');
  static final _language = RegExp(r'^[a-z]{2,3}$');

  /// Os tópicos de [settings]: o de todos sempre; os de torneio do [country]
  /// (e do [state], se for uma sigla, como `PR`) com "Finais de torneios";
  /// um global para "Novidades", outro para "Aulas novas" e o `dia` para
  /// "Final do dia". Com algum aviso de push ligado, também o público do
  /// painel: `pais_<PAIS>`, `pais_<PAIS>_<UF>` e `idioma_<xx>` ([language],
  /// o idioma do app). Sem país, sem torneio nem país. Estado escrito por
  /// extenso não vira tópico.
  static Set<String> topics(
    AlertSettings settings, {
    String? country,
    String? state,
    String? language,
  }) {
    final upper = country?.toUpperCase();
    final code = upper != null && _code.hasMatch(upper) ? upper : null;
    final upperState = state?.toUpperCase();
    final uf = upperState != null && _code.hasMatch(upperState)
        ? upperState
        : null;
    final lang = language?.toLowerCase();
    final anyPush =
        settings.tournaments ||
        settings.daily ||
        settings.news ||
        settings.lessons;
    return {
      AlertTopics.everyone,
      if (settings.tournaments && code != null) ...[
        AlertTopics.tournament(code),
        if (uf != null) AlertTopics.tournament(code, uf),
      ],
      if (anyPush && code != null) ...[
        AlertTopics.country(code),
        if (uf != null) AlertTopics.country(code, uf),
      ],
      if (anyPush && lang != null && _language.hasMatch(lang))
        AlertTopics.language(lang),
      if (settings.daily) AlertTopics.daily,
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
