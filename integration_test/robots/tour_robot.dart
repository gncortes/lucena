import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'settings_robot.dart';

/// O tour da primeira abertura.
class TourRobot {
  const TourRobot(this.$);

  final PatrolIntegrationTester $;

  // A faixa de [chooseLevel] até o [start] (o robô é const).
  static final _level = Expando<RatingLevel>();

  /// O passo aberto. A tela do tour rola inteira e um passo alto pode ter o
  /// meio fora da tela: basta ele existir.
  Future<void> expectStep(TourStep step) async {
    await _answerGoalIfOpen();
    await $(TourKeys.step(step)).waitUntilExists();
    await $.pumpAndSettle();
  }

  TourCubit get cubit =>
      $.tester.element(find.byKey(TourKeys.screen)).read<TourCubit>();

  LevelCubit get levelCubit => $.tester
      .element(find.byKey(TourKeys.step(TourStep.level)))
      .read<LevelCubit>();

  /// A barra de progresso da barra do app: (posição + 1) de quantos passos
  /// aparecem (cinco; quatro vindo de um link).
  void expectProgress(TourStep step) {
    final bar = $.tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(TourKeys.progress),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(bar.value, closeTo(cubit.state.progress, 0.001));
  }

  /// O botão principal do passo está habilitado: o último (Conta) não tem
  /// "Continuar", o principal dele é o "Agora não".
  void expectPrimaryEnabled({required bool last}) {
    final button = $.tester.widget<ButtonStyleButton>(
      find.byKey(last ? TourKeys.accountLater : TourKeys.nextButton),
    );
    expect(button.onPressed, isNotNull);
  }

  /// O que o tour gravou nas preferências do aparelho.
  Future<Onboarding> savedOnboarding() =>
      LocalOnboardingRepository(PreferencesService()).load();

  void expectNotOpen() => expect(find.byKey(TourKeys.screen), findsNothing);

  bool _isOpen(TourStep step) =>
      find.byKey(TourKeys.step(step)).evaluate().isNotEmpty;

  /// A primeira abertura começa no Objetivo: responde se ele estiver aberto.
  Future<void> _answerGoalIfOpen() async {
    if (find.byKey(GoalKeys.screen).evaluate().isNotEmpty) await answerGoal();
  }

  /// O botão que avança o passo aberto: "Continuar" do Nível, "Agora não" da
  /// Conta e o "Continuar" comum dos outros.
  Future<void> next() async {
    await _answerGoalIfOpen();
    final Key key;
    if (_isOpen(TourStep.level)) {
      key = LevelKeys.continueButton;
    } else if (_isOpen(TourStep.account)) {
      key = TourKeys.accountLater;
    } else {
      key = TourKeys.nextButton;
    }
    await _tap(key);
  }

  /// No primeiro passo: escreve o nome do jogador.
  Future<void> enterName(String name) async {
    await $(TourKeys.nameField).scrollTo().enterText(name);
    await $.pumpAndSettle();
  }

  /// O nome que está no campo do primeiro passo.
  Future<void> expectName(String name) async {
    await $(TourKeys.nameField).scrollTo();
    expect(
      $.tester
          .widget<TextField>(find.byKey(TourKeys.nameField))
          .controller!
          .text,
      name,
    );
  }

  Future<void> back() async {
    await $(TourKeys.backButton).tap();
    await $.pumpAndSettle();
  }

  /// O tour abre no tabuleiro (depois do Objetivo): avança até o passo da voz (o nome do jogador).
  Future<void> openVoice() async {
    await expectStep(TourStep.board);
    await next();
    await expectStep(TourStep.theme);
    await next();
    await expectStep(TourStep.voice);
  }

  /// Avança até o passo [step].
  Future<void> nextUntil(TourStep step) async {
    await _answerGoalIfOpen();
    for (var i = 0; i < TourStep.values.length && !_isOpen(step); i++) {
      await next();
    }
  }

  /// Termina os passos do tour: no último, "Agora não" leva ao Início.
  Future<void> finishSteps() async {
    await nextUntil(TourStep.account);
    await _tap(TourKeys.accountLater);
  }

  /// "O que você quer fazer?": marca [goal] e segue para o tour.
  Future<void> answerGoal([
    GoalPreference goal = GoalPreference.improve,
  ]) async {
    await $(GoalKeys.screen).waitUntilVisible();
    await _tap(GoalKeys.option(goal));
    await _tap(GoalKeys.continueButton);
  }

