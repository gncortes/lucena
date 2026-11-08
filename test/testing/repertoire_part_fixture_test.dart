import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';

import '../../testing/training/repertoire_part_fixture.dart';

void main() {
  test('parallel bank completion cannot select an inactive profile', () {
    final solid = OpeningTrecho(
      id: 'solid-part',
      title: 'Solid part',
      profile: 'solido',
      lines: [
        ['d2d4', 'd7d5'],
      ],
    );
    final aggressive = OpeningTrecho(
      id: 'aggressive-part',
      title: 'Aggressive part',
      profile: 'agressivo',
      lines: [
        ['e2e4', 'e7e5'],
      ],
    );
    final selected = repertoirePartFixture(
      TrainingResources(
        lessons: const [
          TrainingLesson(
            id: 'solid',
            kind: TrainingLessonKind.opening,
            title: 'Solid',
            openingProfile: 'solido',
          ),
          TrainingLesson(
            id: 'aggressive',
            kind: TrainingLessonKind.opening,
            title: 'Aggressive',
            openingProfile: 'agressivo',
            visible: false,
          ),
        ],
        // The inactive bank finished loading first.
        openings: {
          'aggressive': [aggressive],
          'solid': [solid],
        },
      ),
    );
    expect(selected.lessonId, 'solid');
    expect(selected.part, same(solid));
  });
}
