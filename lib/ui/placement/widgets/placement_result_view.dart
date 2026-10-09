import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/placement.dart';
import '../../../domain/models/rating_level.dart';
import '../../core/keys/placement_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../view_models/placement_cubit.dart';
import 'placement_prompt.dart';

/// O fim do teste: a faixa (com o intervalo numa régua), o mapa do que o
/// jogador domina e do que falta, os três primeiros passos do roteiro e, fixo
/// embaixo, "Usar este nível".
class PlacementResultView extends StatefulWidget {
  const PlacementResultView({
    required this.state,
    this.onDone,
    this.onChooseByHand,
    super.key,
  });

  final PlacementViewState state;
  final VoidCallback? onDone;
  final VoidCallback? onChooseByHand;

  @override
  State<PlacementResultView> createState() => _PlacementResultViewState();
}

class _PlacementResultViewState extends State<PlacementResultView> {
  RatingLevel? _chosen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.state.result;
    if (result == null) return const SizedBox.shrink();
    final chosen = _chosen ?? result.level;
    final levels = result.levels;
    return Column(
      key: PlacementKeys.result,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: scrollPadding(
              context,
              left: AppSpacing.screen,
              top: AppSpacing.sm,
              right: AppSpacing.screen,
              bottom: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LevelCard(result: result, shown: chosen),
                if (levels.length > 1) ...[
                  const SizedBox(height: AppSpacing.betweenCards),
                  _TwoLevels(
                    levels: levels,
                    chosen: chosen,
                    onChoose: (level) => setState(() => _chosen = level),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _SkillMapSection(state: widget.state),
                if (widget.state.roadmap?.steps.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Roadmap(state: widget.state),
                ],
                const SizedBox(height: AppSpacing.lg),
                _Sources(text: l10n.placementSources),
              ],
            ),
          ),
        ),
        _Actions(
          onUse: () async {
            await context.read<PlacementCubit>().apply(level: chosen);
            widget.onDone?.call();
          },
          onChooseByHand: widget.onChooseByHand,
        ),
      ],
    );
  }
}

/// A faixa em destaque: a peça, o nome, o número e o intervalo numa régua de
/// 400 a 2800, com as seis faixas.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.result, required this.shown});

  final PlacementResult result;
  final RatingLevel shown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.filled(
      key: PlacementKeys.level,
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.placementResultTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedSwitcher(
              duration: AppMotion.of(context).state,
              child: Row(
                key: ValueKey(shown),
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      shown.name(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    shown == result.level
                        ? '${result.theta}'
                        : '${shown.rating}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.placementBetween(result.low, result.high),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Ruler(result: result),
          ],
        ),
      ),
    );
  }
}

/// A régua: as faixas lado a lado, o intervalo em destaque e um marcador no
/// número. O intervalo abre a partir do número quando a tela entra.
class _Ruler extends StatelessWidget {
  const _Ruler({required this.result});

  final PlacementResult result;

  static const _min = 400.0;
  static const _max = 2800.0;

  static double _at(num rating) =>
      ((rating - _min) / (_max - _min)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      key: PlacementKeys.ruler,
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context).screen,
      curve: AppMotion.enter,
      builder: (context, t, _) => LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final theta = _at(result.theta) * width;
          final low = theta + (_at(result.low) * width - theta) * t;
          final high = theta + (_at(result.high) * width - theta) * t;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // As faixas, alternando o tom.
                    Positioned.fill(
                      top: 10,
                      bottom: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppShape.full),
                        child: Row(
                          children: [
                            for (final level in RatingLevel.values)
                              Expanded(
                                flex: _span(level),
                                child: ColoredBox(
                                  color: level.index.isEven
                                      ? colors.surface.withValues(alpha: 0.7)
                                      : colors.surface.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // O intervalo.
                    Positioned(
                      left: low,
                      width: (high - low).clamp(0, width),
                      top: 8,
                      bottom: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(AppShape.full),
                        ),
                      ),
                    ),
                    // O número.
                    Positioned(
                      left: theta - 4,
                      width: 8,
                      top: 2,
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(AppShape.full),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final label in ['400', '1000', '1600', '2200', '2800'])
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // A largura de cada faixa na régua, em pontos de rating.
  static int _span(RatingLevel level) {
    final min = level.min ?? _min.toInt();
    final max = (level.max ?? _max.toInt() - 1) + 1;
    return max - min;
  }
}

/// O intervalo cruza duas faixas (ou mais): o jogador escolhe.
class _TwoLevels extends StatelessWidget {
  const _TwoLevels({
    required this.levels,
    required this.chosen,
    required this.onChoose,
  });

  final List<RatingLevel> levels;
  final RatingLevel chosen;
  final ValueChanged<RatingLevel> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.placementTwoLevels, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final level in levels)
              ChoiceChip(
                key: PlacementKeys.levelChoice(level),
                label: Text(level.name(l10n)),
                selected: level == chosen,
                onSelected: (_) => onChoose(level),
              ),
          ],
        ),
      ],
    );
  }
}

