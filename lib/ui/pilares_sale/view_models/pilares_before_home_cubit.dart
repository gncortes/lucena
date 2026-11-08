import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/character.dart';

/// A oferta antes do Início (H-VEN-15, `PropV2OfertaAntesInicio`): a
/// conta das vezes é do Início (H-INI-14, `OpeningOfferRepository`); aqui
/// ficam o rosto do Viktor e os eventos de vista e de fechada. O estado é o
/// professor (nulo enquanto carrega ou sem o personagem).
class PilaresBeforeHomeCubit extends Cubit<Character?> {
  PilaresBeforeHomeCubit({required this._analytics, required this._characters})
    : super(null) {
    unawaited(_open());
  }

  static const origin = 'abertura_app';
  static const format = 'tela';

  final AnalyticsRepository _analytics;
  final CharacterRepository _characters;
  bool _closed = false;

  Future<void> _open() async {
    unawaited(
      _analytics.log(
        AnalyticsEvents.pilaresOfertaVista(origem: origin, destaque: format),
      ),
    );
    final characters = await _characters.characters();
    if (isClosed) return;
    emit(characters.where((each) => each.id == 'master').firstOrNull);
  }

  /// O X, o voltar do sistema ou o toque fora da folha: conta uma vez só.
  Future<void> dismissed() async {
    if (_closed) return;
    _closed = true;
    await _analytics.log(
      AnalyticsEvents.pilaresOfertaFechada(origem: origin, destaque: format),
    );
  }

  /// "Conhecer o plano" não é fechar a oferta.
  void learn() => _closed = true;
}
