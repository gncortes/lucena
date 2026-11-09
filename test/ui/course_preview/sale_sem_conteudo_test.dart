import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_preview_repository.dart';
import '../../../testing/test_app.dart';

/// Sem o JSON da venda (o app de E2E/dev sem pacote de conteúdo), o
/// repositório devolve nulo: a venda aberta pela cota do Treinador não pode
/// ficar em branco, sem saída.
void main() {
  testWidgets('venda sem conteúdo: erro com voltar, nunca tela em branco', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('partida')),
        ),
        ...d2Routes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CoursePreviewRepository>.value(
            value: FakeCoursePreviewRepository(),
          ),
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<AccountRepository>.value(
            value: FakeAccountRepository(),
          ),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          router: router,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(Routes.pilaresSale));
    await tester.pumpAndSettle();

    expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
    await tester.tap(find.byKey(LoadErrorKeys.back));
    await tester.pumpAndSettle();
    expect(find.text('partida'), findsOneWidget);
  });
}
