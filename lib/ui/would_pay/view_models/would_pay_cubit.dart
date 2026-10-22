import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/feedback/feedback_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/review/review_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../data/repositories/would_pay/would_pay_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/feedback_entry.dart';
import '../../../domain/models/would_pay.dart';
import '../../../domain/use_cases/lesson_count.dart';
import '../../../domain/use_cases/would_pay_rules.dart';

class WouldPayState {
  const WouldPayState({
    this.ready = false,
    this.step = 0,
    this.answers = const WouldPayAnswers(),
    this.levelDefined = false,
    this.viktor,
    this.sending = false,
    this.sent = false,
  });

  final bool ready;

  /// O passo aberto, a partir de 0.
  final int step;
  final WouldPayAnswers answers;

  /// O perfil já tem nível: o passo 3 não pergunta.
  final bool levelDefined;
  final Character? viktor;
  final bool sending;
  final bool sent;

  int get total => WouldPayRules.totalSteps;
  bool get isLast => step == total - 1;
  bool get canAdvance => WouldPayRules.canAdvance(step, answers);

  WouldPayState copyWith({
    bool? ready,
    int? step,
    WouldPayAnswers? answers,
    bool? levelDefined,
    Character? viktor,
    bool? sending,
    bool? sent,
  }) => WouldPayState(
    ready: ready ?? this.ready,
    step: step ?? this.step,
    answers: answers ?? this.answers,
    levelDefined: levelDefined ?? this.levelDefined,
    viktor: viktor ?? this.viktor,
    sending: sending ?? this.sending,
    sent: sent ?? this.sent,
  );
}

