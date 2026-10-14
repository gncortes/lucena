import 'package:flutter/material.dart';
import 'package:lucena/data/repositories/school/school_progress_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/school_robot.dart';

const _english = Locale('en', 'US');

// As aulas de peças já feitas: a notação e os primeiros mates abertos.
Future<void> _seedPieces() =>
    LocalSchoolProgressRepository(PreferencesService()).save(
      const SchoolProgress(
        completed: {
          'pieces.rook',
          'pieces.bishop',
          'pieces.queen',
          'pieces.king',
          'pieces.knight',
          'pieces.pawn',
          'rules.captureProtect',
          'pieces.check',
          'rules.outOfCheck',
          'rules.castling',
          'pieces.stalemate',
          'rules.draws',
        },
      ),
    );

void main() {
  // As aulas de notação e de mate têm roteiro (T71): abrem na tela
  // roteirizada, com o balão do Viktor.
  patrolTest('coordenadas e mate de duas torres abrem na tela roteirizada', (
    $,
  ) async {
    final app = AppRobot($);
    final school = SchoolRobot($);
    await app.open(systemLocale: _english);
    await _seedPieces();
    await app.restart();
    await school.openFromHome();
    await school.openScriptLesson('notation.coordinates');
    await $(LessonScriptKeys.speech).waitUntilVisible();
    await $(LessonScriptKeys.board).waitUntilVisible();
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await school.openScriptLesson('mates.twoRooks');
    await $(LessonScriptKeys.speech).waitUntilVisible();
    await $(LessonScriptKeys.board).waitUntilVisible();
  });
}
