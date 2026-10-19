import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/ui/endgames/widgets/assessment_response_form.dart';

const _current = AssessmentFormSnapshot(
  ref: 'current',
  fen: 'public synthetic position',
  label: 'Posição atual',
);
const _visited = AssessmentFormSnapshot(
  ref: 'visited-1',
  fen: 'public synthetic visited position',
  label: 'Posição visitada 1',
);

final _labels = AssessmentResponseLabels(
  target: 'Alvo',
  corner: 'Escolha um canto',
  referencePiece: 'Peça de referência',
  color: 'Cor do canto',
  sameColor: 'Mesma cor',
  otherColor: 'Outra cor',
  accessSquares: 'Escolher casas de acesso',
  confirmTarget: 'Confirmar alvo',
  removeTarget: 'Remover alvo',
  relation: 'Relações indicadas por você',
  piece: 'Peça',
  kind: 'Tipo de relação',
  moment: 'Momento',
  snapshot: 'Posição',
  relationSquares: 'Escolher casas da relação',
  components: 'Usar esta relação em',
  confirmRelation: 'Confirmar relação',
  cancelEdit: 'Cancelar edição',
  edit: 'Editar relação',
  remove: 'Remover relação',
  cornerLabel: (corner) => corner,
  pieceLabel: (piece) => switch (piece) {
    AssessmentPiece.king => 'Rei',
    AssessmentPiece.bishop => 'Bispo',
    AssessmentPiece.knight => 'Cavalo',
  },
  kindLabel: (kind) => switch (kind) {
    AssessmentRelationKind.control => 'Controle',
    AssessmentRelationKind.protection => 'Proteção',
    AssessmentRelationKind.check => 'Xeque',
  },
  momentLabel: (moment) => switch (moment) {
    AssessmentMoment.initial => 'Inicial',
    AssessmentMoment.visited => 'Visitado',
    AssessmentMoment.plannedOrUnrepresented => 'Planejado ou não representado',
  },
  componentLabel: (component) => switch (component) {
    AssessmentComponent.target => 'Alvo',
    AssessmentComponent.pieces => 'Peças',
    AssessmentComponent.protection => 'Proteção',
    AssessmentComponent.execution => 'Execução',
  },
  squaresLabel: (squares) => 'Casas: ${squares.join(', ')}',
  relationLabel: (relation) =>
      'Relação ${relation.id}: '
      '${relation.targetSquares.join(', ')}',
);

class _Host extends StatefulWidget {
  const _Host({required this.picker, this.initialValue, super.key});
  final AssessmentSquarePicker picker;
  final AssessmentDraft? initialValue;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  AssessmentDraft value = AssessmentDraft();
  AssessmentPhase phase = AssessmentPhase.initial;
  bool busy = false, enabled = true;
  int emissions = 0, identities = 0;
  AssessmentFormSnapshot currentSnapshot = _current;
  Future<bool> Function()? targetRemoval = () async => true;
  Future<bool> Function(AssessmentRelation)? relationRemoval = (_) async =>
      true;

  void update(VoidCallback change) => setState(change);

  @override
  void initState() {
    super.initState();
    value = widget.initialValue ?? AssessmentDraft();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(brightness: Brightness.light),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AssessmentResponseForm(
            value: value,
            phase: phase,
            currentSnapshot: currentSnapshot,
            visitedSnapshots: const [_visited],
            labels: _labels,
            pickSquares: widget.picker,
            createRelationId: () => 'r${++identities}',
            confirmRemoveTarget: targetRemoval,
            confirmRemoveRelation: relationRemoval,
            enabled: enabled,
            busy: busy,
            onChanged: (next) => setState(() {
              value = next;
              emissions++;
            }),
          ),
        ),
      ),
    ),
  );
}

Finder _find(String key) => find.byKey(ValueKey('assessment.$key'));

AssessmentDraft _roundtrip(AssessmentDraft draft) => AssessmentDraft.fromJson(
  (jsonDecode(jsonEncode(draft.toJson())) as Map).cast<String, Object?>(),
);

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_find(key));
  await tester.pumpAndSettle();
  await tester.tap(_find(key));
  await tester.pumpAndSettle();
}

Future<GlobalKey<_HostState>> _host(
  WidgetTester tester, {
  AssessmentSquarePicker? picker,
  AssessmentDraft? value,
}) async {
  final key = GlobalKey<_HostState>();
  await tester.pumpWidget(
    _Host(
      key: key,
      initialValue: value,
      picker: picker ?? (_, _) async => {'b2', 'c3'},
    ),
  );
  return key;
}

