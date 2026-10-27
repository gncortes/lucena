import '../domain/models/app_links.dart';
import '../domain/models/reminder.dart';
import 'routes.dart';

/// Para onde leva o toque num aviso que não é desafio: o `link` dos dados,
/// só o caminho ou um endereço do app (E1.21 §6, campanhas da E1.24).
///
/// - `/daily`: o final do dia ("Não abriu há 3 dias").
/// - `/lesson`: a aula começada, no passo salvo ("Começou uma aula e
///   parou"); terminada desde então, nada.
/// - `/lesson/{id}`: a aula nova.
/// - `/featured/{id}` e `/featured/tournament/{id}`: o final e o torneio.
///
/// Outro endereço (de outro site, aula já terminada ou tela que esta versão
/// do app não tem): o início ([Routes.home]).
Future<String> pushRoute(
  Uri uri, {
  required Future<PausedLesson?> Function() pausedLesson,
}) async {
  if ((uri.hasScheme || uri.hasAuthority) && !AppLinks.isOwn(uri)) {
    return Routes.home;
  }
  return switch (uri.pathSegments) {
    ['daily'] || ['dia'] => Routes.dailyFrom('aviso'),
    ['lesson'] => switch (await pausedLesson()) {
      final paused? => Routes.endgameLessonScript(
        paused.lessonId,
        part: paused.partId,
        stage: paused.stage,
        origin: 'aviso',
      ),
      null => Routes.home,
    },
    ['lesson', final id] => Routes.endgameLesson(id, origin: 'aviso'),
    ['featured', 'tournament', final id] => Routes.featuredTournament(id),
    ['featured', final id] => Routes.featuredEndgame(id),
    _ => Routes.home,
  };
}
