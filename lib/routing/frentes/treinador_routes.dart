import '../../ui/treinador_seu_jogo/widgets/seu_jogo_aba.dart';

import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/analysis/analysis_repository.dart';
import '../../data/repositories/analysis/learning_analysis_repository.dart';
import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../data/repositories/treinador/curiosidades_repository.dart';
import '../../data/repositories/treinador/treinador_preferencias.dart';
import '../../data/repositories/treinador/treinador_repository.dart';
import '../../domain/models/learning_analysis.dart';
import '../../domain/models/treinador/treinador.dart';
import '../../domain/use_cases/now.dart';
import '../../domain/use_cases/treinador/lances_da_partida.dart';
import '../../ui/core/keys/treinador_keys.dart';
import '../../ui/core/l10n/l10n.dart';
import '../../ui/core/widgets/load_error.dart';
import '../../ui/core/widgets/load_skeleton.dart';
import '../../ui/learning_analysis/view_models/learning_analysis_cubit.dart';
import '../../ui/learning_analysis/widgets/learning_analysis_screen.dart';
import '../../ui/survey/view_models/viktor_thanks_cubit.dart';
import '../../ui/treinador/view_models/curiosidades_cubit.dart';
import '../../ui/treinador/view_models/treinador_cubit.dart';
import '../../ui/treinador/view_models/treinador_exercicio_cubit.dart';
import '../../ui/treinador/view_models/treinador_partida_cubit.dart';
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
      create: (c) => TreinadorCubit(
        repository: c.read<TreinadorRepository>(),
        grants: c.read<CourseGrantsRepository>(),
        preferencias: c.read<TreinadorPreferencias>(),
        now: c.read<Now>(),
      )..load(),
      child: _VoltarDoSistema(
        destino: Routes.home,
        child: TreinadorScreen(
          key: ValueKey(state.uri.queryParameters['aba']),
          aba: AbaTreinador.parse(state.uri.queryParameters['aba']),
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
          BlocProvider(
            create: (c) => TreinadorPartidaCubit(
              id: id,
              repository: c.read<TreinadorRepository>(),
              grants: c.read<CourseGrantsRepository>(),
              preferencias: c.read<TreinadorPreferencias>(),
              now: c.read<Now>(),
            )..load(),
          ),
          BlocProvider(
            create: (c) => CuriosidadesCubit(
              repository: c.read<CuriosidadesRepository>(),
              now: c.read<Now>(),
            )..load(),
          ),
          BlocProvider(
            create: (c) =>
                ViktorThanksCubit(characters: c.read<CharacterRepository>())
                  ..load(),
          ),
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
          create: (c) => TreinadorExercicioCubit(
            id: state.pathParameters['id']!,
            repository: c.read<TreinadorRepository>(),
            preferencias: c.read<TreinadorPreferencias>(),
            refazer: state.uri.queryParameters['refazer'] == '1',
          )..load(),
        ),
        BlocProvider(
          create: (c) =>
              ViktorThanksCubit(characters: c.read<CharacterRepository>())
                ..load(),
        ),
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

/// A análise completa da partida: a linha do PGN no tabuleiro de análise,
/// com os comentários do servidor nos lances ruins.
class _AnaliseDaPartida extends StatefulWidget {
  const _AnaliseDaPartida({required this.id, this.lance});

  final String id;

  /// O meio-lance aberto (1 = o primeiro lance das brancas).
  final int? lance;

  @override
  State<_AnaliseDaPartida> createState() => _AnaliseDaPartidaState();
}

class _AnaliseDaPartidaState extends State<_AnaliseDaPartida> {
  late final Future<PartidaTreinador?> _partida = context
      .read<TreinadorRepository>()
      .partida(widget.id)
      .first
      .timeout(const Duration(seconds: 20));

  @override
  void initState() {
    super.initState();
    unawaited(_marcarVista());
  }

  /// `progresso.viuAnalise` (o funil do painel): uma vez por partida.
  Future<void> _marcarVista() async {
    final repository = context.read<TreinadorRepository>();
    try {
      final progresso = await repository.progresso(widget.id);
      if (progresso.viuAnalise) return;
      await repository.salvarProgresso(widget.id, progresso.comAnaliseVista());
    } on Object catch (e) {
      debugPrint('análise vista sem gravar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<PartidaTreinador?>(
      future: _partida,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return LoadSkeletonScreen(title: l.treinadorAnaliseTitulo);
        }
        final partida = snap.data;
        if (snap.hasError || partida == null) {
          return LoadErrorScreen(
            kind: snap.hasError
                ? LoadErrorKind.offline
                : LoadErrorKind.notFound,
            onAction: () => context.go(Routes.treinador()),
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(Routes.treinador()),
          );
        }
        final lances = LancesDaPartida.de(partida.pgn);
        final anotacoes = <int, AnalysisAnnotation>{
          for (final (i, lance) in partida.lances.indexed)
            if (lance.classe.ruim || (lance.comentario ?? '').isNotEmpty)
              i + 1: AnalysisAnnotation(
                suffix: switch (lance.classe) {
                  ClasseLance.grave => '??',
                  ClasseLance.erro => '?',
                  ClasseLance.imprecisao => '?!',
                  ClasseLance.ok => null,
                },
                comment: lance.comentario,
              ),
        };
        final launch = LearningAnalysisLaunch(
          fen: LancesDaPartida.inicio(partida.pgn),
          moves: [for (final m in lances) m.uci],
          orientation: partida.cor == CorPartida.pretas
              ? Side.black
              : Side.white,
          selected: widget.lance?.clamp(0, lances.length),
        );
        return KeyedSubtree(
          key: TreinadorKeys.analise,
          child: BlocProvider(
            create: (c) => LearningAnalysisCubit(
              launch: launch,
              repository: c.read<LearningAnalysisRepository>(),
              engine: c.read<AnalysisRepository>(),
            )..load(),
            child: LearningAnalysisScreen(
              title: l.treinadorAnaliseTitulo,
              annotations: anotacoes,
            ),
          ),
        );
      },
    );
  }
}
