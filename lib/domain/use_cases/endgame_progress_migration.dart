import '../models/endgame_lesson.dart';
import '../models/lesson.dart';

/// Migra o progresso salvo (`endgames.progress`) quando a lição
/// `pawns.distantOpposition` foi dividida em duas partes (T74): a Parte 1
/// continua com o id antigo e a Parte 2 ganhou [secondId].
///
/// Quem tinha a lição inteira concluída fica com a Parte 1 concluída e a
/// Parte 2 não concluída (o resumo de abertura dela ainda falta). O que o
/// aluno já fez não se perde: capítulos, estrelas e o exercício aberto vão
/// para a lição que passou a ter aquele capítulo ou exercício. A migração é
/// idempotente: com a Parte 2 já gravada, nada muda.
class EndgameProgressMigration {
  const EndgameProgressMigration._();

  static const firstId = 'pawns.distantOpposition';
  static const secondId = 'pawns.waitingMoves';

  /// Os capítulos da lição antiga que foram para a Parte 2.
  static const secondParts = {
    'reserve',
    'waiting',
    'secondReserve',
    'useReserve',
    'fixedTarget',
    'synchronize',
    'means',
  };

  /// Os capítulos da lição antiga que ficaram na Parte 1.
  static const firstParts = {
    'distant',
    'diagonal',
    'defend',
    'lateral',
    'capablanca',
    'outflank',
    'edge',
    'edgeCorner',
    'protectPawn',
  };

  /// Os exercícios da lição antiga que foram para a Parte 2.
  static const secondExercises = {'e14', 'e15', 'e16'};

  /// Os exercícios da lição antiga e a nota mínima dela: com todos resolvidos
  /// e a nota atingida, ela estava aprovada.
  static const oldExercises = {'e09', 'e11', 'e13', 'e14', 'e15', 'e16'};
  static const oldPassScore = 9;

  static bool _wasApproved(EndgameLessonProgress old) =>
      old.lessonDone &&
      oldExercises.every(old.stars.containsKey) &&
      oldExercises.fold<int>(0, (sum, id) => sum + (old.stars[id] ?? 0)) >=
          oldPassScore;

  /// Aplica a migração; devolve o mesmo objeto se não há o que mudar.
  static EndgameProgress apply(EndgameProgress progress) {
    if (progress.lessons.containsKey(secondId)) return progress;
    final old = progress.lessons[firstId];
    final ongoing = _ongoing(progress.ongoing);
    if (old == null && identical(ongoing, progress.ongoing)) return progress;
    if (old == null) return progress.copyWith(ongoing: ongoing);

    final done = old.lessonDone ? {...firstParts, ...secondParts} : old.parts;
    final exercise = old.exercise;
    final exerciseInSecond =
        exercise != null && secondExercises.contains(exercise.exerciseId);
    final first = EndgameLessonProgress(
      lessonDone: old.lessonDone,
      approved: _wasApproved(old),
      parts: done.intersection(firstParts),
      stars: {
        for (final e in old.stars.entries)
          if (!secondExercises.contains(e.key)) e.key: e.value,
      },
      exercise: exerciseInSecond ? null : exercise,
    );
    final second = EndgameLessonProgress(
      parts: done.intersection(secondParts),
      stars: {
        for (final e in old.stars.entries)
          if (secondExercises.contains(e.key)) e.key: e.value,
      },
      exercise: exerciseInSecond ? exercise : null,
    );
    return EndgameProgress(
      lessons: {...progress.lessons, firstId: first, secondId: second},
      ongoing: ongoing,
    );
  }

  /// A lição aberta num capítulo que foi para a Parte 2 passa a apontar para
  /// ela. Um checkpoint sem capítulo (formato anterior às partes) fica como
  /// está.
  static LessonCheckpoint? _ongoing(LessonCheckpoint? checkpoint) {
    if (checkpoint == null ||
        checkpoint.lessonId != firstId ||
        !secondParts.contains(checkpoint.part)) {
      return checkpoint;
    }
    return LessonCheckpoint(
      lessonId: secondId,
      step: checkpoint.step,
      fen: checkpoint.fen,
      collected: checkpoint.collected,
      turn: checkpoint.turn,
      moves: checkpoint.moves,
      open: checkpoint.open,
      part: checkpoint.part,
      stepId: checkpoint.stepId,
      stepStartedAt: checkpoint.stepStartedAt,
      stepPausedAt: checkpoint.stepPausedAt,
      hintsShown: checkpoint.hintsShown,
      mistakes: checkpoint.mistakes,
      demoMove: checkpoint.demoMove,
      demoPlaying: checkpoint.demoPlaying,
    );
  }
}
