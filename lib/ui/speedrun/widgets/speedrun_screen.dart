import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun.dart';
import '../../../routing/routes.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_text.dart';
import '../../journey/widgets/journey_ui.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/time_display.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_rating_bonus_card.dart';
import 'speedrun_ui.dart';
import '../../core/widgets/skeleton.dart';

/// Um speedrun antes de começar (artboards `SpeedrunDetalhe*` e
/// `MaratonaDetalhe`): quem ou o que é, o ritmo e o nível, o recorde (ou a
/// oferta de rating de quem nunca concluiu, ou a tentativa em andamento) e a
/// trilha das etapas. O histórico das tentativas fica na tela dele. "Começar"
/// (ou "Continuar") fica fixo embaixo.
class SpeedrunScreen extends StatelessWidget {
  const SpeedrunScreen({
    this.trainingGoalDone,
    this.onNextGoal,
    this.preview,
    super.key,
  });
  final Future<bool> Function()? trainingGoalDone;
  final VoidCallback? onNextGoal;
  final Speedrun? preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SpeedrunCubit>().state;
    final summary = state.selected;
    final speedrun = summary?.speedrun ?? preview;
    if (speedrun == null) {
      return Scaffold(
        key: SpeedrunKeys.screen,
        appBar: LucenaAppBar(title: Text(l10n.speedrunTitle)),
        body: state.all != null ? null : const SkeletonList(),
      );
    }
    final characters = state.characters;
    final ongoing = summary?.ongoing;
    final total = speedrun.stages.length;
    return Scaffold(
      key: SpeedrunKeys.screen,
      appBar: LucenaAppBar(
        title: Text(
          speedrun.kind == SpeedrunKind.marathon
              ? l10n.marathonSection
              : l10n.speedrunTitle,
        ),
      ),
      bottomNavigationBar: summary == null
          ? null
          : FutureBuilder<bool>(
              future: trainingGoalDone?.call(),
              builder: (context, training) => training.data == true
                  ? SpeedrunActionBar(
                      buttonKey: TrainingKeys.nextGoal,
                      icon: Icons.arrow_forward_rounded,
                      label: l10n.trainingNextGoal,
                      onPressed: onNextGoal!,
                    )
                  : ongoing == null
                  ? SpeedrunActionBar(
                      buttonKey: SpeedrunKeys.start,
                      icon: Icons.play_arrow_rounded,
                      label: l10n.speedrunStartStages(total),
                      onPressed: () => startSpeedrun(context, speedrun),
                    )
                  // O app fechou no meio de uma etapa: ela continua de onde parou.
                  : SpeedrunActionBar(
                      buttonKey: SpeedrunKeys.resume,
                      icon: Icons.play_arrow_rounded,
                      label: l10n.speedrunContinueStage(
                        ongoing.currentStage + 1,
                        total,
                      ),
                      onPressed: () async {
                        final cubit = context.read<SpeedrunCubit>();
                        final route = await cubit.resume();
                        if (route == null || !context.mounted) return;
                        await context.push(route);
                        if (context.mounted) {
                          await cubit.load(speedrunId: speedrun.id);
                        }
                      },
                    ),
            ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          SpeedrunHeader(
            speedrun: speedrun,
            characters: characters,
            homeHero: preview?.stages.isNotEmpty == true,
          ),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: _Block(state: state, summary: summary),
            ),
          if (summary != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(l10n.speedrunStages, style: context.cardTitle),
            ),
          // A ordem das etapas, uma embaixo da outra: quem o jogador
          // enfrenta e, com uma tentativa em andamento, até onde ela chegou
          // e o tempo das etapas feitas.
          if (summary != null)
            for (final (index, stage) in speedrun.stages.indexed)
              SpeedrunStageRow(
                key: SpeedrunKeys.stageCard(index),
                index: index,
                stage: stage,
                speedrun: speedrun,
                last: index == total - 1,
                status: ongoing == null
                    ? SpeedrunStageStatus.idle
                    : index < ongoing.currentStage
                    ? SpeedrunStageStatus.done
                    : index == ongoing.currentStage
                    ? SpeedrunStageStatus.current
                    : SpeedrunStageStatus.ahead,
                trailing: ongoing != null && index < ongoing.currentStage
                    ? TimeDisplay(
                        value: runTime(context, ongoing.stages[index].time),
                        semanticsLabel: l10n.speedrunStageTimeValue(
                          index + 1,
                          total,
                          runTime(context, ongoing.stages[index].time),
                        ),
                        type: TimeDisplayType.duration,
                        size: TimeDisplaySize.inline,
                        textKey: SpeedrunKeys.stageTime(index),
                      )
                    : null,
              ),
        ],
      ),
    );
  }
}

// O que vem logo abaixo do cabeçalho: a tentativa em andamento, o recorde ou,
// para quem nunca concluiu, a oferta de rating e a melhor tentativa.
class _Block extends StatelessWidget {
  const _Block({required this.state, required this.summary});

