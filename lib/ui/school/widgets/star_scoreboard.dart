import 'package:flutter/material.dart';

import '../../../domain/models/star_challenge.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import 'star_challenge_ui.dart';

/// O placar das estrelas sob o tabuleiro, o mesmo no convite, jogando e no
/// fim: cada tipo de estrela (ouro, prata, bronze) com quanto vale e quantas
/// foram pegas, e o total de pontos. O formato e o tamanho não mudam entre os
/// momentos; só os números. A cada estrela, o ícone da cor dela dá um pulo e
/// os números sobem contando.
class StarScoreboard extends StatelessWidget {
  const StarScoreboard({required this.counts, required this.points, super.key});

  /// Estrelas pegas por cor.
  final Map<StarKind, int> counts;

  /// A soma dos pontos (bronze 1, prata 2, ouro 3).
  final int points;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: StarChallengeKeys.scoreboard,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        children: [
          for (final kind in StarKind.values.reversed)
            Expanded(
              child: _KindCounter(kind: kind, count: counts[kind] ?? 0),
            ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: _Total(points: points)),
        ],
      ),
    );
  }
}

/// Uma linha que diminui em vez de estourar a largura (fonte grande, idioma
/// longo).
class _Fit extends StatelessWidget {
  const _Fit({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: child);
}

/// A estrela de uma cor: quantas foram pegas e quanto ela vale.
class _KindCounter extends StatelessWidget {
  const _KindCounter({required this.kind, required this.count});

  final StarKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Fit(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pop(
                value: count,
                child: Icon(
                  Icons.star_rounded,
                  color: starColor(kind),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _Count(
                value: count,
                builder: (value) => Text(
                  '$value',
                  key: StarChallengeKeys.kindCount(kind.name),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        _Fit(
          child: Text(
            context.l10n.starChallengeWorth(kind.points),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// O total de pontos, em destaque.
class _Total extends StatelessWidget {
  const _Total({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Fit(
            child: _Pop(
              value: points,
              child: _Count(
                value: points,
                builder: (value) => Text(
                  '$value',
                  key: StarChallengeKeys.collected,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          _Fit(
            child: Text(
              context.l10n.starChallengePointsLabel(points),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Um pulo (cresce e volta) a cada vez que [value] sobe. O filho fica
/// montado, para o número dentro dele seguir contando.
class _Pop extends StatefulWidget {
  const _Pop({required this.value, required this.child});

  final int value;
  final Widget child;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1);
  late final _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.4,
        end: 1.0,
      ).chain(CurveTween(curve: AppMotion.pop)),
      weight: 2,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(_Pop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > oldWidget.value) {
      _controller.duration = AppMotion.of(context).celebrate;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// O número que sobe contando até [value].
class _Count extends StatelessWidget {
  const _Count({required this.value, required this.builder});

  final int value;
  final Widget Function(int value) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: value, end: value),
    duration: AppMotion.of(context).component,
    curve: AppMotion.enter,
    builder: (context, value, _) => builder(value),
  );
}
