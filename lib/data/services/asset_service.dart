import 'package:flutter/services.dart';

/// Embrulha a leitura de arquivos que vêm dentro do app.
class AssetService {
  const AssetService([AssetBundle? bundle]) : _bundle = bundle;

  final AssetBundle? _bundle;

  /// O texto de um arquivo do app (`assets/positions/positions.json`).
  Future<String> loadString(String path) =>
      (_bundle ?? rootBundle).loadString(path, cache: false);
}
