import '../models/challenge_link.dart';

/// Como o fim de um desafio de link oferece a aula ligada (T84).
enum LinkLessonOffer {
  /// Sem aula ligada: o fim de sempre (jogar de novo, compartilhar, conhecer
  /// o app).
  none,

  /// Não conseguiu (perdeu, ou empatou quando era para ganhar): a aula é o
  /// botão principal.
  primary,

  /// Conseguiu: os parabéns e a aula como botão secundário.
  secondary;

  /// O `destaque` do Analytics.
  String get code => switch (this) {
    LinkLessonOffer.none => 'nenhum',
    LinkLessonOffer.primary => 'principal',
    LinkLessonOffer.secondary => 'secundaria',
  };
}

/// O próximo passo de quem tocou na aula oferecida.
enum LinkLessonStep {
  /// Sem conta: o convite de conta antes, e a aula no fim dele.
  invite,

  /// Já tem conta: a aula direto.
  lesson,

  /// A aula não existe ou não está liberada: a rota dela mostra a regra de
  /// sempre ("aula indisponível"), e o Analytics registra.
  unavailable,
}

/// As regras do link de campanha: o que o fim mostra e para onde a oferta
/// leva.
abstract final class LinkLessonRules {
  /// A oferta do fim da partida de [link], com o objetivo cumprido ou não
  /// ([fulfilled]; nulo enquanto a partida continua).
  static LinkLessonOffer offer(
    ChallengeLink? link, {
    required bool? fulfilled,
  }) {
    if (link?.lesson == null || fulfilled == null) return LinkLessonOffer.none;
    return fulfilled ? LinkLessonOffer.secondary : LinkLessonOffer.primary;
  }

  /// O passo depois do toque na oferta. A aula indisponível não pede conta.
  static LinkLessonStep next({
    required bool available,
    required bool hasAccount,
  }) {
    if (!available) return LinkLessonStep.unavailable;
    return hasAccount ? LinkLessonStep.lesson : LinkLessonStep.invite;
  }
}
