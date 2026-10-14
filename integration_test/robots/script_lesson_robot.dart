import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';
import '../../testing/e2e_dependencies.dart';

/// A tela da aula roteirizada (T70/T71): o balão do Viktor, o tabuleiro, o
/// Continuar e o que mais a fase pede. O estado é lido do cubit; os gestos
/// são os do jogador (toque no tabuleiro, no balão, nos botões).
class ScriptLessonRobot {
  const ScriptLessonRobot(this.$);

  final PatrolIntegrationTester $;

  LessonScriptCubit get cubit => $.tester
      .element(find.byKey(LessonScriptKeys.screen))
      .read<LessonScriptCubit>();

  LessonScriptState get state => cubit.state;

  /// Texto do Viktor agora, de todos os trechos.
  String get speech => state.speech.join(' ');

  Chessboard get _chessboard =>
      $.tester.widget<Chessboard>(find.byKey(LessonScriptKeys.board));

  /// Anda o relógio do app junto com o real (a demonstração e o ritmo da
  /// aula medem o tempo pelo relógio injetado) e deixa a tela assentar.
  Future<void> settle([int steps = 8]) async {
    for (var i = 0; i < steps; i++) {
      e2eNow.advance(const Duration(milliseconds: 100));
      await $.pump(const Duration(milliseconds: 100));
    }
  }

  /// Espera [done] ser verdadeiro, até [timeout].
  Future<void> waitUntil(
    bool Function() done, {
    Duration timeout = const Duration(seconds: 20),
    String reason = 'não aconteceu',
  }) async {
    final start = DateTime.now();
    while (!done()) {
      if (DateTime.now().difference(start) > timeout) {
        fail(
          '$reason em $timeout (fase ${state.phase}, '
          'etapa ${state.stageId}, exemplo ${state.exampleIndex})',
        );
      }
      await settle(2);
    }
  }

  /// Anda a aula como o aluno: Continuar quando há, "Ver a resposta" nas
  /// perguntas e espera nas demonstrações, até [done] ser verdadeiro.
  Future<void> advanceUntil(bool Function() done) async {
    for (var i = 0; i < 300 && !done(); i++) {
      if (find.byKey(LessonScriptKeys.primary).evaluate().isNotEmpty) {
        await $(LessonScriptKeys.primary).tap();
        await settle(4);
      } else if (find
          .byKey(LessonScriptKeys.showAnswer)
          .evaluate()
          .isNotEmpty) {
        await $(LessonScriptKeys.showAnswer).tap();
        await settle(4);
      } else {
        await settle(5);
      }
    }
    expect(done(), isTrue, reason: 'a aula não chegou onde se esperava');
    await settle(4);
  }

  /// Anda até a fase [phase] (na etapa [stage], se dada).
  Future<void> advanceToPhase(ScriptPhase phase, {String? stage}) =>
      advanceUntil(
        () => state.phase == phase && (stage == null || state.stageId == stage),
      );

  /// Anda até o exemplo [example] da etapa [stage], já na fase [phase].
  Future<void> advanceToExample(String stage, int example, ScriptPhase phase) =>
      advanceUntil(
        () =>
            state.stageId == stage &&
            state.exampleIndex == example &&
            state.phase == phase,
      );

  // ---- balão e folha --------------------------------------------------------

  /// O toque no balão abre a fala inteira numa folha, qualquer que seja o
  /// tamanho da fala; o ✕ dela fecha. O balão em si não tem ✕.
  Future<void> expectSpeechSheetRoundTrip() async {
    final balloon = find.byKey(LessonScriptKeys.speech);
    await $(balloon).waitUntilVisible();
    expect(
      find.descendant(of: balloon, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
    await $.tester.tap(balloon);
    await $.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
    await $(LessonScriptKeys.speechSheetClose).tap();
    await $.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsNothing);
  }

  /// Toca no trecho [text] (um link como "Show answer") da fala do balão.
  Future<void> tapInSpeech(String text) async {
    final paragraph = $.tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byKey(LessonScriptKeys.speech),
            matching: find.byType(RichText),
          )
          .first,
    );
    final plain = paragraph.text.toPlainText();
    final at = plain.indexOf(text);
    expect(at, greaterThanOrEqualTo(0), reason: '"$text" não está na fala');
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: at + 1),
      Rect.zero,
    );
    await $.tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 10)));
    await $.pumpAndSettle();
  }

  // ---- tabuleiro ------------------------------------------------------------

  Offset _square(String square) => squareCenter(
    $.tester.getRect(find.byKey(LessonScriptKeys.board)),
    square,
    orientation: _chessboard.orientation,
  );

  /// Toca na casa de origem e depois na de destino.
  Future<void> move(String from, String to) async {
    await $.tester.tapAt(_square(from));
    await $.pump();
    await $.tester.tapAt(_square(to));
    await $.pump();
  }

  /// Toque numa casa (prática do tipo toque).
  Future<void> tapSquare(String square) async {
    await $.tester.tapAt(_square(square));
    await settle(3);
  }

  /// A posição (só a parte das peças do FEN) que o tabuleiro mostra.
  String get placement => state.fen.split(' ').first;

  // ---- lance errado ---------------------------------------------------------

  /// Joga [from]-[to], que a pergunta não aceita: o lance aparece, o Viktor
  /// diz o erro, e a peça volta sozinha para a posição de antes, na mesma
  /// pergunta e com o tabuleiro movível de novo.
  Future<void> expectWrongMoveBounces(
    String from,
    String to, {
    required String errorText,
  }) async {
    final before = state.fen;
    expect(state.phase, ScriptPhase.pergunta);
    await move(from, to);
    await settle(2);
    expect(state.tone, ScriptTone.bad);
    expect(speech, contains(errorText));
    // A peça volta depois do atraso do desfazer (800 ms) e o erro continua
    // na fala.
    await waitUntil(
      () => state.fen == before && state.movable != null,
      timeout: const Duration(seconds: 5),
      reason: 'a peça não voltou',
    );
    expect(state.phase, ScriptPhase.pergunta);
    expect(state.tone, ScriptTone.bad);
    expect(speech, contains(errorText));
    expect(find.byKey(LessonScriptKeys.back), findsNothing);
  }

  // ---- ver a resposta e lista de lances -------------------------------------

  void expectMoveListHidden() =>
      expect(find.byKey(LessonScriptKeys.moveList), findsNothing);

  /// A lista de lances aparece com ao menos um lance.
  void expectMoveListShown() {
    expect(find.byKey(LessonScriptKeys.moveList), findsOneWidget);
    expect(state.moves, isNotEmpty);
  }

  // ---- coordenadas ----------------------------------------------------------

  /// As letras e os números da borda estão ou não desenhados.
  void expectCoordinates({required bool visible}) {
    expect(state.coordinates, visible);
    expect(
      find.byKey(LessonScriptKeys.coordinates),
      visible ? findsWidgets : findsNothing,
    );
  }
}
