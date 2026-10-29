import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/hero_card.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/goldens/golden_harness.dart';
import '../../../../testing/phone_size.dart';
import '../../../../testing/test_app.dart';

void main() {
  setUpAll(Goldens.loadFonts);
  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    for (final status in [HomeCourseStatus.done, HomeCourseStatus.dayOff]) {
      testWidgets('training hero $status retains full question at $size', (
        tester,
      ) async {
        setPhoneSize(tester, size);
        final training = HomeTraining(
          config: TrainingCourseConfig.pilares,
          state: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'compact-hero',
          ),
          resources: TrainingResources(
            lessons: [
              const TrainingLesson(
                id: 'next',
                kind: TrainingLessonKind.theme,
                title: 'Próxima aula',
              ),
            ],
          ),
          card: HomeCourseCard(status, HomeCourseDestination.lessonTab, 'next'),
        );
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: HeroCard(
                    state: HomeState(
                      ready: true,
                      teacher: FakeCharacterRepository.viktor,
                      training: training,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final label = status == HomeCourseStatus.done
            ? 'Metas feitas · mais uma aula?'
            : 'Dia de folga · mais uma aula?';
        final target = find.byKey(HomeKeys.heroLabel);
        final paragraph = tester.renderObject<RenderParagraph>(target);
        expect(paragraph.text.toPlainText(), label);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: 'The final aula? must remain painted.',
        );
        expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: label.length),
        );
        expect(
          boxes.map((box) => box.top).toSet().length,
          size.width == 360 ? 2 : 1,
        );
        for (final box in boxes) {
          expect(box.left, greaterThanOrEqualTo(0));
          expect(box.right, lessThanOrEqualTo(paragraph.size.width + .01));
          expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + .01));
        }
        final action = tester.getRect(find.byKey(HomeKeys.goalAction));
        final labelRect = tester.getRect(target);
        expect(labelRect.right, lessThanOrEqualTo(action.left));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
