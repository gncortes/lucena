import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/blind_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../voice/view_models/speech_cubit.dart';

/// Confere o pré-requisito antes de pedir que o jogador escolha a posição.
class BlindEntryScreen extends StatefulWidget {
  const BlindEntryScreen({this.resume = false, super.key});

  final bool resume;

  @override
  State<BlindEntryScreen> createState() => _BlindEntryScreenState();
}

class _BlindEntryScreenState extends State<BlindEntryScreen>
    with WidgetsBindingObserver {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SpeechCubit>().reloadVoices();
    }
  }

  void _return() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.allModes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final speech = context.watch<SpeechCubit>().state;
    final available = speech.availableFor(
      Localizations.localeOf(context).toLanguageTag(),
    );
    if (speech.loaded && available && !_opening) {
      _opening = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement(
            widget.resume ? Routes.blind : Routes.blindCatalog,
          );
        }
      });
    }
    return Scaffold(
      key: BlindKeys.entry,
      appBar: LucenaAppBar(title: Text(l10n.blindTitle)),
      body: !speech.loaded || available
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: EmptyState(
                messageKey: BlindKeys.voiceRequired,
                icon: Icons.record_voice_over_outlined,
                message:
                    '${l10n.blindVoiceRequired}\n\n${l10n.voiceUnavailable}',
              ),
            ),
      bottomNavigationBar: !speech.loaded || available
          ? null
          : ActionsFooter(
              stacked: true,
              children: [
                FilledButton(
                  key: BlindKeys.openVoices,
                  onPressed: context.read<SpeechCubit>().openSystemVoices,
                  child: Text(l10n.voiceOpenSystem),
                ),
                TextButton(onPressed: _return, child: Text(l10n.allModesTitle)),
              ],
            ),
    );
  }
}
