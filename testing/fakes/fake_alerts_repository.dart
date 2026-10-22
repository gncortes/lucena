import 'package:lucena/data/repositories/alerts/alerts_repository.dart';
import 'package:lucena/domain/models/alert_settings.dart';

/// As chaves de Avisos na memória.
class FakeAlertsRepository implements AlertsRepository {
  FakeAlertsRepository([this.settings = const AlertSettings()]);

  AlertSettings settings;
  int saves = 0;

  @override
  Future<AlertSettings> load() async => settings;

  @override
  Future<void> save(AlertSettings settings) async {
    saves++;
    this.settings = settings;
  }
}
