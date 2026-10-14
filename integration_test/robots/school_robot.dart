import 'package:chessground/chessground.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/board/speech_flash.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';
import 'home_robot.dart';

/// A Escola do Viktor: a trilha e as aulas.
class SchoolRobot {
  const SchoolRobot(this.$);

  final PatrolIntegrationTester $;

  /// Da tela inicial, pelo botão das aulas.
  Future<void> openFromHome() async {
    await tapHomePath($, HomeKeys.schoolButton);
    await expectTrail();
  }

  Future<void> expectTrail() async {
    await $(SchoolKeys.screen).waitUntilVisible();
  }

  Future<void> openLesson(String id) async {
    await _tapLesson(id);
    await $(LessonKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  /// Abre uma aula do curso que tem roteiro: a rota troca pela tela
  /// roteirizada (T70/T71), sem o rodapé nem os passos da lição de reserva.
  Future<void> openScriptLesson(String id) async {
    await _tapLesson(id);
    await $(LessonScriptKeys.screen).waitUntilVisible();
    await $.pumpAndSettle();
  }

  Future<void> _tapLesson(String id) async {
    // A trilha é longa: a aula vai para o meio da tela, longe do botão fixo
    // de baixo, antes do toque.
    final lesson = find.byKey(SchoolKeys.lesson(id));
    await $.scrollUntilExists(finder: lesson, maxScrolls: 80);
    await Scrollable.ensureVisible($.tester.element(lesson), alignment: 0.5);
    await $.pumpAndSettle();
    await $(lesson).tap();
  }

  /// O balão do Viktor na tela roteirizada: sem ✕ nele; o toque abre a fala
  /// inteira numa folha (T72), que fecha pelo ✕ dela.
  Future<void> expectScriptSpeechSheet() async {
    final balloon = find.byKey(LessonScriptKeys.speech);
    await $(balloon).waitUntilVisible();
    expect(
      find.descendant(of: balloon, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    await $.tester.tap(balloon);
    await $.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
    await $(LessonScriptKeys.speechSheetClose).tap();
    await $.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
  }

  /// "Continuar" da tela roteirizada.
  Future<void> scriptContinue() async {
    await $(LessonScriptKeys.primary).tap();
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

  /// No passo de tocar: toca na casa [square].
  Future<void> tapSquare(String square) async {
    await $.tester.tapAt(_square(square));
    await $.pumpAndSettle();
  }

  /// Toca no trecho [text] (uma casa ou um lance) da fala do Viktor.
  Future<void> tapInSpeech(String text) async {
    final paragraph = $.tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(LessonKeys.speech).last,
        matching: find.byType(RichText),
      ),
    );
    final plain = paragraph.text.toPlainText();
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: plain.indexOf(text) + 1),
      Rect.zero,
    );
    await $.tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 10)));
    await $.pumpAndSettle();
  }

  /// O destaque da fala no tabuleiro (o anel na casa).
  void expectSpeechRing({required bool visible}) =>
      expect(find.byType(SpeechRing), visible ? findsOneWidget : findsNothing);

  /// O que o Viktor está dizendo.
  String? get speech =>
      _plain($.tester.widget<Text>(find.byKey(LessonKeys.speech).last));

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

  // A fala como texto, simples ou com as casas destacadas (texto rico).
  static String? _plain(Text text) => text.data ?? text.textSpan?.toPlainText();
}
