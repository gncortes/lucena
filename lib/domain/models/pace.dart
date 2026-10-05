import 'clock.dart';

/// O ritmo de uma partida, pela regra do Lichess: o tempo estimado é o
/// inicial mais 40 incrementos.
enum PaceCategory {
  bullet,
  blitz,
  rapid,
  classical;

  /// Código guardado no banco e no JSON.
  String get code => name;

  /// Lê o [code]. Nulo se não for um ritmo conhecido.
  static PaceCategory? fromCode(String? code) {
    for (final pace in values) {
      if (pace.code == code) return pace;
    }
    return null;
  }

  /// O ritmo de um tempo de jogo.
  static PaceCategory of(TimeControl time) {
    final estimated = time.initial.inSeconds + 40 * time.increment.inSeconds;
    if (estimated < 180) return bullet;
    if (estimated < 480) return blitz;
    if (estimated < 1500) return rapid;
    return classical;
  }
}

/// Um tempo de jogo com nome, como os do Lichess (`3+2`).
class NamedTimeControl {
  const NamedTimeControl({required this.id, required this.time});

  /// Nome em minutos e incremento (`3+2`).
  final String id;
  final TimeControl time;

  PaceCategory get category => PaceCategory.of(time);

  @override
  bool operator ==(Object other) =>
      other is NamedTimeControl && other.id == id && other.time == time;

  @override
  int get hashCode => Object.hash(id, time);
}

/// Como o Maia decide num ritmo. No bullet ele fica nos lances naturais,
/// os mais prováveis da política (jogo de instinto), e pensa menos.
class PaceProfile {
  const PaceProfile({required this.temperature, required this.thinkScale});

  /// Substitui `MaiaLevels.temperature` no sorteio do lance: mais perto de 0,
  /// mais ele fica nos lances mais prováveis.
  final double temperature;

  /// Multiplica o tempo que o Maia pensa num lance.
  final double thinkScale;

  /// O perfil sem ajuste de ritmo.
  static const standard = PaceProfile(temperature: 0.5, thinkScale: 1);

  @override
  bool operator ==(Object other) =>
      other is PaceProfile &&
      other.temperature == temperature &&
      other.thinkScale == thinkScale;

  @override
  int get hashCode => Object.hash(temperature, thinkScale);
}

/// Os tempos de jogo oferecidos e o perfil do Maia em cada ritmo
/// (`assets/progression/time_controls.json`).
class PaceTable {
  const PaceTable({required this.named, required this.profiles});

  final List<NamedTimeControl> named;
  final Map<PaceCategory, PaceProfile> profiles;

  /// O perfil do ritmo de [time]. Sem relógio, vale o clássico.
  PaceProfile profileFor(TimeControl? time) {
    final category = time == null
        ? PaceCategory.classical
        : PaceCategory.of(time);
    return profiles[category] ?? PaceProfile.standard;
  }

  /// Lê o JSON do asset. Entradas inválidas são ignoradas.
  static PaceTable fromJson(Map<String, dynamic> json) {
    final named = <NamedTimeControl>[];
    final rawNamed = json['named'];
    if (rawNamed is List) {
      for (final entry in rawNamed) {
        if (entry is! Map) continue;
        final id = entry['id'];
        final time = TimeControl.tryParse(
          entry['time'] is String ? entry['time'] as String : null,
        );
        if (id is! String || id.isEmpty || time == null) continue;
        named.add(NamedTimeControl(id: id, time: time));
      }
    }
    final profiles = <PaceCategory, PaceProfile>{};
    final rawProfiles = json['profiles'];
    if (rawProfiles is Map) {
      for (final MapEntry(:key, :value) in rawProfiles.entries) {
        final category = PaceCategory.fromCode(key is String ? key : null);
        if (category == null || value is! Map) continue;
        final temperature = value['temperature'];
        final thinkScale = value['thinkScale'];
        if (temperature is! num || thinkScale is! num) continue;
        if (temperature < 0 || thinkScale <= 0) continue;
        profiles[category] = PaceProfile(
          temperature: temperature.toDouble(),
          thinkScale: thinkScale.toDouble(),
        );
      }
    }
    return PaceTable(named: named, profiles: profiles);
  }
}
