import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/core/motion/rota_que_abre.dart';
import 'package:lucena/ui/lesson_ad/widgets/lesson_entry.dart';

const _abrir = Key('test.cadeado');
const _folha = Key('test.folha');
const _conhecer = Key('test.folha.conhecer');
const _depois = Key('test.folha.depois');
const _tela = Size(412, 860);

/// H-ANI-04, entrada única da venda: "Conhecer o Pilares" na folha do
/// cadeado (PropV2MetaSemCompraDemoCadeadoFolha) abre a apresentação
/// crescendo da folha, em 560 ms, e não da chamada da aba que está embaixo.
void main() {
  Future<void> abre(WidgetTester t, {bool reduzir = false}) async {
    t.view.physicalSize = _tela;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                // A chamada "Conhecer o Pilares" da aba, no alto, com o
                // mesmo id da venda.
                OrigemQueAbre(
                  id: pilaresSaleOrigin,
                  child: Container(height: 60, color: Colors.amber),
                ),
                TextButton(
                  key: _abrir,
                  onPressed: () async {
                    final ver = await LessonEntry.showLockedFeature(
                      context,
                      title: 'Metas fazem parte do Pilares',
                      body: 'No Pilares, o que você erra volta nas metas.',
                      primary: 'Conhecer o Pilares',
                      sheetKey: _folha,
                      primaryKey: _conhecer,
                      laterKey: _depois,
                    );
                    if (ver && context.mounted) {
                      await context.push('/apresentacao');
                    }
                  },
                  child: const Text('meta trancada'),
                ),
              ],
            ),
          ),
          routes: [
            GoRoute(
              path: 'apresentacao',
              pageBuilder: (context, state) => RotaQueAbre<void>(
                context: context,
                id: pilaresSaleOrigin,
                venda: true,
                key: state.pageKey,
                child: const Scaffold(body: Text('apresentação')),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: _tela, disableAnimations: reduzir),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (_, child) => EntradasVistasEscopo(
            vistas: EntradasVistas(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(_abrir));
    await t.pumpAndSettle();
  }

  testWidgets('Conhecer o Pilares cresce da folha até a tela em 560 ms', (
    t,
  ) async {
    await abre(t);
    final folha = t.getRect(find.byKey(_folha));
    await t.tap(find.byKey(_conhecer));
    await t.pump();
    await t.pump();
    final inicio = t.getRect(find.byKey(MotionKeys.rotaQueAbre));
    // Começa na folha (embaixo), não na chamada do alto da aba.
    expect(inicio.top, greaterThan(folha.top - 2));
    expect(inicio.height, lessThan(folha.height + 2));
    await t.pump(const Duration(milliseconds: 280));
    final meio = t.getRect(find.byKey(MotionKeys.rotaQueAbre));
    expect(meio.top, inExclusiveRange(0, inicio.top));
    expect(meio.top, greaterThan(60));
    await t.pump(const Duration(milliseconds: 281));
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
    expect(find.text('apresentação'), findsOneWidget);
  });

  testWidgets('Agora não só fecha a folha', (t) async {
    await abre(t);
    await t.tap(find.byKey(_depois));
    await t.pumpAndSettle();
    expect(find.byKey(_folha), findsNothing);
    expect(find.text('apresentação'), findsNothing);
  });

  testWidgets('movimento reduzido: a apresentação entra em fade', (t) async {
    await abre(t, reduzir: true);
    await t.tap(find.byKey(_conhecer));
    await t.pump();
    await t.pump();
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
    await t.pumpAndSettle();
    expect(find.text('apresentação'), findsOneWidget);
  });
}
