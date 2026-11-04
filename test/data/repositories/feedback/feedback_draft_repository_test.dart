import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/feedback/feedback_draft_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late PreferencesService preferences;
  late LocalFeedbackDraftRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesService();
    repository = LocalFeedbackDraftRepository(preferences);
  });

  test('grava e lê o assunto e o texto', () async {
    await repository.save(
      const FeedbackDraft(type: FeedbackType.idea, text: 'Relógio maior'),
    );
    final draft = await repository.load();
    expect(draft?.type, FeedbackType.idea);
    expect(draft?.text, 'Relógio maior');
  });

  test('sem assunto ainda, só o texto', () async {
    await repository.save(const FeedbackDraft(text: 'Oi'));
    final draft = await repository.load();
    expect(draft?.type, isNull);
    expect(draft?.text, 'Oi');
  });

  test('apagar some com o rascunho', () async {
    await repository.save(const FeedbackDraft(text: 'Oi'));
    await repository.clear();
    expect(await repository.load(), isNull);
  });

  test('JSON estragado vale como sem rascunho', () async {
    await preferences.setString(LocalFeedbackDraftRepository.key, '{oops');
    expect(await repository.load(), isNull);
    await preferences.setString(LocalFeedbackDraftRepository.key, '[1]');
    expect(await repository.load(), isNull);
  });
}
