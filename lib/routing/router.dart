import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/use_cases/game_rules.dart';
import '../ui/board_settings/widgets/board_appearance_screen.dart';
import '../ui/board_settings/widgets/board_behavior_screen.dart';
import '../ui/free_board/view_models/free_board_cubit.dart';
import '../ui/free_board/widgets/free_board_screen.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/settings/widgets/language_screen.dart';
import '../ui/settings/widgets/settings_screen.dart';
import '../ui/settings/widgets/theme_screen.dart';
import 'routes.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'board',
            builder: (context, state) {
              // `?fen=` abre numa posição preparada; FEN inválido cai na inicial.
              // `?side=` deixa o jogador mover só as peças de um lado.
              final fen = state.uri.queryParameters['fen'];
              final side = state.uri.queryParameters['side'];
              final start = fen == null ? null : GameRules.fromFen(fen);
              return BlocProvider(
                key: ValueKey(state.uri),
                create: (context) => FreeBoardCubit(
                  start: start ?? GameRules.initial,
                  playerSide: Side.values.asNameMap()[side],
                ),
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
            ],
          ),
        ],
      ),
    ],
  );
}
