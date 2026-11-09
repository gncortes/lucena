import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/race.dart';
import '../../../domain/use_cases/race_diagnosis.dart';
import '../../../routing/routes.dart';
import '../../core/keys/race_keys.dart';
import '../../core/motion/entrada_de_resultado.dart';
import '../../core/motion/numero_que_conta.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/position_board.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/race_cubit.dart';
import 'race_problems_screen.dart';

/// O resultado (canvas SugP2CorridaFimA): por que acabou, quantos acertos, o
/// cartão "O que contou" (acertos e recorde, nível, desempenho por final) e os
/// problemas que apareceram (certos e errados).
class RaceResultView extends StatelessWidget {
  const RaceResultView({required this.state, super.key});

  final RaceState state;

  /// Quantas miniaturas a grade mostra; o resto fica em "Ver os N".
  static const shownProblems = 8;

  @override
  Widget build(BuildContext context) {
    final outcome = state.outcome;
    if (outcome == null) return const SizedBox.shrink();
    final result = outcome.result;
    final run = result.run;
    final mistakes = state.mistakes;
    // H-ANI-25: o título sobe, os acertos contam, o resto do resultado entra
    // e os botões deslizam por último. Cada Corrida é um resultado novo.
    return KeyedSubtree(
      key: RaceKeys.resultView,
      child: EntradaDeResultado(
        id: 'corrida-${run.startedAt.microsecondsSinceEpoch}',
        titulo: _ResultTitle(end: result.end),
        placar: _ResultScore(outcome: outcome),
        viktor: _ResultBody(state: state, outcome: outcome),
        botoes: _ResultButtons(mistakes: mistakes.length),
        montar: (partes) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                ),
                children: partes.sublist(0, partes.length - 1),
              ),
            ),
            partes.last,
          ],
        ),
      ),
    );
  }
}

/// Por que a Corrida acabou.
class _ResultTitle extends StatelessWidget {
  const _ResultTitle({required this.end});

  final RaceEnd end;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Text(
      switch (end) {
        RaceEnd.time => l10n.raceEndTime,
        RaceEnd.errors => l10n.raceEndErrors,
        RaceEnd.quit => l10n.raceEndQuit,
      },
      key: RaceKeys.resultTitle,
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

/// Os acertos (contando) e, se bateu o recorde, a etiqueta do recorde.
class _ResultScore extends StatelessWidget {
  const _ResultScore({required this.outcome});

  final RaceOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final run = outcome.result.run;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NumeroQueConta(
          key: RaceKeys.resultCorrects,
          valor: run.corrects,
          estilo: theme.textTheme.displayLarge?.copyWith(
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
                label: l10n.desafiosRaceNewRecord(
                  run.duration.minutes,
                  outcome.previous.corrects,
                ),
                background: ChangeColors.of(
                  context,
                  up: true,
                ).withValues(alpha: 0.16),
                foreground: ChangeColors.of(context, up: true),
              ),
            ),
          ),
      ],
    );
  }
}

/// O cartão "O que contou" e os problemas que apareceram.
class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.state, required this.outcome});

  final RaceState state;
  final RaceOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final run = outcome.result.run;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        // O que contou (canvas SugP2CorridaFimA): os acertos e o recorde,
        // o nível alcançado e o desempenho por final. Sem ponto fraco no
        // resultado: pronto, a linha abre o desempenho por final.
        _CountedCard(
          key: RaceKeys.counted,
          minutes: run.duration.minutes,
          corrects: run.corrects,
          record: math.max(outcome.previous.corrects, run.corrects),
          hardest: run.hardestSolved,
          diagnosis: state.diagnosis,
          onPerformance: () => context.push(Routes.racePerformance),
        ),
        const SizedBox(height: AppSpacing.lg),
        // O título sem o recuo próprio: alinhado aos cartões de cima.
        SectionTitle(
          l10n.raceProblemsTitle,
          inset: 0,
          action: run.answers.length > RaceResultView.shownProblems
              ? SectionAction(
                  key: RaceKeys.seeAllProblems,
                  label: l10n.desafiosRaceSeeAll(run.answers.length),
                  onPressed: () => unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RaceProblemsScreen(
                          answers: run.answers,
                          problems: state.problems,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        RaceProblemGrid(
          tiles: (size) => [
            for (final (index, answer)
                in run.answers.take(RaceResultView.shownProblems).indexed)
              RaceProblemTile(
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
    );
  }
}

/// Jogar de novo e, havendo erros, revê-los.
class _ResultButtons extends StatelessWidget {
  const _ResultButtons({required this.mistakes});

  final int mistakes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RaceCubit>();
    return ActionsFooter(
      stacked: true,
      children: [
        FilledButton.icon(
          key: RaceKeys.again,
          icon: const Icon(Icons.replay),
          label: Text(l10n.raceAgain),
          onPressed: cubit.start,
        ),
        if (mistakes > 0)
          OutlinedButton.icon(
            key: RaceKeys.reviewMistakes,
            icon: const Icon(Icons.visibility),
            label: Text(l10n.raceReviewMistakes(mistakes)),
            onPressed: cubit.review,
          ),
      ],
    );
  }
}

/// O cartão "O que contou": até três linhas com ícone, como os fatos da
/// abertura. Sem acerto, não há nível para contar e a linha some.
class _CountedCard extends StatelessWidget {
  const _CountedCard({
    required this.minutes,
    required this.corrects,
    required this.record,
    required this.hardest,
    required this.diagnosis,
    required this.onPerformance,
    super.key,
  });

  final int minutes;
  final int corrects;

  /// O recorde da duração, já contando esta Corrida.
  final int record;
  final int hardest;
  final RaceDiagnosis diagnosis;
  final VoidCallback onPerformance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const total = RaceDiagnosis.neededRuns;
    // Com as Corridas feitas mas sem problemas bastantes de nenhum final,
    // ainda falta uma.
    final done = diagnosis.runs.clamp(0, total - 1);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Text(
              l10n.raceCountedTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            _CountedLine(
              key: RaceKeys.countedCorrects,
              icon: Icons.emoji_events,
              text: l10n.raceCountedCorrects(corrects, minutes, record),
            ),
            if (hardest > 0)
              _CountedLine(
                key: RaceKeys.countedLevel,
                icon: Icons.trending_up,
                text: l10n.raceCountedLevel(hardest),
              ),
            if (diagnosis.ready)
              _CountedLine(
                key: RaceKeys.performance,
                icon: Icons.query_stats,
                text: l10n.racePerformanceLine,
                onTap: onPerformance,
              )
            else
              _CountedLine(
                key: RaceKeys.diagnosisProgress,
                icon: Icons.query_stats,
                text: l10n.raceCountedPerformance(done, total),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountedLine extends StatelessWidget {
  const _CountedLine({
    required this.icon,
    required this.text,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // O alvo de toque mínimo quando a linha abre algo.
        constraints: BoxConstraints(minHeight: onTap == null ? 0 : 48),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: AppIconSize.notice,
                color: colors.primary,
              ),
            ),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            if (onTap != null)
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
    );
  }
}

/// A grade dos problemas (canvas): 4 colunas de 88 dp, espalhadas pela largura
/// e com a última linha alinhada ao início.
class RaceProblemGrid extends StatelessWidget {
  const RaceProblemGrid({required this.tiles, super.key});

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
        RaceProblemTile.maxSize,
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
class RaceProblemTile extends StatelessWidget {
  const RaceProblemTile({
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
