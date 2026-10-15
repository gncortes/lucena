import 'package:flutter/material.dart';

import '../theme/app_shape.dart';

/// A barra de progresso dentro de cartão (T73, 7.1): 8 dp de altura, ponta
/// em pílula. A de 4 dp colada na AppBar é o `AppBarProgress`, outro componente.
class ProgressPill extends StatelessWidget {
  const ProgressPill({required this.value, super.key});

  static const height = 8.0;

  /// De 0 a 1.
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShape.full),
      child: LinearProgressIndicator(value: value, minHeight: height),
    );
  }
}
