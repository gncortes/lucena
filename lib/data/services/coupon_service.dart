/// O resultado de `validarCupom` (contrato de promoções, R23).
sealed class CouponCheck {
  const CouponCheck();
}

/// O código vale: a oferta da loja que ele libera.
class CouponValid extends CouponCheck {
  const CouponValid({
    required this.promotionId,
    required this.code,
    required this.offerId,
    this.endsAt,
  });

  final String promotionId;
  final String code;

  /// A oferta da Play com a tag `lucena-link` (`link-20`).
  final String offerId;

  /// Sem fim: nulo.
  final DateTime? endsAt;
}

/// Por que o código não vale.
enum CouponInvalidReason { notFound, outOfDate, ended, soldOut }

class CouponInvalid extends CouponCheck {
  const CouponInvalid(this.reason);

  final CouponInvalidReason reason;
}

/// As vagas do link acabaram entre a conferência e a compra (`reservarVaga`).
class CouponGoneException implements Exception {
  const CouponGoneException();
}

/// As Cloud Functions das promoções (`validarCupom`, `reservarVaga`,
/// `conferirCompra`) atrás de interface. No flavor dev, simuladas.
abstract class CouponService {
  /// Nulo: não deu para conferir (sem rede); o código fica guardado.
  Future<CouponCheck?> validate(String code);

  /// Segura a vaga do link por 30 minutos para a conta que está entrada.
  /// Lança [CouponGoneException] quando não há mais vaga.
  Future<void> reserve(String code);

  /// Manda o token da compra para o servidor liberar o curso.
  Future<void> confirmPurchase(String token);
}

/// Sem servidor de promoções: todo código fica sem conferir.
class NoCouponService implements CouponService {
  const NoCouponService();

  @override
  Future<CouponCheck?> validate(String code) async => null;

  @override
  Future<void> reserve(String code) async {}

  @override
  Future<void> confirmPurchase(String token) async {}
}
