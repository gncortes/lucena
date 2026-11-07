import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/course_grant.dart';
import '../../../domain/use_cases/now.dart';

/// A tela que a compra abre por cima do app, de onde quer que o aluno esteja.
/// [done]: a compra na loja deste aparelho (toma o lugar de tudo); [gift] e
/// [granted]: o curso dado pelo servidor, presente ou compra de fora
/// (H-R5-62), por cima de onde estava.
enum PurchaseScreen { done, ended, gift, granted }

class PurchaseWatchState {
  const PurchaseWatchState({this.screen, this.id = 0});

  final PurchaseScreen? screen;

  /// Muda a cada tela pedida (a mesma tela duas vezes também abre).
  final int id;
}

/// Vigia a compra para o app todo (H-VEN-05/06/10): a compra confirmada
/// (também a pendente que a loja confirmou depois, ou a que voltou com o app
/// reaberto) abre "O curso completo é seu" uma vez; a assinatura que terminou
/// abre "Sua assinatura terminou" uma vez. Ao voltar do segundo plano,
/// consulta a loja. O curso dado em `acessos/{uid}` e ainda não visto abre
/// o Curso liberado uma vez por acesso (H-R5-62): na hora, se o app está
/// aberto, ou na próxima abertura.
class PilaresPurchaseWatchCubit extends Cubit<PurchaseWatchState> {
  PilaresPurchaseWatchCubit({
    required this._purchases,
    required this._analytics,
    this._grants = const NoCourseGrantsRepository(),
    this._now = const SystemNow(),
  }) : super(const PurchaseWatchState()) {
    _subscription = _purchases.changes.listen(_check);
    _grantsSubscription = _grants.changes.listen(_checkGrants);
    unawaited(_start());
  }

  final PurchaseRepository _purchases;
  final AnalyticsRepository _analytics;
  final CourseGrantsRepository _grants;
  final Now _now;
  late final StreamSubscription<PurchaseState> _subscription;
  late final StreamSubscription<CourseGrants> _grantsSubscription;

  Future<void> _start() async {
    await _purchases.start();
    _check(_purchases.state);
    await _grants.start();
    _checkGrants(_grants.current);
  }

  void _checkGrants(CourseGrants grants) {
    if (isClosed || !grants.unseen(pilaresCourseId, _now())) return;
    final grant = grants.active(pilaresCourseId, _now())!;
    unawaited(_grants.markSeen(pilaresCourseId));
    _open(
      grant.origin == GrantOrigin.gift
          ? PurchaseScreen.gift
          : PurchaseScreen.granted,
    );
  }

  /// O app voltou do segundo plano.
  Future<void> resumed() => _purchases.refresh();

  void _check(PurchaseState purchase) {
    if (isClosed) return;
    if (purchase.outcome == PurchaseOutcome.done) {
      _purchases.clearOutcome();
      // A compra da loja também chega ao `acessos`: uma tela só.
      unawaited(_grants.markSeen(pilaresCourseId));
      _open(PurchaseScreen.done);
    } else if (purchase.access.showEnded) {
      unawaited(_purchases.markEndedSeen());
      unawaited(_analytics.log(AnalyticsEvents.pilaresAssinaturaEncerrada()));
      _open(PurchaseScreen.ended);
    }
  }

  void _open(PurchaseScreen screen) =>
      emit(PurchaseWatchState(screen: screen, id: state.id + 1));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _grantsSubscription.cancel();
    return super.close();
  }
}
