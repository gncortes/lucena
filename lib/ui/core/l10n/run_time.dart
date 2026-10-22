import 'package:flutter/widgets.dart';

import '../../../domain/use_cases/clock_format.dart';

/// O tempo de um speedrun ou de uma etapa como nos relógios de xadrez e nos
/// cronômetros de speedrun: `3:25.0`, sempre com ponto (o Lichess e o
/// chess.com fazem assim em qualquer idioma).
String runTime(BuildContext context, Duration time) =>
    RunTimeFormat.clock(time);
