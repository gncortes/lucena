import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/ads_state.dart';
import 'package:lucena/domain/use_cases/ad_policy.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 10);
  // 2ª sessão, 3ª lição aberta: passou da carência.
  const ready = AdsState(sessions: 2, lessonsOpened: 3);

  AdDecision decide({
    AdsState state = ready,
    LessonKind kind = LessonKind.endgame,
    String lessonId = 'opposition',
    bool consentReady = true,
    bool adReady = true,
    bool adFree = false,
    AdsConfig config = const AdsConfig(),
  }) => AdPolicy(config).decide(
    state: state,
    kind: kind,
    lessonId: lessonId,
    now: now,
    consentReady: consentReady,
    adReady: adReady,
    adFree: adFree,
  );

  test('passada a carência, abrir lição de final ou da Escola mostra', () {
    expect(decide(), AdDecision.show);
    expect(decide(kind: LessonKind.school), AdDecision.show);
  });

  test('a 1ª sessão inteira não tem anúncio', () {
    expect(
      decide(state: const AdsState(sessions: 1, lessonsOpened: 9)),
      AdDecision.grace,
    );
  });

  test('as 2 primeiras lições abertas não têm anúncio', () {
    expect(
      decide(state: const AdsState(sessions: 3, lessonsOpened: 2)),
      AdDecision.grace,
    );
    expect(
      decide(state: const AdsState(sessions: 3, lessonsOpened: 3)),
      AdDecision.show,
    );
  });

  test('ads_free_lessons muda a carência', () {
    expect(decide(config: const AdsConfig(freeLessons: 5)), AdDecision.grace);
  });

  test('no máximo 1 por lição por sessão', () {
    final state = ready.copyWith(shownThisSession: {'opposition'});
    expect(decide(state: state), AdDecision.alreadyThisLesson);
    expect(decide(state: state, lessonId: 'lucena'), AdDecision.show);
  });

  test('intervalo mínimo entre dois anúncios', () {
    final recent = ready.copyWith(
      lastShownAt: now.subtract(const Duration(seconds: 179)),
    );
    expect(decide(state: recent), AdDecision.gap);
    final old = ready.copyWith(
      lastShownAt: now.subtract(const Duration(seconds: 180)),
    );
    expect(decide(state: old), AdDecision.show);
  });

  test('desafio por link, final do dia e torneio nunca têm anúncio', () {
    for (final kind in [
      LessonKind.challengeLink,
      LessonKind.daily,
      LessonKind.tournament,
    ]) {
      expect(decide(kind: kind), AdDecision.wrongKind);
    }
  });

  test('sem anúncios comprado, nada', () {
    expect(decide(adFree: true), AdDecision.adFree);
  });

  test('ads_enabled desligado, nada', () {
    expect(
      decide(config: const AdsConfig(enabled: false)),
      AdDecision.disabled,
    );
  });

  test('sem consentimento resolvido, nada', () {
    expect(decide(consentReady: false), AdDecision.noConsent);
  });

  test('anúncio não carregado: a lição abre direto', () {
    expect(decide(adReady: false), AdDecision.notReady);
  });

  test('sessão nova depois de 30 minutos em segundo plano', () {
    final hidden = now.subtract(const Duration(minutes: 29));
    expect(AdPolicy.isNewSession(hidden, now), isFalse);
    expect(
      AdPolicy.isNewSession(now.subtract(const Duration(minutes: 30)), now),
      isTrue,
    );
  });

  test('a sessão nova esquece as lições da anterior e não grava a lista', () {
    final state = ready.copyWith(shownThisSession: {'opposition'});
    final next = state.newSession();
    expect(next.sessions, 3);
    expect(next.shownThisSession, isEmpty);
    expect(AdsState.fromJson(state.toJson()).shownThisSession, isEmpty);
  });
}
