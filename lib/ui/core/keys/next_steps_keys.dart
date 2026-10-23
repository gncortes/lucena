import 'package:flutter/widgets.dart';

/// O bloco "E agora?" do fim de cada fluxo (E1.34) e a tela de próximos
/// passos (fim do nível e Escola concluída).
abstract final class NextStepsKeys {
  static const block = Key('nextSteps.block');
  static Key option(String id) => Key('nextSteps.option.$id');
  static const comingSoon = Key('nextSteps.comingSoon');
  static const dataNote = Key('nextSteps.dataNote');

  static const screen = Key('nextSteps.screen');
  static const home = Key('nextSteps.home');
}
