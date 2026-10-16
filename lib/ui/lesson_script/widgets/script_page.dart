import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  /// Na tela baixa, a folga mínima entre o tabuleiro e o rodapé; se faltar
  /// altura, o tabuleiro encolhe.
  static const compactGap = 8.0;

  final Key pageKey;

  /// O balão, numa área de altura fixa ([ScriptSpeechMetrics.areaHeight])
  /// medida por [metrics]: as da tela, com as linhas a mais que couberem na
  /// sobra de cima ([ScriptSpeechMetrics.grow]).
  final Widget Function(ScriptSpeechMetrics metrics) speechBuilder;

  /// A faixa do Viktor, com a altura de [stripHeight].
  final Widget strip;
  final Widget Function(double size) boardBuilder;
  final Widget list;

  @override
  Widget build(BuildContext context) {
    final metrics = ScriptSpeechMetrics.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        // A área da fala é fixa (3 linhas) e a faixa também: o tabuleiro tem
        // um tamanho e um lugar só em todos os passos (Gabriel, 14/10/2026).
        // Ele ocupa a largura cheia se couber. O balão fica colado na faixa e
        // a faixa colada no tabuleiro; a sobra de altura se divide em partes
        // iguais acima da área da fala e entre o tabuleiro e o rodapé
        // (Gabriel, 14/10/2026). Na tela baixa, o tabuleiro encosta no rodapé
        // e a lista fica abaixo da dobra.
        final above = metrics.areaHeight(context) + stripHeight;
        final room = box.maxHeight - above - compactGap;
        final size = math.max(0.0, math.min(box.maxWidth, room));
        final spare = math.max(0.0, box.maxHeight - above - size);
        final half = metrics.compact ? 0.0 : spare / 2;
        // Tela baixa: a sobra fica em cima e o tabuleiro encosta no rodapé
        // (folga de [compactGap]).
        final top = metrics.compact ? math.max(0.0, spare - compactGap) : half;
        // As linhas inteiras que cabem na sobra de cima vão para o balão:
        // fala longa usa o vão vazio em vez de rolar dentro do balão; fala
        // curta continua presa embaixo, e o tabuleiro fica onde estava.
        final line = metrics.lineExtent(context);
        final extra = line <= 0 ? 0 : (top / line).floor();
        final grown = metrics.grow(extra);
        return SingleChildScrollView(
          key: pageKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: top - extra * line),
                speechBuilder(grown),
                strip,
                Center(child: boardBuilder(size)),
                SizedBox(height: metrics.compact ? compactGap : half),
                list,
              ],
            ),
          ),
        );
      },
    );
  }
}
