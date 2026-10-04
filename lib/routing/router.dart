import 'package:go_router/go_router.dart';

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
            ],
          ),
        ],
      ),
    ],
  );
}
