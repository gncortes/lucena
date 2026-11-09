import 'package:flutter/material.dart';

import '../../core/motion/barra_que_enche.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_card.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../core/l10n/l10n.dart';
import 'seu_jogo_textos.dart';

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
    return LucenaCard(
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

/// O que as três faixas da [BarraDoPlacar] contam.
enum EstiloPlacar {
  /// Dele: vitórias em azul, empates no azul claro, derrotas em cinza.
  resultado,

  /// Da teoria (Lichess): brancas, empates e pretas nas cores das peças, com
  /// o % das brancas e o das pretas dentro da barra (canvas DAnaliseTeoria).
  cores,
}

/// Barra de três faixas lado a lado: vitórias, empates e derrotas dele ou,
/// no estilo [EstiloPlacar.cores], brancas, empates e pretas.
class BarraDoPlacar extends StatelessWidget {
  const BarraDoPlacar({
    required this.vitorias,
    required this.empates,
    required this.derrotas,
    this.estilo = EstiloPlacar.resultado,
    super.key,
  });

  /// No estilo [EstiloPlacar.cores], as vitórias das brancas.
  final int vitorias;
  final int empates;

  /// No estilo [EstiloPlacar.cores], as vitórias das pretas.
  final int derrotas;
  final EstiloPlacar estilo;

  @override
  Widget build(BuildContext context) {
    final cores = estilo == EstiloPlacar.cores;
    final (primeira, meio, ultima) = cores
        ? (
            AppColors.chessWhiteColor,
            AppColors.trainingAnalysisInactive,
            AppColors.chessBlackColor,
          )
        : (
            Theme.of(context).colorScheme.primary,
            corSuave(context),
            corDerrota(context),
          );
    final faixas = Row(
      // Stretch: ColoredBox sem filho mede a altura mínima (zero) se solta.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vitorias > 0)
          Expanded(
            flex: vitorias,
            child: ColoredBox(color: primeira),
          ),
        if (empates > 0)
          Expanded(
            flex: empates,
            child: ColoredBox(color: meio),
          ),
        if (derrotas > 0)
          Expanded(
            flex: derrotas,
            child: ColoredBox(color: ultima),
          ),
      ],
    );
    if (!cores) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: SizedBox(height: AppSpacing.sm, child: faixas),
      );
    }
    final t = context.l10n;
    final texto = Theme.of(context).textTheme.labelSmall
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
              faixas,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    if (vitorias > 0)
                      Text(
                        t.sjPorcento(vitorias),
                        style: texto?.copyWith(
                          color: AppColors.chessBlackColor,
                        ),
                      ),
                    const Spacer(),
                    if (derrotas > 0)
                      Text(
                        t.sjPorcento(derrotas),
                        style: texto?.copyWith(
                          color: AppColors.chessWhiteColor,
                        ),
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
class MedidorConfianca extends StatelessWidget {
  const MedidorConfianca({
    required this.nivel,
    required this.partidas,
    this.corDoTrilho,
    super.key,
  });

  final NivelEstilo nivel;
  final int partidas;

  /// O cinza dos degraus que faltam; o padrão serve ao cartão neutro.
  final Color? corDoTrilho;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final primaria = theme.colorScheme.primary;
    final variante = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.sjEstiloComPartidas(partidas, nivel.name),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final n in NivelEstilo.values) ...[
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
                          color: n.index <= nivel.index
                              ? primaria
                              : corDoTrilho ?? AppColors.sheetSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.nivelNome(n),
                      style: n == nivel
                          ? theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            )
                          : variante,
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
