import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../view_models/daily_start_cubit.dart';

/// O `/daily`: um instante em branco enquanto acha o final de hoje e troca
/// pela partida dele.
class DailyStartScreen extends StatelessWidget {
  const DailyStartScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocListener<DailyStartCubit, DailyStartState>(
        listener: (context, state) {
          if (state case DailyStartReady(:final location)) {
            // Sem final hoje, a home; com ele, a partida no lugar desta tela.
            location == Routes.home
                ? context.go(location)
                : context.replace(location);
          }
        },
        child: const Scaffold(body: SizedBox.shrink()),
      );
}
