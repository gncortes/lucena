import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

/// As aulas de finais de verdade (`assets/lessons/endgames`): o que o
/// `build_aula.py` conferiu com a tabela de finais, aqui conferido de novo
/// com as regras do app, sem rede, para o CI.
void main() {
  final index = jsonDecode(
    io.File(AssetEndgameLessonRepository.indexPath).readAsStringSync(),
  ) as Map<String, dynamic>;
  final ids = [
    for (final module
        in (index['modules'] as List).cast<Map<String, dynamic>>())
      ...(module['lessons'] as List).cast<String>(),
  ];
  final lessons = [
    for (final id in ids)
      AssetEndgameLessonRepository.parseLesson(
        jsonDecode(
          io.File(AssetEndgameLessonRepository.lessonPath(id))
              .readAsStringSync(),
        ),
      ),
  ];
  Map<String, dynamic> texts(String language, String id) => jsonDecode(
    io.File(AssetEndgameLessonRepository.textsPath(language, id))
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final gluedAnnotation = RegExp(r'[a-h1-8O][+#]?[?!]{1,2}[:;.]');
  final mateInN = RegExp(r'mate (em|in) \d+', caseSensitive: false);

  test('as aulas em revisão existem no índice', () {
    final review = jsonDecode(
      io.File(AssetEndgameLessonRepository.reviewPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final inReview = (review['lessons'] as List).cast<String>();
    expect(inReview.toSet().length, inReview.length);
    expect(ids, containsAll(inReview));
  });

  test('o índice só aponta aulas que existem, sem repetição', () {
    expect(ids.toSet().length, ids.length);
    for (final (index, lesson) in lessons.indexed) {
      expect(lesson.id, ids[index]);
    }
  });

  test('nenhum passo usa um id reservado (apagaria o resumo da aula)', () {
    const reserved = {'title', 'summary', 'history', 'practice'};
    for (final lesson in lessons) {
      for (final step in lesson.lesson.steps) {
        expect(
          reserved.contains(step.id),
          isFalse,
          reason: '${lesson.id}.${step.id}',
        );
      }
    }
  });

  test('toda aula tem lição, ao menos 3 exercícios e nota mínima válida', () {
    for (final lesson in lessons) {
      expect(lesson.lesson.steps, isNotEmpty, reason: lesson.id);
      // Um exercício por ideia distinta, sem cota: o mínimo é 3.
      expect(
        lesson.exercises.length,
        greaterThanOrEqualTo(3),
        reason: lesson.id,
      );
      for (final exercise in lesson.exercises) {
        expect(exercise.stars, inInclusiveRange(1, 3), reason: exercise.id);
        expect(
          exercise.line,
          isNotEmpty,
          reason: '${lesson.id}.${exercise.id}',
        );
      }
      expect(
        lesson.passScore,
        inInclusiveRange((lesson.maxScore / 2).ceil(), lesson.maxScore),
        reason: lesson.id,
      );
      expect(lesson.keyPositions, isNotEmpty, reason: lesson.id);
      expect(
        lesson.references.any((r) => r.kind == 'book' || r.kind == 'study'),
        isTrue,
        reason: lesson.id,
      );
      for (final position in lesson.keyPositions) {
        if (position.ref case final ref?) {
          // `id` ou `id#ply` (a mesma partida parada noutro lance).
          expect(
            lesson.reference(ref),
            isNotNull,
            reason: '${lesson.id}.key.${position.id}',
          );
        }
      }
    }
  });

  test('toda posição abre e todo lance das linhas é legal', () {
    void checkLine(String where, String fen, List<MoveTurn> line) {
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
          position = GameRules.play(position, Move.parse(reply)!)?.position;
          expect(position, isNotNull, reason: '$where: $reply');
        }
      }
    }

    for (final lesson in lessons) {
      for (final step in lesson.lesson.steps) {
        final where = '${lesson.id}.${step.id}';
        switch (step) {
          case TalkStep(:final fen):
            if (fen != null) Board.parseFen(fen.split(' ').first);
          case MoveStep(:final fen, :final line):
            checkLine(where, fen, line);
          case PlayStep(:final fen):
            final position = GameRules.fromFen(fen);
            expect(position, isNotNull, reason: where);
            expect(GameRules.endOf(position!), isNull, reason: where);
          case ThinkStep(:final fen, :final hints):
            expect(GameRules.fromFen(fen), isNotNull, reason: where);
            expect(hints, inInclusiveRange(1, 3), reason: where);
          case DemoStep(:final fen, :final line):
            // Os lances da demonstração, dos dois lados, todos legais.
            var position = GameRules.fromFen(fen);
            expect(position, isNotNull, reason: where);
            for (final move in line) {
              position = GameRules.play(
                position!,
                Move.parse(move.uci)!,
              )?.position;
              expect(position, isNotNull, reason: '$where: ${move.uci}');
            }
          case StarsStep() || TapStep():
            fail(
              '$where: aula de final não tem passo de estrelas nem de tocar',
            );
        }
      }
      for (final exercise in lesson.exercises) {
        checkLine(
          '${lesson.id}.ex.${exercise.id}',
          exercise.fen,
          exercise.line,
        );
      }
      expect(
        GameRules.fromFen(lesson.practice.fen),
        isNotNull,
        reason: lesson.id,
      );
      expect(lesson.practice.goal, isA<PositionGoal>());
      for (final position in lesson.keyPositions) {
        Board.parseFen(position.fen.split(' ').first);
      }
    }
  });

  test('em português e em inglês, toda fala existe, sem sobra nem "mate em N"', () {
    for (final lesson in lessons) {
      final expected = {
        'title',
        'summary',
        'history',
        'practice',
        for (final part in lesson.lesson.parts) ...[
          'part.${part.id}.title',
          'part.${part.id}.summary',
        ],
        for (final step in lesson.lesson.steps) ...[
          'step.${step.id}',
          if (step is MoveStep) ...[
            'step.${step.id}.hint',
            'step.${step.id}.done',
          ],
          if (step is ThinkStep)
            for (var hint = 1; hint <= step.hints; hint++)
              'step.${step.id}.hint$hint',
          if (step is DemoStep)
            for (var move = 1; move <= step.line.length; move++)
              'step.${step.id}.m$move',
        ],
        for (final exercise in lesson.exercises) ...[
          'ex.${exercise.id}',
          'ex.${exercise.id}.hint',
          'ex.${exercise.id}.solution',
        ],
        for (final position in lesson.keyPositions) 'key.${position.id}',
      };
      for (final language in ['pt', 'en']) {
        final all = texts(language, lesson.id);
        expect(all.keys.toSet(), expected, reason: '$language ${lesson.id}');
        for (final MapEntry(:key, :value) in all.entries) {
          final text = value is List ? value.join(' ') : '$value';
          expect(
            text.trim(),
            isNotEmpty,
            reason: '$language ${lesson.id} $key',
          );
          expect(
            mateInN.hasMatch(text),
            isFalse,
            reason: '$language ${lesson.id} $key diz "mate em N"',
          );
          // Como nos livros: o símbolo fecha a frase do lance ("Te6! A
          // torre..."), nunca "Te6!:" nem "De3?." (T60).
          expect(
            gluedAnnotation.hasMatch(text),
            isFalse,
            reason:
                '$language ${lesson.id} $key: ${gluedAnnotation.firstMatch(text)?.group(0)}',
          );
        }
      }
    }
  });
}
