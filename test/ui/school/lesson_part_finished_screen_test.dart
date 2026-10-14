import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T65 (F4, item 2): o capítulo concluído fica como na V1, sem a barra de
/// progresso, com "Revisar" e "Próximo" do mesmo tamanho.
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  final lesson = Lesson.parted(
    id: 'rook.lucena',
    parts: const [
      LessonPart(
        id: 'one',
        steps: [TalkStep(id: 'a', fen: fen)],
      ),
      LessonPart(
        id: 'two',
        steps: [TalkStep(id: 'b', fen: fen)],
      ),
    ],
  );
  final trail = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: lesson,
            exercises: const [],
            passScore: 0,
            keyPositions: const [],
            practice: const Practice(fen: fen, goal: PositionGoal.win),
          ),
        ],
      ),
    ],
  );

  testWidgets('capítulo concluído: sem barra de progresso e botões iguais', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(
          trail: trail,
          texts: LessonTexts.fromJson({
            'rook.lucena.a': 'First.',
            'rook.lucena.b': 'Second.',
            'coach.partDone': ['Chapter done.'],
            'coach.allPartsDone': ['Lesson done.'],
          }),
        ),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.progress), findsOneWidget);

    await cubit.next();
    await tester.pumpAndSettle();
    // Entre as partes não há tela de fim (crit. 18): vai direto à próxima.
    expect(find.byKey(LessonKeys.partFinished), findsNothing);
    expect(cubit.state.partNumber, 2);
    expect(cubit.state.finished, isFalse);
    expect(find.byKey(LessonKeys.progress), findsOneWidget);
    // Durante a aula, seta; sem ✕ (T73, D12).
    expect(find.byKey(LessonKeys.appBarClose), findsNothing);

    // Na conclusão (T73, D12): ✕ no lugar da seta.
    await cubit.next();
    await tester.pumpAndSettle();
    expect(cubit.state.finished, isTrue);
    // A última parte fecha a aula: fala de fim de aula, não de capítulo.
    expect(cubit.state.speech, 'Lesson done.');
    expect(find.byKey(LessonKeys.appBarClose), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  });
}
