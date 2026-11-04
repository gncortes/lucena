import 'package:flutter/widgets.dart';

import '../../../domain/models/board_settings.dart';
import '../../tour/view_models/tour_cubit.dart';

abstract final class TourKeys {
  static const screen = Key('tour.screen');
  static const skipButton = Key('tour.skip');
  static const nextButton = Key('tour.next');
  static const backButton = Key('tour.back');

  /// Só em rc, no primeiro passo: abre um link de desafio colado.
  static const openLink = Key('tour.openLink');

  /// No primeiro passo, o vazio de 56 dp no lugar de "Voltar" (o "Pular" fica
  /// no mesmo lugar nos dois primeiros passos).
  static const backSlot = Key('tour.backSlot');

  /// A barra de progresso colada na base da barra do app.
  static const progress = Key('tour.progress');

  /// O retrato do Viktor com o nome e o som (o cabeçalho).
  static const viktor = Key('tour.viktor');

  /// O balão da fala; o clique abre a fala inteira.
  static const speech = Key('tour.speech');

  /// A tela do tour, que rola inteira.
  static const scroll = Key('tour.scroll');

  /// No passo da voz: o nome do jogador e a nota embaixo.
  static const nameField = Key('tour.name');
  static const voiceHint = Key('tour.voiceHint');

  /// O passo aberto.
  static Key step(TourStep step) => Key('tour.step.${step.name}');

  /// No passo do tabuleiro: a amostra, as cores e as peças.
  static const boardPreview = Key('tour.board.preview');
  static Key boardColors(BoardColors colors) =>
      Key('tour.board.colors.${colors.code}');
  static Key boardPieces(PieceStyle pieces) =>
      Key('tour.board.pieces.${pieces.code}');

  /// O interruptor do som das peças, no fim do passo do tabuleiro.
  static const boardSound = Key('tour.board.sound');

  /// No passo do tema: os três cartões.
  static const themeSystem = Key('tour.theme.system');
  static const themeLight = Key('tour.theme.light');
  static const themeDark = Key('tour.theme.dark');

  /// No passo do tabuleiro: o seletor "Cores | Peças".
  static const boardTabs = Key('tour.board.tabs');
  static const boardTabColors = Key('tour.board.tabs.colors');
  static const boardTabPieces = Key('tour.board.tabs.pieces');

  /// No passo da voz: o cartão da voz de número [n] (de 1) e "Sem voz".
  static Key voiceCard(int n) => Key('tour.voice.card.$n');
  static const voiceNone = Key('tour.voice.none');

  /// No passo da região: os três campos, a folha de busca e as linhas dela.
  static const regionCountry = Key('tour.region.country');
  static const regionState = Key('tour.region.state');
  static const regionCity = Key('tour.region.city');
  static const regionSheet = Key('tour.region.sheet');
  static const regionSearch = Key('tour.region.search');
  static const regionNone = Key('tour.region.none');
  static Key regionOption(String id) => Key('tour.region.option.$id');

  /// No passo da conta: os botões e o estado sem internet.
  static const accountGoogle = Key('tour.account.google');
  static const accountEmail = Key('tour.account.email');
  static const accountLogin = Key('tour.account.login');
  static const accountLater = Key('tour.account.later');
  static const accountOffline = Key('tour.account.offline');
  static const accountRetry = Key('tour.account.retry');
  static const accountBack = Key('tour.account.back');
}
