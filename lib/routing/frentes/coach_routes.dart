import '../../ui/coach_your_game/widgets/your_game_tab.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/use_cases/coach/coach_game_review.dart';
import '../../config/view_models/coach.dart';
import '../../ui/core/keys/coach_keys.dart';
import '../../ui/coach/view_models/coach_analysis_cubit.dart';
import '../../ui/core/l10n/l10n.dart';
import '../../ui/core/widgets/load_error.dart';
import '../../ui/core/widgets/load_skeleton.dart';
import '../../ui/game_details/view_models/game_details_cubit.dart';
import '../../ui/game_details/widgets/game_details_screen.dart';
import '../../ui/coach/widgets/coach_exercise_screen.dart';
import '../../ui/coach/widgets/coach_game_screen.dart';
import '../../ui/coach/widgets/coach_screen.dart';
import '../route_names.dart';
import '../routes.dart';
import '../router.dart';

/// Telas do Treinador de partidas (T87). Só a frente app-análise mexe neste
/// arquivo; a aba Seu jogo entra pelo `seuJogo` da [CoachScreen].
abstract final class CoachPaths {
  static const coach = '/treinador';
  static const game = '/treinador/partida/:id';
  static const exercises = '/treinador/partida/:id/exercicios';
  static const analysis = '/treinador/partida/:id/analise';
}

final List<RouteBase> coachRoutes = [
  appRoute(
    name: RouteNames.coach,
    path: CoachPaths.coach,
    builder: (context, state) => BlocProvider(
      create: (c) => createCoachCubit(c)..load(),
      child: _SystemBack(
        destination: Routes.home,
        child: CoachScreen(
          key: ValueKey(state.uri.queryParameters['aba']),
          tab: CoachTab.parse(state.uri.queryParameters['aba']),
          openLast: state.uri.queryParameters['abrir'] == 'ultima',
          yourGame: (_) => const YourGameTab(),
        ),
      ),
    ),
  ),
  appRoute(
    name: RouteNames.coachGame,
    path: CoachPaths.game,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (c) => createCoachGameCubit(c, id: id)..load()),
          BlocProvider(create: (c) => createTriviaCubit(c)..load()),
          BlocProvider(create: (c) => createViktorThanksCubit(c)..load()),
        ],
        child: const _SystemBack(child: CoachGameScreen()),
      );
    },
  ),
  appRoute(
    name: RouteNames.coachExercises,
    path: CoachPaths.exercises,
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
      child: const _SystemBack(child: CoachExerciseScreen()),
    ),
  ),
  appRoute(
    name: RouteNames.coachAnalysis,
    path: CoachPaths.analysis,
    builder: (context, state) => _SystemBack(
      child: _GameAnalysis(
        id: state.pathParameters['id']!,
        chessMove: int.tryParse(state.uri.queryParameters['lance'] ?? ''),
      ),
    ),
  ),
];

/// O Voltar do sistema numa tela do Treinador aberta sem nada embaixo (o
/// atalho da Home usa `go`, a notificação abre a partida direto): em vez de
/// fechar o app, vai a [destination] (a Home, ou a lista do Treinador). Com tela
/// embaixo, o Voltar volta normalmente.
class _SystemBack extends StatelessWidget {
  const _SystemBack({required this.child, this.destination});

  final Widget child;
  final String? destination;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: GoRouter.of(context).canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go(destination ?? Routes.coach());
    },
    child: child,
  );
}

/// A análise completa da partida, na mesma base da análise de partida do app
/// ([GameDetailsScreen]): a linha do PGN, a qualidade de cada lance pela
/// classe do servidor e os comentários do treinador.
class _GameAnalysis extends StatelessWidget {
  const _GameAnalysis({required this.id, this.chessMove});

  final String id;

  /// O meio-lance aberto (1 = o primeiro lance das brancas).
  final int? chessMove;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (c) => createCoachAnalysisCubit(c, id: id)..load(),
    child: _AnalysisBody(chessMove: chessMove),
  );
}

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({this.chessMove});

  final int? chessMove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<CoachAnalysisCubit, CoachAnalysisState>(
      builder: (context, state) {
        final game = state.game;
        if (state.status == CoachAnalysisStatus.loading) {
          return LoadSkeletonScreen(title: l.treinadorAnaliseTitulo);
        }
        if (game == null) {
          return LoadErrorScreen(
            kind: state.status == CoachAnalysisStatus.offline
                ? LoadErrorKind.offline
                : LoadErrorKind.notFound,
            onAction: () => context.go(Routes.coach()),
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.coach()),
          );
        }
        final match = CoachGameReview.of(
          game,
          chessMove: chessMove,
          weight: GameDetailsCubit.importedWeight,
        );
        return KeyedSubtree(
          key: CoachKeys.analysis,
          child: BlocProvider(
            create: (c) => createImportedGameDetailsCubit(c, match)..load(),
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
