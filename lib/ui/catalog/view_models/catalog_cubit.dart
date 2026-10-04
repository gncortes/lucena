import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/positions/positions_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/training/training_repository.dart';
import '../../../domain/models/endgame_position.dart';

part 'catalog_cubit.freezed.dart';

@freezed
abstract class CatalogState with _$CatalogState {
  const factory CatalogState({
    /// Nulo enquanto o catálogo é lido.
    List<CatalogCategory>? categories,

    /// As posições da subcategoria aberta, na ordem do catálogo. Nulo fora da
    /// lista de posições ou enquanto ela é lida.
    List<EndgamePosition>? positions,
    @Default(GoalFilter.all) GoalFilter filter,

    /// As posições em que o objetivo já foi cumprido.
    @Default(<String>{}) Set<String> fulfilled,
  }) = _CatalogState;

  const CatalogState._();

  /// As posições da subcategoria que passam pelo filtro.
  List<EndgamePosition>? get visiblePositions =>
      positions?.where((p) => filter.accepts(p.goal)).toList();
}

/// O catálogo: categorias, subcategorias e posições, com o filtro por
/// objetivo (gravado: volta igual na próxima vez).
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._positions, this._training, this._progress)
    : super(const CatalogState());

  final PositionsRepository _positions;
  final TrainingRepository _training;
  final ProgressRepository _progress;

  /// Lê o catálogo e o filtro. Com [subcategory], lê também as posições dela.
  Future<void> load({String? subcategory}) async {
    final filter = await _training.loadCatalogFilter();
    final categories = await _positions.catalog();
    final positions = subcategory == null
        ? null
        : await _positions.bySubcategory(subcategory);
    final fulfilled = await _progress.fulfilledPositions();
    if (isClosed) return;
    emit(
      CatalogState(
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
}
