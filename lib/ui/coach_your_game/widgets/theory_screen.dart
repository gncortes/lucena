import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/coach/coach.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/coach_your_game_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/position_board.dart';
import '../view_models/theory_cubit.dart';
import 'your_game_tab.dart' show ModelGamesLink;
import 'your_game_parts.dart';
import 'your_game_texts.dart';
import '../../core/theme/app_text.dart';

/// Onde ele saiu da teoria numa partida e o que mais se joga ali (dados que
/// o servidor guardou; o aparelho não consulta o Lichess).
class YourGameTheoryScreen extends StatelessWidget {
  const YourGameTheoryScreen({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => createTheoryCubit(c, gameId: gameId)..load(),
      child: Scaffold(
        key: YourGameKeys.theoryScreen,
        appBar: LucenaAppBar(
          title: Text(context.l10n.sjTeoriaTitulo),
          centerTitle: true,
        ),
        body: BlocBuilder<TheoryCubit, TheoryState>(
          builder: (context, state) => switch (state.status) {
            TheoryStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            TheoryStatus.error => LoadErrorScreen(
              kind: LoadErrorKind.generic,
              onAction: () => context.read<TheoryCubit>().load(),
            ),
            TheoryStatus.noTheory => EmptyState(
              icon: Icons.menu_book_outlined,
              message: context.l10n.sjTeoriaSem,
            ),
            TheoryStatus.ready => _Theory(state: state),
          },
        ),
      ),
    );
  }
}

/// "8...O-O 9.Ch4 Bg6", a partir do meio-lance [ply].
String numberedLine(AppLocalizations t, int ply, List<String> sans) {
  final parts = <String>[];
  for (final (i, san) in sans.indexed) {
    final p = ply + i;
    parts.add(i == 0 || p.isEven ? t.moveOfPly(p, san) : localizedSan(t, san));
  }
  return parts.join(' ');
}

class _Theory extends StatelessWidget {
  const _Theory({required this.state});

  final TheoryState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final theory = state.theory!;
    final game = state.game!;
    final board = state.board;
    final played = state.played;
    final opening = game.opening;
    final comment = state.candidate == null
        ? (played == null
              ? t.sjTeoriaSaiuSemLance
              : t.sjTeoriaSaiu(t.moveOfPly(theory.chessMove, played)))
        : t.sjTeoriaLinha(numberedLine(t, theory.chessMove, state.line));
    // A navegação fica fixa embaixo (canvas DAnaliseTeoria).
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              LayoutBuilder(
                builder: (context, c) => PositionBoard(
                  boardKey: YourGameKeys.theoryBoard,
                  fen: board.fen,
                  size: c.maxWidth,
                  radius: 0,
                  orientation: game.color == GameColor.white
                      ? Side.white
                      : Side.black,
                  lastMove: board.chessMove,
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
                    _Moves(state: state),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      comment,
                      key: state.candidate == null
                          ? YourGameKeys.theoryComment
                          : YourGameKeys.theoryLine,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    YourGameSection(
                      title: t.sjTeoriaNaTeoria,
                      subtitle: t.sjTeoriaFonte,
                      child: Column(
                        children: [
                          for (final c in theory.candidates)
                            _Candidate(
                              candidate: c,
                              ply: theory.chessMove,
                              chosen: c.san == state.chosen,
                              youPlayed: c.san == played,
                            ),
                          if (played != null &&
                              theory.candidates.every((c) => c.san != played))
                            _YouPlayed(
                              fullMove: t.moveOfPly(theory.chessMove, played),
                            ),
                        ],
                      ),
                    ),
                    if (opening != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      // O mesmo link da aba (componente único).
                      ModelGamesLink(
                        key: YourGameKeys.theoryModelGames,
                        eco: opening.eco,
                        name: opening.name,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(top: false, child: _Navigation(state: state)),
      ],
    );
  }
}

/// Os lances da partida até o dele e, com um lance da teoria tocado, a linha
/// dele entre parênteses (a lista da Análise, canvas DAnaliseTeoria e
/// DAnaliseTeoriaLinha). O marcado é o lance que está no tabuleiro.
class _Moves extends StatelessWidget {
  const _Moves({required this.state});

