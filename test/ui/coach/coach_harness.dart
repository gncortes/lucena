import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucena/data/repositories/analysis/analysis_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/lesson_ad/course_grants_repository.dart';
import 'package:lucena/data/repositories/settings/settings_repository.dart';
import 'package:lucena/data/repositories/coach/trivia_repository.dart';
import 'package:lucena/data/repositories/coach/your_game_filter_repository.dart';
import 'package:lucena/data/repositories/coach/coach_preferences.dart';
import 'package:lucena/data/repositories/coach/coach_repository.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/coach/trivia.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/frentes/coach_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_grants.dart';
import '../../../testing/fakes/fake_trivia_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';
import '../../../testing/test_app.dart';
import '../learning_analysis/analysis_test_support.dart';

/// Um [PreferencesService] em memória (as preferências do Treinador).
class MemoryPreferences extends PreferencesService {
  MemoryPreferences() : super(_platform());

  static SharedPreferencesAsync _platform() {
    initializeAnalysisPreferences();
    return SharedPreferencesAsync();
  }

  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// O direito `treinador` ativo (o plano de análise).
CourseGrants withPlan() => const CourseGrants(
  courses: {'treinador': CourseGrant(origin: GrantOrigin.purchase)},
);

/// O "agora" fixo dos testes (nunca `DateTime.now()`).
DateTime testNow() => DateTime.utc(2026, 11, 9, 12);

/// Tudo de que as telas e os view models do Treinador dependem, em memória.
class CoachBed {
  CoachBed({
    FakeCoachRepository? repo,
    CourseGrants grants = CourseGrants.empty,
    DateTime? currentTime,
    this.trivias,
    MemoryPreferences? prefs,
  }) : memory = prefs ?? MemoryPreferences(),
       repo = repo ?? FakeCoachRepository.withData(),
       grants = FakeCourseGrantsRepository(grants),
       now = FakeNow(currentTime ?? testNow()) {
    preferences = CoachPreferences(memory);
  }

  final FakeCoachRepository repo;
  final FakeCourseGrantsRepository grants;
  final FakeNow now;
  final MemoryPreferences memory;
  late final CoachPreferences preferences;
  final List<Trivia>? trivias;
  final engine = ControlledAnalysisEngine();
  final characters = FakeCharacterRepository();

  /// O login do Lichess (ligar a conta de lá passa por ele).
  final lichess = FakeLichessRepository();
  late final GoRouter router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const Scaffold(body: Text('stub.home')),
      ),
      GoRoute(
        path: Routes.pilaresSale,
        builder: (_, _) => const Scaffold(body: Text('stub.pilares')),
      ),
      ...coachRoutes,
    ],
  );

  /// O caminho em que o roteador está agora.
  ///
  /// Uma tela empilhada com `push` não muda a base do roteador: o caminho
  /// dela vem da última rota imperativa.
  String get path {
    final configuration = router.routerDelegate.currentConfiguration;
    final top = configuration.last;
    return (top is ImperativeRouteMatch ? top.matches : configuration).uri
        .toString();
  }

  /// O app de teste, em PT-BR, com tudo o que as rotas do Treinador leem.
  Widget app({SettingsCubit? settings}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<CoachRepository>.value(value: repo),
      RepositoryProvider<LichessRepository>.value(value: lichess),
      RepositoryProvider<CourseGrantsRepository>.value(value: grants),
      RepositoryProvider<CoachPreferences>.value(value: preferences),
      // A aba Seu jogo (aberta pelo "Onde você mais erra") lê o filtro.
      RepositoryProvider<YourGameFilterRepository>.value(
        value: YourGameFilterRepository(memory),
      ),
      RepositoryProvider<Now>.value(value: now),
      RepositoryProvider<TriviaRepository>.value(
        value: FakeTriviaRepository(trivias),
      ),
      RepositoryProvider<CharacterRepository>.value(value: characters),
      RepositoryProvider<AnalysisRepository>.value(value: engine),
      // A análise da partida lê a barra de avaliação dos ajustes.
      RepositoryProvider<SettingsRepository>.value(
        value: FakeSettingsRepository(),
      ),
    ],
    child: TestApp(
      locale: const Locale('pt'),
      settingsCubit: settings,
      router: router,
      child: const SizedBox.shrink(),
    ),
  );

  /// Abre [path] por cima da home (o voltar da tela fecha a tela).
  Future<void> open(
    WidgetTester tester,
    String path, {
    bool waitFor = true,
  }) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    addTearDown(settings.close);
    await tester.pumpWidget(app(settings: settings));
    await tester.pump();
    unawaited(router.push(path));
    if (waitFor) await assentar(tester);
  }
}

/// Deixa as animações e os fluxos assíncronos acabarem, sem esperar timers
/// periódicos (a espera da análise tem um).
Future<void> assentar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// O aparelho dos testes de tela: 411x914 dp, densidade 1.
void device411x914(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(411, 914);
  addTearDown(tester.view.reset);
}

/// Uma partida da lista em outro estado.
CoachGame withStatus(CoachGame p, GameStatus status, {String? errorReason}) =>
    CoachGame(
      id: p.id,
      moveAt: p.moveAt,
      color: p.color,
      opponent: p.opponent,
      result: p.result,
      timeControl: p.timeControl,
      cadence: p.cadence,
      rating: p.rating,
      opening: p.opening,
      pgn: p.pgn,
      status: status,
      errorReason: errorReason,
    );
