import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';

/// Uma `LessonSource` que só registra o que o roteiro grava (T70).
class FakeLessonSource implements LessonSource {
  FakeLessonSource({
    this.refs = const [],
    this.outcome = const LessonOutcome(nextPart: 'next'),
    this.endgame = true,
  });

  final List<Reference> refs;
  final LessonOutcome outcome;

  /// Os pontos de retomada gravados, em ordem.
  final checkpoints = <LessonCheckpoint>[];

  /// As partes concluídas, como `lição/parte`.
  final completed = <String>[];

  @override
  final bool endgame;

  @override
  Future<Lesson?> lesson(String id) async => lessonData;

  @override
  Future<LessonTexts> texts(String language) =>
      throw UnimplementedError('o roteiro não lê as falas por aqui');

  @override
  Future<List<Reference>> references(String id) async => refs;

  @override
  Future<(int, int)> placeOf(String id) async => (1, 1);

  /// O que [untouched] responde.
  bool fresh = true;

  /// A aula que [lesson] devolve (nula: o roteiro conta 1 capítulo de 1).
  Lesson? lessonData;

  @override
  Future<bool> untouched(String id) async => fresh;

  @override
  Future<LessonCheckpoint?> checkpoint() async =>
      checkpoints.isEmpty ? null : checkpoints.last;

  @override
  Future<void> saveCheckpoint(LessonCheckpoint checkpoint) async =>
      checkpoints.add(checkpoint);

  @override
  Future<void> clearCheckpoint() async => checkpoints.clear();

  @override
  Future<void> leave() async {}

  @override
  Future<LessonOutcome> complete(String id) async => outcome;

  @override
  Future<LessonOutcome> completePart(String id, String partId) async {
    completed.add('$id/$partId');
    return outcome;
  }
}
