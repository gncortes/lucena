import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/attempt_history.dart';
import '../../core/widgets/challenge_tile.dart';
import '../view_models/journey_cubit.dart';
import 'journey_ui.dart';

/// Um desafio: a posição, contra quem, o botão de jogar e as partidas dele
/// agrupadas por mês.
class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<JourneyCubit>().state;
    final challenge = state.challenge;
    return Scaffold(
      key: JourneyKeys.challengeScreen,
      appBar: AppBar(title: Text(l10n.journeyChallengeTitle)),
      body: challenge == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ChallengeTile(
                  position: challenge.position,
                  onTap: null,
                  subtitle: Text(
                    l10n.journeyAgainst(
                      opponentRefLabel(l10n, challenge.opponent),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: FilledButton.icon(
                    key: JourneyKeys.play,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.journeyPlay),
                    onPressed: () async {
                      await context.push(Routes.challengeGame(challenge));
                      if (!context.mounted) return;
                      final uri = GoRouterState.of(context).pathParameters;
                      await context.read<JourneyCubit>().load(
                        rungId: uri['rung'],
                        positionId: uri['position'],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                  child: Text(
                    l10n.setupHistory,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (state.attempts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.journeyHistoryEmpty,
                      key: JourneyKeys.emptyHistory,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  AttemptHistory(
                    attempts: state.attempts,
                    monthKey: JourneyKeys.month,
                    attemptKey: JourneyKeys.attempt,
                  ),
              ],
            ),
    );
  }
}
