import 'dart:async';
import 'dart:convert';

import '../../../domain/models/ads_state.dart';
import '../../../domain/use_cases/ad_policy.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/ads_service.dart';
import '../../services/preferences_service.dart';
import '../config/remote_flags_repository.dart';
import '../purchase/purchase_repository.dart';

/// O que aconteceu no toque que abre a lição: nada, o anúncio do SDK já
/// passou, ou o app tem que desenhar o anúncio (o falso do modo E2E).
enum AdOutcome { none, shown, showInApp }

/// O consentimento do Google e o intersticial antes da lição (E1.25).
abstract class AdsRepository {
  /// Na abertura: conta a sessão e, se a pergunta do objetivo já foi
  /// respondida e a pessoa não veio por link, pede o consentimento. Sem
  /// esperar o formulário, carrega o primeiro anúncio.
  Future<void> start({required bool fromLink, required bool goalAnswered});

  /// Depois da pergunta do objetivo: o formulário do Google, se exigido.
  /// Nada para quem comprou ou veio por link nesta sessão.
  Future<void> requestConsent();

  /// No toque que abre a lição [lessonId]: conta a lição e, se o
  /// [AdPolicy] deixa, mostra o anúncio. Nunca espera carregar.
  Future<AdOutcome> beforeLesson({
    required String lessonId,
    required LessonKind kind,
  });

  /// O app foi para o segundo plano.
  void hidden();

  /// O app voltou; depois de 30 minutos fora, é sessão nova.
  void visible();

  /// A pessoa viu um anúncio nesta sessão (a E1.26 não pede avaliação).
  bool get shownThisSession;

  /// Avisa cada anúncio mostrado.
  Stream<void> get adShown;

  /// "Escolhas de anúncios" aparece na Privacidade.
  Future<bool> privacyOptionsRequired();

  Future<void> showPrivacyOptions();
}

class ServiceAdsRepository implements AdsRepository {
  ServiceAdsRepository({
    required this._service,
    required this._preferences,
    required this._flags,
    required this._purchases,
    required this._now,
  });

  final AdsService _service;
  final PreferencesService _preferences;
  final RemoteFlagsRepository _flags;
  final PurchaseRepository _purchases;
  final Now _now;

  static const stateKey = 'ads.state';

  final _adShown = StreamController<void>.broadcast();
  AdsState _state = const AdsState();
  Future<void>? _loaded;
  bool _fromLink = false;
  bool _consentReady = false;
  bool _consentOpen = false;
  bool _shownThisSession = false;
  DateTime? _hiddenAt;

  bool get _adFree => _purchases.state.adFree;

  @override
  bool get shownThisSession => _shownThisSession;

  @override
  Stream<void> get adShown => _adShown.stream;

  @override
  Future<void> start({required bool fromLink, required bool goalAnswered}) {
    _fromLink = fromLink;
    return _loaded ??= _start(goalAnswered: goalAnswered);
  }

  Future<void> _start({required bool goalAnswered}) async {
    _state = (await _read()).newSession();
    unawaited(_save());
    await _purchases.start();
    if (_adFree) return;
    // Primeira abertura: o formulário espera a pergunta do objetivo.
    if (goalAnswered) unawaited(requestConsent());
  }

  Future<AdsState> _read() async {
    final raw = await _preferences.getString(stateKey);
    if (raw == null) return const AdsState();
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?>
          ? AdsState.fromJson(json)
          : const AdsState();
    } on FormatException {
      return const AdsState();
    }
  }

  Future<void> _save() =>
      _preferences.setString(stateKey, jsonEncode(_state.toJson()));

  @override
  Future<void> requestConsent() async {
    if (_adFree || _consentOpen) return;
    _consentOpen = true;
    try {
      await _service.updateConsent();
      // Quem veio por link vê o formulário na próxima abertura normal.
      if (!_fromLink) await _service.showConsentFormIfRequired();
    } on Exception {
      // Sem rede: vale o que o SDK já guardou.
    } finally {
      _consentOpen = false;
    }
    await _prepare();
  }

  Future<void> _prepare() async {
    if (_adFree) return;
    try {
      _consentReady = await _service.canRequestAds();
      if (!_consentReady || _adFree) return;
      await _service.initialize();
      _service.preload();
    } on Exception {
      _consentReady = false;
    }
  }

  @override
  Future<AdOutcome> beforeLesson({
    required String lessonId,
    required LessonKind kind,
  }) async {
    await _loaded;
    final now = _now();
    _state = _state.copyWith(lessonsOpened: _state.lessonsOpened + 1);
    final decision =
        AdPolicy(
          AdsConfig(
            enabled: _flags.adsEnabled,
            freeLessons: _flags.adsFreeLessons,
            minGapSeconds: _flags.adsMinGapSeconds,
          ),
        ).decide(
          state: _state,
          kind: kind,
          lessonId: lessonId,
          now: now,
          consentReady: _consentReady && !_consentOpen,
          adReady: _service.ready,
          adFree: _adFree,
        );
    if (decision == AdDecision.notReady) _service.preload();
    if (decision != AdDecision.show) {
      unawaited(_save());
      return AdOutcome.none;
    }
    _state = _state.copyWith(
      lastShownAt: now,
      shownThisSession: {..._state.shownThisSession, lessonId},
    );
    unawaited(_save());
    _shownThisSession = true;
    _adShown.add(null);
    if (_service.drawsInApp) return AdOutcome.showInApp;
    final shown = await _service.show();
    _service.preload();
    return shown ? AdOutcome.shown : AdOutcome.none;
  }

  @override
  void hidden() => _hiddenAt = _now();

  @override
  void visible() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null || !AdPolicy.isNewSession(hiddenAt, _now())) return;
    _state = _state.newSession();
    _shownThisSession = false;
    unawaited(_save());
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    if (_adFree) return false;
    try {
      return await _service.privacyOptionsRequired();
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await _service.showPrivacyOptions();
    } on Exception {
      // A janela do Google não abriu; a tela continua.
    }
  }
}

/// Sem anúncios (F-Droid, sem Firebase, testes).
class NoAdsRepository implements AdsRepository {
  const NoAdsRepository();

  @override
  Future<void> start({
    required bool fromLink,
    required bool goalAnswered,
  }) async {}

  @override
  Future<void> requestConsent() async {}

  @override
  Future<AdOutcome> beforeLesson({
    required String lessonId,
    required LessonKind kind,
  }) async => AdOutcome.none;

  @override
  void hidden() {}

  @override
  void visible() {}

  @override
  bool get shownThisSession => false;

  @override
  Stream<void> get adShown => const Stream.empty();

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}
