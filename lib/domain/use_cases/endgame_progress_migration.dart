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
///
/// T76 reorganizou os capítulos: `pawns.keySquares` ("Casas-chave e
/// oposição") passou a abrir a Oposição e ficou com o `diagonal`, que era da
/// Parte 1; o `means` subiu da Parte 2 para a Parte 1; o exercício `e17`
/// (tempo de reserva) desceu da Parte 1 para a Parte 2. Capítulos que saíram
/// da estrutura (defend, outflank, edgeCorner, protectPawn, wrapUp, refresher,
/// useReserve, synchronize...) contam como feitos só enquanto a lição inteira
/// estava concluída. O marcador de que isso já rodou é
/// `EndgameProgress.chaptersMigrated`.
class EndgameProgressMigration {
  const EndgameProgressMigration._();

  static const firstId = 'pawns.distantOpposition';
  static const secondId = 'pawns.waitingMoves';
  static const keySquaresId = 'pawns.keySquares';

  /// Os capítulos de cada lição depois da T76.
  static const keySquaresChapters = {'keySquares', 'opposition', 'diagonal'};
  static const firstChapters = {
    'distant',
    'lateral',
    'capablanca',
    'edge',
    'means',
  };
  static const secondChapters = {
    'reserve',
    'waiting',
    'secondReserve',
    'fixedTarget',
  };

  /// Os capítulos da Parte 1 antes da T76 que seguem na Parte 1 (o resto saiu
  /// ou mudou de lição).
  static const _firstKept = {'distant', 'lateral', 'capablanca', 'edge'};

  /// O exercício que mudou da Parte 1 para a Parte 2 na T76.
  static const movedExercise = 'e17';

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

  /// As lições que saíram do app: as de bispo e cavalo (T77), cujo lugar é a
  /// `mates.bishopKnight.deletang`, e as de dama contra torre (T78), cujo
  /// lugar é a [queenId]; as duas com capítulos e exercícios novos.
  static const removedIds = {
    'mates.bishopKnight.w',
    'mates.bishopKnight.edge',
    'mates.bishopKnight.full',
    'queen.vsRook.approach',
    'queen.vsRook.thirdRank',
  };

  /// A lição de dama contra torre (T78): manteve o id, mas os capítulos e os
  /// exercícios mudaram.
  static const queenId = 'queen.vsRook.philidor';

  /// Os capítulos dela depois da T78. O `philidor` é a mesma ideia do
  /// capítulo antigo de mesmo id: quem o fez continua com ele feito.
  static const queenChapters = {
    'philidor',
    'tempo',
    'segunda',
    'terceira',
    'borda',
    'convert',
  };

  /// A lição de torre (T79): manteve o id, mas os capítulos e os exercícios
  /// mudaram (nenhum capítulo antigo tem o nome de um novo).
  static const lucenaId = 'rook.lucena';

  /// Os capítulos dela depois da T79.
  static const lucenaChapters = {
    'ponte',
    'corte',
    'lateral',
    'chegar',
    'convert',
  };

  /// As lições que mantiveram o id com capítulos novos, e os capítulos delas.
  static const _reshaped = {queenId: queenChapters, lucenaId: lucenaChapters};

  /// Os exercícios da lição no formato antigo (os novos têm outro nome).
  static final _oldExercise = RegExp(r'^e\d\d$');

  /// Aplica as migrações (T74, T76, T77, T78 e T79); devolve o mesmo objeto
  /// se não há o que mudar.
  static EndgameProgress apply(EndgameProgress progress) =>
      _reshaped.entries.fold(
        _removed(_chapters(_split(progress))),
        (progress, e) => _reshape(progress, e.key, e.value),
      );

  /// T78 e T79: na lição [id], saem os capítulos que não estão em
  /// [chapters] e os exercícios do formato antigo, e com eles a lição
  /// concluída e aprovada; a lição aberta num capítulo que saiu fecha.
  static EndgameProgress _reshape(
    EndgameProgress progress,
    String id,
    Set<String> chapters,
  ) {
    final old = progress.lessons[id];
    final checkpoint = progress.ongoing;
    final ongoing =
        checkpoint?.lessonId == id &&
        checkpoint?.part != null &&
        !chapters.contains(checkpoint?.part);
    final stale =
        old != null &&
        (old.parts.any((part) => !chapters.contains(part)) ||
            old.stars.keys.any(_oldExercise.hasMatch) ||
            _oldExercise.hasMatch(old.exercise?.exerciseId ?? ''));
    if (!stale && !ongoing) return progress;
    return progress.copyWith(
      lessons: {
        ...progress.lessons,
        if (stale)
          id: EndgameLessonProgress(
            parts: old.parts.intersection(chapters),
            stars: {
              for (final e in old.stars.entries)
                if (!_oldExercise.hasMatch(e.key)) e.key: e.value,
            },
            exercise: _oldExercise.hasMatch(old.exercise?.exerciseId ?? '')
                ? null
                : old.exercise,
          ),
      },
      clearOngoing: ongoing,
    );
  }

