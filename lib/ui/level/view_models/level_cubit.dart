import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/chesscom/chesscom_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../domain/models/level_source.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/platform_rating.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/use_cases/analytics_rules.dart';
import '../../../domain/use_cases/home_suggestion.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/rating_conversion.dart';
import '../../../domain/use_cases/visible_lessons.dart';

/// Os cartões da tela "Seu nível", na ordem do canvas.
/// `known` é o cartão "Já sei o meu rating": abre os três caminhos
/// (`lichess`, `chess`, `manual`).
enum LevelChoice { test, known, lichess, chess, manual, zero }

/// O que deu errado na última tentativa (mostrado uma vez pela tela).
enum LevelError { lichessOffline, chessOffline }

class LevelState {
  const LevelState({
    this.ready = false,
    this.choice = LevelChoice.test,
    this.knowsRating = false,
    this.placed,
    this.lichess,
    this.lichessBusy = false,
    this.chess,
    this.chessBusy = false,
    this.chessNotFound = false,
    this.manualRating,
    this.manualOrigin = RatingOrigin.fide,
    this.error,
    this.errorCount = 0,
    this.finished = false,
    this.toSchool = false,
    this.inviteAccount = false,
    this.rating,
    this.viktor,
    this.characters = const [],
  });

  final bool ready;

  /// O cartão marcado. "Fazer o teste" vem marcado (decisão 7 da QA).
  final LevelChoice choice;

  /// "Já sei o meu rating" aberto: a tela mostra Lichess, Chess.com e o
  /// número, no lugar das três opções.
  final bool knowsRating;

  /// O rating que o teste de nível deu, se o jogador o fez e usou.
  final int? placed;

  /// Os ratings lidos da conta do Lichess conectada.
  final PlatformRating? lichess;

  /// O login do Lichess está aberto no navegador.
  final bool lichessBusy;

  /// Os ratings públicos do usuário do Chess.com digitado.
  final PlatformRating? chess;
  final bool chessBusy;

  /// O usuário digitado não existe no Chess.com (ou não tem rating).
  final bool chessNotFound;

  /// O número digitado em "Informar o meu rating" e de onde ele é.
  final int? manualRating;
  final RatingOrigin manualOrigin;

  /// O último erro; [errorCount] muda a cada um, para a tela mostrar de novo
  /// o mesmo erro.
  final LevelError? error;
  final int errorCount;

  /// A escolha foi gravada: a tela sai.
  final bool finished;

  /// "Não sei jogar" com a Escola visível: termina nas aulas.
  final bool toSchool;

  /// Terminou com o Lichess e sem conta no Lucena: antes de sair, a tela
  /// convida a criar a conta (`pos_lichess`), que guarda o vínculo.
  final bool inviteAccount;

  /// O nível que foi para o perfil, quando terminou.
  final int? rating;
  final Character? viktor;

  /// Os personagens, para dizer o nome do adversário do degrau.
  final List<Character> characters;

  /// "Fazer o teste" marcado e o teste ainda não feito: "Continuar" abre o
  /// teste.
  bool get testPending => choice == LevelChoice.test && placed == null;

  /// O rating do Lichess que vai para o Lucena (a escala é a mesma).
  int? get lichessRating => lichess?.main?.rating;

  /// O rating do Chess.com convertido para o Lucena.
  int? get chessRating => switch (chess?.main?.rating) {
    final rating? => RatingConversion.toLucena(RatingOrigin.chesscom, rating),
    null => null,
  };

  /// O número informado está entre 400 e 3000.
  bool get manualValid =>
      manualRating != null && RatingConversion.isValid(manualRating!);

  /// O número informado na escala do Lucena. Nulo fora do intervalo.
  int? get manualLucena => manualValid
      ? RatingConversion.toLucena(manualOrigin, manualRating!)
      : null;

  /// O personagem do degrau em que a Jornada começa com [rating].
  Character? startCharacter(int rating) =>
      characters.forLevel(RatingConversion.startRung(rating));

