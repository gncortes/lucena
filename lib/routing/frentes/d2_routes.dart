import 'package:go_router/go_router.dart';

/// Telas novas da frente D2 (Venda + Conta + Ajustes, T85). A frente registra as rotas na
/// lista [d2Routes] com `appRoute(name: RouteNames.x, path: D2Paths.x, ...)`,
/// do `router.dart`, e navega por nome. Só esta frente mexe neste arquivo.
abstract final class D2Paths {
  /// Apresentação do Pilares (H-VEN-14).
  static const pilaresPresentation = '/pilares';

  /// Para quem é, a faixa (H-VEN-02).
  static const pilaresForWhom = '/pilares/for-whom';

  /// Sobre o Pilares, 3 abas (H-VEN-03).
  static const pilaresAbout = '/pilares/about';

  /// Fim da demonstração (H-VEN-04).
  static const pilaresDemoEnd = '/pilares/demo-end';

  /// Oferta vitalício/mensal (H-VEN-05).
  static const pilaresOffer = '/pilares/offer';

  /// Compra processando (H-VEN-07).
  static const pilaresPurchaseProcessing = '/pilares/purchase/processing';

  /// Compra concluída (H-VEN-07).
  static const pilaresPurchaseDone = '/pilares/purchase/done';

  /// Compra pendente (H-VEN-08).
  static const pilaresPurchasePending = '/pilares/purchase/pending';

  /// Restaurar compra (H-VEN-09).
  static const pilaresRestore = '/pilares/restore';

  /// Já tem o curso (H-VEN-09).
  static const pilaresOwned = '/pilares/owned';

  /// Assinatura encerrada (H-VEN-10).
  static const pilaresSubscriptionEnded = '/pilares/subscription-ended';

  /// Oferta antes do Início, variante A (H-VEN-15).
  static const pilaresBeforeHome = '/pilares/before-home';

  /// Plano como venda (H-VEN-14).
  static const pilaresPlan = '/pilares/plan';

  /// Esqueci a senha (H-CON-08).
  static const accountForgot = '/conta/esqueci-senha';

  /// Aceite dos Termos (H-CON-09).
  static const accountTerms = '/conta/termos';

  /// Convite por link, tela cheia com X (H-CON-18).
  static const accountInvite = '/conta/convite';

  /// Compra exige conta (H-CON-19).
  static const accountRequired = '/conta/exige';

  /// Perfil Lichess / Chess.com (H-CON-20).
  static const accountExternal = '/conta/externo/:site';
}

final List<RouteBase> d2Routes = [];
