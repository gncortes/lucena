import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/ads/ads_repository.dart';

/// Pede o consentimento do Google para os anúncios (E1.25).
Future<void> requestAdsConsent(BuildContext context) =>
    context.read<AdsRepository>().requestConsent();
