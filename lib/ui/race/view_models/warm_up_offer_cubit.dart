import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/race_rules.dart';

/// A oferta de aquecimento antes do desafio: o estado diz se ela está ligada
/// (Configurações › Partida e "Não perguntar de novo" na folha).
class WarmUpOfferCubit extends Cubit<bool> {
  WarmUpOfferCubit(this._repository) : super(true);

  final RaceRepository _repository;

  /// Lê a preferência guardada.
  Future<void> load() async {
    final value = await _repository.offersWarmUp();
    if (!isClosed) emit(value);
  }

  /// Liga ou desliga a oferta e guarda.
  Future<void> setOffers({required bool value}) async {
    emit(value);
    await _repository.setOffersWarmUp(value: value);
  }

  /// Os problemas a oferecer antes do final ([subcategory], [category]).
  /// Vazio quando o jogador pediu para não perguntar mais ou o banco não tem.
  Future<List<RaceProblem>> problemsToOffer({
    String? subcategory,
    String? category,
  }) async {
    if (!await _repository.offersWarmUp()) return const [];
    return RaceRules.warmUp(
      await _repository.problems(),
      subcategory: subcategory,
      category: category,
    );
  }
}
