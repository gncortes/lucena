import 'package:flutter/material.dart';

import '../../core/theme/app_shape.dart';
import '../../core/theme/canvas_symbols.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/use_cases/training/opening_parts.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../core/keys/training_keys.dart';
import '../../core/widgets/course/compact_course_action.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';
import '../../course_guide/widgets/course_guide_copy.dart';

/// Detail in the course shell; the selected profile retains its own saved tracks.
class TrainingOpeningProgressScreen extends StatefulWidget {
  const TrainingOpeningProgressScreen({
    required this.onTrain,
    this.onLesson,
    super.key,
  });
  final void Function(String lessonId, String partId) onTrain;
  final ValueChanged<TrainingLesson>? onLesson;
  @override
  State<TrainingOpeningProgressScreen> createState() => _ProgressState();
}

class _ProgressState extends State<TrainingOpeningProgressScreen> {
  String? _selected;
  bool _changing = false;
  Future<void> _changeProfile() async {
    final cubit = context.read<CourseGuideCubit>();
    if (_changing || cubit.state.saving) return;
    setState(() => _changing = true);
    final saved = cubit.state.training!;
    final t = context.l10n;
    final current = saved.openingProfile == 'solido'
        ? t.trainingProfileSolid
        : t.trainingProfileAggressive;
    final target = saved.openingProfile == 'solido'
        ? t.trainingProfileAggressive
        : t.trainingProfileSolid;
    final parts = cubit.state.resources!.lessons
        .map((l) => l.partId)
        .toSet()
        .toList();
    final next = cubit.state.nextLesson;
    final part = courseGuideRoman(
      next == null ? parts.length : parts.indexOf(next.partId) + 1,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titleTextStyle: Theme.of(context).textTheme.titleLarge
            ?.copyWith(height: 1.4, letterSpacing: 0),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(height: 20 / 14, letterSpacing: 0),
        // The 48 dp touch targets add 6 dp above/below the Canvas's 36 dp
        // visual button row; those 6 dp come from its surrounding whitespace.
        actionsPadding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
        title: Text(t.trainingProfileChangeTitle(target)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(t.trainingProfileChangeBody(target, part)),
            Text(t.trainingProfileChangeSaved(current)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.trainingProfileCancel),
          ),
          TextButton(
            key: TrainingKeys.openingProfile('confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.trainingProfileChange),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await cubit.selectOpeningProfile(
        saved.openingProfile == 'solido' ? 'agressivo' : 'solido',
      );
      if (mounted && success) setState(() => _selected = null);
    }
    if (mounted) setState(() => _changing = false);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final saved = state.training, resources = state.resources;
      if (saved == null || resources == null) return const SizedBox.shrink();
      final tracks = activeOpeningTracks(saved, resources).toList();
      final selected =
          tracks.where((e) => e.key == _selected).firstOrNull ??
          tracks.firstOrNull;
      final t = context.l10n;
      if (tracks.isEmpty) {
        final lessons = resources.lessons
            .where(
              (l) =>
                  l.kind == TrainingLessonKind.opening &&
                  l.published &&
                  (l.openingProfile ?? openingProfileForLesson(l.id)) ==
                      saved.openingProfile,
            )
            .toList();
        String slot(TrainingLesson lesson) =>
            lesson.id.split('.').last.replaceAll(RegExp(r'\d+$'), '');
        final slots = lessons.map(slot).toSet().toList();
        final selectedSlot = slots.contains(_selected)
            ? _selected
            : slots.firstOrNull;
        final selectedLessons = lessons
            .where((l) => slot(l) == selectedSlot)
            .toList();
        String title(String id) =>
            resources
                .openings[lessons.firstWhere((l) => slot(l) == id).id]
                ?.firstOrNull
                ?.title ??
            lessons.firstWhere((l) => slot(l) == id).title;
        final profile = saved.openingProfile == 'solido'
            ? t.trainingProfileSolid
            : t.trainingProfileAggressive;
        final previous = saved.openingProfile == 'solido'
            ? t.trainingProfileAggressive
            : t.trainingProfileSolid;
        final parts = resources.lessons.map((l) => l.partId).toSet().toList();
        final from = parts.indexOf(saved.openingProfileStartPart);
        return ListView(
          key: TrainingKeys.openingProgressScreen,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.trainingRepertoire(profile),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          t.trainingProfileNoPractice,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                CompactCourseAction(
                  key: TrainingKeys.openingProfile('change'),
                  onPressed: state.saving ? null : _changeProfile,
                  label: t.trainingProfileChange,
                ),
              ],
            ),
            if (saved.openingProfileStartPart.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppShape.card),
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(
                      CanvasSymbols.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Expanded(
                      child: Text(
                        t.trainingProfileSwitched(previous, profile),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  for (final id in slots)
                    ChoiceChip(
                      key: TrainingKeys.openingPart(id),
                      selected: id == selectedSlot,
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppShape.small),
                      ),
                      label: Text(
                        id == 'others' || id == 'othersAggr'
                            ? t.trainingOpeningChipOthers
                            : title(id),
                      ),
                      onSelected: (_) => setState(() => _selected = id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (selectedLessons.isNotEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.trainingOpeningSideTitle(
                          title(selectedSlot!),
                          resources
                                      .openings[selectedLessons.first.id]
                                      ?.firstOrNull
                                      ?.black ==
                                  true
                              ? 'black'
                              : 'white',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final lesson in selectedLessons)
                        InkWell(
                          key: TrainingKeys.openingPart(lesson.id),
                          onTap: widget.onLesson == null
                              ? null
                              : () => widget.onLesson!(lesson),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              spacing: 8,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    courseGuideRoman(
                                      parts.indexOf(lesson.partId) + 1,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color:
                                              parts.indexOf(lesson.partId) <
                                                  from
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    lesson.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          height: 20 / 14,
                                          letterSpacing: 0,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  parts.indexOf(lesson.partId) < from
                                      ? t.courseGuideTabCatalog
                                      : parts.indexOf(lesson.partId) == from
                                      ? t.trainingCourseNext
                                      : t.trainingPartLabel(
                                          courseGuideRoman(
                                            parts.indexOf(lesson.partId) + 1,
                                          ),
                                        ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        letterSpacing: 0,
                                        color:
                                            parts.indexOf(lesson.partId) == from
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        fontWeight:
                                            parts.indexOf(lesson.partId) == from
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }
      return ListView(
        key: TrainingKeys.openingProgressScreen,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.trainingRepertoire(
                        saved.openingProfile == 'solido'
                            ? t.trainingProfileSolid
                            : t.trainingProfileAggressive,
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      t.trainingRepertoireNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CompactCourseAction(
                key: TrainingKeys.openingProfile('change'),
                onPressed: state.saving ? null : _changeProfile,
                label: t.trainingProfileChange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (final entry in tracks)
                  SizedBox(
                    height: 28,
                    child: ChoiceChip(
                      key: TrainingKeys.openingPart(entry.key),
                      selected: entry.key == selected?.key,
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppShape.small),
                      ),
                      label: Text(switch (resources
                          .openings[entry.key]!
                          .first
                          .openingId) {
                        'london' => t.trainingOpeningChipLondon,
                        'slav' => t.trainingOpeningChipSlav,
                        'others' || 'othersAggr' => t.trainingOpeningChipOthers,
                        _ => resources.openings[entry.key]!.first.title,
                      }),
                      onSelected: (_) => setState(() => _selected = entry.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (selected != null)
            Builder(
              builder: (context) {
                final bank = resources.openings[selected.key]!;
                final track = selected.value;
                final next = bank
                    .where((p) => !track.doneTrechos.containsKey(p.id))
                    .firstOrNull;
                final done = bank
                    .where((p) => track.doneTrechos.containsKey(p.id))
                    .length;
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bank.first.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    bank.first.black
                                        ? t.sideBlack
                                        : t.sideWhite,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              t.trainingOpeningCount(done, bank.length),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        for (final (i, part) in bank.indexed)
                          Builder(
                            builder: (context) {
                              final results = track.firstTry[part.id];
                              final completed = track.doneTrechos.containsKey(
                                part.id,
                              );
                              final score = results == null || results.isEmpty
                                  ? 0
                                  : (100 *
                                            results.where((v) => v).length /
                                            results.length)
                                        .round();
                              final color = !completed
                                  ? part == next
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                  : openingAccuracyColor(score);
                              return SizedBox(
                                height: 48,
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    Icon(
                                      completed
                                          ? score == 100
                                                ? Icons.check_circle_outline
                                                : Icons.replay
                                          : Icons.radio_button_unchecked,
                                      color: color,
                                    ),
                                    Expanded(
                                      child: Text(t.trainingPartName(i + 1)),
                                    ),
                                    if (completed)
                                      Text(
                                        '$score %',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(color: color),
                                      ),
                                    if (completed && score < 100)
                                      CompactCourseAction(
                                        key: TrainingKeys.openingPart(part.id),
                                        filled: true,
                                        visualHeight: 24,
                                        onPressed: () => widget.onTrain(
                                          selected.key,
                                          part.id,
                                        ),
                                        label: t.trainingPartRedo,
                                      )
                                    else if (part.id == next?.id)
                                      TextButton(
                                        key: TrainingKeys.openingPart(part.id),
                                        onPressed: () => widget.onTrain(
                                          selected.key,
                                          part.id,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(t.trainingPartPractice),
                                            const Icon(Icons.chevron_right),
                                          ],
                                        ),
                                      )
                                    else if (!completed)
                                      Text(
                                        t.trainingPartPending,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: color),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      );
    },
  );
}

Color openingAccuracyColor(int percent) => percent == 100
    ? AppColors.trainingDayCorrect
    : percent >= 70
    ? AppColors.trainingMasteryDeveloping
    : AppColors.trainingDayWrong;
