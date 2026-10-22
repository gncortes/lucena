import 'package:lucena/data/services/secure_storage_service.dart';

/// Um armazenamento seguro em memória.
class FakeSecureStorageService implements SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
