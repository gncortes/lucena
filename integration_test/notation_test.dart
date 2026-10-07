import 'package:flutter/widgets.dart';
import 'package:lucena/data/repositories/school/school_progress_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/lesson.dart';
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
          'pieces.check',
          'pieces.stalemate',
        },
      ),
    );

void main() {
  patrolTest('coordenadas: tocar nas casas que o Viktor pede, com e sem as '
      'letras da borda', ($) async {
    final app = AppRobot($);
    final school = SchoolRobot($);
    await app.open(systemLocale: _english);
    await _seedPieces();
    await app.restart();
    await school.openFromHome();
    await school.openLesson('notation.coordinates');
    await school.next();

    await school.expectStep('notation.coordinates', 'find');
    // A errada não conta: a casa pedida continua a mesma.
    await school.tapSquare('h1');
    for (final square in ['e4', 'a1', 'h8', 'd5']) {
      await school.tapSquare(square);
    }
    await school.next();
    await school.expectStep('notation.coordinates', 'blind');
    for (final square in ['c6', 'f2', 'b7', 'g3']) {
      await school.tapSquare(square);
    }
    await school.next();
    await school.expectStep('notation.coordinates', 'end');
  });

  patrolTest('a casa citada na fala: tocar marca no tabuleiro; tocar de novo '
      'desmarca', ($) async {
    final app = AppRobot($);
    final school = SchoolRobot($);
    await app.open(systemLocale: _english);
    await _seedPieces();
    await app.restart();
    await school.openFromHome();
    await school.openLesson('mates.twoRooks');

    await school.tapInSpeech('a4');
    school.expectSpeechRing(visible: true);
    await school.tapInSpeech('a4');
    school.expectSpeechRing(visible: false);
  });
}
