import '../models/challenge_link.dart';
import '../models/endgame_lesson.dart';
import '../models/lesson.dart';
import '../models/push_alert.dart';
import '../models/star_challenge.dart';

/// O que o app leu na abertura, já sem repositório: a tela que estava aberta
/// quando ele fechou, o link ou o aviso que o abriu e o conteúdo publicado.
class LaunchFacts {
  const LaunchFacts({
    this.conclusion,
    this.resumeGame = false,
    this.resumeBlind = false,
    this.school = const SchoolProgress(),
    this.endgames = const EndgameProgress(),
    this.stars,
    this.onboardingDone = false,
    this.boardControlsOpen = false,
    this.goalAnswered = false,
    this.consentUid,
    this.accountUid,
    this.opened,
    this.openedInvalid = false,
    this.openedChallenge,
    this.pushOpening,
    this.pushedChallenge,
    this.fromReferrer = false,
    this.showSchool = true,
    this.visibleEndgameLessons = const {},
    this.schoolLessonFound,
    this.trailLessons,
  });

  /// A conclusão que ficou por mostrar.
  final int? conclusion;

  /// A partida gravada reabre na abertura.
  final bool resumeGame;

  /// Há partida às cegas gravada.
  final bool resumeBlind;
  final SchoolProgress school;
  final EndgameProgress endgames;
  final OpenStarChallenge? stars;
  final bool onboardingDone;
  final bool boardControlsOpen;

  /// Já respondeu "O que você quer fazer?" (o perfil tem objetivo).
  final bool goalAnswered;

  /// A conta com o aceite dos Termos pendente, e a conta conectada agora.
  final String? consentUid;
  final String? accountUid;

  /// O link que abriu o app (ou o do post que levou à Play).
  final Uri? opened;

  /// [opened] é um link do app que esta versão não abre.
  final bool openedInvalid;

  /// O desafio de [opened], se é link de desafio.
  final ChallengeLink? openedChallenge;

  /// O aviso de push tocado com o app fechado.
  final PushOpening? pushOpening;

  /// O desafio do link do aviso, se é link de desafio.
  final ChallengeLink? pushedChallenge;

  /// [opened] veio do referrer da instalação (T84).
  final bool fromReferrer;

  /// A Escola e as aulas de final que esta versão mostra.
  final bool showSchool;
  final Set<String> visibleEndgameLessons;

  /// A aula da Escola em andamento existe no pacote. Nulo: não foi conferida.
  final bool? schoolLessonFound;

  /// As aulas de final do pacote (vazio: pacote indisponível). Nulo: não foi
  /// conferido.
  final Set<String>? trailLessons;

  LaunchFacts withContent({
    bool? schoolLessonFound,
    Set<String>? trailLessons,
  }) => LaunchFacts(
    conclusion: conclusion,
    resumeGame: resumeGame,
    resumeBlind: resumeBlind,
    school: school,
    endgames: endgames,
    stars: stars,
    onboardingDone: onboardingDone,
    boardControlsOpen: boardControlsOpen,
    goalAnswered: goalAnswered,
    consentUid: consentUid,
    accountUid: accountUid,
    opened: opened,
    openedInvalid: openedInvalid,
    openedChallenge: openedChallenge,
    pushOpening: pushOpening,
    pushedChallenge: pushedChallenge,
    fromReferrer: fromReferrer,
    showSchool: showSchool,
    visibleEndgameLessons: visibleEndgameLessons,
    schoolLessonFound: schoolLessonFound ?? this.schoolLessonFound,
    trailLessons: trailLessons ?? this.trailLessons,
  );
}

/// O que fazer depois que a primeira tela abre, pelo aviso tocado.
enum LaunchFollowUp {
  /// Nada.
  none,

  /// "Abrindo o seu presente…" por cima (H-R5-63).
  gift,

  /// A tela do link do aviso (que não é desafio) por cima.
  pushedScreen,
}

/// Onde o app abre e o que vem depois.
class LaunchDestination {
  const LaunchDestination({
    required this.facts,
    required this.link,
    required this.uri,
    required this.consentPending,
    required this.showSchool,
    required this.visibleEndgameLessons,
    required this.invalidLinkOnTop,
    required this.followUp,
  });

  final LaunchFacts facts;

  /// O desafio que abre (do link ou do aviso).
  final ChallengeLink? link;

  /// O link do app que abre a tela dele.
  final Uri? uri;
  final bool consentPending;
  final bool showSchool;
  final Set<String> visibleEndgameLessons;

  /// O link frio é inválido: o erro entra por cima da retomada, para Voltar
  /// recuperá-la.
  final bool invalidLinkOnTop;
  final LaunchFollowUp followUp;
}

/// Decide para onde o app abre a partir do que foi lido na abertura.
class ResolveLaunchDestination {
  const ResolveLaunchDestination();

  /// Deferred deep link (T84): na 1ª abertura sem link nem aviso, o link do
  /// post que levou à Play abre como se tivesse sido tocado com o app já
  /// instalado.
  bool readsReferrer({
    required bool opened,
    required bool pushed,
    required bool onboardingDone,
  }) => !opened && !pushed && !onboardingDone;

  /// O desafio que abre: o do link; sem link, o do aviso.
  ChallengeLink? link(LaunchFacts facts) => facts.opened != null
      ? (facts.openedInvalid ? null : facts.openedChallenge)
      : facts.pushedChallenge;

  /// Quem veio de um link não vê o formulário do anúncio agora (E1.25).
  bool fromLink(LaunchFacts facts) =>
      facts.opened != null || link(facts) != null;

  /// O app abriu pelo toque num aviso (e não por um link).
  bool pushed(LaunchFacts facts) =>
      facts.opened == null && facts.pushOpening != null;

  // A retomada de aula só vale quando nada vem antes dela.
  bool _restores(LaunchFacts facts) =>
      facts.conclusion == null &&
      !facts.resumeGame &&
      facts.opened == null &&
      link(facts) == null &&
      !facts.boardControlsOpen;

  /// Conferir no pacote se a aula da Escola em andamento ainda existe:
  /// conteúdo que sumiu não prende a instalação antiga numa aula.
  bool checksSchoolLesson(LaunchFacts facts) =>
      _restores(facts) &&
      facts.showSchool &&
      (facts.school.ongoing?.open ?? false);

  /// Conferir no pacote as aulas de final da retomada.
  bool checksEndgameLessons(LaunchFacts facts) =>
      _restores(facts) &&
      ((facts.endgames.ongoing?.open ?? false) ||
          facts.endgames.openExercise != null);

  LaunchDestination call(LaunchFacts facts) {
    final consentUid = facts.consentUid;
    final trail = facts.trailLessons;
    final opened = facts.opened;
    final pushedUri = facts.pushOpening?.link;
    final gift = opened == null && (facts.pushOpening?.isGift ?? false);
    return LaunchDestination(
      facts: facts,
      link: link(facts),
      uri: opened != null && !facts.openedInvalid ? opened : null,
      consentPending: consentUid != null && facts.accountUid == consentUid,
      showSchool: facts.schoolLessonFound ?? facts.showSchool,
      visibleEndgameLessons: trail == null
          ? facts.visibleEndgameLessons
          : {
              for (final id in trail)
                if (facts.visibleEndgameLessons.contains(id)) id,
            },
      invalidLinkOnTop: opened != null && facts.openedInvalid,
      followUp: gift
          ? LaunchFollowUp.gift
          : opened == null && pushedUri != null && facts.pushedChallenge == null
          ? LaunchFollowUp.pushedScreen
          : LaunchFollowUp.none,
    );
  }
}
