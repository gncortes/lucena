import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/placement_roadmap.dart';

import 'placement_fixtures.dart';

void main() {
  final skills = smallSkills();

  PlacementRoadmap build(
    Map<String, NodeStatus> nodes, {
    int theta = 1450,
    Set<String> completedSchool = const {},
    Set<String> completedEndgames = const {},
  }) => PlacementRoadmap.build(
    result: resultWith(nodes, theta: theta),
    skills: skills,
    schoolLessons: smallSchool,
    endgameLessons: smallEndgames,
    completedSchool: completedSchool,
    completedEndgames: completedEndgames,
  );

  group('Escola do Viktor', () {
    test('torre e dama sabidas, bispo não: começa pelo bispo', () {
      final roadmap = build({
        'rules.rook': mastered,
        'rules.queen': mastered,
        'rules.bishop': gap,
      }, theta: mid(RatingLevel.beginner));
      expect(roadmap.skippedSchool, {
        'pieces.rook': SkipReason.confirmed,
        'pieces.queen': SkipReason.confirmed,
      });
      expect(roadmap.nextSchool, 'pieces.bishop');
      expect(roadmap.next!.lessonId, 'pieces.bishop');
      expect(roadmap.nodes.first, 'rules.bishop');
    });

    test('dispensa provável e confirmada têm selos diferentes', () {
      final roadmap = build({
        'rules.rook': mastered,
        'rules.bishop': likely,
        'rules.queen': const NodeStatus(NodeState.mastered),
      });
      expect(roadmap.skippedSchool['pieces.rook'], SkipReason.confirmed);
      expect(roadmap.skippedSchool['pieces.bishop'], SkipReason.likely);
      // "Domina" inferido não é confirmado.
      expect(roadmap.skippedSchool['pieces.queen'], SkipReason.likely);
    });

    test(
      'aula feita depois do teste conta como feita, não como dispensada',
      () {
        final roadmap = build(
          {'rules.rook': mastered, 'rules.bishop': gap},
          completedSchool: {'pieces.rook', 'pieces.bishop'},
        );
        expect(roadmap.skippedSchool, isNot(contains('pieces.rook')));
        expect(roadmap.nodes, isNot(contains('rules.bishop')));
        expect(roadmap.nextSchool, isNot('pieces.bishop'));
      },
    );

    test('sem passo da escola no roteiro: a primeira aula nem feita nem '
        'dispensada', () {
      final all = {for (final node in skills.nodes) node.id: mastered};
      final roadmap = build(all);
      // tricks.* é só da tática de meio-jogo: não é dispensada pelo mapa.
      expect(roadmap.nextSchool, 'tricks.scholarsMate');
      expect(
        roadmap.skippedSchool.keys,
        containsAll(['pieces.rook', 'mates.queen']),
      );
    });

    test('escola inteira feita ou dispensada: nada a seguir', () {
      final all = {for (final node in skills.nodes) node.id: mastered};
      final roadmap = build(
        all,
        completedSchool: {'tricks.scholarsMate', 'tricks.foolsMate'},
      );
      expect(roadmap.nextSchool, isNull);
      expect(roadmap.schoolSteps, isEmpty);
    });
  });

  group('trilha de finais', () {
    test('já domina, recomendada e os próximos', () {
      final roadmap = build({
        'mate.queen': mastered,
        'rook.lucena': gap,
      }, theta: mid(RatingLevel.intermediate));
      expect(roadmap.endgameBadges['basics.queenMate'], EndgameBadge.mastered);
      final ready = roadmap.endgameSteps.firstWhere((step) => !step.soon);
      expect(roadmap.endgameBadges[ready.lessonId], EndgameBadge.recommended);
      expect(roadmap.endgameBadges, isNot(contains('rook.philidor')));
      expect(roadmap.nextEndgame!.lessonId, 'rook.lucena');
      expect(roadmap.followingEndgames().map((s) => s.lessonId), [
        'rook.philidor',
        'pawns.reti',
        'tactics.endgameTricks',
      ]);
    });

    test('aula do catálogo aparece como "em breve"', () {
      final roadmap = build({
        'pawns.opposition': mastered,
        'pawns.reti': gap,
      }, theta: mid(RatingLevel.advanced));
      final reti = roadmap.nextEndgame!;
      expect(reti.node, 'pawns.reti');
      expect(reti.soon, isTrue);
      expect(reti.school, isFalse);
      // Só aula que existe ganha o selo de recomendada: a primeira feita do
      // roteiro.
      expect(roadmap.endgameBadges, isNot(contains('pawns.reti')));
      final ready = roadmap.endgameSteps.firstWhere((step) => !step.soon);
      expect(roadmap.endgameBadges[ready.lessonId], EndgameBadge.recommended);
      expect(
        roadmap.skippedSchool['technique.opposition'],
        SkipReason.confirmed,
      );
    });

    test('aula de finais feita depois do teste: a recomendação anda', () {
      final roadmap = build(
        {'rook.lucena': gap, 'rook.philidor': gap},
        completedEndgames: {'rook.lucena'},
      );
      expect(roadmap.endgameBadges['rook.philidor'], EndgameBadge.recommended);
      expect(roadmap.endgameBadges, isNot(contains('rook.lucena')));
      expect(roadmap.nodes, isNot(contains('rook.lucena')));
    });

    test('ordem: lacunas primeiro, depois os desconhecidos até a faixa '
        'seguinte', () {
      final roadmap = build({
        'rules.rook': likely,
        'rules.bishop': likely,
        'rules.queen': likely,
        'mate.queen': likely,
        'pawns.opposition': likely,
        'pawns.reti': gap,
      }, theta: mid(RatingLevel.intermediate));
      expect(roadmap.nodes.first, 'pawns.reti');
      expect(
        roadmap.nodes,
        containsAllInOrder(['rook.lucena', 'rook.philidor']),
      );
    });
  });

  test('tática de meio-jogo: no resultado, nunca no roteiro', () {
    final roadmap = build({'tactics.basic': gap});
    expect(roadmap.nodes, isNot(contains('tactics.basic')));
    expect(
      roadmap.steps.where((step) => step.node == 'tactics.basic'),
      isEmpty,
    );
    // E não dispensa as aulas dela mesmo se dominada.
    final strong = build({'tactics.basic': mastered});
    expect(
      strong.skippedSchool.keys.where((id) => id.startsWith('tricks.')),
      isEmpty,
    );
  });

  test(
    'aula nova de nó avançado vai para a trilha de finais como em breve',
    () {
      final roadmap = build({
        'tactics.endgame': gap,
      }, theta: mid(RatingLevel.advanced));
      final step = roadmap.steps.firstWhere(
        (step) => step.node == 'tactics.endgame',
      );
      expect(step.soon, isTrue);
      expect(step.school, isFalse);
      expect(step.lessonId, 'tactics.endgameTricks');
    },
  );
}
