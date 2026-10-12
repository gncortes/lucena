import 'package:lucena/data/repositories/characters/talk_repository.dart';

class FakeTalkRepository implements TalkRepository {
  TalkSnapshot? saved;
  DateTime? speechHintShownAt;

  @override
  Future<TalkSnapshot?> load() async => saved;

  @override
  Future<void> save(TalkSnapshot snapshot) async => saved = snapshot;

  @override
  Future<DateTime?> loadSpeechHintShownAt() async => speechHintShownAt;

  @override
  Future<void> saveSpeechHintShownAt(DateTime shownAt) async =>
      speechHintShownAt = shownAt;
}
