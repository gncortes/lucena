import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/learning/learning_content_version.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/lesson_content.dart';

class _Content extends AssetService {
  final files = <String, String>{
    'assets/lessons/endgames/x.json':
        '{"parts":[{"id":"a","roteiro":"assets/lessons/roteiros/x/a.json"}]}',
    'assets/lessons/roteiros/x/a.json': '{"stages":[]}',
  };
  bool offline = false;
  @override
  Future<String> loadString(String path) async {
    if (offline) throw Exception('offline');
    return files[path] ?? (throw const LessonContentNotFound());
  }
}

void main() {
  test('School fingerprint follows the actual lessons.json texts', () async {
    final content = _Content();
    content.files['assets/lessons/course.json'] =
        '{"modules":[{"id":"m","lessons":[{"id":"school.x","steps":[]}]}]}';
    content.files['assets/lessons/en/lessons.json'] =
        '{"school.x.title":"Before"}';
    final version = LearningContentVersion(content);
    final first = await version(false, 'school.x');
    expect(first, hasLength(64));
    content.files['assets/lessons/en/lessons.json'] =
        '{"school.y.title":"Other change", "school.x.title":"Before"}';
    expect(await version(false, 'school.x'), first);
    content.files['assets/lessons/en/lessons.json'] =
        '{"school.x.title":"After"}';
    expect(await version(false, 'school.x'), isNot(first));
  });
  test(
    'fingerprint includes scripts and texts; transport failure has no version',
    () async {
      final content = _Content();
      final version = LearningContentVersion(content);
      final initial = await version(true, 'x');
      expect(initial, hasLength(64));
      expect(await version(true, 'x'), initial);
      content.files['assets/lessons/roteiros/x/a.json'] = '{"stages":[1]}';
      final updated = await version(true, 'x');
      expect(updated, isNot(initial));
      content.files['assets/lessons/pt/endgames/x.a.rot.json'] =
          '{"fala":"nova"}';
      expect(await version(true, 'x'), isNot(updated));
      content.offline = true;
      expect(await version(true, 'x'), isNull);
    },
  );
}
