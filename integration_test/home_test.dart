import 'package:lucena/main.dart';
import 'package:patrol/patrol.dart';

import 'robots/home_robot.dart';

void main() {
  patrolTest('abrir o app mostra a tela inicial', ($) async {
    await $.pumpWidgetAndSettle(const LucenaApp());

    await HomeRobot($).expectVisible();
  });
}
