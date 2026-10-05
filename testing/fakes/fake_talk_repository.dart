import 'package:lucena/data/repositories/characters/talk_repository.dart';

class FakeTalkRepository implements TalkRepository {
  TalkSnapshot? saved;

  @override
  Future<TalkSnapshot?> load() async => saved;

  @override
  Future<void> save(TalkSnapshot snapshot) async => saved = snapshot;
}
