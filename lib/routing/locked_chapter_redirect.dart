import '../domain/models/course_access.dart';
import '../domain/use_cases/ad_policy.dart';
import 'frentes/d2_routes.dart';

/// Capítulo trancado não abre por rota nem por link (H-LIC-06): quem não tem
/// o curso completo vai para a oferta. Nulo deixa seguir.
String? lockedChapterRedirect(Uri target, CourseAccess access) {
  if (target.path == D2Paths.pilaresOffer) return null;
  final chapter = DemoAdPolicy.chapterOf(target.toString());
  if (chapter == null || !DemoAdPolicy.isChapterLocked(access, chapter)) {
    return null;
  }
  return D2Paths.pilaresOffer;
}
