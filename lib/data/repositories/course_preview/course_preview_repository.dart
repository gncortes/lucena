import '../../../domain/models/course_preview.dart';

/// A prévia do Pilares do Xadrez (T82), só para o layout.
abstract class CoursePreviewRepository {
  /// Os textos da prévia. Sem a fonte (ou quebrada), nada.
  Future<CoursePreview?> load();
}
