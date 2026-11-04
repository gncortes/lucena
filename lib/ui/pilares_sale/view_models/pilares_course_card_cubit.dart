import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/links/link_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';

/// O cartão do curso no Perfil (H-VEN-04/09): acompanha o acesso salvo no
/// aparelho (abre sem internet) e pede à loja o estado atual ao abrir.
class PilaresCourseCardCubit extends Cubit<PurchaseState> {
  PilaresCourseCardCubit({
    required PurchaseRepository purchases,
    required this._links,
  }) : _purchases = purchases,
       super(purchases.state) {
    _subscription = _purchases.changes.listen((state) {
      if (!isClosed) emit(state);
    });
    unawaited(_purchases.refresh());
  }

  final PurchaseRepository _purchases;
  final LinkRepository _links;
  late final StreamSubscription<PurchaseState> _subscription;

  /// As assinaturas do app na Google Play ("Gerenciar" e "Atualizar
  /// pagamento").
  static final subscriptionsUrl = Uri.https(
    'play.google.com',
    '/store/account/subscriptions',
    {'package': 'com.gncortes.lucena'},
  );

  Future<bool> openSubscriptions() => _links.open(subscriptionsUrl);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
