import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/race.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/next_steps.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/race_cubit.dart';
import 'race_diagnosis_card.dart';

/// O resultado: por que acabou, quantos acertos, o recorde, três números, o
/// diagnóstico das últimas Corridas (com o que fazer no ponto mais fraco) e os
/// problemas que apareceram (certos e errados).
class RaceResultView extends StatelessWidget {
  const RaceResultView({required this.state, super.key});

  final RaceState state;

  @override
  Widget build(BuildContext context) {
    final outcome = state.outcome;
    if (outcome == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final cubit = context.read<RaceCubit>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final result = outcome.result;
    final run = result.run;
    final mistakes = state.mistakes;
    final diagnosis = state.diagnosis;
    final weakest = diagnosis.weakest;
    // Quanto tempo a Corrida durou, no máximo o limite.
    final elapsed = result.finishedAt.difference(run.startedAt);
    final limit = run.duration.limit;
    final used = elapsed > limit ? limit : elapsed;
    final pace = run.answers.isEmpty
        ? '-'
        : l10n.raceStatPaceValue(
            (used.inMilliseconds / run.answers.length / 1000).round(),
          );
    return Column(
      key: RaceKeys.resultView,
      children: [
        Expanded(
          child: ListView(
            padding: scrollPadding(
              context,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
            ),
            children: [
              Text(
                switch (result.end) {
                  RaceEnd.time => l10n.raceEndTime,
                  RaceEnd.errors => l10n.raceEndErrors,
                  RaceEnd.quit => l10n.raceEndQuit,
                },
                key: RaceKeys.resultTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${run.corrects}',
                key: RaceKeys.resultCorrects,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                l10n.raceCorrectsCount(run.corrects),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (outcome.isRecord && outcome.previous.corrects > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Center(
                    child: InfoChip(
                      key: RaceKeys.newRecord,
                      icon: Icons.emoji_events,
                      label: l10n.raceNewRecord(outcome.previous.corrects),
                      background: ChangeColors.of(
                        context,
                        up: true,
                      ).withValues(alpha: 0.16),
                      foreground: ChangeColors.of(context, up: true),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                spacing: AppSpacing.sm,
                children: [
                  _Stat(
                    key: RaceKeys.statErrors,
                    value: '${run.errors}',
                    label: l10n.raceStatErrors(run.errors),
                  ),
                  _Stat(
                    key: RaceKeys.statHardest,
                    value: run.hardestSolved == 0
                        ? '-'
                        : '${run.hardestSolved}',
                    label: l10n.raceStatHardest,
                  ),
                  _Stat(
                    key: RaceKeys.statPace,
                    value: pace,
                    label: l10n.raceStatPace,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              RaceDiagnosisCard(diagnosis: diagnosis),
              if (weakest != null) ...[
                const SizedBox(height: AppSpacing.lg),
                NextSteps(
                  title: l10n.raceImproveTitle(
                    categoryName(l10n, weakest.category),
                  ),
                  steps: [
                    NextStep(
                      id: 'raceFocus',
                      icon: Icons.timer,
                      title: l10n.raceFocusTitle(
                        categoryName(l10n, weakest.category),
                      ),
                      body: l10n.raceFocusBody,
                      onTap: () => cubit.focus(category: weakest.category),
                    ),
                    NextStep(
                      id: 'raceTrain',
                      icon: Icons.sports_esports,
                      title: l10n.raceTrainTitle(
                        categoryName(l10n, weakest.category),
                      ),
                      body: l10n.raceTrainBody,
                      onTap: () =>
                          context.go(Routes.catalogCategory(weakest.category)),
                    ),
                  ],
                ),
              ],
              if (!diagnosis.ready) ...[
                const SizedBox(height: AppSpacing.lg),
                const DataNote(),
              ],
              // O título sem o recuo próprio: alinhado aos cartões de cima.
              SectionTitle(l10n.raceProblemsTitle, inset: 0),
              _ProblemGrid(
                tiles: (size) => [
                  for (final (index, answer) in run.answers.indexed)
                    _ProblemTile(
                      key: RaceKeys.problemTile(index),
                      size: size,
                      answer: answer,
                      problem: state.problems
                          .where((p) => p.id == answer.problemId)
                          .firstOrNull,
                    ),
                ],
              ),
            ],
          ),
        ),
        ActionsFooter(
          stacked: true,
          children: [
            FilledButton.icon(
              key: RaceKeys.again,
              icon: const Icon(Icons.replay),
              label: Text(l10n.raceAgain),
              onPressed: cubit.start,
            ),
            if (mistakes.isNotEmpty)
              OutlinedButton.icon(
                key: RaceKeys.reviewMistakes,
                icon: const Icon(Icons.visibility),
                label: Text(l10n.raceReviewMistakes(mistakes.length)),
                onPressed: cubit.review,
              ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A grade dos problemas (canvas): 4 colunas de 88 dp, espalhadas pela largura
/// e com a última linha alinhada ao início.
class _ProblemGrid extends StatelessWidget {
  const _ProblemGrid({required this.tiles});

  static const _columns = 4;

  /// O vão mínimo entre as miniaturas: numa tela estreita elas diminuem, para
  /// o selo de uma não encostar na vizinha.
  static const _minGap = AppSpacing.md;

  /// As miniaturas, no tamanho que cabe.
  final List<Widget> Function(double size) tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(
        _ProblemTile.maxSize,
        ((box.maxWidth - (_columns - 1) * _minGap) / _columns).floorToDouble(),
      );
      final gap = ((box.maxWidth - _columns * size) / (_columns - 1))
          .floorToDouble();
      return Wrap(
        alignment: WrapAlignment.start,
        spacing: gap,
        runSpacing: AppSpacing.lg,
        children: tiles(size),
      );
    },
  );
}

/// A miniatura de um problema: o selo de certo ou de errado e o nível
/// embaixo.
class _ProblemTile extends StatelessWidget {
  const _ProblemTile({
    required this.size,
    required this.answer,
    required this.problem,
    super.key,
  });

  /// O tamanho do canvas (PropV1CorridaResultado), quando cabe.
  static const maxSize = 88.0;
  static const _badge = 22.0;

  final double size;
  final RaceAnswer answer;
  final RaceProblem? problem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = answer.correct
        ? ChangeColors.of(context, up: true)
        : colors.error;
    final problem = this.problem;
    return SizedBox(
      width: size,
      child: Column(
        spacing: AppSpacing.xs,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (problem == null)
                SizedBox.square(dimension: size)
              else
                PositionBoard(
                  fen: problem.fen,
                  size: size,
                  radius: AppShape.small,
                ),
              PositionedDirectional(
                end: -AppSpacing.xs,
                top: -AppSpacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: _badge,
                    child: Icon(
                      answer.correct ? Icons.check : Icons.close,
                      size: AppIconSize.small,
                      color: colors.onError,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${answer.level}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
