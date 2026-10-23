import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/featured.dart';
import '../../services/asset_service.dart';
import 'featured_repository.dart';

/// Os finais em `assets/featured/featured.json`.
class AssetFeaturedRepository implements FeaturedRepository {
  AssetFeaturedRepository(this._assets);

  static const path = 'assets/featured/featured.json';

  final AssetService _assets;

  Future<FeaturedCatalog>? _catalog;

  @override
  Future<FeaturedCatalog> catalog() => _catalog ??= _load();

  Future<FeaturedCatalog> _load() async {
    try {
      final text = await _assets.loadString(path);
      return await compute(_parse, text);
    } catch (_) {
      return FeaturedCatalog.empty;
    }
  }

  static FeaturedCatalog _parse(String text) =>
      FeaturedCatalog.fromJson(jsonDecode(text) as Map<String, dynamic>);
}
