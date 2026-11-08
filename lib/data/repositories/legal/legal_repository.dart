import 'package:flutter/services.dart';

import '../../../domain/models/legal_document.dart';

/// Os Termos e a Política embarcados no app (funcionam sem internet).
/// Por ora só em português: nos outros idiomas, [load] devolve `null` e a
/// tela abre o site.
abstract class LegalRepository {
  Future<LegalDocument?> load(LegalKind kind, String languageCode);
}

class AssetLegalRepository implements LegalRepository {
  AssetLegalRepository([AssetBundle? bundle]) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static String? assetFor(LegalKind kind, String languageCode) {
    if (languageCode != 'pt') return null;
    return switch (kind) {
      LegalKind.terms => 'assets/legal/termos_pt.md',
      LegalKind.privacy => 'assets/legal/privacidade_pt.md',
    };
  }

  @override
  Future<LegalDocument?> load(LegalKind kind, String languageCode) async {
    final asset = assetFor(kind, languageCode);
    if (asset == null) return null;
    return LegalDocument.parse(await _bundle.loadString(asset));
  }
}
