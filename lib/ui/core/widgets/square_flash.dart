import 'dart:async';

import 'package:flutter/foundation.dart';

import '../theme/app_motion.dart';

/// A casa que o aluno tocou na fala do professor: o tabuleiro da tela a
/// realça por [duration] e o realce some sozinho ou quando o aluno toca em
/// outra casa. Tocar de novo na mesma casa repete o realce ([show] sempre
/// avisa).
class SquareFlash extends ChangeNotifier {
  static const duration = AppMotion.squareFlash;

  String? _square;
  Timer? _timer;

  /// A casa realçada agora (`f5`); nula quando o realce já sumiu.
  String? get square => _square;

  void show(String square) {
    _timer?.cancel();
    _square = square;
    _timer = Timer(duration, clear);
    notifyListeners();
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    if (_square == null) return;
    _square = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
