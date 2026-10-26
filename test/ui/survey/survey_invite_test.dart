import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/visible_endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/survey_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';
import 'package:lucena/ui/survey/widgets/survey_invite_card.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_survey_repository.dart';
import '../../../testing/test_app.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

void main() {
  late FakeSurveyRepository surveys;

  setUp(() => surveys = FakeSurveyRepository());

  Future<void> pumpCard(WidgetTester tester, SurveyKind kind) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: surveys,
        child: Scaffold(
          body: SurveyInviteCard(
            key: UniqueKey(),
            kind: kind,
            source: SurveyInviteSource.trail,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('o convite aparece sem resposta e some com ela, por tipo', (
    tester,
  ) async {
    await pumpCard(tester, SurveyKind.endgames);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsOneWidget);
    expect(find.text('O que achou do curso?'), findsOneWidget);
    expect(find.text('Responder'), findsOneWidget);

    await surveys.saveResponse(
      SurveyKind.school,
      const SurveyAnswers(rating: 4),
    );
    await pumpCard(tester, SurveyKind.endgames);
    // Responder a Escola não esconde o de finais.
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsOneWidget);

    await surveys.saveResponse(
      SurveyKind.endgames,
      const SurveyAnswers(rating: 4),
    );
    await pumpCard(tester, SurveyKind.endgames);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsNothing);
  });

  testWidgets('fechar sem enviar mantém o convite; enviar o esconde', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => const Scaffold(
            body: SurveyInviteCard(
              kind: SurveyKind.endgames,
              source: SurveyInviteSource.trail,
            ),
          ),
        ),
        GoRoute(
          path: '/survey/:kind',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('fechar'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: surveys,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SurveyKeys.inviteAction(SurveyKind.endgames)));
    await tester.pumpAndSettle();
    expect(find.text('fechar'), findsOneWidget);
    await tester.tap(find.text('fechar'));
    await tester.pumpAndSettle();
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsOneWidget);

    await tester.tap(find.byKey(SurveyKeys.inviteAction(SurveyKind.endgames)));
    await tester.pumpAndSettle();
    await surveys.saveResponse(
      SurveyKind.endgames,
      const SurveyAnswers(rating: 5),
    );
    await tester.tap(find.text('fechar'));
    await tester.pumpAndSettle();
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsNothing);
    expect(Routes.survey(SurveyKind.endgames), '/survey/endgames');
  });

  testWidgets('a trilha real: só as aulas visíveis, sem "em breve" nem '
      '"avise", e o convite depois do último tile', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final cubit = EndgamesCubit(
      lessons: VisibleEndgameLessonRepository(
        AssetEndgameLessonRepository(
          _Assets(),
          school: AssetLessonRepository(_Assets()),
        ),
      ),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await tester.runAsync(() => cubit.load('pt'));
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        surveyRepository: surveys,
        child: BlocProvider.value(value: cubit, child: const EndgamesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(SurveyKeys.invite(SurveyKind.endgames)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final tiles = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'endgames.lesson.',
          ) &&
          !(widget.key! as ValueKey<String>).value.contains('.score'),
    );
    final ids = {
      for (final element in tiles.evaluate())
        (element.widget.key! as ValueKey<String>).value.substring(
          'endgames.lesson.'.length,
        ),
    };
    expect(ids, isNotEmpty);
    expect(VisibleLessons.endgameLessonIds.containsAll(ids), isTrue);
    expect(find.textContaining('em breve', findRichText: true), findsNothing);
    expect(find.textContaining('avise', findRichText: true), findsNothing);
    expect(find.byKey(SurveyKeys.invite(SurveyKind.endgames)), findsOneWidget);
    // O convite fica abaixo do último tile.
    final lastTile = tester.getBottomLeft(tiles.last).dy;
    expect(
      tester.getTopLeft(find.byKey(SurveyKeys.invite(SurveyKind.endgames))).dy,
      greaterThan(lastTile),
    );
  });
}