  /// Responde o Objetivo ([goal]) e avança o tour até o passo Nível.
  Future<void> nextUntilLevel([
    GoalPreference goal = GoalPreference.improve,
  ]) async {
    // Já dentro do tour (o Objetivo foi respondido antes), segue direto.
    if (find.byKey(TourKeys.screen).evaluate().isEmpty) {
      await answerGoal(goal);
    }
    await nextUntil(TourStep.level);
    await expectStep(TourStep.level);
  }

  /// No passo do tabuleiro: as cores e as peças.
  /// As cores e as peças ficam em abas: abre a aba antes de escolher.
  Future<void> chooseBoardColors(BoardColors colors) async {
    await _tap(TourKeys.boardTabColors);
    await _tap(TourKeys.boardColors(colors));
  }

  Future<void> chooseBoardPieces(PieceStyle pieces) async {
    await _tap(TourKeys.boardTabPieces);
    await _tap(TourKeys.boardPieces(pieces));
  }

  /// O que o tabuleiro de amostra do passo do tabuleiro está mostrando.
  Future<void> expectBoardPreview({
    required BoardColors colors,
    required PieceStyle pieces,
  }) async {
    await $(TourKeys.boardPreview).scrollTo();
    final settings = $.tester
        .widget<StaticChessboard>(find.byKey(TourKeys.boardPreview))
        .settings;
    expect(settings.colorScheme, colors.scheme);
    expect(settings.pieceAssets, pieces.assets);
  }

  // As opções ficam numa lista que rola para baixo e em fileiras que rolam
  // para o lado: traz a opção para a tela antes de tocar.
  Future<void> _tap(Key key) async {
    await $(key).scrollTo();
    await $.tester.ensureVisible(find.byKey(key));
    await $.pumpAndSettle();
    await $(key).tap();
    await $.pumpAndSettle();
  }

  /// No passo do nível: "Estou começando" para o iniciante; as outras faixas
  /// vêm do cartão "Já sei meu rating" e da folha de faixas.
  Future<void> chooseLevel(RatingLevel level) async {
    _level[this] = level;
    if (level == RatingLevel.beginner) {
      await _tap(LevelKeys.option(LevelChoice.zero));
      return;
    }
    await _tap(LevelKeys.option(LevelChoice.band));
    await _tapInSheet(LevelKeys.bandOption(level));
    await _tapInSheet(LevelKeys.bandConfirm);
  }

  // Na folha de faixas, o `scrollTo` procura a rolagem da página de trás:
  // o `ensureVisible` rola a da própria folha.
  Future<void> _tapInSheet(Key key) async {
    await $(LevelKeys.bandSheet).waitUntilVisible();
    await $.tester.ensureVisible(find.byKey(key));
    await $.pumpAndSettle();
    await $(key).tap();
    await $.pumpAndSettle();
  }

  /// No passo do nível: abre o teste de nível.
  Future<void> takeTest() => _tap(LevelKeys.option(LevelChoice.test));

  /// No passo Nível: "Continuar" (com o teste marcado e sem teste feito, abre
  /// o teste). Com a faixa escolhida em [chooseLevel] e [leave], termina o
  /// tour (Região e Conta) e chega ao Início.
  Future<void> start({bool leave = true}) async {
    await _tap(LevelKeys.continueButton);
    if (leave) await leaveNextSteps();
  }

  /// Termina o que falta do tour a partir do passo aberto: Região
  /// "Continuar" e Conta "Agora não". Sem tour aberto, não faz nada.
  Future<void> leaveNextSteps() async {
    for (var i = 0; i < TourStep.values.length; i++) {
      if (find.byKey(TourKeys.screen).evaluate().isEmpty) break;
      await next();
    }
    await $.pumpAndSettle();
  }

  /// Responde o Objetivo e pula cada passo do tour (o "Pular" vale só para
  /// o passo aberto); no Nível escolhe [level] e na Conta sai por "Agora não".
  Future<void> skip({RatingLevel level = RatingLevel.intermediate}) async {
    await _answerGoalIfOpen();
    for (var i = 0; i < TourStep.values.length; i++) {
      if (find.byKey(TourKeys.screen).evaluate().isEmpty) break;
      if (_isOpen(TourStep.account)) {
        await _tap(TourKeys.accountLater);
      } else if (_isOpen(TourStep.level)) {
        await chooseLevel(level);
        await _tap(LevelKeys.continueButton);
      } else {
        await _tap(TourKeys.skipButton);
      }
    }
    await $.pumpAndSettle();
  }

  /// Em Configurações, "Rever o tour".
  Future<void> openFromSettings() async {
    await SettingsRobot($).openAbout();
    await $(SettingsKeys.tourTile).scrollTo().tap();
    await $(TourKeys.screen).waitUntilVisible();
  }
}
