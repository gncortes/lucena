import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../domain/models/home_layout.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/home_suggestion.dart';

class HomeLayoutState {
  const HomeLayoutState({
    this.layout,
    this.level = RatingLevel.casual,
    this.goal,
  });

  /// Nulo enquanto lê.
  final HomeLayout? layout;
  final RatingLevel level;

  /// O objetivo: o caminho dele vem primeiro na sugestão.
  final GoalPreference? goal;

  /// O layout já é a sugestão do nível: "voltar à sugestão" não muda nada.
  bool get isSuggestion => layout != null && !layout!.custom;
}

/// A configuração da tela inicial: marcar, reordenar e voltar à sugestão do
/// nível. Cada mudança é gravada na hora.
class HomeLayoutCubit extends Cubit<HomeLayoutState> {
  HomeLayoutCubit({required this._layouts, required this._profile})
    : super(const HomeLayoutState());

  final HomeLayoutRepository _layouts;
  final ProfileRepository _profile;

  Future<void> load() async {
    final profile = await _profile.load();
    final saved = await _layouts.load();
    if (isClosed) return;
    emit(
      HomeLayoutState(
        layout: HomeSuggestion.resolve(
          saved,
          profile.level,
          goal: profile.goal,
        ),
        level: profile.level,
        goal: profile.goal,
      ),
    );
  }

  /// Marca ou desmarca [path] (o último marcado não sai).
  Future<void> toggle(HomePath path) => _change(
    (layout) =>
        HomeSuggestion.toggle(layout, path, state.level, goal: state.goal),
  );

  /// Arrastou da posição [from] para [to] (o índice do `ReorderableListView`,
  /// que conta o lugar antes de tirar o item).
  Future<void> reorder(int from, int to) => _change(
    (layout) => HomeSuggestion.move(
      layout,
      from,
      to > from ? to - 1 : to,
      state.level,
      goal: state.goal,
    ),
  );

  /// Volta à sugestão do nível: a ordem e os marcados dele, que acompanham
  /// o nível dali em diante.
  Future<void> restore() =>
      _change((_) => HomeSuggestion.of(state.level, goal: state.goal));

  Future<void> _change(HomeLayout Function(HomeLayout) change) async {
    final layout = state.layout;
    if (layout == null) return;
    final next = change(layout);
    emit(HomeLayoutState(layout: next, level: state.level, goal: state.goal));
    await _layouts.save(next);
  }
}
