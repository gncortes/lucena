import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/skeleton.dart';
import '../../journey/widgets/challenge_load_error.dart';
import '../view_models/daily_start_cubit.dart';

/// O `/daily`: o esqueleto da partida enquanto acha o final de hoje e troca
/// pela partida dele. Sem final hoje, volta ao Início com um aviso.
class DailyStartScreen extends StatelessWidget {
  const DailyStartScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DailyStartCubit, DailyStartState>(
        listener: (context, state) {
          switch (state) {
            case DailyStartReady(:final location):
              context.replace(location);
            case DailyStartEmpty():
              leaveForNoFinal(context);
            default:
          }
        },
        builder: (context, state) => state is DailyStartFailed
            ? challengeLoadError(
                context,
                state.failure,
                context.read<DailyStartCubit>().load,
              )
            : const DailyLoadingScreen(),
      );
}

/// Não há final hoje (H-DES-03): vai ao Início e avisa, sem registrar nada.
void leaveForNoFinal(BuildContext context) {
  final text = context.l10n.desafiosDailyNone;
  context.go(Routes.home);
  showLucenaSnackBar(context, text, key: DailyKeys.noFinalNotice);
}

/// O carregando do final do dia (canvas PropV1DesDiaCarregando): o título,
/// um jogador, o tabuleiro e o outro jogador. O Compartilhar já fica no lugar,
/// desabilitado (H-DES-04, "ícones fixos entre estados").
class DailyLoadingScreen extends StatelessWidget {
  const DailyLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    key: DailyKeys.loading,
    appBar: LucenaAppBar(
      title: Text(context.l10n.dailyTitle),
      actions: [
        IconButton(
          key: DailyKeys.appBarShare,
          tooltip: context.l10n.desafiosDailyShareTooltip,
          icon: const Icon(Icons.share_outlined),
          onPressed: null,
        ),
      ],
    ),
    body: const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: SkeletonBlock(height: 52, radius: 12),
          ),
          SkeletonBlock(height: 412, radius: 0),
          Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: SkeletonBlock(height: 52, radius: 12),
          ),
        ],
      ),
    ),
  );
}

/// A rota `dailyEmpty` (entrada de lembrete ou link sem final): o mesmo
/// destino, o Início com o aviso.
class DailyEmptyScreen extends StatefulWidget {
  const DailyEmptyScreen({super.key});

  @override
  State<DailyEmptyScreen> createState() => _DailyEmptyScreenState();
}

class _DailyEmptyScreenState extends State<DailyEmptyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) leaveForNoFinal(context);
    });
  }

  @override
  Widget build(BuildContext context) => const DailyLoadingScreen();
}
