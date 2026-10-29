import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/training_help/widgets/training_help_screen.dart';
import 'package:lucena/ui/training_help/widgets/training_tour.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  for (final size in phoneSizes) {
    testWidgets(
      'FAQ abre as seis respostas e tour por ação explícita em $size',
      (tester) async {
        setPhoneSize(tester, size);
        var tour = false;
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: TrainingHelpScreen(onBack: () {}, onTour: () => tour = true),
          ),
        );
        await tester.pumpAndSettle();
        final t = tester.element(find.byType(TrainingHelpScreen)).l10n;
        final answers = [
          t.courseGuideFaq1Answer,
          t.courseGuideFaq2Answer,
          t.courseGuideFaq3Answer,
          t.courseGuideFaq4Answer,
          t.courseGuideFaq5Answer,
          t.courseGuideFaq6Answer,
        ];
        expect(find.text(answers.first).hitTestable(), findsOneWidget);
        final questions = [
          t.courseGuideFaq1Question,
          t.courseGuideFaq2Question,
          t.courseGuideFaq3Question,
          t.courseGuideFaq4Question,
          t.courseGuideFaq5Question,
          t.courseGuideFaq6Question,
        ];
        await tester.tap(find.text(questions.first));
        await tester.pumpAndSettle();
        for (var i = 2; i <= 6; i++) {
          await Scrollable.ensureVisible(
            tester.element(find.text(questions[i - 1])),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(questions[i - 1]));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(answers[i - 1]));
          await tester.pumpAndSettle();
          expect(find.text(answers[i - 1]).hitTestable(), findsOneWidget);
          await Scrollable.ensureVisible(
            tester.element(find.text(questions[i - 1])),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(questions[i - 1]));
          await tester.pumpAndSettle();
        }
        await tester.scrollUntilVisible(
          find.byKey(TrainingKeys.helpTour),
          -200,
        );
        await tester.tap(find.byKey(TrainingKeys.helpTour));
        expect(tour, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    for (final finish in ['done', 'skip', 'close', 'back', 'retry']) {
      testWidgets('tour $finish persiste antes de sair em $size', (
        tester,
      ) async {
        setPhoneSize(tester, size);
        final repository = FakeTrainingRepository(
          content: {TrainingCourse.pilares: TrainingResources()},
        );
        final cubit = CourseGuideCubit(
          repository: repository,
          config: TrainingCourseConfig.pilares,
          now: FakeNow(DateTime(2026, 10, 28)),
        );
        addTearDown(cubit.close);
        addTearDown(repository.dispose);
        await cubit.load();
        final tabs = <CourseGuideTab>[];
        var closed = false;
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: TrainingTour(
                onTab: tabs.add,
                onClose: () => closed = true,
                child: const Scaffold(body: SizedBox()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tabs, [CourseGuideTab.lesson]);
        expect(
          (await repository.load(TrainingCourse.pilares)).tourSeen,
          isFalse,
        );
        if (finish == 'done') {
          for (var i = 0; i < 3; i++) {
            await tester.tap(find.byKey(TrainingKeys.tourNext));
            await tester.pumpAndSettle();
          }
          expect(tabs, CourseGuideTab.values);
          expect(find.byKey(TrainingKeys.tourSkip), findsNothing);
          await tester.tap(find.byKey(TrainingKeys.tourNext));
        } else if (finish == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          if (finish == 'retry') repository.writeError = StateError('save');
          await tester.tap(
            find.byKey(
              finish == 'close'
                  ? TrainingKeys.tourClose
                  : TrainingKeys.tourSkip,
            ),
          );
          if (finish == 'retry') {
            await tester.pumpAndSettle();
            expect(closed, isFalse);
            expect(
              (await repository.load(TrainingCourse.pilares)).tourSeen,
              isFalse,
            );
            repository.writeError = null;
            await tester.tap(find.byKey(TrainingKeys.tourSkip));
          }
        }
        await tester.pumpAndSettle();
        expect(closed, isTrue);
        expect(
          (await repository.load(TrainingCourse.pilares)).tourSeen,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
