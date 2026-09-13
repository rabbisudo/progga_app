import 'package:flutter/material.dart';

/// Custom ScrollBehavior for Progga application.
/// Prevents excessive bouncing voids and huge empty gaps when pulling/dragging
/// up or down, while maintaining smooth, native Android/Material edge clamping.
class ProggaScrollBehavior extends MaterialScrollBehavior {
  const ProggaScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // Clean stretching overscroll indicator without disconnecting or exposing large empty backgrounds
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
