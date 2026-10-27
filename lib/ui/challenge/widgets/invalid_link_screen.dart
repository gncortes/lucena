import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/theme/app_spacing.dart';

/// O erro fica sobre a atividade anterior; colar outro link não a substitui.
class InvalidLinkScreen extends StatelessWidget {
  const InvalidLinkScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _paste(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    final uri = Uri.tryParse(data?.text?.trim() ?? '');
    final route = uri == null ? null : Routes.appLink(uri);
    if (route == null || route == Routes.invalidLink) {
      showLucenaSnackBar(context, context.l10n.challengeInvalidLinkMessage);
      return;
    }
    context.pushReplacement(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: ChallengeKeys.invalidScreen,
      appBar: LucenaAppBar(
        title: Text(l10n.journeyChallengeTitle),
        leading: IconButton(
          key: ChallengeKeys.invalidBack,
          tooltip: l10n.challengeInvalidLinkBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _back(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  l10n.challengeInvalidLinkTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ErrorState(
                messageKey: ChallengeKeys.invalidMessage,
                message: l10n.challengeInvalidLinkMessage,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionsFooter(
        children: [
          FilledButton.icon(
            key: ChallengeKeys.invalidPaste,
            onPressed: () => _paste(context),
            icon: const Icon(Icons.content_paste),
            label: Text(l10n.challengeInvalidLinkPaste),
          ),
        ],
      ),
    );
  }
}
