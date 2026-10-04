import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';

void main() {
  /// Joga os lances (em UCI) a partir de [start] e devolve a notação de cada um.
  (Position, List<String>) playAll(List<String> ucis, {Position? start}) {
    var position = start ?? GameRules.initial;
    final sans = <String>[];
    for (final uci in ucis) {
      final played = GameRules.play(position, NormalMove.fromUci(uci));
      expect(played, isNotNull, reason: 'lance ilegal: $uci');
      position = played!.position;
      sans.add(played.san);
    }
    return (position, sans);
  }

  test('lances legais dos dois lados saem em notação algébrica', () {
    final (position, sans) = playAll(['e2e4', 'e7e5', 'g1f3']);

    expect(sans, ['e4', 'e5', 'Nf3']);
    expect(position.turn, Side.black);
  });

  test('lance ilegal é recusado', () {
    expect(
      GameRules.play(GameRules.initial, NormalMove.fromUci('e2e5')),
      isNull,
    );
    expect(
      GameRules.play(GameRules.initial, NormalMove.fromUci('e7e5')),
      isNull,
    );
  });

  test('roque pequeno: rei anda duas casas e a torre pula', () {
    final start = GameRules.fromFen(
      'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
    )!;

    final (position, sans) = playAll(['e1g1'], start: start);

    expect(sans, ['O-O']);
    expect(position.board.roleAt(Square.g1), Role.king);
    expect(position.board.roleAt(Square.f1), Role.rook);
  });

  test('en passant: o peão capturado sai do tabuleiro', () {
    final start = GameRules.fromFen(
      'rnbqkbnr/1pp1pppp/p7/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
    )!;

    final (position, sans) = playAll(['e5d6'], start: start);

    expect(sans, ['exd6']);
    expect(position.board.pieceAt(Square.d5), isNull);
    expect(position.board.roleAt(Square.d6), Role.pawn);
  });

  test('promoção a cavalo (subpromoção)', () {
    final start = GameRules.fromFen('8/P6k/8/8/8/8/8/K7 w - - 0 1')!;

    final (position, sans) = playAll(['a7a8n'], start: start);

    expect(sans, ['a8=N']);
    expect(position.board.roleAt(Square.a8), Role.knight);
  });

  test('promoção sem escolher a peça é ilegal', () {
    final start = GameRules.fromFen('8/P6k/8/8/8/8/8/K7 w - - 0 1')!;

    expect(GameRules.play(start, NormalMove.fromUci('a7a8')), isNull);
  });

  test('mate do pastor termina a partida com vitória das brancas', () {
    final (position, sans) = playAll([
      'e2e4',
      'e7e5',
      'f1c4',
      'b8c6',
      'd1h5',
      'g8f6',
      'h5f7',
    ]);

    expect(sans.last, 'Qxf7#');
    expect(
      GameRules.endOf(position),
      const GameEnd(GameEndReason.checkmate, winner: Side.white),
    );
    expect(GameRules.legalMoves(position), isEmpty);
  });

  test('rei afogado termina em empate', () {
    final position = GameRules.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1')!;

    expect(GameRules.endOf(position), const GameEnd(GameEndReason.stalemate));
  });

  test('rei contra rei termina por material insuficiente', () {
    final position = GameRules.fromFen('8/8/4k3/8/8/4K3/8/8 w - - 0 1')!;

    expect(
      GameRules.endOf(position),
      const GameEnd(GameEndReason.insufficientMaterial),
    );
  });

  test('partida em andamento não tem fim', () {
    expect(GameRules.endOf(GameRules.initial), isNull);
  });

  test('aponta a casa do rei em xeque', () {
    final (position, _) = playAll(['e2e4', 'f7f6', 'd1h5']);

    expect(GameRules.checkedKing(position), Square.e8);
    expect(GameRules.checkedKing(GameRules.initial), isNull);
  });

  test('FEN inválido ou posição impossível não vira posição', () {
    expect(GameRules.fromFen('isto não é um FEN'), isNull);
    expect(GameRules.fromFen('8/8/8/8/8/8/8/8 w - - 0 1'), isNull);
  });

  test('tempo esgotado: vence quem ainda pode dar mate', () {
    expect(
      GameRules.timeoutEnd(GameRules.initial, Side.white),
      const GameEnd(GameEndReason.timeout, winner: Side.black),
    );
  });

  test('tempo esgotado contra rei sozinho é empate', () {
    final position = GameRules.fromFen('k7/8/8/8/8/8/P7/K7 w - - 0 1')!;

    expect(
      GameRules.timeoutEnd(position, Side.white),
      const GameEnd(GameEndReason.timeoutVsInsufficientMaterial),
    );
    // O lado com o peão ainda pode dar mate: se a bandeira é das pretas, ele vence.
    expect(
      GameRules.timeoutEnd(position, Side.black),
      const GameEnd(GameEndReason.timeout, winner: Side.white),
    );
  });
}
