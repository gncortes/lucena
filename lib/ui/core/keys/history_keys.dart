import 'package:flutter/widgets.dart';

/// O Histórico em abas: Partidas, Clássico e Maratona. As do cartão do
/// rating e das linhas de partida continuam em `RatingKeys`.
abstract final class HistoryKeys {
  static const screen = Key('history.screen');
  static const loading = Key('history.loading');

  /// A aba: 0 Partidas, 1 Clássico, 2 Maratona.
  static Key tab(int index) => Key('history.tab.$index');

  /// O chip de filtro: `all` (o botão `tune`), `period`, `result`, `pace`,
  /// `level`.
  static Key filterChip(String name) => Key('history.filter.chip.$name');

  /// A folha de filtros, cada opção dela (`grupo`, `valor`), o Limpar e o
  /// botão que aplica.
  static const filterSheet = Key('history.filter.sheet');
  static Key filterOption(String group, String value) =>
      Key('history.filter.option.$group.$value');
  static const filterClear = Key('history.filter.clear');
  static const filterApply = Key('history.filter.apply');

  /// Uma coluna do placar (0 a 2) e o cabeçalho de um mês (Partidas).
  static Key score(int index) => Key('history.score.$index');
  static Key month(int index) => Key('history.month.$index');

  /// O cabeçalho de um nível (Clássico e Maratona).
  static Key group(int index) => Key('history.group.$index');

  /// Uma linha de speedrun (índice na aba), a situação dela e o "+N" do
  /// bônus de rating.
  static Key row(int index) => Key('history.row.$index');
  static Key rowStatus(int index) => Key('history.row.$index.status');
  static Key rowBonus(int index) => Key('history.row.$index.bonus');

  /// A aba sem nada jogado e a sem resultado do filtro (com o botão de
  /// limpar).
  static const empty = Key('history.empty');
  static const emptyFiltered = Key('history.empty.filtered');
  static const emptyClear = Key('history.empty.clear');
}
