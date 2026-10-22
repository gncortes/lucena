import 'dart:convert';

import '../../../domain/models/featured.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/streak_rules.dart';
import '../../services/preferences_service.dart';
import '../featured/featured_progress_repository.dart';
import '../progress/progress_repository.dart';
import '../school/school_progress_repository.dart';

/// Os dias com atividade, para a sequência (E1.22, decisão 2b): partida,
/// aula ou final jogado.
abstract class ActivityRepository {
  /// Os dias com atividade, à meia-noite local.
  Future<Set<DateTime>> days();

  /// Marca hoje como dia com atividade.
  Future<void> markToday();

  /// Se a folha da sequência que acabou em [lastDay] ainda não saiu.
  Future<bool> lostPending(DateTime lastDay);

  /// A folha da sequência que acabou em [lastDay] já saiu: não volta.
  Future<void> markLostShown(DateTime lastDay);
}

/// Aulas e finais marcam o dia nas preferências; as partidas já têm a data
/// gravada no banco e entram na leitura. Assim não há migração, e os dias de
/// partidas de antes desta versão já contam.
class LocalActivityRepository implements ActivityRepository {
  LocalActivityRepository(this._preferences, this._progress, this._now);

  static const _daysKey = 'activity.days';
  static const _lostKey = 'activity.lostShown';

  final PreferencesService _preferences;
  final ProgressRepository _progress;
  final Now _now;

  @override
  Future<Set<DateTime>> days() async {
    final attempts = await _progress.allAttempts();
    return {
      ...await _marked(),
      for (final attempt in attempts) StreakRules.day(attempt.playedAt),
    };
  }

  @override
  Future<void> markToday() async {
    final today = StreakRules.day(_now());
    final marked = await _marked();
    if (!marked.add(today)) return;
    await _preferences.setString(
      _daysKey,
      jsonEncode([for (final day in marked) _encode(day)]..sort()),
    );
  }

  @override
  Future<bool> lostPending(DateTime lastDay) async =>
      await _preferences.getString(_lostKey) != _encode(lastDay);

  @override
  Future<void> markLostShown(DateTime lastDay) =>
      _preferences.setString(_lostKey, _encode(lastDay));

  Future<Set<DateTime>> _marked() async {
    final text = await _preferences.getString(_daysKey);
    if (text == null) return {};
    final Object? list;
    try {
      list = jsonDecode(text);
    } on FormatException {
      return {};
    }
    return {
      if (list is List)
        for (final item in list)
          if (item is String) ?DateTime.tryParse(item),
    };
  }

  static String _encode(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// Marca o dia quando uma aula termina (o capítulo entra pela
/// `NotifyingEndgameProgressRepository`).
class ActiveSchoolProgressRepository implements SchoolProgressRepository {
  ActiveSchoolProgressRepository(this._inner, this._activity);

  final SchoolProgressRepository _inner;
  final ActivityRepository _activity;

  @override
  Future<SchoolProgress> load() => _inner.load();

  @override
  Future<void> save(SchoolProgress progress) async {
    final before = await _inner.load();
    await _inner.save(progress);
    if (!before.completed.containsAll(progress.completed)) {
      await _activity.markToday();
    }
  }
}

/// Marca o dia no primeiro lance de um final em destaque, mesmo já jogado
/// antes.
class ActiveFeaturedProgressRepository implements FeaturedProgressRepository {
  ActiveFeaturedProgressRepository(this._inner, this._activity);

  final FeaturedProgressRepository _inner;
  final ActivityRepository _activity;

  @override
  Future<Set<String>> played() => _inner.played();

  @override
  Future<void> markPlayed(String id) async {
    await _inner.markPlayed(id);
    await _activity.markToday();
  }

  @override
  Future<FeaturedChoice?> choice(String id) => _inner.choice(id);

  @override
  Future<void> saveChoice(String id, FeaturedChoice choice) =>
      _inner.saveChoice(id, choice);
}