  final TheoryState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final game = state.game!;
    final ply = state.theory!.chessMove;
    final until = (ply + 1).clamp(0, game.moves.length);
    final line = state.line;
    final inGame = state.markedInGame;
    final inLine = state.markedInLine;
    return Wrap(
      key: YourGameKeys.theoryMoves,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < until; i++)
          _Move(
            text: i == 0 || i.isEven
                ? t.moveOfPly(i, game.moves[i].san)
                : localizedSan(t, game.moves[i].san),
            marked: i == inGame,
          ),
        if (line.isNotEmpty) ...[
          // Parênteses da notação de variante (PGN), não texto de interface.
          const _Move(text: '(', variant: true),
          for (final (i, san) in line.indexed)
            _Move(
              text: i == 0 || (ply + i).isEven
                  ? t.moveOfPly(ply + i, san)
                  : localizedSan(t, san),
              marked: i == inLine,
              variant: true,
            ),
          const _Move(text: ')', variant: true),
        ],
      ],
    );
  }
}

/// Um lance da lista: marcado em azul; os da variante em tom mais apagado.
class _Move extends StatelessWidget {
  const _Move({required this.text, this.marked = false, this.variant = false});

  final String text;
  final bool marked;
  final bool variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: marked ? colors.primary : null,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: marked
              ? colors.onPrimary
              : (variant ? colors.onSurfaceVariant : null),
          fontWeight: marked
              ? FontWeight.w600
              : (variant ? AppWeight.regular : AppWeight.medium),
        ),
      ),
    );
  }
}

/// ⏮ ‹ › ⏭ pela linha do lance tocado; sem lance tocado, › abre a do mais
/// jogado.
class _Navigation extends StatelessWidget {
  const _Navigation({required this.state});

  final TheoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TheoryCubit>();
    final has = state.chosen != null;
    final current = state.currentStep;
    final end = state.line.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            key: YourGameKeys.theoryStart,
            onPressed: has && current > 0 ? () => cubit.goTo(0) : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton.filledTonal(
            key: YourGameKeys.theoryPrevious,
            onPressed: has && current > 0 ? cubit.previous : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton.filledTonal(
            key: YourGameKeys.theoryNext,
            onPressed: !has || current < end ? cubit.next : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            key: YourGameKeys.theoryEnd,
            onPressed: has && current < end ? () => cubit.goTo(end) : null,
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
    );
  }
}

class _Candidate extends StatelessWidget {
  const _Candidate({
    required this.candidate,
    required this.ply,
    required this.chosen,
    required this.youPlayed,
  });

  /// A jogada dele está entre os candidatos: marcada com "Você jogou".
  final bool youPlayed;
  final TheoryCandidate candidate;
  final int ply;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variant = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final c = candidate;
    return Material(
      color: chosen ? theme.colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppShape.small),
      child: InkWell(
        key: YourGameKeys.theoryCandidate(c.san),
        borderRadius: BorderRadius.circular(AppShape.small),
        onTap: () => context.read<TheoryCubit>().pick(c.san),
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
                        t.moveOfPly(ply, c.san),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: AppWeight.medium,
                        ),
                      ),
                      if (youPlayed)
                        Text(
                          t.sjTeoriaVoceJogouCurto,
                          key: YourGameKeys.theoryPlayed,
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
                    NumberFormat.compact(locale: t.localeName).format(c.games),
                    style: variant,
                  ),
                ),
                // Brancas, empates e pretas com o % dentro (canvas
                // DAnaliseTeoria): o azul fica só para "você venceu".
                Expanded(
                  child: ScoreBar(
                    wins: c.white,
                    draws: c.draws,
                    losses: c.black,
                    style: ScoreStyle.colors,
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

class _YouPlayed extends StatelessWidget {
  const _YouPlayed({required this.fullMove});

  final String fullMove;

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
              context.l10n.sjTeoriaVoceJogou(fullMove),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
