import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_download_repository.dart';
import '../../../data/services/lesson_package_service.dart';

/// Pins installed content until the current lesson/exercise/test route closes.
class CourseContentSession extends StatefulWidget {
  const CourseContentSession({required this.child, super.key});
  final Widget child;
  @override
  State<CourseContentSession> createState() => _SessionState();
}

class _SessionState extends State<CourseContentSession> {
  LessonPackageLease? _lease;
  @override
  void initState() {
    super.initState();
    try {
      _lease = context.read<CourseDownloadRepository>().beginSession();
    } on ProviderNotFoundException {
      /* Compositions without remote content. */
    }
  }

  @override
  void dispose() {
    final lease = _lease;
    if (lease != null) unawaited(lease.close().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
