import '../../core/widgets/empty_state.dart';
import '../../../domain/models/ads_state.dart';
import '../../core/ads/lesson_gate.dart';

import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/course/course_continue_card.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/course/course_part_header.dart';
import '../../core/widgets/info_chip.dart';
import '../view_models/school_cubit.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/placement_test_card.dart';

/// A Escola do Viktor (canvas `PropV2EscolaCurso`, padrão T1 dos cursos): o
/// cartão "Continuar", o teste de nível, os desafios e as partes com as
/// lições (feitas, liberadas e trancadas).
class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final _currentLesson = GlobalKey();
  String? _scrolledLesson;

  void _revealCurrent(String? lesson) {
    if (lesson == null || lesson == _scrolledLesson) return;
    _scrolledLesson = lesson;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scrolledLesson != lesson) return;
      final target = _currentLesson.currentContext;
      final box = target?.findRenderObject();
      // Embaixo de outra tela (o app reabriu num desafio), a lista não foi
      // desenhada: não há o que rolar.
      if (target != null && box is RenderBox && box.hasSize) {
        // Só rola se a lição atual estiver fora da janela: o topo (o
        // Continuar) fica à vista como no canvas.
        Scrollable.ensureVisible(
          target,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: SchoolKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.schoolTitle)),
      body: BlocBuilder<SchoolCubit, SchoolState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          if (state.course.lessons.isEmpty) {
            return SafeArea(
              top: false,
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: EmptyState(
                    icon: Icons.auto_stories_outlined,
                    message: context.l10n.lessonsUnavailableMessage,
                  ),
                ),
              ),
            );
          }
          final next = state.next;
          _revealCurrent(next);
          return SingleChildScrollView(
            key: SchoolKeys.scroll,
            // v2_cursos_padrao: corpo 8 16 0 16; o fim respira 32.
            padding: scrollPadding(
              context,
              left: AppSpacing.lg,
              top: AppSpacing.sm,
              right: AppSpacing.lg,
              bottom: AppSpacing.xxl,
            ),
            // Todas as âncoras estão montadas: a lição atual pode estar numa
            // parte distante, fora da primeira janela visível.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // v2_cursos_padrao: 12 entre os blocos.
              spacing: AppSpacing.md,
              children: [
                // Formado, o "Continuar" vira a entrada do Curso de finais.
                if (state.graduated)
                  FilledButton.tonalIcon(
                    key: SchoolKeys.endgamesButton,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(kButtonHeight),
                      textStyle: AppButtonText.footer(context),
                    ),
                    icon: const Icon(Icons.auto_stories_outlined),
                    label: Text(l10n.endgamesTitle),
                    onPressed: () => context.push(Routes.endgames),
                  )
                else if (next != null)
                  _Continue(lessonId: next, state: state),
                if (!state.tested && !state.graduated)
                  PlacementTestCard(
                    label: context.l10n.schoolTestPrompt,
                    tapKey: SchoolKeys.placementTest,
                    onTap: () async {
                      final cubit = context.read<SchoolCubit>();
                      final language = Localizations.localeOf(context)
                          .languageCode;
                      final used = await context.push<bool>(
                        Routes.placementFrom('school'),
                      );
                      if (used == true) await cubit.load(language);
                    },
                  ),
                _ChallengesCard(),
                if (state.skipped.isNotEmpty) _SkippedGroup(state: state),
                for (final (index, module) in state.course.modules.indexed)
                  _ModuleSection(
                    index: index,
                    module: module,
                    state: state,
                    currentLesson: _currentLesson,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _openLesson(BuildContext context, String id) => LessonGate.open(
  context,
  lessonId: id,
  kind: LessonKind.school,
  open: () => context.go(Routes.lessonScript(id)),
);

/// O cartão "Continuar": a parte e o número da lição, o título e o resumo.
class _Continue extends StatelessWidget {
  const _Continue({required this.lessonId, required this.state});

  final String lessonId;
  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final texts = state.texts;
    final modules = state.course.modules;
    final part = modules.indexWhere(
      (module) => module.lessons.any((lesson) => lesson.id == lessonId),
    );
    final number = part < 0
        ? 1
        : modules[part].lessons.indexWhere((l) => l.id == lessonId) + 1;
    final fresh =
        state.ongoing == null && state.done == 0 && state.skipped.isEmpty;
    return CourseContinueCard(
      label: l10n.schoolLessonPlace(part < 0 ? 1 : part + 1, number),
      title: texts.lessonTitle(lessonId),
      summary: texts.lessonSummary(lessonId),
      buttonLabel: fresh ? l10n.endgamePartStart : l10n.homeContinue,
      buttonKey: SchoolKeys.continueButton,
      onPressed: () => _openLesson(context, lessonId),
    );
  }
}

/// Uma parte da Escola: "Parte N", o título, quantas lições já foram e os
/// cartões das lições (sem medalha: a Escola não guarda nota).
class _ModuleSection extends StatelessWidget {
  const _ModuleSection({
    required this.index,
    required this.module,
    required this.state,
    required this.currentLesson,
  });

  final GlobalKey currentLesson;
  final int index;
  final CourseModule module;
  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = module.lessons.where((lesson) {
      final status = state.status(lesson.id);
      return status == LessonStatus.completed ||
          status == LessonStatus.skippedByTest;
    }).length;
    return Column(
      key: SchoolKeys.module(module.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        CoursePartHeader(
          label: l10n.schoolModule(index + 1),
          title: state.texts.moduleTitle(module.id),
          count: l10n.coursePartProgress(done, module.lessons.length),
        ),
        // v2_cursos_padrao lista(): 8 entre as lições.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            for (final lesson in module.lessons)
              KeyedSubtree(
                key: state.next == lesson.id ? currentLesson : null,
                child: _LessonTile(lesson: lesson, state: state),
              ),
          ],
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.state});

  final Lesson lesson;
  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final status = state.status(lesson.id);
    final texts = state.texts;
    final tileState = switch (status) {
      LessonStatus.completed ||
      LessonStatus.skippedByTest => CourseItemState.approved,
      LessonStatus.open when state.next == lesson.id => CourseItemState.next,
      LessonStatus.open => CourseItemState.open,
      LessonStatus.locked => CourseItemState.locked,
    };
    void open() {
      if (status == LessonStatus.locked) {
        final blocker = state.blockedBy(lesson.id);
        showLucenaSnackBar(
          context,
          l10n.schoolLocked(blocker == null ? '' : texts.lessonTitle(blocker)),
        );
        return;
      }
      _openLesson(context, lesson.id);
    }

    return Semantics(
      button: true,
      label: l10n.schoolLessonLabel(texts.lessonTitle(lesson.id), status.name),
      excludeSemantics: true,
      child: CourseItemTile(
        key: SchoolKeys.lesson(lesson.id),
        state: tileState,
        title: texts.lessonTitle(lesson.id),
        summary: texts.lessonSummary(lesson.id),
        // CompAulaTile dominada: o selo "Já domina" da pulada pelo teste.
        tags: [
          if (status == LessonStatus.skippedByTest)
            InfoChip(
              icon: Icons.verified_rounded,
              label: l10n.placementMastered,
              background: colors.secondaryContainer,
              foreground: colors.onSecondaryContainer,
            ),
        ],
        onTap: open,
      ),
    );
  }
}

