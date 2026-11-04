import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/history_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/chip_lucena.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';
import 'package:lucena/ui/history/widgets/history_filters.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/phone_size.dart';
import '../../../../testing/test_app.dart';
import 'entrada_helpers.dart';

/// H-ANI-21 e H-ANI-23 nas folhas de filtro das telas (Histórico,
/// PropV2HistoricoAbaPartidasFiltro; Finais, PropV2FiltroFinaisAberto): o
/// chip tocado se enche em 200 ms e o anterior se esvazia; as opções entram
/// 120 ms depois de a folha começar a subir, só na 1ª abertura da sessão.
void main() {
  Color fundo(WidgetTester tester, Key chave) {
    final ink = find.descendant(
      of: find.byKey(chave),
      matching: find.byType(Ink),
    );
    final decoracao = tester.widget<Ink>(ink.first).decoration!;
    return (decoracao as ShapeDecoration).color!;
  }

  group('Histórico', () {
    Key opcao(String v) => HistoryKeys.filterOption('result', v);

    Future<void> abre(WidgetTester tester, {EntradasVistas? vistas}) async {
      setPhoneSize(tester, const Size(412, 917));
      await tester.pumpWidget(
        EntradasVistasEscopo(
          vistas: vistas ?? EntradasVistas(),
          child: TestApp(
            locale: const Locale('pt'),
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showHistoryFilterSheet(
                    context,
                    groups: const [
                      HistoryFilterGroup(
                        name: 'result',
                        title: 'Resultado',
                        options: [
                          HistoryOption('win', 'Vitória'),
                          HistoryOption('loss', 'Derrota'),
                        ],
                      ),
                    ],
                    initial: const {'result': 'win'},
                    count: (_) => 3,
                    applyLabel: (n) => 'Ver $n',
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump();
    }

    testWidgets('as opções entram 120 ms depois; na 2ª vez, prontas', (
      tester,
    ) async {
      final vistas = EntradasVistas();
      await abre(tester, vistas: vistas);
      await tester.pump(const Duration(milliseconds: 110));
      expect(opacidadeAcima(tester, find.byKey(opcao('win'))), 0);
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        opacidadeAcima(tester, find.byKey(opcao('win'))),
        allOf(greaterThan(0), lessThan(1)),
      );
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byKey(opcao('win')))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(opacidadeAcima(tester, find.byKey(opcao('win'))), 1);
      await tester.pumpAndSettle();
    });

    testWidgets('o chip tocado se enche em 200 ms; o anterior se esvazia', (
      tester,
    ) async {
      await abre(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ChipLucena), findsNWidgets(2));
      final cheio = fundo(tester, opcao('win'));
      final vazio = fundo(tester, opcao('loss'));
      await tester.tap(find.byKey(opcao('loss')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(fundo(tester, opcao('win')), isNot(anyOf(cheio, vazio)));
      expect(fundo(tester, opcao('loss')), isNot(anyOf(cheio, vazio)));
      await tester.pumpAndSettle();
      expect(fundo(tester, opcao('loss')), cheio);
      expect(fundo(tester, opcao('win')), vazio);
    });
  });

  group('Finais', () {
    Future<void> abre(WidgetTester tester) async {
      setPhoneSize(tester, const Size(412, 917));
      final cubit = EndgamesCubit(
        lessons: FakeEndgameLessonRepository(),
        progress: FakeEndgameProgressRepository(),
        characters: FakeCharacterRepository(),
        settings: FakeSettingsRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load('en');
      await tester.pumpWidget(
        EntradasVistasEscopo(
          vistas: EntradasVistas(),
          child: TestApp(
            child: BlocProvider.value(
              value: cubit,
              child: const EndgamesScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(EndgamesKeys.filtersButton));
      await tester.pump();
    }

    testWidgets('as opções entram em ordem e os chips animam', (tester) async {
      await abre(tester);
      final status = EndgamesKeys.filterOption('status.passed');
      await tester.pump(const Duration(milliseconds: 110));
      expect(opacidadeAcima(tester, find.byKey(status)), 0);
      expect(find.byKey(MotionKeys.itemDoFiltro(0)), findsOneWidget);
      await tester.pumpAndSettle();
      expect(opacidadeAcima(tester, find.byKey(status)), 1);
      expect(
        find.ancestor(of: find.byKey(status), matching: find.byType(ChipLucena)),
        findsNothing,
        reason: 'a key fica no próprio ChipLucena',
      );
      expect(tester.widget(find.byKey(status)), isA<ChipLucena>());
      final vazio = fundo(tester, status);
      await tester.tap(find.byKey(status));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final meio = fundo(tester, status);
      await tester.pumpAndSettle();
      final cheio = fundo(tester, status);
      expect(meio, isNot(anyOf(vazio, cheio)));
    });
  });
}
