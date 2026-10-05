import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/positions/positions_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/training/training_repository.dart';
import '../../../domain/models/endgame_position.dart';

part 'catalog_cubit.freezed.dart';

/// Um final (subcategoria) na tela da categoria: as posições dele que passam
/// pelo filtro e se a seção está aberta.
@freezed
abstract class CatalogSection with _$CatalogSection {
  const factory CatalogSection({
    required String subcategory,
    required List<EndgamePosition> positions,
    @Default(true) bool expanded,
  }) = _CatalogSection;
}

@freezed
abstract class CatalogState with _$CatalogState {
  const factory CatalogState({
    /// Nulo enquanto o catálogo é lido.
    List<CatalogCategory>? categories,

    /// As posições da categoria aberta, na ordem do catálogo. Nulo fora da
    /// tela da categoria ou enquanto elas são lidas.
    List<EndgamePosition>? positions,
    @Default(GoalFilter.all) GoalFilter filter,

    /// As posições em que o objetivo já foi cumprido.
    @Default(<String>{}) Set<String> fulfilled,

    /// Os finais que o jogador fechou na tela da categoria. Toda seção começa
    /// aberta; o estado não é gravado.
    @Default(<String>{}) Set<String> collapsed,
  }) = _CatalogState;

  const CatalogState._();

  /// As posições da categoria que passam pelo filtro.
  List<EndgamePosition>? get visiblePositions =>
      positions?.where((p) => filter.accepts(p.goal)).toList();

  /// Os finais da categoria com as posições que passam pelo filtro, na ordem
  /// do catálogo. Final sem posição para o filtro não entra.
  List<CatalogSection>? get sections {
    final visible = visiblePositions;
    if (visible == null) return null;
    final bySubcategory = <String, List<EndgamePosition>>{};
    for (final position in visible) {
      (bySubcategory[position.subcategory] ??= []).add(position);
    }
    return [
      for (final MapEntry(key: subcategory, value: positions)
          in bySubcategory.entries)
        CatalogSection(
          subcategory: subcategory,
          positions: positions,
          expanded: !collapsed.contains(subcategory),
        ),
    ];
  }
}

/// O catálogo: categorias, subcategorias e posições, com o filtro por
/// objetivo (gravado: volta igual na próxima vez).
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._positions, this._training, this._progress)
    : super(const CatalogState());

  final PositionsRepository _positions;
  final TrainingRepository _training;
  final ProgressRepository _progress;

  /// Lê o catálogo e o filtro. Com [category], lê também as posições de todos
  /// os finais dela.
  Future<void> load({String? category}) async {
    final filter = await _training.loadCatalogFilter();
    final categories = await _positions.catalog();
    List<EndgamePosition>? positions;
    if (category != null) {
      positions = [
        for (final c in categories)
          if (c.key == category)
            for (final sub in c.subcategories)
              ...await _positions.bySubcategory(sub.key),
      ];
    }
    final fulfilled = await _progress.fulfilledPositions();
    if (isClosed) return;
    emit(
      state.copyWith(
        categories: categories,
        positions: positions,
        filter: filter,
        fulfilled: fulfilled,
      ),
    );
  }

  Future<void> setFilter(GoalFilter filter) async {
    emit(state.copyWith(filter: filter));
    await _training.saveCatalogFilter(filter);
  }

  /// Abre ou fecha a seção de um final na tela da categoria.
  void toggleSection(String subcategory) {
    final collapsed = {...state.collapsed};
    if (!collapsed.remove(subcategory)) collapsed.add(subcategory);
    emit(state.copyWith(collapsed: collapsed));
  }
}