/// O mapa: por grupo, os nós com evidência (já domina, provavelmente sabe,
/// para estudar). Os sem evidência ficam de fora.
class _SkillMapSection extends StatelessWidget {
  const _SkillMapSection({required this.state});

  final PlacementViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final result = state.result!;
    final skills = state.skills;
    if (skills == null) return const SizedBox.shrink();
    final groups = <SkillGroup, List<(SkillNode, NodeStatus)>>{};
    for (final node in skills.nodes) {
      final status = result.status(node.id);
      if (status.state == NodeState.unknown) continue;
      groups.putIfAbsent(node.group, () => []).add((node, status));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.placementMapTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // A legenda.
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            for (final state in [
              NodeState.mastered,
              NodeState.likely,
              NodeState.gap,
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon(state), size: 16, color: _color(colors, state)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _label(l10n, state),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
        for (final group in SkillGroup.values)
          if (groups[group] case final nodes?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              skillGroupName(l10n, group),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final (node, status) in nodes)
                  _NodeChip(node: node, status: status),
              ],
            ),
          ],
      ],
    );
  }
}

IconData _icon(NodeState state) => switch (state) {
  NodeState.mastered => Icons.verified_rounded,
  NodeState.likely => Icons.check_circle_outline_rounded,
  NodeState.gap => Icons.priority_high_rounded,
  NodeState.unknown => Icons.help_outline_rounded,
};

Color _color(ColorScheme colors, NodeState state) => switch (state) {
  NodeState.mastered => colors.primary,
  NodeState.likely => colors.primary.withValues(alpha: 0.6),
  NodeState.gap => _amber(colors),
  NodeState.unknown => colors.outline,
};

// "Para estudar": âmbar, um aviso sem cara de erro.
Color _amber(ColorScheme colors) => colors.brightness == Brightness.dark
    ? Colors.amber.shade300
    : Colors.amber.shade900;

String _label(AppLocalizations l10n, NodeState state) => switch (state) {
  NodeState.mastered => l10n.placementMastered,
  NodeState.likely => l10n.placementLikely,
  NodeState.gap => l10n.placementGap,
  NodeState.unknown => '',
};

class _NodeChip extends StatelessWidget {
  const _NodeChip({required this.node, required this.status});

  final SkillNode node;
  final NodeStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final gap = status.isGap;
    return Container(
      key: PlacementKeys.node(node.id),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      // A lacuna em contorno, para saltar aos olhos sem pesar.
      decoration: BoxDecoration(
        color: gap ? colors.surface : colors.surfaceContainerHighest,
        border: gap ? Border.all(color: _amber(colors), width: 1.5) : null,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon(status.state),
            size: 16,
            color: _color(colors, status.state),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              skillName(l10n, node.id),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Os três primeiros passos do roteiro, numerados.
class _Roadmap extends StatelessWidget {
  const _Roadmap({required this.state});

  final PlacementViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final steps = state.roadmap!.steps.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.placementRoadmapTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (index, step) in steps.indexed)
          Padding(
            key: PlacementKeys.step(index),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card.outlined(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: index == 0
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      foregroundColor: index == 0
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: index == 0
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.titles[step.lessonId] ?? step.lessonId,
                            style: theme.textTheme.titleSmall,
                          ),
                          // O nó só quando o título da aula não diz o mesmo.
                          if (skillName(l10n, step.node) case final skill
                              when skill != state.titles[step.lessonId])
                            Text(
                              skill,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      step.school
                          ? Icons.school_outlined
                          : Icons.auto_stories_outlined,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    if (step.soon) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.placementSoon,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A fonte dos puzzles, discreta, no fim.
class _Sources extends StatelessWidget {
  const _Sources({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      key: PlacementKeys.sources,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: colors.outline),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.outline),
          ),
        ),
      ],
    );
  }
}

/// Fixo embaixo: "Usar este nível" e, no tour, "Prefiro escolher minha
/// faixa".
class _Actions extends StatelessWidget {
  const _Actions({required this.onUse, this.onChooseByHand});

  final VoidCallback onUse;
  final VoidCallback? onChooseByHand;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              key: PlacementKeys.useLevel,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: onUse,
              child: Text(l10n.placementUseLevel),
            ),
            if (onChooseByHand != null)
              TextButton(
                key: PlacementKeys.chooseByHand,
                onPressed: onChooseByHand,
                child: Text(l10n.placementChooseByHand),
              ),
          ],
        ),
      ),
    );
  }
}
