import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/campaign/campaign_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/campaign.dart';

/// O fim da demonstração (H-VEN-04, `PropV2DemoOferta`): ao abrir, registra
/// `demo_fim` e, para quem veio de campanha, a oferta vista com o destaque
/// `fim_demo`. O estado é a campanha ativa (nula sem campanha).
class PilaresDemoEndCubit extends Cubit<Campaign?> {
  PilaresDemoEndCubit({required this._analytics, required this._campaigns})
    : super(null) {
    unawaited(_open());
  }

  static const highlight = 'fim_demo';

  final AnalyticsRepository _analytics;
  final CampaignRepository _campaigns;

  Future<void> _open() async {
    await _analytics.log(AnalyticsEvents.demoFim());
    final campaign = await _campaigns.active();
    if (isClosed || campaign == null) return;
    emit(campaign);
    await _analytics.log(
      AnalyticsEvents.campanhaOfertaVista(campaign, destaque: highlight),
    );
  }

  /// "Ver opções de compra".
  Future<void> seeOptions() async {
    final campaign = state;
    if (campaign == null) return;
    await _analytics.log(
      AnalyticsEvents.campanhaOfertaTocada(campaign, destaque: highlight),
    );
  }
}
