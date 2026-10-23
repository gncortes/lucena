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
import 'race_filter_screen.dart';

/// A abertura da Corrida: o que é, a duração (3 ou 5 min), as regras, a
/// linha dos filtros (objetivo e finais, em tela cheia), o recorde da duração
/// escolhida e o "Começar".
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
              // Para que serve a Corrida, além do recorde (E1.34).
              Container(
                key: RaceKeys.goalLine,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.medium),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.sm,
                  children: [
                    Icon(
                      Icons.troubleshoot,
                      size: AppIconSize.button,
                      color: colors.onSecondaryContainer,
                    ),
                    Expanded(
                      child: Text(
                        l10n.raceGoalLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
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
              SectionTitle(l10n.raceFilters, inset: 0),
              _FilterRow(state: state),
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

/// A linha "Filtros": o resumo do objetivo e dos finais; abre a tela de
/// filtros e aplica o que voltar dela.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final RaceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<RaceCubit>();
    Future<void> open() async {
      final filter = await Navigator.of(context).push<RaceFilter>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              RaceFilterScreen(problems: state.problems, filter: state.filter),
        ),
      );
      if (filter != null) await cubit.applyFilter(filter);
    }

    return Card(
      key: RaceKeys.filterRow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(open()),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.tune,
                  size: AppIconSize.standard,
                  color: colors.primary,
                ),
              ),
              Expanded(
                child: Text(
                  raceFilterSummary(l10n, state.problems, state.filter),
                  key: RaceKeys.filterSummary,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right,
                  size: AppIconSize.standard,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
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
