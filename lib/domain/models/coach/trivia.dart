/// Uma curiosidade de xadrez da tela de espera da análise.
final class Trivia {
  const Trivia({required this.id, required this.motif, required this.text});

  final String id;
  final String motif;
  final String text;

  static Trivia? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], text = json['texto'];
    if (id is! String || text is! String || text.isEmpty) return null;
    final motif = json['tema'];
    return Trivia(id: id, motif: motif is String ? motif : '', text: text);
  }
}
