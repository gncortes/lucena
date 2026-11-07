import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/demo_offer_repository.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/training/demo_offer_rules.dart';

/// Decide se a oferta da demonstração aparece depois da lição (H-LIC-51):
/// no máximo 2 vezes, com 3 dias entre elas; quem comprou nunca vê.
class DemoOfferCubit extends Cubit<bool?> {
  DemoOfferCubit({
    required this.course,
    required this.repository,
    required this.demo,
    required this.now,
  }) : super(null);

  final TrainingCourse course;
  final DemoOfferRepository repository;
  final bool demo;
  final Now now;

  /// Carrega o contador; se for mostrar, já conta esta exibição.
  Future<void> decide() async {
    final state = await repository.load(course);
    final show = DemoOfferRules.shouldOffer(state, demo: demo, now: now());
    if (show) await repository.markShown(course);
    emit(show);
  }
}
