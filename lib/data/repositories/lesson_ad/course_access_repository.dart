import '../../../domain/models/course_access.dart';

/// O que a pessoa tem do curso Pilares: demonstração, comprador ou assinatura
/// vencida (H-LIC-14). A H-VEN-16 (frente Venda) troca a implementação pela
/// que confere a compra; a lição só lê.
abstract interface class CourseAccessRepository {
  CourseAccess get access;

  Stream<CourseAccess> get changes;
}

/// Enquanto a compra do Pilares não existe: o curso está aberto, sem
/// anúncio nem cadeado (o comportamento da V1).
final class FullCourseAccessRepository implements CourseAccessRepository {
  const FullCourseAccessRepository();

  @override
  CourseAccess get access => CourseAccess.owned;

  @override
  Stream<CourseAccess> get changes => const Stream.empty();
}
