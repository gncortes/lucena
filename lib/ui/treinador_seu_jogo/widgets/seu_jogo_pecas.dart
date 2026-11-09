import 'package:flutter/material.dart';

import '../../core/motion/barra_que_enche.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';

/// Peças visuais comuns às telas do Seu jogo (cartão, barra, linha).

/// O tom claro do azul nas barras que não são a maior.
Color corSuave(BuildContext context) => Color.alphaBlend(
  Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
  AppColors.cardSurface,
);

/// O cinza da parte das derrotas na barra empilhada.
Color corDerrota(BuildContext context) => Color.alphaBlend(
  Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
  AppColors.cardSurface,
);

/// Cartão de seção: título à esquerda, valor curto à direita e o conteúdo.
class SecaoSeuJogo extends StatelessWidget {
  const SecaoSeuJogo({
    required this.titulo,
    required this.child,
    this.valor,
    this.subtitulo,
    super.key,
  });

  final String titulo;
  final String? valor;
  final String? subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variante = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppShape.card),
        border: Border.all(color: AppColors.cardOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (valor case final v?) Text(v, style: variante),
              ],
            ),
            if (subtitulo case final s?) Text(s, style: variante),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

/// Linha com rótulo, detalhe, valor e a barra que enche embaixo.
class LinhaComBarra extends StatelessWidget {
  const LinhaComBarra({
    required this.rotulo,
    required this.valor,
    required this.fracao,
    this.detalhe,
    this.destaque = false,
    super.key,
  });

  final String rotulo;
  final String? detalhe;
  final String valor;
  final double fracao;

  /// A maior do grupo: barra azul cheia e valor em negrito.
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cores = theme.colorScheme;
    final forte = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
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
                    Text(rotulo, style: forte),
                    if (detalhe case final d?)
                      Text(
                        d,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                valor,
                style: destaque
                    ? forte
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: cores.onSurfaceVariant,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BarraQueEnche(
            valor: fracao.clamp(0, 1).toDouble(),
            cor: destaque ? cores.primary : corSuave(context),
            corDoTrilho: AppColors.sheetSurface,
          ),
        ],
      ),
    );
  }
}

/// Barra de vitórias, empates e derrotas lado a lado.
class BarraDoPlacar extends StatelessWidget {
  const BarraDoPlacar({
    required this.vitorias,
    required this.empates,
    required this.derrotas,
    super.key,
  });

  final int vitorias, empates, derrotas;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: SizedBox(
        height: AppSpacing.sm,
        child: Row(
          children: [
            if (vitorias > 0)
              Expanded(
                flex: vitorias,
                child: ColoredBox(color: Theme.of(context).colorScheme.primary),
              ),
            if (empates > 0)
              Expanded(
                flex: empates,
                child: ColoredBox(color: corSuave(context)),
              ),
            if (derrotas > 0)
              Expanded(
                flex: derrotas,
                child: ColoredBox(color: corDerrota(context)),
              ),
          ],
        ),
      ),
    );
  }
}
