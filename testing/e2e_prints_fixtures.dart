import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';

/// Dados prontos para os prints das telas que precisam de conteúdo no modo
/// E2E: o final "Ache o lance" do catálogo de destaques e uma partida salva
/// para os "Detalhes da partida".

/// O único final do tipo "Ache o lance" de `assets/featured/featured.json`.
const e2eFindMoveFeaturedId = 'gligoric-fischer-1959';

/// Mate de dama contra o Maia 1200, jogado e vencido pelas brancas: a
/// partida salva que abre nos "Detalhes da partida".
final e2eSavedGame = Attempt(
  positionId: 'basic.queen.0001',
  playedAt: DateTime.utc(2026, 10, 30, 19, 40),
  outcome: AttemptOutcome.win,
  fulfilled: true,
  opponent: OpponentKind.maia,
  opponentLevel: 1200,
  startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
  moves: const [
    'c1e3', 'd7d6', 'c2b2', 'd6d7', 'b2c3', 'd7c6', 'c3c4', 'c6c7', //
    'e3e5', 'c7b6', 'e5f6', 'b6a7', 'c4c5', 'a7b8', 'c5b6', 'b8c8', //
    'f6g7', 'c8d8', 'g7f7', 'd8c8', 'f7c7',
  ],
  userSide: Side.white,
  endReason: GameEndReason.checkmate,
);
