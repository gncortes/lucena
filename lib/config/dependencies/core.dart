import 'dart:async';

import '../../data/repositories/analytics/analytics_repository.dart';
import '../../data/repositories/settings/settings_repository_local.dart';
import '../../data/services/asset_service.dart';
import '../../data/services/database/app_database.dart';
import '../../data/services/firebase/analytics_service.dart';
import '../../data/services/firebase/auth_service.dart';
import '../../data/services/firebase/cloud_store_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/preferences_service.dart';
import '../../domain/use_cases/analytics_rules.dart';
import '../../domain/use_cases/now.dart';
import '../build_flags.dart';

/// O que quase toda área usa: relógio, conta, gravação no aparelho, nuvem e
/// estatísticas.
class CoreDependencies {
  CoreDependencies._({
    required this.firebase,
    required this.auth,
    required this.preferences,
    required this.settings,
    required this.notifications,
    required this.database,
    required this.cloudStore,
    required this.analytics,
  });

  /// [firebase] diz se o Firebase subiu: sem ele, conta, nuvem e estatísticas
  /// ficam desligadas.
  factory CoreDependencies.create({required bool firebase}) {
    final auth = firebase
        ? FirebaseAuthService(now: const SystemNow())
        : const NoAuthService();
    final preferences = PreferencesService();
    final settings = LocalSettingsRepository(preferences);
    // Um plugin só para os lembretes e o push (o toque tem um dono só).
    final notifications = DeviceNotificationService();
    final database = AppDatabase();
    final analytics = ServiceAnalyticsRepository(
      firebase && analyticsMode != AnalyticsMode.off
          ? FirebaseAnalyticsService()
          : const NoAnalyticsService(),
      preferences,
      mode: analyticsMode,
    );
    // O uid da conta como id do usuário no Analytics (H-R5-65).
    auth.changes
        .map((account) => account?.uid)
        .distinct()
        .listen((uid) => unawaited(analytics.setUserId(uid)));
    return CoreDependencies._(
      firebase: firebase,
      auth: auth,
      preferences: preferences,
      settings: settings,
      notifications: notifications,
      database: database,
      cloudStore: firebase
          ? FirestoreCloudStoreService()
          : const NoCloudStoreService(),
      analytics: analytics,
    );
  }

  final bool firebase;
  final Now now = const SystemNow();
  final AssetService assets = const AssetService();
  final AuthService auth;
  final PreferencesService preferences;
  final LocalSettingsRepository settings;
  final NotificationService notifications;
  final AppDatabase database;
  final CloudStoreService cloudStore;
  final ServiceAnalyticsRepository analytics;

  /// O uid da conta aberta agora, ou nada.
  String? uid() => auth.current?.uid;
}