  final SpeedrunState state;
  final SpeedrunSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final speedrun = summary.speedrun;
    final ongoing = summary.ongoing;
    if (ongoing != null) {
      return _OngoingCard(
        speedrun: speedrun,
        run: ongoing,
        characters: state.characters,
        offer: state.ongoingOffer,
      );
    }
    final best = summary.records.best;
    if (best != null) return _RecordCard(speedrun: speedrun, best: best);
    final reached = summary.furthestStage;
    // Sem tentativa terminada e sem oferta, só o convite.
    if (state.offer <= 0 && reached == null) {
      return Row(
        children: [
          ExcludeSemantics(
            child: Icon(Icons.timer_outlined, color: colors.outline),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.speedrunFirstTimeInvite,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Some se já foi pago no grupo ou se não dá bônus.
        if (state.offer > 0)
          SpeedrunRatingBonusCard.offer(
            points: state.offer,
            group: PaceCategory.of(speedrun.time),
          ),
        if (reached != null)
          _BestAttemptRow(
            speedrun: speedrun,
            stage: reached,
            padTop: state.offer > 0,
          ),
      ],
    );
  }
}

// O recorde, com o caminho para o histórico: o cartão inteiro toca.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.speedrun, required this.best});

  final Speedrun speedrun;
  final Duration best;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final marathon = speedrun.kind == SpeedrunKind.marathon;
    final label = marathon ? l10n.marathonBest : l10n.speedrunYourRecord;
    final value = runTime(context, recordTime(speedrun, best));
    final record = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            color: colors.onSurfaceVariant,
          ),
        ),
        TimeDisplay(
          value: value,
          semanticsLabel: marathon
              ? l10n.marathonBestValue(value)
              : '$label: $value',
          type: TimeDisplayType.record,
          state: TimeDisplayState.highlight,
          textKey: SpeedrunKeys.best,
        ),
      ],
    );
    final link = _HistoryLink(withChevron: true);
    // Com a fonte grande, o link vai para baixo do recorde.
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    return Card(
      key: SpeedrunKeys.recordCard,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          key: SpeedrunKeys.seeHistory,
          onTap: () => context.push(Routes.speedrunHistory(speedrun.id)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            // 12/8/12/16 no artboard (cima, fim, baixo, início).
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: large
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.sm,
                      children: [record, link],
                    )
                  : Row(
                      children: [
                        Expanded(child: record),
                        link,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// "Ver histórico" com o ícone e, no cartão do recorde, a seta.
class _HistoryLink extends StatelessWidget {
  const _HistoryLink({this.withChevron = false});

  final bool withChevron;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        ExcludeSemantics(
          child: Icon(Icons.history, size: AppIconSize.button, color: primary),
        ),
        Flexible(
          child: Text(
            l10n.speedrunSeeHistory,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: primary,
            ),
          ),
        ),
        if (withChevron)
          ExcludeSemantics(
            child: Icon(
              rtl ? Icons.chevron_left : Icons.chevron_right,
              size: AppIconSize.standard,
              color: primary,
            ),
          ),
      ],
    );
  }
}

// "Melhor tentativa: etapa N de 10" e "Ver histórico", para quem nunca
// concluiu: a linha inteira toca.
class _BestAttemptRow extends StatelessWidget {
  const _BestAttemptRow({
    required this.speedrun,
    required this.stage,
    required this.padTop,
  });

  final Speedrun speedrun;

  /// O índice da etapa mais longe a que chegou.
  final int stage;
  final bool padTop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: padTop ? AppSpacing.md : 0),
      child: Semantics(
        button: true,
        child: InkWell(
          key: SpeedrunKeys.bestAttempt,
          borderRadius: BorderRadius.circular(AppShape.small),
          onTap: () => context.push(Routes.speedrunHistory(speedrun.id)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.stairs,
                    size: AppIconSize.button,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.speedrunBestAttempt(stage + 1, speedrun.stages.length),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const _HistoryLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A tentativa que o app deixou no meio de uma etapa: onde parou, o tempo até
// aqui e quanto de rating ela vai render ao concluir.
class _OngoingCard extends StatelessWidget {
  const _OngoingCard({
    required this.speedrun,
    required this.run,
    required this.characters,
    required this.offer,
  });

  final Speedrun speedrun;
  final SpeedrunRun run;
  final List<Character> characters;
  final int offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = speedrun.stages.length;
    final stage = run.currentStage;
    final body = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSecondaryContainer,
    );
    return Card(
      key: SpeedrunKeys.ongoingCard,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.pause_circle,
                size: AppIconSize.standard,
                color: colors.onSecondaryContainer,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.speedrunOngoingTitle,
                    style: context.cardTitle?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    l10n.speedrunOngoingStoppedAt(
                      stage + 1,
                      total,
                      opponentName(
                        l10n,
                        characters,
                        speedrun.stages[stage].opponent,
                      ),
                    ),
                    style: body,
                  ),
                  Text(
                    l10n.speedrunTimeSoFar(runTime(context, run.total)),
                    style: body,
                  ),
                  if (offer > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    KeyedSubtree(
                      key: SpeedrunKeys.ongoingOffer,
                      child: SpeedrunOfferLine(points: offer, style: body),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
