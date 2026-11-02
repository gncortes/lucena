import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/diagnostics/failure_report_repository.dart';
import 'package:lucena/ui/core/view_models/course_availability_cubit.dart';

class _Reports extends FailureReportRepository {
  final errors = <Object>[];
  final stacks = <StackTrace>[];

  @override
  void record(Object error, StackTrace stack) {
    errors.add(error);
    stacks.add(stack);
  }
}

void main() {
  test(
    'consulta falha: lista sem curso, diagnóstico e sem exceção solta',
    () async {
      final error = StateError('consulta');
      final reports = _Reports();
      final cubit = CourseAvailabilityCubit(
        () async => throw error,
        reports: reports,
      );
      addTearDown(cubit.close);

      await expectLater(cubit.load(), completes);

      expect(cubit.state, isFalse);
      expect(reports.errors, [same(error)]);
      expect(reports.stacks.single.toString(), isNotEmpty);
    },
  );

  test('uma nova consulta pode recuperar o curso depois da falha', () async {
    var fail = true;
    final reports = _Reports();
    final cubit = CourseAvailabilityCubit(
      () async => fail ? throw StateError('consulta') : true,
      reports: reports,
    );
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state, isFalse);
    fail = false;
    await cubit.load();
    expect(cubit.state, isTrue);
    expect(reports.errors, hasLength(1));
  });
}
