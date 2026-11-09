import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/coach/widgets/game_row.dart';

import '../../../testing/test_app.dart';
import 'coach_harness.dart';

CoachGame _long({GameStatus status = GameStatus.newGame}) => CoachGame(
  id: 'lichess_Longa001',
  moveAt: DateTime.utc(2026, 11, 9, 9),
  timeControl: TimeControl.rapid,
  cadence: '15+10',
  color: GameColor.black,
  opponent: const Opponent(name: 'JogadorDeNomeLongo_25', rating: 1612),
  result: GameResult.loss,
  opening: const GameOpening(
    eco: 'B99',
    name: 'Defesa Siciliana: Variante Najdorf, Ataque Inglês',
  ),
  status: status,
);

/// Todo texto da linha, com o que o layout fez dele.
Iterable<RenderParagraph> _paragraphs(WidgetTester tester) => tester
    .renderObjectList<RenderParagraph>(
      find.descendant(
        of: find.byType(GameRow),
        matching: find.byType(RichText),
      ),
    )
    .where((p) => p.text.toPlainText().trim().isNotEmpty);

void main() {
  Future<void> montar(WidgetTester tester, CoachGame p) async {
    device411x914(tester);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: GameRow(game: p, currentTime: testNow(), grant: true),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('abertura curta fica na mesma linha, como no canvas', (
    tester,
  ) async {
    final short = CoachGame(
      id: 'lichess_Curta001',
      moveAt: DateTime.utc(2026, 11, 9, 9),
      timeControl: TimeControl.blitz,
      cadence: '5+0',
      color: GameColor.black,
      opponent: const Opponent(name: 'Tiago_Rook', rating: 1612),
      result: GameResult.loss,
      opening: const GameOpening(eco: 'B12', name: 'Caro-Kann'),
    );
    // A fonte dos testes é mais larga que a Roboto: tela larga para a linha
    // caber inteira.
    await montar(tester, short);
    tester.view.physicalSize = const Size(900, 914);
    await tester.pump();
    final texts = [for (final p in _paragraphs(tester)) p.text.toPlainText()];
    expect(texts, contains('5+0 Blitz · Pretas · Caro-Kann · Hoje'));
  });

  // Cobertura 5 do QA: nada de reticências com dado real longo a 411x914.
  for (final status in [GameStatus.newGame, GameStatus.ready]) {
    testWidgets('nome de 25 caracteres e abertura longa não cortam '
        '($status)', (tester) async {
      await montar(tester, _long(status: status));

      expect(find.text('JogadorDeNomeLongo_25 (1612)'), findsOneWidget);
      // Com a abertura longa, ela abre a linha de baixo (ordem estável:
      // ritmo, cor, abertura, quando).
      final texts = [for (final p in _paragraphs(tester)) p.text.toPlainText()];
      expect(texts, contains('15+10 Rápido · Pretas'));
      expect(
        texts,
        contains('Defesa Siciliana: Variante Najdorf, Ataque Inglês · Hoje'),
      );
      for (final p in _paragraphs(tester)) {
        // Nenhum texto passa do máximo de linhas (nada é cortado).
        expect(
          p.didExceedMaxLines,
          isFalse,
          reason: 'cortou: ${p.text.toPlainText()}',
        );
        expect(
          p.maxLines,
          anyOf(isNull, GameRow.detailMaxLines, GameRow.detailMaxLines + 1),
        );
        expect(p.text.toPlainText(), isNot(contains('…')));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sem seta e sem estado: só nome e detalhe', (tester) async {
    device411x914(tester);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: GameRow(
            game: _long(status: GameStatus.newGame),
            currentTime: testNow(),
            grant: true,
            showArrow: false,
            showStatus: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.chevron_right), findsNothing);
    final texts = [for (final p in _paragraphs(tester)) p.text.toPlainText()];
    // A letra do resultado, o nome e as duas linhas do detalhe.
    expect(texts, hasLength(4));
  });
}
