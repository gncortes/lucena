import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/models/course_preview.dart';
import '../../services/asset_service.dart';
import '../../services/scoped_asset_cache.dart';
import 'course_preview_repository.dart';

/// A prévia em `assets/courses/pt/pilares_preview.json` (exportada do canvas
/// por `tools/export_pilares_preview.py`).
class AssetCoursePreviewRepository implements CoursePreviewRepository {
  AssetCoursePreviewRepository(this._assets);

  static const path = 'assets/courses/pt/pilares_preview.json';

  final AssetService _assets;

  late final _cache = ScopedAssetCache(_assets);

  @override
  Future<CoursePreview?> load() async {
    try {
      return await _cache.load(path, () async {
        final text = await _assets.loadString(path);
        return compute(_parse, text);
      });
    } catch (_) {
      return null;
    }
  }

  static CoursePreview _parse(String text) =>
      CoursePreview.fromJson(jsonDecode(text) as Map<String, dynamic>);
}
