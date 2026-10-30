import '../../core/theme/app_shape.dart';
import '../../core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/endgame_lesson_cubit.dart';
import 'grade_widgets.dart';
import 'stars_row.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/keys/test_canvas_keys.dart';

/// Antes dos exercícios: o Viktor explica como pensar (uns 5 minutos por
/// posição) e como a nota fecha; chips com o tamanho do teste e a nota
/// mínima; o que vale cada estrela; o aviso de que depois dá para voltar a
/// qualquer exercício e analisar no Lichess; e, fixo embaixo, o botão que
/// abre o primeiro (ou o próximo).
class ExercisesIntroScreen extends StatelessWidget {
  const ExercisesIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<EndgameLessonCubit>().state;
    final lesson = state.lesson;
    final viktor = state.viktor;
    final next = state.nextExercise;
    if (lesson != null && lesson.id.startsWith('pilares.')) {
      final chapter =
          int.tryParse(
            RegExp(r'\.c(\d+)').firstMatch(lesson.id)?.group(1) ?? '',
          ) ??
          state.lessonNumber;
      return TestCanvasIntroPage(
        chapter: chapter,
        count: state.exerciseCount,
        onStart: next == null
            ? null
            : () => context.pushReplacement(
                Routes.endgameExercise(lesson.id, next.id),
              ),
      );
    }
    // As faixas, da melhor para a menor; numa aula pequena duas podem pedir
    // o mesmo, e aí só a de cima vale.
    final tiers = <MapEntry<ExerciseGrade, int>>[];
    for (final entry in state.gradeStars.entries.toList().reversed) {
      if (tiers.isEmpty || tiers.last.value != entry.value) tiers.add(entry);
    }
    final facts = [
      (
        Icons.format_list_numbered_rounded,
        l10n.endgameTestCount(state.exerciseCount),
        l10n.exercisesIntroCountBody,
      ),
      (
        Icons.star_outline_rounded,
        l10n.exercisesIntroMinTitle(state.passScore),
        l10n.exercisesIntroMinBody(state.maxScore),
      ),
      (
        Icons.schedule_rounded,
        l10n.exercisesIntroChipThink,
        l10n.exercisesIntroThinkBody,
      ),
    ];
    return Scaffold(
      key: ExercisesIntroKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.endgameFinalTest)),
      body: SafeArea(
        child: lesson == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Expanded(
                    // Tela curta: tudo montado de uma vez.
                    child: SingleChildScrollView(
                      padding: scrollPadding(
                        context,
                        left: AppSpacing.screen,
                        top: AppSpacing.lg,
                        right: AppSpacing.screen,
                        bottom: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (viktor != null)
                            TeacherSpeech(
                              speechContext: SpeechContext.teaching,
                              teacher: viktor,
                              text: l10n.exercisesIntroSpeech,
                              emotion: Emotion.focused,
                              avatarSize: CharacterAvatar.speech,
                              speaks: true,
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          // Os três pontos do teste, cada um com o porquê.
                          for (final (icon, title, body) in facts) ...[
                            _FactCard(icon: icon, title: title, body: body),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          // O que vale cada estrela, e o que erro e dica tiram.
                          _InfoCard(
                            child: Column(
                              children: [
                                // Quebra em duas linhas se faltar largura
                                // (idioma longo, letra grande).
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: AppSpacing.lg,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    for (final points in [3, 2, 1])
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ValueStar(points: points, size: 26),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            l10n.exercisePoints(points),
                                            style: theme.textTheme.labelLarge,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.exercisesIntroStarLegend,
                                  key: ExercisesIntroKeys.legend,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // As faixas da nota: o que cada uma pede.
                          _InfoCard(
                            child: Column(
                              key: ExercisesIntroKeys.tiers,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final entry in tiers)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 56,
                                          child: GradeMedal(
                                            grade: entry.key,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                gradeName(l10n, entry.key),
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          AppWeight.strong,
                                                    ),
                                              ),
                                              Text(
                                                l10n.exercisesDoneScore(
                                                  entry.value,
                                                  state.maxScore,
                                                ),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Depois: a lista fica aberta para rever e analisar.
                          _InfoCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    l10n.exercisesIntroAfter,
                                    key: ExercisesIntroKeys.after,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Fixo embaixo, como o "Continuar" da aula.
                  ActionsFooter(
                    children: [
                      FilledButton.icon(
                        key: ExercisesIntroKeys.start,
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: next == null
                            ? null
                            : () => context.pushReplacement(
                                Routes.endgameExercise(lesson.id, next.id),
                              ),
                        label: Text(
                          state.solved == 0
                              ? l10n.endgameExercisesStart
                              : l10n.endgameExercisesContinue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Canvas chapter-test introduction. Data and navigation are supplied by the
/// existing chapter scope, also allowing explicit preview fixtures.
class TestCanvasIntroPage extends StatelessWidget {
  const TestCanvasIntroPage({
    required this.chapter,
    required this.count,
    this.onStart,
    super.key,
  });
  final int chapter, count;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final facts = [
      (
        Icons.format_list_numbered,
        t.endgameTestCount(count),
        t.testCanvasCountBody,
      ),
      (CanvasSymbols.lightbulb, t.testCanvasNoHint, t.testCanvasNoHintBody),
      (
        Icons.visibility_off_outlined,
        t.testCanvasAnswerEnd,
        t.testCanvasAnswerEndBody,
      ),
      (Icons.timer_off_outlined, t.exercisesIntroChipThink, t.testCanvasThink),
    ];
    final names = [
      t.exerciseGradePerfect,
      t.exerciseGradeExcellent,
      t.exerciseGradeGood,
      t.testCanvasRegular,
      t.testCanvasFailed,
    ];
    final thresholds = [
      count,
      ChapterTestScores.excellent(count),
      ChapterTestScores.good(count),
      ChapterTestScores.passed(count),
      (ChapterTestScores.passed(count) - 1).clamp(0, count),
    ];
    return Scaffold(
      key: ExercisesIntroKeys.screen,
      appBar: LucenaAppBar(
        toolbarHeight: 64,
        title: Text(
          t.testCanvasTitle(chapter),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TestCanvasCard(
                      child: Column(
                        key: TestCanvasKeys.facts,
                        spacing: 14,
                        children: [
                          for (final (icon, title, body) in facts)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 12,
                              children: [
                                Icon(
                                  icon,
                                  size: AppIconSize.standard,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 16 / 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TestCanvasCard(
                      child: Column(
                        key: ExercisesIntroKeys.tiers,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 6,
                        children: [
                          Text(
                            t.testCanvasMedals,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          for (var i = 0; i < 5; i++)
                            SizedBox(
                              height: 28,
                              child: Row(
                                spacing: 8,
                                children: [
                                  SizedBox(
                                    width: 56,
                                    height: 24,
                                    child: Center(
                                      child: TestCanvasMedal(
                                        grade: ExerciseGrade.values[4 - i],
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      names[i],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    i == 4
                                        ? t.testCanvasBelow(thresholds[i])
                                        : t.testCanvasScore(
                                            thresholds[i],
                                            count,
                                          ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 20 / 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ActionsFooter(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                FilledButton.icon(
                  key: ExercisesIntroKeys.start,
                  onPressed: onStart,
                  icon: const Icon(CanvasSymbols.playArrow),
                  label: Text(t.endgamePartStart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TestCanvasCard extends StatelessWidget {
  const _TestCanvasCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.chessWhiteColor,
      borderRadius: BorderRadius.circular(AppShape.card),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

/// Filled Material Symbols medals follow CompEstrelas geometry.
class TestCanvasMedal extends StatelessWidget {
  const TestCanvasMedal({required this.grade, this.size = 80, super.key});
  final ExerciseGrade grade;
  final double size;
  @override
  Widget build(BuildContext context) {
    final color = switch (grade) {
      ExerciseGrade.perfect || ExerciseGrade.excellent => AppColors.goldColor,
      ExerciseGrade.good => AppColors.silverColor,
      ExerciseGrade.passed => AppColors.bronzeColor,
      ExerciseGrade.below => AppColors.trainingCanvasOutline,
    };
    final star = Icon(
      CanvasSymbols.star,
      size: size,
      color: color,
      fill: grade == ExerciseGrade.below ? 0 : 1,
    );
    return grade == ExerciseGrade.perfect
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(CanvasSymbols.star, size: size * .6, color: color, fill: 1),
              star,
              Icon(CanvasSymbols.star, size: size * .6, color: color, fill: 1),
            ],
          )
        : star;
  }
}

/// Um card discreto de informação.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

/// Um ponto do teste: ícone num círculo, o título e a explicação.
class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _InfoCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              icon,
              size: AppIconSize.standard,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppWeight.strong,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
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
