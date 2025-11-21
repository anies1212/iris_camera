import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

class LensStatusIndicator extends StatelessWidget {
  const LensStatusIndicator({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return isActive
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.switch_camera_outlined);
  }
}

String buildLensSubtitle(CameraLensDescriptor lens) {
  final parts = <String>[lens.category.name, lens.position.name];
  final fieldOfView = lens.fieldOfView;
  if (fieldOfView != null) {
    parts.add('${fieldOfView.toStringAsFixed(1)}° FOV');
  }
  return parts.join(' • ');
}
