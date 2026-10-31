import '../../core/widgets/course/course_navigation_bar.dart';
import '../../../domain/use_cases/training/training_goal_counts.dart';
import '../../../domain/use_cases/training/needs_opening_profile.dart';
import '../../core/keys/training_profile_keys.dart';

import 'package:flutter/material.dart';

import '../../core/theme/canvas_symbols.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../core/keys/course_guide_keys.dart';
import '../../core/keys/training_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/course/course_continue_card.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/course/course_part_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/course_guide_cubit.dart';
import 'course_guide_copy.dart';
import '../../course_entry/widgets/course_content_states.dart';

class CourseGuideScreen extends StatelessWidget {
  const CourseGuideScreen({
    required this.onBack,
    required this.onPlan,
    required this.onHelp,
    required this.onWelcomeContinue,
    required this.onLesson,
    required this.onChapter,
    required this.goalsBuilder,
    required this.progressBuilder,
    this.onLevelTest,
    this.centerTitle = false,
    this.showHeaderActions = true,
    this.bodyOverride,
    this.titleOverride,
    this.onTabChanged,
    this.onStartPilares,
    super.key,
  });
  final VoidCallback onBack, onPlan, onHelp, onWelcomeContinue;
  final VoidCallback? onLevelTest;
  final VoidCallback? onStartPilares;
  final ValueChanged<TrainingLesson> onLesson;
  final ValueChanged<String> onChapter;
  final WidgetBuilder goalsBuilder, progressBuilder;
  final bool centerTitle, showHeaderActions;
  final Widget? bodyOverride;
  final String? titleOverride;
  final ValueChanged<CourseGuideTab>? onTabChanged;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<CourseGuideCubit, CourseGuideState>(
    listenWhen: (before, after) =>
        !before.failed && after.failed && after.training != null,
    listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
    ),
    builder: (context, state) {
      final cubit = context.read<CourseGuideCubit>();
      final config = cubit.config;
      final t = context.l10n;
      final training = state.training;
      final tab = training?.tab ?? CourseGuideTab.lesson;
      final title =
          titleOverride ??
          switch (tab) {
            CourseGuideTab.lesson => courseGuideCopy(context, config.titleKey),
            CourseGuideTab.goals => t.trainingGoalsTitle,
            CourseGuideTab.progress => t.courseGuideTabProgress,
            CourseGuideTab.catalog => t.courseGuideTabCatalog,
          };
      return Scaffold(
        key: CourseGuideKeys.screen,
        appBar: LucenaAppBar(
          centerTitle: centerTitle,
          toolbarHeight: 64,
          titleSpacing: 0,
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            key: CourseGuideKeys.back,
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(CanvasSymbols.arrowBack),
          ),
          actions: showHeaderActions
              ? [
                  IconButton(
                    key: CourseGuideKeys.planAction,
                    onPressed: state.saving ? null : onPlan,
                    tooltip: t.courseGuidePlanAction,
                    icon: const Icon(CanvasSymbols.editCalendar),
                  ),
                  if (config.hasHelp)
                    IconButton(
                      key: CourseGuideKeys.helpAction,
                      onPressed: onHelp,
                      tooltip: t.courseGuideHelpAction,
                      icon: const Icon(CanvasSymbols.info),
                    ),
                ]
              : null,
        ),
        body: SafeArea(
          top: false,
          child: state.loading
              ? const CourseDownloadSkeleton()
              : state.failed && training == null
              ? Center(
                  child: TextButton(
                    onPressed: cubit.load,
                    child: Text(t.lessonRetry),
                  ),
                )
              : !(state.resources?.lessons.any((lesson) => lesson.visible) ??
                    false)
              ? Center(
                  child: EmptyState(
                    icon: Icons.auto_stories_outlined,
                    message: t.lessonsUnavailableMessage,
                  ),
                )
              : bodyOverride ??
                    switch (tab) {
                      CourseGuideTab.lesson =>
                        training?.onboardingDone == true
                            ? _LessonTab(
                                state: state,
                                onLesson: onLesson,
                                onStartPilares: onStartPilares,
                              )
                            : _WelcomeTab(onContinue: onWelcomeContinue),
                      CourseGuideTab.goals => goalsBuilder(context),
                      CourseGuideTab.progress => progressBuilder(context),
                      CourseGuideTab.catalog => _CatalogTab(
                        state: state,
                        onChapter: onChapter,
                        onLesson: onLesson,
                        onLevelTest: onLevelTest,
                      ),
                    },
        ),
        bottomNavigationBar: CourseNavigationBar(
          selectedIndex: tab.index,
          remaining: training == null
              ? 0
              : trainingGoalCounts(training).remaining,
          onDestinationSelected: state.saving
              ? null
              : (index) async {
                  final tab = CourseGuideTab.values[index];
                  if (await cubit.selectTab(tab)) onTabChanged?.call(tab);
                },
        ),
      );
    },
  );
}

