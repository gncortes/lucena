import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/settings/widgets/about_screen.dart';
import 'package:lucena/ui/settings/widgets/settings_screen.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';
import '../../core/motion/entrada_helpers.dart';

/// H-ANI-16, 17 e 20 nas telas de Ajustes.
void main() {
  Future<void> abrir(WidgetTester tester, Widget screen) async {
    final cubit = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(cubit.close);
    await cubit.load();
    final profile = ProfileCubit(FakeProfileRepository());
    addTearDown(profile.close);
    await profile.load();
    await tester.pumpWidget(
      RepositoryProvider<AccountRepository>.value(
        value: FakeAccountRepository(),
        child: TestApp(
          settingsCubit: cubit,
          profileCubit: profile,
          child: screen,
        ),
      ),
    );
  }

  testWidgets('H-ANI-16: Sobre entra em cascata e termina pronto', (
    tester,
  ) async {
    await abrir(tester, const AboutScreen(version: '1.0.0'));
    final primeiro = find.byKey(MotionKeys.itemDaCascata(0));
    final ultimo = find.byKey(MotionKeys.itemDaCascata(3));
    expect(opacidade(tester, ultimo), lessThan(1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacidade(tester, primeiro), greaterThan(opacidade(tester, ultimo)));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(opacidade(tester, ultimo), 1);
    expect(subida(tester, ultimo), 0);
  });

  testWidgets('H-ANI-17: Configurações entra em ordem, de cima para baixo', (
    tester,
  ) async {
    await abrir(tester, const SettingsScreen());
    final a = find.byKey(MotionKeys.itemDaLista(0));
    final b = find.byKey(MotionKeys.itemDaLista(1));
    expect(a, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
    expect(opacidade(tester, a), greaterThanOrEqualTo(opacidade(tester, b)));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(opacidade(tester, b), 1);
  });

  testWidgets('H-ANI-20: o cartão da pessoa afunda a 0,97 no toque', (
    tester,
  ) async {
    await abrir(tester, const SettingsScreen());
    await tester.pump(const Duration(milliseconds: 1500));
    final dedo = await tester.startGesture(
      tester.getCenter(find.byKey(SettingsKeys.profileTile)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final t = find.descendant(
      of: find.byKey(MotionKeys.cartaoPressionado),
      matching: find.byType(Transform),
    );
    expect(
      tester.widget<Transform>(t.first).transform.storage[0],
      closeTo(0.97, .01),
    );
    await dedo.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      tester.widget<Transform>(t.first).transform.storage[0],
      closeTo(1, .01),
    );
  });
}
