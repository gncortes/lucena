import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/crowd/crowd_repository.dart';
import '../../../domain/models/crowd_stat.dart';

/// O "x% acertaram" de um final em destaque (E1.24), lido da nuvem no fim
/// da partida. Nulo: o número ainda não saiu (ou sem rede).
class FeaturedCrowdCubit extends Cubit<CrowdStat?> {
  FeaturedCrowdCubit({required this.id, required this._crowd}) : super(null);

  final String id;
  final CrowdRepository _crowd;

  Future<void> load() async {
    final stat = await _crowd.featured(id);
    if (!isClosed) emit(stat);
  }
}
