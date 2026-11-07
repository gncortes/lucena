import 'dart:async';

import '../../../domain/models/course_access.dart';
import '../../../domain/models/course_grant.dart';
import '../../../domain/models/pilares_access.dart';
import '../../../domain/use_cases/now.dart';
import '../purchase/purchase_repository.dart';
import 'course_grants_repository.dart';

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

/// O acesso que vale (H-R5-61): a compra da loja ou o curso dado pelo
/// servidor em `acessos/{uid}` (presente, compra pelo site, pago por fora).
/// O curso revogado fecha na próxima sincronização; o prazo ([CourseGrant]
/// `ate`) fecha quando vence. Com `bloqueio` vigente, fecha tudo, até a
/// compra da loja (H-R5-39, Dúvida 8).
final class ServerCourseAccessRepository implements CourseAccessRepository {
  ServerCourseAccessRepository(this._base, this._grants, {required this._now});

  final CourseAccessRepository _base;
  final CourseGrantsRepository _grants;
  final Now _now;

  CourseAccess _of(CourseAccess base, CourseGrants grants) =>
      grants.blockedAt(_now())
      ? CourseAccess.demo
      : base == CourseAccess.owned ||
            grants.active(pilaresCourseId, _now()) != null
      ? CourseAccess.owned
      : base;

  @override
  CourseAccess get access => _of(_base.access, _grants.current);

  @override
  Stream<CourseAccess> get changes {
    late final StreamController<CourseAccess> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    var last = access;
    void check(Object? _) {
      final next = access;
      if (next == last) return;
      last = next;
      controller.add(next);
    }

    controller = StreamController<CourseAccess>(
      onListen: () {
        last = access;
        subscriptions
          ..add(_base.changes.listen(check))
          ..add(_grants.changes.listen(check));
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }
}
