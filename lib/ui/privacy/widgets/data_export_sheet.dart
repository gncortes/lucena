import 'package:flutter/material.dart';

import '../../core/motion/botao_carregando.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/view_models/privacy.dart';
import '../../core/keys/privacy_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import '../view_models/data_export_cubit.dart';

/// "Baixar seus dados?" (H-CON-21; quadros PropV1ContaDadosBaixar,
/// …Baixando, …Pronto e …Erro): a mesma folha troca de quadro.
Future<void> showDataExportSheet(BuildContext context, {required String uid}) {
  final cubit = createDataExportCubit(context, uid: uid);
  return showLucenaSheet<void>(
    context,
    sheetKey: PrivacyKeys.downloadSheet,
    closeKey: PrivacyKeys.downloadClose,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const DataExportSheet()),
  ).whenComplete(cubit.close);
}

class DataExportSheet extends StatelessWidget {
  const DataExportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<DataExportCubit, DataExportState>(
      listenWhen: (before, now) => now.step == DataExportStep.cancelled,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) {
        final cubit = context.read<DataExportCubit>();
        void close() => Navigator.of(context).pop();
        final (title, hint) = switch (state.step) {
          DataExportStep.ready => (
            l10n.conDadosReadyTitle,
            l10n.conDadosReadyText,
          ),
          DataExportStep.error => (
            l10n.conDadosErrorTitle,
            l10n.conDadosErrorText,
          ),
          _ => (l10n.conDadosAskTitle, l10n.conDadosAskText),
        };
        final buttons = switch (state.step) {
          DataExportStep.ask || DataExportStep.cancelled => [
            FilledButton.icon(
              key: PrivacyKeys.downloadStart,
              onPressed: cubit.download,
              icon: const Icon(Icons.download),
              label: Text(l10n.conDadosStart),
            ),
            OutlinedButton(onPressed: close, child: Text(l10n.conDadosCancel)),
          ],
          DataExportStep.downloading => [
            BotaoCarregando(
              buttonKey: PrivacyKeys.downloading,
              busy: true,
              onPressed: null,
              label: l10n.conDadosDownloading,
            ),
            OutlinedButton(
              onPressed: cubit.cancel,
              child: Text(l10n.conDadosCancel),
            ),
          ],
          DataExportStep.ready => [
            FilledButton.icon(
              key: PrivacyKeys.downloadOpen,
              onPressed: () async {
                await cubit.open();
                if (context.mounted) close();
              },
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.conDadosOpen),
            ),
            OutlinedButton(onPressed: close, child: Text(l10n.conDadosClose)),
          ],
          DataExportStep.error => [
            FilledButton.icon(
              key: PrivacyKeys.downloadRetry,
              onPressed: cubit.download,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.conDadosRetry),
            ),
            OutlinedButton(onPressed: close, child: Text(l10n.conDadosClose)),
          ],
        };
        return KeyedSubtree(
          key: switch (state.step) {
            DataExportStep.ready => PrivacyKeys.downloadReady,
            DataExportStep.error => PrivacyKeys.downloadError,
            _ => null,
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: title, hint: hint),
              ActionsFooter(
                stacked: true,
                margin: AppSpacing.xl,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                children: buttons,
              ),
            ],
          ),
        );
      },
    );
  }
}
