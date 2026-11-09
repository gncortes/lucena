import '../../../domain/models/treinador/treinador.dart';
import '../../services/preferences_service.dart';

/// O ritmo escolhido nos chips da aba Seu jogo: fica gravado no aparelho e
/// volta igual depois de fechar o app.
class SeuJogoFiltroRepository {
  SeuJogoFiltroRepository(this._preferences);

  final PreferencesService _preferences;

  static const _chave = 'treinador.seuJogo.ritmo';
  static const _todos = 'todos';

  /// `null` = Todos.
  Future<Ritmo?> ritmo() async =>
      Ritmo.parse(await _preferences.getString(_chave));

  Future<void> definirRitmo(Ritmo? ritmo) =>
      _preferences.setString(_chave, ritmo?.wire ?? _todos);
}
