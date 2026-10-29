import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../core/keys/course_guide_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/course/course_continue_card.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/course/course_part_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/placement_test_card.dart';
import '../view_models/course_guide_cubit.dart';
import 'course_guide_copy.dart';

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
    this.bodyOverride,
    this.titleOverride,
    this.onTabChanged,
    super.key,
  });
  final VoidCallback onBack, onPlan, onHelp, onWelcomeContinue;
  final VoidCallback? onLevelTest;
  final ValueChanged<TrainingLesson> onLesson;
  final ValueChanged<String> onChapter;
  final WidgetBuilder goalsBuilder, progressBuilder;
  final Widget? bodyOverride;
  final String? titleOverride;
  final ValueChanged<CourseGuideTab>? onTabChanged;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final cubit = context.read<CourseGuideCubit>();
      final config = cubit.config;
      final t = context.l10n;
      final training = state.training;
      final tab = training?.tab ?? CourseGuideTab.lesson;
      final labels = [
        t.courseGuideTabLesson,
        t.courseGuideTabGoals,
        t.courseGuideTabProgress,
        t.courseGuideTabCatalog,
      ];
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
          centerTitle: false,
          toolbarHeight: 64,
          titleSpacing: 0,
          title: Text(title),
          leading: BackButton(onPressed: onBack),
          actions: [
            IconButton(
              key: CourseGuideKeys.planAction,
              onPressed: state.saving ? null : onPlan,
              tooltip: t.courseGuidePlanAction,
              icon: const Icon(Icons.edit_calendar_outlined),
            ),
            if (config.hasHelp)
              IconButton(
                key: CourseGuideKeys.helpAction,
                onPressed: onHelp,
                tooltip: t.courseGuideHelpAction,
                icon: const Icon(Icons.info_outline),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
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
                            ? _LessonTab(state: state, onLesson: onLesson)
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
        bottomNavigationBar: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: NavigationBar(
            height: 78,
            selectedIndex: tab.index,
            onDestinationSelected: state.saving
                ? null
                : (index) async {
                    final tab = CourseGuideTab.values[index];
                    if (await cubit.selectTab(tab)) onTabChanged?.call(tab);
                  },
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerLowest,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => Theme.of(context).textTheme.labelMedium?.copyWith(
                color: states.contains(WidgetState.selected)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
            destinations: [
              for (final (i, icon) in [
                Icons.school_outlined,
                Icons.task_alt,
                Icons.insights,
                Icons.menu_book_outlined,
              ].indexed)
                NavigationDestination(
                  key: CourseGuideKeys.tab(CourseGuideTab.values[i].name),
                  label: labels[i],
                  icon: i == 1
                      ? Badge(
                          key: CourseGuideKeys.goalsBadge,
                          isLabelVisible: (training?.day?.remaining ?? 0) > 0,
                          label: Text(
                            (training?.day?.remaining ?? 0).toString(),
                          ),
                          child: Icon(
                            icon,
                            color: i == tab.index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          icon,
                          color: i == tab.index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
            ],
          ),
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
            minimumSize: const Size.fromHeight(52),
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
  const _LessonTab({required this.state, required this.onLesson});
  final CourseGuideState state;
  final ValueChanged<TrainingLesson> onLesson;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CourseGuideCubit>();
    final lesson = state.nextLesson;
    if (lesson == null) {
      return const SizedBox.shrink(); // Course completion is outside T85.
    }
    final t = context.l10n;
    final index =
        state.resources!.lessons
            .where(
              (l) =>
                  l.visible &&
                  l.partId == lesson.partId &&
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        CourseContinueCard(
          label: lesson.kind == TrainingLessonKind.test
              ? partLabel
              : t.trainingPartLesson(index, partLabel),
          title: lesson.title,
          summary: lesson.summary,
          buttonLabel: state.training!.completedLessons.isEmpty
              ? t.homeHeroStart
              : t.homeContinue,
          buttonKey: CourseGuideKeys.continueButton,
          onPressed: () => onLesson(lesson),
        ),
        const SizedBox(height: 12),
        Card(
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: CourseGuideKeys.seeCatalog,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
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
    final lesson = widget.state.resources!.lessons.firstWhere((l) => l.visible);
    expanded.add(lesson.partId);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.state.resources!.lessons
        .where((l) => l.visible)
        .toList();
    final config = context.read<CourseGuideCubit>().config;
    final sections = {
      for (final lesson in data) lesson.partId: lesson.partTitle,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (config.hasLevelTest) ...[
          PlacementTestCard(
            label: context.l10n.trainingCourseLevelTest,
            onTap: () => widget.onLevelTest?.call(),
            tapKey: CourseGuideKeys.levelTest,
          ),
          const SizedBox(height: 12),
        ],
        for (final (index, part) in sections.entries.indexed) ...[
          if (expanded.contains(part.key)) ...[
            CoursePartHeader(
              label: context.l10n.trainingPartLabel(
                courseGuideRoman(index + 1),
              ),
              title: part.value,
              count: context.l10n.trainingCount(
                _chapters(data, part.key).length,
                _chapters(
                  data,
                  part.key,
                ).where((id) => _status(id) == CourseItemState.approved).length,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in {
              for (final l in data.where((l) => l.partId == part.key))
                l.groupId: l.group,
            }.entries) ...[
              CourseItemTile(
                key: CourseGuideKeys.chapter(entry.key),
                state: _status(entry.key),
                title: context.l10n.trainingChapterTitle(
                  _chapters(data, part.key).indexOf(entry.key) + 1,
                  entry.value,
                ),
                summary: data
                    .where(
                      (l) =>
                          l.groupId == entry.key &&
                          l.kind != TrainingLessonKind.test,
                    )
                    .map((l) => l.title)
                    .join(', '),
                onTap: () => widget.onChapter(entry.key),
              ),
              const SizedBox(height: 8),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppShape.large),
                child: ListTile(
                  key: CourseGuideKeys.catalogPart(part.key),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.trainingPartLabel(
                          courseGuideRoman(index + 1),
                        ),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Text(part.value),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.expand_more,
                    size: AppIconSize.standard,
                  ),
                  onTap: () => setState(() => expanded.add(part.key)),
                ),
              ),
            ),
        ],
      ],
    );
  }

  List<String> _chapters(List<TrainingLesson> lessons, String part) => lessons
      .where((l) => l.partId == part)
      .map((l) => l.groupId)
      .toSet()
      .toList();

  CourseItemState _status(String chapter) {
    final lessons = widget.state.resources!.lessons
        .where((l) => l.groupId == chapter)
        .toList();
    final done = lessons
        .where((l) => widget.state.training!.completedLessons.containsKey(l.id))
        .length;
    return done == lessons.length
        ? CourseItemState.approved
        : done > 0
        ? CourseItemState.started
        : CourseItemState.open;
  }
}
