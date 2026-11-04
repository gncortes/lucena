import '../models/ads_state.dart';
import '../models/course_access.dart';

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

/// Onde a pessoa está entrando (H-LIC-15): só a porta da lição e a da lista de
/// exercícios têm anúncio; dentro da lição e no teste do capítulo, nunca.
enum DemoAdEntry { lesson, list, insideLesson, test }

/// O que vem antes de abrir: nada, o aviso do primeiro anúncio ou o anúncio.
enum DemoAdStep { none, notice, ad }

/// As regras do anúncio da demonstração do Pilares (T85-D1, H-LIC-08 a 15) e
/// do capítulo trancado (H-LIC-06): Dart puro, sem relógio nem tela.
abstract final class DemoAdPolicy {
  /// Quanto o anúncio fica antes de poder fechar.
  static const countdown = Duration(seconds: 3);

  /// Comprador não vê aviso nem anúncio; a demo vê o aviso uma vez e depois
  /// o anúncio em toda entrada.
  static DemoAdStep stepFor({
    required CourseAccess access,
    required DemoAdEntry entry,
    required bool noticeSeen,
  }) {
    if (!access.seesAds) return DemoAdStep.none;
    if (entry == DemoAdEntry.insideLesson || entry == DemoAdEntry.test) {
      return DemoAdStep.none;
    }
    return noticeSeen ? DemoAdStep.ad : DemoAdStep.notice;
  }

  /// O número que o botão mostra ("Fechar em 3"); 0 libera o "Fechar".
  static int secondsLeft(Duration elapsed) {
    final left = countdown - elapsed;
    if (left <= Duration.zero) return 0;
    return (left.inMilliseconds / 1000).ceil();
  }

  static final _chapterId = RegExp(r'pilares\.c(\d+)');

  /// O número do capítulo de um id (`pilares.c2` ou `pilares.c2.parte`) ou
  /// de um caminho que o cita; nulo se não é do Pilares.
  static int? chapterOf(String idOrPath) {
    final match = _chapterId.firstMatch(Uri.decodeComponent(idOrPath));
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// Só o Capítulo 1 abre sem o curso completo.
  static bool isChapterLocked(CourseAccess access, int chapter) =>
      !access.hasFullCourse && chapter > 1;
}
