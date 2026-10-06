import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/game_export.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

void main() {
  test('PGN com a posição de início e os números dos lances', () {
    final pgn = GameExport.pgn(
      startFen: '7k/8/5K2/8/8/8/8/6Q1 w - - 0 12',
      sans: ['Qg2', 'Kh7', 'Qg7#'],
      result: '1-0',
      white: 'Jogador',
      black: 'Tito',
      date: DateTime(2026, 10, 6),
    );
    expect(pgn, contains('[FEN "7k/8/5K2/8/8/8/8/6Q1 w - - 0 12"]'));
    expect(pgn, contains('[Date "2026.10.06"]'));
    expect(pgn, contains('[White "Jogador"]'));
    expect(pgn.split('\n').last, '12. Qg2 Kh7 13. Qg7# 1-0');
  });

  test('começando com as pretas, o primeiro lance leva reticências', () {
    final pgn = GameExport.pgn(
      startFen: '7k/8/5K2/8/8/8/8/6Q1 b - - 0 5',
      sans: ['Kh7', 'Qg7#'],
    );
    expect(pgn.split('\n').last, '5... Kh7 6. Qg7# *');
  });

  test('endereços da análise no Lichess e no chess.com, na posição', () {
    const fen = '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1';
    expect(
      GameExport.lichess(fen).toString(),
      'https://lichess.org/analysis/standard/7k/8/5K2/8/8/8/8/6Q1_w_-_-_0_1',
    );
    final chessCom = GameExport.chessCom(fen);
    expect(chessCom.host, 'www.chess.com');
    expect(chessCom.path, '/analysis');
    expect(chessCom.queryParameters['fen'], fen);
  });

  test(
    'a linha da engine em notação algébrica, até o primeiro lance ilegal',
    () {
      final start = GameRules.fromFen('7k/8/5K2/8/8/8/8/6Q1 w - - 0 1')!;
      expect(GameRules.sanLine(start, ['g1g2', 'h8h7', 'g2g7']), [
        'Qg2',
        'Kh7',
        'Qg7#',
      ]);
      expect(GameRules.sanLine(start, ['g1g2', 'a1a2', 'g2g7']), ['Qg2']);
      expect(GameRules.sanLine(start, ['g1g2', 'h8h7'], max: 1), ['Qg2']);
    },
  );
}
