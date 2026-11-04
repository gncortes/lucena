import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/featured/view_models/featured_alert_cubit.dart';
import 'package:lucena/ui/featured/view_models/featured_endgame_cubit.dart';
import 'package:lucena/ui/featured/widgets/featured_game_bar.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeFeaturedAlertsRepository prompts;
  late FakeAlertsRepository alertsRepo;
  late FakePushRepository push;

  setUp(() {
    prompts = FakeFeaturedAlertsRepository();
    alertsRepo = FakeAlertsRepository(const AlertSettings(tournaments: false));
    push = FakePushRepository(granted: true);
  });

  // 'a' é um final de torneio; 'c' não tem torneio.
  Future<void> open(WidgetTester tester, {String id = 'a'}) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final alertsCubit = AlertsCubit(
      alerts: alertsRepo,
      push: push,
      profile: FakeProfileRepository(),
    );
    addTearDown(alertsCubit.close);
    await alertsCubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        alertsCubit: alertsCubit,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => FeaturedEndgameCubit(
                id: id,
                featured: FakeFeaturedRepository(sampleFeaturedCatalog()),
                progress: FakeFeaturedProgressRepository(),
                characters: FakeCharacterRepository(),
              )..load(),
            ),
            BlocProvider(
              create: (_) => FeaturedAlertCubit(
                id: id,
                prompts: prompts,
                alerts: alertsRepo,
                push: push,
              )..load(),
            ),
          ],
          child: Scaffold(body: FeaturedEndBar(onAgain: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fim de final de torneio: o cartão pergunta e tem dois botões', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(FeaturedKeys.alertCard), findsOneWidget);
    expect(
      find.text('Quer saber quando sair outro final assim?'),
      findsOneWidget,
    );
    expect(find.textContaining('no máximo um por dia'), findsOneWidget);
    expect(find.textContaining('Dá para desligar no Perfil'), findsOneWidget);
    expect(find.byKey(FeaturedKeys.alertAccept), findsOneWidget);
    expect(find.byKey(FeaturedKeys.alertDecline), findsOneWidget);
    // Nenhum texto repete o rótulo do botão.
    expect(find.text('Quero receber'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);
  });

  testWidgets('a altura reservada pelo tabuleiro cobre o cartão a 360', (
    tester,
  ) async {
    await open(tester);
    tester.view.physicalSize = const Size(360, 1600);
    await tester.pumpAndSettle();
    final height = tester.getSize(find.byKey(FeaturedKeys.alertCard)).height;
    expect(height, lessThanOrEqualTo(FeaturedEndBar.alertHeight));
  });

  testWidgets('"Agora não": o cartão some e não volta neste final', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(FeaturedKeys.alertDecline));
    await tester.pumpAndSettle();
    expect(find.byKey(FeaturedKeys.alertCard), findsNothing);
    expect(alertsRepo.settings.tournaments, isFalse);
    await open(tester);
    expect(find.byKey(FeaturedKeys.alertCard), findsNothing);
  });

  testWidgets('"Quero receber": liga os torneios no Perfil e o cartão some', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(FeaturedKeys.alertAccept));
    await tester.pumpAndSettle();
    expect(find.byKey(FeaturedKeys.alertCard), findsNothing);
    expect(alertsRepo.settings.tournaments, isTrue);
    expect(push.permissionRequests, 1);
    expect(push.followed, isNotEmpty);
  });

  testWidgets('permissão negada: não liga os torneios', (tester) async {
    push.granted = false;
    await open(tester);
    await tester.tap(find.byKey(FeaturedKeys.alertAccept));
    await tester.pumpAndSettle();
    expect(find.byKey(FeaturedKeys.alertCard), findsNothing);
    expect(alertsRepo.settings.tournaments, isFalse);
  });

  testWidgets('final sem torneio: sem cartão', (tester) async {
    await open(tester, id: 'c');
    expect(find.byKey(FeaturedKeys.alertCard), findsNothing);
    expect(find.byKey(FeaturedKeys.continueButton), findsOneWidget);
  });
}
