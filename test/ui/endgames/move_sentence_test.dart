import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/move_words.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/endgames/widgets/move_sentence.dart';

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));

  String say(AppLocalizations l10n, String fen, String uci, [String? symbol]) =>
      moveSentence(l10n, fenBefore: fen, uci: uci, symbol: symbol);

  const kingFen = '8/8/1K6/8/8/8/8/7k w - - 0 1';
  const pawnFen = '8/8/3P4/8/8/8/8/K6k w - - 0 1';
  const rooksFen = 'r6k/8/8/8/8/8/8/R6K w - - 0 1';
  const promoteFen = '8/1P5k/8/8/8/8/8/K7 w - - 0 1';
  const promoteCaptureFen = 'r7/1P5k/8/8/8/8/8/K7 w - - 0 1';

  test('peão: avança, sem notação, com a casa entre colchetes', () {
    expect(say(pt, pawnFen, 'd6d7'), 'O peão avança para [d7].');
    expect(say(en, pawnFen, 'd6d7'), 'The pawn advances to [d7].');
  });

  test('peça: nome e gênero certos em português', () {
    expect(say(pt, kingFen, 'b6c6'), 'O rei vai para [c6].');
    expect(say(pt, rooksFen, 'a1a2'), 'A torre vai para [a2].');
    expect(say(en, kingFen, 'b6c6'), 'The king goes to [c6].');
  });

  test('captura: a casa é a da peça capturada', () {
    expect(say(pt, rooksFen, 'a1a8'), 'A torre captura em [a8].');
    expect(say(en, rooksFen, 'a1a8'), 'The rook captures on [a8].');
  });

  test('promoção, com e sem captura', () {
    expect(
      say(pt, promoteFen, 'b7b8q'),
      'O peão vai a [b8] e é promovido a dama.',
    );
    expect(
      say(pt, promoteFen, 'b7b8n'),
      'O peão vai a [b8] e é promovido a cavalo.',
    );
    expect(
      say(pt, promoteCaptureFen, 'b7a8r'),
      'O peão captura em [a8] e é promovido a torre.',
    );
    expect(
      say(en, promoteFen, 'b7b8q'),
      'The pawn goes to [b8] and is promoted to queen.',
    );
  });

  test('lance ruim ou perdedor ganha a avaliação, sem notação', () {
    expect(
      say(pt, kingFen, 'b6c7', '?'),
      'O rei vai para [c7]. Esse lance não resolve o exercício.',
    );
    expect(
      say(pt, kingFen, 'b6c7', '??'),
      'O rei vai para [c7]. Esse lance é um erro grave.',
    );
    expect(
      say(pt, kingFen, 'b6c7', '!'),
      'O rei vai para [c7]. Esse lance faz parte da solução.',
    );
  });

  test('en passant conta como captura; FEN ruim não quebra', () {
    expect(
      MoveWords.of('8/8/8/3pP3/8/8/8/K6k w - d6 0 1', 'e5d6')?.capture,
      isTrue,
    );
    expect(MoveWords.of('lixo', 'e2e4'), isNull);
    expect(say(pt, 'lixo', 'e2e4'), '');
  });
}
