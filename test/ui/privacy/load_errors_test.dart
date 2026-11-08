import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_device_settings_repository.dart';
import '../../../testing/test_app.dart';

class _Accounts extends FakeAccountRepository {
  bool failing = true;
  int reads = 0;
  final changesController = StreamController<Account?>.broadcast();

  @override
  Account? get current {
    reads++;
    if (failing) throw StateError('privacy');
    return null;
  }

  @override
  Stream<Account?> get changes => changesController.stream;
}

/// Gap 3 da Privacidade e dados: a leitura da conta falha e a tela mostra
/// o erro padrão (antes "Excluir" sumia sem aviso).
void main() {
  for (final fromChanges in [false, true]) {
    testWidgets(
      'Gap 3: a leitura ${fromChanges ? 'da mudança de conta' : 'inicial'} '
      'falha, mostra o erro e "Tentar de novo" volta à tela',
      (tester) async {
        final accounts = _Accounts()..failing = !fromChanges;
        final cubit = PrivacyCubit(
          accounts: accounts,
          device: FakeDeviceSettingsRepository(),
        );
        addTearDown(cubit.close);
        addTearDown(accounts.changesController.close);
        await cubit.load();
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(
              value: cubit,
              child: const PrivacyScreen(),
            ),
          ),
        );
        await tester.pump();
        if (fromChanges) {
          accounts.changesController.addError(StateError('stream'));
          await tester.pump();
          await tester.pump();
        }
        expect(
          tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
          LoadErrorKind.generic,
        );
        expect(find.byKey(LoadErrorKeys.back), findsOneWidget);

        accounts.failing = false;
        await tester.tap(find.byKey(LoadErrorKeys.action));
        await tester.pump();
        expect(find.byType(LoadErrorScreen), findsNothing);
        expect(find.byKey(PrivacyKeys.screen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
