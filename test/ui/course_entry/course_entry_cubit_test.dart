import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/course_entry/view_models/course_entry_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';

class _Downloads extends CourseDownloadRepository {
  _Downloads() : super.unconfigured();
  int attempts = 0;
  Object? failure;
  Completer<void>? pending;
  @override
  Future<void> prepare(TrainingCourseConfig config, {String? chapterId}) async {
    ++attempts;
    if (pending case final operation?) await operation.future;
    if (failure case final error?) throw error;
  }
}

void main() {
  late FakeAccountRepository accounts;
  late _Downloads downloads;
  late CourseEntryCubit cubit;
  setUp(() {
    accounts = FakeAccountRepository();
    downloads = _Downloads();
    cubit = CourseEntryCubit(
      accounts: accounts,
      downloads: downloads,
      characters: FakeCharacterRepository(),
      config: TrainingCourseConfig.pilares,
    );
  });
  tearDown(() => cubit.close());

  test('anonymous entry never downloads and Google sign in continues automatically', () async {
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CourseEntryPhase.account);
    expect(downloads.attempts, 0);
    final ready = cubit.stream.firstWhere(
      (s) => s.phase == CourseEntryPhase.ready,
    );
    await accounts.signInWithGoogle();
    await ready;
    expect(downloads.attempts, 1);
  });

  test('canceling Google keeps account gate without any download', () async {
    accounts.canceled = true;
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    await accounts.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CourseEntryPhase.account);
    expect(downloads.attempts, 0);
  });

  test('network failure retains screen and explicit retry completes', () async {
    accounts.account = FakeAccountRepository.google;
    downloads.failure = const LessonContentNetworkUnavailable();
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, CourseEntryPhase.failure);
    expect(cubit.state.failure, isA<LessonContentNetworkUnavailable>());
    downloads.failure = null;
    await cubit.retry();
    expect(cubit.state.phase, CourseEntryPhase.ready);
    expect(downloads.attempts, 2);
  });

  test(
    'signing out during download cannot reveal course on stale completion',
    () async {
      accounts.account = FakeAccountRepository.google;
      downloads.pending = Completer<void>();
      final start = cubit.start();
      final anonymous = cubit.stream.firstWhere(
        (s) => s.phase == CourseEntryPhase.account,
      );
      await accounts.signOut();
      await anonymous;
      downloads.pending!.complete();
      await start;
      expect(cubit.state.phase, CourseEntryPhase.account);
    },
  );
}
