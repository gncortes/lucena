import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/analytics/widgets/analytics_opt_in_tile.dart';
import 'package:lucena/ui/analytics/widgets/version_footer.dart';
import 'package:lucena/ui/core/keys/analytics_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeAnalyticsRepository analytics;

  setUp(() => analytics = FakeAnalyticsRepository());

  Future<void> pump(WidgetTester tester, Widget child) async {
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        analytics: analytics,
        child: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVersion(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(find.byKey(SettingsKeys.version));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  group('VersionFooter', () {
    testWidgets('6 toques não abrem o Modo equipe', (tester) async {
      await pump(tester, const VersionFooter(version: '1.2.3'));
      await tapVersion(tester, 6);

      expect(find.byKey(AnalyticsKeys.teamSheet), findsNothing);
      expect(analytics.team, isFalse);
      expect(find.text('Version 1.2.3'), findsOne);
    });

    testWidgets('7 toques abrem o Modo equipe ligado', (tester) async {
      await pump(tester, const VersionFooter(version: '1.2.3'));
      await tapVersion(tester, 7);

      expect(find.byKey(AnalyticsKeys.teamSheet), findsOne);
      expect(find.text('Team mode'), findsOne);
      expect(analytics.team, isTrue);
      expect(find.text('Version 1.2.3 · team mode'), findsOne);
    });

    testWidgets('a chave da folha desliga o Modo equipe', (tester) async {
      analytics.team = true;
      await pump(tester, const VersionFooter(version: '1.2.3'));
      expect(find.text('Version 1.2.3 · team mode'), findsOne);
      await tapVersion(tester, 7);

      await tester.tap(find.byKey(AnalyticsKeys.teamSwitch));
      await tester.pumpAndSettle();

      expect(analytics.team, isFalse);
    });
  });

  group('AnalyticsOptInTile', () {
    testWidgets('começa ligada e desligar grava', (tester) async {
      await pump(tester, const AnalyticsOptInTile());
      final tile = find.byKey(AnalyticsKeys.optInSwitch);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
      expect(find.text('Help improve Lucena'), findsOne);

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      expect(analytics.optIn, isFalse);
    });
  });
}
