import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../domain/models/character.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/player_rating.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../domain/use_cases/speedrun_score.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/time_display.dart';
import '../../history/widgets/history_labels.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/speedrun_cubit.dart';
import 'marathon_attempt_view.dart';
import 'speedrun_rating_bonus_card.dart';
import 'speedrun_ui.dart';

/// O resumo de uma tentativa terminada do clássico (artboards
/// `SpeedrunTentativa*`): concluída, com o tempo, a comparação com o recorde e
/// o ganho de rating; ou parada (desistiu, perdeu, empatou), com o motivo, o
/// aviso do que falta e "Tentar novamente". É onde o speedrun termina e o que
/// o histórico abre.
class SpeedrunAttemptScreen extends StatelessWidget {
  const SpeedrunAttemptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SpeedrunCubit>().state;
    final summary = state.selected;
    final run = state.run;
    if (summary == null || run == null) {
      return Scaffold(
        key: SpeedrunKeys.attemptScreen,
        appBar: AppBar(centerTitle: true, title: Text(l10n.speedrunTitle)),
        body: state.all != null
            ? null
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final speedrun = summary.speedrun;
    // A Maratona tem o seu fim (bônus, motivo, tempo que sobrou).
    if (speedrun.kind == SpeedrunKind.marathon) {
      return MarathonAttemptView(state: state);
    }
    final end = SpeedrunScore.endOf(run);
    final completed = end == SpeedrunRunEnd.completed;
    final total = speedrun.stages.length;
    final stopped = math.min(run.currentStage, total - 1);
    return Scaffold(
      key: SpeedrunKeys.attemptScreen,
      appBar: AppBar(
        centerTitle: true,
        title: Text(speedrunName(l10n, state.characters, speedrun)),
      ),
      bottomNavigationBar: completed
          ? null
          : SpeedrunActionBar(
              buttonKey: SpeedrunKeys.retry,
              icon: Icons.replay,
              label: l10n.speedrunRetry,
              // Uma tentativa nova do mesmo final e ritmo, da primeira
              // etapa; o resumo sai da pilha.
              onPressed: () => startSpeedrun(context, speedrun, replace: true),
            ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                if (completed)
                  ..._finish(context, state, summary, run)
                else
                  ..._ended(context, state, summary, run, end, stopped),
                _Chips(speedrun: speedrun, run: run),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 8),
            child: Text(
              l10n.speedrunStages,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
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
              trailing: stage.done || (!completed && index == stopped)
                  ? stage.time == Duration.zero && !stage.done
                        ? null
                        : TimeDisplay(
                            value: runTime(context, stage.time),
                            semanticsLabel: l10n.speedrunStageTimeValue(
                              index + 1,
                              total,
                              runTime(context, stage.time),
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

  static String _note(AppLocalizations l10n, SpeedrunRunEnd end) =>
      switch (end) {
        SpeedrunRunEnd.drawn => l10n.speedrunDrawnHere,
        SpeedrunRunEnd.lost => l10n.speedrunLostHere,
        _ => l10n.speedrunAbandonedHere,
      };

  // Concluída: o tempo em destaque, a comparação com o recorde, o ganho de
  // rating e o aviso de que o bônus já foi pago.
  List<Widget> _finish(
    BuildContext context,
    SpeedrunState state,
    SpeedrunSummary summary,
    SpeedrunRun run,
  ) {
    final l10n = context.l10n;
    final speedrun = summary.speedrun;
    final previous = state.previousBest;
    final newRecord = previous != null && run.total < previous;
    final first = previous == null;
    final bonus = state.bonus;
    final paid = state.paid;
    final label = newRecord
        ? l10n.speedrunNewRecord
        : first
        ? l10n.speedrunYourRecord
        : l10n.speedrunTotal;
    final time = runTime(context, run.total);
    final spoken = '$label: $time';
    Widget hero = TimeDisplay(
      value: time,
      semanticsLabel: spoken,
      type: newRecord || first
          ? TimeDisplayType.record
          : TimeDisplayType.stopwatch,
      state: newRecord || first
          ? TimeDisplayState.highlight
          : TimeDisplayState.normal,
      size: TimeDisplaySize.block,
      label: label,
      textKey: SpeedrunKeys.total,
    );
    if (newRecord) {
      hero = KeyedSubtree(key: SpeedrunKeys.newRecord, child: hero);
    }
    final notice = paid == null
        ? null
        : _AlreadyEarned(paid: paid, speedrun: speedrun, state: state);
    return [
      hero,
      if (previous != null)
        _CompareCard(total: run.total, previous: previous, footer: notice),
      if (bonus != null) SpeedrunRatingBonusCard.earned(bonus: bonus),
      if (previous == null && notice != null) _SurfaceCard(child: notice),
    ];
  }

  // Parada: como acabou, o aviso (ou o recorde) e as etapas.
  List<Widget> _ended(
    BuildContext context,
    SpeedrunState state,
    SpeedrunSummary summary,
    SpeedrunRun run,
    SpeedrunRunEnd end,
    int stopped,
  ) {
    final speedrun = summary.speedrun;
    final best = summary.records.best;
    return [
      _EndCard(
        end: end,
        speedrun: speedrun,
        run: run,
        characters: state.characters,
        stage: stopped,
      ),
      if (best != null)
        _RecordCard(best: best)
      else
        _NotFinished(
          speedrun: speedrun,
          characters: state.characters,
          reached: math.max(summary.furthestStage ?? 0, stopped),
          offer: state.offer,
        ),
    ];
  }
}

// Números dentro de uma frase em árabe seguem da esquerda para a direita; nos
// outros idiomas o texto fica como está.
String _ltr(BuildContext context, String text) =>
    Directionality.of(context) == TextDirection.rtl
    ? HistoryLabels.ltr(text)
    : text;

/// O ritmo e quando a tentativa terminou.
class _Chips extends StatelessWidget {
  const _Chips({required this.speedrun, required this.run});

  final Speedrun speedrun;
  final SpeedrunRun run;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final endedAt = run.finishedAt ?? run.attempt.abandonedAt;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        SpeedrunChip(
          icon: paceIcon(PaceCategory.of(speedrun.time)),
          label: paceLabel(l10n, speedrun.time),
        ),
        if (endedAt != null)
          SpeedrunChip(
            icon: Icons.calendar_today,
            outlined: true,
            label: HistoryLabels.capitalize(
              DateFormat.MMMd(locale).add_Hm().format(endedAt.toLocal()),
            ),
          ),
      ],
    );
  }
}

// O cartão cinza (surfaceContainerLow, raio 16) dos avisos e comparações.
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.cardKey,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) => Container(
    key: cardKey,
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppShape.large),
    ),
    child: child,
  );
}

