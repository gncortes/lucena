import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/firebase/auth_service.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/account/widgets/account_flow.dart';

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));

  test(
    'abuso: conta desativada pelo admin vira "suspensa", não erro genérico',
    () {
      final failure = FirebaseAuthService.failureOf('user-disabled');
      expect(failure, AccountFailure.disabled);
      expect(
        accountFailureText(pt, failure),
        'Esta conta foi suspensa. Seu progresso neste aparelho continua salvo.',
      );
    },
  );

  test('os outros códigos seguem como antes', () {
    expect(
      FirebaseAuthService.failureOf('too-many-requests'),
      AccountFailure.tooManyAttempts,
    );
    expect(FirebaseAuthService.failureOf('qualquer'), AccountFailure.unknown);
  });
}
