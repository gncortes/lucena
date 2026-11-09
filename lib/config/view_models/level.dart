import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/account/account_repository.dart';
import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/chesscom/chesscom_repository.dart';
import '../../data/repositories/home/home_layout_repository.dart';
import '../../data/repositories/lichess/lichess_repository.dart';
import '../../data/repositories/onboarding/onboarding_repository.dart';
import '../../data/repositories/profile/profile_repository.dart';
import '../../data/repositories/rating/rating_repository.dart';
import '../../data/repositories/sync/sync_scheduler.dart';
import '../../domain/use_cases/now.dart';
import '../../ui/core/analytics/analytics_context.dart';
import '../../ui/level/view_models/level_cubit.dart';

/// O [LevelCubit] montado com os repositórios do [context], já carregando.
/// [inTour]: o passo de nível do tour (sem trocar o rating do app);
/// [fromProfile]: aberto pelo Perfil, a tela só troca o nível.
LevelCubit createLevelCubit(
  BuildContext context, {
  bool inTour = false,
  bool fromProfile = false,
}) => LevelCubit(
  onboarding: context.read<OnboardingRepository>(),
  profile: context.read<ProfileRepository>(),
  characters: context.read<CharacterRepository>(),
  lichess: context.read<LichessRepository>(),
  chessCom: context.read<ChessComRepository>(),
  home: context.read<HomeLayoutRepository>(),
  inTour: inTour,
  fromProfile: fromProfile,
  analytics: context.analytics,
  accounts: context.read<AccountRepository>(),
  sync: context.read<SyncScheduler>(),
  now: context.read<Now>(),
  rating: inTour ? null : context.read<RatingRepository>(),
)..load();
