import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/sync/sync_scheduler.dart';
import '../ui/alerts/view_models/alerts_cubit.dart';
import '../ui/pilares_sale/view_models/pilares_purchase_watch_cubit.dart';
import '../ui/profile/view_models/profile_cubit.dart';
import '../ui/reminders/view_models/reminders_cubit.dart';
import '../ui/settings/view_models/settings_cubit.dart';
import '../ui/update/view_models/update_cubit.dart';
import '../ui/voice/view_models/speech_cubit.dart';
import '../ui/wiki/view_models/wiki_links_cubit.dart';
import 'app_repository_providers.dart';
import 'dependencies.dart';

/// Os repositórios e os view models do app todo, por área, acima do
/// [child]. O [sync], o [update] e o [settings] vivem com o app.
class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.dependencies,
    required this.sync,
    required this.update,
    required this.settings,
    required this.child,
    super.key,
  });

  final Dependencies dependencies;
  final SyncScheduler sync;
  final UpdateCubit update;
  final SettingsCubit settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final deps = dependencies;
    String? region() =>
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    return MultiRepositoryProvider(
      providers: appRepositoryProviders(deps, sync),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UpdateCubit>.value(value: update),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<ProfileCubit>(
            create: (context) => ProfileCubit(
              deps.profileRepository,
              // O país do Perfil vem da região do celular, sem permissão.
              region: region,
              analytics: deps.analyticsRepository,
            )..load(),
          ),
          BlocProvider<AlertsCubit>(
            // Na abertura, já acerta os tópicos do push com as chaves.
            lazy: false,
            create: (context) => AlertsCubit(
              alerts: deps.alertsRepository,
              push: deps.pushRepository,
              reminders: deps.remindersRepository,
              profile: deps.profileRepository,
              region: region,
              analytics: deps.analyticsRepository,
            )..load(),
          ),
          BlocProvider<RemindersCubit>(
            // Os lembretes locais: o RemindersBridge passa as chaves e os
            // textos.
            lazy: false,
            create: (context) => RemindersCubit(
              reminders: deps.remindersRepository,
              activity: deps.activityRepository,
              week: deps.weekRepository,
              now: deps.now,
              changes: deps.localChanges,
              training: deps.courseTrainingRepository,
              courses: activeTrainingCourses,
              analytics: deps.analyticsRepository,
            ),
          ),
          BlocProvider<PilaresPurchaseWatchCubit>(
            // A compra vigiada no app todo (H-VEN-05/06/10).
            lazy: false,
            create: (context) => PilaresPurchaseWatchCubit(
              purchases: deps.purchaseRepository,
              analytics: deps.analyticsRepository,
              grants: deps.courseGrantsRepository,
              now: deps.now,
            ),
          ),
          BlocProvider<WikiLinksCubit>(
            create: (context) =>
                WikiLinksCubit(deps.wikiLinksRepository)..load(),
          ),
          BlocProvider<SpeechCubit>(
            create: (context) => SpeechCubit(
              deps.voiceRepository,
              characters: deps.characterRepository,
            )..load(),
          ),
        ],
        child: child,
      ),
    );
  }
}