  LevelState copyWith({
    LevelChoice? choice,
    bool? knowsRating,
    int? Function()? placed,
    PlatformRating? Function()? lichess,
    bool? lichessBusy,
    PlatformRating? Function()? chess,
    bool? chessBusy,
    bool? chessNotFound,
    int? Function()? manualRating,
    RatingOrigin? manualOrigin,
    LevelError? error,
    bool? finished,
    bool? toSchool,
    bool? inviteAccount,
    int? rating,
  }) => LevelState(
    ready: ready,
    choice: choice ?? this.choice,
    knowsRating: knowsRating ?? this.knowsRating,
    placed: placed == null ? this.placed : placed(),
    lichess: lichess == null ? this.lichess : lichess(),
    lichessBusy: lichessBusy ?? this.lichessBusy,
    chess: chess == null ? this.chess : chess(),
    chessBusy: chessBusy ?? this.chessBusy,
    chessNotFound: chessNotFound ?? this.chessNotFound,
    manualRating: manualRating == null ? this.manualRating : manualRating(),
    manualOrigin: manualOrigin ?? this.manualOrigin,
    error: error ?? this.error,
    errorCount: error == null ? errorCount : errorCount + 1,
    finished: finished ?? this.finished,
    toSchool: toSchool ?? this.toSchool,
    inviteAccount: inviteAccount ?? this.inviteAccount,
    rating: rating ?? this.rating,
    viktor: viktor,
    characters: characters,
  );
}

/// "Seu nível" (E1.12): o teste, o Lichess, o Chess.com, o rating informado
/// ou "aprender do zero". O rating aceito vai para o perfil, com a origem, e
/// decide o degrau de início da Jornada e a sugestão da tela inicial. Na
/// primeira abertura, só aqui o tour conta como visto; pelo Perfil
/// ([fromProfile]), a tela só troca o nível.
///
/// Com conta no Lucena ([_accounts]), o usuário do Lichess vai no perfil que
/// sobe para ela (o vínculo, T83), em qualquer ordem: Lichess e depois a
/// conta, ou a conta e depois o Lichess.
class LevelCubit extends Cubit<LevelState> {
  LevelCubit({
    required this._onboarding,
    required this._profile,
    required this._characters,
    required this._lichess,
    required this._chessCom,
    this._home,
    this.fromProfile = false,
    this._analytics = const NoAnalyticsRepository(),
    this._accounts,
    this._sync,
    this._now = const SystemNow(),
  }) : super(const LevelState());

  final AnalyticsRepository _analytics;
  final AccountRepository? _accounts;
  final SyncScheduler? _sync;
  final Now _now;
  StreamSubscription<Account?>? _accountSubscription;
  final OnboardingRepository _onboarding;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final LichessRepository _lichess;
  final ChessComRepository _chessCom;
  final HomeLayoutRepository? _home;
  final bool fromProfile;
  Onboarding _saved = const Onboarding();
  Future<void> _onboardingSaved = Future.value();
  bool _finishing = false;
  int _chessRevision = 0;

  bool get _locked => !state.ready || state.finished || _finishing;

  bool get _hasAccount => _accounts?.current != null;

  /// `nivel` na primeira abertura; `perfil` quando veio do Perfil.
  String get _origin => fromProfile ? 'perfil' : 'nivel';