class _WelcomeTab extends StatelessWidget {
  const _WelcomeTab({required this.onContinue});
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    final config = context.read<CourseGuideCubit>().config;
    final t = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  courseGuideCopy(context, config.welcomeKeys[0]),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    height: 26 / 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  courseGuideCopy(context, config.welcomeKeys[1]),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  t.courseGuideTabsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final (icon, title, body) in [
                  (
                    Icons.school_outlined,
                    t.courseGuideTabLesson,
                    config.welcomeKeys.length > 2
                        ? courseGuideCopy(context, config.welcomeKeys[2])
                        : t.courseGuideTabsLesson,
                  ),
                  (
                    Icons.task_alt,
                    t.courseGuideTabGoals,
                    config.welcomeKeys.length > 3
                        ? courseGuideCopy(context, config.welcomeKeys[3])
                        : t.courseGuideTabsGoals,
                  ),
                  (
                    Icons.insights,
                    t.courseGuideTabProgress,
                    config.welcomeKeys.length > 4
                        ? courseGuideCopy(context, config.welcomeKeys[4])
                        : t.courseGuideTabsProgress,
                  ),
                  (
                    Icons.menu_book_outlined,
                    t.courseGuideTabCatalog,
                    config.welcomeKeys.length > 5
                        ? courseGuideCopy(context, config.welcomeKeys[5])
                        : t.courseGuideTabsCatalog,
                  ),
                ])
                  Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      Expanded(
                        child: Text(
                          t.courseGuideTabIntro(title, body),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: CourseGuideKeys.continueButton,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(kButtonHeight),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: onContinue,
          child: Text(t.homeContinue),
        ),
      ],
    );
  }
}

class _LessonTab extends StatelessWidget {
  const _LessonTab({
    required this.state,
    required this.onLesson,
    this.onStartPilares,
  });
  final CourseGuideState state;
  final ValueChanged<TrainingLesson> onLesson;
  final VoidCallback? onStartPilares;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CourseGuideCubit>();
    final lesson = state.nextLesson;
    if (lesson == null) {
      final t = context.l10n;
      if (state.awaitingPublication) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            const TrainingUnpublishedNotice(),
            const SizedBox(height: 12),
            FilledButton(
              key: TrainingKeys.completedPrimary,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kButtonHeight),
              ),
              onPressed: () => cubit.selectTab(CourseGuideTab.goals),
              child: Text(t.trainingViewGoals),
            ),
            const SizedBox(height: 12),
            _studyTips(context, cubit),
          ],
        );
      }
      final school =
          cubit.config.progressKind == TrainingProgressKind.modulesAndPieces;
      return ListView(
        key: TrainingKeys.completedCourse,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    spacing: 16,
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.trainingDayCorrect,
                      ),
                      Expanded(
                        child: Text(
                          school
                              ? t.trainingEscolaCompletedTitle
                              : t.trainingPilaresCompletedTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    school
                        ? t.trainingEscolaCompletedBody
                        : t.trainingPilaresCompletedBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: TrainingKeys.completedPrimary,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kButtonHeight),
            ),
            onPressed: school
                ? onStartPilares
                : () => cubit.selectTab(CourseGuideTab.goals),
            child: Text(school ? t.trainingStartPilares : t.trainingViewGoals),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: TrainingKeys.completedCatalog,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(kButtonHeight),
            ),
            icon: const Icon(Icons.menu_book),
            onPressed: () => cubit.selectTab(CourseGuideTab.catalog),
            label: Text(t.trainingViewCatalog),
          ),
        ],
      );
    }
    final t = context.l10n;
    final modules =
        cubit.config.progressKind == TrainingProgressKind.modulesAndPieces;
    final index =
        state.resources!.lessons
            .where(
              (l) =>
                  l.visible &&
                  (modules
                      ? l.groupId == lesson.groupId
                      : l.partId == lesson.partId) &&
                  l.kind != TrainingLessonKind.test,
            )
            .toList()
            .indexOf(lesson) +
        1;
    final partLabel = t.trainingPartLabel(
      courseGuideRoman(
        state.resources!.lessons
                .where((l) => l.visible)
                .map((l) => l.partId)
                .toSet()
                .toList()
                .indexOf(lesson.partId) +
            1,
      ),
    );
    final sectionLabel = modules
        ? t.trainingModuleLabel(
            state.resources!.lessons
                    .where((l) => l.visible)
                    .map((l) => l.groupId)
                    .toSet()
                    .toList()
                    .indexOf(lesson.groupId) +
                1,
          )
        : partLabel;
    final needsProfile = needsOpeningProfile(
      state.training!,
      state.resources!,
      lesson,
    );
    final resumed = state.resumedLesson?.id == lesson.id;
    final resumeStage = state.lessonCheckpoint?.step ?? 0;
    final resumeStageLabel = switch (resumeStage) {
      0 => t.trainingResumeTheory,
      1 => t.trainingResumeDemo,
      _ => t.trainingResumePractice,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        CourseContinueCard(
          key: needsProfile ? TrainingProfileKeys.moment : null,
          label: needsProfile
              ? t.trainingProfileMomentLabel(partLabel)
              : resumed
              ? t.trainingResumeLabel(sectionLabel, index, resumeStageLabel)
              : lesson.kind == TrainingLessonKind.test
              ? sectionLabel
              : t.trainingPartLesson(index, sectionLabel),
          title: needsProfile
              ? t.trainingProfileMomentTitle
              : trainingMasteryLessonTitle(context, lesson),
          summary: needsProfile
              ? t.trainingProfileMomentBody
              : resumed
              ? switch (resumeStage) {
                  0 => t.trainingResumeTheoryBody,
                  1 => t.trainingResumeDemoBody,
                  _ => t.trainingResumePracticeBody,
                }
              : lesson.summary,
          buttonLabel: needsProfile
              ? t.trainingProfileChoose
              : resumed
              ? t.homeContinue
              : state.training!.completedLessons.isEmpty
              ? t.homeHeroStart
              : t.homeContinue,
          buttonKey: CourseGuideKeys.continueButton,
          onPressed: () => onLesson(lesson),
        ),
        const SizedBox(height: 12),
        _studyTips(context, cubit),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: CourseGuideKeys.seeCatalog,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(kButtonHeight),
          ),
          onPressed: () => cubit.selectTab(CourseGuideTab.catalog),
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(t.courseGuideSeeCatalog),
        ),
      ],
    );
  }
}

