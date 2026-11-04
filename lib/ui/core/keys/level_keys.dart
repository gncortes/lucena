import 'package:flutter/widgets.dart';

import '../../../domain/models/level_source.dart';
import '../../../domain/models/rating_level.dart';
import '../../level/view_models/level_cubit.dart';

/// "Seu nível" e a conta opcional, que vêm depois do tour.
abstract final class LevelKeys {
  static const screen = Key('level.screen');
  static const viktor = Key('level.viktor');
  static const speech = Key('level.speech');
  static const continueButton = Key('level.continue');
  static const back = Key('level.back');

  /// Um dos cinco cartões.
  static Key option(LevelChoice choice) => Key('level.option.${choice.name}');

  /// "Escolher minha faixa": a folha "Rating aproximado", uma faixa e
  /// "Confirmar".
  static const bandSheet = Key('level.band.sheet');
  static Key bandOption(RatingLevel level) => Key('level.band.${level.name}');
  static const bandConfirm = Key('level.band.confirm');

  /// "Lichess conectado" (também com rating provisório).
  static const lichessScreen = Key('level.lichess');
  static const lichessUse = Key('level.lichess.use');
  static const lichessTest = Key('level.lichess.test');
  static const lichessUseDefault = Key('level.lichess.useDefault');

  /// O aviso de autorização cancelada e o "Tentar novamente" dele.
  static const lichessCancelledSnack = Key('level.lichess.cancelledSnack');
  static const lichessSnackRetry = Key('level.lichess.snackRetry');

  /// "Sem internet" do Lichess, com "Tentar novamente" e "Voltar".
  static const lichessOfflineScreen = Key('level.lichess.offline');
  static const lichessRetry = Key('level.lichess.retry');
  static const lichessOfflineBack = Key('level.lichess.offlineBack');

  /// "Rating do Chess.com".
  static const chessScreen = Key('level.chess');
  static const chessField = Key('level.chess.field');
  static const chessUse = Key('level.chess.use');
  static const chessSearch = Key('level.chess.search');

  /// Usuário achado, mas sem rating: "Fazer o teste" e "Escolher minha faixa".
  static const chessNoRating = Key('level.chess.noRating');
  static const chessTest = Key('level.chess.test');
  static const chessPickBand = Key('level.chess.pickBand');

  /// "Sem internet" do Chess.com, com "Tentar novamente" e "Voltar".
  static const chessOfflineScreen = Key('level.chess.offline');
  static const chessRetry = Key('level.chess.retry');
  static const chessOfflineBack = Key('level.chess.offlineBack');

  /// "Prefiro fazer o teste" no Lichess e no Chess.com.
  static const preferTest = Key('level.preferTest');

  /// "Informar o rating".
  static const ratingScreen = Key('level.rating');
  static const ratingField = Key('level.rating.field');
  static Key ratingSource(RatingOrigin origin) =>
      Key('level.rating.source.${origin.name}');
  static const ratingUse = Key('level.rating.use');
}
