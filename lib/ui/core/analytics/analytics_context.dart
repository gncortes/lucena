import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/campaign/campaign_repository.dart';

extension AnalyticsContext on BuildContext {
  /// As estatísticas (E1.03) para passar ao view model. Sem o repositório
  /// acima (uma tela montada sozinha num teste), nenhuma: o Analytics nunca
  /// derruba uma tela.
  AnalyticsRepository get analytics {
    try {
      return read<AnalyticsRepository>();
    } on ProviderNotFoundException {
      return const NoAnalyticsRepository();
    }
  }

  /// A campanha do link de post (T84). Sem o repositório acima, uma na
  /// memória, a mesma para o app todo.
  CampaignRepository get campaigns {
    try {
      return read<CampaignRepository>();
    } on ProviderNotFoundException {
      return _memoryCampaigns;
    }
  }
}

final _memoryCampaigns = MemoryCampaignRepository();
