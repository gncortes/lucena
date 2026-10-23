import '../models/ads_state.dart';

/// Quando o intersticial toca (E1.25, item 3): só no toque que abre uma lição
/// de finais ou da Escola, depois da carência, no máximo 1 por lição por
/// sessão, com intervalo mínimo, consentimento resolvido e anúncio pronto.
class AdPolicy {
  const AdPolicy(this._config);

  final AdsConfig _config;

  /// Sessão = do abrir do app até ele ficar isto em segundo plano.
  static const sessionTimeout = Duration(minutes: 30);

  /// Voltou do segundo plano em [now] depois de sair em [hiddenAt]: começa
  /// sessão nova?
  static bool isNewSession(DateTime hiddenAt, DateTime now) =>
      now.difference(hiddenAt) >= sessionTimeout;

  /// [state] já conta a lição que está abrindo e a sessão atual (a 1ª sessão
  /// tem `sessions == 1`).
  AdDecision decide({
    required AdsState state,
    required LessonKind kind,
    required String lessonId,
    required DateTime now,
    required bool consentReady,
    required bool adReady,
    required bool adFree,
  }) {
    if (adFree) return AdDecision.adFree;
    if (!_config.enabled) return AdDecision.disabled;
    if (kind != LessonKind.endgame && kind != LessonKind.school) {
      return AdDecision.wrongKind;
    }
    if (!consentReady) return AdDecision.noConsent;
    if (state.sessions < 2 || state.lessonsOpened <= _config.freeLessons) {
      return AdDecision.grace;
    }
    if (state.shownThisSession.contains(lessonId)) {
      return AdDecision.alreadyThisLesson;
    }
    final last = state.lastShownAt;
    if (last != null &&
        now.difference(last) < Duration(seconds: _config.minGapSeconds)) {
      return AdDecision.gap;
    }
    if (!adReady) return AdDecision.notReady;
    return AdDecision.show;
  }
}
