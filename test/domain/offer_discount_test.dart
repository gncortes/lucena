import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/offer_discount.dart';
import 'package:lucena/domain/use_cases/best_discount.dart';
import 'package:lucena/domain/use_cases/install_referrer_rules.dart';
import 'package:lucena/routing/routes.dart';

OfferDiscount _discount(
  String id,
  int percent, {
  DateTime? endsAt,
  DiscountKind kind = DiscountKind.everyone,
}) => OfferDiscount(
  kind: kind,
  offerId: id,
  percent: percent,
  price: 'R\$ 1',
  fullPrice: 'R\$ 2',
  endsAt: endsAt,
);

void main() {
  group('OfferCodes (regra 6)', () {
    test('lê o código do link próprio, em maiúsculas', () {
      expect(
        OfferCodes.fromLink(
          Uri.parse(
            'https://playlucenachess.com/oferta/cxc20?utm_source=ig&utm_campaign=x',
          ),
        ),
        'CXC20',
      );
      expect(
        OfferCodes.fromLink(
          Uri.parse('https://playlucenachess.com/oferta/AB12/'),
        ),
        'AB12',
      );
    });

    test('recusa host de fora, caminho errado e código fora da regra', () {
      expect(
        OfferCodes.fromLink(Uri.parse('https://x.com/oferta/CXC20')),
        null,
      );
      expect(
        OfferCodes.fromLink(Uri.parse('https://playlucenachess.com/oferta')),
        null,
      );
      expect(
        OfferCodes.fromLink(
          Uri.parse('https://playlucenachess.com/oferta/ABC'),
        ),
        null,
      );
      expect(
        OfferCodes.fromLink(
          Uri.parse('https://playlucenachess.com/oferta/ABCDEFGHIJKLMNOPQRSTU'),
        ),
        null,
      );
      expect(
        OfferCodes.fromLink(
          Uri.parse('https://playlucenachess.com/oferta/CX-20'),
        ),
        null,
      );
    });

    test('o link abre a Oferta com o código e vale no referrer da Play', () {
      final link = Uri.parse(
        'https://playlucenachess.com/oferta/CXC20?utm_source=ig',
      );
      expect(Routes.appLink(link), '/pilares/offer?origem=link&codigo=CXC20');
      expect(
        InstallReferrerRules.link('/oferta/CXC20?utm_source=ig'),
        isNotNull,
      );
    });
  });

  group('bestDiscount (regra 5)', () {
    test('vence o maior', () {
      expect(
        bestDiscount([_discount('a', 20), _discount('b', 30)])?.offerId,
        'b',
      );
    });

    test('no empate, o que termina primeiro; sem fim é o último', () {
      expect(
        bestDiscount([
          _discount('sem-fim', 20),
          _discount('dez', 20, endsAt: DateTime(2026, 12, 31)),
          _discount('nov', 20, endsAt: DateTime(2026, 11, 30)),
        ])?.offerId,
        'nov',
      );
    });

    test('sem desconto, nulo', () => expect(bestDiscount(const []), null));
  });
}
