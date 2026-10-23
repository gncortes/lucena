import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../alerts/view_models/alerts_cubit.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/reminders_cubit.dart';
import 'l10n_reminder_texts.dart';

/// Liga o [RemindersCubit] ao resto do app: as chaves de Avisos, o idioma, o
/// app voltando ou indo para segundo plano e o toque nas notificações
/// ([onOpen] recebe a rota).
class RemindersBridge extends StatefulWidget {
  const RemindersBridge({required this.onOpen, required this.child, super.key});

  final ValueChanged<String> onOpen;
  final Widget child;

  @override
  State<RemindersBridge> createState() => _RemindersBridgeState();
}

class _RemindersBridgeState extends State<RemindersBridge> {
  L10nReminderTexts? _texts;
  StreamSubscription<String>? _taps;
  bool _launched = false;

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: _refresh,
    onHide: _refresh,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _taps = context.read<RemindersCubit>().taps.listen(
      (route) => widget.onOpen(route),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final texts = L10nReminderTexts(context.l10n);
    if (texts == _texts) return;
    _texts = texts;
    unawaited(_update(context.read<AlertsCubit>().state));
  }

  void _refresh() => unawaited(context.read<RemindersCubit>().refresh());

  Future<void> _update(AlertsState alerts) async {
    final texts = _texts;
    if (!alerts.ready || texts == null) return;
    final reminders = context.read<RemindersCubit>();
    await reminders.update(settings: alerts.settings, texts: texts);
    if (_launched) return;
    _launched = true;
    // O plugin só conta qual notificação abriu o app depois de preparado.
    final route = await reminders.launchRoute();
    if (route != null && mounted) widget.onOpen(route);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_taps?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AlertsCubit, AlertsState>(
    listenWhen: (before, after) =>
        before.ready != after.ready ||
        before.settings != after.settings ||
        before.permitted != after.permitted,
    listener: (context, alerts) => unawaited(_update(alerts)),
    child: widget.child,
  );
}