  Future<void> load() async {
    // A conta criada depois do Lichess (pelo convite) liga os dois.
    _accountSubscription ??= _accounts?.changes.listen((account) {
      if (account != null) unawaited(_markLinked());
    });
    _saved = await _onboarding.load();
    final characters = await _characters.characters();
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == 'master') viktor = character;
    }
    if (!_saved.done && !fromProfile) {
      unawaited(_save(_saved.copyWith(stage: OnboardingStage.level)));
    }
    final selected = _saved.selectedRating;
    final placed = !fromProfile && !_saved.byHand ? selected : null;
    emit(
      LevelState(
        ready: true,
        placed: placed,
        viktor: viktor,
        characters: characters,
      ),
    );
    // O app pode ter sido fechado no navegador: a volta do Lichess termina
    // aquela conexão aqui.
    try {
      final rating = await _lichess.resume();
      if (rating != null) _connected();
      if (rating != null && !isClosed) {
        emit(
          state.copyWith(
            choice: LevelChoice.lichess,
            knowsRating: true,
            lichess: () => rating,
          ),
        );
      }
    } on LichessException catch (e) {
      _lichessFailed(e.failure);
    }
  }

  void select(LevelChoice choice) {
    if (_locked) return;
    emit(state.copyWith(choice: choice));
  }

  /// "Já sei o meu rating" + Continuar: mostra os três caminhos do rating.
  void openKnown() {
    if (_locked) return;
    emit(state.copyWith(choice: LevelChoice.lichess, knowsRating: true));
  }

  /// Voltar dos três caminhos para as três opções.
  void closeKnown() {
    if (_locked) return;
    emit(state.copyWith(choice: LevelChoice.known, knowsRating: false));
  }

  /// "Entrar com o Lichess": abre o login no navegador e espera a volta.
  Future<void> connectLichess() async {
    if (_locked || state.lichessBusy) return;
    emit(
      state.copyWith(
        choice: LevelChoice.lichess,
        knowsRating: true,
        lichessBusy: true,
      ),
    );
    try {
      final rating = await _lichess.connect();
      _connected();
      unawaited(
        _analytics.log(
          AnalyticsEvents.contaLichess(
            acao: 'conectado',
            rating: rating.main?.rating,
          ),
        ),
      );
      if (isClosed) return;
      emit(state.copyWith(lichessBusy: false, lichess: () => rating));
    } on LichessException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(lichessBusy: false));
      _lichessFailed(e.failure);
    }
  }

  void _connected() => unawaited(
    _analytics.log(
      AnalyticsEvents.lichessConectado(origem: _origin, temConta: _hasAccount),
    ),
  );

  /// `lichess_vinculado`: há conta e o perfil tem o usuário do Lichess.
  Future<void> _markLinked() async {
    final profile = await _profile.load();
    await _analytics.setTrait(
      AnalyticsTrait.lichessLinked,
      AnalyticsRules.yesNo(_hasAccount && profile.lichessUser != null),
    );
  }

  /// Com conta, o vínculo novo sobe agora (sem esperar a próxima partida).
  Future<void> _pushLink() async {
    final uid = _accounts?.current?.uid;
    final sync = _sync;
    if (uid == null || sync == null) return;
    try {
      await sync.syncNow(uid);
    } on SyncException {
      // Sem rede: sobe na próxima sincronização.
    }
  }

  /// A pessoa voltou do navegador sem autorizar.
  void cancelLichess() {
    if (state.lichessBusy) _lichess.cancel();
  }

  // Cancelar na página do Lichess volta sem erro (regra 7).
  void _lichessFailed(LichessFailure failure) {
    if (isClosed || failure == LichessFailure.cancelled) return;
    emit(state.copyWith(error: LevelError.lichessOffline));
  }

  /// Procura o usuário no Chess.com. Vazio, limpa.
  Future<void> lookUpChess(String user) async {
    if (_locked) return;
    final revision = ++_chessRevision;
    final name = user.trim();
    if (name.isEmpty) {
      emit(
        state.copyWith(
          chess: () => null,
          chessBusy: false,
          chessNotFound: false,
        ),
      );
      return;
    }
    emit(state.copyWith(chessBusy: true, chessNotFound: false));
    try {
      final rating = await _chessCom.stats(name);
      if (isClosed || revision != _chessRevision) return;
      emit(state.copyWith(chessBusy: false, chess: () => rating));
    } on ChessComException catch (e) {
      if (isClosed || revision != _chessRevision) return;
      final notFound = e.failure == ChessComFailure.notFound;
      emit(
        state.copyWith(
          chessBusy: false,
          chess: () => null,
          chessNotFound: notFound,
          error: notFound ? null : LevelError.chessOffline,
        ),
      );
    }
  }

  /// O número digitado em "Informar o meu rating" (nulo se não é número).
  void setManual(int? rating) {
    if (_locked) return;
    emit(state.copyWith(manualRating: () => rating));
  }

  void setManualOrigin(RatingOrigin origin) {
    if (_locked) return;
    emit(state.copyWith(manualOrigin: origin));
  }

  /// "Usar esse rating" (ou "Usar o 1500 mesmo assim") do Lichess.
  Future<void> useLichess() async {
    final lichess = state.lichess;
    final rating = state.lichessRating;
    if (lichess == null || rating == null) return;
    await _finish(LevelSource.lichess, rating, lichessUser: lichess.user);
  }

  /// "Usar esse rating" do Chess.com, já convertido.
  Future<void> useChess() async {
    final chess = state.chess;
    final rating = state.chessRating;
    if (chess == null || rating == null) return;
    await _finish(LevelSource.chesscom, rating, chessComUser: chess.user);
  }

  /// "Usar esse rating" do número informado, já convertido.
  Future<void> useManual() async {
    final rating = state.manualLucena;
    if (rating == null) return;
    await _finish(LevelSource.manual, rating);
  }

  /// Chamado quando o teste volta com um resultado que a pessoa usou: o
  /// cartão do teste fica marcado com o degrau.
  Future<void> usePlacement() async {
    if (_locked) return;
    final profile = await _profile.load();
    if (isClosed || _locked) return;
    emit(
      state.copyWith(choice: LevelChoice.test, placed: () => profile.rating),
    );
    await _save(
      _saved.copyWith(selectedRating: () => profile.rating, byHand: false),
    );
  }

  /// "Continuar" com o teste feito ou "Não sei jogar".
  Future<void> finish() async {
    final placed = state.placed;
    switch (state.choice) {
      case LevelChoice.test when placed != null:
        await _finish(LevelSource.test, placed);
      case LevelChoice.zero:
        await _finish(LevelSource.zero, RatingLevel.beginner.rating);
      default:
        return;
    }
  }

  Future<void> _finish(
    LevelSource source,
    int rating, {
    String? lichessUser,
    String? chessComUser,
  }) async {
    if (_locked) return;
    _finishing = true;
    try {
      await _onboardingSaved;
      final saved = await _profile.load();
      final zero = source == LevelSource.zero;
      final profile = saved.copyWith(
        rating: rating,
        levelSource: source,
        lichessUser: lichessUser ?? saved.lichessUser,
        lichessLinkedAt: _linkedAt(saved, lichessUser),
        chessComUser: chessComUser ?? saved.chessComUser,
        goal: zero ? GoalPreference.learn : saved.goal,
      );
      await _profile.save(profile);
      unawaited(_counted(source, rating));
      final lichess = source == LevelSource.lichess;
      if (lichess) {
        unawaited(_markLinked());
        unawaited(_pushLink());
      }
      final home = _home;
      if (home != null && (await home.load())?.custom != true) {
        await home.save(
          HomeSuggestion.of(RatingLevel.of(rating), goal: profile.goal),
        );
      }
      await home?.markNoticeSeen();
      await _save(
        _saved.copyWith(
          done: true,
          step: 0,
          startRung: '${RatingConversion.startRung(rating)}',
          inProgress: false,
          selectedRating: () => rating,
          byHand: source != LevelSource.test,
        ),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            finished: true,
            toSchool: zero && VisibleLessons.school,
            inviteAccount: lichess && _accounts != null && !_hasAccount,
            rating: rating,
          ),
        );
      }
    } finally {
      _finishing = false;
    }
  }

  // Usuário novo (ou o primeiro vínculo): a data é a de agora; o mesmo
  // usuário de novo mantém a data.
  DateTime? _linkedAt(UserProfile saved, String? lichessUser) {
    if (lichessUser == null) return saved.lichessLinkedAt;
    if (lichessUser == saved.lichessUser && saved.lichessLinkedAt != null) {
      return saved.lichessLinkedAt;
    }
    return _now();
  }

  @override
  Future<void> close() async {
    await _accountSubscription?.cancel();
    return super.close();
  }

  Future<void> _counted(LevelSource source, int rating) async {
    final via = switch (source) {
      LevelSource.test => 'teste',
      LevelSource.lichess => 'lichess',
      LevelSource.chesscom => 'chesscom',
      LevelSource.manual => 'manual',
      LevelSource.zero => 'zero',
    };
    await _analytics.log(
      AnalyticsEvents.nivelDefinido(via: via, rating: rating),
    );
    await _analytics.setTrait(AnalyticsTrait.levelVia, via);
    await _analytics.setTrait(
      AnalyticsTrait.levelBand,
      AnalyticsRules.ratingBand(rating),
    );
  }

  Future<void> _save(Onboarding onboarding) {
    _saved = onboarding;
    return _onboardingSaved = _onboardingSaved.then(
      (_) => _onboarding.save(onboarding),
    );
  }
}
