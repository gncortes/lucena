import 'package:dartchess/dartchess.dart';

import 'clock.dart';
import 'endgame_position.dart';
import 'game_setup.dart';

/// De onde vem um final em destaque (o selo no cartão).
enum FeaturedOrigin {
  tournament,
  video,
  online,
  historical,
  challenge;

  static FeaturedOrigin? fromCode(String? code) => values.asNameMap()[code];
}

/// O que se faz no final: jogá-lo contra um adversário ou achar o lance.
enum FeaturedKind {
  play,
  findMove;

  static FeaturedKind fromCode(String? code) =>
      values.asNameMap()[code] ?? FeaturedKind.play;
}

/// O tipo do final, o rótulo do cartão.
enum FeaturedTheme {
  escapedWin,
  perfectConversion,
  resourcefulDefense,
  decisiveMistake;

  static FeaturedTheme? fromCode(String? code) => values.asNameMap()[code];
}

/// Um texto em vários idiomas. Falta o idioma: inglês; falta ele: o primeiro.
class LocalizedText {
  const LocalizedText(this.values);

  factory LocalizedText.fromJson(Object? json) {
    if (json is String) return LocalizedText({'en': json});
    if (json is! Map) return const LocalizedText({});
    return LocalizedText({
      for (final entry in json.entries)
        if (entry.value is String) entry.key as String: entry.value as String,
    });
  }

  final Map<String, String> values;

  String of(String language) =>
      values[language] ??
      values['en'] ??
      (values.isEmpty ? '' : values.values.first);

  bool get isEmpty => values.isEmpty;
}

/// Um jogador do livrinho.
class FeaturedPlayer {
  const FeaturedPlayer({
    required this.name,
    this.title,
    this.rating,
    this.country,
    this.fideId,
  });

  factory FeaturedPlayer.fromJson(Map<String, dynamic> json) => FeaturedPlayer(
    name: json['name'] as String,
    title: json['title'] as String?,
    rating: json['rating'] as int?,
    country: json['country'] as String?,
    fideId: json['fideId'] as int?,
  );

  final String name;

  /// GM, IM... Nulo quando não se sabe.
  final String? title;
  final int? rating;

  /// Código do país (ISO 3166-1 alfa-2).
  final String? country;

  /// O número no cadastro da FIDE; com ele, o nome abre o perfil.
  final int? fideId;

  Uri? get profile =>
      fideId == null ? null : Uri.https('ratings.fide.com', '/profile/$fideId');
}

/// Para que serve um link do torneio.
enum FeaturedLinkKind {
  results,
  broadcast,
  info;

  static FeaturedLinkKind fromCode(String? code) =>
      values.asNameMap()[code] ?? FeaturedLinkKind.info;
}

class FeaturedLink {
  const FeaturedLink({required this.kind, required this.url});

  factory FeaturedLink.fromJson(Map<String, dynamic> json) => FeaturedLink(
    kind: FeaturedLinkKind.fromCode(json['kind'] as String?),
    url: Uri.parse(json['url'] as String),
  );

  final FeaturedLinkKind kind;
  final Uri url;
}

/// O torneio de onde saem os finais.
class FeaturedTournament {
  const FeaturedTournament({
    required this.id,
    required this.name,
    required this.year,
    this.nameEn,
    this.place,
    this.placeEn,
    this.country,
    this.startsOn,
    this.endsOn,
    this.summary = const LocalizedText({}),
    this.links = const [],
  });

  factory FeaturedTournament.fromJson(Map<String, dynamic> json) =>
      FeaturedTournament(
        id: json['id'] as String,
        name: json['name'] as String,
        nameEn: json['name_en'] as String?,
        year: json['year'] as int,
        place: json['place'] as String?,
        placeEn: json['place_en'] as String?,
        country: json['country'] as String?,
        startsOn: _date(json['startsOn']),
        endsOn: _date(json['endsOn']),
        summary: LocalizedText.fromJson(json['summary']),
        links: [
          for (final link in (json['links'] as List? ?? const []))
            FeaturedLink.fromJson(link as Map<String, dynamic>),
        ],
      );

