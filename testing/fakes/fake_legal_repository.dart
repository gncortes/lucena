import 'dart:io';

import 'package:lucena/data/repositories/legal/legal_repository.dart';
import 'package:lucena/domain/models/legal_document.dart';

/// Os mesmos textos embarcados, lidos do disco sem esperar o `rootBundle`
/// (que nos testes de widget responde fora do relógio falso).
class FakeLegalRepository implements LegalRepository {
  final loaded = <LegalKind>[];

  @override
  Future<LegalDocument?> load(LegalKind kind, String languageCode) async {
    loaded.add(kind);
    final asset = AssetLegalRepository.assetFor(kind, languageCode);
    if (asset == null) return null;
    return LegalDocument.parse(File(asset).readAsStringSync());
  }
}
