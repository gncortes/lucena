// Native UI evidence only. Explicit E2E target; never used by lib/main.dart.
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';

import 'package:lucena/data/services/notification_service.dart';
import 'package:lucena/data/services/system_settings_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/main.dart' show LucenaApp;
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';
import 'package:lucena/domain/use_cases/training/reminder_text.dart';

import '../e2e_dependencies.dart';
import '../fakes/fake_push_repository.dart';
import 'e2e_training.dart';
import 'native_frame_recorder.dart';

class _NativePermissionPush extends FakePushRepository {
  _NativePermissionPush(this.notifications);
  final NotificationService notifications;
  @override
  Future<bool> permitted() => notifications.permitted();
  @override
  Future<bool> requestPermission() => notifications.requestPermission();
  @override
  Future<bool> openSystemSettings() =>
      const SystemSettingsService().openAppNotifications();
}

/// Seeds once per explicit fixture version, then preserves the real local
/// repositories across backgrounding and Android force-stop. Auth and network
/// integrations are test doubles; Stockfish runs on the actual Android device.
Future<void> main() async {
  if (!const bool.fromEnvironment('E2E')) {
    throw StateError('The integral preview requires E2E=true');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final frames = NativeFrameRecorder()..start();
  const scenarioName = String.fromEnvironment(
    'T85_SCENARIO',
    defaultValue: 'goalsMiddle',
  );
  const fixture = 't85-integral-native-v1-$scenarioName';
  final preferences = PreferencesService();
  final seeded = await preferences.getBool(fixture) ?? false;
  e2eNow.value = DateTime(2026, 10, 26, 12);
  e2eAnalysis.useStockfish = true;
  final notifications = DeviceNotificationService();
  final dependencies = await e2eDependencies(
    localContentPackages: true,
    now: const SystemNow(),
    notifications: notifications,
    push: _NativePermissionPush(notifications),
    trainingScenario: seeded
        ? null
        : E2ETrainingScenario.values.byName(scenarioName),
  );
  if (!seeded) {
    final settings = await dependencies.settingsRepository.load();
    await dependencies.settingsRepository.save(
      settings.copyWith(languageCode: 'pt', themeMode: AppThemeMode.light),
    );
    await dependencies.onboardingRepository.save(
      const Onboarding(done: true, boardControlsDone: true),
    );
    await preferences.setBool(fixture, value: true);
  }
  // Android rejects reminder dates older than its real wall clock. Keep the
  // authored seed deterministic, then use Now for real device integrations.
  e2eNow.value = const SystemNow()();
  runApp(LucenaApp(dependencies: dependencies));
  // Dedicated debug command file; no other app files or preferences are read.
  // The host requests only one of four Canvas notification fixtures. Permission
  // still comes from the real Android dialog in the normal plan flow.
  final command = File(
    '${Directory.systemTemp.path}/t85-native-notification.txt',
  );
  var previous = '';
  var busy = false;
  Timer.periodic(const Duration(seconds: 1), (_) async {
    if (busy) return;
    busy = true;
    try {
      if (!await command.exists()) return;
      final state = (await command.readAsString()).trim();
      if (state.startsWith('segment:')) {
        if (state != previous) frames.segment(state.substring(8));
        previous = state;
        return;
      }
      if (state == previous ||
          !const {
            'Notificacao',
            'NotificacaoAulaFeita',
            'EscolaNotificacao',
            'EscolaNotificacaoAulaFeita',
          }.contains(state)) {
        return;
      }
      previous = state;
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
      final copy = L10nReminderTexts(l10n);
      final school = state.startsWith('Escola');
      final done = state.endsWith('AulaFeita');
      final request = TrainingReminderText(
        done ? 'trainingNotifGoals' : 'trainingNotifLesson',
        {'n': school ? 5 : 4},
      );
      await notifications.show(
        ShownNotification(
          id: 85049,
          channel: copy.trainingChannel,
          title: copy.trainingTitle,
          body: copy.trainingBody(
            request,
            school ? 'O peão e a promoção' : 'Cravada',
          ),
          payload: Routes.home,
        ),
      );
    } finally {
      busy = false;
    }
  });
}
