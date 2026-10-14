import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/use_cases/free_play_referee.dart';

const start = '4k3/8/8/8/8/3K2P1/8/8 w - - 0 1';

FreeEnd? check(List<String> fens, {int limit = 40}) =>
    FreePlayReferee.check(fens, limit: limit);

void main() {
  test('o jogo segue sem fim', () {
    expect(check([start]), isNull);
  });

  test('coroou: sobra uma dama no lugar do peão', () {
    expect(check([start, '4k1Q1/8/8/8/8/3K4/8/8 b - - 0 1']), FreeEnd.coroa);
  });

  test('capturado: só os reis', () {
    expect(check([start, '8/8/8/8/8/3K4/8/4k3 w - - 0 1']), FreeEnd.capturado);
  });

  test('afogado: sem lances e sem xeque', () {
    expect(check([start, '7k/5P2/6K1/8/8/8/8/8 b - - 0 1']), FreeEnd.afogado);
  });

  test('repetição: a mesma posição três vezes', () {
    const a = '4k3/8/8/8/8/3K2P1/8/8 w - - 0 1';
    const b = '3k4/8/8/8/8/3K2P1/8/8 b - - 1 1';
    const c = '3k4/8/8/8/8/4K1P1/8/8 w - - 2 2';
    const d = '4k3/8/8/8/8/4K1P1/8/8 b - - 3 2';
    // a aparece em 0, 4 e 8 (o contador de lances não conta).
    const a2 = '4k3/8/8/8/8/3K2P1/8/8 w - - 4 3';
    final line = [a, b, c, d, a2, b, c, d];
    expect(check(line), isNull, reason: 'só duas vezes');
    expect(
      check([...line, '4k3/8/8/8/8/3K2P1/8/8 w - - 8 5']),
      FreeEnd.repeticao,
    );
  });

  test('limite: lances completos, dois meios-lances cada', () {
    final line = [for (var i = 0; i < 81; i++) _distinct(i)];
    expect(check(line.sublist(0, 80), limit: 40), isNull);
    expect(check(line, limit: 40), FreeEnd.limite);
    expect(check(line, limit: 41), isNull);
  });

  test('o mesmo FEN com contadores diferentes é a mesma posição', () {
    const a = '4k3/8/8/8/8/3K2P1/8/8 w - - 0 1';
    expect(check([a, a, a]), FreeEnd.repeticao);
  });

  group('objetivo mate', () {
    const rooks = 'k7/7R/8/8/8/8/8/K5R1 w - - 0 1';
    test('sem peão não é coroa: o jogo segue', () {
      expect(FreePlayReferee.check([rooks], limit: 40, mate: true), isNull);
    });

    test('mate', () {
      expect(
        FreePlayReferee.check(
          [rooks, 'k5R1/7R/8/8/8/8/8/K7 b - - 1 1'],
          limit: 40,
          mate: true,
        ),
        FreeEnd.mate,
      );
    });

    test('afogado, insuficiente e limite', () {
      expect(
        FreePlayReferee.check(
          ['k7/2Q5/1K6/8/8/8/8/8 b - - 1 1'],
          limit: 40,
          mate: true,
        ),
        FreeEnd.afogado,
      );
      expect(
        FreePlayReferee.check(
          ['8/1k6/8/8/8/8/K7/8 w - - 0 2'],
          limit: 40,
          mate: true,
        ),
        FreeEnd.insuficiente,
      );
      expect(
        FreePlayReferee.check(
          [
            rooks,
            'k7/7R/8/8/8/8/8/1K4R1 b - - 1 1',
            '1k6/7R/8/8/8/8/8/1K4R1 w - - 2 2',
          ],
          limit: 1,
          mate: true,
        ),
        FreeEnd.limite,
      );
    });
  });
}

/// 81 posições diferentes de rei e peão (peão em h2), nenhuma três vezes.
String _distinct(int i) {
  final whiteKing = i % 6; // a1–f1
  final blackKing = (i ~/ 6) % 8; // a8–h8
  final turn = (i ~/ 48).isEven ? 'w' : 'b';
  return '${_row('k', blackKing)}/8/8/8/8/8/7P/${_row('K', whiteKing)} $turn - - 0 1';
}

String _row(String king, int at) {
  final out = StringBuffer();
  var gap = 0;
  for (var file = 0; file < 8; file++) {
    if (file == at) {
      if (gap > 0) out.write(gap);
      gap = 0;
      out.write(king);
    } else {
      gap++;
    }
  }
  if (gap > 0) out.write(gap);
  return out.toString();
}
