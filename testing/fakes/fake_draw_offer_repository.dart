import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/draw/draw_offer_repository.dart';
import 'package:lucena/domain/models/game_setup.dart';

/// A máquina responde o que o teste combinou em [accept].
class FakeDrawOfferRepository implements DrawOfferRepository {
  FakeDrawOfferRepository({this.accept = false});

  bool accept;

  /// Quantas propostas chegaram.
  int offers = 0;

  @override
  Future<bool> accepts(
    Position position, {
    required Side machine,
    required OpponentKind kind,
    int? level,
  }) async {
    offers++;
    return accept;
  }
}
