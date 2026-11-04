import 'package:flutter/widgets.dart';

/// Chaves do anúncio da demonstração e das folhas que vêm antes dele
/// (T85-D1, H-LIC-06 a 12).
abstract final class AdsKeys {
  /// A tela do anúncio (PropV2DemoAnuncio).
  static const screen = Key('ads.screen');

  /// O selo "Anúncio" da barra do topo.
  static const badge = Key('ads.badge');

  /// "Fechar em 3" ... "Fechar".
  static const adCloseButton = Key('ads.close');

  /// "Conhecer o Pilares" na barra do topo.
  static const learnMore = Key('ads.card.learnMore');

  /// O anúncio carregando antes de abrir.
  static const loading = Key('ads.loading');

  /// "Depois do anúncio", com o nome da lição.
  static const after = Key('ads.after');

  /// A falha do anúncio (PropV2DemoAnuncioFalhou).
  static const failed = Key('ads.failed');
  static const adFailedRetry = Key('ads.failed.retry');
  static const adFailedBack = Key('ads.failed.back');

  /// O aviso do primeiro anúncio (PropV2DemoAviso).
  static const noticeSheet = Key('ads.notice.sheet');
  static const demoAdNoticeSee = Key('ads.notice.see');
  static const demoAdNoticeLater = Key('ads.notice.later');

  /// A folha do capítulo trancado (PropV2DemoBloqueado).
  static const lockedSheet = Key('ads.locked.sheet');
  static const demoLockedSheetBuy = Key('ads.locked.buy');
  static const demoLockedSheetLater = Key('ads.locked.later');
}
