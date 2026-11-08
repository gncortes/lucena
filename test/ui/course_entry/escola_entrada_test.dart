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
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/training_entry_keys.dart';
import 'package:lucena/ui/course_entry/widgets/course_entry_gate.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

class _Downloads extends CourseDownloadRepository {
  _Downloads({this.failure, this.loading = false}) : super.unconfigured();
  final Object? failure;
  final bool loading;
  @override
  Future<void> prepare(TrainingCourseConfig config, {String? chapterId}) async {
    if (loading) await Completer<void>().future;
    if (failure case final error?) throw error;
  }
}

/// T85-D3 (Escola): portão de entrada, H-ESC-01 a 03.
void main() {
  Future<({FakeAccountRepository accounts, List<String> pushed})> mount(
    WidgetTester tester,
    _Downloads downloads, {
    bool signedIn = false,
    String? from,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    final accounts = FakeAccountRepository();
    if (signedIn) accounts.account = FakeAccountRepository.google;
    final scheduler = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(scheduler.dispose);
    final pushed = <String>[];
    final router = GoRouter(
      initialLocation: from ?? '/school',
      routes: [
        GoRoute(
          path: '/school',
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
            child: const CourseEntryGate(
              config: TrainingCourseConfig.escola,
              child: SizedBox(),
            ),
          ),
        ),
        GoRoute(
          path: Routes.accountEnter,
          builder: (context, state) {
            pushed.add(state.uri.path);
            return const Scaffold(body: Text('conta'));
          },
        ),
        GoRoute(path: Routes.home, builder: (_, _) => const Text('inicio')),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox(),
      ),
    );
    if (from != null) {
      // A Escola abre por cima da tela anterior (push), como o atalho de
      // quem tem pilha.
      unawaited(router.push('/school'));
    }
    if (downloads.loading) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
    return (accounts: accounts, pushed: pushed);
  }

  testWidgets('sem conta: fala nova, linha salva e botão único', (
    tester,
  ) async {
    await mount(tester, _Downloads());
    expect(find.text('Escola do Viktor'), findsOneWidget);
    expect(
      find.textContaining(
        'Vou acompanhar cada lição e cada teste seu, do primeiro capítulo ao diploma.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(TrainingEntryKeys.saved), findsOneWidget);
    expect(
      find.text('Seu progresso salvo, em qualquer celular'),
      findsOneWidget,
    );
    expect(find.textContaining('funcionam sem internet'), findsNothing);
    expect(find.byKey(TrainingEntryKeys.google), findsNothing);
    expect(find.byKey(TrainingEntryKeys.email), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(TrainingEntryKeys.signIn), findsOneWidget);
    expect(find.text('Entrar ou criar conta'), findsOneWidget);
  });

  testWidgets('o botão abre a Conta', (tester) async {
    final r = await mount(tester, _Downloads());
    await tester.tap(find.byKey(TrainingEntryKeys.signIn));
    await tester.pumpAndSettle();
    expect(r.pushed, [Routes.accountEnter]);
    expect(find.text('conta'), findsOneWidget);
  });

  testWidgets('voltar vai ao Início', (tester) async {
    await mount(tester, _Downloads());
    await tester.tap(find.byKey(TrainingEntryKeys.accountBack));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('T85-B5a: a tela de conta tem a seta e ela volta à anterior', (
    tester,
  ) async {
    final r = await mount(tester, _Downloads(), from: Routes.home);
    expect(find.byKey(TrainingEntryKeys.accountBack), findsOneWidget);
    await tester.tap(find.byKey(TrainingEntryKeys.accountBack));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
    expect(find.byKey(TrainingEntryKeys.account), findsNothing);
    expect(r.pushed, isEmpty);
  });

  testWidgets('baixando: esqueleto com as quatro abas', (tester) async {
    await mount(tester, _Downloads(loading: true), signedIn: true);
    expect(find.byKey(TrainingEntryKeys.loading), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('sem internet: erro padrão com Voltar e texto do curso', (
    tester,
  ) async {
    await mount(
      tester,
      _Downloads(failure: const LessonContentNetworkUnavailable()),
      signedIn: true,
    );
    expect(find.text('Sem internet'), findsOneWidget);
    expect(
      find.text(
        'Você precisa de conexão com a internet para acessar este curso.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
    expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
  });

  testWidgets('erro genérico: erro padrão com Voltar', (tester) async {
    await mount(
      tester,
      _Downloads(failure: const LessonContentUnavailable()),
      signedIn: true,
    );
    expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
    expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
    expect(find.byKey(TrainingEntryKeys.failure), findsNothing);
  });
}
