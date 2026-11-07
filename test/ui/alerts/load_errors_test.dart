import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';
import 'package:lucena/ui/alerts/widgets/alerts_screen.dart';
import 'package:lucena/ui/core/keys/alerts_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';
import '../../../testing/test_app.dart';

class _Alerts extends FakeAlertsRepository {
  bool failing = false;
  @override
  Future<AlertSettings> load() async {
    if (failing) throw StateError('alerts');
    return super.load();
  }
}

class _Push extends FakePushRepository {
  bool followFailing = false;
  bool permissionFailing = false;
  Completer<bool>? pending;
  @override
  Future<void> follow(Set<String> topics) async {
    if (followFailing) throw StateError('follow');
    await super.follow(topics);
  }

  @override
  Future<bool> permitted() async {
    if (permissionFailing) throw StateError('permission');
    if (pending case final request?) return request.future;
    return super.permitted();
  }
}

void main() {
  for (final area in ['repository', 'follow', 'refresh']) {
    testWidgets('alerts $area failure and retry', (tester) async {
      final repo = _Alerts()..failing = area == 'repository';
      final push = _Push()..followFailing = area == 'follow';
      final cubit = AlertsCubit(
        alerts: repo,
        push: push,
        profile: FakeProfileRepository(),
      );
      addTearDown(cubit.close);
      await cubit.load();
      if (area == 'refresh') push.permissionFailing = true;
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          alertsCubit: cubit,
          child: const AlertsScreen(),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
        LoadErrorKind.generic,
      );
      expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
      repo.failing = false;
      push.followFailing = false;
      push.permissionFailing = false;
      final pending = push.pending = Completer<bool>();
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(LoadErrorKeys.action)).onPressed,
        isNull,
      );
      pending.complete(true);
      await tester.pump();
      expect(find.byKey(AlertsKeys.screen), findsOneWidget);
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
