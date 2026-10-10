import 'dart:math';
import 'dart:ui';

/// A geometria do modo exercício da lição (T60), em contas puras: o
/// tabuleiro centralizado no espaço que sobra enquanto o aluno resolve, e no
/// alto, com a folha da fala embaixo, depois da resposta.
abstract final class ExerciseLayout {
  /// A margem de cada lado do tabuleiro.
  static const gutter = 8.0;

  /// O menor tabuleiro que ainda se joga.
  static const minBoard = 120.0;

  /// O maior tabuleiro que cabe em [area], descontados o cabeçalho (o
  /// enunciado) e o rodapé (o cronômetro e as ações), com a margem em volta.
  static double boardSize(Size area, {double header = 0, double footer = 0}) {
    final width = area.width - 2 * gutter;
    final height = area.height - header - footer - 2 * gutter;
    return max(min(width, height), minBoard);
  }

  /// Onde o tabuleiro fica enquanto o aluno resolve: centralizado na
  /// horizontal e, na vertical, com o centro em [centerY] (o centro da tela,
  /// nas coordenadas da área). Se ali ele cobriria o cabeçalho ou o rodapé,
  /// desce ou sobe só o necessário; sem [centerY], fica no meio do espaço
  /// livre entre os dois.
  static Rect solvingRect(
    Size area, {
    double header = 0,
    double footer = 0,
    double? centerY,
  }) {
    final size = boardSize(area, header: header, footer: footer);
    final free = area.height - header - footer;
    final top = header + (free - size) / 2;
    final wanted = centerY == null ? top : centerY - size / 2;
    final lowest = area.height - footer - gutter - size;
    final highest = header + gutter;
    return Rect.fromLTWH(
      (area.width - size) / 2,
      lowest < highest ? top : wanted.clamp(highest, lowest),
      size,
      size,
    );
  }

  /// Onde ele fica depois da resposta: no alto, encolhendo se precisar, para
  /// deixar [sheetRoom] para a folha da fala. Com [lowered] (a escola), ele
  /// desce o quanto a folha deixar, para ficar perto de onde estava enquanto
  /// o aluno resolvia: o tabuleiro quase não sai do lugar entre os passos.
  static Rect explainingRect(
    Size area, {
    required double sheetRoom,
    bool lowered = false,
  }) {
    final size = max(
      min(area.width - 2 * gutter, area.height - sheetRoom),
      minBoard,
    );
    final top = lowered ? max(gutter, area.height - sheetRoom - size) : gutter;
    return Rect.fromLTWH((area.width - size) / 2, top, size, size);
  }
}

/// A altura do enunciado ao abrir o passo ou exercício [stepKey]: o
/// tabuleiro se posiciona por ela e não sai mais do lugar dentro dele. Uma
/// fala maior depois (dica, correção) cresce para o espaço livre acima do
/// tabuleiro e rola se não couber. Recomeça no próximo passo.
class HeaderMemo {
  String? stepKey;
  String? _heldFor;
  double _height = 0;

  /// A altura guardada para o passo aberto; nula se ele acabou de abrir.
  double? get held => _heldFor == stepKey ? _height : null;

  /// Guarda a altura medida ao abrir o passo.
  void hold(double measured) {
    _heldFor = stepKey;
    _height = measured;
  }
}
