import 'dart:convert';

import '../use_cases/rating_period.dart';
import 'attempt.dart';
import 'clock.dart';
import 'pace.dart';
import 'speedrun.dart';

/// As três abas do Histórico.
enum HistoryTab {
  games,
  classic,
  marathon;

  String get code => name;

  /// A aba gravada; o que não se entende volta às partidas.
  static HistoryTab fromCode(String? code) =>
      values.asNameMap()[code] ?? HistoryTab.games;
}

Map<String, dynamic>? _decode(String? code) {
  if (code == null || code.isEmpty) return null;
  try {
    final json = jsonDecode(code);
    return json is Map<String, dynamic> ? json : null;
  } on FormatException {
    return null;
  }
}

String? _text(Object? value) => value is String ? value : null;

/// Os filtros da aba Partidas: o período (sempre há um), o resultado e o ritmo.
/// Uma escolha por dimensão.
class GamesHistoryFilter {
  const GamesHistoryFilter({
    this.period = RatingPeriod.all,
    this.result,
    this.pace,
  });

  /// O valor de [pace] das partidas sem relógio.
  static const noClock = 'none';

  /// Lê o gravado; lixo volta ao padrão.
  factory GamesHistoryFilter.fromCode(String? code) {
    final json = _decode(code);
    if (json == null) return const GamesHistoryFilter();
    final pace = json['pace'];
    return GamesHistoryFilter(
      period:
          RatingPeriod.values.asNameMap()[_text(json['period'])] ??
          RatingPeriod.all,
      result: AttemptOutcome.values.asNameMap()[_text(json['result'])],
      pace:
          pace is String &&
              (pace == noClock || PaceCategory.fromCode(pace) != null)
          ? pace
          : null,
    );
  }

  /// Monta o filtro das escolhas da folha (grupo -> valor).
  factory GamesHistoryFilter.fromSelection(Map<String, String?> selection) =>
      GamesHistoryFilter(
        period:
            RatingPeriod.values.asNameMap()[selection['period']] ??
            RatingPeriod.all,
        result: AttemptOutcome.values.asNameMap()[selection['result']],
        pace: selection['pace'],
      );

  final RatingPeriod period;
  final AttemptOutcome? result;

  /// O [PaceCategory.code], ou [noClock]. Nulo: qualquer.
  final String? pace;

  /// Quantas dimensões estão fora do padrão (Todas, qualquer, qualquer).
  int get count =>
      (period == RatingPeriod.all ? 0 : 1) +
      (result == null ? 0 : 1) +
      (pace == null ? 0 : 1);

  bool get isEmpty => count == 0;

  Map<String, String?> get selection => {
    'period': period.name,
    'result': result?.code,
    'pace': pace,
  };

  /// Se uma partida de ritmo [time] (nulo: sem relógio) passa no ritmo.
  bool matchesPace(TimeControl? time) {
    final pace = this.pace;
    if (pace == null) return true;
    if (time == null) return pace == noClock;
    return pace == PaceCategory.of(time).code;
  }

  String get code =>
      jsonEncode({'period': period.name, 'result': result?.code, 'pace': pace});

  @override
  bool operator ==(Object other) =>
      other is GamesHistoryFilter &&
      other.period == period &&
      other.result == result &&
      other.pace == pace;

  @override
  int get hashCode => Object.hash(period, result, pace);
}

/// Os filtros das abas Clássico e Maratona: o nível e o ritmo. Uma escolha
/// por dimensão.
class SpeedrunHistoryFilter {
  const SpeedrunHistoryFilter({this.level, this.pace});

  /// Lê o gravado; lixo volta ao padrão.
  factory SpeedrunHistoryFilter.fromCode(String? code) {
    final json = _decode(code);
    if (json == null) return const SpeedrunHistoryFilter();
    return SpeedrunHistoryFilter(
      level: SpeedrunCategory.fromCode(_text(json['level'])),
      pace: PaceCategory.fromCode(_text(json['pace'])),
    );
  }

  /// Monta o filtro das escolhas da folha (grupo -> valor).
  factory SpeedrunHistoryFilter.fromSelection(Map<String, String?> selection) =>
      SpeedrunHistoryFilter(
        level: SpeedrunCategory.fromCode(selection['level']),
        pace: PaceCategory.fromCode(selection['pace']),
      );

  final SpeedrunCategory? level;
  final PaceCategory? pace;

  int get count => (level == null ? 0 : 1) + (pace == null ? 0 : 1);

  bool get isEmpty => count == 0;

  Map<String, String?> get selection => {
    'level': level?.name,
    'pace': pace?.code,
  };

  String get code => jsonEncode({'level': level?.name, 'pace': pace?.code});

  @override
  bool operator ==(Object other) =>
      other is SpeedrunHistoryFilter &&
      other.level == level &&
      other.pace == pace;

  @override
  int get hashCode => Object.hash(level, pace);
}
