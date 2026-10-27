import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/level_source.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
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
    await $(TourKeys.step(step)).waitUntilExists();
    await $.pumpAndSettle();
  }

  TourCubit get cubit =>
      $.tester.element(find.byKey(TourKeys.screen)).read<TourCubit>();

  LevelCubit get levelCubit =>
      $.tester.element(find.byKey(LevelKeys.screen)).read<LevelCubit>();

  /// A barra de progresso da barra do app: (posição + 1) de quantos passos
  /// aparecem (cinco; quatro vindo de um link).
  void expectProgress(TourStep step) {
    final steps = cubit.state.steps;
    final bar = $.tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(TourKeys.progress),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(bar.value, closeTo((steps.indexOf(step) + 1) / steps.length, 0.001));
  }

  /// "Continuar" do passo (o último troca só a chave) está habilitado.
  void expectPrimaryEnabled({required bool last}) {
    final button = $.tester.widget<FilledButton>(
      find.byKey(last ? TourKeys.startButton : TourKeys.nextButton),
    );
    expect(button.onPressed, isNotNull);
  }

  /// O que o tour gravou nas preferências do aparelho.
  Future<Onboarding> savedOnboarding() =>
      LocalOnboardingRepository(PreferencesService()).load();

  void expectNotOpen() => expect(find.byKey(TourKeys.screen), findsNothing);

  Future<void> next() async {
    await $(TourKeys.nextButton).tap();
    await $.pumpAndSettle();
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

  /// O tour abre no tabuleiro: avança até o passo da voz (o nome do jogador).
  Future<void> openVoice() async {
    await expectStep(TourStep.board);
    await next();
    await expectStep(TourStep.voice);
  }

  /// Avança até o passo [step].
  Future<void> nextUntil(TourStep step) async {
    while (find.byKey(TourKeys.step(step)).evaluate().isEmpty) {
      await next();
    }
  }

  /// Termina os passos do tour (o último leva ao objetivo).
  Future<void> finishSteps() async {
    await nextUntil(TourStep.play);
    await $(TourKeys.startButton).tap();
    await $.pumpAndSettle();
  }

  /// "O que você quer fazer?": marca [goal] e segue (aprender a jogar vai
  /// direto para a tela inicial; os outros, para o nível).
  Future<void> answerGoal([
    GoalPreference goal = GoalPreference.endgames,
  ]) async {
    await $(GoalKeys.screen).waitUntilVisible();
    await _tap(GoalKeys.option(goal));
    await _tap(GoalKeys.continueButton);
  }

  /// Avança o tour inteiro e o objetivo ([goal]) até "Seu nível".
  Future<void> nextUntilLevel([
    GoalPreference goal = GoalPreference.endgames,
  ]) async {
    await finishSteps();
    await answerGoal(goal);
    await $(LevelKeys.screen).waitUntilVisible();
  }

  /// No passo do tabuleiro: as cores e as peças.
  Future<void> chooseBoardColors(BoardColors colors) =>
      _tap(TourKeys.boardColors(colors));

  Future<void> chooseBoardPieces(PieceStyle pieces) =>
      _tap(TourKeys.boardPieces(pieces));

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

  /// No passo do nível: "Não sei jogar" para o iniciante; as outras faixas
  /// abrem "Já sei o meu rating" e marcam "Informar o meu rating", e [start] digita o rating delas como do
  /// Lichess (que não converte).
  Future<void> chooseLevel(RatingLevel level) async {
    _level[this] = level;
    if (level == RatingLevel.beginner) {
      await _tap(LevelKeys.option(LevelChoice.zero));
      return;
    }
    // O número fica atrás de "Já sei o meu rating".
    await _tap(LevelKeys.option(LevelChoice.known));
    await _tap(LevelKeys.continueButton);
    await _tap(LevelKeys.option(LevelChoice.manual));
  }

  /// No passo do nível: abre o teste de nível.
  Future<void> takeTest() => _tap(LevelKeys.option(LevelChoice.test));

  /// Em "Seu nível": "Continuar" (com o teste marcado e sem teste feito, abre
  /// o teste). Com "Informar o meu rating", digita a faixa de [chooseLevel].
  /// Com a faixa escolhida e [leave], sai dos próximos passos para a tela
  /// inicial.
  Future<void> start({bool leave = true}) async {
    await _tap(LevelKeys.continueButton);
    final level = _level[this];
    if (level == null) return;
    if (level == RatingLevel.beginner) {
      if (leave && !VisibleLessons.school) await leaveNextSteps();
      return;
    }
    await $(LevelKeys.ratingScreen).waitUntilVisible();
    await $(LevelKeys.ratingField).enterText(level.rating.toString());
    await $(LevelKeys.ratingSource(RatingOrigin.lichess)).scrollTo().tap();
    await $(LevelKeys.ratingUse).tap();
    await $.pumpAndSettle();
    if (leave) await leaveNextSteps();
  }

  /// Nos próximos passos do fim do tour (E1.34): "Ir para o início".
  Future<void> leaveNextSteps() async {
    await $(NextStepsKeys.screen).waitUntilVisible();
    await $(NextStepsKeys.home).tap();
    await $.pumpAndSettle();
  }

  /// Pula o tour, responde o objetivo e, em "Seu nível", escolhe [level] e
  /// segue.
  Future<void> skip({RatingLevel level = RatingLevel.intermediate}) async {
    await $(TourKeys.skipButton).tap();
    await $.pumpAndSettle();
    await answerGoal();
    await $(LevelKeys.screen).waitUntilVisible();
    await chooseLevel(level);
    await start();
  }

  /// Em Configurações, "Rever o tour".
  Future<void> openFromSettings() async {
    await SettingsRobot($).openAbout();
    await $(SettingsKeys.tourTile).scrollTo().tap();
    await $(TourKeys.screen).waitUntilVisible();
  }
}
