import '../models/character.dart';
import 'emotion_state.dart';
import 'game_events.dart';

/// Escolhe a fala do personagem para os eventos de um momento da partida.
class LinePicker {
  const LinePicker._();

  /// Lances mínimos entre duas falas, para não virar ruído.
  static const minMovesBetweenLines = 2;

  /// Categorias que falam mesmo antes de [minMovesBetweenLines].
  static const priority = {
    LineCategory.gameStart,
    LineCategory.win,
    LineCategory.loss,
    LineCategory.draw,
    LineCategory.ownBlunder,
    LineCategory.opponentBlunder,
    LineCategory.comeback,
    LineCategory.collapse,
    LineCategory.ownPromotion,
    LineCategory.opponentPromotion,
  };

  /// A fala para o primeiro evento de [events] (já em ordem de importância)
  /// que tenha o que dizer, e a memória atualizada; null se nada a dizer.
  ///
  /// Não repete fala na partida enquanto houver outra da categoria; esgotadas,
  /// repete, mas nunca a mesma duas vezes seguidas. Prefere a intensidade do
  /// evento (ou a mais próxima) e a emoção do momento. [roll] (de 0 a 1)
  /// sorteia entre as que sobram.
  ///
  /// As falas de ex-aluno só valem com [student], e aí vêm na frente das
  /// outras da categoria.
  static ({CharacterLine line, TalkMemory memory})? pick({
    required List<CharacterLine> lines,
    required List<GameEvent> events,
    required TalkMemory memory,
    required double roll,
    bool student = false,
  }) {
    final emotion = EmotionRules.of(memory);
    for (final event in events) {
      if (!priority.contains(event.category) &&
          memory.movesSinceLine < minMovesBetweenLines) {
        continue;
      }
      var ofCategory = [
        for (final l in lines)
          if (l.category == event.category &&
              (student || l.audience != LineAudience.student))
            l,
      ];
      if (student) {
        final forStudent = [
          for (final l in ofCategory)
            if (l.audience == LineAudience.student &&
                !memory.spoken.contains(l.id))
              l,
        ];
        if (forStudent.isNotEmpty) ofCategory = forStudent;
      }
      var pool = [
        for (final l in ofCategory)
          if (!memory.spoken.contains(l.id)) l,
      ];
      if (pool.isEmpty) {
        pool = [
          for (final l in ofCategory)
            if (l.id != memory.lastLineId) l,
        ];
      }
      if (pool.isEmpty) continue;

      final nearest = pool
          .map((l) => (l.intensity - event.intensity).abs())
          .reduce((a, b) => a < b ? a : b);
      pool = [
        for (final l in pool)
          if ((l.intensity - event.intensity).abs() == nearest) l,
      ];
      final feeling = [
        for (final l in pool)
          if (l.emotion == emotion) l,
      ];
      if (feeling.isNotEmpty) pool = feeling;

      final index = (roll.clamp(0.0, 1.0) * pool.length).floor().clamp(
        0,
        pool.length - 1,
      );
      final line = pool[index];
      return (
        line: line,
        memory: memory.copyWith(
          spoken: memory.spoken.contains(line.id)
              ? memory.spoken
              : [...memory.spoken, line.id],
          lastLineId: line.id,
          emotion: emotion,
          movesSinceLine: 0,
          onceFlags: GameEvents.onceCategories.contains(line.category)
              ? {...memory.onceFlags, line.category.name}
              : memory.onceFlags,
        ),
      );
    }
    return null;
  }

  /// A memória depois de mais um lance.
  static TalkMemory moved(TalkMemory m) =>
      m.copyWith(movesSinceLine: m.movesSinceLine + 1);
}
