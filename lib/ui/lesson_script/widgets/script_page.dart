import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/widgets/speech_balloon.dart';
import 'script_speech.dart';

/// A página das telas em 3 etapas e do exercício (T70/T72): o balão do
/// Viktor, a faixa dele, o tabuleiro e a lista de lances, numa página que
/// rola inteira quando a lista passa do fundo. É a mesma conta nas duas
/// telas: um componente só (Gabriel, 14/10/2026).
class ScriptPage extends StatelessWidget {
  const ScriptPage({
    required this.pageKey,
    required this.speechBuilder,
    required this.strip,
    required this.boardBuilder,
    required this.list,
    super.key,
  });

  /// A altura da faixa do Viktor: retrato 40, nos botões de 48 dp do lado
  /// (protótipo, 50).
  static const stripHeight = 50.0;

  /// A folga entre a ponta do balão e o retrato: 4 dp (T72, canvas `CompBalao`).
  static const tailGap = 4.0;

  /// Na tela baixa, a folga mínima entre o tabuleiro e o rodapé; se faltar
  /// altura, o tabuleiro encolhe.
  static const compactGap = 8.0;

  final Key pageKey;

  /// O balão, com até quantas linhas ele pode ter (nulo: o padrão).
  final Widget Function(int? lines) speechBuilder;

  /// A faixa do Viktor, já com a altura de [stripHeight] + [tailGap].
  final Widget strip;
  final Widget Function(double size) boardBuilder;
  final Widget list;

  @override
  Widget build(BuildContext context) {
    final metrics = ScriptSpeechMetrics.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        // O tabuleiro tem um tamanho só: a largura cheia, desde que caiba com
        // a fala de duas linhas e o retrato acima; nunca encolhe para
        // centralizar nem para mostrar a lista. Na tela baixa, o maior
        // possível, e a lista fica abaixo da dobra (Gabriel, 14/10/2026;
        // canvas `T70-etapa1-estados`).
        final above =
            metrics.top +
            metrics.minHeight(context) +
            SpeechBalloon.tailHeight +
            stripHeight +
            tailGap;
        final room = box.maxHeight - above - compactGap;
        final size = math.max(0.0, math.min(box.maxWidth, room));
        // A fala vai até 4 linhas, ou mais se couberem acima do tabuleiro
        // centralizado; depois a letra desce até 12 sp e, só então, o
        // tabuleiro desce o necessário.
        final bubbleRoom =
            (box.maxHeight - size) / 2 -
            stripHeight -
            tailGap -
            SpeechBalloon.tailHeight -
            ScriptSpeechMetrics.minTop -
            2 * metrics.verticalPadding;
        final lines = metrics.compact
            ? null
            : math.max(
                metrics.maxLines,
                (bubbleRoom / metrics.lineExtent(context)).floor(),
              );
        // Centralizado na altura sempre que dá; a fala sobe no espaço de
        // cima e só empurra o tabuleiro quando não cabe ali. A tela toda
        // rola, sem barra, quando a lista passa do fundo.
        return SingleChildScrollView(
          key: pageKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    // Tela baixa: o tabuleiro encosta no rodapé (a folga de
                    // [compactGap]) e a lista fica toda abaixo da dobra, sem a
                    // primeira linha cortada pelo meio.
                    minHeight: metrics.compact
                        ? math.max(0, box.maxHeight - size - compactGap)
                        : (box.maxHeight - size) / 2,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(children: [speechBuilder(lines), strip]),
                  ),
                ),
                Center(child: boardBuilder(size)),
                // Tela baixa: a lista começa abaixo da dobra, depois do vão.
                if (metrics.compact) const SizedBox(height: compactGap),
                list,
              ],
            ),
          ),
        );
      },
    );
  }
}