  final String id;
  final String name;
  final String? nameEn;
  final int year;
  final String? place;
  final String? placeEn;

  /// O país onde acontece (ISO 3166-1 alfa-2). Nulo quando não se sabe.
  final String? country;

  /// As datas, quando se sabem: com elas, o torneio pode estar em andamento.
  final DateTime? startsOn;
  final DateTime? endsOn;
  final LocalizedText summary;
  final List<FeaturedLink> links;

  String nameIn(String language) => language == 'pt' ? name : nameEn ?? name;

  String? placeIn(String language) =>
      language == 'pt' ? place : placeEn ?? place;

  /// Em andamento em [now]: entre o primeiro e o último dia.
  bool isOngoing(DateTime now) {
    final start = startsOn;
    final end = endsOn;
    if (start == null || end == null) return false;
    final last = DateTime(end.year, end.month, end.day + 1);
    return !now.isBefore(start) && now.isBefore(last);
  }

  Uri? link(FeaturedLinkKind kind) {
    for (final link in links) {
      if (link.kind == kind) return link.url;
    }
    return null;
  }
}

/// O adversário e o relógio de um final.
class FeaturedChoice {
  const FeaturedChoice({required this.opponent, this.level, this.clock});

  final OpponentKind opponent;

  /// O nível do Maia, quando ele é o adversário.
  final int? level;

  /// `segundos+incremento`; nulo é sem relógio.
  final String? clock;

  TimeControl? get time => TimeControl.tryParse(clock);

  FeaturedChoice copyWith({
    OpponentKind? opponent,
    int? level,
    String? clock,
    bool noClock = false,
  }) => FeaturedChoice(
    opponent: opponent ?? this.opponent,
    level: level ?? this.level,
    clock: noClock ? null : clock ?? this.clock,
  );

  @override
  bool operator ==(Object other) =>
      other is FeaturedChoice &&
      other.opponent == opponent &&
      other.level == level &&
      other.clock == clock;

  @override
  int get hashCode => Object.hash(opponent, level, clock);
}

/// Um final em destaque: uma posição de uma partida real, com o livrinho dela.
class FeaturedEndgame {
  const FeaturedEndgame({
    required this.id,
    required this.kind,
    required this.origin,
    required this.fen,
    required this.goal,
    required this.white,
    required this.black,
    required this.suggested,
    this.theme,
    this.tournamentId,
    this.round,
    this.result,
    this.publishedOn,
    this.playerCanChange = false,
    this.solutions = const [],
    this.title = const LocalizedText({}),
    this.hook = const LocalizedText({}),
    this.hint = const LocalizedText({}),
    this.whatHappened = const LocalizedText({}),
    this.gameUrl,
    this.lessonId,
    this.similarCategory,
  });

  factory FeaturedEndgame.fromJson(Map<String, dynamic> json) {
    final goal = PositionGoal.fromCode(json['goal'] as String?);
    return FeaturedEndgame(
      id: json['id'] as String,
      kind: FeaturedKind.fromCode(json['kind'] as String?),
      origin:
          FeaturedOrigin.fromCode(json['origin'] as String?) ??
          FeaturedOrigin.historical,
      theme: FeaturedTheme.fromCode(json['theme'] as String?),
      fen: json['fen'] as String,
      goal: goal ?? PositionGoal.draw,
      white: FeaturedPlayer.fromJson(json['white'] as Map<String, dynamic>),
      black: FeaturedPlayer.fromJson(json['black'] as Map<String, dynamic>),
      tournamentId: json['tournament'] as String?,
      round: json['round'] as int?,
      result: json['result'] as String?,
      publishedOn: _date(json['publishedOn']),
      playerCanChange: json['playerCanChange'] as bool? ?? false,
      solutions: [
        for (final move in (json['solutions'] as List? ?? const []))
          move as String,
      ],
      suggested: FeaturedChoice(
        opponent: OpponentKind.trainingFromCode(json['opponent'] as String?),
        level: json['level'] as int?,
        clock: json['clock'] as String?,
      ),
      title: LocalizedText.fromJson(json['title']),
      hook: LocalizedText.fromJson(json['hook']),
      hint: LocalizedText.fromJson(json['hint']),
      whatHappened: LocalizedText.fromJson(json['whatHappened']),
      gameUrl: json['gameUrl'] == null
          ? null
          : Uri.parse(json['gameUrl'] as String),
      lessonId: json['lesson'] as String?,
      similarCategory: json['similar'] as String?,
    );
  }

