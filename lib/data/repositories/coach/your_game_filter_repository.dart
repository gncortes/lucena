import '../../../domain/models/coach/coach.dart';
import '../../services/preferences_service.dart';

/// O ritmo escolhido nos chips da aba Seu jogo: fica gravado no aparelho e
/// volta igual depois de fechar o app.
class YourGameFilterRepository {
  YourGameFilterRepository(this._preferences);

  final PreferencesService _preferences;

  static const _key = 'treinador.seuJogo.ritmo';
  static const _everyone = 'todos';

  /// `null` = Todos.
  Future<TimeControl?> timeControl() async =>
      TimeControl.parse(await _preferences.getString(_key));

  Future<void> setTimeControl(TimeControl? timeControl) =>
      _preferences.setString(_key, timeControl?.wire ?? _everyone);
}
