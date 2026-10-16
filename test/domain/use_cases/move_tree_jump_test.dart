import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/move_tree.dart';

/// O ex1 da oposição distante tem saltos sem lance: a volta de "e se f4?" a
/// 1...Rf7, a volta a 2.Rf5 e as voltas a 1.Re4 para as outras defesas.
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

  test('"e se f4?": 2.Rf4 e 2...Rf6 ficam na variante de 2.Rf5', () {
    final f4 = at('d3e4-e8f7-e4f4');
    expect(f4.san, 'Kf4');
    expect(f4.number, 2);
    expect(f4.variant, isTrue);
    expect(at('d3e4-e8f7-e4f4-f7f6').variant, isTrue);
    expect(at('d3e4-e8f7-e4f5').variant, isFalse);
    // O passo da variante joga os dois lances; o último é o atual.
    expect(tree.of(ex1.line[5]).last.id, 'd3e4-e8f7-e4f4-f7f6');
  });

  test('a volta a 2.Rf5 não repete o lance e segue a principal', () {
    expect(tree.nodes.where((n) => n.id == 'd3e4-e8f7-e4f5'), hasLength(1));
    final kg7 = at('d3e4-e8f7-e4f5-f7g7');
    expect(kg7.variant, isFalse);
    expect(tree.of(kg7.step).map((n) => n.id), contains(kg7.id));
  });

  test('as voltas a 1.Re4 abrem 1...Rf8 e 1...Re7 como irmãos de 1...Rf7', () {
    expect(at('d3e4-e8f7').variant, isFalse);
    expect(at('d3e4-e8e7').variant, isTrue);
    expect(at('d3e4-e8f8').variant, isTrue);
  });
}
