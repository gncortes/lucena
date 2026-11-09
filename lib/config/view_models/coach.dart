import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/analysis/analysis_repository.dart';
import '../../data/repositories/characters/character_repository.dart';
import '../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../data/repositories/settings/settings_repository.dart';
import '../../data/repositories/training/course_training_repository.dart';
import '../../data/repositories/coach/trivia_repository.dart';
import '../../data/repositories/coach/your_game_filter_repository.dart';
import '../../data/repositories/coach/coach_preferences.dart';
import '../../data/repositories/coach/coach_repository.dart';
import '../../domain/models/imported_game.dart';
import '../../domain/models/coach/coach.dart';
import '../../domain/use_cases/now.dart';
import '../../ui/game_details/view_models/game_details_cubit.dart';
import '../../ui/survey/view_models/viktor_thanks_cubit.dart';
import '../../ui/coach/view_models/coach_analysis_cubit.dart';
import '../../ui/coach/view_models/trivia_cubit.dart';
import '../../ui/coach/view_models/link_account_cubit.dart';
import '../../ui/coach/view_models/coach_cubit.dart';
import '../../ui/coach/view_models/coach_exercise_cubit.dart';
import '../../ui/coach/view_models/coach_game_cubit.dart';
import '../../ui/coach_your_game/view_models/opening_course_cubit.dart';
import '../../ui/coach_your_game/view_models/model_games_cubit.dart';
import '../../ui/coach_your_game/view_models/your_game_cubit.dart';
import '../../ui/coach_your_game/view_models/theory_cubit.dart';

/// A lista do Treinador (as três abas).
CoachCubit createCoachCubit(BuildContext context) => CoachCubit(
  repository: context.read<CoachRepository>(),
  grants: context.read<CourseGrantsRepository>(),
  preferences: context.read<CoachPreferences>(),
  now: context.read<Now>(),
);

/// Ligar a conta de [platform].
LinkAccountCubit createLinkAccountCubit(
  BuildContext context, {
  required Platform platform,
}) => LinkAccountCubit(
  repository: context.read<CoachRepository>(),
  platform: platform,
);

/// Uma partida analisada pelo servidor.
CoachGameCubit createCoachGameCubit(
  BuildContext context, {
  required String id,
}) => CoachGameCubit(
  id: id,
  repository: context.read<CoachRepository>(),
  grants: context.read<CourseGrantsRepository>(),
  preferences: context.read<CoachPreferences>(),
  now: context.read<Now>(),
);

/// As curiosidades que passam enquanto a partida é analisada.
TriviaCubit createTriviaCubit(BuildContext context) => TriviaCubit(
  repository: context.read<TriviaRepository>(),
  now: context.read<Now>(),
);

/// O agradecimento do Viktor nas telas do Treinador.
ViktorThanksCubit createViktorThanksCubit(BuildContext context) =>
    ViktorThanksCubit(characters: context.read<CharacterRepository>());

/// Os exercícios de uma partida; [redo] recomeça do primeiro.
CoachExerciseCubit createCoachExerciseCubit(
  BuildContext context, {
  required String id,
  required bool redo,
}) => CoachExerciseCubit(
  id: id,
  repository: context.read<CoachRepository>(),
  preferences: context.read<CoachPreferences>(),
  redo: redo,
);

/// A partida da análise completa.
CoachAnalysisCubit createCoachAnalysisCubit(
  BuildContext context, {
  required String id,
}) => CoachAnalysisCubit(repository: context.read<CoachRepository>(), id: id);

/// A análise completa de uma partida importada, na base da análise do app.
GameDetailsCubit createImportedGameDetailsCubit(
  BuildContext context,
  ImportedGame game,
) => GameDetailsCubit.imported(
  game,
  analysis: context.read<AnalysisRepository>(),
  settings: context.read<SettingsRepository>(),
);

/// A aba Seu jogo (e as telas de estilo e de tema, que leem o mesmo resumo).
YourGameCubit createYourGameCubit(BuildContext context) => YourGameCubit(
  repository: context.read<CoachRepository>(),
  filter: context.read<YourGameFilterRepository>(),
  now: context.read<Now>(),
);

/// Onde a partida [gameId] saiu da teoria.
TheoryCubit createTheoryCubit(BuildContext context, {required String gameId}) =>
    TheoryCubit(repository: context.read<CoachRepository>(), gameId: gameId);

/// As partidas-modelo da abertura [eco].
ModelGamesCubit createModelGamesCubit(
  BuildContext context, {
  required String eco,
}) => ModelGamesCubit(repository: context.read<CoachRepository>(), eco: eco);

/// A abertura [slot] no Pilares e se ele já tem o curso.
OpeningCourseCubit createOpeningCourseCubit(
  BuildContext context, {
  required String slot,
  int? part,
}) => OpeningCourseCubit(
  training: context.read<TrainingRepository>(),
  access: context.read<CourseAccessRepository>(),
  slot: slot,
  part: part,
);
