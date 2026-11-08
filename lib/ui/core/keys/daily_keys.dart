import 'package:flutter/widgets.dart';

/// O final do dia (H-DES-01 a 04): o compartilhar da app bar, a folha, o
/// "Parabéns!" da vitória e o carregando.
abstract final class DailyKeys {
  /// O ícone de compartilhar da app bar da partida.
  static const appBarShare = Key('daily.appBarShare');

  /// A folha "Compartilhar final do dia" e o X dela.
  static const shareSheet = Key('daily.shareSheet');
  static const shareSheetClose = Key('daily.shareSheetClose');

  /// A imagem da posição inicial dentro da folha.
  static const shareImage = Key('daily.shareImage');

  /// O botão "Compartilhar" da folha.
  static const shareButton = Key('daily.shareButton');

  /// O modal "Parabéns!" e os dois botões dele.
  static const winSheet = Key('daily.winSheet');
  static const winShare = Key('daily.winShare');
  static const winLater = Key('daily.winLater');

  /// O carregando do final do dia (título + jogador + tabuleiro + jogador).
  static const loading = Key('daily.loading');

  /// O aviso "Hoje não há final do dia. Volte amanhã."
  static const noFinalNotice = Key('daily.noFinalNotice');
}
