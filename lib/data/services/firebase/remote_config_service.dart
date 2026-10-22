import 'package:firebase_remote_config/firebase_remote_config.dart';

/// O Remote Config do Firebase (E1.32): valores que mudam sem publicar o app.
///
/// Os padrões vêm de `remote_defaults.dart`, gerado do mesmo modelo que o CI
/// publica. Sem rede vale o último valor buscado; sem nunca ter buscado, o
/// padrão.
abstract class RemoteConfigService {
  /// Grava os [defaults] e o intervalo mínimo entre buscas. Não busca nada.
  Future<void> start({
    required Map<String, Object> defaults,
    required Duration minimumFetchInterval,
  });

  /// Busca e passa a usar os valores novos. Verdadeiro: algum valor mudou.
  Future<bool> fetchAndActivate();

  int getInt(String key);

  bool getBool(String key);

  String getString(String key);

  /// As chaves que mudaram no console, já ativadas (tempo real).
  Stream<Set<String>> get onUpdated;
}

/// Sem Firebase (F-Droid, CI de PR, testes): só os padrões.
class NoRemoteConfigService implements RemoteConfigService {
  NoRemoteConfigService();

  Map<String, Object> _defaults = const {};

  @override
  Future<void> start({
    required Map<String, Object> defaults,
    required Duration minimumFetchInterval,
  }) async => _defaults = defaults;

  @override
  Future<bool> fetchAndActivate() async => false;

  @override
  int getInt(String key) => switch (_defaults[key]) {
    final int value => value,
    _ => 0,
  };

  @override
  bool getBool(String key) => _defaults[key] == true;

  @override
  String getString(String key) => switch (_defaults[key]) {
    final String value => value,
    _ => '',
  };

  @override
  Stream<Set<String>> get onUpdated => const Stream.empty();
}

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService([FirebaseRemoteConfig? config])
    : _config = config ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _config;

  /// A busca não segura a abertura por mais do que isto (E1.32 §3).
  static const fetchTimeout = Duration(seconds: 3);

  @override
  Future<void> start({
    required Map<String, Object> defaults,
    required Duration minimumFetchInterval,
  }) async {
    await _config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ),
    );
    await _config.setDefaults(defaults);
    await _config.ensureInitialized();
  }

  @override
  Future<bool> fetchAndActivate() => _config.fetchAndActivate();

  @override
  int getInt(String key) => _config.getInt(key);

  @override
  bool getBool(String key) => _config.getBool(key);

  @override
  String getString(String key) => _config.getString(key);

  // A mudança chega buscada, mas só vale depois de ativar.
  @override
  Stream<Set<String>> get onUpdated =>
      _config.onConfigUpdated.asyncMap((update) async {
        await _config.activate();
        return update.updatedKeys;
      });
}
