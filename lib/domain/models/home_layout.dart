/// Um caminho da tela inicial: o que dá para fazer no Lucena.
enum HomePath {
  /// As aulas do Viktor.
  learn,

  /// A Jornada, do Coco ao Stockfish.
  journey,

  /// As aulas de finais.
  endgames,

  /// O speedrun.
  speedrun,

  /// Os finais avulsos do catálogo.
  train;

  static HomePath? fromCode(Object? code) => values.asNameMap()[code];
}

/// Os caminhos da tela inicial: todos, na ordem, e os que aparecem. Os
/// outros ficam em "Outros modos", nunca inacessíveis.
class HomeLayout {
  const HomeLayout({
    required this.order,
    required this.visible,
    this.custom = false,
  });

  /// Os cinco caminhos, na ordem da tela.
  final List<HomePath> order;

  /// Os que aparecem em destaque. Nunca vazio.
  final Set<HomePath> visible;

  /// O jogador mexeu: a sugestão do nível não muda mais o layout.
  final bool custom;

  /// Os caminhos em destaque, na ordem.
  List<HomePath> get shown => [
    for (final path in order)
      if (visible.contains(path)) path,
  ];

  /// Os escondidos (em "Outros modos"), na ordem.
  List<HomePath> get hidden => [
    for (final path in order)
      if (!visible.contains(path)) path,
  ];

  HomeLayout copyWith({
    List<HomePath>? order,
    Set<HomePath>? visible,
    bool? custom,
  }) => HomeLayout(
    order: order ?? this.order,
    visible: visible ?? this.visible,
    custom: custom ?? this.custom,
  );

  Map<String, Object?> toJson() => {
    'order': [for (final path in order) path.name],
    'visible': [
      for (final path in order)
        if (visible.contains(path)) path.name,
    ],
    'custom': custom,
  };

  /// O layout gravado. Caminho que falta (versão nova) vai para o fim,
  /// escondido; sem nenhum visível, o primeiro aparece. Nulo se não dá para
  /// ler.
  static HomeLayout? fromJson(Object? json) {
    if (json is! Map) return null;
    final rawOrder = json['order'];
    final rawVisible = json['visible'];
    if (rawOrder is! List || rawVisible is! List) return null;
    // Sem repetidos, na ordem gravada.
    final order = <HomePath>[];
    for (final code in rawOrder) {
      final path = HomePath.fromCode(code);
      if (path != null && !order.contains(path)) order.add(path);
    }
    for (final path in HomePath.values) {
      if (!order.contains(path)) order.add(path);
    }
    final visible = {for (final code in rawVisible) ?HomePath.fromCode(code)};
    return HomeLayout(
      order: order,
      visible: visible.isEmpty ? {order.first} : visible,
      custom: json['custom'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HomeLayout &&
      other.custom == custom &&
      _sameList(other.order, order) &&
      other.visible.length == visible.length &&
      other.visible.containsAll(visible);

  static bool _sameList(List<HomePath> a, List<HomePath> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    custom,
    Object.hashAll(order),
    Object.hashAllUnordered(visible),
  );
}
