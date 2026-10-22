import '../../services/app_update_service.dart';
import '../../services/preferences_service.dart';

export '../../services/app_update_service.dart' show PlayUpdateInfo;

/// O build instalado, a Play e a recomendada já vista (E1.32 §3).
abstract class AppUpdateRepository {
  /// O `versionCode` instalado.
  Future<int> installedBuild();

  Future<PlayUpdateInfo> check();

  Future<bool> immediate();

  Future<bool> flexible();

  Future<void> completeFlexible();

  Future<void> openStore();

  /// O valor de `update_recommended_build` que a pessoa já viu (0: nenhum).
  Future<int> recommendedSeen();

  Future<void> markRecommendedSeen(int build);
}

class PlayAppUpdateRepository implements AppUpdateRepository {
  PlayAppUpdateRepository(
    this._service,
    this._preferences, {
    required this._build,
  });

  final AppUpdateService _service;
  final PreferencesService _preferences;
  final Future<int> Function() _build;

  static const seenKey = 'update.v1.recommended_seen';

  @override
  Future<int> installedBuild() => _build();

  @override
  Future<PlayUpdateInfo> check() => _service.check();

  @override
  Future<bool> immediate() => _service.immediate();

  @override
  Future<bool> flexible() => _service.flexible();

  @override
  Future<void> completeFlexible() => _service.completeFlexible();

  @override
  Future<void> openStore() => _service.openStore();

  @override
  Future<int> recommendedSeen() async =>
      int.tryParse(await _preferences.getString(seenKey) ?? '') ?? 0;

  @override
  Future<void> markRecommendedSeen(int build) =>
      _preferences.setString(seenKey, '$build');
}

/// Sem Play nem preferências (testes que não olham a atualização): nunca há
/// versão nova.
class NoAppUpdateRepository implements AppUpdateRepository {
  const NoAppUpdateRepository();

  @override
  Future<int> installedBuild() async => 0;

  @override
  Future<PlayUpdateInfo> check() async => const PlayUpdateInfo();

  @override
  Future<bool> immediate() async => false;

  @override
  Future<bool> flexible() async => false;

  @override
  Future<void> completeFlexible() async {}

  @override
  Future<void> openStore() async {}

  @override
  Future<int> recommendedSeen() async => 0;

  @override
  Future<void> markRecommendedSeen(int build) async {}
}
