import 'package:flutter/widgets.dart';

import '../../blind/view_models/blind_game_cubit.dart';

/// Keys do modo às cegas.
abstract final class BlindKeys {
  static const screen = Key('blind.screen');
  static const status = Key('blind.status');
  static const mic = Key('blind.mic');
  static const board = Key('blind.board');

  /// O espaço do tabuleiro, entre a barra do app e o painel de baixo.
  static const boardArea = Key('blind.boardArea');
  static const heard = Key('blind.heard');
  static const lastMoves = Key('blind.lastMoves');
  static const toggleMoves = Key('blind.toggleMoves');
  static const copyLog = Key('blind.copyLog');
  static const micAllow = Key('blind.micAllow');
  static const micDeny = Key('blind.micDeny');
  static const micDenied = Key('blind.micDenied');
  static const offlineMissing = Key('blind.offlineMissing');
  static const result = Key('blind.result');
  static const hint = Key('blind.hint');

  /// O aviso no topo (não entendi, lance ilegal, segure para gravar…).
  static const toast = Key('blind.toast');

  /// O ⓘ de como dizer os lances e a folha que ele abre.
  static const help = Key('blind.help');
  static const helpSheet = Key('blind.helpSheet');

  /// Gravando: descartar o áudio.
  static const discard = Key('blind.discard');

  /// O microfone acima do lance entendido: grava de novo.
  static const reRecord = Key('blind.reRecord');

  /// O alto-falante do lance proposto (lê em voz alta).
  static const sayProposal = Key('blind.sayProposal');

  /// Propor empate e desistir, no alto.
  static const offerDraw = Key('blind.offerDraw');
  static const resign = Key('blind.resign');
  static const resignConfirm = Key('blind.resignConfirm');

  /// O tabuleiro só com as casas, que aceita o lance pelo toque.
  static const emptyBoard = Key('blind.emptyBoard');

  /// Digitar o lance: o botão que troca, o campo e o de jogar.
  static const typeToggle = Key('blind.typeToggle');
  static const typeField = Key('blind.typeField');
  static const typeSend = Key('blind.typeSend');

  /// Soltou o microfone: o app entendendo o que foi dito.
  static const processing = Key('blind.processing');

  /// O balão enquanto grava: o tempo e as ondas.
  static const recording = Key('blind.recording');
  static const repeat = Key('blind.repeat');
  static const proposal = Key('blind.proposal');
  static const confirm = Key('blind.confirm');
  static const reject = Key('blind.reject');
  static const narrateGame = Key('blind.narrateGame');
  static const narratePosition = Key('blind.narratePosition');
  static const introListen = Key('blind.intro.listen');
  static const introBoard = Key('blind.intro.board');
  static const start = Key('blind.start');
  static Key view(BlindView view) => Key('blind.view.${view.name}');
  static Key option(String san) => Key('blind.option.$san');

  /// Os relógios embaixo do tabuleiro.
  static const userClock = Key('blind.userClock');
  static const opponentClock = Key('blind.opponentClock');

  /// Na configuração da partida: o modo às cegas.
  static const playButton = Key('blind.play');
}
