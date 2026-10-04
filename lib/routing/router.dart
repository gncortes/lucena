import 'package:go_router/go_router.dart';

import '../ui/home/widgets/home_screen.dart';
import 'routes.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
