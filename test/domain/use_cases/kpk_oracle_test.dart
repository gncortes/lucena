import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';

void main() {
  group('índice e normalização (tabela sintética)', () {
    Uint8List table(int index, int value) {
      final bytes = Uint8List(KpkTableOracle.size);
      bytes[index] = value;
      return bytes;
    }

    // Ex1 4k3/8/8/8/8/3K2P1/8/8 w: peão g3 espelha para b3 (coluna 1,
    // fileira 3), rei branco d3 vira e3, rei preto e8 vira d8.
    final ex1 = KpkTableOracle.index(
      column: 1,
      pawnRank: 2,
      whiteKing: 2 * 8 + 4,
      blackKing: 7 * 8 + 3,
      turn: 0,
    );

    test('peão branco na ala do rei é espelhado para a–d', () {
      final oracle = KpkTableOracle(table(ex1, 25));
      expect(
        oracle.evaluateFen('4k3/8/8/8/8/3K2P1/8/8 w - - 0 1'),
        const KpkOutcome.win(25),
      );
    });

    test('peão preto vira branco por espelho vertical, com a vez trocada', () {
      final oracle = KpkTableOracle(table(ex1, 25));
      expect(
        oracle.evaluateFen('8/8/3k2p1/8/8/8/8/4K3 b - - 0 1'),
        const KpkOutcome.win(25),
      );
    });

    test(
      'o índice tem uma posição por combinação e cabe nos 196 608 bytes',
      () {
        expect(KpkTableOracle.size, 196608);
        expect(
          KpkTableOracle.index(
            column: 3,
            pawnRank: 6,
            whiteKing: 63,
            blackKing: 63,
            turn: 1,
          ),
          KpkTableOracle.size - 1,
        );
      },
    );

    test('0 é empate e 255 é fora da tabela', () {
      final oracle = KpkTableOracle(table(ex1, 0));
      expect(
        oracle.evaluateFen('4k3/8/8/8/8/3K2P1/8/8 w - - 0 1'),
        KpkOutcome.draw,
      );
      expect(
        KpkTableOracle(table(ex1, 255))
            .evaluateFen('4k3/8/8/8/8/3K2P1/8/8 w - - 0 1'),
        KpkOutcome.outside,
      );
    });

    test('tamanho errado é recusado', () {
      expect(() => KpkTableOracle(Uint8List(10)), throwsArgumentError);
    });
  });

  group('sem peão ou com mais peças', () {
    final oracle = KpkTableOracle(Uint8List(KpkTableOracle.size));

    test('só os reis: empate (o peão caiu)', () {
      expect(
        oracle.evaluateFen('4k3/8/8/8/8/3K4/8/8 w - - 0 1'),
        KpkOutcome.draw,
      );
    });

    test('dama coroada: vitória', () {
      expect(
        oracle.evaluateFen('4k3/8/8/8/8/3K4/8/6Q1 b - - 0 1').isWin,
        isTrue,
      );
    });

    test('dama coroada que deixa o rei sem lances: afogamento, empate', () {
      expect(
        oracle.evaluateFen('7k/5K2/6Q1/8/8/8/8/8 b - - 0 1'),
        KpkOutcome.draw,
      );
    });

    test('dama coroada indefesa que o rei captura: empate', () {
      expect(
        oracle.evaluateFen('7k/7Q/8/8/8/8/8/K7 b - - 0 1'),
        KpkOutcome.draw,
      );
    });

    test('dama coroada defendida pelo rei: vitória', () {
      expect(oracle.evaluateFen('7k/7Q/6K1/8/8/8/8/8 b - - 0 1').isWin, isTrue);
    });

    test('mais de um peão ou outra peça: fora da tabela', () {
      expect(
        oracle.evaluateFen('4k3/8/8/8/8/3K2P1/7P/8 w - - 0 1'),
        KpkOutcome.outside,
      );
      expect(
        oracle.evaluateFen('4k3/8/8/8/8/3K2P1/8/R7 w - - 0 1'),
        KpkOutcome.outside,
      );
      expect(oracle.evaluateFen('lixo'), KpkOutcome.outside);
    });
  });

  group('tabela real', () {
    final bin = File('assets/tablebase/kpk.bin');
    final checks = File('tools/tablebase/kpk_checks.json');
    final skip = !bin.existsSync() || !checks.existsSync()
        ? 'kpk.bin ou kpk_checks.json ainda não existem'
        : null;

    test('confere as posições do gerador (python-chess)', () {
      final oracle = KpkTableOracle(bin.readAsBytesSync());
      final json = jsonDecode(checks.readAsStringSync()) as Map;
      final positions = (json['posicoes'] as List).cast<Map>();
      expect(positions.length, greaterThanOrEqualTo(20));
      for (final p in positions) {
        final byte = p['byte'] as int;
        final expected = byte == 255
            ? KpkOutcome.outside
            : byte == 0
            ? KpkOutcome.draw
            : KpkOutcome.win(byte);
        expect(
          oracle.evaluateFen(p['fen'] as String),
          expected,
          reason: '${p['nota']}: ${p['fen']}',
        );
      }
    }, skip: skip);

    test(
      'as sete posições do contrato ganham ou seguram como o roteiro diz',
      () {
        final oracle = KpkTableOracle(bin.readAsBytesSync());
        const wins = [
          '4k3/8/8/8/8/3K2P1/8/8 w - - 0 1',
          '8/4k3/8/8/8/8/3K2P1/8 w - - 0 1',
          '4k3/8/8/8/8/1P3K2/8/8 w - - 0 1',
        ];
        const draws = [
          '4k3/8/8/8/8/4K1P1/8/8 b - - 0 1',
          '8/4k3/8/8/8/8/3K2P1/8 b - - 0 1',
          '8/4k3/8/8/8/8/4K1P1/8 b - - 0 1',
          '8/1k6/8/8/8/8/2K3P1/8 b - - 0 1',
        ];
        for (final fen in wins) {
          expect(oracle.evaluateFen(fen).isWin, isTrue, reason: fen);
        }
        for (final fen in draws) {
          expect(oracle.evaluateFen(fen).isDraw, isTrue, reason: fen);
        }
      },
      skip: skip,
    );
  });
}
