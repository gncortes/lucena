import 'app_links.dart';

/// O código do link com desconto (contrato de promoções, regra 6):
/// `https://playlucena.com/oferta/<CODIGO>`, de 4 a 20 maiúsculas e números.
abstract final class OfferCodes {
  /// O caminho do link: `<host>/oferta/<código>`.
  static const segment = 'oferta';

  /// Quantos dias o código fica no aparelho (regra 10).
  static const keepFor = Duration(days: 30);

  static final _pattern = RegExp(r'^[A-Z0-9]{4,20}$');

  static bool isValid(String code) => _pattern.hasMatch(code);

  /// O código do link [uri], ou nulo se não é um link de desconto do app.
  static String? fromLink(Uri uri) {
    if (!AppLinks.isOwn(uri)) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != segment) return null;
    final code = segments.last.toUpperCase();
    return isValid(code) ? code : null;
  }
}

/// De onde vem o desconto: a promoção para todos ou o link.
enum DiscountKind { everyone, link }

/// O desconto do vitalício que a oferta mostra (regra 10): o preço cheio
/// riscado, o com desconto, o selo e o prazo. Os preços vêm da loja.
class OfferDiscount {
  const OfferDiscount({
    required this.kind,
    required this.offerId,
    required this.percent,
    required this.price,
    required this.fullPrice,
    this.endsAt,
    this.name,
  });

  final DiscountKind kind;

  /// A oferta da loja (`black-friday-2026`, `link-20`).
  final String offerId;
  final int percent;
  final String price;
  final String fullPrice;

  /// Sem fim (link sem data): nulo.
  final DateTime? endsAt;

  /// O nome da promoção para todos ("Black Friday").
  final String? name;

  @override
  bool operator ==(Object other) =>
      other is OfferDiscount &&
      other.kind == kind &&
      other.offerId == offerId &&
      other.percent == percent &&
      other.price == price &&
      other.fullPrice == fullPrice &&
      other.endsAt == endsAt &&
      other.name == name;

  @override
  int get hashCode =>
      Object.hash(kind, offerId, percent, price, fullPrice, endsAt, name);
}
