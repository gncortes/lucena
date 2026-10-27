import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/reminder.dart';
import 'package:lucena/routing/push_route.dart';
import 'package:lucena/routing/routes.dart';

void main() {
  const paused = PausedLesson(
    lessonId: 'lucena',
    title: 'Lucena',
    chapter: 2,
    total: 3,
    partId: 'ponte',
    stage: 1,
  );

  Future<String?> route(String link, {PausedLesson? lesson = paused}) =>
      pushRoute(Uri.parse(link), pausedLesson: () async => lesson);

  test('as três rotas das campanhas', () async {
    expect(await route('/daily'), Routes.daily);
    expect(await route('/dia'), Routes.daily);
    expect(
      await route('/lesson'),
      Routes.endgameLessonScript('lucena', part: 'ponte', stage: 1),
    );
    expect(await route('/featured/carlsen-2024'), '/featured/carlsen-2024');
  });

  test('o endereço do app vale como o caminho', () async {
    expect(await route('https://playlucena.com/daily'), Routes.daily);
    expect(await route('https://playlucena.com/dia'), Routes.daily);
    expect(
      await route('https://playlucena.com/featured/tournament/wch'),
      Routes.featuredTournament('wch'),
    );
  });

  test('a aula nova abre a aula', () async {
    expect(await route('/lesson/oposicao'), Routes.endgameLesson('oposicao'));
  });

  test(
    'aula já terminada, outro site ou tela desconhecida: o início',
    () async {
      expect(await route('/lesson', lesson: null), Routes.home);
      expect(await route('https://example.com/daily'), Routes.home);
      expect(await route('javascript:/daily'), Routes.home);
      expect(await route('/settings'), Routes.home);
      // Um link de uma versão nova (tela que esta versão não tem).
      expect(await route('/featured/ranking/2026'), Routes.home);
    },
  );
}
