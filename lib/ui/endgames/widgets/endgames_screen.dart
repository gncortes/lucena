import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/ads_state.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/survey.dart';
import '../../../routing/routes.dart';
import '../../core/ads/lesson_gate.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/course/course_continue_card.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/course/course_part_header.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../../survey/widgets/survey_invite_card.dart';
import '../../would_pay/widgets/would_pay_invite_card.dart';
import '../view_models/endgames_cubit.dart';
import 'endgames_filters.dart';
import 'grade_widgets.dart';

/// O Curso de finais (canvas `PropV2FinaisCurso`, padrão T1 dos cursos): o
/// cartão "Continuar" no topo e as partes com os capítulos, cada um com a
/// medalha da nota já alcançada.
class EndgamesScreen extends StatelessWidget {
  const EndgamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: EndgamesKeys.screen,
      appBar: LucenaAppBar(
        title: Text(l10n.endgamesTitle),
        actions: [
          BlocBuilder<EndgamesCubit, EndgamesState>(
            buildWhen: (before, after) => before.ready != after.ready,
            builder: (context, state) => state.ready
                ? const EndgamesFilterButton()
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocBuilder<EndgamesCubit, EndgamesState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          final next = state.next;
          return ListView(
            // v2_cursos_padrao: corpo 8 16 0 16; o fim respira 32.
            padding: scrollPadding(
              context,
              left: AppSpacing.lg,
              top: AppSpacing.sm,
              right: AppSpacing.lg,
              bottom: AppSpacing.xxl,
            ),
            children: [
              if (next != null) _Continue(lessonId: next, state: state),
              if (!state.filter.isEmpty) EndgamesActiveFilters(state: state),
              for (final section in state.sections)
                _Section(section: section, state: state),
              if (state.filteredLessons.isEmpty && state.total > 0)
                const EndgamesFiltersEmpty(),
              // O "Você pagaria?" e o "Sua opinião", depois do último cartão.
              const SizedBox(height: AppSpacing.lg),
              const WouldPayInviteCard(),
              const SurveyInviteCard(
                kind: SurveyKind.endgames,
                source: SurveyInviteSource.trail,
              ),
            ],
          );
        },
      ),
    );
  }
}

void _openLesson(BuildContext context, String id) => LessonGate.open(
  context,
  lessonId: id,
  kind: LessonKind.endgame,
  open: () => context.push(Routes.endgameLesson(id)),
);

/// O cartão "Continuar": a parte e o número do capítulo, o título e o resumo.
class _Continue extends StatelessWidget {
  const _Continue({required this.lessonId, required this.state});

  final String lessonId;
  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final texts = state.texts;
    final place = state.place(lessonId);
    final module = place == null
        ? ''
        : texts.plain('endgames.module.${place.$1.id}') ?? place.$1.id;
    final fresh =
        state.passed == 0 && state.status(lessonId) == EndgameLessonStatus.open;
    return CourseContinueCard(
      label: l10n.courseChapterPlace(module, place?.$2 ?? 1),
      title: texts.lessonTitle(lessonId),
      summary: texts.lessonSummary(lessonId),
      buttonLabel: fresh ? l10n.endgamePartStart : l10n.homeContinue,
      buttonKey: EndgamesKeys.continueButton,
      onPressed: () => _openLesson(context, lessonId),
    );
  }
}

/// Uma parte do curso: um módulo da trilha ou uma faixa de dificuldade.
class _Section extends StatelessWidget {
  const _Section({required this.section, required this.state});

  final EndgameSection section;
  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final module = section.module;
    final level = section.level;
    final lessons = section.lessons;
    final title = module != null
        ? state.texts.plain('endgames.module.${module.id}') ?? module.id
        : level == null
        ? l10n.endgamesLevelNone
        : l10n.endgamesLevelSection(level.name(l10n), level.range(l10n));
    final passed = lessons
        .where(
          (lesson) => state.status(lesson.id) == EndgameLessonStatus.passed,
        )
        .length;
    return Padding(
      key: module != null
          ? EndgamesKeys.module(module.id)
          : EndgamesKeys.level(level == null ? 'none' : EnumName(level).name),
      // v2_cursos_padrao: 12 entre os blocos.
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          CoursePartHeader(
            title: title,
            count: l10n.coursePartProgress(passed, lessons.length),
          ),
          // v2_cursos_padrao lista(): 8 entre os capítulos.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              for (final lesson in lessons)
                _LessonTile(lesson: lesson, state: state),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.state});

  final EndgameLesson lesson;
  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = state.status(lesson.id);
    final texts = state.texts;
    final medal = state.medal(lesson.id);
    final tileState = switch (status) {
      EndgameLessonStatus.passed => CourseItemState.approved,
      _ when state.next == lesson.id => CourseItemState.next,
      EndgameLessonStatus.started => CourseItemState.started,
      EndgameLessonStatus.open => CourseItemState.open,
    };
    return Semantics(
      button: true,
      label: l10n.endgamesLessonLabel(
        texts.lessonTitle(lesson.id),
        status.name,
      ),
      excludeSemantics: true,
      child: CourseItemTile(
        key: EndgamesKeys.lesson(lesson.id),
        state: tileState,
        title: texts.lessonTitle(lesson.id),
        summary: texts.lessonSummary(lesson.id),
        // A revisão do conteúdo: reprovada (será refeita) ou em revisão.
        tags: [
          if (lesson.failed || lesson.inReview)
            _ReviewTag(
              key: EndgamesKeys.reviewTag(lesson.id),
              failed: lesson.failed,
            ),
        ],
        medal: medal == null
            ? null
            : GradeMedal(
                key: EndgamesKeys.medal(lesson.id),
                grade: medal,
                size: CourseItemTile.medalSize,
                sideRatio: GradeMedal.compactSideRatio,
              ),
        onTap: () => _openLesson(context, lesson.id),
      ),
    );
  }
}

/// O selo da revisão do conteúdo: ✕ "Reprovada" (o capítulo será refeito) ou
/// "Em revisão".
class _ReviewTag extends StatelessWidget {
  const _ReviewTag({required this.failed, super.key});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InfoChip(
      icon: failed ? Icons.close_rounded : Icons.rate_review_outlined,
      label: failed
          ? context.l10n.endgamesTagFailed
          : context.l10n.endgamesTagInReview,
      background: failed ? colors.errorContainer : colors.secondaryContainer,
      foreground: failed
          ? colors.onErrorContainer
          : colors.onSecondaryContainer,
    );
  }
}
