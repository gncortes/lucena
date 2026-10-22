import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/would_pay/would_pay_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/would_pay.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  LocalWouldPayRepository open() =>
      LocalWouldPayRepository(PreferencesService());

  test('o rascunho volta ao reabrir, no mesmo passo', () async {
    expect(await open().loadDraft(), isNull);
    await open().saveDraft(
      const WouldPayDraft(
        step: 1,
        answers: WouldPayAnswers(
          course: WouldPayAnswer.maybe,
          coursePrice: CoursePrice.upTo29,
          why: {'curious'},
        ),
      ),
    );
    final back = await open().loadDraft();
    expect(back?.step, 1);
    expect(back?.answers.course, WouldPayAnswer.maybe);
    expect(back?.answers.coursePrice, CoursePrice.upTo29);
    expect(back?.answers.why, {'curious'});
  });

  test('"Agora não" fica gravado', () async {
    expect(await open().dismissed(), isFalse);
    await open().dismiss();
    expect(await open().dismissed(), isTrue);
  });

  test('respondido apaga o rascunho', () async {
    await open().saveDraft(
      const WouldPayDraft(step: 2, answers: WouldPayAnswers()),
    );
    await open().markAnswered();
    expect(await open().answered(), isTrue);
    expect(await open().loadDraft(), isNull);
  });

  test('rascunho estragado vale como nenhum', () async {
    await PreferencesService().setString(
      LocalWouldPayRepository.draftKey,
      '{"step": 1, "answers": 3}',
    );
    expect(await open().loadDraft(), isNull);
    await PreferencesService().setString(
      LocalWouldPayRepository.draftKey,
      'não é json',
    );
    expect(await open().loadDraft(), isNull);
  });
}
