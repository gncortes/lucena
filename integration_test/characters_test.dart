import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/character_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';
import 'robots/home_robot.dart';

// Rei e torre contra rei, o rei preto longe: a torre vai e volta em h1 e h2.
const _rookShuffle = 'k7/8/8/8/8/8/8/4K2R w - - 0 1';

const _english = Locale('en', 'US');

void main() {
  /// Abre a partida contra o Maia 1600 (o Valdini, o mágico).
  Future<void> openMagician(PatrolIntegrationTester $) async {
    await FreeBoardRobot($).openAt(
      _rookShuffle,
      opponent: 'maia',
      level: 1600,
      user: Side.white,
      goal: 'win',
      white: '300+0',
      black: '300+0',
    );
    await CharacterRobot($).expectCharacter('Valdini', 1600);
  }

  /// O jogador move a torre (o lance [index] dele) e a máquina responde.
  Future<void> shuffle(PatrolIntegrationTester $, int index) async {
    final board = FreeBoardRobot($);
    final (from, to) = index.isEven ? ('h1', 'h2') : ('h2', 'h1');
    await board.move(from, to);
    await board.waitForMoves(index * 2 + 2);
  }

  patrolTest('erro grave do jogador: o personagem reage com a fala certa', (
    $,
  ) async {
    final character = CharacterRobot($);
    await AppRobot($).open(systemLocale: _english);
    await openMagician($);
    await character.expectLine('gameStart');

    character.evaluate(0);
    await shuffle($, 0);
    // O lance seguinte do jogador entrega a posição.
    character.evaluate(500);
    await shuffle($, 1);

    await character.expectLine('opponentBlunder');
  });

  patrolTest('virada: fala de "virou", não de "está ganhando"', ($) async {
    final character = CharacterRobot($);
    await AppRobot($).open(systemLocale: _english);
    await openMagician($);

    character.evaluate(-300);
    await shuffle($, 0);
    await shuffle($, 1);
    character.evaluate(300);
    await shuffle($, 2);

    await character.expectLine('comeback');
  });

  patrolTest('a mesma situação várias vezes: falas diferentes', ($) async {
    final character = CharacterRobot($);
    await AppRobot($).open(systemLocale: _english);
    await openMagician($);

    final blunders = <String>[];
    for (var round = 0; round < 4; round++) {
      character.evaluate(0);
      await shuffle($, round * 2);
      character.evaluate(500);
      await shuffle($, round * 2 + 1);
      blunders.add(await character.expectLine('opponentBlunder'));
    }
    expect(blunders.toSet(), hasLength(blunders.length));
  });

  patrolTest('falas silenciadas continuam silenciadas depois de reabrir', (
    $,
  ) async {
    final app = AppRobot($);
    final character = CharacterRobot($);
    await app.open(systemLocale: _english);
    await HomeRobot($).openSettings();
    await $(SettingsKeys.characterTalkSwitch).scrollTo().tap();
    await $.pumpAndSettle();

    await app.restart();
    await HomeRobot($).openSettings();
    await $(SettingsKeys.characterTalkSwitch).scrollTo();
    expect(
      $.tester
          .widget<SwitchListTile>(find.byKey(SettingsKeys.characterTalkSwitch))
          .value,
      isFalse,
    );
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await openMagician($);
    await shuffle($, 0);
    await character.expectNoBubble();
  });

  patrolTest('partida restaurada depois de fechar à força: emoção e fala '
      'mantidas', ($) async {
    final app = AppRobot($);
    final character = CharacterRobot($);
    await app.open(systemLocale: _english);
    await openMagician($);
    character.evaluate(-450);
    await shuffle($, 0);
    await shuffle($, 1);
    final emotion = character.emotion();
    final line = character.lineId();
    expect(emotion, isIn([Emotion.sad, Emotion.nervous]));

    await app.restart();
    await character.expectCharacter('Valdini', 1600);
    await $.pumpAndSettle();
    expect(character.emotion(), emotion);
    expect(character.lineId(), line);
  });

  patrolTest('escolher o Mágico na configuração: retrato e nome na partida', (
    $,
  ) async {
    final catalog = CatalogRobot($);
    final setup = GameSetupRobot($);
    await AppRobot($).open(systemLocale: _english);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    await setup.expectVisible();
    await setup.chooseOpponent(OpponentKind.maia);
    await setup.chooseLevel(1600);
    await setup.start();

    await CharacterRobot($).expectCharacter('Valdini', 1600);
    await FreeBoardRobot($).expectPlayerName('Valdini');
  });

  patrolTest('combinação do Mágico: a fala e a imagem da emoção trocam', (
    $,
  ) async {
    final character = CharacterRobot($);
    await AppRobot($).open(systemLocale: _english);
    await openMagician($);
    character.evaluate(-400);
    await shuffle($, 0);
    await shuffle($, 1);
    final before = character.emotion();
    final lineBefore = character.lineId();

    // A combinação dele: de perdido para ganho.
    character.evaluate(700);
    await shuffle($, 2);

    final line = await character.expectLine('comeback');
    expect(line, isNot(lineBefore));
    expect(character.emotion(), isNot(before));
    expect(
      character.emotion(),
      isIn([Emotion.happy, Emotion.confident, Emotion.playful]),
    );
  });

  patrolTest('tema escuro e árabe: retrato e balão certos e espelhados', (
    $,
  ) async {
    final app = AppRobot($);
    final character = CharacterRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('ar'));
    await FreeBoardRobot($).openAt(
      _rookShuffle,
      opponent: 'maia',
      level: 1600,
      user: Side.white,
      goal: 'win',
    );
    await $(FreeBoardKeys.characterBar).waitUntilExists();
    await character.expectLine('gameStart');

    app
      ..expectDirection(TextDirection.rtl)
      ..expectBrightness(Brightness.dark);
    // Da direita para a esquerda: o retrato fica à direita do balão.
    expect(
      character.avatarRect().left,
      greaterThan(character.bubbleRect().left),
    );
    app.expectNoClippedText();
  });

  patrolTest('segundo plano com o balão aberto: volta sem travar', ($) async {
    final app = AppRobot($);
    final character = CharacterRobot($);
    await app.open(systemLocale: _english);
    await openMagician($);
    final line = await character.expectLine('gameStart');

    await app.sendToBackgroundFor(const Duration(seconds: 20));

    expect(character.lineId(), line);
    await shuffle($, 0);
    FreeBoardRobot($).expectStillPlaying();
  });
}
