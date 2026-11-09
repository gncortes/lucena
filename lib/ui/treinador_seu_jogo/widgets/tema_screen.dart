import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/resumo_seu_jogo.dart';
import '../../../domain/use_cases/treinador/treinador_regras.dart';
import '../../../routing/routes.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/open_link.dart';
import '../../core/widgets/position_board.dart';
import '../view_models/seu_jogo_cubit.dart';
import 'seu_jogo_textos.dart';
import '../../core/theme/app_text.dart';

/// As posições de um tema em que ele errou, da mais recente.
class SeuJogoTemaScreen extends StatelessWidget {
  const SeuJogoTemaScreen({required this.tema, super.key});

  final String tema;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocProvider(
      create: (c) => createYourGameCubit(c)..load(),
      child: Scaffold(
        key: SeuJogoKeys.temaScreen,
        appBar: LucenaAppBar(title: Text(t.temaNome(tema)), centerTitle: true),
        body: BlocBuilder<SeuJogoCubit, SeuJogoState>(
          builder: (context, state) {
            final resumo = state.resumo;
            final doTema = resumo?.temas
                .where((r) => r.tema == tema)
                .firstOrNull;
            return switch (state.status) {
              SeuJogoStatus.carregando => const Center(
                child: CircularProgressIndicator(),
              ),
              SeuJogoStatus.erro => LoadErrorScreen(
                kind: LoadErrorKind.generic,
                onAction: () => context.read<SeuJogoCubit>().load(),
              ),
              SeuJogoStatus.pronto when doTema == null || resumo == null =>
                EmptyState(
                  icon: Icons.extension_outlined,
                  message: t.sjTemaSem,
                ),
              SeuJogoStatus.pronto => _Lista(
                tema: doTema!,
                partidas: resumo!.partidas,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.tema, required this.partidas});

  final ResumoTema tema;
  final int partidas;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variante = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final descricao = t.sjTemaDescricao(tema.tema);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        LucenaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (descricao.isNotEmpty) ...[
                Text(descricao, style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                t.sjTemaContagem(tema.posicoes.length, partidas),
                style: variante,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          t.sjTemaDaRecente,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (i, p) in tema.posicoes.indexed) _Posicao(indice: i, pos: p),
      ],
    );
  }
}

Side _lado(PartidaTreinador p) =>
    p.cor == CorPartida.brancas ? Side.white : Side.black;

class _Posicao extends StatelessWidget {
  const _Posicao({required this.indice, required this.pos});

  final int indice;
  final PosicaoDoTema pos;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final partida = pos.partida;
    final detalhe = [
      t.dataCurta(partida.jogadaEm, context.read<Now>()),
      if (partida.ritmo != null) t.ritmoNome(partida.ritmo),
      t.corNome(partida.cor),
    ].join(' · ');
    return InkWell(
      key: SeuJogoKeys.temaPosicao(indice),
      borderRadius: BorderRadius.circular(AppShape.small),
      onTap: () => _abrir(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            PositionBoard(
              fen: pos.posicao.fen,
              size: 56,
              orientation: _lado(partida),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.sjTemaLance(pos.posicao.lance, partida.adversario.nome),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: AppWeight.medium,
                    ),
                  ),
                  Text(
                    detalhe,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: AppIconSize.button,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // Partida analisada: abre a análise no lance (como no canvas, SeuJogoTema →
  // AnaliseL32). Sem análise pronta, fica a folha com a posição e o site.
  Future<void> _abrir(BuildContext context) => pos.partida.pronta
      ? context.push(
          Routes.treinadorAnalise(
            pos.partida.id,
            lance: TreinadorRegras.meioLance(
              pos.posicao.lance,
              brancas: pos.partida.cor == CorPartida.brancas,
            ),
          ),
        )
      : showLucenaSheet<void>(context, builder: (sheet) => _Folha(pos: pos));
}

/// A posição grande e o link para a partida no site.
class _Folha extends StatelessWidget {
  const _Folha({required this.pos});

  final PosicaoDoTema pos;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final partida = pos.partida;
    final url = partida.url == null ? null : Uri.tryParse(partida.url!);
    // O erro é dele: meio-lance das brancas ou das pretas no lance N.
    final ply =
        (pos.posicao.lance - 1) * 2 +
        (partida.cor == CorPartida.pretas ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.sjTemaLance(pos.posicao.lance, partida.adversario.nome),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: AppWeight.medium),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, c) => PositionBoard(
              fen: pos.posicao.fen,
              size: c.maxWidth,
              orientation: _lado(partida),
            ),
          ),
          if (url != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kButtonHeight),
              ),
              // No Lichess, `#N` abre a partida na posição do lance.
              onPressed: () => openLink(
                context,
                url.host.endsWith('lichess.org')
                    ? url.replace(fragment: '${ply + 1}')
                    : url,
              ),
              icon: const Icon(Icons.open_in_new, size: AppIconSize.button),
              label: Text(t.sjTemaAbrirPartida),
            ),
          ],
        ],
      ),
    );
  }
}
