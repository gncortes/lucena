import 'dart:convert';
import 'dart:io';

import '../../../domain/use_cases/now.dart';
import '../../services/firebase/cloud_store_service.dart';
import '../../services/share_service.dart';
import 'data_export_repository.dart';

/// Lê a conta na nuvem e grava `exports/lucena-dados.json` na pasta do app.
/// Grava num `.part` e renomeia no fim: fechar o app no meio não deixa
/// arquivo pela metade (e o `.part` de uma tentativa interrompida é apagado
/// na próxima).
class CloudDataExportRepository implements DataExportRepository {
  CloudDataExportRepository(
    this._store, {
    required this._directory,
    required this._now,
    this._share = const ShareService(),
  });

  final CloudStoreService _store;
  /// A pasta do app (`getApplicationSupportDirectory`).
  final Future<Directory> Function() _directory;
  final Now _now;
  final ShareService _share;

  static const fileName = 'lucena-dados.json';

  @override
  Future<String> download(String uid) async {
    try {
      final export = await _store.exportUser(uid);
      final folder = Directory('${(await _directory()).path}/exports');
      await folder.create(recursive: true);
      final part = File('${folder.path}/$fileName.part');
      if (part.existsSync()) await part.delete();
      final text = const JsonEncoder.withIndent('  ').convert({
        'gerado_em': _now().toIso8601String(),
        'conta': export.user,
        'progresso': export.progress,
        'partidas': export.games,
      });
      await part.writeAsString(text, flush: true);
      final file = await part.rename('${folder.path}/$fileName');
      return file.path;
    } on DataExportException {
      rethrow;
    } on Object catch (error) {
      throw DataExportException(error);
    }
  }

  @override
  Future<bool> open(String path) =>
      _share.shareFile(path, mimeType: 'application/json');

  @override
  Future<void> discard(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
