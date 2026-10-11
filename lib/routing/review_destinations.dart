import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/achievements/achievements_repository.dart';
import '../data/repositories/analysis/analysis_repository.dart';
import '../data/repositories/characters/character_repository.dart';
import '../data/repositories/journey/journey_repository.dart';
import '../data/repositories/progress/progress_repository.dart';
import '../data/repositories/rating/rating_repository.dart';
import '../data/repositories/review/game_review_repository.dart';
import '../data/repositories/school/lesson_repository.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/speedrun/speedrun_repository.dart';
import '../domain/use_cases/now.dart';
import '../ui/game_details/view_models/game_details_cubit.dart';
import '../ui/game_details/widgets/game_details_screen.dart';
import '../ui/profile/view_models/rating_cubit.dart';
import '../ui/profile/widgets/rating_screen.dart';

/// Shared by canonical routes and Android container entry points.
Widget ratingDestination(BuildContext context, {int? highlightedGame}) =>
    BlocProvider(
      create: (_) => RatingCubit(
        context.read<RatingRepository>(),
        progress: context.read<ProgressRepository>(),
        achievements: context.read<AchievementsRepository>(),
        speedruns: context.read<SpeedrunRepository>(),
        journey: context.read<JourneyRepository>(),
        characters: context.read<CharacterRepository>(),
        reviews: context.read<GameReviewRepository>(),
        now: context.read<Now>(),
        highlightedGame: highlightedGame,
      )..load(),
      child: const RatingScreen(gameDestinationBuilder: gameDetailsDestination),
    );

Widget gameDetailsDestination(BuildContext context, int id) {
  // Read locale outside provider.create; it may not depend on Localizations.
  final language = Localizations.localeOf(context).languageCode;
  return BlocProvider(
    create: (_) => GameDetailsCubit(
      id,
      progress: context.read<ProgressRepository>(),
      rating: context.read<RatingRepository>(),
      characters: context.read<CharacterRepository>(),
      analysis: context.read<AnalysisRepository>(),
      reviews: context.read<GameReviewRepository>(),
      lessons: context.read<LessonRepository>(),
      settings: context.read<SettingsRepository>(),
    )..load(language: language),
    child: const GameDetailsScreen(),
  );
}
