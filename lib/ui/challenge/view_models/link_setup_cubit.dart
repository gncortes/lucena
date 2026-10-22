import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/onboarding/onboarding_repository.dart';

/// O "Antes do desafio" da primeira abertura por link: o estado é se já
/// terminou. Ao terminar, grava que o jogador passou por ele, para o tour
/// não repetir o tabuleiro e o link não pedir de novo.
class LinkSetupCubit extends Cubit<bool> {
  LinkSetupCubit(this._onboarding) : super(false);

  final OnboardingRepository _onboarding;

  Future<void> finish() async {
    final saved = await _onboarding.load();
    await _onboarding.save(saved.copyWith(linkSetupDone: true));
    if (!isClosed) emit(true);
  }
}
