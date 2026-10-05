import 'package:chessground/chessground.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';

/// A Escola do Viktor: a trilha e as aulas.
class SchoolRobot {
  const SchoolRobot(this.$);

  final PatrolIntegrationTester $;

  /// Da tela inicial, pelo botão das aulas.
  Future<void> openFromHome() async {
    await $(HomeKeys.schoolButton).scrollTo().tap();
    await expectTrail();
  }

  Future<void> expectTrail() async {
    await $(SchoolKeys.screen).waitUntilVisible();
  }

  Future<void> openLesson(String id) async {
    await $(SchoolKeys.lesson(id)).scrollTo().tap();
    await $(LessonKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> expectStep(String lesson, String step) async {
    await $(LessonKeys.step(lesson, step)).waitUntilExists();
  }

  /// "Continuar" (ou "Concluir a aula", no último passo).
  Future<void> next() async {
    await $(LessonKeys.nextButton).tap();
    await $.pumpAndSettle();
  }

  Future<void> hint() async {
    await $(LessonKeys.hintButton).tap();
    await $.pumpAndSettle();
  }

  /// Toca na casa de origem e depois na de destino.
  Future<void> move(String from, String to) async {
    await $.tester.tapAt(_square(from));
    await $.pump();
    await $.tester.tapAt(_square(to));
    await $.pumpAndSettle();
  }

  /// O que o Viktor está dizendo.
  String? get speech =>
      $.tester.widget<Text>(find.byKey(LessonKeys.speech).last).data;

  void expectStar(String square, {bool visible = true}) => expect(
    find.byKey(LessonKeys.star(square)),
    visible ? findsOneWidget : findsNothing,
  );

  /// A seta da dica no tabuleiro.
  void expectHintArrow(String from, String to) {
    final board = $.tester.widget<Chessboard>(find.byKey(LessonKeys.board));
    expect(
      board.shapes.whereType<Arrow>().any(
        (arrow) => arrow.orig.name == from && arrow.dest.name == to,
      ),
      isTrue,
    );
  }

  Future<void> expectFinished() async {
    await $(LessonKeys.finished).waitUntilVisible();
  }

  Future<void> openNextLesson() async {
    await $(LessonKeys.nextLessonButton).tap();
    await $(LessonKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Offset _square(String square) {
    final board = $.tester.widget<Chessboard>(find.byKey(LessonKeys.board));
    return squareCenter(
      $.tester.getRect(find.byKey(LessonKeys.board)),
      square,
      orientation: board.orientation,
    );
  }
}
