import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/ui/lesson_ad/view_models/lesson_entry_gate.dart';

import '../../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../../testing/fakes/fake_lesson_ad_repositories.dart';

void main() {
  test('sem repositórios, o curso está aberto e sem anúncio', () async {
    const gate = LessonEntryGate();

    expect(gate.access, CourseAccess.owned);
    expect(gate.hasAds, isFalse);
    expect(await gate.noticeSeen(), isTrue);
  });

  test('lê o acesso e o aviso da demonstração', () async {
    final ads = FakeDemoAdRepository();
    final gate = LessonEntryGate(
      access: FakeCourseAccessRepository(),
      ads: ads,
    );

    expect(gate.access, CourseAccess.demo);
    expect(gate.hasAds, isTrue);
    expect(await gate.noticeSeen(), isFalse);

    await gate.markNoticeSeen();

    expect(ads.marks, 1);
    expect(await gate.noticeSeen(), isTrue);
  });

  test('depois do anúncio, marca o revés na avaliação', () {
    final review = FakeReviewRepository();
    final gate = LessonEntryGate(review: review);

    gate.noteSetback();

    expect(review.setbacks, 1);
  });
}
