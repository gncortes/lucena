import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda segredos (o token do Lichess) no armazenamento seguro do aparelho.
/// Nunca nas preferências, nunca no log.
abstract class SecureStorageService {
  /// Nulo quando não há nada gravado ou o armazenamento falhou.
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// O Keystore do Android, pelo `flutter_secure_storage`.
class DeviceSecureStorageService implements SecureStorageService {
  DeviceSecureStorageService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on Object {
      // Sem o que apagar.
    }
  }
}
