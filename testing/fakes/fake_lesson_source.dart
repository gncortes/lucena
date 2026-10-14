import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';

/// Uma `LessonSource` que só registra o que o roteiro grava (T70).
class FakeLessonSource implements LessonSource {
  FakeLessonSource({
    this.refs = const [],
    this.outcome = const LessonOutcome(nextPart: 'next'),
  });

  final List<Reference> refs;
  final LessonOutcome outcome;

  /// Os pontos de retomada gravados, em ordem.
  final checkpoints = <LessonCheckpoint>[];

  /// As partes concluídas, como `lição/parte`.
  final completed = <String>[];

  @override
  bool get endgame => true;

  @override
  Future<Lesson?> lesson(String id) async => null;

  @override
  Future<LessonTexts> texts(String language) =>
      throw UnimplementedError('o roteiro não lê as falas por aqui');

  @override
  Future<List<Reference>> references(String id) async => refs;

  @override
  Future<(int, int)> placeOf(String id) async => (1, 1);

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
