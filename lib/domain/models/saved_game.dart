import 'package:dartchess/dartchess.dart';

import 'character.dart';
import 'game_snapshot.dart';

/// A partida guardada como o aviso a mostra: onde parou e contra quem.
typedef SavedGame = ({
  GameSnapshot snapshot,
  Position position,
  Move? lastMove,
  Character? character,
});
