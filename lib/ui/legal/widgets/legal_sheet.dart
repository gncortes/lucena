import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/legal/legal_repository.dart';
import '../../../domain/models/legal_document.dart';
import '../../core/keys/legal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/open_link.dart';
import '../../core/widgets/sheet_header.dart';

/// Abre os Termos ou a Política numa folha, com o texto embarcado (funciona
/// sem internet). No idioma sem texto embarcado, abre [website].
/// Usada pelo Sobre, por Privacidade e dados e pela conta (H-AJU-14,
/// H-CON-22): componente único.
Future<void> openLegal(
  BuildContext context,
  LegalKind kind, {
  required Uri website,
}) async {
  final language = Localizations.localeOf(context).languageCode;
  final document = await context.read<LegalRepository>().load(kind, language);
  if (!context.mounted) return;
  if (document == null) return openLink(context, website);
  final l10n = context.l10n;
  await showLucenaSheet<void>(
    context,
    sheetKey: LegalKeys.sheet,
    closeKey: LegalKeys.close,
    builder: (context) => LegalSheet(
      kind: kind,
      title: switch (kind) {
        LegalKind.terms => l10n.aboutTerms,
        LegalKind.privacy => l10n.aboutPrivacy,
      },
      hint: shownAddress(website),
      document: document,
    ),
  );
}

/// O endereço como aparece: sem `https://` e sem a barra do fim.
String shownAddress(Uri uri) {
  final text = '${uri.host}${uri.path}';
  return text.endsWith('/') ? text.substring(0, text.length - 1) : text;
}

/// O conteúdo da folha (PropV1LegalTermosSobre): cabeçalho fixo com título e
/// endereço; o texto rola por baixo.
class LegalSheet extends StatelessWidget {
  const LegalSheet({
    required this.kind,
    required this.title,
    required this.hint,
    required this.document,
    super.key,
  });

  final LegalKind kind;
  final String title;
  final String hint;
  final LegalDocument document;

  /// A folha ocupa 80% da tela (734 de 917 no quadro).
  static const heightFactor = 0.8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final body = text.bodyLarge?.copyWith(
      fontSize: 15,
      height: 23 / 15,
      color: theme.colorScheme.onSurface.withValues(alpha: .9),
    );
    final heading = text.titleMedium?.copyWith(
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w700,
    );
    final height = MediaQuery.sizeOf(context).height * heightFactor;
    return SizedBox(
      key: kind == LegalKind.terms ? LegalKeys.terms : LegalKeys.privacy,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(key: LegalKeys.title, title: title, hint: hint),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: ListView(
              key: LegalKeys.body,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                20,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              children: [
                Row(
                  spacing: AppSpacing.sm,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppShape.small),
                      child: Image.asset(
                        'assets/branding/launcher_icon.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                    Text(
                      context.l10n.appTitle,
                      style: text.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: text.headlineSmall?.copyWith(
                    fontSize: 26,
                    height: 34 / 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final block in document.intro) ...[
                  const SizedBox(height: 20),
                  _Block(block, style: body),
                ],
                for (final (index, section) in document.sections.indexed) ...[
                  const SizedBox(height: 20),
                  Text(
                    section.title,
                    key: LegalKeys.section(index),
                    style: heading,
                  ),
                  for (final block in section.blocks) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _Block(block, style: body),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.block, {required this.style});

  final LegalBlock block;
  final TextStyle? style;

  static TextSpan _spans(List<LegalSpan> spans) => TextSpan(
    children: [
      for (final span in spans)
        TextSpan(
          text: span.text,
          style: span.bold
              ? const TextStyle(fontWeight: FontWeight.w700)
              : null,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => switch (block) {
    LegalParagraph(:final spans) => Text.rich(_spans(spans), style: style),
    LegalBullet(:final spans) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: style),
        Expanded(child: Text.rich(_spans(spans), style: style)),
      ],
    ),
    // Numa tela de celular, cada linha da tabela vira um bloco: a primeira
    // célula em negrito e as outras com o nome da coluna.
    LegalTable(:final header, :final rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        for (final row in rows)
          Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < row.length; i++)
                  if (i == 0)
                    TextSpan(
                      text: row[i],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )
                  else
                    TextSpan(
                      text:
                          '\n${i < header.length ? header[i] : ''}: '
                          '${row[i]}',
                    ),
              ],
            ),
            style: style,
          ),
      ],
    ),
  };
}
