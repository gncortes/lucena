import 'package:go_router/go_router.dart';

import '../../ui/coach_your_game/widgets/style_screen.dart';
import '../../ui/coach_your_game/widgets/model_games_screen.dart';
import '../../ui/coach_your_game/widgets/pilares_opening_screen.dart';
import '../../ui/coach_your_game/widgets/your_game_tab.dart';
import '../../ui/coach_your_game/widgets/motif_screen.dart';
import '../../ui/coach_your_game/widgets/theory_screen.dart';
import '../route_names.dart';
import '../router.dart';

/// Telas do Seu jogo do Treinador de partidas (T87). Tudo sob
/// `/treinador/seu-jogo` para não cruzar com as rotas do resto do Treinador.
abstract final class YourGamePaths {
  /// A aba em tela própria (o casco de três abas usa só o corpo).
  static const yourGame = '/treinador/seu-jogo';
  static const motif = '/treinador/seu-jogo/tema/:tema';
  static const style = '/treinador/seu-jogo/estilo';
  static const theory = '/treinador/seu-jogo/teoria/:partida';
  static const modelGames = '/treinador/seu-jogo/modelos/:eco';
  static const pilares = '/treinador/seu-jogo/pilares/:slot';

  static String motifOf(String motif) =>
      '/treinador/seu-jogo/tema/${Uri.encodeComponent(motif)}';

  static String theoryOf(String game) =>
      '/treinador/seu-jogo/teoria/${Uri.encodeComponent(game)}';

  /// [name] = nome da abertura para o título ("Partidas-modelo da Eslava").
  static String modelGamesOf(String eco, {String? name}) => Uri(
    path: '/treinador/seu-jogo/modelos/${Uri.encodeComponent(eco)}',
    queryParameters: {'nome': ?name},
  ).toString();

  /// [part] e [chessMove] = o que o servidor ligou à saída da teoria.
  static String pilaresOf(String slot, {int? part, String? chessMove}) => Uri(
    path: '/treinador/seu-jogo/pilares/${Uri.encodeComponent(slot)}',
    queryParameters: {'parte': ?part?.toString(), 'lance': ?chessMove},
  ).toString();
}

final List<RouteBase> coachYourGameRoutes = [
  appRoute(
    name: RouteNames.yourGame,
    path: YourGamePaths.yourGame,
    builder: (context, state) => const YourGameScreen(),
  ),
  appRoute(
    name: RouteNames.yourGameMotif,
    path: YourGamePaths.motif,
    builder: (context, state) =>
        YourGameMotifScreen(motif: state.pathParameters['tema'] ?? ''),
  ),
  appRoute(
    name: RouteNames.yourGameStyle,
    path: YourGamePaths.style,
    builder: (context, state) => const YourGameStyleScreen(),
  ),
  appRoute(
    name: RouteNames.yourGameTheory,
    path: YourGamePaths.theory,
    builder: (context, state) =>
        YourGameTheoryScreen(gameId: state.pathParameters['partida'] ?? ''),
  ),
  appRoute(
    name: RouteNames.yourGameModelGames,
    path: YourGamePaths.modelGames,
    builder: (context, state) => ModelGamesScreen(
      eco: state.pathParameters['eco'] ?? '',
      name: state.uri.queryParameters['nome'],
    ),
  ),
  appRoute(
    name: RouteNames.yourGamePilares,
    path: YourGamePaths.pilares,
    builder: (context, state) => PilaresOpeningScreen(
      slot: state.pathParameters['slot'] ?? '',
      part: int.tryParse(state.uri.queryParameters['parte'] ?? ''),
      chessMove: state.uri.queryParameters['lance'],
    ),
  ),
];
