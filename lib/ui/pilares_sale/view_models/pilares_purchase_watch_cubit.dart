import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../domain/models/analytics_event.dart';

/// A tela que a compra abre por cima do app, de onde quer que o aluno esteja.
enum PurchaseScreen { done, ended }

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
/// consulta a loja.
class PilaresPurchaseWatchCubit extends Cubit<PurchaseWatchState> {
  PilaresPurchaseWatchCubit({
    required this._purchases,
    required this._analytics,
  }) : super(const PurchaseWatchState()) {
    _subscription = _purchases.changes.listen(_check);
    unawaited(_start());
  }

  final PurchaseRepository _purchases;
  final AnalyticsRepository _analytics;
  late final StreamSubscription<PurchaseState> _subscription;

  Future<void> _start() async {
    await _purchases.start();
    _check(_purchases.state);
  }

  /// O app voltou do segundo plano.
  Future<void> resumed() => _purchases.refresh();

  void _check(PurchaseState purchase) {
    if (isClosed) return;
    if (purchase.outcome == PurchaseOutcome.done) {
      _purchases.clearOutcome();
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
    return super.close();
  }
}
