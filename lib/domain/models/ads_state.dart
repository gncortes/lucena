/// Os números do anúncio que vêm do Remote Config (E1.25), com o padrão do
/// código para quando não há rede.
class AdsConfig {
  const AdsConfig({
    this.enabled = true,
    this.freeLessons = 2,
    this.minGapSeconds = 180,
  });

  /// `ads_enabled`: o interruptor geral.
  final bool enabled;

  /// `ads_free_lessons`: as primeiras lições abertas não têm anúncio.
  final int freeLessons;

  /// `ads_min_gap_seconds`: o mínimo entre dois anúncios.
  final int minGapSeconds;

  @override
  bool operator ==(Object other) =>
      other is AdsConfig &&
      other.enabled == enabled &&
      other.freeLessons == freeLessons &&
      other.minGapSeconds == minGapSeconds;

  @override
  int get hashCode => Object.hash(enabled, freeLessons, minGapSeconds);
}

/// De onde vem a lição que a pessoa tocou para abrir. Só as lições de finais
/// e as da Escola têm anúncio.
enum LessonKind { endgame, school, challengeLink, daily, tournament }

/// O que o aparelho guarda para decidir o anúncio: quantas sessões e lições
/// abertas já houve e quando passou o último. [shownThisSession] (as lições
/// que já tiveram anúncio nesta sessão) não é gravado.
class AdsState {
  const AdsState({
    this.sessions = 0,
    this.lessonsOpened = 0,
    this.lastShownAt,
    this.shownThisSession = const {},
  });

  final int sessions;
  final int lessonsOpened;
  final DateTime? lastShownAt;
  final Set<String> shownThisSession;

  AdsState copyWith({
    int? sessions,
    int? lessonsOpened,
    DateTime? lastShownAt,
    Set<String>? shownThisSession,
  }) => AdsState(
    sessions: sessions ?? this.sessions,
    lessonsOpened: lessonsOpened ?? this.lessonsOpened,
    lastShownAt: lastShownAt ?? this.lastShownAt,
    shownThisSession: shownThisSession ?? this.shownThisSession,
  );

  /// Sessão nova: as lições com anúncio voltam a poder ter.
  AdsState newSession() => AdsState(
    sessions: sessions + 1,
    lessonsOpened: lessonsOpened,
    lastShownAt: lastShownAt,
  );

  Map<String, Object?> toJson() => {
    'sessions': sessions,
    'lessonsOpened': lessonsOpened,
    if (lastShownAt != null) 'lastShownAt': lastShownAt!.toIso8601String(),
  };

  /// JSON estragado vale como "do zero".
  static AdsState fromJson(Map<String, Object?> json) {
    final sessions = json['sessions'];
    final lessons = json['lessonsOpened'];
    final last = json['lastShownAt'];
    return AdsState(
      sessions: sessions is int ? sessions : 0,
      lessonsOpened: lessons is int ? lessons : 0,
      lastShownAt: last is String ? DateTime.tryParse(last) : null,
    );
  }
}

/// A resposta do [AdPolicy]: [show] ou o motivo de não mostrar.
enum AdDecision {
  show,
  adFree,
  disabled,
  wrongKind,
  noConsent,
  grace,
  alreadyThisLesson,
  gap,
  notReady,
}
