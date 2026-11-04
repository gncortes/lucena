import 'package:flutter/widgets.dart';

import '../../../domain/models/training/training_course.dart';

/// The Guide tab: the plan in weeks. Content comes from the goal-based
/// training front; this is the entry point the course screen mounts.
class TrainingGuideTab extends StatelessWidget {
  const TrainingGuideTab({super.key, required this.course});
  final TrainingCourse course;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