  /// T77 e T78: o progresso das lições de [removedIds] sai (os capítulos e os
  /// exercícios delas não existem na lição nova), e a lição aberta nelas
  /// fecha.
  static EndgameProgress _removed(EndgameProgress progress) {
    final stale = progress.lessons.keys.any(removedIds.contains);
    final ongoing = removedIds.contains(progress.ongoing?.lessonId);
    if (!stale && !ongoing) return progress;
    return progress.copyWith(
      lessons: {
        for (final MapEntry(:key, :value) in progress.lessons.entries)
          if (!removedIds.contains(key)) key: value,
      },
      clearOngoing: ongoing,
    );
  }

  /// T76: leva `diagonal`, `means` e o exercício `e17` para a lição nova.
  static EndgameProgress _chapters(EndgameProgress progress) {
    if (progress.chaptersMigrated) return progress;
    final first = progress.lessons[firstId];
    final second = progress.lessons[secondId];
    final ongoing = _ongoingChapters(progress.ongoing);
    if (first == null && second == null) {
      return progress.copyWith(ongoing: ongoing, chaptersMigrated: true);
    }
    final firstDone = first?.lessonDone ?? false;
    final secondDone = second?.lessonDone ?? false;
    final diagonalDone =
        firstDone || (first?.parts.contains('diagonal') ?? false);
    final meansDone = secondDone || (second?.parts.contains('means') ?? false);
    final exercise = first?.exercise;
    final exerciseMoves = exercise?.exerciseId == movedExercise;

    final firstParts = {
      if (firstDone)
        ..._firstKept
      else
        ...?first?.parts.intersection(_firstKept),
      if (meansDone) 'means',
    };
    final newFirst = EndgameLessonProgress(
      lessonDone: firstDone && meansDone,
      approved: first?.approved ?? false,
      parts: firstParts,
      stars: {
        for (final e in (first?.stars ?? const <String, int>{}).entries)
          if (e.key != movedExercise) e.key: e.value,
      },
      exercise: exerciseMoves ? null : exercise,
    );
    final newSecond = EndgameLessonProgress(
      lessonDone: secondDone,
      approved: second?.approved ?? false,
      parts: secondDone
          ? second!.parts
          : second?.parts.intersection(secondChapters) ?? const {},
      stars: {
        ...?second?.stars,
        if (first?.stars[movedExercise] case final int stars)
          movedExercise: stars,
      },
      exercise: exerciseMoves ? exercise : second?.exercise,
    );
    return EndgameProgress(
      lessons: {
        ...progress.lessons,
        firstId: newFirst,
        secondId: newSecond,
        keySquaresId:
            (progress.lessons[keySquaresId] ?? const EndgameLessonProgress())
                .copyWith(
                  parts: {
                    ...?progress.lessons[keySquaresId]?.parts,
                    if (diagonalDone) 'diagonal',
                  },
                ),
      },
      ongoing: ongoing,
    );
  }

  /// A lição aberta no `diagonal` (era da Parte 1) passa a apontar para
  /// `pawns.keySquares`; a aberta no `means` (era da Parte 2), para a Parte 1.
  static LessonCheckpoint? _ongoingChapters(LessonCheckpoint? checkpoint) {
    if (checkpoint == null) return checkpoint;
    final target = switch ((checkpoint.lessonId, checkpoint.part)) {
      (firstId, 'diagonal') => keySquaresId,
      (secondId, 'means') => firstId,
      _ => null,
    };
    return target == null ? checkpoint : _retarget(checkpoint, target);
  }

  /// T74: a Parte 2 ganhou id próprio.
  static EndgameProgress _split(EndgameProgress progress) {
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
      chaptersMigrated: progress.chaptersMigrated,
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
    return _retarget(checkpoint, secondId);
  }

  static LessonCheckpoint _retarget(LessonCheckpoint checkpoint, String id) {
    return LessonCheckpoint(
      lessonId: id,
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