/// O "Você pagaria?" (E1.26). Cada mudança grava o rascunho; "Enviar" manda
/// as respostas e o cartão não volta.
class WouldPayCubit extends Cubit<WouldPayState> {
  WouldPayCubit({
    required this._wouldPay,
    required this._feedback,
    required this._profile,
    required this._characters,
    required this._review,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const WouldPayState());

  static const _type = 'pagaria';

  final WouldPayRepository _wouldPay;
  final FeedbackRepository _feedback;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final ReviewRepository _review;
  final AnalyticsRepository _analytics;

  /// O nível ou rating do perfil, quando definido (vai no envio).
  String? _profileLevel;

  /// [step] (1 a 3) vem da rota; sem ele, o do rascunho.
  Future<void> load({int? step}) async {
    // Viu o questionário: nesta sessão não pede avaliação.
    _review.noteSurveySeen();
    final draft = await _wouldPay.loadDraft();
    final profile = await _profile.load();
    Character? viktor;
    for (final character in await _characters.characters()) {
      if (character.id == 'master') viktor = character;
    }
    if (isClosed) return;
    if (!state.ready) {
      // O convite é o único caminho até aqui (E1.03).
      unawaited(
        _analytics.log(
          AnalyticsEvents.questionarioAberto(
            tipo: _type,
            origem: 'cartao_aulas',
          ),
        ),
      );
    }
    final defined = profile.levelSource != null;
    _profileLevel = defined ? '${profile.rating}' : null;
    final answers = draft?.answers ?? const WouldPayAnswers();
    final wanted = step == null ? draft?.step ?? 0 : step - 1;
    emit(
      state.copyWith(
        ready: true,
        step: _reachable(wanted.clamp(0, state.total - 1), answers),
        answers: answers,
        levelDefined: defined,
        viktor: viktor,
      ),
    );
  }

  /// Não pula passo obrigatório: para no primeiro incompleto.
  static int _reachable(int step, WouldPayAnswers answers) {
    for (var before = 0; before < step; before++) {
      if (!WouldPayRules.canAdvance(before, answers)) return before;
    }
    return step;
  }

  Future<void> _change({int? step, WouldPayAnswers? answers}) async {
    emit(state.copyWith(step: step, answers: answers));
    await _wouldPay.saveDraft(
      WouldPayDraft(step: state.step, answers: state.answers),
    );
  }

  Future<void> pickCourse(WouldPayAnswer answer) =>
      _change(answers: state.answers.copyWith(course: answer));

  Future<void> pickCoursePrice(CoursePrice price) =>
      _change(answers: state.answers.copyWith(coursePrice: price));

  Future<void> pickCoach(WouldPayAnswer answer) =>
      _change(answers: state.answers.copyWith(coach: answer));

  Future<void> pickCoachPrice(MonthPrice price) =>
      _change(answers: state.answers.copyWith(coachPrice: price));

  Future<void> pickLearn(LearnAnswer answer) =>
      _change(answers: state.answers.copyWith(learn: answer));

  Future<void> setNext(String text) =>
      _change(answers: state.answers.copyWith(next: text));

  Future<void> toggleWhy(String id) {
    final why = state.answers.why;
    return _change(
      answers: state.answers.copyWith(
        why: why.contains(id) ? ({...why}..remove(id)) : {...why, id},
      ),
    );
  }

  /// Um nível só; tocar no escolhido desmarca.
  Future<void> toggleLevel(String id) => _change(
    answers: state.answers.level == id
        ? state.answers.copyWith(clearLevel: true)
        : state.answers.copyWith(level: id),
  );

  Future<void> next() async {
    if (state.isLast || !state.canAdvance) return;
    await _change(step: state.step + 1);
    unawaited(
      _analytics.log(
        AnalyticsEvents.questionarioPasso(
          tipo: _type,
          passo: state.step + 1,
          passosTotal: state.total,
        ),
      ),
    );
  }

  /// O "X" antes de enviar: o rascunho fica, mas conta como dispensado.
  void leave() {
    if (!state.ready || state.sent) return;
    unawaited(
      _analytics.log(
        AnalyticsEvents.questionarioDispensado(
          tipo: _type,
          passo: state.step + 1,
          como: 'fechou',
        ),
      ),
    );
  }

  Future<void> back() async {
    if (state.step == 0) return;
    await _change(step: state.step - 1);
  }

  Future<void> send() async {
    if (!state.isLast || state.sending || state.sent) return;
    if (!WouldPayRules.complete(state.answers)) return;
    emit(state.copyWith(sending: true));
    // Com nível no perfil, o do passo 3 não aparece nem vai.
    final answers = state.levelDefined
        ? state.answers.copyWith(clearLevel: true)
        : state.answers;
    await _feedback.send(
      FeedbackEntry.wouldPay(answers: answers),
      level: _profileLevel,
    );
    await _wouldPay.markAnswered();
    unawaited(
      _analytics.log(
        AnalyticsEvents.questionarioEnviado(
          tipo: _type,
          interesse: switch (answers.course) {
            WouldPayAnswer.yes => 'sim',
            WouldPayAnswer.maybe => 'talvez',
            WouldPayAnswer.no => 'nao',
            null => null,
          },
          cursoFaixa: answers.coursePrice?.code,
          mensalFaixa: answers.coachPrice?.code,
          temTexto: answers.next?.trim().isNotEmpty ?? false,
        ),
      ),
    );
    if (isClosed) return;
    emit(state.copyWith(sending: false, sent: true));
  }
}

/// O cartão de convite na lista de aulas: aparece uma vez, depois da 2ª aula
/// concluída, até "Agora não" ou o envio.
class WouldPayInviteCubit extends Cubit<bool> {
  WouldPayInviteCubit({
    required this._wouldPay,
    required this._school,
    required this._endgames,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(false);

  final WouldPayRepository _wouldPay;
  final SchoolProgressRepository _school;
  final EndgameProgressRepository _endgames;
  final AnalyticsRepository _analytics;

  Future<void> load() async {
    final show = WouldPayRules.shouldInvite(
      lessonsCompleted: LessonCount.completed(
        await _school.load(),
        await _endgames.load(),
      ),
      dismissed: await _wouldPay.dismissed(),
      answered: await _wouldPay.answered(),
    );
    if (!isClosed) emit(show);
  }

  /// "Agora não": some e não volta.
  Future<void> dismiss() async {
    emit(false);
    unawaited(
      _analytics.log(
        AnalyticsEvents.questionarioDispensado(
          tipo: WouldPayCubit._type,
          passo: 0,
          como: 'agora_nao',
        ),
      ),
    );
    await _wouldPay.dismiss();
  }
}
