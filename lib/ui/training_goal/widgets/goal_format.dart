import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';

/// Texto de uma data civil `yyyy-MM-dd` ("12 de nov."), na língua do app.
String civilShort(BuildContext context, String date) {
  final parsed = DateTime.parse(date);
  return DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
      .format(parsed);
}

/// Texto completo da data ("12 de nov. de 2026").
String civilLong(BuildContext context, String date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(DateTime.parse(date));

String civilKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// "1 hora e 30 minutos", "45 minutos", "2 horas".
String durationText(BuildContext context, int minutes) {
  final t = context.l10n;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return t.treinoDurMinutes(m);
  if (m == 0) return t.treinoDurHours(h);
  return t.treinoDurBoth(t.treinoDurHours(h), t.treinoDurMinutes(m));
}
