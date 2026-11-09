import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/treinador/treinador_repository.dart';
import '../../../domain/models/treinador/treinador.dart';
import '../../../routing/frentes/treinador_seu_jogo_routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/treinador_seu_jogo_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/position_board.dart';
import '../view_models/teoria_cubit.dart';
import 'seu_jogo_pecas.dart';
import 'seu_jogo_textos.dart';

/// Onde ele saiu da teoria numa partida e o que a teoria joga ali (dados que
/// o servidor guardou; o aparelho não consulta o Lichess).
class SeuJogoTeoriaScreen extends StatelessWidget {
  const SeuJogoTeoriaScreen({required this.partidaId, super.key});

  final String partidaId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => TeoriaCubit(
        repository: c.read<TreinadorRepository>(),
        partidaId: partidaId,
      )..load(),
      child: Scaffold(
        key: SeuJogoKeys.teoriaScreen,
        appBar: LucenaAppBar(
          title: Text(context.l10n.sjTeoriaTitulo),
          centerTitle: true,
        ),
        body: BlocBuilder<TeoriaCubit, TeoriaState>(
          builder: (context, state) => switch (state.status) {
            TeoriaStatus.carregando => const Center(
              child: CircularProgressIndicator(),
            ),
            TeoriaStatus.erro => LoadErrorScreen(
              kind: LoadErrorKind.generic,
              onAction: () => context.read<TeoriaCubit>().load(),
            ),
            TeoriaStatus.semTeoria => EmptyState(
              icon: Icons.menu_book_outlined,
              message: context.l10n.sjTeoriaSem,
            ),
            TeoriaStatus.pronta => _Teoria(state: state),
          },
        ),
      ),
    );
  }
}

/// "8...O-O 9.Ch4 Bg6", a partir do meio-lance [ply].
String linhaNumerada(AppLocalizations t, int ply, List<String> sans) {
  final partes = <String>[];
  for (final (i, san) in sans.indexed) {
    final p = ply + i;
    partes.add(
      i == 0 || p.isEven ? t.jogadaDoPly(p, san) : localizedSan(t, san),
    );
  }
  return partes.join(' ');
}

class _Teoria extends StatelessWidget {
  const _Teoria({required this.state});

  final TeoriaState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final teoria = state.teoria!;
    final partida = state.partida!;
    final tabuleiro = state.tabuleiro;
    final jogado = state.jogado;
    final abertura = partida.abertura;
    final comentario = state.candidato == null
        ? (jogado == null
              ? t.sjTeoriaSaiuSemLance
              : t.sjTeoriaSaiu(t.jogadaDoPly(teoria.lance, jogado)))
        : t.sjTeoriaLinha(linhaNumerada(t, teoria.lance, state.linha));
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        LayoutBuilder(
          builder: (context, c) => PositionBoard(
            boardKey: SeuJogoKeys.teoriaTabuleiro,
            fen: tabuleiro.fen,
            size: c.maxWidth,
            radius: 0,
            orientation: partida.cor == CorPartida.brancas
                ? Side.white
                : Side.black,
            lastMove: tabuleiro.lance,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                comentario,
                key: state.candidato == null
                    ? SeuJogoKeys.teoriaComentario
                    : SeuJogoKeys.teoriaLinha,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              SecaoSeuJogo(
                titulo: t.sjTeoriaNaTeoria,
                subtitulo: t.sjTeoriaFonte,
                child: Column(
                  children: [
                    for (final c in teoria.candidatos)
                      _Candidato(
                        candidato: c,
                        ply: teoria.lance,
                        escolhido: c.san == state.escolhido,
                      ),
                    if (jogado != null &&
                        teoria.candidatos.every((c) => c.san != jogado))
                      _VoceJogou(jogada: t.jogadaDoPly(teoria.lance, jogado)),
                  ],
                ),
              ),
              if (abertura != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  key: SeuJogoKeys.teoriaModelos,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.emoji_events_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(t.sjModelosDe(abertura.nome)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    SeuJogoPaths.modelosDe(abertura.eco, nome: abertura.nome),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Candidato extends StatelessWidget {
  const _Candidato({
    required this.candidato,
    required this.ply,
    required this.escolhido,
  });

  final CandidatoTeoria candidato;
  final int ply;
  final bool escolhido;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variante = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final c = candidato;
    return Material(
      color: escolhido
          ? theme.colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppShape.small),
      child: InkWell(
        key: SeuJogoKeys.teoriaCandidato(c.san),
        borderRadius: BorderRadius.circular(AppShape.small),
        onTap: () => context.read<TeoriaCubit>().escolher(c.san),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    t.jogadaDoPly(ply, c.san),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    NumberFormat.compact(locale: t.localeName)
                        .format(c.partidas),
                    style: variante,
                  ),
                ),
                Text(t.sjPorcento(c.brancas), style: variante),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: BarraDoPlacar(
                    vitorias: c.brancas,
                    empates: c.empates,
                    derrotas: c.pretas,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(t.sjPorcento(c.pretas), style: variante),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoceJogou extends StatelessWidget {
  const _VoceJogou({required this.jogada});

  final String jogada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: AppIconSize.compact,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.sjTeoriaVoceJogou(jogada),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
