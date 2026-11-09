import '../data/repositories/deep_link/deep_link_repository.dart';
import '../domain/models/lesson_content.dart';
import '../domain/models/push_alert.dart';
import '../domain/use_cases/resolve_launch_destination.dart';
import '../domain/use_cases/visible_lessons.dart';
import '../routing/routes.dart';
import 'dependencies.dart';
import 'startup_tasks.dart';

/// Lê dos repositórios o que decide a primeira tela e passa ao
/// [ResolveLaunchDestination]. O aviso e o link que abriram o app são lidos
/// uma vez só: a abertura repetida depois de uma falha usa os mesmos.
class LaunchReader {
  LaunchReader(this._dependencies, {required this._tasks});

  final Dependencies _dependencies;
  final StartupTasks _tasks;
  static const _resolve = ResolveLaunchDestination();
  Future<PushOpening?>? _initialPush;
  Future<Uri?>? _initialLink;

  Future<LaunchDestination> read() async {
    final dependencies = _dependencies;
    final game = await dependencies.ongoingGameRepository.load();
    final blind = await dependencies.blindCheckpointRepository.load();
    final conclusion = await dependencies.conclusionRepository.pending();
    final school = await dependencies.schoolProgressRepository.load();
    final endgames = await dependencies.endgameProgressRepository.load();
    final stars = await dependencies.starChallengeRepository.open();
    final deepLinks = dependencies.deepLinkRepository;
    _tasks.beforeLaunch();
    final pushOpening = await (_initialPush ??= dependencies.pushRepository
        .initialOpening()
        .catchError((Object error, StackTrace stack) {
          _initialPush = null;
          Error.throwWithStackTrace(error, stack);
        }));
    final onboarding = await dependencies.onboardingRepository.load();
    var opened = await (_initialLink ??= deepLinks.initialUri().catchError((
      Object error,
      StackTrace stack,
    ) {
      _initialLink = null;
      Error.throwWithStackTrace(error, stack);
    }));
    var fromReferrer = false;
    if (_resolve.readsReferrer(
      opened: opened != null,
      pushed: pushOpening != null,
      onboardingDone: onboarding.done,
    )) {
      opened = await dependencies.installReferrerRepository.pendingLink();
      fromReferrer = opened != null;
    }
    final openedInvalid =
        opened != null && Routes.appLink(opened) == Routes.invalidLink;
    final pushed = pushOpening?.link;
    final profile = await dependencies.profileRepository.load();
    final consentUid = await dependencies.legalConsentRepository.pending();
    var facts = LaunchFacts(
      conclusion: conclusion,
      resumeGame: game != null && game.reopensOnLaunch,
      resumeBlind: blind != null,
      school: school,
      endgames: endgames,
      stars: stars,
      onboardingDone: onboarding.done,
      boardControlsOpen: onboarding.boardControlsOpen,
      goalAnswered: profile.goal != null,
      consentUid: consentUid,
      accountUid: dependencies.accountRepository.current?.uid,
      opened: opened,
      openedInvalid: openedInvalid,
      openedChallenge: opened == null || openedInvalid
          ? null
          : deepLinks.parse(opened),
      pushOpening: pushOpening,
      pushedChallenge: pushed == null ? null : deepLinks.parse(pushed),
      fromReferrer: fromReferrer,
      showSchool: VisibleLessons.school,
      visibleEndgameLessons: VisibleLessons.endgameLessonIds,
    );
    _tasks.launched(facts);
    // Missing/unpublished content must not trap an old installation in a
    // restored lesson. Keep its progress; only postpone automatic reopening.
    if (_resolve.checksSchoolLesson(facts)) {
      facts = facts.withContent(schoolLessonFound: await _schoolLesson(facts));
    }
    if (_resolve.checksEndgameLessons(facts)) {
      facts = facts.withContent(trailLessons: await _trailLessons());
    }
    return _resolve(facts);
  }

  Future<bool> _schoolLesson(LaunchFacts facts) async {
    try {
      final course = await _dependencies.lessonRepository.course();
      return course.lesson(facts.school.ongoing!.lessonId) != null;
    } on LessonContentUnavailable {
      return false;
    }
  }

  Future<Set<String>> _trailLessons() async {
    try {
      final trail = await _dependencies.endgameLessonRepository.trail();
      return {for (final lesson in trail.lessons) lesson.id};
    } on LessonContentUnavailable {
      return {};
    }
  }
}
