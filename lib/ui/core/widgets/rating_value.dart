import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'goal_style.dart';

/// O rating em destaque com a variação ao lado, em verde (+) ou vermelho (−),
/// como no chess.com. Sem [change], só o número.
class RatingValue extends StatelessWidget {
  const RatingValue({
    required this.rating,
    this.change,
    this.large = false,
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
  final Key? valueKey;
  final Key? changeKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = this.change;
    final style =
        (large ? theme.textTheme.displaySmall : theme.textTheme.headlineSmall)
            ?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(rating.toString(), key: valueKey, style: style),
        if (change != null) ...[
          const SizedBox(width: 8),
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
            size: large ? 28 : 24,
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
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
          ),
        ],
      ),
    ];
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
