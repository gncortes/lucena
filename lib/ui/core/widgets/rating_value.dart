import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'goal_style.dart';

/// O rating em destaque com a variação ao lado, em verde (+) ou vermelho (−),
/// como no chess.com. Sem [change], só o número.
class RatingValue extends StatelessWidget {
  const RatingValue({
    required this.rating,
    this.change,
    this.large = false,
    this.animateOnce = false,
    this.valueKey,
    this.changeKey,
    this.up,
    super.key,
  });

  /// Se a variação é de subida. Nulo: pelo sinal de [change]. Serve para a
  /// seta e a cor não trocarem enquanto o número conta a partir do zero.
  final bool? up;

  final int rating;
  final int? change;

  /// O número grande do perfil; o menor vai no painel do fim da partida.
  final bool large;

  /// Opt-in entrance count. A rebuild/reload does not restart the counter.
  /// Existing callers (including conclusion counters) stay unchanged.
  final bool animateOnce;
  final Key? valueKey;
  final Key? changeKey;

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    if (animateOnce) {
      if (AppMotion.of(context).disabled) {
        return RatingValue(
          rating: rating,
          change: change,
          large: large,
          valueKey: valueKey,
          changeKey: changeKey,
          up: up,
        );
      }
      return _CountedRating(value: this);
    }
    final theme = Theme.of(context);
    final style =
        (large ? theme.textTheme.displaySmall : theme.textTheme.headlineSmall)
            ?.copyWith(
              fontWeight: AppWeight.heavy,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(rating.toString(), key: valueKey, style: style),
        if (change != null) ...[
          const SizedBox(width: AppSpacing.sm),
          ..._change(context, theme, change, up ?? change >= 0),
        ],
      ],
    );
  }

  List<Widget> _change(
    BuildContext context,
    ThemeData theme,
    int change,
    bool up,
  ) {
    return [
      // A variação em texto verde ou vermelho, com a seta, sem fundo.
      Row(
        key: changeKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: large ? AppIconSize.large : AppIconSize.standard,
            color: ChangeColors.of(context, up: up),
          ),
          Text(
            signedChange(change),
            textDirection: TextDirection.ltr,
            style:
                (large
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleMedium)
                    ?.copyWith(
                      color: ChangeColors.of(context, up: up),
                      fontWeight: AppWeight.strong,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          ),
        ],
      ),
    ];
  }
}

class _CountedRating extends StatefulWidget {
  const _CountedRating({required this.value});
  final RatingValue value;

  @override
  State<_CountedRating> createState() => _CountedRatingState();
}

class _CountedRatingState extends State<_CountedRating>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AppMotion.of(context);
    if (motion.disabled) {
      _started = true;
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      _controller.duration = motion.screen;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) => RatingValue(
        rating: (value.rating * _curve.value).round(),
        change: value.change,
        large: value.large,
        valueKey: value.valueKey,
        changeKey: value.changeKey,
        up: value.up,
      ),
    );
  }
}

/// A variação com sinal: `+12`, `−8` (com o sinal de menos tipográfico) e `0`.
String signedChange(int change) => change > 0
    ? '+$change'
    : change < 0
    ? '−${-change}'
    : '0';

/// O rating e a variação para o leitor de tela.
String ratingSemantics(BuildContext context, int rating, int change) =>
    context.l10n.reportRating(rating, signedChange(change));
