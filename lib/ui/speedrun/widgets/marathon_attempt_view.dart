import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/marathon.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/time_display.dart';
import '../../history/widgets/history_labels.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_rating_bonus_card.dart';
import 'speedrun_ui.dart';

/// O fim de uma tentativa da Maratona (artboards `MaratonaResumo` e
/// `MaratonaFim*`, contrato da T67f):
/// - concluída: o tempo que sobrou em destaque, o cartão do bônus de rating e
///   as etapas;
/// - perdeu, empatou, sem tempo ou desistiu: o cartão de como acabou, o aviso
///   de que ainda não concluiu (ou o recorde, se já concluiu), as etapas com a
///   que parou marcada e "Tentar novamente" no rodapé.
class MarathonAttemptView extends StatelessWidget {
  const MarathonAttemptView({required this.state, super.key});

  final SpeedrunState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = state.selected!;
    final run = state.run!;
    final speedrun = summary.speedrun;
    final characters = state.characters;
    final end = MarathonEnd.of(speedrun, run);
    final completed = end == SpeedrunRunEnd.completed;
    final total = speedrun.stages.length;
    final stopped = math.min(run.currentStage, total - 1);
    final bonus = state.bonus;
    final best = summary.records.best;
    return Scaffold(
      key: SpeedrunKeys.attemptScreen,
      appBar: LucenaAppBar(
        title: Text(
          endgameName(l10n, speedrun.stages.first.position.subcategory),
        ),
      ),
      bottomNavigationBar: completed
          ? null
          : SpeedrunActionBar(
              buttonKey: SpeedrunKeys.retry,
              icon: Icons.replay,
              label: l10n.speedrunRetry,
              onPressed: () => _retry(context, speedrun),
            ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                if (completed) ...[
                  TimeDisplay(
                    value: runTime(context, recordTime(speedrun, run.total)),
                    semanticsLabel: l10n.marathonLeftValue(
                      runTime(context, recordTime(speedrun, run.total)),
                    ),
                    type: TimeDisplayType.record,
                    size: TimeDisplaySize.block,
                    state: TimeDisplayState.highlight,
                    label: l10n.marathonLeft,
                    textKey: SpeedrunKeys.total,
                  ),
                  if (bonus != null && bonus.points > 0)
                    SpeedrunRatingBonusCard.earned(bonus: bonus),
                ] else ...[
                  _EndCard(
                    end: end,
                    speedrun: speedrun,
                    run: run,
                    characters: characters,
                    stage: stopped,
                  ),
                  if (best != null)
                    _RecordCard(speedrun: speedrun, best: best)
                  else
                    _NotFinished(
                      speedrun: speedrun,
                      characters: characters,
                      reached: [run, ...summary.abandoned]
                          .map((r) => math.min(r.currentStage, total - 1))
                          .reduce(math.max),
                      offer: state.offer,
                    ),
                ],
                RunChips(speedrun: speedrun, run: run, marathon: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(l10n.speedrunStages, style: context.cardTitle),
          ),
          for (final (index, stage) in run.stages.indexed)
            SpeedrunStageRow(
              key: SpeedrunKeys.stage(index),
              index: index,
              stage: speedrun.stages[index],
              speedrun: speedrun,
              last: index == total - 1,
              note: !completed && index == stopped ? _note(l10n, end) : null,
              noteKey: SpeedrunKeys.stageNote(index),
              status: stage.done
                  ? SpeedrunStageStatus.done
                  : !completed && index == stopped
                  // A etapa em que a tentativa parou.
                  ? SpeedrunStageStatus.current
                  : SpeedrunStageStatus.ahead,
              trailing: stage.done || stage.losses > 0
                  ? TimeDisplay(
                      value: runTime(context, stage.time),
                      semanticsLabel: l10n.speedrunStageTimeValue(
                        index + 1,
                        total,
                        runTime(context, stage.time),
                      ),
                      size: TimeDisplaySize.inline,
                      textKey: SpeedrunKeys.stageTime(index),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  static String _note(AppLocalizations l10n, SpeedrunRunEnd end) =>
      switch (end) {
        SpeedrunRunEnd.drawn => l10n.marathonDrawnHere,
        SpeedrunRunEnd.timeout => l10n.marathonTimeoutHere,
        SpeedrunRunEnd.abandoned => l10n.speedrunAbandonedHere,
        _ => l10n.speedrunLostHere,
      };

  // "Tentar novamente": uma tentativa nova do mesmo final e ritmo, da
  // primeira etapa. A tela do fim sai da pilha: voltar da partida leva ao
  // detalhe.
  Future<void> _retry(BuildContext context, Speedrun speedrun) async {
    final started = await context.read<SpeedrunCubit>().startWith(
      speedrun.time,
    );
    if (started == null || !context.mounted) return;
    final (paced, attempt) = started;
    context.pushReplacement(
      Routes.challengeGame(
        paced.stages.first,
        speedrunId: paced.id,
        attemptId: attempt,
        stage: 0,
      ),
    );
  }
}

/// Como a tentativa acabou: ícone, "Perdeu na etapa N de 10", contra quem e o
/// tempo que sobrou (no "sem tempo" não há o que mostrar: sobrou zero).
class _EndCard extends StatelessWidget {
  const _EndCard({
    required this.end,
    required this.speedrun,
    required this.run,
    required this.characters,
    required this.stage,
  });

  final SpeedrunRunEnd end;
  final Speedrun speedrun;
  final SpeedrunRun run;
  final List<Character> characters;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = speedrun.stages.length;
    final (icon, hero) = switch (end) {
      SpeedrunRunEnd.drawn => (
        Icons.drag_handle,
        l10n.marathonDrawnHero(stage + 1, total),
      ),
      SpeedrunRunEnd.timeout => (
        Icons.hourglass_bottom,
        l10n.marathonTimeoutHero(stage + 1, total),
      ),
      SpeedrunRunEnd.abandoned => (
        Icons.do_not_disturb_on_outlined,
        l10n.speedrunAbandonedHero(stage + 1, total),
      ),
      _ => (Icons.remove, l10n.speedrunLostHero(stage + 1, total)),
    };
    final opponent = opponentName(
      l10n,
      characters,
      speedrun.stages[stage].opponent,
    );
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          // 20 no artboard.
          vertical: AppSpacing.lg + AppSpacing.xs,
        ),
        child: Column(
          spacing: AppSpacing.sm,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Icon(
                  icon,
                  size: AppIconSize.large,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                hero,
                key: SpeedrunKeys.marathonEndHero,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Text(
              l10n.speedrunRungTitle(opponent),
              key: SpeedrunKeys.marathonEndOpponent,
              textAlign: TextAlign.center,
              style: muted,
            ),
            if (end != SpeedrunRunEnd.timeout)
              Text(
                l10n.marathonLeftValue(
                  HistoryLabels.ltr(
                    runTime(context, Marathon.bank(run, speedrun.time)),
                  ),
                ),
                key: SpeedrunKeys.marathonEndLeft,
                textAlign: TextAlign.center,
                style: muted,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Você ainda não concluiu esta maratona": a melhor etapa alcançada e o que
/// concluir renderia de rating (a linha some sem oferta).
class _NotFinished extends StatelessWidget {
  const _NotFinished({
    required this.speedrun,
    required this.characters,
    required this.reached,
    required this.offer,
  });

  final Speedrun speedrun;
  final List<Character> characters;
  final int reached;
  final int offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final opponent = opponentName(
      l10n,
      characters,
      speedrun.stages[reached].opponent,
    );
    final onContainer = colors.onSecondaryContainer;
    final body = theme.textTheme.bodyMedium?.copyWith(color: onContainer);
    return Card(
      key: SpeedrunKeys.marathonNotFinished,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          // 14 no artboard.
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.info,
                size: AppIconSize.standard,
                color: onContainer,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    l10n.marathonNotFinishedYet,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onContainer,
                    ),
                  ),
                  Text(
                    l10n.speedrunBestReached(
                      reached + 1,
                      speedrun.stages.length,
                      opponent,
                    ),
                    style: body,
                  ),
                  if (offer > 0) _Offer(points: offer, style: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "+N de rating ao concluir", com o "+N de rating" em verde e o ícone.
class _Offer extends StatelessWidget {
  const _Offer({required this.points, required this.style});

  final int points;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final background = theme.colorScheme.secondaryContainer;
    final color = _legible(
      ChangeColors.of(context, up: true),
      background,
      theme.brightness,
    );
    final full = l10n.speedrunRatingBonusAtFinish(points);
    final short = l10n.speedrunRatingBonusShort(points);
    final at = full.indexOf(short);
    if (at < 0) return Text(full, style: style);
    final strong = style?.copyWith(fontWeight: AppWeight.strong, color: color);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: full.substring(0, at)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ExcludeSemantics(
              child: Icon(
                Icons.trending_up,
                size: AppIconSize.small,
                color: color,
              ),
            ),
          ),
          const WidgetSpan(child: SizedBox(width: AppSpacing.xs)),
          TextSpan(text: HistoryLabels.ltr(short), style: strong),
          TextSpan(text: full.substring(at + short.length)),
        ],
      ),
    );
  }

  // O verde do "sobe" com o contraste de leitura (4,5:1) sobre o aviso.
  static Color _legible(Color color, Color background, Brightness brightness) {
    final target = brightness == Brightness.dark
        ? AppColors.white
        : AppColors.black;
    var result = color;
    for (var i = 0; i < 10 && _contrast(result, background) < 4.5; i++) {
      result = Color.lerp(result, target, 0.1)!;
    }
    return result;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}

/// O recorde de quem já concluiu a Maratona, no lugar do aviso.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.speedrun, required this.best});

  final Speedrun speedrun;
  final Duration best;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = runTime(context, recordTime(speedrun, best));
    final green = GoalStyle.of(context, GoalTone.win).color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: Text(
                l10n.marathonBest,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Semantics(
              container: true,
              excludeSemantics: true,
              label: l10n.marathonBestValue(value),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: AppIconSize.standard,
                    color: green,
                  ),
                  Text(
                    value,
                    key: SpeedrunKeys.marathonRecord,
                    textDirection: TextDirection.ltr,
                    style: context.bigNumber?.copyWith(
                      color: green,
                      fontSize: 24,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
