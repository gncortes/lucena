import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/home_suggestion.dart';

/// Para onde a pergunta sai depois do "Continuar".
enum GoalExit {
  /// "Seu nível".
  level,

  /// "Aprender a jogar" pula o nível: a tela inicial (decisão 1a da E1.11).
  home,
}

class GoalState {
  const GoalState({
    this.ready = false,
    this.goal = GoalPreference.endgames,
    this.exit,
    this.viktor,
  });

  final bool ready;

  /// A opção marcada. Vem "Aprender finais" de saída, como no canvas.
  final GoalPreference goal;

  /// A escolha foi gravada: a tela sai para cá. Nulo enquanto fica.
  final GoalExit? exit;
  final Character? viktor;

  GoalState copyWith({GoalPreference? goal, GoalExit? exit}) => GoalState(
    ready: ready,
    goal: goal ?? this.goal,
    exit: exit ?? this.exit,
    viktor: viktor,
  );
}

/// "O que você quer fazer?", entre o tour e "Seu nível": o objetivo vai para
/// o perfil e decide o primeiro cartão da tela inicial.
class GoalCubit extends Cubit<GoalState> {
  GoalCubit({
    required this._onboarding,
    required this._profile,
    required this._characters,
    this._home,
  }) : super(const GoalState());

  final OnboardingRepository _onboarding;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final HomeLayoutRepository? _home;
  bool _finishing = false;

  Future<void> load() async {
    final onboarding = await _onboarding.load();
    final profile = await _profile.load();
    final characters = await _characters.characters();
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == 'master') viktor = character;
    }
    emit(
      GoalState(
        ready: true,
        goal: profile.goal ?? GoalPreference.endgames,
        viktor: viktor,
      ),
    );
    // O app fechado aqui volta aqui.
    if (!onboarding.done) {
      await _onboarding.save(onboarding.copyWith(stage: OnboardingStage.goal));
    }
  }

  /// Marca a opção (só grava no "Continuar").
  void select(GoalPreference goal) {
    if (!state.ready || state.exit != null || _finishing) return;
    emit(state.copyWith(goal: goal));
  }

  /// Grava o objetivo. "Aprender a jogar" fecha a primeira abertura como
  /// iniciante; os outros seguem para "Seu nível".
  Future<void> finish() async {
    if (!state.ready || state.exit != null || _finishing) return;
    _finishing = true;
    try {
      final goal = state.goal;
      final profile = await _profile.load();
      if (goal != GoalPreference.learn) {
        await _profile.save(profile.copyWith(goal: goal));
        if (!isClosed) emit(state.copyWith(exit: GoalExit.level));
        return;
      }
      const rating = RatingLevel.beginner;
      await _profile.save(profile.copyWith(goal: goal, rating: rating.rating));
      await _home?.save(HomeSuggestion.of(rating, goal: goal));
      await _home?.markNoticeSeen();
      final onboarding = await _onboarding.load();
      await _onboarding.save(
        onboarding.copyWith(
          done: true,
          step: 0,
          startRung: '${MaiaLevels.atOrBelow(rating.rating)}',
          selectedRating: () => rating.rating,
          byHand: true,
          inProgress: false,
        ),
      );
      if (!isClosed) emit(state.copyWith(exit: GoalExit.home));
    } finally {
      _finishing = false;
    }
  }
}
