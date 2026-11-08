import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';

const _english = Locale('en', 'US');

// Mate em um: Dh8#.
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

/// O selo do fim de partida (T65 F4). Os cenários da tela antiga da lição
/// (barra contínua, demonstração, modo variante, apresentação B) saíram com
/// ela; a lição nova é coberta por `lesson_script_test.dart`.
void main() {
  patrolTest('S1: o selo de vitória entra e fica sobre o tabuleiro com o '
      '"Ver o resultado"', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final board = FreeBoardRobot($);
    await board.openAt(
      _mateInOne,
      opponent: 'maia',
      level: 1000,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );
    // Sem esperar assentar: o selo entra junto com o lance.
    await board.move('h1', 'h8', settle: false);
    // Sob IgnorePointer: existe, mas não recebe toque.
    await $(FreeBoardKeys.endFlash).waitUntilExists();
    expect(find.text('You won!'), findsOneWidget);
    // H-PAR-11 (desde 175263a9a): o selo fica sobre o tabuleiro até o
    // jogador seguir; não some sozinho.
    await $.pump(const Duration(seconds: 3));
    expect(find.byKey(FreeBoardKeys.endFlash), findsOneWidget);
    expect(find.text('You won!'), findsOneWidget);
    await $(FreeBoardKeys.seeResultButton).waitUntilVisible();
  });
}
