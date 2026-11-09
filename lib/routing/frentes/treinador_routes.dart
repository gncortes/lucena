import '../../ui/treinador_seu_jogo/widgets/seu_jogo_aba.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/use_cases/treinador/revisao_da_partida.dart';
import '../../config/view_models/coach.dart';
import '../../ui/core/keys/treinador_keys.dart';
import '../../ui/treinador/view_models/coach_analysis_cubit.dart';
import '../../ui/core/l10n/l10n.dart';
import '../../ui/core/widgets/load_error.dart';
import '../../ui/core/widgets/load_skeleton.dart';
import '../../ui/game_details/view_models/game_details_cubit.dart';
import '../../ui/game_details/widgets/game_details_screen.dart';
import '../../ui/treinador/widgets/treinador_exercicio_screen.dart';
import '../../ui/treinador/widgets/treinador_partida_screen.dart';
import '../../ui/treinador/widgets/treinador_screen.dart';
import '../route_names.dart';
import '../routes.dart';
import '../router.dart';

/// Telas do Treinador de partidas (T87). Só a frente app-análise mexe neste
/// arquivo; a aba Seu jogo entra pelo `seuJogo` da [TreinadorScreen].
abstract final class TreinadorPaths {
  static const treinador = '/treinador';
  static const partida = '/treinador/partida/:id';
  static const exercicios = '/treinador/partida/:id/exercicios';
  static const analise = '/treinador/partida/:id/analise';
}

final List<RouteBase> treinadorRoutes = [
  appRoute(
    name: RouteNames.treinador,
    path: TreinadorPaths.treinador,
    builder: (context, state) => BlocProvider(
      create: (c) => createCoachCubit(c)..load(),
      child: _VoltarDoSistema(
        destino: Routes.home,
        child: TreinadorScreen(
          key: ValueKey(state.uri.queryParameters['aba']),
          aba: AbaTreinador.parse(state.uri.queryParameters['aba']),
          abrirUltima: state.uri.queryParameters['abrir'] == 'ultima',
          seuJogo: (_) => const SeuJogoAba(),
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.treinadorPartida,
    path: TreinadorPaths.partida,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (c) => createCoachGameCubit(c, id: id)..load()),
          BlocProvider(create: (c) => createTriviaCubit(c)..load()),
          BlocProvider(create: (c) => createViktorThanksCubit(c)..load()),
        ],
        child: const _VoltarDoSistema(child: TreinadorPartidaScreen()),
      );
    },
  ),
  appRoute(
    name: RouteNames.treinadorExercicios,
    path: TreinadorPaths.exercicios,
    builder: (context, state) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (c) => createCoachExerciseCubit(
            c,
            id: state.pathParameters['id']!,
            redo: state.uri.queryParameters['refazer'] == '1',
          )..load(),
        ),
        BlocProvider(create: (c) => createViktorThanksCubit(c)..load()),
      ],
      child: const _VoltarDoSistema(child: TreinadorExercicioScreen()),
    ),
  ),
  appRoute(
    name: RouteNames.treinadorAnalise,
    path: TreinadorPaths.analise,
    builder: (context, state) => _VoltarDoSistema(
      child: _AnaliseDaPartida(
        id: state.pathParameters['id']!,
        lance: int.tryParse(state.uri.queryParameters['lance'] ?? ''),
      ),
    ),
  ),
];

/// O Voltar do sistema numa tela do Treinador aberta sem nada embaixo (o
/// atalho da Home usa `go`, a notificação abre a partida direto): em vez de
/// fechar o app, vai a [destino] (a Home, ou a lista do Treinador). Com tela
/// embaixo, o Voltar volta normalmente.
class _VoltarDoSistema extends StatelessWidget {
  const _VoltarDoSistema({required this.child, this.destino});

  final Widget child;
  final String? destino;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: GoRouter.of(context).canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go(destino ?? Routes.treinador());
    },
    child: child,
  );
}

/// A análise completa da partida, na mesma base da análise de partida do app
/// ([GameDetailsScreen]): a linha do PGN, a qualidade de cada lance pela
/// classe do servidor e os comentários do treinador.
class _AnaliseDaPartida extends StatelessWidget {
  const _AnaliseDaPartida({required this.id, this.lance});

  final String id;

  /// O meio-lance aberto (1 = o primeiro lance das brancas).
  final int? lance;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (c) => createCoachAnalysisCubit(c, id: id)..load(),
    child: _AnaliseCorpo(lance: lance),
  );
}

class _AnaliseCorpo extends StatelessWidget {
  const _AnaliseCorpo({this.lance});

  final int? lance;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<CoachAnalysisCubit, CoachAnalysisState>(
      builder: (context, state) {
        final partida = state.game;
        if (state.status == CoachAnalysisStatus.loading) {
          return LoadSkeletonScreen(title: l.treinadorAnaliseTitulo);
        }
        if (partida == null) {
          return LoadErrorScreen(
            kind: state.status == CoachAnalysisStatus.offline
                ? LoadErrorKind.offline
                : LoadErrorKind.notFound,
            onAction: () => context.go(Routes.treinador()),
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(Routes.treinador()),
          );
        }
        final jogo = RevisaoDaPartida.de(
          partida,
          lance: lance,
          peso: GameDetailsCubit.importedWeight,
        );
        return KeyedSubtree(
          key: TreinadorKeys.analise,
          child: BlocProvider(
            create: (c) => createImportedGameDetailsCubit(c, jogo)..load(),
            child: GameDetailsScreen(
              title: l.treinadorAnaliseTitulo,
              onBack: () => Navigator.maybePop(context),
            ),
          ),
        );
      },
    );
  }
}
