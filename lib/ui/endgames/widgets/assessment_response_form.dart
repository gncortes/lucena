import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../domain/models/assessment_attempt.dart';
import '../../core/theme/app_button.dart';

/// Public position supplied by the caller, without answers or evaluation.
class AssessmentFormSnapshot {
  const AssessmentFormSnapshot({
    required this.ref,
    required this.fen,
    required this.label,
  });

  final String ref;
  final String fen;
  final String label;
}

/// A null snapshot means the user explicitly chose an unrepresented position.
typedef AssessmentSquarePicker = Future<Set<String>?> Function(
  AssessmentFormSnapshot? snapshot,
  Set<String> selected,
);

/// All visible and accessible strings come from the caller's localization.
class AssessmentResponseLabels {
  const AssessmentResponseLabels({
    required this.target,
    required this.corner,
    required this.referencePiece,
    required this.color,
    required this.sameColor,
    required this.otherColor,
    required this.accessSquares,
    required this.confirmTarget,
    required this.removeTarget,
    required this.relation,
    required this.piece,
    required this.kind,
    required this.moment,
    required this.snapshot,
    required this.relationSquares,
    required this.components,
    required this.confirmRelation,
    required this.cancelEdit,
    required this.edit,
    required this.remove,
    required this.cornerLabel,
    required this.pieceLabel,
    required this.kindLabel,
    required this.momentLabel,
    required this.componentLabel,
    required this.squaresLabel,
    required this.relationLabel,
  });

  final String target, corner, referencePiece, color, sameColor, otherColor;
  final String accessSquares, confirmTarget, removeTarget, relation, piece;
  final String kind, moment, snapshot, relationSquares, components;
  final String confirmRelation, cancelEdit, edit, remove;
  final String Function(String) cornerLabel;
  final String Function(AssessmentPiece) pieceLabel;
  final String Function(AssessmentRelationKind) kindLabel;
  final String Function(AssessmentMoment) momentLabel;
  final String Function(AssessmentComponent) componentLabel;
  final String Function(Set<String>) squaresLabel;
  final String Function(AssessmentRelation) relationLabel;
}

/// Controlled collection: partial choices are emitted in [AssessmentDraft.editing]
/// for the caller to persist. Targets and relations need explicit confirmation.
/// Restoration uses editing exactly, without filling gaps from confirmed units.
/// Pass only the current phase draft. Submitted initial responses stay in the
/// session's immutable submission and must never become the protection draft.
/// Place this form inside the caller's scroll view. No board is created here.
/// Use an attempt-scoped key so replacing the attempt disposes pending actions.
class AssessmentResponseForm extends StatefulWidget {
  const AssessmentResponseForm({
    required this.value,
    required this.phase,
    required this.currentSnapshot,
    required this.visitedSnapshots,
    required this.labels,
    required this.pickSquares,
    required this.createRelationId,
    required this.onChanged,
    this.confirmRemoveTarget,
    this.confirmRemoveRelation,
    this.enabled = true,
    this.busy = false,
    super.key,
  });

  final AssessmentDraft value;
  final AssessmentPhase phase;
  final AssessmentFormSnapshot currentSnapshot;
  final List<AssessmentFormSnapshot> visitedSnapshots;
  final AssessmentResponseLabels labels;
  final AssessmentSquarePicker pickSquares;

  /// Must return a fresh, nonempty identity for each newly confirmed relation.
  final String Function() createRelationId;
  final ValueChanged<AssessmentDraft> onChanged;

  /// Caller owns confirmation. Without a callback removal is disabled.
  final Future<bool> Function()? confirmRemoveTarget;
  final Future<bool> Function(AssessmentRelation relation)?
  confirmRemoveRelation;
  final bool enabled, busy;

  @override
  State<AssessmentResponseForm> createState() => _AssessmentResponseFormState();
}

class _AssessmentResponseFormState extends State<AssessmentResponseForm> {
  String? _corner;
  AssessmentPiece? _colorPiece, _piece;
  bool? _sameColor;
  Set<String> _access = {}, _squares = {};
  AssessmentRelationKind? _kind;
  AssessmentMoment? _moment;
  String? _snapshotRef, _editingId;
  Set<AssessmentComponent> _components = {};
  bool _picking = false;
  int _epoch = 0;
  String? _localEmission;

