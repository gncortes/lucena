import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/treinador/treinador.dart';
import '../../../routing/frentes/treinador_seu_jogo_routes.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/seu_jogo_cubit.dart';
import 'seu_jogo_aba.dart';
import 'seu_jogo_pecas.dart';
import 'seu_jogo_textos.dart';

/// A leitura do estilo que o servidor faz: o resumo, a confiança e os pontos
/// fortes e a melhorar.
class SeuJogoEstiloScreen extends StatelessWidget {
  const SeuJogoEstiloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => criarSeuJogoCubit(c)..load(),
      child: Scaffold(
        key: SeuJogoKeys.estiloScreen,
        appBar: LucenaAppBar(
          title: Text(context.l10n.sjEstiloTitulo),
          centerTitle: true,
        ),
        body: BlocBuilder<SeuJogoCubit, SeuJogoState>(
          builder: (context, state) => switch (state.status) {
            SeuJogoStatus.carregando => const Center(
              child: CircularProgressIndicator(),
            ),
            SeuJogoStatus.erro => LoadErrorScreen(
              kind: LoadErrorKind.generic,
              onAction: () => context.read<SeuJogoCubit>().load(),
            ),
            SeuJogoStatus.pronto => _Estilo(state: state),
          },
        ),
      ),
    );
  }
}

class _Estilo extends StatelessWidget {
  const _Estilo({required this.state});

  final SeuJogoState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final estilo = state.estatisticas.estilo;
    final partidas = state.estatisticas.partidasAnalisadas > 0
        ? state.estatisticas.partidasAnalisadas
        : state.partidas.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(t.estiloResumo(estilo), style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        _Confianca(nivel: estilo.nivel, partidas: partidas),
        if (estilo.fortes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SecaoSeuJogo(
            titulo: t.sjEstiloFortes,
            child: Column(
              children: [
                for (final (i, p) in estilo.fortes.indexed)
                  _Ponto(
                    key: SeuJogoKeys.estiloForte(i),
                    ponto: p,
                    primeiro: i == 0,
                  ),
              ],
            ),
          ),
        ],
        if (estilo.acertar.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SecaoSeuJogo(
            titulo: t.sjEstiloAcertar,
            child: Column(
              children: [
                for (final (i, p) in estilo.acertar.indexed)
                  _Ponto(
                    key: SeuJogoKeys.estiloAcertar(i),
                    ponto: p,
                    primeiro: i == 0,
                    acao: p.tema == null
                        ? null
                        : (
                            key: SeuJogoKeys.estiloVerPosicoes(i),
                            destino: SeuJogoPaths.temaDe(p.tema!),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Com 60 partidas: leitura firme", os três degraus e a nota de baixo.
class _Confianca extends StatelessWidget {
  const _Confianca({required this.nivel, required this.partidas});

  final NivelEstilo nivel;
  final int partidas;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final primaria = theme.colorScheme.primary;
    final variante = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final falta = switch (nivel) {
      NivelEstilo.primeira => 20 - partidas,
      NivelEstilo.formacao => 50 - partidas,
      NivelEstilo.firme => 0,
    };
    return DecoratedBox(
      key: SeuJogoKeys.estiloConfianca,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                          child: SizedBox(
                            height: 6,
                            child: ColoredBox(
                              color: n.index <= nivel.index
                                  ? primaria
                                  : AppColors.sheetSurface,
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
            const SizedBox(height: AppSpacing.md),
            Text(
              falta > 0 ? t.sjEstiloFalta(falta) : t.sjEstiloRefeita,
              style: variante,
            ),
          ],
        ),
      ),
    );
  }
}

class _Ponto extends StatelessWidget {
  const _Ponto({
    required this.ponto,
    required this.primeiro,
    this.acao,
    super.key,
  });

  final PontoEstilo ponto;
  final bool primeiro;
  final ({Key key, String destino})? acao;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!primeiro) const Divider(height: AppSpacing.lg),
        Text(
          ponto.texto,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (ponto.partidas case final n?)
          Text(
            t.sjEstiloEmPartidas(n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (acao case final a?)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: a.key,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
              ),
              onPressed: () => context.push(a.destino),
              child: Text(t.sjVerPosicoes),
            ),
          ),
      ],
    );
  }
}
