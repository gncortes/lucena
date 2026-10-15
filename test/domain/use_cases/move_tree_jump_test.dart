import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/move_tree.dart';

/// O ex1 da oposição distante tem saltos sem lance: "imagine g4" (vai a uma
/// posição a um lance da linha), a volta a 2.Rf5 e a volta a 1.Re4.
void main() {
  final real = LessonScript.fromJson(
    jsonDecode(
      File('assets/lessons/roteiros/pawns.distantOpposition/distant.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>,
  );
  final ex1 = real.stages[0].examples[0];
  final tree = MoveTree.build(ex1);
  MoveNode at(String id) => tree.node(id)!;

  test('"imagine g4" vira a variante de 2.Rf5, com 2...Rg6 nela', () {
    final g4 = at('d3e4-e8f7-g3g4');
    expect(g4.san, 'g4');
    expect(g4.number, 2);
    expect(g4.variant, isTrue);
    expect(at('d3e4-e8f7-g3g4-f7g6').variant, isTrue);
    expect(at('d3e4-e8f7-e4f5').variant, isFalse);
    // O passo do salto joga o g4: é o lance atual dele.
    expect(tree.of(ex1.line[13]).map((n) => n.id), ['d3e4-e8f7-g3g4']);
    expect(tree.of(ex1.line[14]).single.id, 'd3e4-e8f7-g3g4-f7g6');
  });

  test('a volta a 2.Rf5 não repete o lance e segue a principal', () {
    expect(tree.nodes.where((n) => n.id == 'd3e4-e8f7-e4f5'), hasLength(1));
    final kg7 = at('d3e4-e8f7-e4f5-f7g7');
    expect(kg7.variant, isFalse);
    expect(tree.of(kg7.step).map((n) => n.id), contains(kg7.id));
  });

  test('a volta a 1.Re4 abre 1...Re7 como irmão de 1...Rf7', () {
    expect(at('d3e4-e8f7').variant, isFalse);
    expect(at('d3e4-e8e7').variant, isTrue);
  });
}
