import 'package:path_provider/path_provider.dart';

import '../../data/repositories/account/account_invite_repository.dart';
import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/account/avatar_repository.dart';
import '../../data/repositories/chesscom/chesscom_repository_remote.dart';
import '../../data/repositories/data_export/data_export_repository.dart';
import '../../data/repositories/data_export/data_export_repository_cloud.dart';
import '../../data/repositories/feedback/feedback_repository.dart';
import '../../data/repositories/legal/legal_consent_repository.dart';
import '../../data/repositories/lichess/lichess_repository_remote.dart';
import '../../data/repositories/review/review_repository.dart';
import '../../data/services/app_links_deep_link_service.dart';
import '../../data/services/chesscom_service.dart';
import '../../data/services/device_service.dart';
import '../../data/services/firebase/file_store_service.dart';
import '../../data/services/firebase/push_service.dart';
import '../../data/services/lichess_service.dart';
import '../../data/services/review_service.dart';
import '../../data/services/secure_storage_service.dart';
import '../../domain/models/app_version.dart';
import 'core.dart';

/// A conta, as contas ligadas (Lichess, Chess.com) e o que vai à nuvem por
/// ela: feedback, cópia dos dados, aceite dos Termos e avaliação na Play.
class AccountDependencies {
  AccountDependencies._({
    required this.pushes,
    required this.avatars,
    required this.account,
    required this.lichess,
    required this.chessCom,
    required this.invite,
    required this.feedback,
    required this.dataExport,
    required this.legalConsent,
    required this.review,
  });

  /// [pushService] troca o FCM (os cenários no emulador do Firebase usam um
  /// token de mentira).
  factory AccountDependencies.create(
    CoreDependencies core, {
    required AppVersion version,
    PushService? pushService,
  }) {
    final firebase = core.firebase;
    final now = core.now;
    final preferences = core.preferences;
    final cloudStore = core.cloudStore;
    final PushService pushes =
        pushService ??
        (firebase ? FirebasePushService() : const NoPushService());
    final avatars = CloudAvatarRepository(
      firebase ? FirebaseFileStoreService() : const NoFileStoreService(),
    );
    return AccountDependencies._(
      pushes: pushes,
      avatars: avatars,
      account: CloudAccountRepository(
        core.auth,
        cloudStore,
        avatars: avatars,
        now: now,
        language: () async => (await core.settings.load()).languageCode,
        push: pushes,
        preferences: preferences,
      ),
      lichess: RemoteLichessRepository(
        service: LichessService(),
        storage: DeviceSecureStorageService(),
        links: AppLinksDeepLinkService(),
        now: now,
      ),
      chessCom: RemoteChessComRepository(ChessComService(), now: now),
      invite: LocalAccountInviteRepository(preferences, now: now),
      // Sem Firebase (F-Droid): nada vai à nuvem e a Play nunca é chamada.
      feedback: firebase
          ? CloudFeedbackRepository(
              cloudStore,
              PluginDeviceService(),
              version,
              origin: core.analytics.origin,
            )
          : const NoFeedbackRepository(),
      dataExport: firebase
          ? CloudDataExportRepository(
              cloudStore,
              directory: getApplicationSupportDirectory,
              now: now,
            )
          : const NoDataExportRepository(),
      legalConsent: firebase
          ? LocalLegalConsentRepository(preferences, cloudStore, now: now)
          : const NoLegalConsentRepository(),
      review: LocalReviewRepository(
        preferences,
        firebase ? PlayReviewService() : const NoReviewService(),
        now,
      ),
    );
  }

  final PushService pushes;
  final CloudAvatarRepository avatars;
  final CloudAccountRepository account;
  final RemoteLichessRepository lichess;
  final RemoteChessComRepository chessCom;
  final LocalAccountInviteRepository invite;
  final FeedbackRepository feedback;
  final DataExportRepository dataExport;
  final LegalConsentRepository legalConsent;
  final LocalReviewRepository review;
}
