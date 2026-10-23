import 'package:in_app_review/in_app_review.dart';

/// A janela de avaliação da Play (In-App Review) e a página do app na loja.
abstract class ReviewService {
  /// A Play está no aparelho e aceita o pedido.
  Future<bool> isAvailable();

  /// Pede a janela. O app não fica sabendo se ela apareceu.
  Future<void> requestReview();

  /// Abre a página do app na Play (Perfil > "Avaliar o Lucena").
  Future<void> openStoreListing();
}

class PlayReviewService implements ReviewService {
  PlayReviewService([InAppReview? review])
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _review.isAvailable();
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> requestReview() => _review.requestReview();

  @override
  Future<void> openStoreListing() => _review.openStoreListing();
}

/// Sem Play (F-Droid, testes): nunca pede.
class NoReviewService implements ReviewService {
  const NoReviewService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> requestReview() async {}

  @override
  Future<void> openStoreListing() async {}
}
