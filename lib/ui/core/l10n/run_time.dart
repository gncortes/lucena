import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../domain/use_cases/clock_format.dart';

// O separador dos décimos no idioma da tela (vírgula ou ponto).
String _decimal(BuildContext context) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP == ','
      ? ','
      : '.';
}

/// O tempo de um speedrun ou de uma etapa, com as unidades (`1 min 15,8 s`).
String runTime(BuildContext context, Duration time) =>
    RunTimeFormat.format(time, decimal: _decimal(context));

/// A diferença para o recorde, em segundos com sinal (`+3,2`).
String runTimeDifference(BuildContext context, Duration difference) =>
    RunTimeFormat.difference(difference, decimal: _decimal(context));
