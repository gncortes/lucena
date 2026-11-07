import '../../services/preferences_service.dart';

/// O anúncio da demonstração e o aviso do primeiro anúncio (H-LIC-08, 10, 11).
abstract interface class DemoAdRepository {
  /// A pessoa já viu o aviso "Antes da lição, um anúncio".
  Future<bool> noticeSeen();

  /// Grava que o aviso foi visto: ele aparece uma vez só.
  Future<void> markNoticeSeen();

  /// Carrega o anúncio. `false`: não carregou (sem internet ou falha), e a
  /// lição não abre.
  Future<bool> load();
}

/// O aviso visto vai para o aparelho; o anúncio é o espaço desenhado pelo app
/// (a V1 não tem SDK de anúncios), que sempre carrega.
final class LocalDemoAdRepository implements DemoAdRepository {
  LocalDemoAdRepository(this._preferences);

  final PreferencesService _preferences;

  static const noticeSeenKey = 'lesson.demoAdNoticeSeen';

  @override
  Future<bool> noticeSeen() async =>
      await _preferences.getBool(noticeSeenKey) ?? false;

  @override
  Future<void> markNoticeSeen() =>
      _preferences.setBool(noticeSeenKey, value: true);

  @override
  Future<bool> load() async => true;
}

/// Sem anúncio (testes que não falam dele): nada a ver, nada a carregar.
final class NoDemoAdRepository implements DemoAdRepository {
  const NoDemoAdRepository();

  @override
  Future<bool> noticeSeen() async => true;

  @override
  Future<void> markNoticeSeen() async {}

  @override
  Future<bool> load() async => true;
}
