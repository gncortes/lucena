import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/haptics/haptics_repository.dart';
import '../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../domain/models/clock.dart';
import '../domain/use_cases/game_rules.dart';
import '../domain/use_cases/now.dart';
import '../ui/board_settings/widgets/board_appearance_screen.dart';
import '../ui/board_settings/widgets/board_behavior_screen.dart';
import '../ui/board_settings/widgets/clock_settings_screen.dart';
import '../ui/free_board/view_models/free_board_cubit.dart';
import '../ui/free_board/widgets/free_board_screen.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/settings/widgets/language_screen.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/settings/widgets/theme_screen.dart';
import 'routes.dart';

/// [initialLocation] é a tela em que o app abre; as telas de baixo dela na
/// árvore de rotas entram junto, para o botão de voltar funcionar.
GoRouter buildRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'board',
            builder: (context, state) {
              // Sem parâmetros, a tela continua a partida em andamento (ou
              // começa uma do início). Com parâmetros, começa uma partida nova:
              // `?fen=` abre numa posição preparada; FEN inválido cai na inicial.
              // `?side=` deixa o jogador mover só as peças de um lado.
              final fen = state.uri.queryParameters['fen'];
              final side = state.uri.queryParameters['side'];
              // `?white=` e `?black=` (tempo de cada lado) ligam o relógio.
              final white = TimeControl.tryParse(
                state.uri.queryParameters['white'],
              );
              final black = TimeControl.tryParse(
                state.uri.queryParameters['black'],
              );
              final isNewGame = state.uri.queryParameters.isNotEmpty;
              final start = fen == null ? null : GameRules.fromFen(fen);
              return BlocProvider(
                key: ValueKey(state.uri),
                create: (context) => FreeBoardCubit(
                  now: context.read<Now>(),
                  haptics: context.read<HapticsRepository>(),
                  settings: context.read<SettingsRepository>(),
                  games: context.read<OngoingGameRepository>(),
                  start: isNewGame ? start ?? GameRules.initial : null,
                  playerSide: Side.values.asNameMap()[side],
                  clock: white == null || black == null
                      ? null
                      : ClockConfig(white: white, black: black),
                )..open(),
                child: const FreeBoardScreen(),
              );
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'language',
                builder: (context, state) => const LanguageScreen(),
              ),
              GoRoute(
                path: 'theme',
                builder: (context, state) => const ThemeScreen(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'board-appearance',
                builder: (context, state) => const BoardAppearanceScreen(),
              ),
              GoRoute(
                path: 'board-behavior',
                builder: (context, state) => const BoardBehaviorScreen(),
              ),
              GoRoute(
                path: 'clock',
                builder: (context, state) => const ClockSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
