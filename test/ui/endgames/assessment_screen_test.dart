import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/assessment_attempt_repository.dart';
import 'package:lucena/domain/models/assessment_attempt.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/assessment_cubit.dart';
import 'package:lucena/ui/endgames/widgets/assessment_response_form.dart';
import 'package:lucena/ui/endgames/widgets/assessment_screen.dart';

import '../../../testing/board_gestures.dart';

class _Now implements Now {
  DateTime value = DateTime.utc(2026, 1, 1);
  @override
  DateTime call() => value;
}

/// Public, synthetic history only; this fake has no conceptual facts or answers.
class _Store implements AssessmentAttemptRepository {
  AssessmentAttempt? current;
  final attempts = <String, AssessmentAttempt>{};
  bool fail = false;
  Completer<void>? readGate, writeGate;
  int reads = 0, writes = 0;

  void releaseGates() {
    final reading = readGate;
    final writing = writeGate;
    if (reading != null && !reading.isCompleted) reading.complete();
    if (writing != null && !writing.isCompleted) writing.complete();
  }

  @override
  Future<AssessmentAttempt?> loadCurrent() async {
    reads++;
    await readGate?.future;
    return current;
  }

  @override
  Future<AssessmentAttempt?> loadById(String id) async => attempts[id];
  @override
  Future<void> save(AssessmentAttempt attempt) async {
    await writeGate?.future;
    if (fail) throw const AssessmentAttemptStorageException('test');
    writes++;
    current = attempt;
    attempts[attempt.attemptId] = attempt;
  }
}

final _formLabels = AssessmentResponseLabels(
  target: 'Alvo',
  corner: 'Canto',
  referencePiece: 'Referência',
  color: 'Cor',
  sameColor: 'Mesma cor',
  otherColor: 'Outra cor',
  accessSquares: 'Casas de acesso',
  confirmTarget: 'Confirmar alvo',
  removeTarget: 'Remover alvo',
  relation: 'Relações',
  piece: 'Peça',
  kind: 'Relação',
  moment: 'Momento',
  snapshot: 'Posição',
  relationSquares: 'Casas da relação',
  components: 'Componentes',
  confirmRelation: 'Confirmar relação',
  cancelEdit: 'Cancelar edição',
  edit: 'Editar',
  remove: 'Remover',
  cornerLabel: (v) => v,
  pieceLabel: (v) => v.name,
  kindLabel: (v) => v.name,
  momentLabel: (v) => v.name,
  componentLabel: (v) => v.name,
  squaresLabel: (v) => v.join(', '),
  relationLabel: (v) => v.id,
);

AssessmentScreenLabels _labels({String? newAttempt}) => AssessmentScreenLabels(
  title: 'Registro',
  loading: 'Carregando',
  technicalFailure: 'Não foi possível salvar',
  retry: 'Tentar novamente',
  exit: 'Sair',
  submitInitial: 'Enviar registro',
  finishExecution: 'Encerrar execução',
  submitProtection: 'Enviar proteção',
  closed: 'Registro encerrado',
  phase: (v) => 'Etapa ${v.name}',
  remaining: (v) => 'Restam ${v.inSeconds}s',
  snapshot: (ref, fen) => 'Visita $ref',
  newAttempt: newAttempt,
);

class _Harness {
  final now = _Now();
  final store = _Store();
  int exits = 0, finishPrompts = 0, exitPrompts = 0, ids = 0;
  int opponentCalls = 0;
  Future<bool> Function() finish = () async => false;
  Future<bool> Function() exit = () async => false;
  String? newAttemptLabel;
  Future<bool> Function()? newAttempt;
  late final AssessmentCubit cubit = AssessmentCubit(
    config: AssessmentConfig(
      lessonId: 'mates.bishopKnight.deletang',
      exerciseId: 'finalNetAssessment01',
      initialFen: GameRules.initial.fen,
      student: Side.white,
      contentIdentity: const {'public': 'synthetic-v1'},
      createAttemptId: () => 'public-${++ids}',
      now: now,
    ),
    repository: store,
    pickOpponent: (position, history) async {
      opponentCalls++;
      return Move.parse('e7e5');
    },
    facts: (attempt) async => null,
  );

