import 'package:flutter/material.dart';

import 'skeleton.dart';

/// Existing list shimmer used while the first screen snapshot is unavailable.
class LoadSkeletonScreen extends StatelessWidget {
  const LoadSkeletonScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SafeArea(child: SkeletonList()));
}
