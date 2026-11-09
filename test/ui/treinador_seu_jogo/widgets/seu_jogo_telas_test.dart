import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/data/repositories/treinador/seu_jogo_filtro_repository.dart';
import 'package:lucena/data/repositories/treinador/treinador_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/ui/core/keys/treinador_seu_jogo_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/treinador_seu_jogo/widgets/metas_destaque_treinador.dart';
import 'package:lucena/ui/treinador_seu_jogo/widgets/partidas_modelo_screen.dart';
import 'package:lucena/ui/treinador_seu_jogo/widgets/pilares_abertura_screen.dart';
import 'package:lucena/ui/treinador_seu_jogo/widgets/seu_jogo_aba.dart';
import 'package:lucena/ui/treinador_seu_jogo/widgets/tema_screen.dart';
import 'package:lucena/ui/treinador_seu_jogo/widgets/teoria_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';
import '../../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_treinador_repository.dart';
import '../../../../testing/test_app.dart';
import '../../../../testing/treinador_fixtures.dart';
import '../../../../testing/treinador_seu_jogo_fixtures.dart';

final _resources = TrainingResources(
  lessons: [
    for (final id in ['pilares.ab1.caroKann1', 'pilares.ab2.caroKann2'])
      TrainingLesson(id: id, kind: TrainingLessonKind.opening, title: id),
  ],
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  /// Aparelho padrão (1080x2400 a 420 dpi) e as dependências da frente.
  Future<void> abrir(
    WidgetTester tester,
    Widget tela, {
    TreinadorRepository? repo,
    CourseAccess acesso = CourseAccess.demo,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 420 / 160;
    addTearDown(tester.view.reset);
    final training = FakeTrainingRepository(
      content: {TrainingCourse.pilares: _resources},
    );
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    await settings.load();
    addTearDown(settings.close);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TreinadorRepository>.value(
            value:
                repo ??
                FakeTreinadorRepository(
                  conta: TreinadorFixtures.conta,
                  partidas: SeuJogoFixtures.partidas(),
                  estatisticas: SeuJogoFixtures.estatisticas(),
                ),
          ),
          RepositoryProvider<SeuJogoFiltroRepository>.value(
            value: SeuJogoFiltroRepository(PreferencesService()),
          ),
          RepositoryProvider<Now>.value(value: FakeNow(SeuJogoFixtures.agora)),
          RepositoryProvider<TrainingRepository>.value(value: training),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          courseAccessRepository: FakeCourseAccessRepository(acesso),
          child: tela,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('aba Seu jogo', () {
    testWidgets('60 partidas: números, foco na abertura e temas', (
      tester,
    ) async {
      await abrir(tester, const SeuJogoScreen());
      expect(find.byKey(SeuJogoKeys.base), findsOneWidget);
      expect(find.byKey(SeuJogoKeys.numeros), findsOneWidget);
      expect(find.byKey(SeuJogoKeys.foco), findsOneWidget);
      expect(find.byKey(SeuJogoKeys.poucasAviso), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(SeuJogoKeys.temas),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(SeuJogoKeys.tema('garfo')), findsOneWidget);
    });

    testWidgets('poucas partidas: o aviso no lugar dos números', (
      tester,
    ) async {
      await abrir(
        tester,
        const SeuJogoScreen(),
        repo: FakeTreinadorRepository(
          conta: TreinadorFixtures.conta,
          partidas: SeuJogoFixtures.partidas(5),
          estatisticas: SeuJogoFixtures.estatisticas(nivel: 'primeira'),
        ),
      );
      expect(find.byKey(SeuJogoKeys.poucas), findsOneWidget);
      expect(find.byKey(SeuJogoKeys.numeros), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(SeuJogoKeys.poucasAviso),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    });

    testWidgets('sem partida: o estado vazio', (tester) async {
      await abrir(
        tester,
        const SeuJogoScreen(),
        repo: FakeTreinadorRepository(conta: TreinadorFixtures.conta),
      );
      expect(find.byKey(SeuJogoKeys.vazio), findsOneWidget);
    });
  });

  testWidgets('teoria: candidatos e a linha ao tocar', (tester) async {
    final partida = SeuJogoFixtures.partidas(2)[1];
    await abrir(
      tester,
      SeuJogoTeoriaScreen(partidaId: partida.id),
      repo: FakeTreinadorRepository(partidas: [partida]),
    );
    expect(find.byKey(SeuJogoKeys.teoriaScreen), findsOneWidget);
    expect(find.byKey(SeuJogoKeys.teoriaLinha), findsNothing);
    await tester.tap(find.byKey(SeuJogoKeys.teoriaCandidato('Bf5')));
    await tester.pumpAndSettle();
    expect(find.byKey(SeuJogoKeys.teoriaLinha), findsOneWidget);
  });

  testWidgets('partidas-modelo: lista e o aviso grava', (tester) async {
    final repo = FakeTreinadorRepository(
      conta: TreinadorFixtures.conta,
      modelosPorEco: {
        'B12': [
          const PartidaModelo(fonte: 'torneio', titulo: 'Carlsen x Caruana'),
        ],
      },
    );
    await abrir(
      tester,
      const PartidasModeloScreen(eco: 'B12', nome: 'Defesa Caro-Kann'),
      repo: repo,
    );
    expect(find.byKey(SeuJogoKeys.modelo(0)), findsOneWidget);
    expect(find.text('Carlsen x Caruana'), findsOneWidget);
    await tester.tap(find.byKey(SeuJogoKeys.modelosAviso));
    await tester.pumpAndSettle();
    expect(repo.avisosModelos, [true]);
  });

  group('Pilares da abertura', () {
    testWidgets('sem o curso: partes travadas, destaque e oferta', (
      tester,
    ) async {
      await abrir(
        tester,
        const PilaresAberturaScreen(slot: 'caroKann', parte: 2, lance: 'c5'),
      );
      expect(
        find.byKey(SeuJogoKeys.pilaresParte('pilares.ab1.caroKann1')),
        findsOneWidget,
      );
      expect(find.byKey(SeuJogoKeys.pilaresDestaque), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(SeuJogoKeys.pilaresConhecer),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(SeuJogoKeys.pilaresOferta), findsOneWidget);
    });
  });

  testWidgets('Metas de hoje: a parte do Treinador em destaque', (
    tester,
  ) async {
    final repository = FakeTrainingRepository(
      content: {TrainingCourse.pilares: _resources},
    );
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: FakeNow(SeuJogoFixtures.agora),
    );
    addTearDown(cubit.close);
    await cubit.load();
    TrainingLesson? aberta;
    await abrir(
      tester,
      BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: MetasDestaqueTreinador(
            lessonId: 'pilares.ab2.caroKann2',
            onOpen: (l) => aberta = l,
          ),
        ),
      ),
      acesso: CourseAccess.owned,
    );
    expect(find.byKey(SeuJogoKeys.metasDestaque), findsOneWidget);
    await tester.tap(find.byKey(SeuJogoKeys.metasDestaqueParte));
    expect(aberta?.id, 'pilares.ab2.caroKann2');
  });

  group('texto longo, 411×914', () {
    // Dados reais no limite: usuário do Lichess com 30 letras, abertura com
    // variante e subvariante, partida-modelo com evento e cidade.
    const abertura =
        'Defesa Siciliana, Variante Najdorf, Ataque Inglês, Linha Principal';
    const rival = 'Grande_Mestre_Do_Final_De_Torre';
    const modelo =
        'Magnus Carlsen x Fabiano Caruana, Campeonato Mundial, Londres 2018';

    List<PartidaTreinador> partidas() => [
      for (var i = 0; i < 60; i++)
        PartidaTreinador.fromJson(SeuJogoFixtures.id(i), {
          ...SeuJogoFixtures.partidaJson(i),
          'adversario': {'nome': rival, 'rating': 2950},
          if (i.isOdd) 'abertura': {'eco': 'B90', 'nome': abertura},
        })!,
    ];

    EstatisticasTreinador estatisticas() {
      final json = SeuJogoFixtures.estatisticasJson();
      final ab = (json['aberturas']! as List).first as Map<String, Object?>;
      return EstatisticasTreinador.fromJson({
        ...json,
        'aberturas': [
          {...ab, 'nome': abertura, 'eco': 'B90', 'partidas': 1234},
        ],
      });
    }

    FakeTreinadorRepository repo() => FakeTreinadorRepository(
      conta: TreinadorFixtures.conta,
      partidas: partidas(),
      estatisticas: estatisticas(),
      modelosPorEco: {
        'B90': [
          for (var i = 0; i < 3; i++)
            const PartidaModelo(fonte: 'torneio', titulo: modelo),
        ],
      },
    );

    /// Nenhum texto com reticências ou cortado, nem estouro de layout.
    void semCorte(WidgetTester tester) {
      expect(tester.takeException(), isNull);
      for (final e in find.byType(RichText).evaluate()) {
        final p = e.renderObject! as RenderParagraph;
        expect(
          p.didExceedMaxLines,
          isFalse,
          reason: 'texto cortado: "${p.text.toPlainText()}"',
        );
      }
    }

    /// Rola a tela inteira conferindo a cada tela.
    Future<void> rolarConferindo(WidgetTester tester) async {
      semCorte(tester);
      final rolavel = find.byType(Scrollable).first;
      for (var i = 0; i < 30; i++) {
        final pos = tester.state<ScrollableState>(rolavel).position;
        if (pos.pixels >= pos.maxScrollExtent) break;
        await tester.drag(rolavel, const Offset(0, -500));
        await tester.pumpAndSettle();
        semCorte(tester);
      }
    }

    testWidgets('aba Seu jogo', (tester) async {
      await abrir(tester, const SeuJogoScreen(), repo: repo());
      await rolarConferindo(tester);
      expect(find.textContaining(abertura), findsWidgets);
    });

    testWidgets('teoria', (tester) async {
      final p = partidas()[1];
      await abrir(
        tester,
        SeuJogoTeoriaScreen(partidaId: p.id),
        repo: FakeTreinadorRepository(partidas: [p]),
      );
      await tester.tap(find.byKey(SeuJogoKeys.teoriaCandidato('Bf5')));
      await tester.pumpAndSettle();
      await rolarConferindo(tester);
    });

    testWidgets('partidas-modelo', (tester) async {
      await abrir(
        tester,
        const PartidasModeloScreen(eco: 'B90', nome: abertura),
        repo: repo(),
      );
      await rolarConferindo(tester);
      expect(find.text(modelo), findsWidgets);
    });

    testWidgets('posições de um tema, com o adversário', (tester) async {
      await abrir(tester, const SeuJogoTemaScreen(tema: 'garfo'), repo: repo());
      await rolarConferindo(tester);
      expect(find.textContaining(rival), findsWidgets);
    });
  });
}
