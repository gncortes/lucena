import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/home_layout_keys.dart';
import 'package:lucena/ui/home_layout/view_models/home_layout_cubit.dart';
import 'package:lucena/ui/home_layout/widgets/home_layout_screen.dart';

import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

/// H-ANI-08 em Configurar o Início: Tentar novamente carrega no botão.
class _Perfil extends FakeProfileRepository {
  bool falha = true;
  Completer<void>? porta;

  @override
  Future<UserProfile> load() async {
    if (falha) throw StateError('banco');
    await porta?.future;
    return super.load();
  }
}

void main() {
  testWidgets('Tentar novamente gira o círculo no botão até a resposta', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final perfil = _Perfil();
    final cubit = HomeLayoutCubit(
      layouts: FakeHomeLayoutRepository(),
      profile: perfil,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: const HomeLayoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(HomeLayoutKeys.error), findsOneWidget);

    perfil
      ..falha = false
      ..porta = Completer<void>();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
    perfil.porta!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(HomeLayoutKeys.error), findsNothing);
  });
}
