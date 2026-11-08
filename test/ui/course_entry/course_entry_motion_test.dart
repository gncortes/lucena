import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/data/repositories/training/course_download_repository.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/training_entry_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_navigation_bar.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:lucena/ui/course_entry/widgets/course_entry_gate.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

/// Cada chamada de [prepare] espera o seu Completer, na ordem.
class _Downloads extends CourseDownloadRepository {
  _Downloads() : super.unconfigured();
  final calls = <Completer<void>>[];
  @override
  Future<void> prepare(TrainingCourseConfig config, {String? chapterId}) {
    final c = Completer<void>();
    calls.add(c);
    return c.future;
  }
}

const _content = Key('test.courseContent');

/// T85-D1, H-ANI-07 e H-ANI-08 na entrada do curso (CursoBaixando,
/// CapituloBaixando, CapituloSemEspaco).
void main() {
  Future<_Downloads> mount(
    WidgetTester tester, {
    String? chapterId,
    bool chrome = false,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    final downloads = _Downloads();
    final accounts = FakeAccountRepository()
      ..account = FakeAccountRepository.google;
    final scheduler = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(scheduler.dispose);
    final router = GoRouter(
      initialLocation: '/course',
      routes: [
        GoRoute(
          path: '/course',
          builder: (context, state) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<CharacterRepository>(
                create: (_) => FakeCharacterRepository(),
              ),
              RepositoryProvider<SyncScheduler>.value(value: scheduler),
              RepositoryProvider<CourseDownloadRepository>.value(
                value: downloads,
              ),
            ],
            child: CourseEntryGate(
              config: TrainingCourseConfig.pilares,
              chapterId: chapterId,
              child: chrome
                  ? Scaffold(
                      appBar: LucenaAppBar(
                        centerTitle: false,
                        titleSpacing: 0,
                        leading: const BackButton(),
                        title: const Text('Pilares do Xadrez'),
                      ),
                      body: const Text('curso', key: _content),
                      bottomNavigationBar: const CourseNavigationBar(),
                    )
                  : const Scaffold(body: Text('curso', key: _content)),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return downloads;
  }

  testWidgets('o título do curso fica à esquerda já no esqueleto, como na '
      'tela do curso (não pula do centro)', (tester) async {
    await mount(tester);
    final titulo = find.descendant(
      of: find.byKey(TrainingEntryKeys.skeletonAppBar),
      matching: find.text('Pilares do Xadrez'),
    );
    expect(tester.getTopLeft(titulo).dx, lessThan(64));
  });

  testWidgets('H-ANI-07: o esqueleto brilha até o pacote ficar pronto e a '
      'tela do curso entra seca', (tester) async {
    final downloads = await mount(tester);
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
    expect(find.byKey(_content), findsNothing);
    downloads.calls.single.complete();
    await tester.pump();
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    expect(find.byKey(_content), findsOneWidget);
  });

  testWidgets('a app bar e a barra de baixo não se mexem nem piscam na troca '
      'do esqueleto para o conteúdo', (tester) async {
    final downloads = await mount(tester, chrome: true);
    final barra = find.byType(AppBar);
    final abas = find.byType(NavigationBar);
    expect(barra, findsOneWidget);
    expect(abas, findsOneWidget);
    final barraAntes = tester.getRect(barra);
    final abasAntes = tester.getRect(abas);
    downloads.calls.single.complete();
    // Cada quadro da troca e da entrada do corpo: sempre uma só barra de cada,
    // no mesmo lugar (sem subir, sem sobrepor duas cópias).
    for (var ms = 0; ms <= 600; ms += 16) {
      await tester.pump(Duration(milliseconds: ms == 0 ? 0 : 16));
      expect(barra, findsOneWidget, reason: 'app bar duplicada em $ms ms');
      expect(abas, findsOneWidget, reason: 'barra de baixo duplicada');
      expect(tester.getRect(barra), barraAntes, reason: 'app bar em $ms ms');
      expect(tester.getRect(abas), abasAntes, reason: 'abas em $ms ms');
    }
    expect(find.byKey(_content), findsOneWidget);
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
  });

  testWidgets('H-ANI-08: sem espaço, "Tentar novamente" gira até a nova '
      'tentativa terminar', (tester) async {
    final downloads = await mount(tester, chapterId: 'c1');
    downloads.calls.single.completeError(
      const LessonContentStorageUnavailable(2 * 1024 * 1024),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
    await tester.tap(find.byKey(LoadErrorKeys.action));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
    downloads.calls.last.completeError(
      const LessonContentStorageUnavailable(2 * 1024 * 1024),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(CoreKeys.busySpinner), findsNothing);
  });
}
