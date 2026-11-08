import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../domain/models/pilares_access.dart';

/// Os preços da loja para as telas que só mostram o preço no botão
/// (Assinatura encerrada, H-VEN-10). Sem preço da loja, a tela usa o de
/// referência.
class PilaresPricesCubit extends Cubit<Map<PilaresPlan, String>> {
  PilaresPricesCubit({required PurchaseRepository purchases})
    : super(purchases.state.prices) {
    _subscription = purchases.changes.listen((s) {
      if (!isClosed) emit(s.prices);
    });
    unawaited(purchases.start());
  }

  late final StreamSubscription<PurchaseState> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
