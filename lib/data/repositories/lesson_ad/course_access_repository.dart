import '../../../domain/models/course_access.dart';
import '../../../domain/models/pilares_access.dart';
import '../purchase/purchase_repository.dart';

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

/// O acesso de verdade: a compra do Pilares da Venda (H-VEN-16). Comprador
/// (vitalício, mensal ativo ou em carência) tem o curso; a assinatura
/// encerrada volta a ser demonstração.
final class PurchaseCourseAccessRepository implements CourseAccessRepository {
  PurchaseCourseAccessRepository(this._purchases);

  final PurchaseRepository _purchases;

  static CourseAccess _of(PurchaseState state) => switch (state.access.kind) {
    PilaresAccessKind.lifetime ||
    PilaresAccessKind.monthlyActive ||
    PilaresAccessKind.monthlyGrace => CourseAccess.owned,
    PilaresAccessKind.monthlyEnded => CourseAccess.subscriptionEnded,
    PilaresAccessKind.demo => CourseAccess.demo,
  };

  @override
  CourseAccess get access => _of(_purchases.state);

  @override
  Stream<CourseAccess> get changes {
    var last = access;
    return _purchases.changes.map(_of).where((next) {
      final changed = next != last;
      last = next;
      return changed;
    });
  }
}
