import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/challenge/view_models/challenge_link_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';

void main() {
  const fen = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

  ChallengeLinkCubit cubit(ChallengeLink link) => ChallengeLinkCubit(
    FakeCharacterRepository(),
    FakeProfileRepository(),
    FakeRatingRepository(),
    link: link,
  );

  test(
    'o nível do link vale, e a rota da partida leva o relógio dele',
    () async {
      final c = cubit(
        ChallengeLink(
          fen: fen,
          userSide: Side.white,
          opponent: OpponentKind.maia,
          level: 1400,
          locked: true,
        ),
      );
      await c.load();
      expect(c.state.ready, isTrue);
      expect(c.state.level, 1400);
      expect(c.state.gameRoute, contains('link=https'));
      expect(c.state.gameRoute, contains('level=1400'));
    },
  );

  test(
    'a rota da partida leva o link de origem inteiro (código, trava, cego)',
    () {
      final link = ChallengeLink(
        fen: fen,
        userSide: Side.white,
        opponent: OpponentKind.maia,
        level: 1400,
        locked: true,
      );
      for (final l in [link, link.copyWith(blind: true)]) {
        final route = Routes.linkGame(l, level: 1400);
        // Com ou sem `blind=1`, a partida de link abre no tabuleiro normal.
        expect(Uri.parse(route).path, Routes.freeBoard);
        final carried = Uri.parse(route).queryParameters['link']!;
        final back = ChallengeLink.tryParse(Uri.parse(carried))!;
        expect(back, l);
        expect(back.code, l.code);
        expect(back.locked, isTrue);
      }
    },
  );

  test(
    'contra o Stockfish, o adversário é o do Stockfish e não leva nível',
    () async {
      final c = cubit(
        ChallengeLink(
          fen: fen,
          userSide: Side.black,
          opponent: OpponentKind.stockfish,
          locked: true,
        ),
      );
      await c.load();
      expect(c.state.opponent, Character.stockfish);
      expect(c.state.gameRoute, isNot(contains('level=')));
    },
  );
}
