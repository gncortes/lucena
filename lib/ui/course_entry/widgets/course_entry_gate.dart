import '../../core/widgets/course/course_navigation_bar.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../data/repositories/training/course_download_repository.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/lesson_content.dart';
import '../../../routing/routes.dart';
import '../../account/view_models/account_cubit.dart';
import '../../account/widgets/account_flow.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/training_entry_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../course_guide/widgets/course_guide_copy.dart';
import '../view_models/course_entry_cubit.dart';
import 'course_content_states.dart';

Widget _backButton(BuildContext context, {Key? key}) => BackButton(
  key: key ?? TrainingEntryKeys.back,
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
        final courseTitle = title ?? courseGuideCopy(context, config.titleKey);
        final downloading = state.phase == CourseEntryPhase.downloading;
        if (downloading || state.phase == CourseEntryPhase.ready) {
          // H-ANI-07: o esqueleto brilha enquanto baixa e se dissolve no
          // conteúdo quando o pacote fica pronto.
          return ShimmerConteudo(
            carregando: downloading,
            // A tela do curso (app bar e barra de baixo) entra parada; só o
            // corpo anima, dentro dela.
            trocaAnimada: false,
            // Mensageiro próprio: o aviso (SnackBar) da tela não aparece
            // também no esqueleto enquanto os dois se cruzam.
            esqueleto: ScaffoldMessenger(
              child: _CourseScaffold(
                title: courseTitle,
                chapter: chapterId != null,
                body: CourseDownloadSkeleton(chapter: chapterId != null),
              ),
            ),
            child: downloading ? const SizedBox.shrink() : child,
          );
        }
        if (state.phase == CourseEntryPhase.account) {
          return BlocProvider(
            create: (context) => AccountCubit(
              context.read<AccountRepository>(),
              sync: context.read<SyncScheduler>(),
              analytics: context.analytics,
              campaigns: context.campaigns,
            ),
            child: _AccountEntry(
              title: courseTitle,
              entry: state,
              school: config.course == TrainingCourse.escola,
            ),
          );
        }
        if (state.phase == CourseEntryPhase.failure &&
            (chapterId == null ||
                state.failure is LessonContentStorageUnavailable)) {
          return CourseDownloadFailure(
            failure: state.failure,
            chapter: chapterId != null,
            onRetry: context.read<CourseEntryCubit>().retry,
          );
        }
        return _CourseScaffold(
          title: courseTitle,
          chapter: chapterId != null,
          body: CourseDownloadFailure(
            failure: state.failure,
            chapter: chapterId != null,
            onRetry: context.read<CourseEntryCubit>().retry,
          ),
        );
      },
    ),
  );
}

class _CourseScaffold extends StatelessWidget {
  const _CourseScaffold({
    required this.title,
    required this.chapter,
    required this.body,
  });
  final String title;
  final bool chapter;
  final Widget body;
  @override
  Widget build(BuildContext context) => Scaffold(
    // O título fica onde a tela do curso o põe (à esquerda, colado na seta),
    // para não pular do centro para a esquerda quando o pacote fica pronto
    // (Gabriel, 04/11). O capítulo segue centrado, como a tela dele.
    appBar: LucenaAppBar(
      key: TrainingEntryKeys.skeletonAppBar,
      centerTitle: chapter,
      titleSpacing: chapter ? null : 0,
      leading: _backButton(context),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
    body: SafeArea(child: body),
    bottomNavigationBar: chapter ? null : const CourseNavigationBar(),
  );
}

class _AccountEntry extends StatelessWidget {
  const _AccountEntry({
    required this.title,
    required this.entry,
    required this.school,
  });
  final String title;
  final bool school;
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
          leading: _backButton(context, key: TrainingEntryKeys.accountBack),
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
                    text: school
                        ? t.trainingEntrySpeechSchool
                        : t.trainingEntrySpeech,
                    unifiedSound: true,
                    avatarSize: 56,
                    speechContext: SpeechContext.teaching,
                  ),
                )
              else
                Text(
                  school ? t.trainingEntrySpeechSchool : t.trainingEntrySpeech,
                  key: TrainingEntryKeys.speech,
                ),
              const SizedBox(height: 16),
              for (final text in [
                t.trainingEntrySaved,
                if (!school) t.trainingEntryOffline,
              ])
                _EntryCheck(text: text, saved: text == t.trainingEntrySaved),
            ],
          ),
        ),
        bottomNavigationBar: ActionsFooter(
          stacked: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          children: school
              ? [
                  FilledButton(
                    key: TrainingEntryKeys.signIn,
                    onPressed: busy
                        ? null
                        : () async {
                            final entry = context.read<CourseEntryCubit>();
                            await context.push(
                              Routes.accountEnterFrom(
                                GoRouterState.of(context).uri.toString(),
                              ),
                            );
                            unawaited(entry.retry());
                          },
                    child: Text(t.trainingEntrySignIn),
                  ),
                ]
              : [
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

/// Uma linha de garantia da tela de entrada: o visto e o texto.
class _EntryCheck extends StatelessWidget {
  const _EntryCheck({required this.text, required this.saved});

  final String text;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: saved ? TrainingEntryKeys.saved : null,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.trainingDayCorrect,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
