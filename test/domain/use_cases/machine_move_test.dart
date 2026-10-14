import 'dart:io';

import 'package:dartchess/dartchess.dart' show Move;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';
import 'package:lucena/domain/use_cases/machine_move.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';

String? choose(KpkOracle oracle, String fen) =>
    MachineMove.choose(oracle, GameRules.fromFen(fen)!);

void main() {
  group('atacante', () {
    test('escolhe o lance ganhador de menor DTM', () {
      // Só 'e1e2' tem DTM menor; os outros demoram mais ou empatam.
      final oracle = FakeKpkOracle(
        rule: (p) {
          final king = p.board.kingOf(p.turn.opposite)!.name;
          return switch (king) {
            'e2' => const KpkOutcome.win(4),
            'd1' => const KpkOutcome.win(8),
            _ => KpkOutcome.draw,
          };
        },
      );
      expect(choose(oracle, '8/8/8/8/8/k7/6P1/4K3 w - - 0 1'), 'e1e2');
    });

    test('com DTM igual, desempata pela ordem do UCI', () {
      final oracle = FakeKpkOracle();
      expect(choose(oracle, '8/8/8/8/8/k7/6P1/4K3 w - - 0 1'), 'e1d1');
    });

    test('coroa em dama, nunca em outra peça', () {
      final oracle = FakeKpkOracle(
        rule: (p) => p.board.pawns.isEmpty
            ? const KpkOutcome.win(0)
            : const KpkOutcome.win(9),
      );
      expect(choose(oracle, '8/6P1/8/4K3/8/8/8/k7 w - - 0 1'), 'g7g8q');
    });

    test('sem lance ganhador, mantém o empate', () {
      final oracle = FakeKpkOracle(fallback: KpkOutcome.draw);
      expect(choose(oracle, '8/8/8/8/8/k7/6P1/4K3 w - - 0 1'), isNotNull);
    });
  });

  group('defensor', () {
    test('vai para perto da casa à frente do peão', () {
      final oracle = FakeKpkOracle(fallback: KpkOutcome.draw);
      expect(choose(oracle, '8/8/4k3/8/8/6P1/8/K7 b - - 0 1'), 'e6f5');
    });

    test('captura o peão quando pode', () {
      final oracle = FakeKpkOracle(
        rule: (p) =>
            p.board.pawns.isEmpty ? KpkOutcome.draw : const KpkOutcome.win(6),
      );
      expect(choose(oracle, '8/8/8/8/5k2/6P1/8/K7 b - - 0 1'), 'f4g3');
    });

    test('se nenhum lance segura, escolhe o de maior DTM', () {
      final oracle = FakeKpkOracle(
        rule: (p) {
          final king = p.board.kingOf(p.turn.opposite)!.name;
          return king == 'e5'
              ? const KpkOutcome.win(30)
              : const KpkOutcome.win(12);
        },
      );
      expect(choose(oracle, '8/8/4k3/8/8/6P1/8/K7 b - - 0 1'), 'e6e5');
    });

    test('sem lances legais, nada', () {
      expect(choose(FakeKpkOracle(), '7k/5K2/6Q1/8/8/8/8/8 b - - 0 1'), isNull);
    });
  });

  group('tabela real', () {
    final bin = File('assets/tablebase/kpk.bin');
    final skip = bin.existsSync() ? null : 'kpk.bin ainda não existe';

    test('o atacante ganha o Ex1 sem perder o rumo', () {
      final oracle = KpkTableOracle(bin.readAsBytesSync());
      var position = GameRules.fromFen('4k3/8/8/8/8/3K2P1/8/8 w - - 0 1')!;
      // Os dois lados jogam pela máquina: o atacante só ganha se escolher
      // sempre lances ganhadores.
      for (var i = 0; i < 80 && position.board.pawns.isNotEmpty; i++) {
        final uci = MachineMove.choose(oracle, position)!;
        position = position.playUnchecked(Move.parse(uci)!);
      }
      expect(position.board.pawns.isEmpty, isTrue);
      expect(position.board.queens.size, 1, reason: position.fen);
    }, skip: skip);

    test('o defensor segura a posição 2.2', () {
      final oracle = KpkTableOracle(bin.readAsBytesSync());
      final position = GameRules.fromFen('8/4k3/8/8/8/8/3K2P1/8 b - - 0 1')!;
      final uci = MachineMove.choose(oracle, position)!;
      expect(
        oracle.evaluate(position.playUnchecked(Move.parse(uci)!)).isDraw,
        isTrue,
      );
    }, skip: skip);
  });
}
