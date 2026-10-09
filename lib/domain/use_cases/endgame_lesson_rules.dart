import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../models/endgame_lesson.dart';
import '../models/lesson.dart';
import '../models/speedrun.dart';
import 'game_rules.dart';

/// As regras das aulas de finais: pontos, nota e o que o passo final abre.
abstract final class EndgameLessonRules {
  /// As estrelas que um exercício de [stars] vale depois de [mistakes] erros
  /// e [hints] dicas: acerto de primeira vale tudo; cada erro ou dica tira
  /// uma, até zero.
  static int earned(int stars, {required int mistakes, required int hints}) =>
      max(0, stars - mistakes - hints);

  /// Todos os exercícios foram resolvidos.
  static bool allSolved(EndgameLesson lesson, EndgameLessonProgress progress) =>
      lesson.exercises.every(
        (exercise) => progress.stars.containsKey(exercise.id),
      );

  /// A aula está aprovada: a lição feita, todos os exercícios resolvidos e
  /// a nota no mínimo. É o que libera o passo final.
  static bool passed(EndgameLesson lesson, EndgameLessonProgress progress) =>
      progress.lessonDone &&
      allSolved(lesson, progress) &&
      progress.score >= lesson.passScore;

  /// O speedrun do final da aula: o de modalidade "final" na mesma posição
  /// do treino. Nulo se o final não tem speedrun.
  static Speedrun? speedrunOf(EndgameLesson lesson, List<Speedrun> speedruns) {
    final positionId = lesson.practice.positionId;
    if (positionId == null) return null;
    for (final speedrun in speedruns) {
      if (speedrun.kind == SpeedrunKind.ending &&
          speedrun.positionId == positionId) {
        return speedrun;
      }
    }
    return null;
  }

  /// A próxima aula a fazer na trilha: a primeira cuja lição não foi feita ou
  /// cuja nota não passou. Nula com a trilha inteira passada.
  static EndgameLesson? next(EndgameTrail trail, EndgameProgress progress) {
    for (final lesson in trail.lessons) {
      final each = progress.of(lesson.id);
      if (!passed(lesson, each)) return lesson;
    }
    return null;
  }

  /// A solução do exercício em notação (o lance ensinado de cada vez e a
  /// resposta combinada), para mostrar depois de resolvido. Vazia se a
  /// posição ou um lance não valem.
  static List<String> solution(Exercise exercise) {
    var position = GameRules.fromFen(exercise.fen);
    if (position == null) return const [];
    final line = <String>[];
    for (final turn in exercise.line) {
      final moves = [turn.accept.first, ?turn.reply];
      for (final uci in moves) {
        final move = Move.parse(uci);
        if (move == null || !position!.isLegal(move)) return line;
        final (next, san) = position.makeSan(move);
        line.add(san);
        position = next;
      }
    }
    return line;
  }

  /// A parte recomendada: a primeira ainda não feita. Nula: todas feitas (o
  /// próximo é o teste final). Nada trava: é só o destaque da tela.
  static LessonPart? recommendedPart(
    EndgameLesson lesson,
    EndgameLessonProgress progress,
  ) {
    final done = progress.partsDone(lesson);
    for (final part in lesson.lesson.sections) {
      if (!done.contains(part.id)) return part;
    }
    return null;
  }

  /// O progresso com a parte [partId] feita; com todas, a lição inteira.
  static EndgameLessonProgress completePart(
    EndgameLesson lesson,
    EndgameLessonProgress progress,
    String partId,
  ) {
    final done = {...progress.partsDone(lesson), partId};
    final all = lesson.lesson.sections.every((part) => done.contains(part.id));
    return progress.copyWith(parts: done, lessonDone: all);
  }

  /// O checkpoint lido para a aula em partes: um antigo (sem parte, com o
  /// passo contado na aula inteira) passa para a parte que contém aquele
  /// passo. Nada do que o aluno fez se perde.
  static LessonCheckpoint? migrate(
    EndgameLesson lesson,
    LessonCheckpoint? checkpoint,
  ) {
    if (checkpoint == null || checkpoint.part != null) return checkpoint;
    final located = lesson.lesson.locate(checkpoint.step);
    if (located == null) return null;
    final (part, step) = located;
    return LessonCheckpoint(
      lessonId: checkpoint.lessonId,
      step: step,
      fen: checkpoint.fen,
      collected: checkpoint.collected,
      turn: checkpoint.turn,
      moves: checkpoint.moves,
      open: checkpoint.open,
      part: part.id,
    );
  }
}
