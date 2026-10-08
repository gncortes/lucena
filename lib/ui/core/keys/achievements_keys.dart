import 'package:flutter/widgets.dart';

abstract final class AchievementsKeys {
  static const screen = Key('achievements.screen');
  static const progress = Key('achievements.progress');

  /// A barra do progresso geral, no topo.
  static const progressBar = Key('achievements.progress.bar');

  /// Uma opção do filtro (`all`, `unlocked`, `locked`, `history`).
  static Key filter(String name) => Key('achievements.filter.$name');

  /// O cabeçalho de um grupo (`journey`, `opponents`, `speedrun`).
  static Key group(String category) => Key('achievements.group.$category');

  /// A lista sem nada no filtro escolhido.
  static const empty = Key('achievements.empty');

  /// Uma conquista da lista, e a data dela quando já foi obtida.
  static Key item(String id) => Key('achievements.item.$id');
  static Key unlockedOn(String id) => Key('achievements.item.$id.date');
  static Key locked(String id) => Key('achievements.item.$id.locked');

  /// O progresso de uma que falta ("3 de 9 níveis").
  static Key itemProgress(String id) => Key('achievements.item.$id.progress');

  /// O aviso de conquista desbloqueada, por cima da tela, e o nome nela.
  static const toast = Key('achievements.toast');
  static const toastTitle = Key('achievements.toast.title');

  /// O detalhe de uma conquista (painel inferior).
  static const detail = Key('achievements.detail');
  static const detailMedal = Key('achievements.detail.medal');
  static const detailTitle = Key('achievements.detail.title');
  static const detailDescription = Key('achievements.detail.description');
  static const detailDate = Key('achievements.detail.date');
  static const detailProgress = Key('achievements.detail.progress');
  static const detailOpenGame = Key('achievements.detail.openGame');
  static const detailOpenSpeedrun = Key('achievements.detail.openSpeedrun');
  static const detailShortcut = Key('achievements.detail.shortcut');
}
