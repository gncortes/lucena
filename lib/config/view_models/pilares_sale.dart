import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/links/link_repository.dart';
import '../../data/repositories/purchase/purchase_repository.dart';
import '../../ui/pilares_sale/view_models/pilares_course_card_cubit.dart';

/// O cartão do curso no Perfil.
PilaresCourseCardCubit createPilaresCourseCardCubit(BuildContext context) =>
    PilaresCourseCardCubit(
      purchases: context.read<PurchaseRepository>(),
      links: context.read<LinkRepository>(),
    );
