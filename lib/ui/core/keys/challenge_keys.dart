import 'package:flutter/widgets.dart';

import '../../../domain/models/board_settings.dart';

abstract final class ChallengeKeys {
  static const invalidScreen = Key('challenge.invalid.screen');
  static const invalidMessage = Key('challenge.invalid.message');
  static const invalidBack = Key('challenge.invalid.back');
  static const invalidPaste = Key('challenge.invalid.paste');

  /// O botão da barra da Nova partida que abre a folha de mandar o desafio.
  static const sendButton = Key('challenge.send');

  static const sheet = Key('challenge.sheet');
  static const summary = Key('challenge.summary');
  static const lockSwitch = Key('challenge.lock');
  static const linkField = Key('challenge.link');
  static const share = Key('challenge.share');
  static const copy = Key('challenge.copy');

  /// A tela do desafio fechado (aberto por link).
  static const screen = Key('challenge.screen');
  static const board = Key('challenge.board');
  static const play = Key('challenge.play');
  static const opponentCard = Key('challenge.opponent');
  static const clockRow = Key('challenge.clock');
  static const modeRow = Key('challenge.mode');
  static const lockedNote = Key('challenge.note');

  /// O subtítulo da Nova partida aberta por link.
  static const linkSetupSubtitle = Key('challenge.linkSetup');

  /// O fim da partida de um desafio de link.
  static const endPlayAgain = Key('challenge.end.again');
  static const endShare = Key('challenge.end.share');
  static const compare = Key('challenge.compare');
  static const endMeetApp = Key('challenge.end.app');

  /// A imagem do resultado, desenhada fora da tela para virar PNG.
  static const resultCard = Key('challenge.result.card');

  /// O "Antes do desafio": a única tela da primeira abertura por link.
  static const setupScreen = Key('challenge.setup.screen');
  static const setupClose = Key('challenge.setup.close');
  static const setupPreview = Key('challenge.setup.preview');
  static Key setupColors(BoardColors colors) =>
      Key('challenge.setup.colors.${colors.code}');
  static Key setupPieces(PieceStyle pieces) =>
      Key('challenge.setup.pieces.${pieces.code}');
  static const setupSound = Key('challenge.setup.sound');
  static const setupPlay = Key('challenge.setup.play');
}
