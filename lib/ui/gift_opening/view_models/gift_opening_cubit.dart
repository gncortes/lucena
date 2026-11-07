import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/lesson_ad/course_grants_repository.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/course_grant.dart';
import '../../../domain/use_cases/now.dart';

/// Em que pé está a abertura do presente.
enum GiftOpeningPhase {
  /// Esperando o acesso sincronizar.
  opening,

  /// Sem rede ou o acesso não chegou a tempo.
  failed,

  /// Sem conta neste aparelho: entrar para ver o presente.
  signIn,

  /// Entrou em outra conta: vê o catálogo do curso.
  otherAccount,

  /// O curso está aberto: Curso liberado pelo presente ([gift]) ou pela
  /// compra de fora.
  open,

  /// O Curso liberado deste acesso já saiu (o acesso chegou ao vivo antes do
  /// toque): não abre outro, só volta.
  shown,
}

class GiftOpeningState {
  const GiftOpeningState(this.phase, {this.gift = true});

  final GiftOpeningPhase phase;

  /// Em [GiftOpeningPhase.open]: o acesso é presente (ou compra de fora).
  final bool gift;
}

/// O toque no push do presente (H-R5-63): espera o acesso de [course]
/// sincronizar e abre o Curso liberado. Sem conta, pede para entrar; quem
/// entra na conta [uid] do presente segue; em outra, vê o catálogo.
class GiftOpeningCubit extends Cubit<GiftOpeningState> {
  GiftOpeningCubit({
    required this._accounts,
    required this._grants,
    required this.course,
    this.uid,
    this._now = const SystemNow(),
    this._timeout = const Duration(seconds: 10),
  }) : super(const GiftOpeningState(GiftOpeningPhase.opening));

  final AccountRepository _accounts;
  final CourseGrantsRepository _grants;
  final Now _now;
  final Duration _timeout;

  /// O curso dado e a conta que o ganhou (nula: o push não disse).
  final String course;
  final String? uid;

  StreamSubscription<Account?>? _signIns;
  var _attempt = 0;

  Future<void> start() async {
    final current = _accounts.current;
    if (current == null) {
      _emit(GiftOpeningPhase.signIn);
      _signIns = _accounts.changes.listen((account) {
        if (account == null || state.phase != GiftOpeningPhase.signIn) return;
        unawaited(_open(account.uid));
      });
      return;
    }
    await _open(current.uid);
  }

  /// "Tentar novamente", depois da falha.
  Future<void> retry() async {
    final current = _accounts.current;
    if (current == null) {
      _emit(GiftOpeningPhase.signIn);
    } else {
      await _open(current.uid);
    }
  }

  Future<void> _open(String account) async {
    if (uid != null && account != uid) {
      _emit(GiftOpeningPhase.otherAccount);
      return;
    }
    final attempt = ++_attempt;
    _emit(GiftOpeningPhase.opening);
    CourseGrant? grant;
    try {
      await _grants.start();
      grant = _active(_grants.current);
      // Já aberto e visto antes do toque: o Curso liberado saiu uma vez.
      if (grant != null && !_grants.current.unseen(course, _now())) {
        if (!isClosed && attempt == _attempt) {
          _emit(GiftOpeningPhase.shown);
        }
        return;
      }
      // A conta pode ter acabado de entrar: espera o acesso dela chegar.
      grant ??= _active(
        await _grants.changes
            .firstWhere((grants) => _active(grants) != null)
            .timeout(_timeout),
      );
    } on Object {
      grant = null;
    }
    if (isClosed || attempt != _attempt) return;
    if (grant == null) {
      _emit(GiftOpeningPhase.failed);
      return;
    }
    unawaited(_grants.markSeen(course));
    emit(
      GiftOpeningState(
        GiftOpeningPhase.open,
        gift: grant.origin == GrantOrigin.gift,
      ),
    );
  }

  CourseGrant? _active(CourseGrants grants) => grants.active(course, _now());

  void _emit(GiftOpeningPhase phase) {
    if (!isClosed) emit(GiftOpeningState(phase));
  }

  @override
  Future<void> close() async {
    await _signIns?.cancel();
    return super.close();
  }
}
