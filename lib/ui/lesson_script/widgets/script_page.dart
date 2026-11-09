import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/board/centered_board_layout.dart';
import 'script_speech.dart';

/// The Canvas teaching block geometry, shared by the page and its host when
/// deciding whether an action can fit below the board. Reserving actions never
/// changes the board or speech geometry.
class ScriptCanvasMetrics {
  const ScriptCanvasMetrics._(this.lines, this.notation, this.side, this.spare);

  factory ScriptCanvasMetrics.forSize(Size size) {
    var lines = 2;
    var notation = 0.0;
    var side = size.width;
    var spare = 0.0;
    var fits = false;
    for (final candidate in [(4, 40.0), (3, 40.0), (2, 40.0), (2, 0.0)]) {
      final remaining =
          size.height -
          (42 +
              22.5 * candidate.$1 +
              ScriptPage.canvasStripHeight +
              side +
              candidate.$2);
      if (remaining >= 0) {
        lines = candidate.$1;
        notation = candidate.$2;
        spare = remaining;
        fits = true;
        break;
      }
    }
    if (!fits) {
      side = math.max(0, size.height - 87 - ScriptPage.canvasStripHeight);
    }
    return ScriptCanvasMetrics._(lines, notation, side, spare);
  }

  final int lines;
  final double notation, side, spare;
  double get availableListHeight => notation + spare / 2;
}

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
    this.canvasLayout = false,
    this.actionsBelowBoard = false,
    this.centerBoard = false,
    super.key,
  });

  /// A8: o tabuleiro de ponta a ponta com o centro no centro útil da tela
  /// ([BoardViewport.centerYOf]; sem ele, o centro da página). O balão e a
  /// faixa ficam na sobra de cima, com as linhas que couberem (no mínimo
  /// [ScriptSpeechMetrics.minLines]: se nem assim couberem, a faixa fica sob
  /// a borda do tabuleiro); a lista fica embaixo e rola. Exercícios e
  /// abertura do treino; a lição segue com o bloco do canvas (desligado).
  final bool centerBoard;

  /// A altura da faixa do Viktor: retrato 40, nos botões de 48 dp do lado
  /// (protótipo, 50).
  static const stripHeight = 50.0;
  static const canvasStripHeight = 58.0;

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
  final bool canvasLayout;

  /// Discrete actions use their natural height, painting into the empty
  /// footer if necessary. Their hit target still fits inside the page.
  /// Notation keeps its existing clipping and independent scrolling.
  final bool actionsBelowBoard;

  @override
  Widget build(BuildContext context) {
    final metrics = ScriptSpeechMetrics.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        if (centerBoard) {
          return _CenteredPage(page: this, metrics: metrics, box: box);
        }
        if (canvasLayout) {
          // medidas_lance/tela_lance: centre the complete teaching block,
          // reserving notation before reducing the board.
          final geometry = ScriptCanvasMetrics.forSize(
            Size(box.maxWidth, box.maxHeight),
          );
          final lines = geometry.lines;
          final notation = geometry.notation;
          final side = geometry.side;
          final spare = geometry.spare;
          return Column(
            key: pageKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: spare / 2),
              speechBuilder(ScriptSpeechMetrics.canvas(lines)),
              strip,
              Center(child: boardBuilder(side)),
              Expanded(
                child: actionsBelowBoard
                    ? OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: list,
                      )
                    : ClipRect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: notation == 0
                              ? const SizedBox.shrink()
                              : SingleChildScrollView(child: list),
                        ),
                      ),
              ),
            ],
          );
        }
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

/// A8: o tabuleiro de ponta a ponta com o centro no centro útil da tela.
class _CenteredPage extends StatelessWidget {
  const _CenteredPage({
    required this.page,
    required this.metrics,
    required this.box,
  });

  final ScriptPage page;
  final ScriptSpeechMetrics metrics;
  final BoxConstraints box;

  @override
  Widget build(BuildContext context) {
    final height = box.maxHeight;
    final width = box.maxWidth;
    final centerY = (BoardViewport.centerYOf(context) ?? height / 2)
        .clamp(0.0, height)
        .toDouble();
    final double side = math.max(
      0.0,
      math.min(width, 2 * math.min(centerY, height - centerY)),
    );
    final boardTop = centerY - side / 2;
    final boardBottom = boardTop + side;
    // As linhas que cabem na sobra de cima, de [minLines] até 4.
    final ScriptSpeechMetrics speech;
    final double header;
    if (page.canvasLayout) {
      var lines = ScriptSpeechMetrics.minLines;
      for (final candidate in [4, 3]) {
        if (42 + 22.5 * candidate + ScriptPage.canvasStripHeight <= boardTop) {
          lines = candidate;
          break;
        }
      }
      speech = ScriptSpeechMetrics.canvas(lines);
      header = speech.areaHeight(context) + ScriptPage.canvasStripHeight;
    } else {
      final base = metrics.withLines(ScriptSpeechMetrics.minLines);
      final line = base.lineExtent(context);
      final room = boardTop - base.areaHeight(context) - ScriptPage.stripHeight;
      final extra = line <= 0 || room <= 0 ? 0 : (room / line).floor();
      speech = metrics.withLines(ScriptSpeechMetrics.minLines + extra);
      header = speech.areaHeight(context) + ScriptPage.stripHeight;
    }
    return Stack(
      key: page.pageKey,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: math.max(0.0, boardTop - header),
          height: header,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: page.speechBuilder(speech)),
              page.strip,
            ],
          ),
        ),
        // O tabuleiro vem por cima: na tela baixa, a faixa que passar da
        // borda fica embaixo dele e não rouba o toque das casas.
        Positioned(
          left: (width - side) / 2,
          top: boardTop,
          width: side,
          height: side,
          child: page.boardBuilder(side),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: boardBottom,
          bottom: 0,
          child: page.actionsBelowBoard
              ? OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: page.list,
                )
              : ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SingleChildScrollView(child: page.list),
                  ),
                ),
        ),
      ],
    );
  }
}
