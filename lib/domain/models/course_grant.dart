/// O id do Pilares em `acessos/{uid}.cursos` (o único curso pago hoje).
const pilaresCourseId = 'pilares';

/// De onde veio o acesso dado pelo servidor (`acessos/{uid}.cursos.{id}`).
enum GrantOrigin {
  purchase('compra'),
  gift('presente'),
  paidOutside('pagoPorFora');

  const GrantOrigin(this.wire);

  final String wire;

  static GrantOrigin? parse(Object? value) =>
      values.where((o) => o.wire == value).firstOrNull;
}

enum GrantPlan {
  lifetime('vitalicio'),
  monthly('mensal');

  const GrantPlan(this.wire);

  final String wire;

  static GrantPlan? parse(Object? value) =>
      values.where((p) => p.wire == value).firstOrNull;
}

/// Um curso em `acessos/{uid}` (H-R5-61): gravado só pela Function.
final class CourseGrant {
  const CourseGrant({
    required this.origin,
    this.plan = GrantPlan.lifetime,
    this.until,
    this.givenAt,
    this.revokedAt,
  });

  final GrantOrigin origin;
  final GrantPlan plan;

  /// Fim do acesso (mensal ou presente com prazo). Nulo: sem fim.
  final DateTime? until;
  final DateTime? givenAt;

  /// O admin tirou o curso: fecha na próxima sincronização.
  final DateTime? revokedAt;

  bool activeAt(DateTime now) =>
      revokedAt == null && (until == null || now.isBefore(until!));

  static CourseGrant? fromJson(Object? json) {
    if (json is! Map) return null;
    final origin = GrantOrigin.parse(json['origem']);
    if (origin == null) return null;
    return CourseGrant(
      origin: origin,
      plan: GrantPlan.parse(json['plano']) ?? GrantPlan.lifetime,
      until: _date(json['ate']),
      givenAt: _date(json['dadoEm']),
      revokedAt: _date(json['revogadoEm']),
    );
  }

  Map<String, Object?> toJson() => {
    'origem': origin.wire,
    'plano': plan.wire,
    if (until != null) 'ate': until!.toIso8601String(),
    if (givenAt != null) 'dadoEm': givenAt!.toIso8601String(),
    if (revokedAt != null) 'revogadoEm': revokedAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is CourseGrant &&
      other.origin == origin &&
      other.plan == plan &&
      other.until == until &&
      other.givenAt == givenAt &&
      other.revokedAt == revokedAt;

  @override
  int get hashCode => Object.hash(origin, plan, until, givenAt, revokedAt);
}

/// O documento `acessos/{uid}` lido pelo app: os cursos dados ou comprados e
/// quando a tela "Curso liberado" já apareceu (`vistos`). Com `bloqueio`
/// vigente (`ate` nulo ou futuro), nenhum curso abre (H-R5-39, Dúvida 8).
final class CourseGrants {
  const CourseGrants({
    this.courses = const {},
    this.seen = const {},
    this.blocked = false,
    this.blockedUntil,
  });

  static const empty = CourseGrants();

  final Map<String, CourseGrant> courses;
  final Map<String, DateTime> seen;

  /// Há `bloqueio` no documento; vale até [blockedUntil] (nulo: sem fim).
  final bool blocked;
  final DateTime? blockedUntil;

  bool blockedAt(DateTime now) =>
      blocked && (blockedUntil == null || now.isBefore(blockedUntil!));

  /// O acesso que vale agora para [courseId]; nulo se não tem, acabou ou a
  /// conta está bloqueada.
  CourseGrant? active(String courseId, DateTime now) {
    if (blockedAt(now)) return null;
    final grant = courses[courseId];
    return grant != null && grant.activeAt(now) ? grant : null;
  }

  /// "Curso liberado" ainda não apareceu para este acesso: nunca viu, ou o
  /// curso foi dado de novo depois da última vez (H-R5-62).
  bool unseen(String courseId, DateTime now) {
    final grant = active(courseId, now);
    if (grant == null) return false;
    final seenAt = seen[courseId];
    if (seenAt == null) return true;
    final givenAt = grant.givenAt;
    return givenAt != null && seenAt.isBefore(givenAt);
  }

  CourseGrants markSeen(String courseId, DateTime at) => CourseGrants(
    courses: courses,
    seen: {...seen, courseId: at},
    blocked: blocked,
    blockedUntil: blockedUntil,
  );

  /// Aceita datas como `DateTime` (do serviço) ou texto ISO (da cópia).
  static CourseGrants fromJson(Map<String, Object?>? json) {
    if (json == null) return empty;
    final courses = <String, CourseGrant>{};
    final rawCourses = json['cursos'];
    if (rawCourses is Map) {
      for (final entry in rawCourses.entries) {
        final grant = CourseGrant.fromJson(entry.value);
        if (grant != null) courses['${entry.key}'] = grant;
      }
    }
    final seen = <String, DateTime>{};
    final rawSeen = json['vistos'];
    if (rawSeen is Map) {
      for (final entry in rawSeen.entries) {
        final at = _date(entry.value);
        if (at != null) seen['${entry.key}'] = at;
      }
    }
    final block = json['bloqueio'];
    return CourseGrants(
      courses: courses,
      seen: seen,
      blocked: block is Map,
      blockedUntil: block is Map ? _date(block['ate']) : null,
    );
  }

  Map<String, Object?> toJson() => {
    'cursos': {for (final e in courses.entries) e.key: e.value.toJson()},
    'vistos': {for (final e in seen.entries) e.key: e.value.toIso8601String()},
    if (blocked)
      'bloqueio': {
        if (blockedUntil != null) 'ate': blockedUntil!.toIso8601String(),
      },
  };

  @override
  bool operator ==(Object other) =>
      other is CourseGrants &&
      _mapEquals(other.courses, courses) &&
      _mapEquals(other.seen, seen) &&
      other.blocked == blocked &&
      other.blockedUntil == blockedUntil;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(courses.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(seen.entries.map((e) => (e.key, e.value))),
    blocked,
    blockedUntil,
  );
}

bool _mapEquals<V>(Map<String, V> a, Map<String, V> b) =>
    a.length == b.length &&
    a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);

DateTime? _date(Object? value) => switch (value) {
  final DateTime date => date,
  final String text => DateTime.tryParse(text),
  _ => null,
};
