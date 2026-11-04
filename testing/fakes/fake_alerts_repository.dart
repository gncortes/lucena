import 'package:lucena/data/repositories/alerts/alerts_repository.dart';
import 'package:lucena/domain/models/alert_settings.dart';

/// As chaves de Avisos na memória.
class FakeAlertsRepository implements AlertsRepository {
  FakeAlertsRepository([this.settings = const AlertSettings()]);

  AlertSettings settings;
  int saves = 0;

  /// Quando não nulo, a próxima gravação lança este erro (e nada é gravado).
  Object? saveError;

  /// Quando não nulo, a próxima leitura lança este erro.
  Object? loadError;

  @override
  Future<AlertSettings> load() async {
    final error = loadError;
    if (error != null) {
      loadError = null;
      throw error;
    }
    return settings;
  }

  @override
  Future<void> save(AlertSettings settings) async {
    final error = saveError;
    if (error != null) {
      saveError = null;
      throw error;
    }
    saves++;
    this.settings = settings;
  }
}
