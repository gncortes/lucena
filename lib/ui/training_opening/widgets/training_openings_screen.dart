import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/opening_trecho_rules.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/course/chapter_lesson_list.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/training_opening_cubit.dart';

/// Navigation belongs to the host guide; this destination has no course branch.
class TrainingOpeningsScreen extends StatelessWidget {
  const TrainingOpeningsScreen({
    required this.repository,
    required this.config,
    required this.now,
    required this.onTrain,
    this.embedded = false,
    super.key,
  });
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final ValueChanged<String> onTrain;
  final bool embedded;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        TrainingOpeningCubit(repository: repository, config: config, now: now)
          ..load(),
    child: BlocBuilder<TrainingOpeningCubit, TrainingOpeningState>(
      builder: (context, state) {
        final l = context.l10n;
        final body = SafeArea(
          top: !embedded,
          child: state.saved == null
              ? Center(
                  child: state.phase == TrainingOpeningPhase.loading
                      ? const CircularProgressIndicator()
                      : Text(l.exerciseMissing),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          spacing: 12,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            Expanded(child: Text(l.trainingOpeningsInfo)),
                          ],
                        ),
                      ),
                    ),
                    for (final entry in state.saved!.openings.entries) ...[
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final bank =
                              state.resources!.openings[entry.key] ?? [];
                          final id = state.goal?.items[entry.key];
                          final index = bank.indexWhere((t) => t.id == id);
                          final done =
                              id != null &&
                              entry.value.doneTrechos[id] ==
                                  state.saved!.day?.date;
                          final available = index >= 0 && !done;
                          final progress = OpeningTrechoRules.currentProgress(
                            entry.value,
                            bank,
                          );
                          final allFirm =
                              bank.isNotEmpty && progress.done == bank.length;
                          final title =
                              state.resources!.lessons
                                  .where((l) => l.id == entry.key)
                                  .firstOrNull
                                  ?.title ??
                              bank.firstOrNull?.title ??
                              l.trainingOpeningsTitle;
                          final colors = Theme.of(context).colorScheme;
                          return ChapterLessonList(
                            key: TrainingKeys.openingCard(entry.key),
                            rows: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: 10,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              if (bank.isNotEmpty)
                                                Text(
                                                  bank.first.black
                                                      ? l.sideBlack
                                                      : l.sideWhite,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          l.trainingOpeningCount(
                                            progress.done,
                                            bank.length,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      spacing: 6,
                                      children: [
                                        for (var i = 0; i < bank.length; i++)
                                          Expanded(
                                            child: Container(
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color:
                                                    entry.value.doneTrechos
                                                        .containsKey(bank[i].id)
                                                    ? AppColors.record
                                                    : available && i == index
                                                    ? colors.primary
                                                    : colors.surface,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppShape.small,
                                                    ),
                                              ),
                                              alignment: Alignment.center,
                                              child:
                                                  entry.value.doneTrechos
                                                      .containsKey(bank[i].id)
                                                  ? Icon(
                                                      Icons.check,
                                                      color: colors.onPrimary,
                                                      size: 16,
                                                    )
                                                  : Text(
                                                      '${i + 1}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                            color:
                                                                available &&
                                                                    i == index
                                                                ? colors
                                                                      .onPrimary
                                                                : colors
                                                                      .onSurfaceVariant,
                                                          ),
                                                    ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (available)
                                      TextButton(
                                        key: TrainingKeys.trainTrecho(
                                          entry.key,
                                        ),
                                        style: TextButton.styleFrom(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () => onTrain(entry.key),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                l.trainingOpeningTrain(
                                                  index + 1,
                                                  bank[index].title,
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right),
                                          ],
                                        ),
                                      ),
                                    if (done || allFirm)
                                      Row(
                                        spacing: 6,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: AppColors.record,
                                            size: 20,
                                          ),
                                          Expanded(
                                            child: Text(
                                              allFirm
                                                  ? l.trainingOpeningAllFirm
                                                  : l.trainingOpeningDoneToday,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: AppColors.record,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
        );
        if (embedded) {
          return KeyedSubtree(key: TrainingKeys.openingsScreen, child: body);
        }
        return Scaffold(
          key: TrainingKeys.openingsScreen,
          appBar: LucenaAppBar(title: Text(l.trainingOpeningsTitle)),
          body: body,
        );
      },
    ),
  );
}
