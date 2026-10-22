import 'package:firebase_analytics/firebase_analytics.dart';

/// O Google Analytics pelo Firebase (E1.03). Sem regra nenhuma: o que sai e
/// quando sai é do `AnalyticsRepository`.
abstract class AnalyticsService {
  /// Falso sem o Firebase (build do F-Droid) ou com o build que não mede.
  bool get available;

  Future<void> logEvent(String name, Map<String, Object> params);

  Future<void> setUserProperty(String name, String? value);

  /// Liga ou desliga o envio. Desligado, o SDK não guarda nada.
  Future<void> setCollectionEnabled(bool enabled);

  /// Apaga o id do aparelho e os eventos ainda não enviados.
  Future<void> resetData();

  /// O Consent Mode v2: [analytics] para a medição, [ads] para os anúncios
  /// (E1.25 chama depois do UMP).
  Future<void> setConsent({required bool analytics, required bool ads});
}

class NoAnalyticsService implements AnalyticsService {
  const NoAnalyticsService();

  @override
  bool get available => false;

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> resetData() async {}

  @override
  Future<void> setConsent({required bool analytics, required bool ads}) async {}
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  bool get available => true;

  @override
  Future<void> logEvent(String name, Map<String, Object> params) =>
      _analytics.logEvent(name: name, parameters: params);

  @override
  Future<void> setUserProperty(String name, String? value) =>
      _analytics.setUserProperty(name: name, value: value);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _analytics.setAnalyticsCollectionEnabled(enabled);

  @override
  Future<void> resetData() => _analytics.resetAnalyticsData();

  @override
  Future<void> setConsent({required bool analytics, required bool ads}) =>
      _analytics.setConsent(
        analyticsStorageConsentGranted: analytics,
        adStorageConsentGranted: ads,
        adUserDataConsentGranted: ads,
        adPersonalizationSignalsConsentGranted: ads,
      );
}
