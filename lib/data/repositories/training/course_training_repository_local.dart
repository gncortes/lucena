import 'dart:async';
import 'dart:convert';

import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../services/lesson_content_service.dart';
import '../../services/preferences_service.dart';
import 'course_training_repository.dart';

final class TrainingRepositoryLocal implements TrainingRepository {
  TrainingRepositoryLocal(
    this.preferences,
    this.content, {
    required this.installSeed,
    this.configs = const {TrainingCourse.pilares: TrainingCourseConfig.pilares},
  });
  final PreferencesService preferences;
  final LessonContentAssets content;
  final String installSeed;
  final Map<TrainingCourse, TrainingCourseConfig> configs;
  final _changes = StreamController<TrainingState>.broadcast();
  final _pending = <TrainingCourse, Future<void>>{};
  @override
  Stream<TrainingState> get changes => _changes.stream;

  static String key(TrainingCourse course) => 'training.v1.${course.name}';
  Future<T> _serial<T>(TrainingCourse course, Future<T> Function() action) {
    final next = (_pending[course] ?? Future<void>.value()).then(
      (_) => action(),
    );
    _pending[course] = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<TrainingState> _read(TrainingCourse course) async {
    final raw = await preferences.getString(key(course));
    if (raw == null) {
      return TrainingState(course: course, installSeed: installSeed);
    }
    // Refuse unreadable/newer data without overwriting it or clearing progress.
    final state = TrainingState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (state.course != course) {
      throw const FormatException('Training course key mismatch');
    }
    return state;
  }

  @override
  Future<TrainingState> load(TrainingCourse course) =>
      _serial(course, () => _read(course));

  @override
  Future<TrainingState> update(
    TrainingCourse course,
    TrainingState Function(TrainingState) change,
  ) => _serial(course, () async {
    final before = await _read(course);
    final after = change(before);
    if (identical(before, after)) return before;
    if (after.course != course || after.installSeed != before.installSeed) {
      throw ArgumentError(
        'A transaction cannot change course or installation seed',
      );
    }
    await preferences.setString(key(course), jsonEncode(after.toJson()));
    _changes.add(
      after,
    ); // Subscribers/navigation only observe a durable change.
    return after;
  });

  Future<Map<String, dynamic>?> _json(String path) async {
    try {
      return jsonDecode(await content.loadString(path)) as Map<String, dynamic>;
    } on LessonContentUnavailable {
      return null;
    }
  }

  @override
  Future<TrainingResources> resources(TrainingCourse course) async {
    final config = configs[course];
    if (config == null) {
      throw ArgumentError.value(course, 'course', 'Course is not configured');
    }
    final index = await _json(config.indexSource);
    if (index == null) return TrainingResources();
    final lessons = <TrainingLesson>[];
    for (final part in (index['partes'] as List)) {
      for (final chapter in ((part as Map)['capitulos'] as List)) {
        for (final data in ((chapter as Map)['aulas'] as List)) {
          final lesson = data as Map;
          lessons.add(
            TrainingLesson(
              id: lesson['id'] as String,
              kind: switch (lesson['tipo']) {
                'tema' => TrainingLessonKind.theme,
                'abertura' => TrainingLessonKind.opening,
                'teste' => TrainingLessonKind.test,
                _ => throw const FormatException('Unknown lesson kind'),
              },
              title: lesson['titulo'] as String,
              summary: lesson['resumo'] as String? ?? '',
              group: chapter['titulo'] as String,
              groupId: chapter['id'] as String,
              partId: part['id'] as String,
              partTitle: part['titulo'] as String,
            ),
          );
        }
      }
    }
    final banks = <String, List<TrainingExercise>>{};
    final openings = <String, List<OpeningTrecho>>{};
    await Future.wait(
      lessons.map((lesson) async {
        if (lesson.kind == TrainingLessonKind.theme) {
          final json = await _json('assets/lessons/treino/${lesson.id}.json');
          if (json != null) {
            banks[lesson.id] = (json['exercicios'] as List)
                .map(
                  (e) => TrainingExercise.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
          }
        } else if (lesson.kind == TrainingLessonKind.opening) {
          final json = await _json(
            'assets/lessons/treino/aberturas/${lesson.id}.json',
          );
          if (json != null) {
            openings[lesson.id] = (json['trechos'] as List)
                .map(
                  (t) => OpeningTrecho.fromJson({
                    'cor': json['cor'],
                    ...Map<String, dynamic>.from(t as Map),
                  }),
                )
                .toList();
          }
        }
      }),
    );
    return TrainingResources(
      lessons: lessons,
      banks: banks,
      openings: openings,
    );
  }

  Future<void> dispose() => _changes.close();
}
