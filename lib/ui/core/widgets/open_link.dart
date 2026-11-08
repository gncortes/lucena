import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/links/link_repository.dart';
import '../keys/core_keys.dart';
import '../l10n/l10n.dart';
import 'lucena_snack_bar.dart';

/// Abre [url] fora do app; se não abrir (sem navegador, falha), avisa
/// (Gap 6 do Sobre).
Future<void> openLink(BuildContext context, Uri url) async {
  final message = context.l10n.ajuLinkError;
  final opened = await context.read<LinkRepository>().open(url);
  if (opened || !context.mounted) return;
  showLucenaSnackBar(
    context,
    message,
    icon: Icons.error_outline,
    key: CoreKeys.linkFailure,
  );
}
