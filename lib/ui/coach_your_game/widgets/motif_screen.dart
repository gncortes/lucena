import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/coach/your_game_summary.dart';
import '../../../domain/use_cases/coach/coach_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/coach_your_game_keys.dart';
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
import '../view_models/your_game_cubit.dart';
import 'your_game_texts.dart';
import '../../core/theme/app_text.dart';

/// As posições de um tema em que ele errou, da mais recente.
class YourGameMotifScreen extends StatelessWidget {
  const YourGameMotifScreen({required this.motif, super.key});

  final String motif;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocProvider(
      create: (c) => createYourGameCubit(c)..load(),
      child: Scaffold(
        key: YourGameKeys.motifScreen,
        appBar: LucenaAppBar(
          title: Text(t.motifName(motif)),
          centerTitle: true,
        ),
        body: BlocBuilder<YourGameCubit, YourGameState>(
          builder: (context, state) {
            final summary = state.summary;
            final ofMotif = summary?.motifs
                .where((r) => r.motif == motif)
                .firstOrNull;
            return switch (state.status) {
              YourGameStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              YourGameStatus.error => LoadErrorScreen(
                kind: LoadErrorKind.generic,
                onAction: () => context.read<YourGameCubit>().load(),
              ),
              YourGameStatus.ready when ofMotif == null || summary == null =>
                EmptyState(
                  icon: Icons.extension_outlined,
                  message: t.sjTemaSem,
                ),
              YourGameStatus.ready => _List(
                motif: ofMotif!,
                games: summary!.games,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.motif, required this.games});

  final MotifSummary motif;
  final int games;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variant = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final description = t.sjTemaDescricao(motif.motif);
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
              if (description.isNotEmpty) ...[
                Text(description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                t.sjTemaContagem(motif.positions.length, games),
                style: variant,
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
        for (final (i, p) in motif.positions.indexed)
          _Position(index: i, pos: p),
      ],
    );
  }
}

Side _side(CoachGame p) => p.color == GameColor.white ? Side.white : Side.black;

class _Position extends StatelessWidget {
  const _Position({required this.index, required this.pos});

  final int index;
  final MotifPositionView pos;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final game = pos.game;
    final detail = [
      t.shortDate(game.moveAt, context.read<Now>()),
      if (game.timeControl != null) t.timeControlName(game.timeControl),
      t.colorName(game.color),
    ].join(' · ');
    return InkWell(
      key: YourGameKeys.motifPosition(index),
      borderRadius: BorderRadius.circular(AppShape.small),
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            PositionBoard(
              fen: pos.position.fen,
              size: 56,
              orientation: _side(game),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.sjTemaLance(pos.position.chessMove, game.opponent.name),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: AppWeight.medium,
                    ),
                  ),
                  Text(
                    detail,
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
  Future<void> _open(BuildContext context) => pos.game.ready
      ? context.push(
          Routes.coachAnalysis(
            pos.game.id,
            ply: CoachRules.halfMove(
              pos.position.chessMove,
              white: pos.game.color == GameColor.white,
            ),
          ),
        )
      : showLucenaSheet<void>(context, builder: (sheet) => _Sheet(pos: pos));
}

/// A posição grande e o link para a partida no site.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.pos});

  final MotifPositionView pos;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final game = pos.game;
    final url = game.url == null ? null : Uri.tryParse(game.url!);
    // O erro é dele: meio-lance das brancas ou das pretas no lance N.
    final ply =
        (pos.position.chessMove - 1) * 2 +
        (game.color == GameColor.black ? 1 : 0);
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
            t.sjTemaLance(pos.position.chessMove, game.opponent.name),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: AppWeight.medium),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, c) => PositionBoard(
              fen: pos.position.fen,
              size: c.maxWidth,
              orientation: _side(game),
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
