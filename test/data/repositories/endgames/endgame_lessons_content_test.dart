import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/data/repositories/wiki/wiki_links_repository_asset.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/wiki_links.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/move_tree.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/domain/use_cases/wiki_markup.dart';

import '../../../../testing/script_fixture.dart';

/// As aulas de finais de verdade (`assets/lessons/endgames`): o que o
/// `build_aula.py` conferiu com a tabela de finais, aqui conferido de novo
/// com as regras do app, sem rede, para o CI.
/// O capítulo tem roteiro e o arquivo já existe (T76: o app esconde o capítulo
/// cujo roteiro ainda não chegou).
bool _hasScript(LessonPart part) =>
    part.script != null && io.File(part.script!).existsSync();

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
  // As falas da lição mais as à parte de cada capítulo (`<lição>.<capítulo>.rot.json`,
  // T76), como o app as junta.
  Map<String, dynamic> texts(String language, String id) {
    final base = jsonDecode(
      io.File(AssetEndgameLessonRepository.textsPath(language, id))
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final lesson = lessons.firstWhere((lesson) => lesson.id == id);
    return {
      ...base,
      for (final part in lesson.lesson.parts)
        if (io.File('assets/lessons/$language/endgames/$id.${part.id}.rot.json')
            .existsSync())
          ...jsonDecode(
            io.File('assets/lessons/$language/endgames/$id.${part.id}.rot.json')
                .readAsStringSync(),
          ) as Map<String, dynamic>,
    };
  }

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

  test('O rei como muro não mostra uma seta solta para o lance explicado', () {
    final shoulder = lessons.singleWhere(
      (lesson) => lesson.id == 'pawns.shoulder',
    );
    final wall = shoulder.lesson.steps.firstWhere(
      (step) => step.id == 'wall',
    ) as TalkStep;
    expect(wall.arrows, isNot(contains(('e4', 'd4'))));
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
      expect(
        lesson.lesson.steps.isNotEmpty ||
            lesson.lesson.parts.any((part) => part.script != null),
        isTrue,
        reason: lesson.id,
      );
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
      // A nota vale para os exercícios que aparecem (T76: alguns ficam
      // escondidos até o capítulo da ideia deles voltar).
      final hidden = VisibleLessons.hiddenExercises[lesson.id] ?? const {};
      final shownMax = lesson.exercises
          .where((exercise) => !hidden.contains(exercise.id))
          .fold<int>(0, (sum, exercise) => sum + exercise.stars);
      expect(
        lesson.passScore,
        inInclusiveRange((shownMax / 2).ceil(), shownMax),
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
          for (final line in step.lines)
            for (final branch in line.branches)
              'step.${step.id}.alt.${branch.id}',
        ],
        for (final exercise in lesson.exercises) ...[
          'ex.${exercise.id}',
          'ex.${exercise.id}.hint',
          'ex.${exercise.id}.solution',
        ],
        for (final position in lesson.keyPositions) 'key.${position.id}',
        // Parte em roteiro (T70): as falas do próprio roteiro (as genéricas
        // moram em `roteiro_generico.json`).
        for (final part in lesson.lesson.parts)
          if (_hasScript(part))
            ...scriptTexts(
              jsonDecode(io.File(part.script!).readAsStringSync())
                  as Map<String, dynamic>,
            ).keys.where((key) => !key.startsWith('gen.')),
      };
      // O comentário por lance do ramo (`...alt.<id>.m<k>`) é opcional.
      final optional = {
        for (final step in lesson.lesson.steps)
          for (final line in step.lines)
            for (final branch in line.branches)
              for (var k = 1; k <= branch.uci.length; k++)
                'step.${step.id}.alt.${branch.id}.m$k',
        // A linha principal depois de um alternativo: sem a específica, vale
        // a genérica `gen.principal`.
        for (final part in lesson.lesson.parts)
          if (_hasScript(part))
            for (final stage in LessonScript.fromJson(
              jsonDecode(io.File(part.script!).readAsStringSync())
                  as Map<String, dynamic>,
            ).stages)
              for (final example in stage.examples)
                if (example.question case final question?)
                  if (question.alternatives.isNotEmpty)
                    ScriptTracks.principal(question.rightStep.t),
        // O erro previsto da prática: a chave inteira ou as duas partes
        // (`.1` no lance, `.2` com a resposta).
        for (final part in lesson.lesson.parts)
          if (_hasScript(part))
            for (final stage in LessonScript.fromJson(
              jsonDecode(io.File(part.script!).readAsStringSync())
                  as Map<String, dynamic>,
            ).stages)
              for (final example in stage.examples)
                for (final key
                    in example.practice?.errors.values ?? <String>[]) ...[
                  key,
                  '$key.1',
                  '$key.2',
                ],
      };
      // Também opcionais: resumo curto do passo (`step.<id>.short`), fala da
      // resposta do adversário (`step.<id>.r<n>`, `ex.<id>.r<n>`) e fala do
      // erro comentado (`step.<id>.mistake.<uci>`).
      final stepIds = {for (final step in lesson.lesson.steps) step.id};
      final exerciseIds = {
        for (final exercise in lesson.exercises) exercise.id,
      };
      final optionalPattern = RegExp(
        r'^(step\.([^.]+)\.(short|r\d+|mistake\.[a-h][1-8][a-h][1-8][qrbn]?)'
        r'|ex\.([^.]+)\.r\d+)$',
      );
      bool isOptional(String key) {
        if (optional.contains(key)) return true;
        // A fala de fim da aula, própria dela (no lugar da genérica).
        if (key == 'coach.allPartsDone') return true;
        final match = optionalPattern.firstMatch(key);
        if (match == null) return false;
        return match.group(2) != null
            ? stepIds.contains(match.group(2))
            : exerciseIds.contains(match.group(4));
      }

      for (final language in ['pt', 'en']) {
        final all = texts(language, lesson.id);
        expect(
          all.keys.where((key) => !isOptional(key)).toSet(),
          expected,
          reason: '$language ${lesson.id}',
        );
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

  test(
    'todo nome marcado nas falas tem a chave em links.json, com pt ou en',
    () {
      final links = WikiLinks.fromJson(
        jsonDecode(io.File(AssetWikiLinksRepository.path).readAsStringSync()),
      );
      // Uma marcação quebrada ({{nome}}, {{nome|}}) apareceria crua na tela.
      final broken = RegExp(r'\{\{|\}\}');
      for (final language in ['pt', 'en']) {
        for (final lesson in lessons) {
          for (final MapEntry(:key, :value) in texts(
            language,
            lesson.id,
          ).entries) {
            for (final text in value is List ? value : [value]) {
              if (text is! String) continue;
              final marked = WikiMarkup.parse(text);
              expect(
                broken.hasMatch(marked.text),
                isFalse,
                reason: '$language ${lesson.id} $key: marcação quebrada',
              );
              for (final mark in marked.marks) {
                expect(
                  links.url(mark.key, language),
                  isNotNull,
                  reason: '$language ${lesson.id} $key: ${mark.key} sem link',
                );
              }
            }
          }
        }
      }
    },
  );
}
