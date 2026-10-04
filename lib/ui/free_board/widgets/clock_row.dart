import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/free_board_state.dart';

/// Uma fileira de relógios: o de um lado só (com o nome do lado) ou os dois
/// juntos, brancas primeiro.
class ClockRow extends StatelessWidget {
  const ClockRow({required this.sides, required this.state, super.key});

  /// Altura da fileira, para a tela reservar o espaço do tabuleiro.
  static const height = 56.0;

  final List<Side> sides;
  final FreeBoardState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          spacing: 8,
          children: [
            for (final side in sides)
              Expanded(
                child: _ClockTile(
                  key: FreeBoardKeys.clock(side),
                  side: side,
                  time: state.timeOf(side),
                  running: state.clock?.running == side,
                  showName: sides.length == 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClockTile extends StatelessWidget {
  const _ClockTile({
    required this.side,
    required this.time,
    required this.running,
    required this.showName,
    super.key,
  });

  final Side side;
  final Duration time;

  /// O relógio que está correndo ganha destaque.
  final bool running;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLow = time < ClockEngine.lowTime;
    final (background, foreground) = switch ((running, isLow)) {
      (true, true) => (colors.error, colors.onError),
      (true, false) => (colors.primary, colors.onPrimary),
      (false, _) => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
    final name = side == Side.white
        ? context.l10n.sideWhite
        : context.l10n.sideBlack;
    return Semantics(
      container: true,
      label: name,
      selected: running,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Disco da cor do lado.
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: side == Side.white ? Colors.white : Colors.black,
                border: Border.all(color: colors.outline, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: showName
                  ? ExcludeSemantics(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Os números do relógio são sempre da esquerda para a direita.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                ClockFormat.format(time),
                key: FreeBoardKeys.clockTime(side),
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  // Algarismos da mesma largura: o texto não treme ao contar.
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
