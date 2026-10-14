import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/school/lesson_source.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson_script.dart';

part 'lesson_script_state.freezed.dart';

/// Em que pé está a tela do roteiro (tabela 7.1 do contrato T70).
enum ScriptPhase {
  entrada,
  pergunta,
  refutacao,
  livrePerdido,
  livreMantido,
  livreFim,
  linha,
  fimExemplo,
  fimEtapa,
  praticaVez,
  praticaFim,
}

/// O que um botão faz.
enum ScriptAction {
  /// Próximo trecho, passo ou exemplo.
  continuar,

  /// Abre a próxima etapa.
  proximaEtapa,

  /// Volta à pergunta (jogo livre) ou recomeça a prática.
  voltarInicio,

  /// Mostra a resposta da pergunta.
  verResposta,

  /// Volta à etapa 1 (fim da prática).
  reverIdeia,

  /// Conclui a parte e abre a próxima.
  proximaParte,
}

/// A cor do balão: neutro, certo ou errado (feedback da prática e do jogo
/// livre).
enum ScriptTone { neutral, good, bad }

/// Como o tabuleiro vai da posição anterior à nova.
enum TransitionKind {
  /// Só mostra a posição.
  none,

  /// Anima um lance (`ucis` tem um).
  move,

  /// Anima lances rápidos, 300 ms cada.
  seq,

  /// Corte com esmaecer (200 ms); se `ucis` não é vazio, anima-os depois.
  jump,

  /// A peça volta animando (`ucis` são os lances desfeitos).
  back,
}

/// A mudança de posição que o tabuleiro deve animar. Muda de [id] a cada
/// emissão nova: a tela só anima quando o [id] é outro.
class ScriptTransition {
  const ScriptTransition({
    required this.id,
    this.kind = TransitionKind.none,
    this.fromFen,
    this.ucis = const [],
  });

  final int id;
  final TransitionKind kind;

  /// A posição de onde a animação parte.
  final String? fromFen;
  final List<String> ucis;
}

/// Um lance da lista de lances.
class ScriptMoveEntry {
  const ScriptMoveEntry({
    required this.id,
    required this.san,
    required this.number,
    required this.side,
    required this.variant,
  });

  /// A chave `LessonScriptKeys.move(id)`; é o que `goToMove` recebe.
  final String id;
  final String san;

  /// O número do lance completo.
  final int number;
  final Side side;

  /// Variante (alternativo), em linha cinza recuada.
  final bool variant;
}

/// A folha Curiosidades já com as falas e as referências resolvidas.
class ScriptCuriosities {
  const ScriptCuriosities({
    required this.text,
    this.quote,
    this.quoteAuthor,
    this.references = const [],
  });

  final String text;
  final String? quote;
  final String? quoteAuthor;
  final List<Reference> references;
}

@freezed
abstract class LessonScriptState with _$LessonScriptState {
  const factory LessonScriptState({
    /// Falso até o roteiro, as falas e a tabela carregarem.
    @Default(false) bool ready,
    @Default(0) int stageIndex,
    @Default(1) int stageCount,

    /// `ideia`, `demos` ou `pratica`.
    @Default('') String stageId,
    @Default(0) int exampleIndex,
    @Default(1) int exampleCount,
    @Default(ScriptPhase.entrada) ScriptPhase phase,

    /// A posição do tabuleiro.
    @Default('') String fen,

    /// O lado que fica embaixo (e o lado do aluno).
    @Default(Side.white) Side orientation,

    /// O último lance (UCI), para destacar.
    String? lastMove,

    /// Os balões, já com o texto. Mais de um quando os trechos cabem juntos.
    @Default(<String>[]) List<String> speech,
    @Default(ScriptTone.neutral) ScriptTone tone,
    @Default(<String>[]) List<String> marks,
    @Default(<ScriptArrow>[]) List<ScriptArrow> arrows,

    /// O botão principal e o secundário. Nulos: não aparece.
    ScriptAction? primary,
    ScriptAction? secondary,

    /// O ◀ está ativo.
    @Default(false) bool canBack,

    /// O lado que pode mexer peças agora. Nulo: o tabuleiro não aceita toque.
    Side? movable,

    /// A máquina está para responder.
    @Default(false) bool machineThinking,

    /// Os lances já vistos, na ordem da lista, e o atual.
    @Default(<ScriptMoveEntry>[]) List<ScriptMoveEntry> moves,
    String? currentMoveId,
    @Default(ScriptTransition(id: 0)) ScriptTransition transition,

    /// A folha Curiosidades do exemplo; nula se não tem (esconde o livro).
    ScriptCuriosities? curiosities,

    /// Preenchido quando a parte foi concluída (`finishPart`).
    LessonOutcome? outcome,
  }) = _LessonScriptState;
}
