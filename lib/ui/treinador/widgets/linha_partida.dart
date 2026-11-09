import 'package:flutter/material.dart';

import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';
import '../../core/keys/treinador_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import 'treinador_textos.dart';

/// Uma partida nas listas do Treinador (Hoje, Partidas e o início): o
/// quadrado do resultado, o adversário, ritmo · cor · quando e o estado.
class LinhaPartida extends StatelessWidget {
  const LinhaPartida({
    required this.partida,
    required this.agora,
    required this.acesso,
    this.onTap,
    super.key,
  });

  final PartidaTreinador partida;
  final DateTime agora;
  final bool acesso;
  final VoidCallback? onTap;

  static const minHeight = 64.0;
  static const quadrado = 36.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final p = partida;
    final aberta = TreinadorRegras.abre(p, acesso: acesso);
    final adversario = p.adversario.rating == null
        ? p.adversario.nome
        : '${p.adversario.nome} (${p.adversario.rating})';
    final detalhe = [
      if (p.ritmo != null)
        [?p.cadencia, context.ritmo(p.ritmo!)].join(' ')
      else
        ?p.cadencia,
      context.cor(p.cor),
      ?p.abertura?.nome,
      context.quando(p.jogadaEm, agora),
    ].join(' · ');
    final muted = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0,
      color: colors.onSurfaceVariant,
    );
    return InkWell(
      key: TreinadorKeys.partida(p.id),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              _Resultado(resultado: p.resultado),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            adversario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (p.status == StatusPartida.nova) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      detalhe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                    _Estado(partida: p, aberta: aberta, style: muted),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.resultado});

  final Resultado resultado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (fundo, frente) = switch (resultado) {
      Resultado.vitoria => (
        AppColors.trainingDayCorrect,
        AppColors.chessWhiteColor,
      ),
      Resultado.derrota => (
        AppColors.trainingDayWrong,
        AppColors.chessWhiteColor,
      ),
      Resultado.empate => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    return Semantics(
      label: context.resultado(resultado),
      excludeSemantics: true,
      child: Container(
        width: LinhaPartida.quadrado,
        height: LinhaPartida.quadrado,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(AppShape.small),
        ),
        child: Text(
          context.letraDoResultado(resultado),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: frente,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({
    required this.partida,
    required this.aberta,
    required this.style,
  });

  final PartidaTreinador partida;
  final bool aberta;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = partida;
    final colors = Theme.of(context).colorScheme;
    final total = p.exercicios.length;
    final progresso = p.progresso ?? ProgressoPartida.vazio;
    final (texto, cor) = !aberta
        ? (l.treinadorEstadoBloqueada, colors.onSurfaceVariant)
        : switch (p.status) {
            StatusPartida.nova => (l.treinadorEstadoNova, colors.primary),
            StatusPartida.naFila || StatusPartida.analisando => (
              l.treinadorEstadoAnalisando,
              colors.primary,
            ),
            StatusPartida.erro => (l.treinadorEstadoErro, colors.error),
            StatusPartida.pronta when total == 0 => (
              l.treinadorEstadoSemExercicios,
              colors.onSurfaceVariant,
            ),
            StatusPartida.pronta when progresso.completo(total) => (
              l.treinadorEstadoCompleta(progresso.acertos, total),
              colors.onSurfaceVariant,
            ),
            StatusPartida.pronta => (
              l.treinadorEstadoExercicios(progresso.feitos, total),
              colors.primary,
            ),
          };
    final linha = Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(color: cor),
    );
    if (aberta) return linha;
    return Row(
      children: [
        Icon(Icons.lock_outline, size: AppIconSize.small, color: cor),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: linha),
      ],
    );
  }
}
