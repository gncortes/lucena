import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/game_setup.dart';

void main() {
  FeaturedEndgame endgame({
    String fen = '8/8/8/4k3/8/8/4P3/4K3 b - - 0 1',
    OpponentKind opponent = OpponentKind.maia,
    int? level = 1600,
    String? clock = '300+3',
  }) => FeaturedEndgame(
    id: 'carlsen-so',
    kind: FeaturedKind.fromCode(null),
    origin: FeaturedOrigin.historical,
    fen: fen,
    goal: PositionGoal.draw,
    white: const FeaturedPlayer(name: 'Carlsen'),
    black: const FeaturedPlayer(name: 'So'),
    suggested: FeaturedChoice(opponent: opponent, level: level, clock: clock),
  );

  test('o desafio do compartilhar é a mesma posição, no lado de quem joga', () {
    final link = endgame().challenge();

    expect(link.fen, '8/8/8/4k3/8/8/4P3/4K3 b - - 0 1');
    expect(link.goal, PositionGoal.draw);
    expect(link.userSide, Side.black);
    expect(link.opponent, OpponentKind.maia);
    expect(link.level, 1600);
    expect(link.clock?.code, '300+3');
  });

  test('o link abre no app (mesmo host dos App Links) e volta igual', () {
    final link = endgame().challenge();

    expect(link.uri.host, AppLinks.host);
    expect(link.uri.path, startsWith('/${AppLinks.challengeSegment}/'));
    expect(ChallengeLink.tryParse(link.uri), link);
  });

  test('com a escolha do jogador, o link leva o que ele jogou', () {
    final link = endgame().challenge(
      const FeaturedChoice(opponent: OpponentKind.maia, level: 1900),
    );

    expect(link.level, 1900);
    expect(link.clock, isNull);
  });

  test('contra o Stockfish, o link não leva nível', () {
    final link = endgame(opponent: OpponentKind.stockfish).challenge();

    expect(link.opponent, OpponentKind.stockfish);
    expect(link.level, isNull);
  });
}
