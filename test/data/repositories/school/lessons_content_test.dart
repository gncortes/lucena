import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';

/// O curso de verdade (`assets/lessons`): o que o `tools/build_lessons.py`
/// conferiu com o Stockfish, aqui conferido de novo com as regras do app,
/// sem motor, para o CI.
void main() {
  final course = AssetLessonRepository.parseCourse(
    jsonDecode(io.File(AssetLessonRepository.coursePath).readAsStringSync()),
  );
  Map<String, dynamic> texts(String language) => jsonDecode(
    io.File(AssetLessonRepository.textsPath(language)).readAsStringSync(),
  ) as Map<String, dynamic>;

  test('o curso tem os oito módulos, da torre aos dois bispos, com a notação '
      'logo depois das peças e os primeiros truques depois dos primeiros '
      'mates', () {
    expect(course.modules.map((module) => module.id), [
      'pieces',
      'notation',
      'firstMates',
      'tricks',
      'technique',
      'pawns',
      'minorPieces',
      'graduation',
    ]);
    expect(course.lessons.first.id, 'pieces.rook');
    expect(course.lessons.last.id, 'graduation.twoBishops');
    final ids = course.lessons.map((lesson) => lesson.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('toda posição abre, e os lances das aulas são legais', () {
    for (final lesson in course.lessons) {
      for (final step in lesson.steps) {
        final where = '${lesson.id}.${step.id}';
        switch (step) {
          case TalkStep(:final fen):
            if (fen != null) Board.parseFen(fen.split(' ').first);
          case StarsStep(:final fen, :final stars):
            // Toda estrela alcançável, uma depois da outra, na ordem dada.
            var board = LessonRules.starsBoard(fen);
            final side = step.side;
            for (final star in stars) {
              final path = _route(board, side, Square.fromName(star));
              expect(path, isNotNull, reason: '$where: $star inalcançável');
              board = path!;
            }
          case TapStep(:final fen, :final targets):
            // Casas de verdade, e cada uma pedida uma vez só.
            Board.parseFen(fen.split(' ').first);
            expect(targets, isNotEmpty, reason: where);
            expect(targets.toSet().length, targets.length, reason: where);
            for (final target in targets) {
              expect(
                () => Square.fromName(target),
                returnsNormally,
                reason: '$where: $target',
              );
            }
          case MoveStep(:final fen, :final line):
            var position = GameRules.fromFen(fen);
            expect(position, isNotNull, reason: where);
            for (final turn in line) {
              expect(turn.accept, isNotEmpty, reason: where);
              for (final uci in turn.accept) {
                expect(
                  GameRules.play(position!, Move.parse(uci)!),
                  isNotNull,
                  reason: '$where: $uci',
                );
              }
              position = GameRules.play(
                position!,
                Move.parse(turn.accept.first)!,
              )!.position;
              if (turn.reply case final reply?) {
                position = GameRules.play(
                  position,
                  Move.parse(reply)!,
                )?.position;
                expect(position, isNotNull, reason: '$where: $reply');
              }
            }
          case PlayStep(:final fen):
            final position = GameRules.fromFen(fen);
            expect(position, isNotNull, reason: where);
            expect(GameRules.endOf(position!), isNull, reason: where);
        }
      }
    }
  });

  test('em português e em inglês, toda aula e todo passo têm fala', () {
    for (final language in ['pt', 'en']) {
      final all = texts(language);
      for (final module in course.modules) {
        expect(all['module.${module.id}'], isNotNull, reason: module.id);
      }
      for (final lesson in course.lessons) {
        expect(all['${lesson.id}.title'], isNotNull, reason: lesson.id);
        expect(all['${lesson.id}.summary'], isNotNull, reason: lesson.id);
        for (final step in lesson.steps) {
          expect(
            all['${lesson.id}.${step.id}'],
            isNotNull,
            reason: '$language ${lesson.id}.${step.id}',
          );
        }
      }
      for (final key in [
        'coach.praise',
        'coach.good',
        'coach.star',
        'coach.wrong',
        'coach.hint',
        'coach.keepGoing',
        'coach.stalemate',
        'coach.draw',
        'coach.lost',
        'coach.retry',
        'coach.lessonDone',
        'coach.graduation',
        'school.welcome',
        'school.welcomeBack',
        'school.graduated',
        'tour.level',
        'tour.level.beginner',
      ]) {
        expect(all[key], isNotNull, reason: '$language $key');
      }
    }
  });

  test('o português e o inglês têm as mesmas chaves', () {
    expect(texts('pt').keys.toSet(), texts('en').keys.toSet());
  });
}

/// O tabuleiro com a peça na estrela [target], indo por qualquer caminho.
/// Nulo se nenhuma peça chega lá.
Board? _route(Board start, Side side, Square target) {
  final seen = {start.fen};
  var frontier = [start];
  for (var depth = 0; depth < 8 && frontier.isNotEmpty; depth++) {
    final next = <Board>[];
    for (final board in frontier) {
      for (final MapEntry(key: from, value: tos) in LessonRules.starsMoves(
        board,
        side,
      ).entries) {
        for (final to in tos) {
          final moved = LessonRules.moveStar(board, side, from, to)!;
          if (to == target) return moved;
          if (seen.add(moved.fen)) next.add(moved);
        }
      }
    }
    frontier = next;
  }
  return null;
}
