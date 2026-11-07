import 'dart:async';

import 'package:lucena/data/repositories/data_export/data_export_repository.dart';

/// "Baixar meus dados" sem disco: com [gate], o download espera o teste
/// completar; com [fails], falha.
class FakeDataExportRepository implements DataExportRepository {
  static const path = '/exports/lucena-dados.json';

  Completer<void>? gate;
  bool fails = false;

  final downloads = <String>[];
  final opened = <String>[];
  final discarded = <String>[];

  /// Os arquivos que existem agora.
  final saved = <String>{};

  @override
  Future<String> download(String uid) async {
    downloads.add(uid);
    if (gate case final gate?) await gate.future;
    if (fails) throw const DataExportException('falso');
    saved.add(path);
    return path;
  }

  @override
  Future<bool> open(String path) async {
    opened.add(path);
    return true;
  }

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
    saved.remove(path);
  }
}
