import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/coach/coach_repository.dart';
import '../../../domain/models/coach/coach.dart';

/// Ligar a conta do Lichess ou do chess.com.
final class LinkAccountState {
  const LinkAccountState({
    required this.platform,
    this.username = '',
    this.sending = false,
    this.failure,
    this.linked = false,
  });

  final Platform platform;
  final String username;
  final bool sending;
  final LinkAccountFailure? failure;
  final bool linked;

  bool get canSend => !sending && username.trim().isNotEmpty;

  LinkAccountState copyWith({
    String? username,
    bool? sending,
    LinkAccountFailure? Function()? failure,
    bool? linked,
  }) => LinkAccountState(
    platform: platform,
    username: username ?? this.username,
    sending: sending ?? this.sending,
    failure: failure == null ? this.failure : failure(),
    linked: linked ?? this.linked,
  );
}

final class LinkAccountCubit extends Cubit<LinkAccountState> {
  LinkAccountCubit({required this.repository, required Platform platform})
    : super(LinkAccountState(platform: platform));

  final CoachRepository repository;

  void typeText(String username) =>
      emit(state.copyWith(username: username, failure: () => null));

  Future<void> link() async {
    if (!state.canSend) return;
    emit(state.copyWith(sending: true, failure: () => null));
    try {
      await repository.linkAccount(state.platform, state.username.trim());
      if (!isClosed) emit(state.copyWith(sending: false, linked: true));
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
