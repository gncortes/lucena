import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/share/share_repository.dart';
import '../../../domain/models/challenge_link.dart';

part 'challenge_sheet_cubit.freezed.dart';

@freezed
abstract class ChallengeSheetState with _$ChallengeSheetState {
  const factory ChallengeSheetState({
    /// O desafio, com a trava que a pessoa escolheu.
    required ChallengeLink link,

    /// O menu do sistema está aberto: sem dois toques abrindo dois menus.
    @Default(false) bool sharing,
  }) = _ChallengeSheetState;
}

/// A folha "Mandar como desafio": a trava e o envio do link.
class ChallengeSheetCubit extends Cubit<ChallengeSheetState> {
  ChallengeSheetCubit(this._share, {required ChallengeLink link})
    : super(ChallengeSheetState(link: link));

  final ShareRepository _share;

  void setLocked({required bool locked}) =>
      emit(state.copyWith(link: state.link.withLock(locked: locked)));

  /// Abre o menu do sistema com [text] (a mensagem já com o link).
  Future<void> share(String text) async {
    if (state.sharing) return;
    emit(state.copyWith(sharing: true));
    try {
      await _share.shareText(text);
    } finally {
      if (!isClosed) emit(state.copyWith(sharing: false));
    }
  }
}
