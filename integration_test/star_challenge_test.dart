import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/school_robot.dart';
import 'robots/star_challenge_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('desafio das estrelas: a torre no fácil pega duas estrelas', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _english);
    await SchoolRobot($).openFromHome();
    final challenge = StarChallengeRobot($);
    await challenge.openFromSchool();
    await challenge.openChallenge('rook', 'easy');

    await challenge.go();
    expect(challenge.points, 0);
    await challenge.collect();
    final first = challenge.points;
    expect(first, greaterThan(0));
    await challenge.collect();
    expect(challenge.points, greaterThan(first));

    // Sai no meio: volta à lista, sem marca gravada.
    await challenge.back();
    expect(find.byKey(StarChallengeKeys.listScreen), findsOneWidget);
  });
}
