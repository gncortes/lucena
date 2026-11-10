import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/coach_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../domain/models/coach/coach.dart';

/// Ligar a conta do Lichess ou do chess.com.
final class LinkAccountState {
  const LinkAccountState({
    required this.platform,
    this.username = '',
    this.sending = false,
    this.failure,
    this.linked = false,
    this.cancelled = false,
  });

  final Platform platform;
  final String username;
  final bool sending;
  final LinkAccountFailure? failure;
  final bool linked;

  /// A pessoa voltou do login do Lichess sem autorizar.
  final bool cancelled;

  bool get canSend => !sending && username.trim().isNotEmpty;

  LinkAccountState copyWith({
    String? username,
    bool? sending,
    LinkAccountFailure? Function()? failure,
    bool? linked,
    bool? cancelled,
  }) => LinkAccountState(
    platform: platform,
    username: username ?? this.username,
    sending: sending ?? this.sending,
    failure: failure == null ? this.failure : failure(),
    linked: linked ?? this.linked,
    cancelled: cancelled ?? this.cancelled,
  );
}

/// chess.com: nome digitado, conferido na API pública. Lichess: login na
/// página de lá (o mesmo do Perfil); o servidor confere o dono pelo token.
final class LinkAccountCubit extends Cubit<LinkAccountState> {
  LinkAccountCubit({
    required this.repository,
    required this.lichess,
    required Platform platform,
  }) : super(LinkAccountState(platform: platform));

  final CoachRepository repository;
  final LichessRepository lichess;

  void typeText(String username) =>
      emit(state.copyWith(username: username, failure: () => null));

  Future<void> link() async {
    if (!state.canSend) return;
    await _run(
      () => repository.linkAccount(state.platform, state.username.trim()),
    );
  }

  /// Usa o login do Lichess que já existe; sem login, ou com um que não vale
  /// mais, abre a página do Lichess (uma vez).
  Future<void> linkLichess() async {
    if (state.sending) return;
    await _run(() async {
      var token = await lichess.accessToken();
      if (token == null) {
        await lichess.connect();
        token = await lichess.accessToken();
      }
      if (token == null) {
        throw const LinkAccountException(LinkAccountFailure.noResponse);
      }
      try {
        await repository.linkLichess(token);
      } on LinkAccountException catch (e) {
        if (e.failure != LinkAccountFailure.lichessLogin) rethrow;
        await lichess.disconnect();
        await lichess.connect();
        final fresh = await lichess.accessToken();
        if (fresh == null) rethrow;
        await repository.linkLichess(fresh);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    emit(state.copyWith(sending: true, failure: () => null, cancelled: false));
    try {
      await action();
      if (!isClosed) emit(state.copyWith(sending: false, linked: true));
    } on LichessException catch (e) {
      if (isClosed) return;
      emit(
        e.failure == LichessFailure.cancelled
            ? state.copyWith(sending: false, cancelled: true)
            : state.copyWith(
                sending: false,
                failure: () => LinkAccountFailure.noResponse,
              ),
      );
    } on LinkAccountException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(sending: false, failure: () => e.failure));
      }
    } on Object {
      if (!isClosed) {
        emit(
          state.copyWith(
            sending: false,
            failure: () => LinkAccountFailure.noResponse,
          ),
        );
      }
    }
  }
}
