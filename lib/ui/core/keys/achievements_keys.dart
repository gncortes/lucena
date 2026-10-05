import 'package:flutter/widgets.dart';

abstract final class AchievementsKeys {
  static const screen = Key('achievements.screen');
  static const progress = Key('achievements.progress');

  /// Uma conquista da lista, e a data dela quando já foi obtida.
  static Key item(String id) => Key('achievements.item.$id');
  static Key unlockedOn(String id) => Key('achievements.item.$id.date');
  static Key locked(String id) => Key('achievements.item.$id.locked');

  /// O aviso de conquista desbloqueada, por cima da tela, e o nome nela.
  static const toast = Key('achievements.toast');
  static const toastTitle = Key('achievements.toast.title');
}
