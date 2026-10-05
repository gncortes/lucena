import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/journey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../view_models/journey_cubit.dart';
import 'journey_ui.dart';

/// A Jornada: onde o jogador está, o próximo degrau e todos os degraus, com o
/// que já foi concluído em cada um.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = context.select(
      (JourneyCubit cubit) => cubit.state.progress,
    );
    return Scaffold(
      key: JourneyKeys.screen,
      appBar: AppBar(title: Text(l10n.journeyTitle)),
      body: progress == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Summary(progress: progress),
                for (final rung in progress.rungs)
                  _RungTile(rung: rung, progress: progress),
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.progress});

  final JourneyProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final current = progress.current;
    final next = progress.next;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              current == null
                  ? l10n.journeyFinished
                  : l10n.journeyCurrent(
                      opponentRefLabel(l10n, current.rung.opponent),
                    ),
              key: JourneyKeys.current,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (current != null)
              Text(
                l10n.journeyRungProgress(
                  current.completed.length,
                  current.rung.challenges.length,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            if (next != null)
              Text(
                l10n.journeyNext(opponentRefLabel(l10n, next.rung.opponent)),
                key: JourneyKeys.next,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RungTile extends StatelessWidget {
  const _RungTile({required this.rung, required this.progress});

  final RungProgress rung;
  final JourneyProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final id = rung.rung.id;
    final locked = rung.status == RungStatus.locked;
    final character = context.select(
      (JourneyCubit cubit) =>
          cubit.state.characters.forLevel(rung.rung.opponent.level),
    );
    final status = switch (rung.status) {
      RungStatus.locked => Icon(
        Icons.lock_outline,
        key: JourneyKeys.rungLocked(id),
        color: colors.outline,
        semanticLabel: l10n.journeyLockedLabel,
      ),
      RungStatus.completed => Icon(
        Icons.check_circle,
        key: JourneyKeys.rungCompleted(id),
        color: colors.primary,
        semanticLabel: l10n.journeyCompletedLabel,
      ),
      RungStatus.open => Icon(Icons.flag_outlined, color: colors.primary),
    };
    return ListTile(
      key: JourneyKeys.rung(id),
      leading: character == null
          ? SizedBox.square(dimension: 44, child: Center(child: status))
          : Opacity(
              opacity: locked ? 0.45 : 1,
              child: CharacterAvatar(character: character),
            ),
      title: Text(
        character == null
            ? opponentRefLabel(l10n, rung.rung.opponent)
            : l10n.characterNameLevel(character.name, character.level),
      ),
      subtitle: Text(
        l10n.journeyRungProgress(
          rung.completed.length,
          rung.rung.challenges.length,
        ),
      ),
      textColor: locked ? colors.outline : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (character != null) status,
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () async {
        if (!locked) {
          await context.push(Routes.journeyRung(id));
          // Ao voltar, um degrau pode ter sido concluído.
          if (context.mounted) await context.read<JourneyCubit>().load();
          return;
        }
        // Trancado: diz o que falta no degrau anterior.
        final before = progress.before(id);
        if (before == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.journeyLocked(
                  before.remaining,
                  opponentRefLabel(l10n, before.rung.opponent),
                ),
                key: JourneyKeys.lockedMessage,
              ),
            ),
          );
      },
    );
  }
}
