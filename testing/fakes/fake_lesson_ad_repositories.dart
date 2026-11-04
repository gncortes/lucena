import 'dart:async';

import 'package:lucena/data/repositories/lesson_ad/course_access_repository.dart';
import 'package:lucena/data/repositories/lesson_ad/demo_ad_repository.dart';
import 'package:lucena/domain/models/course_access.dart';

class FakeCourseAccessRepository implements CourseAccessRepository {
  FakeCourseAccessRepository([this._access = CourseAccess.demo]);

  CourseAccess _access;
  final _changes = StreamController<CourseAccess>.broadcast();

  @override
  CourseAccess get access => _access;

  set access(CourseAccess value) {
    _access = value;
    _changes.add(value);
  }

  @override
  Stream<CourseAccess> get changes => _changes.stream;
}

class FakeDemoAdRepository implements DemoAdRepository {
  FakeDemoAdRepository({this.seen = false, this.loads = const [true]});

  bool seen;

  /// A resposta de cada [load], na ordem; a última se repete.
  List<bool> loads;
  int loadCalls = 0;
  int marks = 0;

  /// Se preenchido, [load] espera por ele (para ver o carregando).
  Completer<void>? gate;

  @override
  Future<bool> noticeSeen() async => seen;

  @override
  Future<void> markNoticeSeen() async {
    seen = true;
    marks++;
  }

  @override
  Future<bool> load() async {
    final answer =
        loads[loadCalls < loads.length ? loadCalls : loads.length - 1];
    loadCalls++;
    await gate?.future;
    return answer;
  }
}
