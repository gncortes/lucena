import 'dart:convert';
import 'dart:io';

import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository_asset.dart';
import 'package:lucena/domain/models/course_preview.dart';

/// A prévia de verdade (o asset exportado do canvas), lida do disco.
class FakeCoursePreviewRepository implements CoursePreviewRepository {
  FakeCoursePreviewRepository({this.preview});

  /// O asset do app (os testes rodam na raiz do checkout).
  static CoursePreview real() => CoursePreview.fromJson(
    jsonDecode(File(AssetCoursePreviewRepository.path).readAsStringSync())
        as Map<String, dynamic>,
  );

  final CoursePreview? preview;

  @override
  Future<CoursePreview?> load() async => preview;
}
