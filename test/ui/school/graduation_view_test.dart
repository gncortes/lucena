import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_finished.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_share_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(360, 640),
    FakeShareRepository? share,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final profile = ProfileCubit(
      FakeProfileRepository(const UserProfile(nickname: 'Ana')),
    );
    addTearDown(profile.close);
    await profile.load();
    await tester.pumpWidget(
      TestApp(
        profileCubit: profile,
        shareRepository: share,
        child: MediaQuery(
          data: MediaQueryData(size: size, disableAnimations: true),
          child: Scaffold(
            body: LessonFinished(
              state: LessonState(
                ready: true,
                finished: true,
                courseFinished: true,
                finishedAt: DateTime.utc(2026, 10, 8),
                lesson: const Lesson(id: 'tricks.final', steps: []),
                viktor: FakeCharacterRepository.viktor,
                speech: 'You graduated!',
                lessonNumber: 39,
                lessonCount: 39,
                graduationPath: const [
                  CourseModule(
                    id: 'pieces',
                    lessons: [
                      Lesson(id: 'pieces.rook', steps: []),
                      Lesson(id: 'pieces.bishop', steps: []),
                    ],
                  ),
                  CourseModule(
                    id: 'graduation',
                    lessons: [Lesson(id: 'graduation.twoBishops', steps: [])],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('diploma com o apelido e a data', (tester) async {
    await pump(tester);
    expect(find.byKey(SchoolKeys.diploma), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.byKey(SchoolKeys.graduationSummary), findsOneWidget);
  });

  testWidgets('"Subir a Jornada" à vista sem rolar num celular pequeno', (
    tester,
  ) async {
    await pump(tester, size: const Size(320, 568));
    final journey = tester.getRect(find.byKey(LessonKeys.journeyButton));
    expect(journey.bottom, lessThanOrEqualTo(568));
    expect(journey.top, greaterThan(0));
    // O convite do Lichess fica no fim, depois do diploma.
    final diploma = tester.getRect(find.byKey(SchoolKeys.diploma));
    final invite = tester.getRect(find.byKey(LessonKeys.lichessInvite));
    expect(invite.top, greaterThan(diploma.bottom));
  });

  testWidgets('caminho: os módulos feitos e a prova final', (tester) async {
    await pump(tester);
    final path = find.byKey(SchoolKeys.graduationSummary);
    expect(
      find.descendant(of: path, matching: find.text('2 lessons')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: path,
        matching: find.textContaining('Passed the final test'),
      ),
      findsOneWidget,
    );
    // O módulo da prova não vira linha de módulo.
    expect(
      find.descendant(of: path, matching: find.text('1 lesson')),
      findsNothing,
    );
  });

  testWidgets('compartilhar manda a imagem do cartão e o texto com o site', (
    tester,
  ) async {
    final share = FakeShareRepository();
    await pump(tester, share: share);
    // O cartão (título, diploma, caminho e marca) está dentro da imagem.
    for (final key in [SchoolKeys.diploma, SchoolKeys.graduationSummary]) {
      expect(
        find.descendant(
          of: find.byKey(SchoolKeys.graduationCard),
          matching: find.byKey(key),
        ),
        findsOneWidget,
      );
    }
    await tester.ensureVisible(find.byKey(SchoolKeys.graduationShare));
    await tester.runAsync(
      () => tester.tap(find.byKey(SchoolKeys.graduationShare)),
    );
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && share.shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    expect(share.shared, hasLength(1));
    final sent = share.shared.single;
    expect(sent.name, 'lucena-diploma.png');
    // PNG de verdade: começa com a assinatura do formato.
    expect(sent.png.sublist(1, 4), 'PNG'.codeUnits);
    expect(sent.text, contains('39'));
    expect(sent.text, contains('https://gncortes.github.io/lucena/en/'));
  });
}
