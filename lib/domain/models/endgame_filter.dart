import 'dart:convert';

import 'rating_level.dart';

/// A situação de uma aula de final na trilha.
enum EndgameLessonStatus {
  /// Nada feito ainda.
  open,

  /// A lição foi feita ou há exercícios resolvidos, mas a nota não passou.
  started,

  /// Lição feita e nota mínima alcançada.
  passed,
}

/// O tipo de final, pelo material do treino final da aula. Uma aula pode ter
/// mais de um tipo (dama contra torre é final de dama e de torre).
enum EndgameKind {
  /// Só reis e peões.
  pawn,
  queen,
  rook,
  bishop,
  knight,

  /// Bispo ou cavalo, sem dama nem torre.
  minor,
}

/// A ordem da lista de aulas de finais.
enum EndgameSort {
  /// A ordem da trilha, por módulo.
  trail,

  /// Das mais fáceis às mais difíceis, pela faixa de rating da aula.
  easiest,
}

/// Os filtros da lista de aulas de finais. Dentro de um grupo, vale
/// qualquer uma das opções marcadas; entre grupos, todas precisam valer.
class EndgameFilter {
  const EndgameFilter({
    this.kinds = const {},
    this.levels = const {},
    this.statuses = const {},
    this.sort = EndgameSort.trail,
  });

  /// Lê o gravado; o que não se entende fica de fora.
  factory EndgameFilter.fromCode(String? code) {
    if (code == null || code.isEmpty) return const EndgameFilter();
    try {
      final json = jsonDecode(code) as Map<String, dynamic>;
      Set<T> parse<T extends Enum>(String key, List<T> values) => {
        for (final name in json[key] as List? ?? const [])
          ?values.asNameMap()[name],
      };
      return EndgameFilter(
        kinds: parse('kinds', EndgameKind.values),
        levels: parse('levels', RatingLevel.values),
        statuses: parse('statuses', EndgameLessonStatus.values),
        sort: EndgameSort.values.asNameMap()[json['sort']] ?? EndgameSort.trail,
      );
    } on FormatException {
      return const EndgameFilter();
    } on TypeError {
      return const EndgameFilter();
    }
  }

  final Set<EndgameKind> kinds;
  final Set<RatingLevel> levels;
  final Set<EndgameLessonStatus> statuses;
  final EndgameSort sort;

  /// Nenhum filtro nem ordem diferente da trilha.
  bool get isEmpty =>
      kinds.isEmpty &&
      levels.isEmpty &&
      statuses.isEmpty &&
      sort == EndgameSort.trail;

  /// Quantas opções estão marcadas (a ordem conta uma).
  int get count =>
      kinds.length +
      levels.length +
      statuses.length +
      (sort == EndgameSort.trail ? 0 : 1);

  /// Se uma aula passa pelos filtros (a ordem não filtra nada). Uma aula sem
  /// faixa conhecida não passa quando há faixa marcada.
  bool matches({
    required Set<EndgameKind> kinds,
    required RatingLevel? level,
    required EndgameLessonStatus status,
  }) =>
      (this.kinds.isEmpty || this.kinds.any(kinds.contains)) &&
      (levels.isEmpty || (level != null && levels.contains(level))) &&
      (statuses.isEmpty || statuses.contains(status));

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  EndgameFilter toggleKind(EndgameKind kind) => EndgameFilter(
    kinds: _toggle(kinds, kind),
    levels: levels,
    statuses: statuses,
    sort: sort,
  );

  EndgameFilter toggleLevel(RatingLevel level) => EndgameFilter(
    kinds: kinds,
    levels: _toggle(levels, level),
    statuses: statuses,
    sort: sort,
  );

  EndgameFilter toggleStatus(EndgameLessonStatus status) => EndgameFilter(
    kinds: kinds,
    levels: levels,
    statuses: _toggle(statuses, status),
    sort: sort,
  );

  EndgameFilter withSort(EndgameSort sort) => EndgameFilter(
    kinds: kinds,
    levels: levels,
    statuses: statuses,
    sort: sort,
  );

  /// O texto gravado nas preferências.
  String get code => jsonEncode({
    'kinds': [
      for (final kind in EndgameKind.values)
        if (kinds.contains(kind)) kind.name,
    ],
    'levels': [
      for (final level in RatingLevel.values)
        if (levels.contains(level)) level.name,
    ],
    'statuses': [
      for (final status in EndgameLessonStatus.values)
        if (statuses.contains(status)) status.name,
    ],
    'sort': sort.name,
  });

  @override
  bool operator ==(Object other) =>
      other is EndgameFilter && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
