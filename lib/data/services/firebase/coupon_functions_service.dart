import 'package:cloud_functions/cloud_functions.dart';

import '../coupon_service.dart';

/// As Cloud Functions das promoções (`functions/src/promocoes.ts`), chamadas
/// pelo `cloud_functions` (flavor `prod`, E1.22). Todas pedem a conta
/// entrada; o repositório só chama com uid.
class FirebaseCouponService implements CouponService {
  FirebaseCouponService([FirebaseFunctions? functions])
    : _functions = functions;

  /// A região das Functions (`REGIAO` em `functions/src/comum/config.ts`).
  static const region = 'southamerica-east1';

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _api =>
      _functions ?? FirebaseFunctions.instanceFor(region: region);

  @override
  Future<CouponCheck?> validate(String code) async {
    final result = await _api.httpsCallable('validarCupom').call<Object?>({
      'codigo': code,
    });
    return parseValidation(result.data);
  }

  @override
  Future<void> reserve(String code) async {
    try {
      await _api.httpsCallable('reservarVaga').call<Object?>({'codigo': code});
    } on FirebaseFunctionsException catch (e) {
      // O link acabou ou esgotou (`failed-precondition` com o motivo).
      if (e.code == 'failed-precondition') throw const CouponGoneException();
      rethrow;
    }
  }

  @override
  Future<void> confirmPurchase(String token) async {
    await _api.httpsCallable('conferirCompra').call<Object?>({'token': token});
  }

  /// A resposta de `validarCupom`: `{valido: true, promocaoId, codigo,
  /// offerId, fim}` ou `{valido: false, motivo}`. Nulo: resposta que o app
  /// não entende (fica para a próxima conferência).
  static CouponCheck? parseValidation(Object? data) {
    if (data is! Map) return null;
    if (data['valido'] == true) {
      final promotionId = data['promocaoId'];
      final code = data['codigo'];
      final offerId = data['offerId'];
      if (promotionId is! String || code is! String || offerId is! String) {
        return null;
      }
      final end = data['fim'];
      return CouponValid(
        promotionId: promotionId,
        code: code,
        offerId: offerId,
        endsAt: end is String ? DateTime.tryParse(end) : null,
      );
    }
    final reason = switch (data['motivo']) {
      'naoExiste' => CouponInvalidReason.notFound,
      'foraDaData' => CouponInvalidReason.outOfDate,
      'encerrado' => CouponInvalidReason.ended,
      'esgotado' => CouponInvalidReason.soldOut,
      _ => null,
    };
    return reason == null ? null : CouponInvalid(reason);
  }
}
