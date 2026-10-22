import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/rating_level.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_button_text.dart';
import '../../core/theme/app_spacing.dart';
import '../../goal/widgets/goal_sheet.dart';
import '../../goal/widgets/goal_ui.dart';
import '../view_models/profile_cubit.dart';
import 'rating_level_sheet.dart';
import 'rating_level_ui.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/nickname_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nickname = TextEditingController();
  final _nicknameFocus = FocusNode();

  // A faixa confirmada no painel; só é gravada ao salvar.
  RatingLevel? _level;

  @override
  void initState() {
    super.initState();
    _fill(context.read<ProfileCubit>().state);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  // A tela recebe o perfil gravado uma vez só; depois valem as edições.
  void _fill(UserProfile? profile) {
    if (_level != null || profile == null) return;
    _nickname.text = profile.nickname;
    _level = profile.level;
  }

  Future<void> _pickLevel(RatingLevel current) async {
    // Fecha o teclado e não deixa o foco voltar ao apelido quando o painel
    // fechar (o teclado abriria de novo sozinho).
    _nicknameFocus.unfocus();
    _nicknameFocus.canRequestFocus = false;
    final picked = await showRatingLevelSheet(context, selected: current);
    if (!mounted) return;
    if (picked != null) setState(() => _level = picked);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nicknameFocus.canRequestFocus = true;
    });
  }

  Future<void> _pickGoal(UserProfile? profile) async {
    final cubit = context.read<ProfileCubit>();
    _nicknameFocus.unfocus();
    final goal = await showGoalSheet(context, selected: profile?.goal);
    if (goal != null) await cubit.setGoal(goal);
  }

  Future<void> _takeTest() async {
    final cubit = context.read<ProfileCubit>();
    final used = await context.push<bool>(Routes.placementFrom('settings'));
    if (used == true) await cubit.load();
  }

  // "Seu nível" grava o rating na hora; a faixa acima passa a ser a dele.
  Future<void> _openLevel() async {
    final cubit = context.read<ProfileCubit>();
    _nicknameFocus.unfocus();
    await context.push(Routes.levelFrom('profile'));
    await cubit.load();
    if (!mounted) return;
    setState(() => _level = cubit.state?.level ?? _level);
  }

  Future<void> _save(RatingLevel level) async {
    await context.read<ProfileCubit>().save(
      nickname: _nickname.text,
      level: level,
    );
    if (mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ProfileCubit, UserProfile?>(
      listener: (context, profile) => setState(() => _fill(profile)),
      builder: (context, profile) {
        final level = _level;
        return Scaffold(
          key: ProfileKeys.screen,
          appBar: LucenaAppBar(title: Text(l10n.settingsProfile)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                NicknameField(
                  fieldKey: ProfileKeys.nicknameField,
                  controller: _nickname,
                  focusNode: _nicknameFocus,
                  label: l10n.profileNickname,
                  hint: l10n.profileNicknameDefault,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (level != null)
                  _LevelField(level: level, onTap: () => _pickLevel(level)),
                // O teste de nível de novo: não apaga progresso; usado o
                // resultado, a faixa acima muda.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: ProfileKeys.placementTest,
                    onPressed: _takeTest,
                    icon: const Icon(Icons.quiz_outlined),
                    label: Text(l10n.placementTake),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  key: ProfileKeys.rowLevel,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.show_chart),
                  title: Text(l10n.levelTitle),
                  subtitle: profile == null
                      ? null
                      : Text(profile.rating.toString()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openLevel,
                ),
                // Grava na hora: a folha tem o próprio "Salvar".
                ListTile(
                  key: ProfileKeys.rowGoal,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag),
                  title: Text(l10n.profileGoal),
                  subtitle: Text(
                    profile?.goal?.title(l10n) ?? l10n.profileGoalNone,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickGoal(profile),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  key: ProfileKeys.saveButton,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonHeight),
                    textStyle: AppButtonText.footer(context),
                  ),
                  onPressed: level == null ? null : () => _save(level),
                  child: Text(l10n.profileSave),
                ),
                const SizedBox(height: AppSpacing.lg),
                // O rating de finais fica no histórico, com os detalhes.
                OutlinedButton.icon(
                  key: ProfileKeys.ratingCard,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonHeight),
                    textStyle: AppButtonText.footer(context),
                  ),
                  onPressed: () => context.push(Routes.rating),
                  icon: const Icon(Icons.show_chart_rounded),
                  label: Text(l10n.ratingHistory),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Parece um campo de formulário, mas abre o painel de escolha da faixa.
class _LevelField extends StatelessWidget {
  const _LevelField({required this.level, required this.onTap});

  final RatingLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Semantics(
      button: true,
      child: InkWell(
        key: ProfileKeys.levelField,
        borderRadius: BorderRadius.circular(AppShape.small),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.profileRating,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: Row(
            children: [
              LevelBadge(level: level),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name(l10n),
                      key: ProfileKeys.levelName,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      level.describe(l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
