import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// A tela de conclusão (T51, frente B): abre no lugar da partida contra a
/// máquina quando ela acaba, depois do resultado em destaque no tabuleiro.
class ConclusionRobot {
  const ConclusionRobot(this.$);

  final PatrolIntegrationTester $;

  /// Espera a conclusão abrir e ficar pronta (o título no cabeçalho).
  Future<void> waitConclusion() async {
    await $(ConclusionKeys.screen).waitUntilVisible();
    // O aviso de conquista nova desce por cima do título: basta existir.
    await $(ConclusionKeys.title).waitUntilExists();
    await $.pumpAndSettle();
  }

  /// O título do cabeçalho: `You won!`, `You lost`, `Draw` ou, no speedrun,
  /// a etapa.
  Future<void> expectTitle(String title) async {
    await waitConclusion();
    expectText(_text(ConclusionKeys.title), title);
  }

  /// Como a partida acabou (`Checkmate`, `Resignation`, `Time out`...).
  Future<void> expectReason(String reason) async {
    await waitConclusion();
    expectText(_text(ConclusionKeys.reason), reason);
  }

  /// O fim da partida contra a máquina: o resultado do ponto de vista do
  /// jogador e o motivo.
  Future<void> expectEnd({
    required String title,
    required String reason,
  }) async {
    await expectTitle(title);
    expectText(_text(ConclusionKeys.reason), reason);
  }

  /// O objetivo do treino: `Goal achieved!` ou `Goal not achieved`.
  Future<void> expectGoal(String text) async {
    await waitConclusion();
    await $(ConclusionKeys.goal).waitUntilVisible();
    expectText(_text(ConclusionKeys.goal), text);
  }

  /// O rating contando do antigo ao novo, com a variação num selo.
  Future<void> expectRatingChanged() async {
    await waitConclusion();
    await $(ConclusionKeys.ratingValue).scrollTo();
    await $(ConclusionKeys.ratingDelta).waitUntilVisible();
  }

  /// O botão da ação [action] está (ou não está) na tela.
  Future<void> expectAction(ConclusionAction action) async {
    await waitConclusion();
    await $(ConclusionKeys.action(action)).scrollTo();
  }

  void expectNoAction(ConclusionAction action) {
    expect(find.byKey(ConclusionKeys.action(action)), findsNothing);
  }

  /// Toca na ação [action]. "Analisar a partida" fica fixo embaixo; as
  /// outras ficam na lista e podem estar fora da tela.
  Future<void> tap(ConclusionAction action) async {
    await waitConclusion();
    if (action == ConclusionAction.analyze) {
      await $(ConclusionKeys.action(action)).tap();
    } else {
      await $(ConclusionKeys.action(action)).scrollTo().tap();
    }
    await $.pumpAndSettle();
  }

  /// "Jogar de novo": a mesma posição e configuração num tabuleiro novo, no
  /// lugar da conclusão.
  Future<void> playAgain() async {
    await tap(ConclusionAction.playAgain);
    await _waitBoard();
  }

  /// "Próximo desafio", na conclusão de um desafio da Jornada.
  Future<void> nextChallenge() async {
    await tap(ConclusionAction.nextChallenge);
    await _waitBoard();
  }

  /// Fecha a conclusão: volta para onde o jogador estava antes da partida.
  Future<void> close() async {
    await waitConclusion();
    await $(ConclusionKeys.close).tap();
    await $.pumpAndSettle();
    expect(find.byKey(ConclusionKeys.screen), findsNothing);
  }

  /// No speedrun: o tempo da etapa que acabou de ser vencida.
  Future<void> expectStageTime(String time) async {
    await $(ConclusionKeys.stageTime).scrollTo();
    // "Tempo da etapa: 5.0 s" (o rótulo vem antes do tempo).
    expect(_lastText(ConclusionKeys.stageTime), endsWith(time));
  }

  /// No speedrun: o total (somado até aqui ou, no fim, o da tentativa).
  Future<void> expectTotal(String time) async {
    await $(ConclusionKeys.total).scrollTo();
    expect(_lastText(ConclusionKeys.total), time);
  }

  /// No fim do speedrun: os tempos de cada etapa, em ordem, e por fim o
  /// total (os textos de tempo do quadro do speedrun).
  Future<List<String>> runTimes() async {
    await $(ConclusionKeys.run).scrollTo();
    // Os tempos de cada etapa ficam em "Ver estatística detalhada" (T51).
    if (find.byKey(ConclusionKeys.stage(0)).evaluate().isEmpty &&
        find.byKey(ConclusionKeys.runDetails).evaluate().isNotEmpty) {
      await $(ConclusionKeys.runDetails).scrollTo().tap();
      await $.pumpAndSettle();
    }
    final time = RegExp(r'^\d.* s$');
    List<String> timesIn(Key key) => [
      for (final text in $.tester.widgetList<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)),
      ))
        if (text.data case final data? when time.hasMatch(data)) data,
    ];
    return [
      for (
        var stage = 0;
        find.byKey(ConclusionKeys.stage(stage)).evaluate().isNotEmpty;
        stage++
      )
        ...timesIn(ConclusionKeys.stage(stage)),
      ...timesIn(ConclusionKeys.total),
    ];
  }

  Future<void> expectNewRecord({required bool record}) async {
    await $(ConclusionKeys.run).scrollTo();
    if (record) {
      await $(ConclusionKeys.newRecord).waitUntilVisible();
    } else {
      expect(find.byKey(ConclusionKeys.newRecord), findsNothing);
    }
  }

  /// As mensagens do fim da partida (primeira vitória, conquistas), em
  /// ordem. A lista desce até o fim para todas estarem montadas.
  Future<List<String>> feedback() async {
    await waitConclusion();
    final scrollable = find
        .descendant(
          of: find.byKey(ConclusionKeys.screen),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = $.tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await $.pumpAndSettle();
    final texts = <String>[];
    for (var index = 0; ; index++) {
      final finder = find.byKey(FreeBoardKeys.feedback(index));
      if (finder.evaluate().isEmpty) return texts;
      texts.add(
        $.tester
            .widgetList<Text>(
              find.descendant(of: finder, matching: find.byType(Text)),
            )
            .first
            .data!,
      );
    }
  }

  Future<void> _waitBoard() async {
    await $(FreeBoardKeys.board).waitUntilVisible();
    expect(find.byKey(ConclusionKeys.screen), findsNothing);
  }

  // O texto dentro da key (o próprio Text ou o primeiro dentro dela).
  String? _text(Key key) => _texts(key).first;

  // O último texto dentro da key: numa linha "rótulo, valor", o valor.
  String? _lastText(Key key) => _texts(key).last;

  List<String?> _texts(Key key) => [
    for (final text in $.tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(Text),
        matchRoot: true,
      ),
    ))
      text.data ?? text.textSpan?.toPlainText(),
  ];
}
