import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';

import 'placement_fixtures.dart';

void main() {
  group('SkillMap', () {
    test('lê o formato do contrato', () {
      final skills = smallSkills();
      final bishop = skills.node('rules.bishop')!;
      expect(bishop.group, SkillGroup.rules);
      expect(bishop.band, RatingLevel.beginner);
      expect(bishop.requires, isEmpty);
      expect(bishop.lessons.single.id, 'pieces.bishop');
      expect(bishop.lessons.single.kind, SkillLessonKind.school);
      expect(skills.node('tactics.basic')!.midgameTactic, isTrue);
      expect(
        skills.node('tactics.endgame')!.lessons.single.kind,
        SkillLessonKind.proposed,
      );
      expect(skills.node('nada'), isNull);
    });

    test('ordem topológica: todo nó depois dos pré-requisitos', () {
      final skills = SkillMap([
        const SkillNode(
          id: 'b',
          group: SkillGroup.rules,
          band: RatingLevel.beginner,
          requires: ['a'],
        ),
        const SkillNode(
          id: 'a',
          group: SkillGroup.rules,
          band: RatingLevel.beginner,
        ),
        const SkillNode(
          id: 'c',
          group: SkillGroup.rules,
          band: RatingLevel.beginner,
        ),
      ]);
      expect(skills.nodes.map((n) => n.id), ['a', 'b', 'c']);
      expect(skills.indexOf('b'), 1);
      expect(skills.indexOf('x'), -1);
    });

    test('pré-requisitos e dependentes, diretos e indiretos', () {
      final skills = smallSkills();
      expect(skills.prerequisitesOf('rook.philidor'), {
        'rook.lucena',
        'mate.queen',
        'rules.queen',
        'rules.rook',
        'rules.bishop',
      });
      expect(skills.prerequisitesOf('rules.rook'), isEmpty);
      expect(skills.dependentsOf('rules.bishop'), {
        'rules.queen',
        'mate.queen',
        'rook.lucena',
        'rook.philidor',
      });
    });

    test('recusa ciclo, nó repetido e pré-requisito que não existe', () {
      SkillNode node(String id, [List<String> requires = const []]) =>
          SkillNode(
            id: id,
            group: SkillGroup.pawns,
            band: RatingLevel.casual,
            requires: requires,
          );
      expect(
        () => SkillMap([
          node('a', ['b']),
          node('b', ['a']),
        ]),
        throwsFormatException,
      );
      expect(() => SkillMap([node('a'), node('a')]), throwsFormatException);
      expect(
        () => SkillMap([
          node('a', ['x']),
        ]),
        throwsFormatException,
      );
      expect(
        () => SkillMap.fromJson({
          'nodes': [
            {'id': 'a', 'group': 'nada', 'band': 'casual'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('ida e volta em JSON', () {
      final skills = smallSkills();
      final again = SkillMap.fromJson(
        jsonDecode(jsonEncode(skills.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), skills.toJson());
    });

    test('aula com prefixo vale para todas as do prefixo', () {
      const lesson = SkillLesson(id: 'tricks.*', kind: SkillLessonKind.school);
      expect(lesson.matches('tricks.foolsMate'), isTrue);
      expect(lesson.matches('tricksx.foolsMate'), isFalse);
      const exact = SkillLesson(
        id: 'rook.lucena',
        kind: SkillLessonKind.endgame,
      );
      expect(exact.matches('rook.lucena'), isTrue);
      expect(exact.matches('rook.lucena.2'), isFalse);
    });
  });

  group('PlacementItem', () {
    final json = <String, dynamic>{
      'id': 'own.mate.inOne.1',
      'node': 'mate.inOne',
      'type': 'move',
      'difficulty': 650.4,
      'fen': '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
      'prompt': 'placementMate',
      'params': {'side': 'white', 'count': 1},
      'moves': ['a1a8'],
      'accept': [
        ['a1a8'],
      ],
      'source': 'lichess',
      'themes': ['mateIn1', 'backRankMate'],
    };

    test('lê o formato do contrato', () {
      final item = PlacementItem.fromJson(json);
      expect(item.type, PlacementItemType.move);
      expect(item.difficulty, 650);
      expect(item.params, {'side': 'white', 'count': '1'});
      expect(item.source, PlacementSource.lichess);
      expect(item.themes, ['mateIn1', 'backRankMate']);
      expect(item.optionCount, 0);
      expect(item.playerMoves, 1);
      expect(item.acceptsMove(0, 'a1a8'), isTrue);
      expect(item.acceptsMove(0, 'a1a7'), isFalse);
      expect(PlacementItem.fromJson(item.toJson()).toJson(), item.toJson());
    });

    test('move sem accept usa a linha; mate em um aceita qualquer mate', () {
      final line = PlacementItem.fromJson({
        ...json,
        'moves': ['e1e2', 'e8e7', 'e2e3'],
        'accept': <List<String>>[],
      });
      expect(line.playerMoves, 2);
      expect(line.acceptsMove(0, 'e1e2'), isTrue);
      expect(line.acceptsMove(1, 'e2e3'), isTrue);
      expect(line.acceptsMove(1, 'e8e7'), isFalse);
      final mate = PlacementItem.fromJson({
        ...json,
        'accept': [
          ['h1h8', 'h1a8'],
        ],
      });
      expect(mate.acceptsMove(0, 'h1a8'), isTrue);
    });

    test('squares exige todas as casas, sem sobrar', () {
      final item = PlacementItem.fromJson({
        'id': 'own.rules.bishop.1',
        'node': 'rules.bishop',
        'type': 'squares',
        'difficulty': 500,
        'fen': '8/8/8/3B4/8/8/8/8 w - - 0 1',
        'prompt': 'placementSquares',
        'params': {'piece': 'bishop'},
        'squares': ['a1', 'b2'],
      });
      expect(item.source, PlacementSource.own);
      expect(item.acceptsSquares(['b2', 'a1']), isTrue);
      expect(item.acceptsSquares(['a1']), isFalse);
      expect(item.acceptsSquares(['a1', 'b2', 'c3']), isFalse);
    });

    test('choice: opções, resposta e chute', () {
      final item = PlacementItem.fromJson({
        'id': 'own.rules.stalemate.1',
        'node': 'rules.stalemate',
        'type': 'choice',
        'difficulty': 700,
        'fen': '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
        'prompt': 'placementMateOrStalemate',
        'options': ['mate', 'stalemate', 'none'],
        'answer': 'stalemate',
      });
      expect(item.optionCount, 3);
      expect(item.acceptsChoice('stalemate'), isTrue);
      expect(item.acceptsChoice('mate'), isFalse);
    });

    test('banco: ida e volta e busca por id', () {
      final bank = PlacementBank.fromJson({
        'items': [json],
      });
      expect(bank.item('own.mate.inOne.1')!.node, 'mate.inOne');
      expect(bank.item('x'), isNull);
      expect(PlacementBank.fromJson(bank.toJson()).items.length, 1);
    });
  });

  group('PlacementState e PlacementResult', () {
    test('fases por número da pergunta', () {
      expect(PlacementPhase.of(0), PlacementPhase.screening);
      expect(PlacementPhase.of(3), PlacementPhase.screening);
      expect(PlacementPhase.of(4), PlacementPhase.adaptation);
      expect(PlacementPhase.of(15), PlacementPhase.adaptation);
      expect(PlacementPhase.of(16), PlacementPhase.confirmation);
      expect(PlacementPhase.of(19), PlacementPhase.confirmation);
    });

    test('estado: ida e volta em JSON', () {
      final state = PlacementState(
        theta: 1333.5,
        initialTheta: 1200,
        seed: 7,
        answered: [
          const PlacementAnswer(
            itemId: 'a',
            node: 'rules.rook',
            difficulty: 600,
            outcome: PlacementOutcome.dontKnow,
            phase: PlacementPhase.screening,
            options: 2,
            elapsed: Duration(milliseconds: 4200),
            thetaAfter: 1100,
          ),
        ],
        evidence: {'rules.rook': const NodeEvidence().add(correct: false)},
      );
      final again = PlacementState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), state.toJson());
      expect(again.questionNumber, 2);
      expect(again.phase, PlacementPhase.screening);
      expect(again.answered.single.outcome, PlacementOutcome.dontKnow);
      expect(again.answered.single.elapsed, const Duration(milliseconds: 4200));
      expect(again.choiceCount, 1);
      expect(again.evidence['rules.rook']!.wrong, 1);
    });

    test('resultado: ida e volta, faixa e faixas do intervalo', () {
      final result = PlacementResult(
        theta: 1580,
        low: 1450,
        high: 1720,
        nodes: const {'rules.rook': mastered, 'pawns.reti': gap},
        takenAt: DateTime.utc(2026, 10, 8, 9, 30),
        answers: [answered('a', 'rules.rook', index: 0)],
      );
      expect(result.level, RatingLevel.intermediate);
      expect(result.levels, [RatingLevel.intermediate, RatingLevel.advanced]);
      expect(result.status('nada'), NodeStatus.unknown);
      final again = PlacementResult.fromJson(
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), result.toJson());
      expect(again.takenAt, result.takenAt);
      expect(again.status('pawns.reti'), gap);
    });

    test('evidência: a última resposta fica marcada', () {
      final evidence = const NodeEvidence()
          .add(correct: true, fast: true)
          .add(correct: false);
      expect(evidence.correct, 1);
      expect(evidence.wrong, 1);
      expect(evidence.fastCorrect, 1);
      expect(evidence.lastCorrect, isFalse);
      expect(evidence.mixed, isTrue);
    });
  });
}
