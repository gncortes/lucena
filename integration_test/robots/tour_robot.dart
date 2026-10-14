import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'settings_robot.dart';

/// O tour da primeira abertura.
class TourRobot {
  const TourRobot(this.$);

  final PatrolIntegrationTester $;

  /// O passo aberto. A tela do tour rola inteira e um passo alto pode ter o
  /// meio fora da tela: basta ele existir.
  Future<void> expectStep(TourStep step) async {
    await $(TourKeys.step(step)).waitUntilExists();
    await $.pumpAndSettle();
  }

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

  /// Avança até o passo do nível.
  Future<void> nextUntilLevel() => nextUntil(TourStep.level);

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

  /// No passo do nível: "Estou começando" é o cartão do iniciante; as outras
  /// faixas vêm da folha de "Escolher minha faixa" (marca e confirma).
  Future<void> chooseLevel(RatingLevel level) async {
    if (level == RatingLevel.beginner) {
      await _tap(TourKeys.levelOption(TourLevelChoice.beginner));
      return;
    }
    await _tap(TourKeys.levelOption(TourLevelChoice.band));
    await $(ProfileKeys.levelSheet).waitUntilVisible();
    await $(ProfileKeys.levelOption(level))
        .scrollTo(
          view: find.descendant(
            of: find.byKey(ProfileKeys.levelSheet),
            matching: find.byType(Scrollable),
          ),
        )
        .tap();
    await $(ProfileKeys.levelConfirmButton).tap();
    await $.pumpAndSettle();
  }

  /// No passo do nível: abre o teste de nível.
  Future<void> takeTest() => _tap(TourKeys.levelOption(TourLevelChoice.test));

  /// No passo do nível: "Começar". Sem escolha, vale "Estou começando".
  Future<void> start() async {
    await _tap(TourKeys.startButton);
  }

  /// Pula o tour. Pular exige um nível escolhido: sem ele, o botão leva ao
  /// passo do nível, onde escolhemos [level] e começamos.
  Future<void> skip({RatingLevel level = RatingLevel.intermediate}) async {
    await $(TourKeys.skipButton).tap();
    await $.pumpAndSettle();
    if (find.byKey(TourKeys.step(TourStep.level)).evaluate().isNotEmpty) {
      await chooseLevel(level);
      await start();
    }
  }

  /// Em Configurações, "Rever o tour".
  Future<void> openFromSettings() async {
    await SettingsRobot($).openAbout();
    await $(SettingsKeys.tourTile).scrollTo().tap();
    await $(TourKeys.screen).waitUntilVisible();
  }
}
