import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/training/course_download_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson_content.dart';
import '../../../domain/models/training/training_course_config.dart';

enum CourseEntryPhase { account, downloading, ready, failure }

class CourseEntryState {
  const CourseEntryState({required this.phase, this.teacher, this.failure});
  final CourseEntryPhase phase;
  final Character? teacher;
  final Object? failure;
}

class CourseEntryCubit extends Cubit<CourseEntryState> {
  CourseEntryCubit({
    required this.accounts,
    required this.downloads,
    required this.characters,
    required this.config,
    this.chapterId,
  }) : super(
         CourseEntryState(
           phase: accounts.current == null
               ? CourseEntryPhase.account
               : CourseEntryPhase.downloading,
         ),
       );

  final AccountRepository accounts;
  final CourseDownloadRepository downloads;
  final CharacterRepository characters;
  final TrainingCourseConfig config;
  final String? chapterId;
  StreamSubscription<Object?>? _subscription;
  String? _identity;
  var _generation = 0;

  Future<void> start() async {
    _identity = accounts.current?.uid;
    _subscription = accounts.changes.listen((account) {
      if (_identity == account?.uid) return;
      _identity = account?.uid;
      unawaited(retry());
    });
    unawaited(_teacher());
    await retry();
  }

  Future<void> _teacher() async {
    try {
      final teacher = (await characters.characters())
          .where((c) => c.id == Character.masterId)
          .firstOrNull;
      if (!isClosed) {
        emit(
          CourseEntryState(
            phase: state.phase,
            teacher: teacher,
            failure: state.failure,
          ),
        );
      }
    } on Object {
      // Authentication and retry must remain available without the portrait.
    }
  }

  Future<void> retry() async {
    final generation = ++_generation;
    if (accounts.current == null) {
      emit(
        CourseEntryState(
          phase: CourseEntryPhase.account,
          teacher: state.teacher,
        ),
      );
      return;
    }
    emit(
      CourseEntryState(
        phase: CourseEntryPhase.downloading,
        teacher: state.teacher,
      ),
    );
    try {
      await downloads.prepare(config, chapterId: chapterId);
      if (!isClosed && generation == _generation) {
        emit(
          CourseEntryState(
            phase: CourseEntryPhase.ready,
            teacher: state.teacher,
          ),
        );
      }
    } on Object catch (failure) {
      if (!isClosed && generation == _generation) {
        emit(
          CourseEntryState(
            phase: CourseEntryPhase.failure,
            teacher: state.teacher,
            failure: failure is LessonContentUnavailable
                ? failure
                : const LessonContentUnavailable(),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    ++_generation;
    await _subscription?.cancel();
    await super.close();
  }
}
