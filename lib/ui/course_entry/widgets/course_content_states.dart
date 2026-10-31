import 'dart:math' as math;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_shape.dart';
import '../../core/theme/canvas_symbols.dart';

import '../../../domain/models/lesson_content.dart';
import '../../core/keys/training_entry_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/theme/app_icon_size.dart';

class CourseDownloadSkeleton extends StatelessWidget {
  const CourseDownloadSkeleton({this.chapter = false, super.key});
  final bool chapter;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: TrainingEntryKeys.loading,
    builder: (context, constraints) {
      if (chapter) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: SkeletonBlock(height: 76, radius: 16),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SkeletonBlock(width: 160, height: 40, radius: 999),
              ),
            ),
            SizedBox.square(
              dimension: math.min(
                constraints.maxWidth,
                math.max(0, constraints.maxHeight - 208),
              ),
              child: const SkeletonBlock(height: double.infinity, radius: 8),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBlock(height: 52, radius: 999),
            ),
            const SizedBox(height: 8),
          ],
        );
      }
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SkeletonBlock(height: 168, radius: 16),
              const SizedBox(height: 24),
              for (var i = 0; i < 4; i++) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    spacing: 12,
                    children: [
                      SkeletonBlock(width: 40, height: 40, radius: 999),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            SkeletonBlock(height: 14, radius: 999),
                            SkeletonBlock(width: 120, height: 12, radius: 999),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const SkeletonBlock(height: 52, radius: 999),
            ],
          ),
        ),
      );
    },
  );
}

class CourseDownloadFailure extends StatelessWidget {
  const CourseDownloadFailure({
    required this.failure,
    required this.onRetry,
    this.chapter = false,
    super.key,
  });
  final Object? failure;
  final VoidCallback onRetry;
  final bool chapter;
  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final noSpace = failure is LessonContentStorageUnavailable;
    final offline = failure is LessonContentNetworkUnavailable;
    final size = noSpace
        ? ((failure as LessonContentStorageUnavailable).bytes / (1024 * 1024))
              .ceil()
              .toString()
        : '0';
    final message = noSpace
        ? chapter
              ? t.trainingDownloadStorage(size)
              : t.trainingDownloadCourseStorage(size)
        : !chapter && offline
        ? t.trainingDownloadCourseOffline
        : chapter && offline
        ? t.trainingDownloadChapterOffline
        : chapter
        ? t.trainingDownloadChapterError
        : t.trainingDownloadCourseError;
    return Center(
      key: TrainingEntryKeys.failure,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                style: EmptyStateStyle.error,
                iconFill: 1,
                icon: noSpace
                    ? Icons.sd_card_alert
                    : offline
                    ? CanvasSymbols.cloudOff
                    : CanvasSymbols.syncProblem,
                usePrimaryErrorColor: true,
                message: message,
                actionLabel: t.lessonRetry,
                actionKey: TrainingEntryKeys.retry,
                onAction: onRetry,
              ),
              if (noSpace &&
                  Theme.of(context).platform == TargetPlatform.android)
                TextButton.icon(
                  key: TrainingEntryKeys.storage,
                  onPressed: () async {
                    try {
                      await const AndroidIntent(
                        action: 'android.settings.INTERNAL_STORAGE_SETTINGS',
                      ).launch();
                    } on Object {
                      // Keep the retry screen, including on devices without a handler.
                    }
                  },
                  icon: const Icon(CanvasSymbols.folderOpen, fill: 1),
                  label: Text(t.trainingDownloadOpenStorage),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Embedded in Metas: other goals and their actions remain usable.
class TrainingGoalsOfflineNotice extends StatelessWidget {
  const TrainingGoalsOfflineNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    key: TrainingEntryKeys.offline,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppShape.card),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_off,
          size: AppIconSize.notice,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.trainingGoalsOffline,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 14, height: 20 / 14, letterSpacing: 0),
          ),
        ),
      ],
    ),
  );
}

/// The existing guide supplies its AppBar, tabs, study tips and Metas action.
class TrainingUnpublishedNotice extends StatelessWidget {
  const TrainingUnpublishedNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    key: TrainingEntryKeys.unpublished,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppShape.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.hourglass_top,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.trainingUnpublishedTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.trainingUnpublishedBody,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}
