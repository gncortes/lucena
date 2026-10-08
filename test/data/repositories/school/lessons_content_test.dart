import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';

/// O curso de verdade (`assets/lessons`): o que o `tools/lessons/check_school.py`
/// conferiu com o python-chess, aqui conferido de novo com as regras do app,
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

  test('as 39 aulas na ordem da trilha: as regras novas (T52) entre as '
      'peças, o en passant abrindo os peões, o valor das peças e os padrões '
      'de mate nos truques, e a formatura por último', () {
    expect(course.lessons.map((lesson) => lesson.id), [
      'pieces.rook',
      'pieces.bishop',
      'pieces.queen',
      'pieces.king',
      'pieces.knight',
      'pieces.pawn',
      'rules.captureProtect',
      'pieces.check',
      'rules.outOfCheck',
      'rules.castling',
      'pieces.stalemate',
      'rules.draws',
      'notation.coordinates',
      'notation.moves',
      'notation.read',
      'mates.twoRooks',
      'mates.queen',
      'rules.pieceValue',
      'tricks.scholarsMate',
      'tricks.defendScholar',
      'tricks.foolsMate',
      'tactics.matePatterns',
      'tricks.principles',
      'technique.opposition',
      'technique.zugzwang',
      'technique.rookCut',
      'technique.rookMate',
      'rules.enPassant',
      'pawns.kingPawn',
      'pawns.square',
      'pawns.rookPawn',
      'pawns.rookTwoPawns',
      'minor.rookBishop',
      'minor.rookKnight',
      'minor.rookTwoBishops',
      'minor.rookTwoKnights',
      'minor.rookBishopKnight',
      'minor.twoRooksVsKnight',
      'graduation.twoBishops',
    ]);
    expect(course.moduleOf('rules.enPassant')?.id, 'pawns');
    expect(course.moduleOf('tactics.matePatterns')?.id, 'tricks');
  });

  group('as aulas novas da T52, com as regras do app', () {
    MoveStep step(String lessonId, String stepId) =>
        course.lesson(lessonId)!.steps.firstWhere((s) => s.id == stepId)
            as MoveStep;
    Position after(MoveStep step, String uci) => GameRules.play(
      GameRules.fromFen(step.fen)!,
      Move.parse(uci)!,
    )!.position;

    test('o roque: proibido do lado em que o rei passa por casa atacada', () {
      final cannot = step('rules.castling', 'cannot');
      final position = GameRules.fromFen(cannot.fen)!;
      expect(GameRules.play(position, Move.parse('e1g1')!), isNull);
      expect(GameRules.play(position, Move.parse('e1c1')!), isNotNull);
      expect(cannot.line.single.accept, containsAll(['e1c1', 'e1a1']));
    });

    test('en passant: o peão capturado sai do tabuleiro', () {
      final white = step('rules.enPassant', 'capture');
      expect(after(white, 'e5d6').board.pieceAt(Square.d5), isNull);
      final black = step('rules.enPassant', 'black');
      expect(black.side, Side.black);
      expect(after(black, 'd4c3').board.pieceAt(Square.c4), isNull);
    });

    test('os empates: material insuficiente e o xeque perpétuo, que repete '
        'a posição', () {
      final take = step('rules.draws', 'takeLast');
      expect(
        GameRules.endOf(after(take, take.line.single.accept.first))?.reason,
        GameEndReason.insufficientMaterial,
      );
      final perpetual = step('rules.draws', 'perpetual');
      final moves = [
        for (final turn in perpetual.line) ...[turn.accept.first, ?turn.reply],
      ];
      expect(moves, ['e1e8', 'g8h7', 'e8h5', 'h7g8', 'h5e8']);
      expect(
        GameRules.repetitionsOf(GameRules.fromFen(perpetual.fen)!, moves),
        2,
      );
    });

    test('a subpromoção: a dama afoga, a torre não', () {
      final rook = step('pieces.pawn', 'rook');
      expect(rook.line.single.accept, {'c7c8r'});
      expect(
        GameRules.endOf(after(rook, 'c7c8q'))?.reason,
        GameEndReason.stalemate,
      );
      expect(GameRules.endOf(after(rook, 'c7c8r')), isNull);
    });

    test('os padrões de mate: todo lance pedido dá mate', () {
      for (final id in ['backRank', 'smothered', 'arabian', 'supported']) {
        final mate = step('tactics.matePatterns', id);
        for (final uci in mate.line.single.accept) {
          expect(
            GameRules.endOf(after(mate, uci))?.reason,
            GameEndReason.checkmate,
            reason: '$id $uci',
          );
        }
      }
    });

    test('a oposição e o afogamento também com as pretas', () {
      expect(step('technique.opposition', 'defend').side, Side.black);
      expect(step('pieces.stalemate', 'save').side, Side.black);
    });
  });

  test('toda posição abre, e os lances das aulas são legais', () {
    for (final lesson in course.lessons) {
      for (final step in lesson.steps) {
        final where = '${lesson.id}.${step.id}';
        switch (step) {
          case TalkStep(:final fen):
            if (fen != null) Board.parseFen(fen.split(' ').first);
          case ThinkStep() || DemoStep():
            fail('$where: a escola não tem passo de pensar nem demonstração');
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
