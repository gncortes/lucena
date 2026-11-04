import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/alerts/alerts_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/featured/featured_alerts_repository.dart';
import '../../../data/repositories/push/push_repository.dart';
import '../../../domain/models/analytics_event.dart';

class FeaturedAlertState {
  const FeaturedAlertState({this.visible = false});

  /// O cartão "Quer saber quando sair outro final assim?" cabe agora.
  final bool visible;
}

/// O cartão do fim de um final em destaque que pergunta se o jogador quer o
/// aviso de final novo de torneio (H-INI-07). Sai uma vez por final: depois de
/// qualquer resposta não volta nesse final. Ligar o aviso é com o
/// `AlertsCubit` (a chave "Torneios" do Perfil > Avisos); aqui só se pede a
/// permissão e se grava a resposta.
class FeaturedAlertCubit extends Cubit<FeaturedAlertState> {
  FeaturedAlertCubit({
    required this.id,
    required this._prompts,
    required this._alerts,
    required this._push,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const FeaturedAlertState());

  final String id;
  final FeaturedAlertsRepository _prompts;
  final AlertsRepository _alerts;
  final PushRepository _push;
  final AnalyticsRepository _analytics;

  /// Sem push (build sem Firebase) a chave de torneios nem existe no Perfil.
  /// A chave nasce ligada, então o cartão cabe também quando ela está ligada
  /// mas o sistema ainda não deixa mostrar avisos; só não cabe com tudo certo.
  Future<void> load() async {
    try {
      final visible =
          _push.available &&
          !await _prompts.promptAnswered(id) &&
          (!(await _alerts.load()).tournaments || !await _push.permitted());
      if (!isClosed) emit(FeaturedAlertState(visible: visible));
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
  }

  /// "Quero receber": pede a permissão do sistema (se ainda não há) e grava a
  /// resposta. Verdadeiro: pode ligar a chave de torneios.
  Future<bool> accept() async {
    final granted = await _push.permitted() || await _push.requestPermission();
    await _answer(granted ? 'permitiu' : 'negou_sistema');
    return granted;
  }

  /// "Agora não".
  Future<void> decline() => _answer('agora_nao');

  Future<void> _answer(String answer) async {
    if (!isClosed) emit(const FeaturedAlertState());
    await _prompts.markPromptAnswered(id);
    unawaited(
      _analytics.log(
        AnalyticsEvents.avisoPedido(
          resposta: answer,
          gatilho: 'final_destaque',
        ),
      ),
    );
  }
}
