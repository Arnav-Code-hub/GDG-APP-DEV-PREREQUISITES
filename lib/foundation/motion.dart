import 'package:flutter/widgets.dart';

bool prefersReducedMotion(BuildContext context) {
  final features = View.of(context).platformDispatcher.accessibilityFeatures;
  // iOS Reduce Motion is separate from the disableAnimations signal.
  return MediaQuery.of(context).disableAnimations ||
      features.disableAnimations ||
      features.reduceMotion;
}