/// "Você já ganhou o rating deste final neste ritmo: +N, em {data}".
class _AlreadyEarned extends StatelessWidget {
  const _AlreadyEarned({
    required this.paid,
    required this.speedrun,
    required this.state,
  });

  final SpeedrunBonus paid;
  final Speedrun speedrun;
  final SpeedrunState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final (_, pace) = SpeedrunPaces.parse(paid.speedrunId);
    final text = l10n
        .speedrunRatingAlreadyEarned(
          speedrunName(l10n, state.characters, speedrun),
          PaceCategory.of(pace).label(l10n),
          paid.points,
          DateFormat.MMMMd(locale).format(paid.at.toLocal()),
        )
        // O "+N" fica LTR dentro do texto, também em árabe.
        .replaceAllMapped(
          RegExp(r'\+\d+'),
          (match) => _ltr(context, match[0]!),
        );
    return Row(
      key: SpeedrunKeys.ratingAlreadyEarned,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        // Alinha o ícone de 16 com a primeira linha de 18.
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ExcludeSemantics(
            child: Icon(
              Icons.trending_flat,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// A comparação com o recorde de antes: a frase da diferença e as duas
/// barras. Com [footer], o aviso de bônus já pago fecha o cartão.
class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.total,
    required this.previous,
    this.footer,
  });

  final Duration total;
  final Duration previous;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final record = total < previous;
    final difference = (previous - total).abs();
    // Os segundos com uma casa e a vírgula do idioma, truncados.
    final decimal = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).symbols.DECIMAL_SEP;
    final seconds = _ltr(
      context,
      RunTimeFormat.difference(difference, decimal: decimal).substring(1),
    );
    final bars = record
        ? [
            _Bar(
              label: l10n.speedrunCompareBefore,
              value: runTime(context, previous),
              fraction: 1,
              color: colors.outline,
            ),
            _Bar(
              label: l10n.speedrunCompareNow,
              value: runTime(context, total),
              fraction: _fraction(total, previous),
              color: colors.tertiary,
              strong: true,
            ),
          ]
        : [
            _Bar(
              label: l10n.speedrunCompareRecord,
              value: runTime(context, previous),
              fraction: _fraction(previous, total),
              color: colors.tertiary,
            ),
            _Bar(
              label: l10n.speedrunCompareThis,
              value: runTime(context, total),
              fraction: 1,
              color: colors.primary,
              strong: true,
            ),
          ];
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: record ? ChangeColors.of(context, up: true) : null,
      fontWeight: record ? FontWeight.w700 : null,
    );
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          // Tempo igual ao recorde: sem frase.
          if (difference > Duration.zero)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    record ? Icons.speed : Icons.schedule,
                    size: 18,
                    color: record
                        ? ChangeColors.of(context, up: true)
                        : colors.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    record
                        ? l10n.speedrunFasterThanRecord(seconds)
                        : l10n.speedrunShortOfRecord(seconds),
                    key: SpeedrunKeys.recordDifference,
                    style: record
                        ? style
                        : style?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          Column(
            key: SpeedrunKeys.recordBars,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: bars,
          ),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: footer,
              ),
            ),
        ],
      ),
    );
  }

  // O quanto [part] é de [whole], de 0 a 1 (com um mínimo para a barra
  // aparecer).
  static double _fraction(Duration part, Duration whole) =>
      whole.inMicroseconds <= 0
      ? 1
      : (part.inMicroseconds / whole.inMicroseconds).clamp(0.02, 1.0);
}

