import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/ads/ads_repository.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';
import 'package:lucena/ui/privacy/widgets/privacy_screen.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';
import '../../../testing/test_app.dart';

class _Ads extends NoAdsRepository {
  bool failing = true;
  int reads = 0;
  Completer<bool>? pending;
  @override
  Future<bool> privacyOptionsRequired() async {
    reads++;
    if (failing) throw StateError('privacy');
    if (pending case final request?) return request.future;
    return false;
  }
}

class _Purchases extends FakePurchaseRepository {
  int subscriptions = 0;
  @override
  Stream<PurchaseState> get changes {
    subscriptions++;
    return super.changes;
  }
}

void main() {
  for (final fromChanges in [false, true]) {
    testWidgets('privacy ${fromChanges ? 'purchase refresh' : 'load'} retry', (
      tester,
    ) async {
      final ads = _Ads()..failing = !fromChanges;
      final purchases = _Purchases();
      final cubit = PrivacyCubit(
        ads: ads,
        purchases: purchases,
        accounts: FakeAccountRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          adsRepository: ads,
          child: BlocProvider.value(value: cubit, child: const PrivacyScreen()),
        ),
      );
      await tester.pump();
      if (fromChanges) {
        ads.failing = true;
        purchases.state = const PurchaseState(adFree: false);
        await tester.pump();
        await tester.pump();
      }
      expect(
        tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
        LoadErrorKind.generic,
      );
      expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      ads.failing = false;
      final pending = ads.pending = Completer<bool>();
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(LoadErrorKeys.action)).onPressed,
        isNull,
      );
      pending.complete(false);
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(find.byKey(PrivacyKeys.screen), findsOneWidget);
      expect(purchases.subscriptions, 1);
      final reads = ads.reads;
      purchases.state = const PurchaseState(adFree: false);
      await tester.pump();
      expect(ads.reads, reads + 1);
      expect(tester.takeException(), isNull);
    });
  }
}
