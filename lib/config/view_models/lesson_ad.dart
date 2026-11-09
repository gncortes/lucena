import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../data/repositories/lesson_ad/demo_ad_repository.dart';
import '../../data/repositories/review/review_repository.dart';
import '../../ui/lesson_ad/view_models/lesson_entry_gate.dart';

/// A entrada de uma lição com o que houver no [context]: sem o acesso, o
/// curso está aberto; sem o anúncio, entra direto.
LessonEntryGate createLessonEntryGate(BuildContext context) => LessonEntryGate(
  access: _read<CourseAccessRepository>(context),
  ads: _read<DemoAdRepository>(context),
  review: _read<ReviewRepository>(context),
);

T? _read<T>(BuildContext context) {
  try {
    return context.read<T>();
  } on ProviderNotFoundException {
    return null;
  }
}
