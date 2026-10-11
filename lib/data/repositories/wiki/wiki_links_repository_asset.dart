import 'dart:convert';

import '../../../domain/models/wiki_links.dart';
import '../../services/asset_service.dart';
import 'wiki_links_repository.dart';

/// O mapa em `assets/lessons/links.json`.
class AssetWikiLinksRepository implements WikiLinksRepository {
  AssetWikiLinksRepository(this._assets);

  static const path = 'assets/lessons/links.json';

  final AssetService _assets;
  Future<WikiLinks>? _links;

  @override
  Future<WikiLinks> links() => _links ??= _load();

  Future<WikiLinks> _load() async {
    try {
      return WikiLinks.fromJson(jsonDecode(await _assets.loadString(path)));
    } catch (_) {
      return WikiLinks.empty;
    }
  }
}