class _CatalogTab extends StatefulWidget {
  const _CatalogTab({
    required this.state,
    required this.onChapter,
    required this.onLesson,
    this.onLevelTest,
  });
  final CourseGuideState state;
  final VoidCallback? onLevelTest;
  final ValueChanged<String> onChapter;
  final ValueChanged<TrainingLesson> onLesson;
  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  final expanded = <String>{};
  @override
  void initState() {
    super.initState();
    final first = widget.state.resources!.lessons
        .where((l) => l.visible && l.published)
        .firstOrNull;
    if (first != null) expanded.add(first.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.state.resources!.lessons
        .where((l) => l.visible && l.published)
        .toList();
    final completed = widget.state.training!.completedLessons;
    final config = context.read<CourseGuideCubit>().config;
    final modules =
        config.progressKind == TrainingProgressKind.modulesAndPieces;
    final groups = {for (final lesson in data) lesson.groupId: lesson.group};
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        for (final (index, group) in groups.entries.indexed) ...[
          if (!modules || expanded.contains(group.key)) ...[
            if (modules)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text(
                  '${context.l10n.trainingModuleLabel(index + 1)} · ${group.value}'
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    height: 20 / 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              KeyedSubtree(
                key: CourseGuideKeys.chapter(group.key),
                child: CoursePartHeader(
                  label: context.l10n.trainingChapterLabel(index + 1),
                  title: group.value,
                  titleWeight: FontWeight.w500,
                  padding: EdgeInsets.fromLTRB(4, index == 0 ? 0 : 8, 4, 0),
                ),
              ),
            const SizedBox(height: 8),
            for (final (lessonIndex, lesson)
                in data.where((l) => l.groupId == group.key).indexed) ...[
              CourseItemTile(
                key: CourseGuideKeys.chapterLesson(lesson.id),
                state: completed.containsKey(lesson.id)
                    ? CourseItemState.approved
                    : widget.state.nextLesson?.id == lesson.id
                    ? modules
                          ? CourseItemState.next
                          : CourseItemState.started
                    : CourseItemState.open,
                title: modules
                    ? context.l10n.trainingLessonLabel(
                        lessonIndex + 1,
                        lesson.title,
                      )
                    : lesson.kind == TrainingLessonKind.test
                    ? context.l10n.trainingChapterTestTitle
                    : lesson.title,
                summary: modules ? lesson.summary : null,
                onTap: () => widget.onLesson(lesson),
              ),
              const SizedBox(height: 8),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppShape.card),
                child: ListTile(
                  key: CourseGuideKeys.catalogPart(group.key),
                  title: Text(
                    '${context.l10n.trainingModuleLabel(index + 1)} · ${group.value}',
                  ),
                  trailing: const Icon(
                    Icons.expand_more,
                    size: AppIconSize.standard,
                  ),
                  onTap: () => setState(() => expanded.add(group.key)),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

Widget _studyTips(BuildContext context, CourseGuideCubit cubit) {
  final t = context.l10n;
  return Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Text(
            t.courseGuideStudyTips,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final (i, prefix) in cubit.config.tipsKeys.indexed)
            Row(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        courseGuideCopy(context, '${prefix}Title'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        courseGuideCopy(context, '${prefix}Body'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  );
}
