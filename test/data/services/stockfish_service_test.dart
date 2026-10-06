import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/stockfish_service.dart';

void main() {
  test('lê a linha, a avaliação e os lances de um info do Stockfish', () {
    final cp = StockfishService.parseInfo(
      'info depth 14 seldepth 18 multipv 2 score cp -35 nodes 12000 nps 400000 '
      'hashfull 3 tbhits 0 time 30 pv e7e5 g1f3 b8c6',
    );
    expect(cp, isNotNull);
    expect(cp!.$1, 2);
    expect(cp.$2.centipawns, -35);
    expect(cp.$2.mate, isNull);
    expect(cp.$2.moves, ['e7e5', 'g1f3', 'b8c6']);

    final mate = StockfishService.parseInfo(
      'info depth 9 seldepth 4 score mate 2 nodes 300 time 1 pv d1h5 g7g6',
    );
    expect(mate!.$1, 1);
    expect(mate.$2.mate, 2);
    expect(mate.$2.moves, ['d1h5', 'g7g6']);
  });

  test('ignora o que não é avaliação com lances e os limites (bound)', () {
    expect(StockfishService.parseInfo('info string NNUE evaluation'), isNull);
    expect(StockfishService.parseInfo('bestmove e2e4 ponder e7e5'), isNull);
    expect(
      StockfishService.parseInfo(
        'info depth 10 multipv 1 score cp 20 lowerbound nodes 1 pv e2e4',
      ),
      isNull,
    );
    expect(
      StockfishService.parseInfo(
        'info depth 10 currmove e2e4 currmovenumber 1',
      ),
      isNull,
    );
  });
}
