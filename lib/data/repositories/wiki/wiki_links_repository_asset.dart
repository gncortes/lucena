import 'dart:convert';

import '../../../domain/models/wiki_links.dart';
import '../../services/asset_service.dart';
import '../../services/scoped_asset_cache.dart';
import 'wiki_links_repository.dart';

/// O mapa em `assets/lessons/links.json`.
class AssetWikiLinksRepository implements WikiLinksRepository {
  AssetWikiLinksRepository(this._assets);

  static const path = 'assets/lessons/links.json';

  final AssetService _assets;
  late final _cache = ScopedAssetCache(_assets);

  @override
  Future<WikiLinks> links() async {
    try {
      return await _cache.load(
        path,
        () async =>
            WikiLinks.fromJson(jsonDecode(await _assets.loadString(path))),
      );
    } catch (_) {
      return WikiLinks.empty;
    }
  }
}
