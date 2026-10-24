/// O tipo do push do painel (E1.19 3.8): escolhe o canal do Android e os
/// botões da notificação.
enum PushKind {
  /// Final em destaque (de torneio): canal "Finais de torneio".
  featured('destaque'),

  /// Final do dia.
  daily('dia'),

  /// Aula nova.
  lesson('aula'),

  /// Novidade do app.
  news('novidade'),

  /// Livre: o painel escolhe o texto e o destino.
  free('livre');

  const PushKind(this.code);

  /// O valor de `tipo` nos dados.
  final String code;

  static PushKind of(String? code) => PushKind.values.firstWhere(
    (kind) => kind.code == code,
    orElse: () => PushKind.free,
  );

  /// Tem o que jogar: a notificação ganha o botão "Jogar".
  bool get playable => this == featured || this == daily;
}

/// Os campos de `data` que a Function manda (P4). Com [title] e [body] o
/// push é "data-only" e o app monta a notificação (imagem grande e botões).
abstract final class PushData {
  static const link = 'link';
  static const kind = 'tipo';
  static const id = 'pushId';
  static const country = 'pais';
  static const title = 'titulo';
  static const body = 'texto';

  /// A imagem 2:1 (diagrama) e a miniatura quadrada, URLs do Storage. Sem
  /// miniatura, a imagem grande serve de miniatura.
  static const image = 'imagem';
  static const thumbnail = 'miniatura';

  /// O link do botão "Ver torneio" (`/featured/tournament/<id>`).
  static const tournament = 'torneio';
}

/// Os botões da notificação.
abstract final class PushActions {
  static const play = 'jogar';
  static const tournament = 'torneio';
}

/// Um push para o app mostrar como notificação própria.
class PushAlert {
  const PushAlert({
    required this.title,
    required this.body,
    this.id,
    this.kind = PushKind.free,
    this.link,
    this.tournament,
    this.country,
    this.image,
    this.thumbnail,
  });

  /// O push dos dados [data], com [title], [body] e [image] da parte
  /// `notification` quando vier (app aberto). Nulo sem título nem texto.
  static PushAlert? fromData(
    Map<String, String> data, {
    String? title,
    String? body,
    String? image,
  }) {
    final shownTitle = _filled(data[PushData.title]) ?? _filled(title);
    final shownBody = _filled(data[PushData.body]) ?? _filled(body);
    if (shownTitle == null && shownBody == null) return null;
    return PushAlert(
      title: shownTitle ?? '',
      body: shownBody ?? '',
      id: _filled(data[PushData.id]),
      kind: PushKind.of(data[PushData.kind]),
      link: _filled(data[PushData.link]),
      tournament: _filled(data[PushData.tournament]),
      country: _filled(data[PushData.country]),
      image: _filled(data[PushData.image]) ?? _filled(image),
      thumbnail: _filled(data[PushData.thumbnail]),
    );
  }

  static String? _filled(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  final String title;
  final String body;
  final String? id;
  final PushKind kind;
  final String? link;
  final String? tournament;
  final String? country;
  final String? image;
  final String? thumbnail;

  /// Os botões: "Jogar" quando há o que jogar e um link; "Ver torneio" com
  /// o link do torneio.
  List<String> get actions => [
    if (kind.playable && link != null) PushActions.play,
    if (tournament != null) PushActions.tournament,
  ];

  /// O número da notificação no Android: o mesmo push substitui a anterior.
  /// Fica acima de [firstNotificationId], longe dos lembretes locais.
  int get notificationId {
    final key = id ?? '$title|$body';
    // FNV-1a de 32 bits: igual em qualquer isolate (o hashCode não é).
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return firstNotificationId + hash % 1000000;
  }

  static const firstNotificationId = 1000000;

  /// O que a notificação guarda para o toque: o destino, o do torneio e o
  /// que o evento `push_aberto` conta.
  String get payload => Uri(
    scheme: PushOpening.scheme,
    queryParameters: {
      PushData.link: ?link,
      PushData.tournament: ?tournament,
      PushData.id: ?id,
      PushData.country: ?country,
    },
  ).toString();
}

/// Um push tocado: o destino e de qual envio e país ele veio.
class PushOpening {
  const PushOpening({this.link, this.pushId, this.country});

  /// O esquema do payload das notificações de push que o app mostra (as dos
  /// lembretes são rotas, sem esquema).
  static const scheme = 'lucena-push';

  /// O push tocado dos dados [data] (notificação do sistema).
  factory PushOpening.fromData(Map<String, String> data) => PushOpening(
    link: _uri(data[PushData.link]),
    pushId: PushAlert._filled(data[PushData.id]),
    country: PushAlert._filled(data[PushData.country]),
  );

  /// Se [payload] é de uma notificação de push (e não de um lembrete).
  static bool isPush(String? payload) =>
      payload != null && payload.startsWith('$scheme:');

  /// O toque na notificação de [payload]; com [action] `torneio`, o destino
  /// é o torneio. Nulo: não é de push.
  static PushOpening? fromPayload(String? payload, {String? action}) {
    if (!isPush(payload)) return null;
    final Map<String, String> query;
    try {
      query = Uri.parse(payload!).queryParameters;
    } on FormatException {
      return null;
    }
    final tournament = action == PushActions.tournament
        ? query[PushData.tournament]
        : null;
    return PushOpening(
      link: _uri(tournament ?? query[PushData.link]),
      pushId: PushAlert._filled(query[PushData.id]),
      country: PushAlert._filled(query[PushData.country]),
    );
  }

  static Uri? _uri(String? link) =>
      link == null || link.isEmpty ? null : Uri.tryParse(link);

  /// O endereço que o toque abre. Nulo: o push não tinha link (abre o app).
  final Uri? link;
  final String? pushId;
  final String? country;

  @override
  bool operator ==(Object other) =>
      other is PushOpening &&
      other.link == link &&
      other.pushId == pushId &&
      other.country == country;

  @override
  int get hashCode => Object.hash(link, pushId, country);

  @override
  String toString() => 'PushOpening($link, $pushId, $country)';
}

/// Os textos do app na notificação: o nome de cada canal (também o texto ao
/// lado de "Lucena" no cabeçalho) e os botões.
class PushTexts {
  const PushTexts({
    required this.tournaments,
    required this.daily,
    required this.lessons,
    required this.news,
    required this.play,
    required this.tournament,
  });

  final String tournaments;
  final String daily;
  final String lessons;
  final String news;
  final String play;
  final String tournament;

  /// O canal de [kind]: id fixo e nome no idioma do app.
  ({String id, String name}) channel(PushKind kind) => switch (kind) {
    PushKind.featured => (id: 'push_torneios_quieto', name: tournaments),
    PushKind.daily => (id: 'push_dia_quieto', name: daily),
    PushKind.lesson => (id: 'push_aulas_quieto', name: lessons),
    PushKind.news || PushKind.free => (id: 'push_novidades_quieto', name: news),
  };

  /// O rótulo do botão [action].
  String action(String action) =>
      action == PushActions.tournament ? tournament : play;
}
