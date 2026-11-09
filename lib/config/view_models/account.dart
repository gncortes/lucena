import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/account/avatar_repository.dart';
import '../../data/repositories/account/mail_app_repository.dart';
import '../../data/repositories/analytics/analytics_repository.dart';
import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/journey/journey_repository.dart';
import '../../data/repositories/legal/legal_consent_repository.dart';
import '../../data/repositories/onboarding/onboarding_repository.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../data/repositories/sync/sync_scheduler.dart';
import '../../domain/models/progress_summary.dart';
import '../../ui/account/view_models/account_consent_cubit.dart';
import '../../ui/account/view_models/account_cubit.dart';
import '../../ui/account/view_models/account_photo_cubit.dart';
import '../../ui/account/view_models/account_restored_cubit.dart';
import '../../ui/core/analytics/analytics_context.dart';

/// O [AccountCubit] de toda tela da conta, montado com os repositórios do
/// [context].
///
/// - [moment]: o `momento` do evento `conta_convite`.
/// - [reauth]: só entrar de novo (apagar a conta pediu um login recente):
///   sem junção, sem Analytics, sem campanha e sem aceite.
/// - [tracked]: com Analytics e a campanha do link (falso: os dados da conta).
/// - [consent]: pede o aceite dos termos depois de criar a conta (sem o
///   repositório acima, numa tela montada sozinha, nenhum).
/// - [onboarding]: oferece o tour, quando o app o tem.
AccountCubit createAccountCubit(
  BuildContext context, {
  String? moment,
  bool reauth = false,
  bool tracked = true,
  bool consent = false,
  bool onboarding = false,
}) {
  final accounts = context.read<AccountRepository>();
  if (reauth) return AccountCubit(accounts);
  return AccountCubit(
    accounts,
    sync: context.read<SyncScheduler>(),
    analytics: tracked ? context.analytics : const NoAnalyticsRepository(),
    campaigns: tracked ? context.campaigns : null,
    moment: moment,
    consent: consent
        ? _optional<LegalConsentRepository>(context) ??
              const NoLegalConsentRepository()
        : const NoLegalConsentRepository(),
    onboarding: onboarding ? _optional<OnboardingRepository>(context) : null,
  );
}

/// O "Termos e privacidade" da conta que acabou de entrar.
AccountConsentCubit createAccountConsentCubit(BuildContext context) =>
    AccountConsentCubit(
      uid: context.read<AccountRepository>().current?.uid,
      consent: context.read<LegalConsentRepository>(),
      analytics: context.analytics,
    );

/// A foto e o avatar dos dados da conta.
AccountPhotoCubit createAccountPhotoCubit(BuildContext context) =>
    AccountPhotoCubit(
      accounts: context.read<AccountRepository>(),
      photos: context.read<PhotoRepository>(),
      avatars: context.read<AvatarRepository>(),
    );

/// O "Bem-vindo de volta" do progresso [summary] que a conta trouxe.
AccountRestoredCubit createAccountRestoredCubit(
  BuildContext context,
  ProgressSummary summary,
) => AccountRestoredCubit(
  summary,
  context.read<JourneyRepository>(),
  context.read<CharacterRepository>(),
  accounts: context.read<AccountRepository>(),
);

/// "Abrir o e-mail" do link de nova senha, ou nulo sem app de e-mail no
/// aparelho (o botão some).
Future<VoidCallback?> mailAppOpener(BuildContext context) async {
  final mail = context.read<MailAppRepository>();
  return await mail.available() ? mail.open : null;
}

T? _optional<T>(BuildContext context) {
  try {
    return context.read<T>();
  } on ProviderNotFoundException {
    return null;
  }
}
