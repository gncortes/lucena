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
  final rawEn = read('en');

  // passo, fala, id do ramo, FEN do ponto de partida (depois de `at` lances).
  final expected = [
    ('intro', 'step.intro', 'g4', 2, '8/5k2/8/8/4K3/6P1/8/8 w - - 2 2'),
    (
      'convert',
      'step.convert.done',
      'g4',
      4,
      '8/5k2/8/4K3/8/6P1/8/8 w - - 4 3',
    ),
    // 1.Re4 Rf8 2.Rf5 (2.g4? Rg7 =)
    ('intro', 'step.intro', 'g4f8', 2, '5k2/8/8/8/4K3/6P1/8/8 w - - 2 2'),
    // 1.Rf4 Re6 2.Re4 (2.e4? Rf6! =)
    ('diagonal', 'step.diagonal', 'e4', 2, '8/8/4k3/8/5K2/4P3/8/8 w - - 2 2'),
    // 1.Re2 Re7 2.Re3 (2.Rd3? Rd7 =; 2.Rf3? Rf7 =)
    for (final branchId in ['kd3', 'kf3'])
      (
        'capablanca',
        'step.capablanca',
        branchId,
        2,
        '8/4k3/8/1p5p/1P5P/8/4K3/8 w - - 2 2',
      ),
    // A armadilha: 1.Re2 Rf8!? 2.Rd3 Re7 3.Re3 (2.Re3?? Re7 =;
    // 2.Rf3? Rf7 =; 3.Re4? Re6 =).
    for (final branchId in ['ke3', 'kf3'])
      (
        'capablancaMove',
        'step.capablancaMove.done',
        branchId,
        2,
        '5k2/8/8/1p5p/1P5P/8/4K3/8 w - - 2 2',
      ),
    (
      'capablancaMove',
      'step.capablancaMove.done',
      'ke4',
      4,
      '8/4k3/8/1p5p/1P5P/3K4/8/8 w - - 4 3',
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
      // A citação mais longa da linha: "1.Rf4" sozinho também começa igual.
      final line =
          SpeechLines.find(SpeechLinks.find(text, letters), letters, [
                step.fen!,
              ])
              .where((l) => cited.matches([for (final m in l.moves) m.uci]))
              .reduce((a, b) => b.length > a.length ? b : a);
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
      // A resposta destacada tem fala própria ("Este lance segura o
      // empate"), sem repetir o lance tocado.
      expect(branch.commentAt(2), isNot(branch.comment));
      expect(branch.commentAt(2), startsWith('Este '));
      expect(en.alternative(id, stepId, branchId), isNotEmpty);
      // A fala em inglês cita a mesma linha.
      final lettersEn = SpeechLinks.lettersFor('en');
      final textEn = WikiMarkup.parse(rawEn[textKey] as String).text;
      expect(
        SpeechLines.find(SpeechLinks.find(textEn, lettersEn), lettersEn, [
          step.fen!,
        ]).any((l) => cited.matches([for (final m in l.moves) m.uci])),
        isTrue,
        reason: 'a fala em inglês precisa citar a linha',
      );
    });
  }
}
