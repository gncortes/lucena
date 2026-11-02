// Native evidence harness. Persistence is real; catalog/services are fixtures.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/featured/featured_progress_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/find_move_checkpoint.dart';
import 'package:lucena/ui/featured/view_models/featured_endgame_cubit.dart';
import 'package:lucena/ui/featured/widgets/featured_endgame_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import 'fakes/fake_character_repository.dart';
import 'fakes/fake_featured_repositories.dart';
import 'fakes/fake_settings_repository.dart';
import 'test_app.dart';

class _VisibleProgress extends LocalFeaturedProgressRepository {
  _VisibleProgress() : super(PreferencesService());

  @override
  Future<FindMoveCheckpoint?> findMove(FeaturedEndgame endgame) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return super.findMove(endgame);
  }

  @override
  Future<void> saveFindMove(
    String id,
    FindMoveCheckpoint checkpoint, {
    Future<void> Function()? onPlayed,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return super.saveFindMove(id, checkpoint, onPlayed: onPlayed);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = _VisibleProgress();
  final catalog = FakeFeaturedRepository(sampleFeaturedCatalog());
  final settings = SettingsCubit(
    FakeSettingsRepository(const AppSettings(languageCode: 'pt')),
    languages: AppLanguage.selectable,
  );
  await settings.load();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settings),
            BlocProvider(
              create: (_) => FeaturedEndgameCubit(
                id: 'b',
                featured: catalog,
                progress: progress,
                characters: FakeCharacterRepository(),
              )..load(),
            ),
            RepositoryProvider<FeaturedProgressRepository>.value(
              value: progress,
            ),
          ],
          child: const FeaturedEndgameScreen(),
        ),
      ),
    ],
  );
  runApp(
    TestApp(
      router: router,
      settingsCubit: settings,
      locale: const Locale('pt'),
      child: const SizedBox.shrink(),
    ),
  );
}
