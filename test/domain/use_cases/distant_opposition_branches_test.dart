import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/variation_tree.dart';
import 'package:lucena/domain/use_cases/speech_lines.dart';
import 'package:lucena/domain/use_cases/speech_links.dart';
import 'package:lucena/domain/use_cases/variation_tree_builder.dart';
import 'package:lucena/domain/use_cases/wiki_markup.dart';

/// Dados reais da oposição distante (T68): cada sub-variante da lição existe,
/// joga legal a partir do ponto, parte da posição conferida no motor e tem
/// comentário em PT e EN.
void main() {
  const path = 'assets/lessons/%s/endgames/pawns.distantOpposition.json';
  Map<String, dynamic> read(String folder) =>
      jsonDecode(io.File(path.replaceFirst('%s', folder)).readAsStringSync())
          as Map<String, dynamic>;

  final lesson = AssetLessonRepository.parseLesson(
    jsonDecode(
      io.File('assets/lessons/endgames/pawns.distantOpposition.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>,
  );
  const id = 'pawns.distantOpposition';
  final pt = LessonTexts.fromJson(
    AssetEndgameLessonRepository.prefixed(id, read('pt')),
  );
  final en = LessonTexts.fromJson(
    AssetEndgameLessonRepository.prefixed(id, read('en')),
  );
  final rawPt = read('pt');

  // passo, fala, id do ramo, FEN do ponto de partida (depois de `at` lances).
  const expected = [
    ('intro', 'step.intro', 'g4', 2, '8/5k2/8/8/4K3/6P1/8/8 w - - 2 2'),
    (
      'convert',
      'step.convert.done',
      'g4',
      4,
      '8/5k2/8/4K3/8/6P1/8/8 w - - 4 3',
    ),
  ];

  for (final (stepId, textKey, branchId, at, fen) in expected) {
    test('$stepId: ramo $branchId existe, joga legal e tem comentário', () {
      final step = lesson.steps.firstWhere((s) => s.id == stepId);
      final cited = step.lines.firstWhere(
        (line) => line.branches.any((b) => b.id == branchId),
      );
      final letters = SpeechLinks.lettersFor('pt');
      final text = WikiMarkup.parse(rawPt[textKey] as String).text;
      final line = SpeechLines.find(SpeechLinks.find(text, letters), letters, [
        step.fen!,
      ]).firstWhere((l) => cited.matches([for (final m in l.moves) m.uci]));
      final tree = VariationTreeBuilder.fromSpeech(
        line: line,
        branches: cited.branches,

        comment: (branch, ply) => pt.alternative(id, stepId, branch, ply),
      );
      final branch = tree.branchOf(branchId);
      expect(branch, isNotNull, reason: 'o ramo precisa jogar legal');
      expect(branch!.at, at);
      expect(line.fens[at], fen);
      expect(branch.result, VariationResult.draw);
      expect(branch.moves.first.move?.uci, isNot(line.moves[at].uci));
      expect(branch.comment, isNotEmpty);
      expect(en.alternative(id, stepId, branchId), isNotEmpty);
    });
  }
}
