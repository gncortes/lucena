import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';

/// A entrada de cada etapa da Maratona, sobre o tabuleiro: o cartão do
/// adversário em cima, o do jogador embaixo (cada um na cor das suas peças) e
/// o selo do "VS" no meio. Os cartões saem, um para cima e o outro para
/// baixo, e a contagem 3, 2, 1 aparece grande no tabuleiro; só depois o
/// relógio corre ([onDone]): é o fôlego entre as etapas.
class VersusIntro extends StatefulWidget {
  const VersusIntro({
    required this.playerName,
    required this.opponentName,
    required this.opponentAvatar,
    required this.stage,
    required this.onDone,
    required this.playerSide,
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

  /// A etapa, a partir de 1.
  final int stage;
  final VoidCallback onDone;

  /// A entrada inteira: os cartões, a saída deles e a contagem.
  static const duration = Duration(milliseconds: 4600);

  @override
  State<VersusIntro> createState() => _VersusIntroState();
}

class _VersusIntroState extends State<VersusIntro>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: VersusIntro.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // De 0 a 1 entre [begin] e [end] do tempo todo.
  double _between(double begin, double end, [Curve curve = Curves.linear]) =>
      curve.transform(
        ((_controller.value - begin) / (end - begin)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Primeiro os dois cartões com o "VS"; eles saem, um para cima e o
        // outro para baixo, e a contagem 3, 2, 1 aparece grande no tabuleiro.
        final enter = still ? 1.0 : _between(0, 0.06, Curves.easeOutCubic);
        final exit = still ? 0.0 : _between(0.24, 0.32, Curves.easeInCubic);
        final shift = 24 * (1 - enter) - 260 * exit;
        final cardsOpacity = (enter * (1 - exit)).clamp(0.0, 1.0);
        final vsPop = still ? 1.0 : _between(0.03, 0.1, Curves.easeOutBack);
        final t = _controller.value;
        const countStart = 0.32;
        const third = (1 - countStart) / 3;
        String? count;
        var tick = 0.0;
        if (!still && t >= countStart) {
          final step = ((t - countStart) / third).floor().clamp(0, 2);
          count = '${3 - step}';
          tick = ((t - countStart) - step * third) / third;
        }
        // O fundo escurecido some junto com o último número.
        final dim = still ? 1.0 : 1 - _between(0.9, 1);
        return Stack(
          key: FreeBoardKeys.marathonBanner,
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
                  child: _Card(
                    avatar: widget.opponentAvatar,
                    name: widget.opponentName,
                    detail: [
                      if (widget.opponentRating != null)
                        '${widget.opponentRating}',
                      l10n.marathonStage(widget.stage),
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
                  child: _Card(
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
              child: Transform.scale(
                scale: vsPop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E2B),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Colors.black38),
                    ],
                  ),
                  child: Text(
                    l10n.versusLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            // A contagem: cada número entra grande, assenta e apaga.
            if (count != null)
              Opacity(
                opacity: tick < 0.75 ? 1 : 1 - (tick - 0.75) / 0.25,
                child: Transform.scale(
                  scale:
                      1.35 -
                      0.35 *
                          Curves.easeOutBack.transform((tick * 4).clamp(0, 1)),
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
        );
      },
    );
  }
}

/// Um jogador: o retrato quadrado, o nome e a linha de baixo, num cartão na
/// cor das peças dele (escuro para as pretas, claro para as brancas).
class _Card extends StatelessWidget {
  const _Card({
    required this.avatar,
    required this.name,
    required this.detail,
    required this.side,
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
        borderRadius: BorderRadius.circular(6),
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
