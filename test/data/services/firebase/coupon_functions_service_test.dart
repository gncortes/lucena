import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/coupon_service.dart';
import 'package:lucena/data/services/firebase/coupon_functions_service.dart';

void main() {
  CouponCheck? parse(Object? data) =>
      FirebaseCouponService.parseValidation(data);

  test('código válido: promoção, código, oferta e fim', () {
    final check = parse({
      'valido': true,
      'promocaoId': 'p1',
      'codigo': 'XADREZ20',
      'offerId': 'link-20',
      'desconto': 20,
      'fim': '2026-11-30T03:00:00.000Z',
    });

    expect(check, isA<CouponValid>());
    final valid = check! as CouponValid;
    expect(valid.promotionId, 'p1');
    expect(valid.code, 'XADREZ20');
    expect(valid.offerId, 'link-20');
    expect(valid.endsAt, DateTime.utc(2026, 11, 30, 3));
  });

  test('código válido sem fim', () {
    final check = parse({
      'valido': true,
      'promocaoId': 'p1',
      'codigo': 'X',
      'offerId': 'link-20',
      'fim': null,
    });

    expect((check! as CouponValid).endsAt, isNull);
  });

  test('cada motivo do servidor vira o seu', () {
    const motivos = {
      'naoExiste': CouponInvalidReason.notFound,
      'foraDaData': CouponInvalidReason.outOfDate,
      'encerrado': CouponInvalidReason.ended,
      'esgotado': CouponInvalidReason.soldOut,
    };
    for (final entry in motivos.entries) {
      final check = parse({'valido': false, 'motivo': entry.key});
      expect((check! as CouponInvalid).reason, entry.value, reason: entry.key);
    }
  });

  test('resposta que o app não entende fica sem conferir', () {
    expect(parse(null), isNull);
    expect(parse('ok'), isNull);
    expect(parse({'valido': false, 'motivo': 'novo'}), isNull);
    expect(parse({'valido': true, 'codigo': 'X'}), isNull);
  });
}