/// As aulas que o teste mostrou que o jogador já sabe, num cartão
/// recolhido: "Rever as aulas anteriores" abre a lista, cada aula com o
/// motivo (acertou no teste ou pelo nível) e podendo ser feita.
class _SkippedGroup extends StatelessWidget {
  const _SkippedGroup({required this.state});

  final SchoolState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<SchoolCubit>();
    final lessons = [
      for (final lesson in state.course.lessons)
        if (state.skipped[lesson.id] case final reason?) (lesson, reason),
    ];
    return Card(
      key: SchoolKeys.skippedGroup,
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: AppMotion.of(context).component,
        curve: AppMotion.move,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: colors.onPrimary,
                      size: AppIconSize.standard,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.schoolKnownTitle,
                                style: context.cardTitle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Quantas aulas.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppShape.full,
                                ),
                              ),
                              child: Text(
                                '${lessons.length}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.schoolKnownBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.showSkipped) ...[
                const SizedBox(height: AppSpacing.md),
                for (final (lesson, reason) in lessons)
                  _KnownLesson(
                    key: SchoolKeys.skippedLesson(lesson.id),
                    title: state.texts.lessonTitle(lesson.id),
                    reason: reason,
                    onTap: () => LessonGate.open(
                      context,
                      lessonId: lesson.id,
                      kind: LessonKind.school,
                      open: () => context.go(Routes.lessonScript(lesson.id)),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                key: SchoolKeys.reviewSkipped,
                onPressed: cubit.toggleSkipped,
                icon: AnimatedRotation(
                  turns: state.showSkipped ? 0.5 : 0,
                  duration: AppMotion.of(context).state,
                  child: const Icon(Icons.expand_more_rounded),
                ),
                label: Text(
                  state.showSkipped
                      ? l10n.schoolHideSkipped
                      : l10n.schoolReviewSkipped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma aula que o jogador já sabe: o título e o motivo, num selo.
class _KnownLesson extends StatelessWidget {
  const _KnownLesson({
    required this.title,
    required this.reason,
    required this.onTap,
    super.key,
  });

  final String title;
  final SkipReason reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final confirmed = reason == SkipReason.confirmed;
    return InkWell(
      borderRadius: BorderRadius.circular(AppShape.small),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              confirmed
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              size: AppIconSize.button,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    confirmed
                        ? l10n.schoolSkippedConfirmed
                        : l10n.schoolSkippedLikely,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.play_arrow_rounded,
              size: AppIconSize.button,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// A entrada dos desafios das estrelas: pegar as estrelas com cada peça
/// contra o relógio. As seis peças em figurino convidam a jogar.
class _ChallengesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: InkWell(
        key: SchoolKeys.challengesButton,
        borderRadius: BorderRadius.circular(AppShape.large),
        onTap: () => context.push(Routes.starChallenges),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.goldColor,
                  size: AppIconSize.large,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.starChallengesTitle,
                      style: context.cardTitle?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.starChallengesBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '♖ ♗ ♘ ♕ ♔ ♙',
                      style: TextStyle(
                        fontFamily: Figurine.fontFamily,
                        fontSize: 22,
                        letterSpacing: 2,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: colors.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
