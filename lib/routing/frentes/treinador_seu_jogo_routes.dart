import 'package:go_router/go_router.dart';

import '../../ui/treinador_seu_jogo/widgets/estilo_screen.dart';
import '../../ui/treinador_seu_jogo/widgets/partidas_modelo_screen.dart';
import '../../ui/treinador_seu_jogo/widgets/pilares_abertura_screen.dart';
import '../../ui/treinador_seu_jogo/widgets/seu_jogo_aba.dart';
import '../../ui/treinador_seu_jogo/widgets/tema_screen.dart';
import '../../ui/treinador_seu_jogo/widgets/teoria_screen.dart';
import '../route_names.dart';
import '../router.dart';

/// Telas do Seu jogo do Treinador de partidas (T87). Tudo sob
/// `/treinador/seu-jogo` para não cruzar com as rotas do resto do Treinador.
abstract final class SeuJogoPaths {
  /// A aba em tela própria (o casco de três abas usa só o corpo).
  static const seuJogo = '/treinador/seu-jogo';
  static const tema = '/treinador/seu-jogo/tema/:tema';
  static const estilo = '/treinador/seu-jogo/estilo';
  static const teoria = '/treinador/seu-jogo/teoria/:partida';
  static const modelos = '/treinador/seu-jogo/modelos/:eco';
  static const pilares = '/treinador/seu-jogo/pilares/:slot';

  static String temaDe(String tema) =>
      '/treinador/seu-jogo/tema/${Uri.encodeComponent(tema)}';

  static String teoriaDe(String partida) =>
      '/treinador/seu-jogo/teoria/${Uri.encodeComponent(partida)}';

  /// [nome] = nome da abertura para o título ("Partidas-modelo da Eslava").
  static String modelosDe(String eco, {String? nome}) => Uri(
    path: '/treinador/seu-jogo/modelos/${Uri.encodeComponent(eco)}',
    queryParameters: {'nome': ?nome},
  ).toString();

  /// [parte] e [lance] = o que o servidor ligou à saída da teoria.
  static String pilaresDe(String slot, {int? parte, String? lance}) => Uri(
    path: '/treinador/seu-jogo/pilares/${Uri.encodeComponent(slot)}',
    queryParameters: {'parte': ?parte?.toString(), 'lance': ?lance},
  ).toString();
}

final List<RouteBase> treinadorSeuJogoRoutes = [
  appRoute(
    name: RouteNames.seuJogo,
    path: SeuJogoPaths.seuJogo,
    builder: (context, state) => const SeuJogoScreen(),
  ),
  appRoute(
    name: RouteNames.seuJogoTema,
    path: SeuJogoPaths.tema,
    builder: (context, state) =>
        SeuJogoTemaScreen(tema: state.pathParameters['tema'] ?? ''),
  ),
  appRoute(
    name: RouteNames.seuJogoEstilo,
    path: SeuJogoPaths.estilo,
    builder: (context, state) => const SeuJogoEstiloScreen(),
  ),
  appRoute(
    name: RouteNames.seuJogoTeoria,
    path: SeuJogoPaths.teoria,
    builder: (context, state) =>
        SeuJogoTeoriaScreen(partidaId: state.pathParameters['partida'] ?? ''),
  ),
  appRoute(
    name: RouteNames.seuJogoModelos,
    path: SeuJogoPaths.modelos,
    builder: (context, state) => PartidasModeloScreen(
      eco: state.pathParameters['eco'] ?? '',
      nome: state.uri.queryParameters['nome'],
    ),
  ),
  appRoute(
    name: RouteNames.seuJogoPilares,
    path: SeuJogoPaths.pilares,
    builder: (context, state) => PilaresAberturaScreen(
      slot: state.pathParameters['slot'] ?? '',
      parte: int.tryParse(state.uri.queryParameters['parte'] ?? ''),
      lance: state.uri.queryParameters['lance'],
    ),
  ),
];
