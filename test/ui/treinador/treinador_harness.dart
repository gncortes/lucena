import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucena/data/repositories/analysis/analysis_repository.dart';
import 'package:lucena/data/repositories/analysis/learning_analysis_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/lesson_ad/course_grants_repository.dart';
import 'package:lucena/data/repositories/treinador/curiosidades_repository.dart';
import 'package:lucena/data/repositories/treinador/treinador_preferencias.dart';
import 'package:lucena/data/repositories/treinador/treinador_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/treinador/curiosidade.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/frentes/treinador_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_grants.dart';
import '../../../testing/fakes/fake_curiosidades_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/test_app.dart';
import '../learning_analysis/analysis_test_support.dart';

/// Um [PreferencesService] em memória (as preferências do Treinador).
class MemoriaPreferencias extends PreferencesService {
  MemoriaPreferencias() : super(_plataforma());

  static SharedPreferencesAsync _plataforma() {
    initializeAnalysisPreferences();
    return SharedPreferencesAsync();
  }

  final valores = <String, String>{};

  @override
  Future<String?> getString(String key) async => valores[key];

  @override
  Future<void> setString(String key, String value) async =>
      valores[key] = value;

  @override
  Future<void> remove(String key) async => valores.remove(key);
}

/// O direito `treinador` ativo (o plano de análise).
CourseGrants comPlano() => const CourseGrants(
  courses: {'treinador': CourseGrant(origin: GrantOrigin.purchase)},
);

/// O "agora" fixo dos testes (nunca `DateTime.now()`).
DateTime agoraDeTeste() => DateTime.utc(2026, 11, 9, 12);

/// Tudo de que as telas e os view models do Treinador dependem, em memória.
class TreinadorBed {
  TreinadorBed({
    FakeTreinadorRepository? repo,
    CourseGrants grants = CourseGrants.empty,
    DateTime? agora,
    this.curiosidades,
    MemoriaPreferencias? prefs,
  }) : memoria = prefs ?? MemoriaPreferencias(),
       repo = repo ?? FakeTreinadorRepository.comDados(),
       grants = FakeCourseGrantsRepository(grants),
       now = FakeNow(agora ?? agoraDeTeste()) {
    preferencias = TreinadorPreferencias(memoria);
  }

  final FakeTreinadorRepository repo;
  final FakeCourseGrantsRepository grants;
  final FakeNow now;
  final MemoriaPreferencias memoria;
  late final TreinadorPreferencias preferencias;
  final List<Curiosidade>? curiosidades;
  final motor = ControlledAnalysisEngine();
  final characters = FakeCharacterRepository();
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
      ...treinadorRoutes,
    ],
  );

  /// O caminho em que o roteador está agora.
  ///
  /// Uma tela empilhada com `push` não muda a base do roteador: o caminho
  /// dela vem da última rota imperativa.
  String get caminho {
    final configuracao = router.routerDelegate.currentConfiguration;
    final topo = configuracao.last;
    return (topo is ImperativeRouteMatch ? topo.matches : configuracao).uri
        .toString();
  }

  /// O app de teste, em PT-BR, com tudo o que as rotas do Treinador leem.
  Widget app({SettingsCubit? settings}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<TreinadorRepository>.value(value: repo),
      RepositoryProvider<CourseGrantsRepository>.value(value: grants),
      RepositoryProvider<TreinadorPreferencias>.value(value: preferencias),
      RepositoryProvider<Now>.value(value: now),
      RepositoryProvider<CuriosidadesRepository>.value(
        value: FakeCuriosidadesRepository(curiosidades),
      ),
      RepositoryProvider<CharacterRepository>.value(value: characters),
      RepositoryProvider<AnalysisRepository>.value(value: motor),
      RepositoryProvider<LearningAnalysisRepository>.value(
        value: LearningAnalysisRepository(AnalysisMemoryPreferences()),
      ),
    ],
    child: TestApp(
      locale: const Locale('pt'),
      settingsCubit: settings,
      router: router,
      child: const SizedBox.shrink(),
    ),
  );

  /// Abre [caminho] por cima da home (o voltar da tela fecha a tela).
  Future<void> abrir(
    WidgetTester tester,
    String caminho, {
    bool esperar = true,
  }) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    addTearDown(settings.close);
    await tester.pumpWidget(app(settings: settings));
    await tester.pump();
    unawaited(router.push(caminho));
    if (esperar) await assentar(tester);
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
void aparelho411x914(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(411, 914);
  addTearDown(tester.view.reset);
}

/// Uma partida da lista em outro estado.
PartidaTreinador comStatus(
  PartidaTreinador p,
  StatusPartida status, {
  String? erroMotivo,
}) => PartidaTreinador(
  id: p.id,
  jogadaEm: p.jogadaEm,
  cor: p.cor,
  adversario: p.adversario,
  resultado: p.resultado,
  ritmo: p.ritmo,
  cadencia: p.cadencia,
  rating: p.rating,
  abertura: p.abertura,
  pgn: p.pgn,
  status: status,
  erroMotivo: erroMotivo,
);