Future<void> _target(WidgetTester tester) async {
  await _tap(tester, 'corner.h8');
  await _tap(tester, 'colorPiece.knight');
  await _tap(tester, 'color.false');
  await _tap(tester, 'access');
}

Future<void> _relation(
  WidgetTester tester, {
  String moment = 'initial',
  String snapshot = 'current',
  String component = 'target',
}) async {
  await _tap(tester, 'piece.king');
  await _tap(tester, 'kind.check');
  await _tap(tester, 'moment.$moment');
  if (moment != 'plannedOrUnrepresented') {
    await _tap(tester, 'snapshot.$snapshot');
  }
  await _tap(tester, 'relationSquares');
  await _tap(tester, 'component.$component');
}

void main() {
  testWidgets(
    'starts empty; partial choices roundtrip JSON without confirming a target',
    (tester) async {
      final host = await _host(tester);
      expect(host.currentState!.emissions, 0);
      expect(
        tester.widget<OutlinedButton>(_find('confirmTarget')).onPressed,
        isNull,
      );
      expect(
        find.byWidgetPredicate((w) => w is ChoiceChip && w.selected),
        findsNothing,
      );
      await _tap(tester, 'corner.h8');
      await _tap(tester, 'color.false');
      host.currentState!.update(() {});
      await tester.pump();
      expect(tester.widget<ChoiceChip>(_find('corner.h8')).selected, isTrue);
      expect(host.currentState!.emissions, 2);
      expect(host.currentState!.value.target, isNull);
      expect(host.currentState!.value.relations, isEmpty);
      final saved = _roundtrip(host.currentState!.value);
      await tester.pumpWidget(const SizedBox());
      final restored = await _host(tester, value: saved);
      expect(tester.widget<ChoiceChip>(_find('corner.h8')).selected, isTrue);
      expect(tester.widget<ChoiceChip>(_find('color.false')).selected, isTrue);
      expect(
        tester.widget<ChoiceChip>(_find('colorPiece.king')).selected,
        isFalse,
      );
      expect(restored.currentState!.value.target, isNull);
      expect(restored.currentState!.emissions, 0);
    },
  );

  testWidgets('confirms full target and grouped squares without adjudication', (
    tester,
  ) async {
    final host = await _host(tester);
    await _target(tester);
    expect(host.currentState!.emissions, 4);
    expect(host.currentState!.value.target, isNull);
    await _tap(tester, 'confirmTarget');
    final target = host.currentState!.value.target!;
    expect(target.corner, 'h8');
    expect(target.colorPiece, AssessmentPiece.knight);
    expect(target.sameColor, isFalse);
    expect(target.accessSquares, {'b2', 'c3'});
    expect(host.currentState!.emissions, 5);
    expect(host.currentState!.value.toJson().keys, [
      'target',
      'relations',
      'editing',
    ]);
    await _tap(tester, 'removeTarget');
    expect(host.currentState!.value.target, isNull);
  });

  testWidgets(
    'cancelled and syntactically invalid picker results change nothing',
    (tester) async {
      Set<String>? result = {'b2', 'c3'};
      final host = await _host(tester, picker: (_, _) async => result);
      await _target(tester);
      final before = host.currentState!.emissions;
      result = null;
      await _tap(tester, 'access');
      result = {'i9'};
      await _tap(tester, 'access');
      expect(host.currentState!.emissions, before);
      await _tap(tester, 'confirmTarget');
      expect(host.currentState!.value.target!.accessSquares, {'b2', 'c3'});
    },
  );

  testWidgets(
    'edits one relation to add links with same ID and grouped houses',
    (tester) async {
      var picks = 0;
      final host = await _host(
        tester,
        picker: (snapshot, selected) async {
          expect(snapshot!.ref, 'current');
          picks++;
          return {'a1', 'h8'};
        },
      );
      await _relation(tester);
      expect(host.currentState!.emissions, 6);
      expect(host.currentState!.value.relations, isEmpty);
      await _tap(tester, 'confirmRelation');
      await _tap(tester, 'edit.r1');
      await _tap(tester, 'component.pieces');
      await _tap(tester, 'component.protection');
      await _tap(tester, 'confirmRelation');
      final relation = host.currentState!.value.relations.single;
      expect(relation.id, 'r1');
      expect(relation.useFor, {
        AssessmentComponent.target,
        AssessmentComponent.pieces,
        AssessmentComponent.protection,
      });
      expect(relation.targetSquares, {'a1', 'h8'});
      expect(relation.kind, AssessmentRelationKind.check);
      expect(picks, 1);
      expect(host.currentState!.identities, 1);
      await _tap(tester, 'remove.r1');
      expect(host.currentState!.value.relations, isEmpty);
    },
  );

  testWidgets(
    'phase whitelists snapshots and moment is an explicit user choice',
    (tester) async {
      AssessmentFormSnapshot? received;
      final host = await _host(
        tester,
        picker: (snapshot, _) async {
          received = snapshot;
          return {'d4'};
        },
      );
      await _tap(tester, 'moment.visited');
      expect(_find('snapshot.current'), findsOneWidget);
      expect(_find('snapshot.visited-1'), findsNothing);
      host.currentState!.update(() {
        host.currentState!.phase = AssessmentPhase.protection;
      });
      await tester.pump();
      expect(_find('corner.h8'), findsNothing);
      expect(_find('confirmTarget'), findsNothing);
      expect(_find('component.target'), findsNothing);
      expect(_find('component.pieces'), findsNothing);
      await _relation(
        tester,
        moment: 'visited',
        snapshot: 'visited-1',
        component: 'protection',
      );
      expect(_find('snapshot.current'), findsNothing);
      expect(received!.ref, 'visited-1');
      await _tap(tester, 'confirmRelation');
      expect(
        host.currentState!.value.relations.single.moment,
        AssessmentMoment.visited,
      );
      await _relation(
        tester,
        moment: 'plannedOrUnrepresented',
        component: 'protection',
      );
      expect(received, isNull);
      await _tap(tester, 'confirmRelation');
      expect(host.currentState!.value.relations.last.snapshotRef, isNull);
      expect(
        host.currentState!.value.relations.last.moment,
        AssessmentMoment.plannedOrUnrepresented,
      );
      host.currentState!.update(() {
        host.currentState!.phase = AssessmentPhase.execution;
      });
      await tester.pump();
      expect(tester.widget<ChoiceChip>(_find('piece.king')).onSelected, isNull);
    },
  );

  testWidgets('confirming a relation preserves a partial target in this form', (
    tester,
  ) async {
    final host = await _host(tester);
    await _tap(tester, 'corner.h8');
    await _relation(tester);
    final beforeConfirm = host.currentState!.emissions;
    await _tap(tester, 'confirmRelation');
    expect(host.currentState!.emissions, beforeConfirm + 1);
    expect(_roundtrip(host.currentState!.value).editing.corner, 'h8');
    expect(host.currentState!.value.editing.relationPiece, isNull);
    expect(host.currentState!.value.target, isNull);
    expect(host.currentState!.value.relations, hasLength(1));
    expect(tester.widget<ChoiceChip>(_find('corner.h8')).selected, isTrue);
    await _tap(tester, 'colorPiece.knight');
    await _tap(tester, 'color.false');
    await _tap(tester, 'access');
    await _tap(tester, 'confirmTarget');
    expect(host.currentState!.value.target!.corner, 'h8');
    expect(host.currentState!.value.relations, hasLength(1));
    await _tap(tester, 'removeTarget');
    expect(host.currentState!.value.target, isNull);
    expect(tester.widget<ChoiceChip>(_find('corner.h8')).selected, isFalse);
    expect(host.currentState!.value.relations, hasLength(1));
  });

  testWidgets('confirming a target preserves an unfinished relation', (
    tester,
  ) async {
    final host = await _host(tester);
    await _tap(tester, 'piece.bishop');
    await _target(tester);
    final beforeConfirm = host.currentState!.emissions;
    await _tap(tester, 'confirmTarget');
    expect(host.currentState!.emissions, beforeConfirm + 1);
    expect(
      _roundtrip(host.currentState!.value).editing.relationPiece,
      AssessmentPiece.bishop,
    );
    expect(tester.widget<ChoiceChip>(_find('piece.bishop')).selected, isTrue);
    await _tap(tester, 'kind.control');
    await _tap(tester, 'moment.initial');
    await _tap(tester, 'snapshot.current');
    await _tap(tester, 'relationSquares');
    await _tap(tester, 'component.pieces');
    await _tap(tester, 'confirmRelation');
    expect(
      host.currentState!.value.relations.single.piece,
      AssessmentPiece.bishop,
    );
    expect(host.currentState!.value.target, isNotNull);
  });

  testWidgets(
    'retapping the selected moment or snapshot preserves selected houses',
    (tester) async {
      var picks = 0;
      final host = await _host(
        tester,
        picker: (_, _) async {
          picks++;
          return {'b2', 'c3'};
        },
      );
      await _relation(tester);
      final emissions = host.currentState!.emissions;
      await _tap(tester, 'moment.initial');
      await _tap(tester, 'snapshot.current');
      expect(host.currentState!.emissions, emissions);
      expect(
        tester.widget<OutlinedButton>(_find('confirmRelation')).onPressed,
        isNotNull,
      );
      await _tap(tester, 'confirmRelation');
      expect(host.currentState!.value.relations.single.targetSquares, {
        'b2',
        'c3',
      });
      expect(picks, 1);
    },
  );

  testWidgets('removal without caller confirmation is disabled', (
    tester,
  ) async {
    final host = await _host(tester);
    await _target(tester);
    await _tap(tester, 'confirmTarget');
    await _relation(tester);
    await _tap(tester, 'confirmRelation');
    host.currentState!.update(() {
      host.currentState!.targetRemoval = null;
      host.currentState!.relationRemoval = null;
    });
    await tester.pump();
    expect(
      tester.widget<OutlinedButton>(_find('removeTarget')).onPressed,
      isNull,
    );
    expect(tester.widget<OutlinedButton>(_find('remove.r1')).onPressed, isNull);
  });

  testWidgets(
    'declining removal preserves responses and another partial edit',
    (tester) async {
      final host = await _host(tester);
      await _target(tester);
      await _tap(tester, 'confirmTarget');
      await _relation(tester);
      await _tap(tester, 'confirmRelation');
      await _tap(tester, 'piece.knight');
      host.currentState!.update(() {
        host.currentState!.targetRemoval = () async => false;
        host.currentState!.relationRemoval = (_) async => false;
      });
      await tester.pump();
      final before = host.currentState!.value.toJson();
      final emissions = host.currentState!.emissions;
      await _tap(tester, 'removeTarget');
      await _tap(tester, 'remove.r1');
      expect(host.currentState!.value.toJson(), before);
      expect(host.currentState!.emissions, emissions);
      expect(tester.widget<ChoiceChip>(_find('piece.knight')).selected, isTrue);
    },
  );

  testWidgets('stale removal confirmation cannot affect a changed phase', (
    tester,
  ) async {
    final host = await _host(tester);
    await _target(tester);
    await _tap(tester, 'confirmTarget');
    final pending = Completer<bool>();
    host.currentState!.update(
      () => host.currentState!.targetRemoval = () => pending.future,
    );
    await tester.pump();
    await tester.ensureVisible(_find('removeTarget'));
    await tester.tap(_find('removeTarget'));
    await tester.pump();
    final emissions = host.currentState!.emissions;
    host.currentState!.update(
      () => host.currentState!.phase = AssessmentPhase.protection,
    );
    await tester.pump();
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(host.currentState!.value.target, isNotNull);
    expect(host.currentState!.emissions, emissions);
    expect(_find('removeTarget'), findsNothing);
  });

  testWidgets(
    'protection collects a fresh phase draft without editing submitted initial responses',
    (tester) async {
      final host = await _host(tester);
      await _target(tester);
      await _tap(tester, 'confirmTarget');
      await _relation(tester);
      await _tap(tester, 'confirmRelation');
      final submitted = host.currentState!.value;
      final frozen = submitted.toJson();
      host.currentState!.update(() {
        host.currentState!.phase = AssessmentPhase.protection;
        host.currentState!.value = AssessmentDraft();
      });
      await tester.pump();
      expect(_find('corner.h8'), findsNothing);
      expect(_find('edit.r1'), findsNothing);
      await _relation(
        tester,
        moment: 'visited',
        snapshot: 'visited-1',
        component: 'protection',
      );
      await _tap(tester, 'confirmRelation');
      expect(host.currentState!.value.target, isNull);
      expect(host.currentState!.value.relations.single.useFor, {
        AssessmentComponent.protection,
      });
      expect(submitted.toJson(), frozen);
    },
  );

  testWidgets('busy invalidates pending picker and blocks changes', (
    tester,
  ) async {
    final pending = Completer<Set<String>?>();
    final host = await _host(tester, picker: (_, _) => pending.future);
    await _tap(tester, 'access');
    host.currentState!.update(() {
      host.currentState!.busy = true;
    });
    await tester.pump();
    pending.complete({'a1'});
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(_find('corner.a1')).onSelected, isNull);
    expect(tester.widget<OutlinedButton>(_find('access')).onPressed, isNull);
    expect(host.currentState!.emissions, 0);
    host.currentState!.update(() {
      host.currentState!.busy = false;
    });
    await tester.pump();
    expect(find.text('Casas: a1'), findsNothing);
    host.currentState!.update(() {
      host.currentState!.enabled = false;
    });
    await tester.pump();
    expect(tester.widget<ChoiceChip>(_find('corner.a1')).onSelected, isNull);
  });

  testWidgets('external restored value replaces local edit without emission', (
    tester,
  ) async {
    final host = await _host(tester);
    await _tap(tester, 'corner.h8');
    host.currentState!.update(() {
      host.currentState!.value = AssessmentDraft(
        target: AssessmentTarget(
          corner: 'a1',
          colorPiece: AssessmentPiece.bishop,
          sameColor: true,
          accessSquares: {'a2'},
        ),
        editing: AssessmentEditingState(
          corner: 'a1',
          colorPiece: AssessmentPiece.bishop,
          sameColor: true,
          accessSquares: {'a2'},
        ),
      );
    });
    await tester.pump();
    expect(tester.widget<ChoiceChip>(_find('corner.a1')).selected, isTrue);
    expect(tester.widget<ChoiceChip>(_find('corner.h8')).selected, isFalse);
    expect(tester.widget<ChoiceChip>(_find('color.true')).selected, isTrue);
    expect(host.currentState!.emissions, 1);
  });

  testWidgets('restores edited relation identity, snapshot, houses and links', (
    tester,
  ) async {
    final host = await _host(tester);
    await _relation(tester);
    expect(host.currentState!.identities, 0);
    await _tap(tester, 'confirmRelation');
    await _tap(tester, 'corner.a8');
    await _tap(tester, 'edit.r1');
    await _tap(tester, 'kind.protection');
    await _tap(tester, 'component.pieces');
    final saved = _roundtrip(host.currentState!.value);
    expect(saved.relations.single.kind, AssessmentRelationKind.check);
    expect(saved.editing.relationId, 'r1');
    expect(saved.editing.relationTargets, {'b2', 'c3'});
    expect(saved.editing.relationSnapshotRef, 'current');
    expect(saved.editing.relationUseFor, {
      AssessmentComponent.target,
      AssessmentComponent.pieces,
    });
    await tester.pumpWidget(const SizedBox());
    final restored = await _host(tester, value: saved);
    expect(restored.currentState!.emissions, 0);
    expect(
      tester.widget<ChoiceChip>(_find('kind.protection')).selected,
      isTrue,
    );
    expect(
      tester.widget<ChoiceChip>(_find('snapshot.current')).selected,
      isTrue,
    );
    expect(
      tester.widget<FilterChip>(_find('component.pieces')).selected,
      isTrue,
    );
    await _tap(tester, 'confirmRelation');
    expect(restored.currentState!.value.relations.single.id, 'r1');
    expect(
      restored.currentState!.value.relations.single.kind,
      AssessmentRelationKind.protection,
    );
    expect(restored.currentState!.identities, 0);
    expect(restored.currentState!.value.editing.corner, 'a8');
    expect(restored.currentState!.emissions, 1);
  });

  testWidgets('cancel edit persists only cleared relation editor', (
    tester,
  ) async {
    final host = await _host(tester);
    await _target(tester);
    await _tap(tester, 'confirmTarget');
    await _relation(tester);
    await _tap(tester, 'confirmRelation');
    await _tap(tester, 'edit.r1');
    await _tap(tester, 'kind.control');
    final before = host.currentState!.value;
    final emissions = host.currentState!.emissions;
    await _tap(tester, 'cancelEdit');
    final after = _roundtrip(host.currentState!.value);
    expect(host.currentState!.emissions, emissions + 1);
    expect(after.target!.toJson(), before.target!.toJson());
    expect(after.relations.single.toJson(), before.relations.single.toJson());
    expect(after.editing.corner, before.editing.corner);
    expect(after.editing.sameColor, isFalse);
    expect(after.editing.accessSquares, before.editing.accessSquares);
    expect(after.editing.relationId, isNull);
    expect(after.editing.relationPiece, isNull);
    expect(after.editing.relationKind, isNull);
    expect(after.editing.relationMoment, isNull);
    expect(after.editing.relationSnapshotRef, isNull);
    expect(after.editing.relationTargets, isEmpty);
    expect(after.editing.relationUseFor, isEmpty);
    // A new incomplete relation can also be cancelled before it has an ID.
    await _tap(tester, 'piece.knight');
    await _tap(tester, 'cancelEdit');
    expect(host.currentState!.value.relations, hasLength(1));
    expect(host.currentState!.value.editing.relationPiece, isNull);
    expect(host.currentState!.identities, 1);
  });

  testWidgets(
    'explicit partial nulls never inherit fields from confirmed target',
    (tester) async {
      final value = AssessmentDraft(
        target: AssessmentTarget(
          corner: 'a1',
          colorPiece: AssessmentPiece.king,
          sameColor: true,
          accessSquares: {'a2'},
        ),
        editing: AssessmentEditingState(sameColor: false),
      );
      final host = await _host(tester, value: _roundtrip(value));
      expect(host.currentState!.emissions, 0);
      expect(tester.widget<ChoiceChip>(_find('color.false')).selected, isTrue);
      expect(tester.widget<ChoiceChip>(_find('corner.a1')).selected, isFalse);
      expect(
        tester.widget<ChoiceChip>(_find('colorPiece.king')).selected,
        isFalse,
      );
      expect(
        tester.widget<OutlinedButton>(_find('confirmTarget')).onPressed,
        isNull,
      );
      expect(host.currentState!.value.target!.corner, 'a1');
    },
  );

  testWidgets(
    'legacy draft keeps confirmed target without inventing editor data',
    (tester) async {
      final legacy = AssessmentDraft.fromJson({
        'target': AssessmentTarget(
          corner: 'h1',
          colorPiece: AssessmentPiece.king,
          sameColor: true,
          accessSquares: {'h2'},
        ).toJson(),
        'relations': <Object?>[],
      });
      final host = await _host(tester, value: legacy);
      expect(host.currentState!.emissions, 0);
      expect(host.currentState!.value.target!.corner, 'h1');
      expect(
        find.byWidgetPredicate((w) => w is ChoiceChip && w.selected),
        findsNothing,
      );
      expect(_find('removeTarget'), findsOneWidget);
    },
  );

  testWidgets(
    'incomplete relation selections restore without confirmation or ID',
    (tester) async {
      final host = await _host(tester);
      await _tap(tester, 'piece.bishop');
      await _tap(tester, 'moment.visited');
      await _tap(tester, 'snapshot.current');
      await _tap(tester, 'relationSquares');
      await _tap(tester, 'component.protection');
      final saved = _roundtrip(host.currentState!.value);
      expect(saved.relations, isEmpty);
      expect(saved.editing.relationKind, isNull);
      expect(saved.editing.relationId, isNull);
      expect(host.currentState!.identities, 0);
      await tester.pumpWidget(const SizedBox());
      final restored = await _host(tester, value: saved);
      expect(restored.currentState!.emissions, 0);
      expect(tester.widget<ChoiceChip>(_find('piece.bishop')).selected, isTrue);
      expect(
        tester.widget<ChoiceChip>(_find('moment.visited')).selected,
        isTrue,
      );
      expect(
        tester.widget<OutlinedButton>(_find('confirmRelation')).onPressed,
        isNull,
      );
      expect(restored.currentState!.value.editing.relationTargets, {
        'b2',
        'c3',
      });
    },
  );

  testWidgets(
    'changed snapshot invalidates an awaited picker without emission',
    (tester) async {
      final pending = Completer<Set<String>?>();
      final host = await _host(tester, picker: (_, _) => pending.future);
      await _tap(tester, 'corner.a1');
      await _tap(tester, 'access');
      final before = host.currentState!.emissions;
      host.currentState!.update(() {
        host.currentState!.currentSnapshot = const AssessmentFormSnapshot(
          ref: 'replacement',
          fen: 'another public synthetic position',
          label: 'Outra posição',
        );
      });
      await tester.pump();
      pending.complete({'g7'});
      await tester.pumpAndSettle();
      expect(host.currentState!.emissions, before);
      expect(host.currentState!.value.editing.accessSquares, isEmpty);
      expect(tester.widget<ChoiceChip>(_find('corner.a1')).selected, isTrue);
    },
  );

  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    testWidgets('PT light font 1 no overflow at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final host = await _host(tester);
      await _target(tester);
      await _tap(tester, 'confirmTarget');
      await _relation(tester, moment: 'plannedOrUnrepresented');
      await _tap(tester, 'confirmRelation');
      await _tap(tester, 'edit.r1');
      await _tap(tester, 'component.protection');
      expect(tester.takeException(), isNull);
      expect(host.currentState!.emissions, 13);
    });
  }
}