  bool get _active =>
      widget.enabled &&
      !widget.busy &&
      !_picking &&
      (widget.phase == AssessmentPhase.initial ||
          widget.phase == AssessmentPhase.protection);

  List<AssessmentFormSnapshot> get _snapshots =>
      widget.phase == AssessmentPhase.initial
      ? [widget.currentSnapshot]
      : widget.phase == AssessmentPhase.protection
      ? widget.visitedSnapshots
      : [];

  AssessmentFormSnapshot? get _selectedSnapshot {
    for (final snapshot in _snapshots) {
      if (snapshot.ref == _snapshotRef) return snapshot;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _restoreEditing();
  }

  void _restoreEditing() {
    final editing = widget.value.editing;
    _corner = editing.corner;
    _colorPiece = editing.colorPiece;
    _sameColor = editing.sameColor;
    _access = {...editing.accessSquares};
    _editingId = editing.relationId;
    _piece = editing.relationPiece;
    _kind = editing.relationKind;
    _moment = editing.relationMoment;
    _snapshotRef = editing.relationSnapshotRef;
    _squares = {...editing.relationTargets};
    _components = {...editing.relationUseFor};
  }

  AssessmentEditingState get _editing => AssessmentEditingState(
    corner: _corner,
    colorPiece: _colorPiece,
    sameColor: _sameColor,
    accessSquares: _access,
    relationId: _editingId,
    relationPiece: _piece,
    relationKind: _kind,
    relationMoment: _moment,
    relationSnapshotRef: _snapshotRef,
    relationTargets: _squares,
    relationUseFor: _components,
  );

  void _emitEditing() => _emit(
    AssessmentDraft(
      target: widget.value.target,
      relations: widget.value.relations,
      editing: _editing,
    ),
  );

  void _changeEditing(VoidCallback change) {
    if (!_active) return;
    final before = jsonEncode(_editing.toJson());
    setState(change);
    if (jsonEncode(_editing.toJson()) != before) _emitEditing();
  }

  String _positions(AssessmentResponseForm form) => jsonEncode([
    form.phase.name,
    [form.currentSnapshot.ref, form.currentSnapshot.fen],
    for (final s in form.visitedSnapshots) [s.ref, s.fen],
  ]);

  @override
  void didUpdateWidget(covariant AssessmentResponseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        jsonEncode(oldWidget.value.toJson()) !=
        jsonEncode(widget.value.toJson());
    final positionsChanged = _positions(oldWidget) != _positions(widget);
    if (changed || positionsChanged) {
      _epoch++;
      _picking = false;
      // Acknowledging a local selection must preserve the other editor.
      final localAck = jsonEncode(widget.value.toJson()) == _localEmission;
      if (positionsChanged || !localAck) {
        _restoreEditing();
      }
    } else if (oldWidget.busy != widget.busy ||
        oldWidget.enabled != widget.enabled) {
      _epoch++;
      _picking = false;
    }
    _localEmission = null;
  }

  void _emit(AssessmentDraft draft) {
    _localEmission = jsonEncode(draft.toJson());
    widget.onChanged(draft);
  }

  void _clearTarget() {
    _corner = null;
    _colorPiece = null;
    _sameColor = null;
    _access = {};
  }

  void _clearRelation() {
    _editingId = null;
    _piece = null;
    _kind = null;
    _moment = null;
    _snapshotRef = null;
    _squares = {};
    _components = {};
  }

  bool _validSquares(Set<String> squares) =>
      squares.isNotEmpty &&
      squares.every((s) => RegExp(r'^[a-h][1-8]$').hasMatch(s));

  bool get _completeTarget =>
      ['a1', 'a8', 'h1', 'h8'].contains(_corner) &&
      _colorPiece != null &&
      _sameColor != null &&
      _validSquares(_access);
  bool get _completeRelation =>
      _piece != null &&
      _kind != null &&
      _moment != null &&
      _components.isNotEmpty &&
      _components.every(_allowedComponents.contains) &&
      _validSquares(_squares) &&
      (_moment == AssessmentMoment.plannedOrUnrepresented ||
          _selectedSnapshot != null);

  Future<void> _pick(bool target) async {
    if (!_active) return;
    AssessmentFormSnapshot? snapshot;
    if (target) {
      for (final candidate in _snapshots) {
        if (candidate.ref == widget.currentSnapshot.ref) snapshot = candidate;
      }
      if (snapshot == null) return;
    } else {
      if (_moment == null) return;
      snapshot = _selectedSnapshot;
      if (_moment != AssessmentMoment.plannedOrUnrepresented &&
          snapshot == null) {
        return;
      }
    }
    final epoch = ++_epoch;
    setState(() => _picking = true);
    try {
      final result = await widget.pickSquares(
        snapshot,
        Set.unmodifiable(target ? _access : _squares),
      );
      if (!mounted || epoch != _epoch) return;
      if (result != null &&
          result.every((s) => RegExp(r'^[a-h][1-8]$').hasMatch(s))) {
        final before = jsonEncode(_editing.toJson());
        setState(() {
          if (target) {
            _access = {...result};
          } else {
            _squares = {...result};
          }
          _picking = false;
        });
        if (jsonEncode(_editing.toJson()) != before) _emitEditing();
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _picking = false);
    }
  }

  Future<void> _confirmRemoval(
    Future<bool> Function() confirm,
    VoidCallback apply,
  ) async {
    if (!_active) return;
    final epoch = ++_epoch;
    final original = widget.value;
    final phase = widget.phase;
    final positions = _positions(widget);
    setState(() => _picking = true);
    try {
      final approved = await confirm();
      if (!mounted ||
          epoch != _epoch ||
          !approved ||
          !identical(widget.value, original) ||
          phase != widget.phase ||
          positions != _positions(widget)) {
        return;
      }
      apply();
    } finally {
      if (mounted && epoch == _epoch) setState(() => _picking = false);
    }
  }

  void _removeTarget() {
    final confirm = widget.confirmRemoveTarget;
    if (confirm == null || widget.phase != AssessmentPhase.initial) return;
    _confirmRemoval(confirm, () {
      setState(_clearTarget);
      _emit(
        AssessmentDraft(relations: widget.value.relations, editing: _editing),
      );
    });
  }

  void _removeRelation(AssessmentRelation relation) {
    final confirm = widget.confirmRemoveRelation;
    if (confirm == null) return;
    _confirmRemoval(() => confirm(relation), () {
      if (_editingId == relation.id) setState(_clearRelation);
      _emit(
        AssessmentDraft(
          target: widget.value.target,
          relations: widget.value.relations.where((r) => r.id != relation.id),
          editing: _editing,
        ),
      );
    });
  }

  void _confirmTarget() {
    if (!_active || !_completeTarget) return;
    _emit(
      AssessmentDraft(
        target: AssessmentTarget(
          corner: _corner!,
          colorPiece: _colorPiece!,
          sameColor: _sameColor!,
          accessSquares: _access,
        ),
        relations: widget.value.relations,
        editing: _editing,
      ),
    );
  }

  void _confirmRelation() {
    if (!_active || !_completeRelation) return;
    final id = _editingId ?? widget.createRelationId();
    if (id.isEmpty ||
        (_editingId == null && widget.value.relations.any((r) => r.id == id))) {
      return;
    }
    final relation = AssessmentRelation(
      id: id,
      snapshotRef: _moment == AssessmentMoment.plannedOrUnrepresented
          ? null
          : _snapshotRef,
      piece: _piece!,
      kind: _kind!,
      targetSquares: _squares,
      useFor: _components,
      moment: _moment!,
    );
    final relations = [...widget.value.relations];
    final index = relations.indexWhere((r) => r.id == id);
    if (index < 0) {
      relations.add(relation);
    } else {
      relations[index] = relation;
    }
    setState(_clearRelation);
    _emit(
      AssessmentDraft(
        target: widget.value.target,
        relations: relations,
        editing: _editing,
      ),
    );
  }

  void _edit(AssessmentRelation relation) {
    if (!_active) return;
    _changeEditing(() {
      _editingId = relation.id;
      _piece = relation.piece;
      _kind = relation.kind;
      _moment = relation.moment;
      _snapshotRef = relation.snapshotRef;
      _squares = {...relation.targetSquares};
      _components = {...relation.useFor}
          .intersection(_allowedComponents.toSet());
    });
  }

  List<AssessmentComponent> get _allowedComponents =>
      widget.phase == AssessmentPhase.protection
      ? const [AssessmentComponent.protection]
      : const [
          AssessmentComponent.target,
          AssessmentComponent.pieces,
          AssessmentComponent.protection,
        ];

  Widget _choices<T>(
    String key,
    String title,
    List<T> options,
    T? selected,
    String Function(T) label,
    ValueChanged<T> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final option in options)
            ChoiceChip(
              key: ValueKey(
                'assessment.$key.${option is Enum ? option.name : option}',
              ),
              label: Text(label(option)),
              selected: selected == option,
              onSelected: _active
                  ? (isSelected) {
                      if (!isSelected || selected == option) return;
                      _changeEditing(() => change(option));
                    }
                  : null,
            ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _button(String key, String label, VoidCallback? action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: OutlinedButton(
      key: ValueKey('assessment.$key'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kButtonHeight),
      ),
      onPressed: _active ? action : null,
      child: Text(label, textAlign: TextAlign.center),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.phase == AssessmentPhase.initial) ...[
          Text(l.target, style: Theme.of(context).textTheme.titleMedium),
          _choices(
            'corner',
            l.corner,
            ['a1', 'a8', 'h1', 'h8'],
            _corner,
            l.cornerLabel,
            (v) => _corner = v,
          ),
          _choices(
            'colorPiece',
            l.referencePiece,
            AssessmentPiece.values,
            _colorPiece,
            l.pieceLabel,
            (v) => _colorPiece = v,
          ),
          _choices(
            'color',
            l.color,
            [true, false],
            _sameColor,
            (v) => v ? l.sameColor : l.otherColor,
            (v) => _sameColor = v,
          ),
          _button('access', l.accessSquares, () => _pick(true)),
          Text(l.squaresLabel(Set.unmodifiable(_access))),
          _button(
            'confirmTarget',
            l.confirmTarget,
            _completeTarget ? _confirmTarget : null,
          ),
          if (widget.value.target != null)
            _button(
              'removeTarget',
              l.removeTarget,
              widget.confirmRemoveTarget == null ? null : _removeTarget,
            ),
        ],
        const SizedBox(height: 16),
        Text(l.relation, style: Theme.of(context).textTheme.titleMedium),
        for (final relation in widget.value.relations) ...[
          Text(l.relationLabel(relation)),
          _button('edit.${relation.id}', l.edit, () => _edit(relation)),
          _button(
            'remove.${relation.id}',
            l.remove,
            widget.confirmRemoveRelation == null
                ? null
                : () => _removeRelation(relation),
          ),
        ],
        _choices(
          'piece',
          l.piece,
          AssessmentPiece.values,
          _piece,
          l.pieceLabel,
          (v) => _piece = v,
        ),
        _choices(
          'kind',
          l.kind,
          AssessmentRelationKind.values,
          _kind,
          l.kindLabel,
          (v) => _kind = v,
        ),
        _choices(
          'moment',
          l.moment,
          AssessmentMoment.values,
          _moment,
          l.momentLabel,
          (v) {
            _moment = v;
            _snapshotRef = null;
            _squares = {};
          },
        ),
        if (_moment != null &&
            _moment != AssessmentMoment.plannedOrUnrepresented)
          _choices(
            'snapshot',
            l.snapshot,
            _snapshots.map((s) => s.ref).toList(),
            _snapshotRef,
            (ref) => _snapshots.firstWhere((s) => s.ref == ref).label,
            (v) {
              _snapshotRef = v;
              _squares = {};
            },
          ),
        _button(
          'relationSquares',
          l.relationSquares,
          _moment != null &&
                  (_selectedSnapshot != null ||
                      _moment == AssessmentMoment.plannedOrUnrepresented)
              ? () => _pick(false)
              : null,
        ),
        Text(l.squaresLabel(Set.unmodifiable(_squares))),
        Text(l.components, style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final component in _allowedComponents)
              FilterChip(
                key: ValueKey('assessment.component.${component.name}'),
                label: Text(l.componentLabel(component)),
                selected: _components.contains(component),
                onSelected: _active
                    ? (selected) => _changeEditing(() {
                        if (selected) {
                          _components.add(component);
                        } else {
                          _components.remove(component);
                        }
                      })
                    : null,
              ),
          ],
        ),
        _button(
          'confirmRelation',
          l.confirmRelation,
          _completeRelation ? _confirmRelation : null,
        ),
        if (_editingId != null ||
            _piece != null ||
            _kind != null ||
            _moment != null ||
            _snapshotRef != null ||
            _squares.isNotEmpty ||
            _components.isNotEmpty)
          _button(
            'cancelEdit',
            l.cancelEdit,
            () => _changeEditing(_clearRelation),
          ),
      ],
    );
  }
}
