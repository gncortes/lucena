import 'package:package_info_plus/package_info_plus.dart';

import '../../data/repositories/config/remote_flags_repository.dart';
import '../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../data/repositories/push/push_repository.dart';
import '../../data/repositories/reminders/reminders_repository.dart';
import '../../data/repositories/update/app_update_repository.dart';
import '../../data/services/app_update_service.dart';
import '../../data/services/firebase/push_service.dart';
import '../../data/services/firebase/remote_config_service.dart';
import '../build_flags.dart';
import '../push_alerts.dart';
import 'core.dart';

/// Os avisos do aparelho (push e lembretes), as chaves do Remote Config e a
/// versão nova na Play.
class NotificationDependencies {
  NotificationDependencies._({
    required this.push,
    required this.reminders,
    required this.flags,
    required this.appUpdate,
  });

  /// [push] troca só o toque no aviso (os cenários no emulador do Firebase
  /// simulam o FCM).
  factory NotificationDependencies.create(
    CoreDependencies core, {
    required PushService pushes,
    required EndgameProgressRepository endgames,
    required EndgameLessonRepository endgameLessons,
    PushRepository? push,
  }) {
    final firebase = core.firebase;
    final preferences = core.preferences;
    return NotificationDependencies._(
      push:
          push ??
          FirebasePushRepository(
            pushes,
            preferences,
            notifications: core.notifications,
            texts: () => loadPushTexts(core.settings),
          ),
      reminders: LocalRemindersRepository(
        core.notifications,
        progress: endgames,
        lessons: endgameLessons,
      ),
      flags: RemoteConfigFlagsRepository(
        firebase ? FirebaseRemoteConfigService() : NoRemoteConfigService(),
        // Nas versões de teste, o valor novo do console vale na hora.
        minimumFetchInterval: showsDevTools
            ? Duration.zero
            : const Duration(hours: 12),
      ),
      appUpdate: PlayAppUpdateRepository(
        firebase ? const PlayAppUpdateService() : const NoAppUpdateService(),
        preferences,
        build: () async =>
            int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0,
      ),
    );
  }

  final PushRepository push;
  final LocalRemindersRepository reminders;
  final RemoteConfigFlagsRepository flags;
  final PlayAppUpdateRepository appUpdate;
}
