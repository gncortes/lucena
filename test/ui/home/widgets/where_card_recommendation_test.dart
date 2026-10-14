import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/where_card.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  for (final path in [HomePath.endgames, HomePath.forYou]) {
    for (final size in [
      const Size(360, 640),
      const Size(360, 800),
      const Size(412, 915),
    ]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'C9 $path $size fonte$scale: recomendação legível abre a aula',
          (tester) async {
            tester.view
              ..physicalSize = size
              ..devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final state = HomeState(
              ready: true,
              layout: HomeLayout(
                order: [path, HomePath.journey],
                visible: {path, HomePath.journey},
                custom: true,
              ),
              endgame: EndgameSummary(
                lessonId: 'rook.lucena',
                title: 'The Lucena position',
                score: 0,
                maxScore: 6,
                teacher: FakeCharacterRepository.viktor,
                recommended: true,
              ),
            );
            final router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, _) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: WhereCard(state: state),
                        ),
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: Routes.endgameLesson('rook.lucena'),
                  builder: (_, _) =>
                      const Scaffold(body: Text('opened lesson')),
                ),
              ],
            );
            addTearDown(router.dispose);
            await tester.pumpWidget(
              TestApp(router: router, child: const SizedBox.shrink()),
            );
            await tester.pumpAndSettle();
            expect(state.continuePath, path);
            expect(find.byKey(HomeKeys.endgameCard), findsOneWidget);
            expect(find.byKey(HomeKeys.endgameTitle), findsOneWidget);
            expect(find.text('Endgames for you'), findsOneWidget);
            expect(find.text('Start the lesson'), findsOneWidget);
            expect(find.byKey(HomeKeys.endgameWhere), findsNothing);
            final button = find.byKey(HomeKeys.endgameContinue);
            final card = tester.getRect(find.byKey(HomeKeys.endgameCard));
            expect(tester.getRect(button).right, lessThanOrEqualTo(card.right));
            expect(
              tester
                  .getRect(button)
                  .overlaps(tester.getRect(find.byKey(HomeKeys.endgameTitle))),
              isFalse,
            );
            expect(button.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(find.text('opened lesson'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('lição aberta sem partes: o cartão mostra a nota, não o passo '
      '(fechar o app reabre no início)', (tester) async {
    final state = HomeState(
      ready: true,
      layout: HomeLayout(
        order: [HomePath.endgames, HomePath.journey],
        visible: {HomePath.endgames, HomePath.journey},
        custom: true,
      ),
      endgame: EndgameSummary(
        lessonId: 'rook.lucena',
        title: 'The Lucena position',
        score: 2,
        maxScore: 6,
        teacher: FakeCharacterRepository.viktor,
        lessonOpen: true,
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: WhereCard(state: state)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(router: router, child: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.endgameWhere)).data,
      '2 of 6 points',
    );
    expect(find.textContaining('Step'), findsNothing);
  });
}
