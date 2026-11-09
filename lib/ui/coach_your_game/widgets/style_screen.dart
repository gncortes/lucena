import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../routing/frentes/coach_your_game_routes.dart';
import '../../core/keys/coach_your_game_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/your_game_cubit.dart';
import 'your_game_parts.dart';
import 'your_game_texts.dart';
import '../../core/theme/app_text.dart';

/// A leitura do estilo que o servidor faz: o resumo, a confiança e os pontos
/// fortes e a melhorar.
class YourGameStyleScreen extends StatelessWidget {
  const YourGameStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => createYourGameCubit(c)..load(),
      child: Scaffold(
        key: YourGameKeys.styleScreen,
        appBar: LucenaAppBar(
          title: Text(context.l10n.sjEstiloTitulo),
          centerTitle: true,
        ),
        body: BlocBuilder<YourGameCubit, YourGameState>(
          builder: (context, state) => switch (state.status) {
            YourGameStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            YourGameStatus.error => LoadErrorScreen(
              kind: LoadErrorKind.generic,
              onAction: () => context.read<YourGameCubit>().load(),
            ),
            YourGameStatus.ready => _Style(state: state),
          },
        ),
      ),
    );
  }
}

class _Style extends StatelessWidget {
  const _Style({required this.state});

  final YourGameState state;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final style = state.stats.style;
    final games = state.stats.analyzedGames > 0
        ? state.stats.analyzedGames
        : state.games.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(t.styleSummary(style), style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        _Confidence(level: style.level, games: games),
        if (style.strengths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          YourGameSection(
            title: t.sjEstiloFortes,
            child: Column(
              children: [
                for (final (i, p) in style.strengths.indexed)
                  _Point(
                    key: YourGameKeys.styleStrong(i),
                    point: p,
                    firstOne: i == 0,
                  ),
              ],
            ),
          ),
        ],
        if (style.solve.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          YourGameSection(
            title: t.sjEstiloAcertar,
            child: Column(
              children: [
                for (final (i, p) in style.solve.indexed)
                  _Point(
                    key: YourGameKeys.styleSolve(i),
                    point: p,
                    firstOne: i == 0,
                    action: p.motif == null
                        ? null
                        : (
                            key: YourGameKeys.styleSeePositions(i),
                            destination: YourGamePaths.motifOf(p.motif!),
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
class _Confidence extends StatelessWidget {
  const _Confidence({required this.level, required this.games});

  final StyleLevel level;
  final int games;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variant = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final missing = switch (level) {
      StyleLevel.first => 20 - games,
      StyleLevel.forming => 50 - games,
      StyleLevel.solid => 0,
    };
    return KeyedSubtree(
      key: YourGameKeys.styleConfidence,
      child: LucenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConfidenceMeter(level: level, games: games),
            const SizedBox(height: AppSpacing.md),
            Text(
              missing > 0 ? t.sjEstiloFalta(missing) : t.sjEstiloRefeita,
              style: variant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.point,
    required this.firstOne,
    this.action,
    super.key,
  });

  final StylePoint point;
  final bool firstOne;
  final ({Key key, String destination})? action;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!firstOne) const Divider(height: AppSpacing.lg),
        Text(
          point.text,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: AppWeight.medium,
          ),
        ),
        if (point.games case final n?)
          Text(
            t.sjEstiloEmPartidas(n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (action case final a?)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: a.key,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, kButtonHeightCompact),
              ),
              onPressed: () => context.push(a.destination),
              child: Text(t.sjVerPosicoes),
            ),
          ),
      ],
    );
  }
}
