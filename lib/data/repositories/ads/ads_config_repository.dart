import '../../../domain/models/ads_state.dart';

/// Os números do anúncio (`ads_enabled`, `ads_free_lessons`,
/// `ads_min_gap_seconds`). O Remote Config entra pela E1.32.
abstract class AdsConfigRepository {
  AdsConfig get config;
}

/// O padrão do código, para quando não há Remote Config.
class ConstAdsConfigRepository implements AdsConfigRepository {
  const ConstAdsConfigRepository([this.config = const AdsConfig()]);

  @override
  final AdsConfig config;
}
