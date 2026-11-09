import '../../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../../data/repositories/lesson_ad/demo_ad_repository.dart';
import '../../../data/repositories/review/review_repository.dart';
import '../../../domain/models/course_access.dart';

/// O que a entrada de uma lição (`LessonEntry`) consulta: o acesso ao curso,
/// o aviso da demonstração e a política de avaliação. Sem estado próprio.
/// Sem [CourseAccessRepository], o curso está aberto (V1); sem
/// [DemoAdRepository], não há anúncio.
class LessonEntryGate {
  const LessonEntryGate({this._access, this._ads, this._review});

  final CourseAccessRepository? _access;
  final DemoAdRepository? _ads;
  final ReviewRepository? _review;

  CourseAccess get access => _access?.access ?? CourseAccess.owned;

  /// Há anúncio da demonstração neste app.
  bool get hasAds => _ads != null;

  /// O aviso da demonstração já apareceu (sem anúncio, conta como visto).
  Future<bool> noticeSeen() async => await _ads?.noticeSeen() ?? true;

  Future<void> markNoticeSeen() async => _ads?.markNoticeSeen();

  /// Logo depois de um anúncio, a Play não pede avaliação (E1.26).
  void noteSetback() => _review?.noteSetback();
}
