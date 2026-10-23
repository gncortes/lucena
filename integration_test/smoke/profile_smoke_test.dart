import 'package:flutter/material.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/home_robot.dart';
import '../robots/profile_robot.dart';

/// Fumaça do Perfil: segundo plano.
void main() {
  patrolTest('perfil volta do segundo plano com o que foi editado', ($) async {
    final app = AppRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('pt', 'BR'));
    await HomeRobot($).openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.saveData();
    await profile.chooseLevel(RatingLevel.advanced);

    await app.sendToBackgroundAndReturn();

    await profile.expectVisible();
    profile.expectFields(name: 'Ana', rating: RatingLevel.advanced.rating);
  });
}
