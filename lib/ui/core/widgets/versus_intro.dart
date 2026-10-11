import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../keys/free_board_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_motion.dart';
import '../theme/app_shape.dart';

/// A entrada de uma partida contra a máquina (T51, A2), sobre o tabuleiro: o
/// cartão do adversário em cima, o do jogador embaixo (cada um na cor das
/// suas peças) e o selo do "VS" no meio. Os cartões saem, um para cima e o
/// outro para baixo; com [countdown] (a Maratona), a contagem 3, 2, 1
/// aparece grande no tabuleiro. Só depois o relógio corre ([onDone]). Sem
/// contagem, um toque pula direto para a partida.
class VersusIntro extends StatefulWidget {
  const VersusIntro({
    required this.playerName,
    required this.opponentName,
    required this.opponentAvatar,
    required this.onDone,
    required this.playerSide,
    this.stage,
    this.countdown = false,
    this.opponentRating,
    super.key,
  });

  final String playerName;
  final String opponentName;
  final Widget opponentAvatar;

  /// A cor do jogador: ele embaixo, o adversário em cima, como no tabuleiro.
  final Side playerSide;

  /// O nível do Maia. Nulo contra o Stockfish.
  final int? opponentRating;

  /// A etapa da Maratona, a partir de 1. Nula fora dela.
  final int? stage;

  /// Com a contagem 3, 2, 1 (só a Maratona).
  final bool countdown;
  final VoidCallback onDone;

  /// A entrada inteira com a contagem: os cartões, a saída deles e os
  /// números.
  static const duration = Duration(milliseconds: 4600);

  /// Sem contagem: os cartões entram, uma pausa curta e saem.
  static const shortDuration = Duration(milliseconds: 2000);

  @override
  State<VersusIntro> createState() => _VersusIntroState();
}

class _VersusIntroState extends State<VersusIntro>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(
          vsync: this,
          duration: widget.countdown
              ? VersusIntro.duration
              : VersusIntro.shortDuration,
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _done();
        })
        ..forward();

  var _finished = false;

  // Uma vez só, mesmo com o toque e o fim da animação juntos.
  void _done() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // De 0 a 1 entre [begin] e [end] do tempo todo.
  double _between(double begin, double end, [Curve curve = AppMotion.linear]) =>
      curve.transform(
        ((_controller.value - begin) / (end - begin)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final still = AppMotion.of(context).disabled;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Primeiro os dois cartões com o "VS"; eles saem, um para cima e o
        // outro para baixo, e a contagem 3, 2, 1 aparece grande no tabuleiro.
        // Sem contagem, a entrada inteira é a dos cartões: as frações do
        // tempo se esticam.
        final scale = widget.countdown ? 1.0 : 0.32 / 0.9;
        double at(double fraction) => fraction / scale;
        final enter = still ? 1.0 : _between(0, at(0.06), AppMotion.enter);
        final exit = still ? 0.0 : _between(at(0.24), at(0.32), AppMotion.exit);
        final shift = 24 * (1 - enter) - 260 * exit;
        final cardsOpacity = (enter * (1 - exit)).clamp(0.0, 1.0);
        final vsPop = still ? 1.0 : _between(0.03, at(0.1), AppMotion.enter);
        final t = _controller.value;
        const countStart = 0.32;
        const third = (1 - countStart) / 3;
        String? count;
        var tick = 0.0;
        if (widget.countdown && !still && t >= countStart) {
          final step = ((t - countStart) / third).floor().clamp(0, 2);
          count = '${3 - step}';
          tick = ((t - countStart) - step * third) / third;
        }
        // O fundo escurecido some junto com o último número.
        final dim = still ? 1.0 : 1 - _between(0.9, 1);
        final stage = widget.stage;
        return GestureDetector(
          key: FreeBoardKeys.versusIntro,
          behavior: HitTestBehavior.opaque,
          // Fora da Maratona, um toque pula a entrada.
          onTap: widget.countdown ? null : _done,
          child: Stack(
            key: widget.countdown ? FreeBoardKeys.marathonBanner : null,
            alignment: Alignment.center,
            children: [
              // O tabuleiro escurece um pouco por trás.
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.3 * dim),
                ),
              ),
              Opacity(
                opacity: cardsOpacity,
                child: Transform.translate(
                  offset: Offset(0, shift),
                  child: Align(
                    alignment: const Alignment(0, -0.3),
                    child: VersusCard(
                      avatar: widget.opponentAvatar,
                      name: widget.opponentName,
                      detail: [
                        if (widget.opponentRating != null)
                          '${widget.opponentRating}',
                        if (stage != null) l10n.marathonStage(stage),
                      ].join(' · '),
                      side: widget.playerSide.opposite,
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: cardsOpacity,
                child: Transform.translate(
                  offset: Offset(0, -shift),
                  child: Align(
                    alignment: const Alignment(0, 0.3),
                    child: VersusCard(
                      avatar: ColoredBox(
                        color: theme.colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                          size: 32,
                        ),
                      ),
                      name: widget.playerName,
                      detail: widget.playerSide == Side.white
                          ? l10n.sideWhite
                          : l10n.sideBlack,
                      side: widget.playerSide,
                    ),
                  ),
                ),
              ),
              // O selo do "VS", entre os dois cartões.
              Opacity(
                opacity: cardsOpacity,
                child: Transform.scale(scale: vsPop, child: const VersusSeal()),
              ),
              // A contagem: cada número entra grande, assenta e apaga.
              if (count != null)
                Opacity(
                  opacity: tick < 0.75 ? 1 : 1 - (tick - 0.75) / 0.25,
                  child: Transform.scale(
                    scale:
                        1.35 -
                        0.35 *
                            AppMotion.enter.transform((tick * 4).clamp(0, 1)),
                    child: Text(
                      count,
                      key: FreeBoardKeys.versusCount,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 144,
                        height: 1,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(
                            blurRadius: 18,
                            offset: Offset(0, 4),
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Um jogador: o retrato quadrado, o nome e a linha de baixo, num cartão na
/// cor das peças dele (escuro para as pretas, claro para as brancas).
class VersusCard extends StatelessWidget {
  const VersusCard({
    required this.avatar,
    required this.name,
    required this.detail,
    required this.side,
    super.key,
  });

  final Widget avatar;
  final String name;
  final String detail;
  final Side side;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = side == Side.black;
    final ink = dark ? Colors.white : const Color(0xFF312E2B);
    return Container(
      width: 236,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF312E2B) : Colors.white,
        borderRadius: BorderRadius.circular(AppShape.small),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black38)],
      ),
      child: Row(
        children: [
          SizedBox.square(dimension: 64, child: avatar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ink.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          // O rei da cor das peças, como o selo da divisão no chess.com.
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ExcludeSemantics(
              child: Image(
                width: 30,
                height: 30,
                image:
                    PieceSet.cburnettAssets[dark
                        ? PieceKind.blackKing
                        : PieceKind.whiteKing]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O selo do "VS", entre os dois cartões.
class VersusSeal extends StatelessWidget {
  const VersusSeal({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF312E2B),
      borderRadius: BorderRadius.circular(AppShape.small),
      boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black38)],
    ),
    child: Text(
      context.l10n.versusLabel,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
    ),
  );
}