/// Uma barra de comparação: rótulo 64 | barra | valor 56. Com a fonte grande,
/// o rótulo e o valor ficam numa linha e a barra embaixo.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    this.strong = false,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    final labelText = Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: colors.onSurfaceVariant,
      ),
    );
    final valueText = Text(
      value,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: strong ? FontWeight.w700 : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final track = Container(
      height: 10,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: fraction,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppShape.full),
          ),
          child: const SizedBox(height: 10),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xs,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Expanded(child: labelText),
                    valueText,
                  ],
                ),
                track,
              ],
            )
          : Row(
              spacing: 10,
              children: [
                SizedBox(width: 64, child: labelText),
                Expanded(child: track),
                SizedBox(width: 56, child: valueText),
              ],
            ),
    );
  }
}

/// Como a tentativa acabou: ícone, "Perdeu na etapa N de 10", contra quem (se
/// perdeu ou empatou) e o tempo até parar.
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
    final time = _ltr(context, runTime(context, run.total));
    final (icon, hero, key, until) = switch (end) {
      SpeedrunRunEnd.drawn => (
        Icons.drag_handle,
        l10n.speedrunDrawnHero(stage + 1, total),
        SpeedrunKeys.drawnTitle,
        l10n.speedrunTimeUntilDrawn(time),
      ),
      SpeedrunRunEnd.lost => (
        Icons.remove,
        l10n.speedrunLostHero(stage + 1, total),
        SpeedrunKeys.lostTitle,
        l10n.speedrunTimeUntilLost(time),
      ),
      _ => (
        Icons.do_not_disturb_on_outlined,
        l10n.speedrunAbandonedHero(stage + 1, total),
        SpeedrunKeys.abandoned,
        l10n.speedrunTimeUntilAbandon(time),
      ),
    };
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return _SurfaceCard(
      cardKey: SpeedrunKeys.abandonedHero,
      // 20/16 no artboard.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
              child: Icon(icon, size: 28, color: colors.onSurfaceVariant),
            ),
          ),
          Semantics(
            header: true,
            child: Text(
              hero,
              key: key,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (end != SpeedrunRunEnd.abandoned)
            Text(
              l10n.speedrunRungTitle(
                opponentName(l10n, characters, speedrun.stages[stage].opponent),
              ),
              textAlign: TextAlign.center,
              style: muted,
            ),
          Text(
            until,
            key: SpeedrunKeys.timeUntil,
            textAlign: TextAlign.center,
            style: muted,
          ),
        ],
      ),
    );
  }
}

/// "Você ainda não concluiu este speedrun": a melhor etapa alcançada e o que
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

  /// O índice da etapa mais longe a que chegou.
  final int reached;
  final int offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onContainer = colors.onSecondaryContainer;
    final body = theme.textTheme.bodyMedium?.copyWith(color: onContainer);
    return Container(
      key: SpeedrunKeys.notFinishedNotice,
      // 14/16 no artboard.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.info, size: 22, color: onContainer),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  l10n.speedrunNotFinishedYet,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w700,
                    color: onContainer,
                  ),
                ),
                Text(
                  l10n.speedrunBestReached(
                    reached + 1,
                    speedrun.stages.length,
                    opponentName(
                      l10n,
                      characters,
                      speedrun.stages[reached].opponent,
                    ),
                  ),
                  key: SpeedrunKeys.bestReached,
                  style: body,
                ),
                if (offer > 0) SpeedrunOfferLine(points: offer, style: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O recorde de quem já concluiu, no lugar do aviso.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.best});

  final Duration best;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final value = runTime(context, best);
    final label = l10n.speedrunYourRecord;
    final spoken = '$label: $value';
    return _SurfaceCard(
      cardKey: SpeedrunKeys.recordCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TimeDisplay(
            value: value,
            semanticsLabel: spoken,
            type: TimeDisplayType.record,
            size: TimeDisplaySize.inline,
            textKey: SpeedrunKeys.best,
          ),
        ],
      ),
    );
  }
}
