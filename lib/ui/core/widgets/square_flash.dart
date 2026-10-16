import 'package:flutter/foundation.dart';

/// A casa que o aluno tocou na fala do professor: o tabuleiro da tela a
/// realça até o aluno tocar nela de novo (desmarca), tocar em outra casa
/// (troca) ou a tela ir para outro passo ([clear]) (Gabriel, 16/10/2026).
class SquareFlash extends ChangeNotifier {
  String? _square;

  /// A casa realçada agora (`f5`); nula quando nenhuma está marcada.
  String? get square => _square;

  void show(String square) {
    _square = _square == square ? null : square;
    notifyListeners();
  }

  void clear() {
    if (_square == null) return;
    _square = null;
    notifyListeners();
  }
}
