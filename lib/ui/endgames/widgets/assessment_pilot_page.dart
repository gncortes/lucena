import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../domain/models/assessment_attempt.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/now.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/position_board.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/assessment_cubit.dart';
import '../view_models/assessment_pilot_factory.dart';
import 'assessment_response_form.dart';
import 'assessment_screen.dart';

/// Route composition for the U1 pilot. Owns only the cubit created here;
/// AssessmentScreen performs the single initial load.
class AssessmentPilotPage extends StatefulWidget {
  const AssessmentPilotPage({this.create, this.onBack, super.key});

  final Future<AssessmentCubit> Function()? create;
  final VoidCallback? onBack;

  @override
  State<AssessmentPilotPage> createState() => _AssessmentPilotPageState();
}

class _AssessmentPilotPageState extends State<AssessmentPilotPage> {
  AssessmentCubit? _cubit;
  bool _loading = false, _failed = false;
  int _request = 0, _relationIds = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    if (!mounted || _loading || _cubit != null) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final cubit =
          await (widget.create?.call() ??
              AssessmentPilotFactory(
                opponent: context.read<OpponentRepository>(),
                now: context.read<Now>(),
              ).create());
      if (!mounted || request != _request) {
        await cubit.close();
        return;
      }
      setState(() {
        _cubit = cubit;
        _loading = false;
      });
    } on Object {
      if (mounted && request == _request) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _request++;
    final cubit = _cubit;
    if (cubit != null) unawaited(cubit.close());
    super.dispose();
  }

  void _back() {
    if (!mounted) return;
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
    } else {
      context.go(Routes.endgames);
    }
  }

  Future<bool> _confirm(String message) async =>
      await showLucenaSheet<bool>(
        context,
        sheetKey: AssessmentPilotKeys.confirmSheet,
        closeKey: AssessmentPilotKeys.sheetClose,
        builder: (sheet) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 16),
              OutlinedButton(
                key: AssessmentPilotKeys.cancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(kButtonHeight),
                ),
                onPressed: () => Navigator.of(sheet).pop(false),
                child: Text(MaterialLocalizations.of(sheet).cancelButtonLabel),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: AssessmentPilotKeys.confirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(kButtonHeight),
                ),
                onPressed: () => Navigator.of(sheet).pop(true),
                child: Text(sheet.l10n.commonConfirm),
              ),
            ],
          ),
        ),
      ) ??
      false;

  Future<Set<String>?> _pick(
    AssessmentFormSnapshot? snapshot,
    Set<String> selected,
    Side orientation,
  ) => showLucenaSheet<Set<String>>(
    context,
    sheetKey: AssessmentPilotKeys.pickerSheet,
    closeKey: AssessmentPilotKeys.sheetClose,
    builder: (_) => _AssessmentSquarePicker(
      snapshot: snapshot,
      selected: selected,
      orientation: orientation,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = _cubit;
    if (cubit == null) {
      return Scaffold(
        key: AssessmentPilotKeys.page,
        appBar: LucenaAppBar(
          title: Text(l.assessmentTitle),
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: AssessmentPilotKeys.back,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loading)
                    const CircularProgressIndicator(
                      key: AssessmentPilotKeys.loading,
                    ),
                  Text(
                    _failed
                        ? l.assessmentTechnicalFailure
                        : l.assessmentLoading,
                  ),
                  if (_failed)
                    FilledButton(
                      key: AssessmentPilotKeys.retry,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(kButtonHeight),
                      ),
                      onPressed: _prepare,
                      child: Text(l.lessonRetry),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final board = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    String piece(AssessmentPiece value) => switch (value) {
      AssessmentPiece.king => l.pieceKing,
      AssessmentPiece.bishop => l.pieceBishop,
      AssessmentPiece.knight => l.pieceKnight,
    };
    String squares(Set<String> values) {
      final sorted = values.toList()..sort();
      return sorted.isEmpty
          ? l.assessmentNoSquares
          : l.assessmentSquares(sorted.join(', '));
    }

    return AssessmentScreen(
      key: AssessmentPilotKeys.collector,
      cubit: cubit,
      boardSettings: board,
      labels: AssessmentScreenLabels(
        title: l.assessmentTitle,
        loading: l.assessmentLoading,
        technicalFailure: l.assessmentTechnicalFailure,
        retry: l.lessonRetry,
        exit: l.assessmentExit,
        submitInitial: l.assessmentSubmitInitial,
        finishExecution: l.assessmentFinishExecution,
        submitProtection: l.assessmentSubmitProtection,
        closed: l.assessmentClosed,
        phase: (phase) => l.assessmentPhase(phase.name),
        remaining: (remaining) => l.assessmentRemaining(remaining.inSeconds),
        snapshot: (ref, fen) => ref == 'ply:0'
            ? l.assessmentMoment('initial')
            : l.assessmentSnapshot(int.parse(ref.substring(4))),
        newAttempt: l.assessmentNewAttempt,
      ),
      responseLabels: AssessmentResponseLabels(
        target: l.assessmentTarget,
        corner: l.assessmentCorner,
        referencePiece: l.assessmentReferencePiece,
        color: l.assessmentColor,
        sameColor: l.assessmentSameColor,
        otherColor: l.assessmentOtherColor,
        accessSquares: l.assessmentAccessSquares,
        confirmTarget: l.assessmentConfirmTarget,
        removeTarget: l.assessmentRemoveTarget,
        relation: l.assessmentRelations,
        piece: l.assessmentChoosePiece,
        kind: l.assessmentChooseKind,
        moment: l.assessmentChooseMoment,
        snapshot: l.assessmentChooseSnapshot,
        relationSquares: l.assessmentRelationSquares,
        components: l.assessmentComponents,
        confirmRelation: l.assessmentConfirmRelation,
        cancelEdit: l.assessmentCancelEdit,
        edit: l.assessmentEdit,
        remove: l.assessmentRemove,
        cornerLabel: (corner) => corner,
        pieceLabel: piece,
        kindLabel: (kind) => l.assessmentKind(kind.name),
        momentLabel: (moment) => l.assessmentMoment(moment.name),
        componentLabel: (component) => l.assessmentComponent(component.name),
        squaresLabel: squares,
        relationLabel: (relation) => l.assessmentRelationSummary(
          piece(relation.piece),
          l.assessmentKind(relation.kind.name),
          squares(relation.targetSquares),
        ),
      ),
      pickSquares: (snapshot, selected) =>
          _pick(snapshot, selected, cubit.config.student),
      createRelationId: () =>
          '${cubit.config.now().toUtc().microsecondsSinceEpoch}-${++_relationIds}',
      confirmFinishExecution: () => _confirm(l.assessmentFinishConfirmation),
      confirmExit: () => _confirm(l.assessmentExitConfirmation),
      confirmRemoveTarget: () => _confirm(l.assessmentRemoveConfirmation),
      confirmRemoveRelation: (_) => _confirm(l.assessmentRemoveConfirmation),
      confirmNewAttempt: () => _confirm(l.assessmentNewAttemptConfirmation),
      onExit: _back,
    );
  }
}

class _AssessmentSquarePicker extends StatefulWidget {
  const _AssessmentSquarePicker({
    required this.snapshot,
    required this.selected,
    required this.orientation,
  });
  final AssessmentFormSnapshot? snapshot;
  final Set<String> selected;
  final Side orientation;
  @override
  State<_AssessmentSquarePicker> createState() =>
      _AssessmentSquarePickerState();
}

class _AssessmentSquarePickerState extends State<_AssessmentSquarePicker> {
  late final _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final snapshot = widget.snapshot;
    final sorted = _selected.toList()..sort();
    Widget inset(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              inset(Text(l.assessmentPickSquares)),
              inset(Text(snapshot?.label ?? l.assessmentUnrepresented)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, box) => SizedBox.square(
                  dimension: box.maxWidth,
                  child: Stack(
                    children: [
                      if (snapshot != null)
                        PositionBoard(
                          key: AssessmentPilotKeys.pickerBoard,
                          fen: snapshot.fen,
                          size: box.maxWidth,
                          orientation: widget.orientation,
                          coordinates: true,
                          radius: 0,
                          shapes: {
                            for (final square in _selected)
                              Circle(
                                color: colors.primary,
                                orig: Square.fromName(square),
                              ),
                          },
                        ),
                      GridView.count(
                        key: AssessmentPilotKeys.squareGrid,
                        crossAxisCount: 8,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var index = 0; index < 64; index++)
                            _cell(index, snapshot == null),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              inset(
                Text(
                  sorted.isEmpty
                      ? l.assessmentNoSquares
                      : l.assessmentSquares(sorted.join(', ')),
                ),
              ),
              const SizedBox(height: 12),
              inset(
                OutlinedButton(
                  key: AssessmentPilotKeys.cancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonHeight),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              inset(
                FilledButton(
                  key: AssessmentPilotKeys.confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonHeight),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(Set<String>.of(_selected)),
                  child: Text(l.commonConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(int index, bool neutral) {
    final file = widget.orientation == Side.white ? index % 8 : 7 - index % 8;
    final rank = widget.orientation == Side.white
        ? 8 - index ~/ 8
        : 1 + index ~/ 8;
    final square = '${String.fromCharCode(97 + file)}$rank';
    final selected = _selected.contains(square);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: square,
      selected: selected,
      button: true,
      child: InkWell(
        key: AssessmentPilotKeys.square(square),
        onTap: () => setState(() {
          if (!_selected.add(square)) _selected.remove(square);
        }),
        child: neutral
            ? Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primaryContainer
                      : colors.surfaceContainerLow,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: ExcludeSemantics(child: Text(square)),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
