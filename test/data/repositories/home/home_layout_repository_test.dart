import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/home/home_layout_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  LocalHomeLayoutRepository open() =>
      LocalHomeLayoutRepository(PreferencesService());

  test('sem nada gravado: nulo (a tela usa a sugestão do nível)', () async {
    expect(await open().load(), isNull);
    expect(await open().noticeSeen(), isFalse);
  });

  test('o layout ajustado volta ao reabrir e não muda com o nível', () async {
    final mine = HomeSuggestion.toggle(
      HomeSuggestion.of(RatingLevel.casual),
      HomePath.speedrun,
      RatingLevel.casual,
    );
    await open().save(mine);
    final saved = await open().load();
    expect(saved, mine);
    expect(HomeSuggestion.resolve(saved, RatingLevel.master), mine);
  });

  test('voltar à sugestão: o layout segue o nível de novo', () async {
    await open().save(HomeSuggestion.of(RatingLevel.casual));
    final saved = await open().load();
    expect(
      HomeSuggestion.resolve(saved, RatingLevel.master),
      HomeSuggestion.of(RatingLevel.master),
    );
  });

  test('o aviso visto fica gravado', () async {
    await open().markNoticeSeen();
    expect(await open().noticeSeen(), isTrue);
  });
}
