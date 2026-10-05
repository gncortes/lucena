import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/journey.dart';
import '../../../routing/routes.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/challenge_tile.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/journey_cubit.dart';
import 'journey_ui.dart';
import '../../core/widgets/scroll_padding.dart';

/// Os desafios de um degrau, com a marca de concluído.
class RungScreen extends StatelessWidget {
  const RungScreen({required this.rungId, super.key});

  final String rungId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final progress = context.select(
      (JourneyCubit cubit) => cubit.state.progress,
    );
    final rung = progress?.rung(rungId);
    final reunion = context.select((JourneyCubit cubit) => cubit.state.reunion);
    final characters = context.select(
      (JourneyCubit cubit) => cubit.state.characters,
    );
    final teacher = [
      for (final character in characters)
        if (character.id == 'master' &&
            character.level == rung?.rung.opponent.level)
          character,
    ].firstOrNull;
    return Scaffold(
      key: JourneyKeys.rungScreen,
      appBar: AppBar(
        title: Text(
          rung == null ? '' : opponentRefLabel(l10n, rung.rung.opponent),
        ),
      ),
      body: rung == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: scrollPadding(context),
              children: [
                if (teacher != null && reunion != null)
                  Card(
                    key: JourneyKeys.reunion,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    color: colors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rungReunionTitle(teacher.name),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TeacherSpeech(teacher: teacher, text: reunion),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.journeyRungProgress(
                      rung.completed.length,
                      rung.rung.challenges.length,
                    ),
                  ),
                ),
                for (final challenge in rung.rung.challenges)
                  _tile(context, rung, challenge, colors),
              ],
            ),
    );
  }

  Widget _tile(
    BuildContext context,
    RungProgress rung,
    Challenge challenge,
    ColorScheme colors,
  ) {
    final position = challenge.position.id;
    final done = rung.completed.contains(challenge.id);
    return ChallengeTile(
      key: JourneyKeys.challenge(position),
      position: challenge.position,
      onTap: () async {
        await context.push(Routes.journeyChallenge(rungId, position));
        // Ao voltar, o desafio pode ter sido concluído.
        if (context.mounted) await context.read<JourneyCubit>().load();
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            Icon(
              Icons.check_circle,
              key: JourneyKeys.challengeDone(position),
              color: colors.primary,
              semanticLabel: context.l10n.journeyCompletedLabel,
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
