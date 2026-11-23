import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/glossary_term.dart';
import '../../core/keys/glossary_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/glossary_cubit.dart';
import 'glossary_term_sheet.dart';

/// O Glossário, a mesma tela em todo o app (protótipo `telaGloss`): busca
/// com rótulo flutuante, a contagem e um cartão de 72 por termo. Com
/// [openTermId] (o termo tocado numa fala), abre já filtrada e mostra a
/// Wikipédia do termo ou, sem internet ou sem verbete, a folha dele.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({this.openTermId, super.key});

  final String? openTermId;

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  late final _controller = TextEditingController(
    text: context.read<GlossaryCubit>().state.query,
  );
  var _opened = false;

  @override
  void initState() {
    super.initState();
    _openTermWhenLoaded(context.read<GlossaryCubit>().state);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openTermWhenLoaded(GlossaryState state) {
    final id = widget.openTermId;
    if (_opened || id == null || state.loading) return;
    _opened = true;
    final term = state.termById(id);
    if (term == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openTerm(term));
  }

  Future<void> _openTerm(GlossaryTerm term) async {
    if (!mounted) return;
    final cubit = context.read<GlossaryCubit>();
    final online = term.wikiUrl != null && await cubit.checkOnline();
    if (!mounted) return;
    if (online) {
      await showGlossaryWiki(context, term);
    } else {
      await showGlossaryTermSheet(context, term);
    }
  }

  void _clear() {
    _controller.clear();
    context.read<GlossaryCubit>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<GlossaryCubit, GlossaryState>(
      listenWhen: (a, b) => a.loading != b.loading,
      listener: (context, state) => _openTermWhenLoaded(state),
      child: Scaffold(
        key: GlossaryKeys.screen,
        appBar: LucenaAppBar(
          leading: const BackButton(key: GlossaryKeys.back),
          title: Text(l10n.glossaryTitle),
          centerTitle: true,
        ),
        body: BlocBuilder<GlossaryCubit, GlossaryState>(
          builder: (context, state) => _Body(
            state: state,
            controller: _controller,
            onClear: _clear,
            onTerm: (term) => showGlossaryTermSheet(context, term),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.controller,
    required this.onClear,
    required this.onTerm,
  });

  final GlossaryState state;
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<GlossaryTerm> onTerm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final results = state.results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: TextField(
            key: GlossaryKeys.search,
            controller: controller,
            onChanged: context.read<GlossaryCubit>().search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l10n.glossarySearchLabel,
              hintText: l10n.glossarySearchHint,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.query.isEmpty
                  ? null
                  : IconButton(
                      key: GlossaryKeys.searchClear,
                      tooltip: MaterialLocalizations.of(context)
                          .deleteButtonTooltip,
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(AppShape.medium),
                ),
              ),
            ),
          ),
        ),
        if (!state.loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.glossaryCount(results.length),
              key: GlossaryKeys.count,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(
          child: state.empty
              ? KeyedSubtree(
                  key: GlossaryKeys.empty,
                  child: EmptyState(
                    style: EmptyStateStyle.text,
                    message: l10n.glossaryEmpty(state.query.trim()),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  itemCount: results.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _TermCard(term: results[index], onTap: onTerm),
                ),
        ),
      ],
    );
  }
}

/// O cartão do termo: nome e o começo da definição numa linha, e a seta.
class _TermCard extends StatelessWidget {
  const _TermCard({required this.term, required this.onTap});

  final GlossaryTerm term;
  final ValueChanged<GlossaryTerm> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LucenaCard(
      key: GlossaryKeys.term(term.id),
      onTap: () => onTap(term),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SizedBox(
        height: 72 - 2 * AppSpacing.sm,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    term.definition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
