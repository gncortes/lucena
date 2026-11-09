import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/lichess/lichess_repository.dart';
import '../../data/repositories/profile/profile_repository.dart';
import '../../data/repositories/rating/rating_repository.dart';
import '../../data/repositories/sync/sync_scheduler.dart';
import '../../ui/core/analytics/analytics_context.dart';
import '../../ui/profile/view_models/account_delete_cubit.dart';
import '../../ui/profile/view_models/current_rating_cubit.dart';
import '../../ui/profile/view_models/profile_account_cubit.dart';

/// O rating que Configurações e Perfil mostram, com o repositório do
/// [context]. Quem chama decide quando ler (`load`).
CurrentRatingCubit createCurrentRatingCubit(BuildContext context) =>
    CurrentRatingCubit(context.read<RatingRepository>());

/// A conta, a sincronização e o Lichess do Perfil.
ProfileAccountCubit createProfileAccountCubit(BuildContext context) =>
    ProfileAccountCubit(
      accounts: context.read<AccountRepository>(),
      sync: context.read<SyncScheduler>(),
      lichess: context.read<LichessRepository>(),
      profile: context.read<ProfileRepository>(),
      analytics: context.analytics,
    );

/// "Excluir sua conta?" para a conta [uid].
AccountDeleteCubit createAccountDeleteCubit(
  BuildContext context, {
  required String uid,
}) => AccountDeleteCubit(
  uid: uid,
  accounts: context.read<AccountRepository>(),
  profile: context.read<ProfileRepository>(),
  analytics: context.analytics,
);
