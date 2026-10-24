import 'package:flutter/widgets.dart';

/// O bloco "Próximos passos" do fim de cada fluxo (E1.34), a linha e a folha
/// "Seus resultados contam" e a tela de próximos passos (fim do nível e Escola
/// concluída).
abstract final class NextStepsKeys {
  static const block = Key('nextSteps.block');
  static Key option(String id) => Key('nextSteps.option.$id');

  static const resultsInfo = Key('nextSteps.resultsInfo');
  static const resultsSheet = Key('nextSteps.resultsSheet');
  static const resultsSheetClose = Key('nextSteps.resultsSheet.close');
  static Key resultsItem(int index) =>
      Key('nextSteps.resultsSheet.item.$index');

  static const screen = Key('nextSteps.screen');
  static const home = Key('nextSteps.home');
}