  Future<void> mount(WidgetTester tester, {bool load = true}) async {
    if (load) await cubit.load();
    addTearDown(() async {
      store.releaseGates();
      await tester.pumpWidget(const SizedBox.shrink());
      // Cubit.close drains its write Future before closing the stream. The
      // teardown runs after the widget test's fake clock; drain in real async.
      await tester.runAsync(cubit.close);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: AssessmentScreen(
          cubit: cubit,
          labels: _labels(newAttempt: newAttemptLabel),
          responseLabels: _formLabels,
          pickSquares: (snapshot, selected) async => selected,
          createRelationId: () => 'relation-${++ids}',
          confirmFinishExecution: () {
            finishPrompts++;
            return finish();
          },
          confirmExit: () {
            exitPrompts++;
            return exit();
          },
          onExit: () => exits++,
          confirmNewAttempt: newAttempt,
        ),
      ),
    );
    await tester.pump();
  }
}

AssessmentResponseForm _form(WidgetTester tester) =>
    tester.widget<AssessmentResponseForm>(find.byType(AssessmentResponseForm));

FilledButton _submit(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(AssessmentKeys.submit));

void main() {
  for (final viewport in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    testWidgets(
      'execution board is centered between Android bars at ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport;
        tester.view.padding = const FakeViewPadding(top: 52, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 52, bottom: 24);
        addTearDown(tester.view.reset);
        final h = _Harness();
        await h.mount(tester);
        await tester.tap(find.byKey(AssessmentKeys.submit));
        await tester.pumpAndSettle();
        final board = tester.getRect(find.byType(Chessboard));
        final appBar = tester.getRect(find.byType(AppBar));
        final footer = tester.getRect(find.byKey(AssessmentKeys.footer));
        final status = tester.getRect(find.byKey(AssessmentKeys.phase));
        final timer = tester.getRect(find.byKey(AssessmentKeys.timer));
        final usefulBottom = viewport.height - 24;
        final above = board.top - 52;
        final below = usefulBottom - board.bottom;
        expect(board.width, closeTo(viewport.width, .01));
        expect(board.height, closeTo(board.width, .01));
        expect(board.center.dx, closeTo(viewport.width / 2, .01));
        expect(board.center.dy, closeTo((52 + usefulBottom) / 2, .01));
        expect((above - below).abs(), lessThanOrEqualTo(.01));
        expect(
          (above - below).abs() / (usefulBottom - 52),
          lessThanOrEqualTo(.05),
        );
        expect(appBar.bottom, closeTo(52 + kToolbarHeight, .01));
        expect(footer.bottom, closeTo(usefulBottom, .01));
        expect(footer.height, closeTo(84, .01));
        expect(
          tester.getSize(find.byKey(AssessmentKeys.submit)).height,
          closeTo(52, .01),
        );
        expect(status.top, greaterThanOrEqualTo(appBar.bottom));
        expect(timer.top, greaterThanOrEqualTo(status.bottom));
        expect(timer.bottom, lessThan(board.top));
        expect(board.bottom, lessThan(footer.top));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'real board selection cannot cross replacement execution binding',
    (tester) async {
      final old = _Harness();
      await old.mount(tester);
      await tester.tap(find.byKey(AssessmentKeys.submit));
      await tester.pumpAndSettle();
      final board = find.byType(Chessboard);
      await tester.tapAt(squareCenter(tester.getRect(board), 'e2'));
      await tester.pump();
      final previousFen = old.cubit.state.snapshot!.execution.gameFen;
      final replacement = _Harness();
      await replacement.cubit.load();
      await replacement.cubit.submitInitial();
      expect(replacement.cubit.state.snapshot!.execution.gameFen, previousFen);
      await replacement.mount(tester);
      await tester.pumpAndSettle();
      await tester.tapAt(squareCenter(tester.getRect(board), 'e4'));
      await tester.pumpAndSettle();
      expect(replacement.store.current!.execution.played, isEmpty);
      expect(replacement.opponentCalls, 0);
      expect(old.store.current!.execution.played, isEmpty);
      await tester.tapAt(squareCenter(tester.getRect(board), 'e2'));
      await tester.pump();
      await tester.tapAt(squareCenter(tester.getRect(board), 'e4'));
      await tester.pumpAndSettle();
      expect(replacement.store.current!.execution.played, ['e2e4', 'e7e5']);
      expect(replacement.opponentCalls, 1);
      expect(old.store.current!.execution.played, isEmpty);
      expect(replacement.cubit.state.technicalFailure, isNull);
    },
  );

  testWidgets(
    'real board tap selection survives clock tick before destination tap',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      await tester.tap(find.byKey(AssessmentKeys.submit));
      await tester.pumpAndSettle();
      final board = find.byType(Chessboard);
      await tester.tapAt(squareCenter(tester.getRect(board), 'e2'));
      await tester.pump();
      expect(h.store.current!.execution.played, isEmpty);
      expect(h.opponentCalls, 0);
      h.now.value = h.now.value.add(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(h.cubit.state.snapshot!.lastObservedUtc, h.now.value);
      await tester.tapAt(squareCenter(tester.getRect(board), 'e4'));
      await tester.pumpAndSettle();
      expect(h.store.current!.execution.played, ['e2e4', 'e7e5']);
      expect(h.opponentCalls, 1);
      expect(h.store.current!.execution.visitedSnapshots.keys, [
        'ply:0',
        'ply:1',
        'ply:2',
      ]);
      expect(h.cubit.state.technicalFailure, isNull);
    },
  );

  testWidgets(
    'initial collection restores only its draft and initial snapshot',
    (tester) async {
      final h = _Harness();
      await h.cubit.load();
      final draft = AssessmentDraft(
        editing: AssessmentEditingState(corner: 'h8'),
      );
      await h.cubit.replaceDraft(draft);
      await h.mount(tester);
      final form = _form(tester);
      expect(form.phase, AssessmentPhase.initial);
      expect(form.value.editing.corner, 'h8');
      expect(form.currentSnapshot.fen, GameRules.initial.fen);
      expect(form.visitedSnapshots.map((s) => s.ref), ['ply:0']);
      expect(find.text('Restam 600s'), findsOneWidget);
      expect(find.byKey(AssessmentKeys.closed), findsNothing);
      expect(h.cubit.state.conceptualResult, isNull);
    },
  );

  testWidgets('finish refusal leaves history deadline and phase untouched', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    await tester.tap(find.byKey(AssessmentKeys.submit));
    await tester.pumpAndSettle();
    final before = h.cubit.state.snapshot!;
    expect(find.byType(AssessmentResponseForm), findsNothing);
    expect(find.byType(Chessboard), findsOneWidget);
    await tester.tap(find.byKey(AssessmentKeys.submit));
    await tester.pumpAndSettle();
    expect(h.finishPrompts, 1);
    final after = h.cubit.state.snapshot!;
    expect(after.attemptId, before.attemptId);
    expect(after.phase, before.phase);
    expect(after.deadlineUtc, before.deadlineUtc);
    expect(after.execution.toJson(), before.execution.toJson());
    expect(after.draft.toJson(), before.draft.toJson());
    expect(
      after.submissions.map((s) => s.toJson()),
      before.submissions.map((s) => s.toJson()),
    );
    expect(
      after.help.map((h) => h.toJson()),
      before.help.map((h) => h.toJson()),
    );
    expect(after.closeReason, before.closeReason);
    expect(after.callbackEpoch, before.callbackEpoch);
    expect(h.cubit.state.technicalFailure, isNull);
    expect(h.exits, 0);
  });

  testWidgets(
    'real board forwards legal moves and protection has a separate draft',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      _form(tester).onChanged(
        AssessmentDraft(editing: AssessmentEditingState(corner: 'a8')),
      );
      await tester.pumpAndSettle();
      final staleForm = _form(tester);
      await tester.tap(find.byKey(AssessmentKeys.submit));
      await tester.pumpAndSettle();
      final board = tester.widget<Chessboard>(find.byType(Chessboard));
      board.onMove?.call(Move.parse('e2e4')!);
      await tester.pumpAndSettle();
      expect(h.cubit.state.snapshot!.execution.played, ['e2e4', 'e7e5']);
      h.finish = () async => true;
      await tester.tap(find.byKey(AssessmentKeys.submit));
      await tester.pumpAndSettle();
      final form = _form(tester);
      expect(form.phase, AssessmentPhase.protection);
      expect(form.value.editing.corner, isNull);
      expect(
        h.cubit.state.snapshot!.submissions.single.response.editing.corner,
        'a8',
      );
      expect(form.visitedSnapshots.map((s) => s.ref), [
        'ply:0',
        'ply:1',
        'ply:2',
      ]);
      staleForm.onChanged(
        AssessmentDraft(editing: AssessmentEditingState(corner: 'h1')),
      );
      await tester.pumpAndSettle();
      expect(h.cubit.state.snapshot!.draft.editing.corner, isNull);
      await tester.ensureVisible(find.byKey(AssessmentKeys.snapshot('ply:0')));
      await tester.tap(find.byKey(AssessmentKeys.snapshot('ply:0')));
      await tester.pumpAndSettle();
      expect(h.cubit.state.snapshot!.viewSnapshotRef, 'ply:0');
      expect(_form(tester).currentSnapshot.fen, GameRules.initial.fen);
      expect(h.cubit.state.snapshot!.execution.played, ['e2e4', 'e7e5']);
      _form(tester).onChanged(
        AssessmentDraft(
          editing: AssessmentEditingState(
            relationPiece: AssessmentPiece.knight,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await h.cubit.resume();
      await tester.pumpAndSettle();
      expect(_form(tester).value.editing.relationPiece, AssessmentPiece.knight);
      await tester.tap(find.byKey(AssessmentKeys.submit));
      await tester.pumpAndSettle();
      expect(find.byKey(AssessmentKeys.closed), findsOneWidget);
      expect(find.byType(AssessmentResponseForm), findsNothing);
      expect(find.byType(Chessboard), findsNothing);
    },
  );

  testWidgets('back requests confirmation and refusal is inert', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    final before = h.store.current!.toJson();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(h.exitPrompts, 1);
    expect(h.exits, 0);
    expect(h.store.current!.toJson(), before);
    expect(find.byKey(AssessmentKeys.screen), findsOneWidget);
  });

  testWidgets('confirmed exit waits for durable cancellation', (tester) async {
    final h = _Harness()..exit = (() async => true);
    await h.mount(tester);
    final gate = Completer<void>();
    h.store.writeGate = gate;
    await tester.tap(find.byKey(AssessmentKeys.exit));
    await tester.pump();
    expect(h.exits, 0);
    expect(_submit(tester).onPressed, isNull);
    expect(_form(tester).enabled, isFalse);
    gate.complete();
    await tester.pumpAndSettle();
    expect(h.store.current!.closeReason, AssessmentCloseReason.cancelled);
    expect(h.exits, 1);
    expect(h.cubit.isClosed, isFalse);
  });

  testWidgets('storage failure blocks exit and retry retains the draft', (
    tester,
  ) async {
    final h = _Harness()..exit = (() async => true);
    await h.mount(tester);
    _form(
      tester,
    ).onChanged(AssessmentDraft(editing: AssessmentEditingState(corner: 'h1')));
    await tester.pumpAndSettle();
    h.store.fail = true;
    await tester.tap(find.byKey(AssessmentKeys.exit));
    await tester.pumpAndSettle();
    expect(h.exits, 0);
    expect(find.byKey(AssessmentKeys.failure), findsOneWidget);
    expect(h.store.current!.phase, AssessmentPhase.initial);
    expect(h.store.current!.draft.editing.corner, 'h1');
    h.store.fail = false;
    await tester.tap(find.byKey(AssessmentKeys.retry));
    await tester.pumpAndSettle();
    expect(_form(tester).value.editing.corner, 'h1');
    await tester.tap(find.byKey(AssessmentKeys.exit));
    await tester.pumpAndSettle();
    expect(h.exits, 1);
  });

  testWidgets(
    'deadline follows injected absolute time and disposal owns no cubit',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      h.now.value = h.now.value.add(const Duration(seconds: 45));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Restam 555s'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      final writes = h.store.writes;
      h.now.value = h.now.value.add(const Duration(seconds: 600));
      await tester.pump(const Duration(seconds: 5));
      expect(h.cubit.isClosed, isFalse);
      expect(h.store.writes, writes);
    },
  );

  testWidgets(
    'foreground replays before controls reenable and deadline closes collection',
    (tester) async {
      final h = _Harness();
      await h.mount(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      h.now.value = h.now.value.add(const Duration(seconds: 601));
      final gate = Completer<void>();
      h.store.readGate = gate;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        tester.widget<IconButton>(find.byKey(AssessmentKeys.exit)).onPressed,
        isNull,
      );
      expect(h.exits, 0);
      gate.complete();
      await tester.pumpAndSettle();
      expect(
        h.cubit.state.snapshot!.closeReason,
        AssessmentCloseReason.timeLimit,
      );
      expect(find.byKey(AssessmentKeys.closed), findsOneWidget);
    },
  );

  testWidgets(
    'confirmation from an older attempt cannot cancel its replacement',
    (tester) async {
      final h = _Harness();
      final answer = Completer<bool>();
      h.exit = () => answer.future;
      await h.mount(tester);
      await tester.tap(find.byKey(AssessmentKeys.exit));
      await tester.pump();
      await h.cubit.cancel();
      await h.cubit.retry();
      await tester.pump();
      final replacement = h.cubit.state.snapshot!.attemptId;
      answer.complete(true);
      await tester.pumpAndSettle();
      expect(h.exits, 0);
      expect(h.cubit.state.snapshot!.attemptId, replacement);
      expect(h.cubit.state.snapshot!.phase, AssessmentPhase.initial);
    },
  );

  testWidgets('overlapping foreground cycles restore controls after replay', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    final reads = h.store.reads;
    final gate = Completer<void>();
    h.store.readGate = gate;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    h.now.value = h.now.value.add(const Duration(seconds: 20));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(AssessmentKeys.submit), findsNothing);
    expect(find.byType(AssessmentResponseForm), findsNothing);
    expect(find.byKey(AssessmentKeys.busy), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    h.now.value = h.now.value.add(const Duration(seconds: 45));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      tester.widget<IconButton>(find.byKey(AssessmentKeys.exit)).onPressed,
      isNull,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(h.store.reads, reads + 2);
    expect(h.cubit.state.snapshot!.lastObservedUtc, h.now.value);
    expect(find.text('Restam 535s'), findsOneWidget);
    expect(_submit(tester).onPressed, isNotNull);
    expect(_form(tester).enabled, isTrue);
    expect(
      tester.widget<IconButton>(find.byKey(AssessmentKeys.exit)).onPressed,
      isNotNull,
    );
  });

  testWidgets('old cancellation save cannot exit a replacement binding', (
    tester,
  ) async {
    final old = _Harness()..exit = (() async => true);
    await old.mount(tester);
    final gate = Completer<void>();
    old.store.writeGate = gate;
    await tester.tap(find.byKey(AssessmentKeys.exit));
    await tester.pump();
    expect(old.cubit.state.busy, isTrue);
    final replacement = _Harness();
    await replacement.mount(tester);
    gate.complete();
    await tester.pumpAndSettle();
    expect(old.store.current!.closeReason, AssessmentCloseReason.cancelled);
    expect(old.exits, 0);
    expect(replacement.exits, 0);
    expect(replacement.cubit.state.snapshot!.phase, AssessmentPhase.initial);
    expect(find.byKey(AssessmentKeys.screen), findsOneWidget);
  });

  testWidgets('initial footer callback is inert after phase changes', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    final initialSubmit = _submit(tester).onPressed!;
    await h.cubit.submitInitial();
    await tester.pumpAndSettle();
    final before = h.store.current!.toJson();
    initialSubmit();
    await tester.pumpAndSettle();
    expect(h.store.current!.toJson(), before);
    expect(h.cubit.state.technicalFailure, isNull);
    expect(h.cubit.state.snapshot!.phase, AssessmentPhase.execution);
  });

  testWidgets('protection footer callback is inert after closure', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    await h.cubit.submitInitial();
    await h.cubit.finishExecution(voluntaryConfirmed: true);
    await tester.pumpAndSettle();
    final protectionSubmit = _submit(tester).onPressed!;
    await h.cubit.cancel();
    await tester.pumpAndSettle();
    final before = h.store.current!.toJson();
    final failure = h.cubit.state.technicalFailure;
    protectionSubmit();
    await tester.pumpAndSettle();
    expect(h.store.current!.toJson(), before);
    expect(h.cubit.state.technicalFailure, failure);
    expect(
      h.cubit.state.snapshot!.closeReason,
      AssessmentCloseReason.cancelled,
    );
  });

  testWidgets('footer callbacks cannot act on an old or replacement cubit', (
    tester,
  ) async {
    final old = _Harness();
    await old.mount(tester);
    final oldSubmit = _submit(tester).onPressed!;
    final before = old.store.current!.toJson();
    final replacement = _Harness();
    await replacement.mount(tester);
    oldSubmit();
    await tester.pumpAndSettle();
    expect(old.store.current!.toJson(), before);
    expect(replacement.cubit.state.snapshot!.phase, AssessmentPhase.initial);
    await replacement.cubit.cancel();
    await tester.pumpAndSettle();
    final closedExit = _submit(tester).onPressed!;
    final third = _Harness()..exit = (() async => true);
    await third.mount(tester);
    closedExit();
    await tester.pumpAndSettle();
    expect(old.exits, 0);
    expect(replacement.exitPrompts, 0);
    expect(third.exitPrompts, 0);
    expect(third.exits, 0);
    expect(third.cubit.state.snapshot!.phase, AssessmentPhase.initial);
  });

  for (final missingLabel in [true, false]) {
    testWidgets(
      'new attempt requires ${missingLabel ? 'label' : 'confirmation'}',
      (tester) async {
        final h = _Harness()
          ..newAttemptLabel = missingLabel ? null : 'Nova tentativa'
          ..newAttempt = missingLabel ? (() async => true) : null;
        await h.cubit.load();
        await h.cubit.cancel();
        await h.mount(tester);
        expect(find.byKey(AssessmentKeys.newAttempt), findsNothing);
        expect(find.byKey(AssessmentKeys.submit), findsOneWidget);
      },
    );
  }

  testWidgets('new attempt is absent during collection and execution', (
    tester,
  ) async {
    final h = _Harness()
      ..newAttemptLabel = 'Nova tentativa'
      ..newAttempt = (() async => true);
    await h.mount(tester);
    expect(find.byKey(AssessmentKeys.newAttempt), findsNothing);
    await h.cubit.submitInitial();
    await tester.pumpAndSettle();
    expect(find.byKey(AssessmentKeys.newAttempt), findsNothing);
    await h.cubit.finishExecution(voluntaryConfirmed: true);
    await tester.pumpAndSettle();
    expect(find.byKey(AssessmentKeys.newAttempt), findsNothing);
  });

  testWidgets(
    'new attempt links to durable predecessor and preserves its data',
    (tester) async {
      final h = _Harness()
        ..newAttemptLabel = 'Nova tentativa'
        ..newAttempt = (() async => true);
      await h.mount(tester);
      await h.cubit.replaceDraft(
        AssessmentDraft(editing: AssessmentEditingState(corner: 'h8')),
      );
      await h.cubit.submitInitial();
      await h.cubit.finishExecution(voluntaryConfirmed: true);
      await h.cubit.replaceDraft(
        AssessmentDraft(
          editing: AssessmentEditingState(
            relationPiece: AssessmentPiece.knight,
          ),
        ),
      );
      await h.cubit.submitProtection();
      await tester.pumpAndSettle();
      final old = h.store.current!;
      final oldJson = old.toJson();
      expect(
        tester.getSize(find.byKey(AssessmentKeys.newAttempt)).height,
        greaterThanOrEqualTo(52),
      );
      expect(
        find.descendant(
          of: find.byKey(AssessmentKeys.submit),
          matching: find.text('Sair'),
        ),
        findsOneWidget,
      );
      h.now.value = h.now.value.add(const Duration(seconds: 1));
      await tester.tap(find.byKey(AssessmentKeys.newAttempt));
      await tester.pumpAndSettle();
      final next = h.store.current!;
      expect(next.attemptId, isNot(old.attemptId));
      expect(next.parentAttemptId, old.attemptId);
      expect(next.exposed, isTrue);
      expect(next.phase, AssessmentPhase.initial);
      expect(next.draft.toJson(), AssessmentDraft().toJson());
      expect(next.submissions, isEmpty);
      expect(next.execution.played, isEmpty);
      expect(next.deadlineUtc, h.now.value.add(const Duration(seconds: 600)));
      expect((await h.store.loadById(old.attemptId))!.toJson(), oldJson);
      expect(h.exits, 0);
      expect(find.byKey(AssessmentKeys.newAttempt), findsNothing);
    },
  );

  testWidgets('new attempt declined confirmation is inert', (tester) async {
    final h = _Harness()
      ..newAttemptLabel = 'Nova tentativa'
      ..newAttempt = (() async => false);
    await h.cubit.load();
    await h.cubit.cancel();
    await h.mount(tester);
    final before = h.store.current!.toJson();
    final writes = h.store.writes;
    await tester.tap(find.byKey(AssessmentKeys.newAttempt));
    await tester.pumpAndSettle();
    expect(h.store.current!.toJson(), before);
    expect(h.store.writes, writes);
    expect(h.store.attempts.length, 1);
    expect(h.exits, 0);
  });

  testWidgets('new attempt old confirmation cannot affect replacement cubit', (
    tester,
  ) async {
    final answer = Completer<bool>();
    final old = _Harness()
      ..newAttemptLabel = 'Nova tentativa'
      ..newAttempt = (() => answer.future);
    await old.cubit.load();
    await old.cubit.cancel();
    await old.mount(tester);
    await tester.tap(find.byKey(AssessmentKeys.newAttempt));
    await tester.pump();
    final replacement = _Harness();
    await replacement.mount(tester);
    final oldWrites = old.store.writes;
    final newWrites = replacement.store.writes;
    answer.complete(true);
    await tester.pumpAndSettle();
    expect(old.store.writes, oldWrites);
    expect(replacement.store.writes, newWrites);
    expect(old.store.current!.phase, AssessmentPhase.closed);
    expect(replacement.store.current!.phase, AssessmentPhase.initial);
    expect(old.exits + replacement.exits, 0);
  });

  testWidgets(
    'new attempt old confirmation cannot affect external new attempt',
    (tester) async {
      final answer = Completer<bool>();
      final h = _Harness()
        ..newAttemptLabel = 'Nova tentativa'
        ..newAttempt = (() => answer.future);
      await h.cubit.load();
      await h.cubit.cancel();
      await h.mount(tester);
      await tester.tap(find.byKey(AssessmentKeys.newAttempt));
      await tester.pump();
      await h.cubit.retry();
      final replacement = h.store.current!;
      answer.complete(true);
      await tester.pumpAndSettle();
      expect(h.store.current!.attemptId, replacement.attemptId);
      expect(h.store.current!.parentAttemptId, replacement.parentAttemptId);
      expect(h.store.current!.phase, AssessmentPhase.initial);
      expect(h.cubit.state.technicalFailure, isNull);
      expect(h.store.attempts.length, 2);
    },
  );

  testWidgets(
    'new attempt blocks busy and storage failure while recovery stays available',
    (tester) async {
      final h = _Harness()
        ..newAttemptLabel = 'Nova tentativa'
        ..newAttempt = (() async => true);
      await h.cubit.load();
      await h.cubit.cancel();
      await h.mount(tester);
      final gate = Completer<void>();
      h.store.writeGate = gate;
      await tester.tap(find.byKey(AssessmentKeys.newAttempt));
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(AssessmentKeys.newAttempt))
            .onPressed,
        isNull,
      );
      h.store.fail = true;
      gate.complete();
      await tester.pumpAndSettle();
      expect(
        h.cubit.state.technicalFailure,
        AssessmentTechnicalFailure.storage,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(AssessmentKeys.newAttempt))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(find.byKey(AssessmentKeys.retry)).onPressed,
        isNotNull,
      );
      expect(h.store.attempts.length, 1);
    },
  );

  testWidgets('technical retry old callback ignores replacement binding', (
    tester,
  ) async {
    final old = _Harness();
    await old.mount(tester);
    old.store.fail = true;
    await old.cubit.cancel();
    await tester.pumpAndSettle();
    final recover = tester
        .widget<TextButton>(find.byKey(AssessmentKeys.retry))
        .onPressed!;
    final replacement = _Harness();
    await replacement.mount(tester);
    final oldReads = old.store.reads;
    final replacementReads = replacement.store.reads;
    recover();
    await tester.pumpAndSettle();
    expect(old.store.reads, oldReads);
    expect(replacement.store.reads, replacementReads);
    expect(
      old.cubit.state.technicalFailure,
      AssessmentTechnicalFailure.storage,
    );
    expect(replacement.cubit.state.technicalFailure, isNull);
  });

  testWidgets('technical retry old callback ignores replacement attempt', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    h.store.fail = true;
    await h.cubit.cancel();
    await tester.pumpAndSettle();
    final recover = tester
        .widget<TextButton>(find.byKey(AssessmentKeys.retry))
        .onPressed!;
    h.store.fail = false;
    await h.cubit.resume();
    await h.cubit.cancel();
    await h.cubit.retry();
    h.store.fail = true;
    await h.cubit.replaceDraft(AssessmentDraft());
    await tester.pumpAndSettle();
    final replacementId = h.cubit.state.snapshot!.attemptId;
    final reads = h.store.reads;
    recover();
    await tester.pumpAndSettle();
    expect(h.store.reads, reads);
    expect(h.cubit.state.snapshot!.attemptId, replacementId);
    expect(h.cubit.state.technicalFailure, AssessmentTechnicalFailure.storage);
  });
}
