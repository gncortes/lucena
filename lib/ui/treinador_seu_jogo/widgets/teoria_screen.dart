import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/treinador/treinador.dart';
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
import 'seu_jogo_aba.dart' show LinkModelos;
import 'seu_jogo_pecas.dart';
import 'seu_jogo_textos.dart';
import '../../core/theme/app_text.dart';

/// Onde ele saiu da teoria numa partida e o que mais se joga ali (dados que
/// o servidor guardou; o aparelho não consulta o Lichess).
class SeuJogoTeoriaScreen extends StatelessWidget {
  const SeuJogoTeoriaScreen({required this.partidaId, super.key});

  final String partidaId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => createTheoryCubit(c, partidaId: partidaId)..load(),
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
    // A navegação fica fixa embaixo (canvas DAnaliseTeoria).
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                  coordinates: true,
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
                    _Lances(state: state),
                    const SizedBox(height: AppSpacing.md),
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
                              jogou: c.san == jogado,
                            ),
                          if (jogado != null &&
                              teoria.candidatos.every((c) => c.san != jogado))
                            _VoceJogou(
                              jogada: t.jogadaDoPly(teoria.lance, jogado),
                            ),
                        ],
                      ),
                    ),
                    if (abertura != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      // O mesmo link da aba (componente único).
                      LinkModelos(
                        key: SeuJogoKeys.teoriaModelos,
                        eco: abertura.eco,
                        nome: abertura.nome,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(top: false, child: _Navegacao(state: state)),
      ],
    );
  }
}

/// Os lances da partida até o dele e, com um lance da teoria tocado, a linha
/// dele entre parênteses (a lista da Análise, canvas DAnaliseTeoria e
/// DAnaliseTeoriaLinha). O marcado é o lance que está no tabuleiro.
class _Lances extends StatelessWidget {
  const _Lances({required this.state});

  final TeoriaState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final partida = state.partida!;
    final ply = state.teoria!.lance;
    final ate = (ply + 1).clamp(0, partida.lances.length);
    final linha = state.linha;
    final naPartida = state.marcadoNaPartida;
    final naLinha = state.marcadoNaLinha;
    return Wrap(
      key: SeuJogoKeys.teoriaLances,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < ate; i++)
          _Lance(
            texto: i == 0 || i.isEven
                ? t.jogadaDoPly(i, partida.lances[i].san)
                : localizedSan(t, partida.lances[i].san),
            marcado: i == naPartida,
          ),
        if (linha.isNotEmpty) ...[
          // Parênteses da notação de variante (PGN), não texto de interface.
          const _Lance(texto: '(', variante: true),
          for (final (i, san) in linha.indexed)
            _Lance(
              texto: i == 0 || (ply + i).isEven
                  ? t.jogadaDoPly(ply + i, san)
                  : localizedSan(t, san),
              marcado: i == naLinha,
              variante: true,
            ),
          const _Lance(texto: ')', variante: true),
        ],
      ],
    );
  }
}

/// Um lance da lista: marcado em azul; os da variante em tom mais apagado.
class _Lance extends StatelessWidget {
  const _Lance({
    required this.texto,
    this.marcado = false,
    this.variante = false,
  });

  final String texto;
  final bool marcado;
  final bool variante;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cores = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: marcado ? cores.primary : null,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: Text(
        texto,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: marcado
              ? cores.onPrimary
              : (variante ? cores.onSurfaceVariant : null),
          fontWeight: marcado
              ? FontWeight.w600
              : (variante ? AppWeight.regular : AppWeight.medium),
        ),
      ),
    );
  }
}

/// ⏮ ‹ › ⏭ pela linha do lance tocado; sem lance tocado, › abre a do mais
/// jogado.
class _Navegacao extends StatelessWidget {
  const _Navegacao({required this.state});

  final TeoriaState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TeoriaCubit>();
    final tem = state.escolhido != null;
    final atual = state.passoAtual;
    final fim = state.linha.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            key: SeuJogoKeys.teoriaInicio,
            onPressed: tem && atual > 0 ? () => cubit.irPara(0) : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton.filledTonal(
            key: SeuJogoKeys.teoriaAnterior,
            onPressed: tem && atual > 0 ? cubit.anterior : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton.filledTonal(
            key: SeuJogoKeys.teoriaProximo,
            onPressed: !tem || atual < fim ? cubit.proximo : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            key: SeuJogoKeys.teoriaFim,
            onPressed: tem && atual < fim ? () => cubit.irPara(fim) : null,
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
    );
  }
}

class _Candidato extends StatelessWidget {
  const _Candidato({
    required this.candidato,
    required this.ply,
    required this.escolhido,
    required this.jogou,
  });

  /// A jogada dele está entre os candidatos: marcada com "Você jogou".
  final bool jogou;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.jogadaDoPly(ply, c.san),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: AppWeight.medium,
                        ),
                      ),
                      if (jogou)
                        Text(
                          t.sjTeoriaVoceJogouCurto,
                          key: SeuJogoKeys.teoriaJogou,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: AppWeight.medium,
                          ),
                        ),
                    ],
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
                // Brancas, empates e pretas com o % dentro (canvas
                // DAnaliseTeoria): o azul fica só para "você venceu".
                Expanded(
                  child: BarraDoPlacar(
                    vitorias: c.brancas,
                    empates: c.empates,
                    derrotas: c.pretas,
                    estilo: EstiloPlacar.cores,
                  ),
                ),
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
