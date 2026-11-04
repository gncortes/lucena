import 'package:flutter/material.dart';

import '../../../domain/models/training/training_course.dart';

class TrainingGuideTab extends StatelessWidget {
  const TrainingGuideTab({super.key, required this.course});
  final TrainingCourse course;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
