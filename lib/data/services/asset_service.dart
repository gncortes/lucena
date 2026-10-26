import 'package:flutter/services.dart';

/// Embrulha a leitura de arquivos que vêm dentro do app.
class AssetService {
  const AssetService([AssetBundle? bundle]) : _bundle = bundle;

  final AssetBundle? _bundle;

  /// Logical source identity. Authenticated content overrides this so parsers
  /// cannot reuse another account's in-memory data.
  Object get cacheScope => this;

  /// O texto de um arquivo do app (`assets/positions/positions.json`).
  Future<String> loadString(String path) =>
      (_bundle ?? rootBundle).loadString(path, cache: false);

  /// Os bytes de um arquivo do app (`assets/models/maia3-5m.bin`).
  Future<Uint8List> loadBytes(String path) async {
    final data = await (_bundle ?? rootBundle).load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
