import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/race.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/race_cubit.dart';
import 'race_ui.dart';

/// A abertura da Corrida: o que é, a duração (3 ou 5 min), as regras, o filtro
/// de finais, o recorde da duração escolhida e o "Começar".
class RaceIntroView extends StatelessWidget {
  const RaceIntroView({required this.state, super.key});

  final RaceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RaceCubit>();
    if (state.problems.isEmpty) {
      return Center(
        key: RaceKeys.introView,
        child: EmptyState(
          key: RaceKeys.empty,
          icon: Icons.extension,
          message: '${l10n.raceEmptyTitle}\n${l10n.raceEmptyBody}',
        ),
      );
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final themes = state.themes;
    return Column(
      key: RaceKeys.introView,
      children: [
        Expanded(
          child: ListView(
            padding: scrollPadding(
              context,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
            ),
            children: [
              Row(
                spacing: AppSpacing.lg,
                children: [
                  ExcludeSemantics(
                    child: PositionBoard(
                      fen: state.problems.first.fen,
                      size: 112,
                      radius: AppShape.small,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.raceIntroSubtitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.raceIntroBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Duração em seção própria, acima das regras (E1.33, opção B).
              SectionTitle(l10n.raceDuration, inset: 0),
              SegmentedButton<RaceDuration>(
                key: RaceKeys.duration,
                showSelectedIcon: false,
                segments: [
                  for (final option in RaceDuration.values)
                    ButtonSegment(
                      value: option,
                      label: OneLine(
                        l10n.raceDurationMinutes(option.minutes),
                        key: RaceKeys.durationOption(option),
                      ),
                    ),
                ],
                selected: {state.duration},
                onSelectionChanged: (selection) =>
                    unawaited(cubit.selectDuration(selection.single)),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Rule(
                icon: Icons.timer,
                title: l10n.raceRuleTimeTitle(state.duration.minutes),
                body: l10n.raceRuleTimeBody,
              ),
              _Rule(
                icon: Icons.trending_up,
                title: l10n.raceRuleHarderTitle,
                body: l10n.raceRuleHarderBody,
              ),
              _Rule(
                icon: Icons.close,
                title: l10n.raceRuleErrorsTitle,
                body: l10n.raceRuleErrorsBody,
              ),
              _Rule(
                icon: Icons.bolt,
                title: l10n.raceRuleShortestTitle,
                body: l10n.raceRuleShortestBody,
              ),
              if (themes.length > 1) ...[
                SectionTitle(l10n.raceWhichEndings, inset: 0),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in <RaceTheme?>[null, ...themes])
                      ChoiceChip(
                        key: RaceKeys.themeChip(option),
                        label: Text(
                          option?.label(context) ?? l10n.raceThemeAll,
                        ),
                        selected: state.theme == option,
                        onSelected: (_) => unawaited(cubit.selectTheme(option)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _RecordCard(record: state.record, duration: state.duration),
            ],
          ),
        ),
        // A nota fica no pé, sobre o "Começar" (canvas).
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Text(
            l10n.raceFootnote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        ActionsFooter(
          children: [
            FilledButton.icon(
              key: RaceKeys.start,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.raceStart),
              onPressed: cubit.start,
            ),
          ],
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.medium),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(
                  icon,
                  size: AppIconSize.button,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O recorde: acertos e o problema mais difícil, ou o convite do primeiro.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.duration});

  final RaceRecord record;
  final RaceDuration duration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      key: RaceKeys.recordCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.emoji_events,
                size: AppIconSize.button,
                color: colors.primary,
              ),
            ),
            Expanded(
              child: record.isEmpty
                  ? Text(l10n.raceRecordEmpty)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.raceRecordCorrects(
                            duration.minutes,
                            record.corrects,
                          ),
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          l10n.raceRecordHardest(record.hardest),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
