import 'dart:convert';

import '../../../domain/models/glossary_term.dart';
import '../../../domain/use_cases/glossary_search.dart';
import '../../services/asset_service.dart';
import '../../services/scoped_asset_cache.dart';
import 'glossary_repository.dart';

/// O Glossário em `assets/glossary/glossario.json`.
class AssetGlossaryRepository implements GlossaryRepository {
  AssetGlossaryRepository(this._assets);

  static const path = 'assets/glossary/glossario.json';

  final AssetService _assets;
  late final _cache = ScopedAssetCache(_assets);

  @override
  Future<List<GlossaryTerm>> terms() async {
    try {
      return await _cache.load(
        path,
        () async => parse(jsonDecode(await _assets.loadString(path))),
      );
    } catch (_) {
      return const [];
    }
  }

  /// `{"termos": [...]}` → termos válidos, por nome.
  static List<GlossaryTerm> parse(Object? json) {
    if (json is! Map<String, dynamic>) return const [];
    final list = json['termos'];
    if (list is! List) return const [];
    return [for (final item in list) ?GlossaryTerm.fromJson(item)]..sort(
      (a, b) =>
          GlossarySearch.fold(a.name).compareTo(GlossarySearch.fold(b.name)),
    );
  }
}
