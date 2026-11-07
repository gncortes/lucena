import 'package:lucena/data/services/preferences_service.dart';

/// A manually mounted bank must not share state with the surrounding course.
class TrainingFixturePreferences extends PreferencesService {
  TrainingFixturePreferences(this.scope, {PreferencesService? delegate})
    : _delegate = delegate ?? PreferencesService();
  final String scope;
  final PreferencesService _delegate;

  @override
  Future<String?> getString(String key) =>
      _delegate.getString('testing.t85.$scope.$key');
  @override
  Future<void> setString(String key, String value) =>
      _delegate.setString('testing.t85.$scope.$key', value);
}