  final String id;
  final FeaturedKind kind;
  final FeaturedOrigin origin;
  final FeaturedTheme? theme;
  final String fen;
  final PositionGoal goal;
  final FeaturedPlayer white;
  final FeaturedPlayer black;
  final String? tournamentId;
  final int? round;

  /// `1-0`, `1/2-1/2`, `0-1`. Nulo quando não se sabe.
  final String? result;
  final DateTime? publishedOn;

  /// O adversário e o relógio podem ser trocados desde a primeira vez (é uma
  /// sugestão). Falso: são o que o final pede, até a primeira tentativa.
  final bool playerCanChange;

  /// Os lances que resolvem o "ache o lance", em UCI.
  final List<String> solutions;

  /// O adversário e o relógio que o final traz.
  final FeaturedChoice suggested;
  final LocalizedText title;
  final LocalizedText hook;

  /// A dica do "ache o lance", quando a posição pede uma própria (a genérica
  /// fala de peça, e aqui só há reis). Vazia: a dica pela peça do lance.
  final LocalizedText hint;

  /// O que aconteceu na partida, em texto: só aparece depois de aberto.
  final LocalizedText whatHappened;
  final Uri? gameUrl;

  /// A aula de final ligada a este final.
  final String? lessonId;

  /// A categoria do catálogo com finais parecidos.
  final String? similarCategory;

  /// O lado do jogador: o que tem a vez na posição.
  Side get userSide => fen.split(' ')[1] == 'b' ? Side.black : Side.white;

  bool get isFindMove => kind == FeaturedKind.findMove;

  /// O final é novo para quem ainda não o jogou, até [days] dias depois de
  /// publicado.
  bool isNew(DateTime now, {int days = 30}) {
    final published = publishedOn;
    if (published == null) return false;
    final age = now.difference(published);
    return !age.isNegative && age < Duration(days: days);
  }
}

/// A lista que o repositório devolve.
class FeaturedCatalog {
  const FeaturedCatalog({this.tournaments = const [], this.finals = const []});

  static const empty = FeaturedCatalog();

  factory FeaturedCatalog.fromJson(Map<String, dynamic> json) =>
      FeaturedCatalog(
        tournaments: [
          for (final each in (json['tournaments'] as List? ?? const []))
            FeaturedTournament.fromJson(each as Map<String, dynamic>),
        ],
        finals: [
          for (final each in (json['finals'] as List? ?? const []))
            FeaturedEndgame.fromJson(each as Map<String, dynamic>),
        ],
      );

  final List<FeaturedTournament> tournaments;
  final List<FeaturedEndgame> finals;

  FeaturedEndgame? endgame(String id) {
    for (final each in finals) {
      if (each.id == id) return each;
    }
    return null;
  }

  FeaturedTournament? tournament(String? id) {
    if (id == null) return null;
    for (final each in tournaments) {
      if (each.id == id) return each;
    }
    return null;
  }

  List<FeaturedEndgame> finalsOf(String tournamentId) => [
    for (final each in finals)
      if (each.tournamentId == tournamentId) each,
  ];
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
