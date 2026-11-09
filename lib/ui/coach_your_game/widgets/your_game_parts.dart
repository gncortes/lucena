import 'package:flutter/material.dart';

import '../../core/motion/barra_que_enche.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_card.dart';
import '../../../domain/models/coach/coach.dart';
import '../../core/l10n/l10n.dart';
import 'your_game_texts.dart';
import '../../core/theme/app_text.dart';

/// Peças visuais comuns às telas do Seu jogo (cartão, barra, linha).

/// O tom claro do azul nas barras que não são a maior.
Color softColor(BuildContext context) => Color.alphaBlend(
  Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
  AppColors.cardSurface,
);

/// O cinza da parte das derrotas na barra empilhada.
Color lossColor(BuildContext context) => Color.alphaBlend(
  Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
  AppColors.cardSurface,
);

/// Cartão de seção: título à esquerda, valor curto à direita e o conteúdo.
class YourGameSection extends StatelessWidget {
  const YourGameSection({
    required this.title,
    required this.child,
    this.value,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? value;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return LucenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppWeight.medium,
                  ),
                ),
              ),
              if (value case final v?) Text(v, style: variant),
            ],
          ),
          if (subtitle case final s?) Text(s, style: variant),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Linha com rótulo, detalhe, valor e a barra que enche embaixo.
class BarRow extends StatelessWidget {
  const BarRow({
    required this.label,
    required this.value,
    required this.fraction,
    this.detail,
    this.highlight = false,
    super.key,
  });

  final String label;
  final String? detail;
  final String value;
  final double fraction;

  /// A maior do grupo: barra azul cheia e valor em negrito.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final strong = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: AppWeight.medium,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: strong),
                    if (detail case final d?)
                      Text(
                        d,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                value,
                style: highlight
                    ? strong
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BarraQueEnche(
            valor: fraction.clamp(0, 1).toDouble(),
            cor: highlight ? colors.primary : softColor(context),
            corDoTrilho: AppColors.sheetSurface,
          ),
        ],
      ),
    );
  }
}

/// O que as três faixas da [ScoreBar] contam.
enum ScoreStyle {
  /// Dele: vitórias em azul, empates no azul claro, derrotas em cinza.
  result,

  /// Da teoria (Lichess): brancas, empates e pretas nas cores das peças, com
  /// o % das brancas e o das pretas dentro da barra (canvas DAnaliseTeoria).
  colors,
}

/// Barra de três faixas lado a lado: vitórias, empates e derrotas dele ou,
/// no estilo [ScoreStyle.colors], brancas, empates e pretas.
class ScoreBar extends StatelessWidget {
  const ScoreBar({
    required this.wins,
    required this.draws,
    required this.losses,
    this.style = ScoreStyle.result,
    super.key,
  });

  /// No estilo [ScoreStyle.colors], as vitórias das brancas.
  final int wins;
  final int draws;

  /// No estilo [ScoreStyle.colors], as vitórias das pretas.
  final int losses;
  final ScoreStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = style == ScoreStyle.colors;
    final (first, middlegame, last) = colors
        ? (
            AppColors.chessWhiteColor,
            AppColors.trainingAnalysisInactive,
            AppColors.chessBlackColor,
          )
        : (
            Theme.of(context).colorScheme.primary,
            softColor(context),
            lossColor(context),
          );
    final bands = Row(
      // Stretch: ColoredBox sem filho mede a altura mínima (zero) se solta.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wins > 0)
          Expanded(
            flex: wins,
            child: ColoredBox(color: first),
          ),
        if (draws > 0)
          Expanded(
            flex: draws,
            child: ColoredBox(color: middlegame),
          ),
        if (losses > 0)
          Expanded(
            flex: losses,
            child: ColoredBox(color: last),
          ),
      ],
    );
    if (!colors) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: SizedBox(height: AppSpacing.sm, child: bands),
      );
    }
    final t = context.l10n;
    final text = Theme.of(context).textTheme.labelSmall
        ?.copyWith(fontWeight: FontWeight.w600, height: 1);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.trainingAnalysisDivider),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: SizedBox(
          height: AppSpacing.lg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              bands,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    if (wins > 0)
                      Text(
                        t.sjPorcento(wins),
                        style: text?.copyWith(color: AppColors.chessBlackColor),
                      ),
                    const Spacer(),
                    if (losses > 0)
                      Text(
                        t.sjPorcento(losses),
                        style: text?.copyWith(color: AppColors.chessWhiteColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Com 60 partidas: leitura firme" e os três degraus (primeira leitura, em
/// formação, leitura firme). Sem fundo próprio: vai dentro de um cartão.
class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({
    required this.level,
    required this.games,
    this.corDoTrilho,
    super.key,
  });

  final StyleLevel level;
  final int games;

  /// O cinza dos degraus que faltam; o padrão serve ao cartão neutro.
  final Color? corDoTrilho;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final variant = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.sjEstiloComPartidas(games, level.wire),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppWeight.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final n in StyleLevel.values) ...[
              if (n.index > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                // Stretch: ColoredBox sem filho mede largura zero se solta.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: SizedBox(
                        height: 6,
                        child: ColoredBox(
                          color: n.index <= level.index
                              ? primaryColor
                              : corDoTrilho ?? AppColors.sheetSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.levelName(n),
                      style: n == level
                          ? theme.textTheme.bodySmall?.copyWith(
                              fontWeight: AppWeight.medium,
                            )
                          : variant,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
