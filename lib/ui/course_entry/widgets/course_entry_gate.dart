import '../../core/widgets/course/course_navigation_bar.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../data/repositories/training/course_download_repository.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../routing/routes.dart';
import '../../account/view_models/account_cubit.dart';
import '../../account/widgets/account_flow.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/training_entry_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../course_guide/widgets/course_guide_copy.dart';
import '../view_models/course_entry_cubit.dart';
import 'course_content_states.dart';

Widget _backButton(BuildContext context) => BackButton(
  key: TrainingEntryKeys.back,
  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
);

/// Creates the course subtree only after authentication and a complete package.
class CourseEntryGate extends StatelessWidget {
  const CourseEntryGate({
    required this.config,
    required this.child,
    this.chapterId,
    this.title,
    super.key,
  });
  final TrainingCourseConfig config;
  final Widget child;
  final String? chapterId, title;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => CourseEntryCubit(
      accounts: context.read<AccountRepository>(),
      downloads: context.read<CourseDownloadRepository>(),
      characters: context.read<CharacterRepository>(),
      config: config,
      chapterId: chapterId,
    )..start(),
    child: BlocBuilder<CourseEntryCubit, CourseEntryState>(
      builder: (context, state) {
        if (state.phase == CourseEntryPhase.ready) return child;
        final courseTitle = title ?? courseGuideCopy(context, config.titleKey);
        if (state.phase == CourseEntryPhase.account) {
          return BlocProvider(
            create: (context) => AccountCubit(
              context.read<AccountRepository>(),
              sync: context.read<SyncScheduler>(),
              analytics: context.analytics,
              campaigns: context.campaigns,
            ),
            child: _AccountEntry(title: courseTitle, entry: state),
          );
        }
        return Scaffold(
          appBar: LucenaAppBar(
            toolbarHeight: 64,
            leading: _backButton(context),
            title: Text(
              courseTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(
            child: state.phase == CourseEntryPhase.downloading
                ? CourseDownloadSkeleton(chapter: chapterId != null)
                : CourseDownloadFailure(
                    failure: state.failure,
                    chapter: chapterId != null,
                    onRetry: () => context.read<CourseEntryCubit>().retry(),
                  ),
          ),
          bottomNavigationBar: chapterId != null
              ? null
              : const CourseNavigationBar(),
        );
      },
    ),
  );
}

class _AccountEntry extends StatelessWidget {
  const _AccountEntry({required this.title, required this.entry});
  final String title;
  final CourseEntryState entry;
  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final busy = context.select((AccountCubit cubit) => cubit.state.busy);
    return BlocListener<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state.done) unawaited(context.read<CourseEntryCubit>().retry());
        if (state.failure case final failure?) {
          showLucenaSnackBar(context, accountFailureText(t, failure));
        }
      },
      child: Scaffold(
        key: TrainingEntryKeys.account,
        appBar: LucenaAppBar(
          toolbarHeight: 64,
          leading: _backButton(context),
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entry.teacher case final teacher?)
                Theme(
                  data: theme.copyWith(
                    textTheme: theme.textTheme.copyWith(
                      bodyLarge: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  child: TeacherSpeech(
                    key: TrainingEntryKeys.speech,
                    teacher: teacher,
                    text: t.trainingEntrySpeech,
                    unifiedSound: true,
                    avatarSize: 56,
                    speechContext: SpeechContext.teaching,
                  ),
                )
              else
                Text(t.trainingEntrySpeech, key: TrainingEntryKeys.speech),
              const SizedBox(height: 16),
              for (final text in [t.trainingEntrySaved, t.trainingEntryOffline])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.trainingDayCorrect,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(text, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          children: [
            FilledButton(
              key: TrainingEntryKeys.google,
              onPressed: busy
                  ? null
                  : () => context.read<AccountCubit>().signInWithGoogle(),
              child: Text(t.accountGoogle),
            ),
            OutlinedButton(
              key: TrainingEntryKeys.email,
              onPressed: busy
                  ? null
                  : () => context.push(
                      Routes.accountEmailFrom(
                        GoRouterState.of(context).uri.toString(),
                      ),
                    ),
              child: Text(t.trainingEntryEmail),
            ),
          ],
        ),
      ),
    );
  }
}
