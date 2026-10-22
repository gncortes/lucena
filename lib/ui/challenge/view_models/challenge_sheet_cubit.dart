import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/share/share_repository.dart';
import '../../../domain/models/analytics_event.dart';
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
  ChallengeSheetCubit(
    this._share, {
    required ChallengeLink link,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(
         ChallengeSheetState(
           link: link.sharedFrom(_screen, generation: LinkTrail.next(null)),
         ),
       );

  final ShareRepository _share;
  final AnalyticsRepository _analytics;

  // O `tela` do E1.03.
  static const _screen = 'criar_desafio';

  // O último link pelo qual a pessoa chegou (`codigo_pai`) e os códigos já
  // contados como criados (a trava muda o código).
  LinkTrail? _trail;
  final _created = <String>{};

  /// Lê o link pelo qual a pessoa chegou: o desafio mandado é a geração
  /// seguinte.
  Future<void> load() async {
    _trail = await _analytics.lastLink();
    if (isClosed) return;
    emit(
      state.copyWith(
        link: state.link.copyWith(generation: LinkTrail.next(_trail)),
      ),
    );
  }

  void setLocked({required bool locked}) =>
      emit(state.copyWith(link: state.link.withLock(locked: locked)));

  /// Abre o menu do sistema com [text] (a mensagem já com o link).
  Future<void> share(String text) async {
    if (state.sharing) return;
    emit(state.copyWith(sharing: true));
    final link = state.link;
    await _createdOnce(link);
    var result = 'indisponivel';
    try {
      result = await _share.shareText(text) ? 'concluido' : 'cancelado';
    } finally {
      if (!isClosed) emit(state.copyWith(sharing: false));
      await _analytics.log(
        AnalyticsEvents.share(
          contentType: 'desafio',
          itemId: link.code,
          resultado: result,
          codigo: link.code,
          geracao: link.generation,
        ),
      );
    }
  }

  /// Tocou em Copiar link (ou no endereço).
  Future<void> copied() async {
    final link = state.link;
    await _createdOnce(link);
    await _analytics.log(
      AnalyticsEvents.linkCopiado(
        tela: _screen,
        codigo: link.code,
        geracao: link.generation,
      ),
    );
  }

  Future<void> _createdOnce(ChallengeLink link) async {
    if (!_created.add(link.code)) return;
    await _analytics.log(
      AnalyticsEvents.linkCreated(link, tela: _screen, parent: _trail?.code),
    );
  }
}
