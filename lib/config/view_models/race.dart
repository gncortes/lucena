import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/race/race_repository.dart';
import '../../ui/race/view_models/warm_up_offer_cubit.dart';

/// A oferta de aquecimento com o repositório da Corrida do [context].
WarmUpOfferCubit createWarmUpOfferCubit(BuildContext context) =>
    WarmUpOfferCubit(context.read<RaceRepository>());
